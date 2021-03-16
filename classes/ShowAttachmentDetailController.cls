/**
 * @description this controller and its component are responsible for generating DX Project (sfdx-project.json) files
 * for a selected artifact.
 */
public with sharing class ShowAttachmentDetailController {
    private AbstractArtifact thisArtifact;
    public Artifact__c currentRecord { get; set; }
    public String attachmentName { get; set; }
    public DXProject thisProject { get; set; }
    public List<Attachment> attachments {
        get {
            if (attachments == null) {
                attachments = getAttachments();
            }
            return attachments;
        }
        set;
    }

    /**
     * @description when an artifact doesn't have a DX Project (sfdx-project.json) file create yet or it doesn't exist
     * in the artifact's attachments, this method creates a default DX Project that will later be populated with the
     * parameters specified by the artifact configuration.
     * @see DXProject
     *
     * @return a DXProject entity with default project attributes.
     */
    private DXProject createDefaultDXProject() {
        DXProject project = new DXProject(
            currentRecord.Package_Namespace__c,
            String.isNotBlank(currentRecord.Sfdc_Login_Url__c) ? currentRecord.Sfdc_Login_Url__c : DXLabel.DEFAULT_SFDC_LOGIN_URL,
            String.isNotBlank(currentRecord.Source_Api_Version__c) ? currentRecord.Source_Api_Version__c : DXLabel.DEFAULT_API_VERSION
        );
        return project;
    }

    /**
     * @description this method generates a new DX Project Definition file or overwrites an existing one with updated
     * content based on the selected Artifact Version.
     *
     * @return a page redirection to the artifact's detail page.
     */
    public PageReference createAttachment() {
        if (!initArtifactInstance()) {
            return null;
        }
        thisProject.clearPackageDirectories();
        setArtifactParameters();
        try {
            setSkipInstallPackageValidation(true);
            String projectJson = thisArtifact.generateProjectJson();
            setSkipInstallPackageValidation(false);

            Attachment projectDefinitionJson = createProjectDefinitionAttachment(projectJson);
            if (
                SObjectType.Attachment.Fields.ParentId.isAccessible() &&
                SObjectType.Attachment.isCreateable() &&
                SObjectType.Attachment.isUpdateable()
            ) {
                upsert projectDefinitionJson;
            }
        } catch (NoAccessException noAccessEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + noAccessEx.getMessage());
            return null;
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            return null;
        }
        return redirectToPreviousPage();
    }

    /**
     * @description gets all the artifact information selected by the user and puts it into the AbstractPackage
     * instance to prepare the DX Project Definition file (sfdx-project.json).
     * @see AbstractPackage
     */
    private void setArtifactParameters() {
        if (thisArtifact instanceof AbstractPackage) {
            if (String.isNotBlank(currentRecord.Package_Id__c)) {
                thisArtifact.setArtifactName(currentRecord.Name);
                ((AbstractPackage) thisArtifact).setPackageId(currentRecord.Package_Id__c);
            }
            if (String.isNotBlank(currentRecord.Artifact_Version__c)) {
                List<ArtifactVersion> artifactVersions = new List<ArtifactVersion>();
                ArtifactVersion thisVersion = createArtifactVersion();
                artifactVersions.add(thisVersion);
                ((AbstractPackage) thisArtifact).setPackageVersions(artifactVersions);

                List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>(); // TODO: GET DEPENDENCIES
                ProjectArtifact mainArtifact = new ProjectArtifact(currentRecord.Name, currentRecord.Package_Id__c, true, thisVersion.getVersion());

                List<PackageDependency> dependencies = getArtifactDependencies();
                mainArtifact.setDependencies(dependencies);

                artifactDirectories.add(mainArtifact);
                for (ProjectArtifact thisArtifact : artifactDirectories) {
                    thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
                }
                thisProject.setPackageDirectories(artifactDirectories);
            }
        }
        thisProject.setNamespace(currentRecord.Package_Namespace__c);
        thisArtifact.setDXProject(thisProject);
    }

    /**
     * @description gets the latest Artifact_Version__c record associated with the current artifact and wraps it in an
     * ArtifactVersion entity that will be appended to the DX Project Definition file afterwards.
     *
     * @return the ArtifactVersion entity wrapping the latest Artifact_Version__c record of the current artifact.
     */
    private ArtifactVersion createArtifactVersion() {
        ArtifactVersion version;
        try {
            Artifact_Version__c thisVersion = [
                SELECT
                    Name,
                    Artifact__c,
                    Artifact__r.Name,
                    Artifact__r.Package_Namespace__c,
                    Subscriber_Version_Id__c,
                    Version_number__c,
                    Version_Description__c,
                    Artifact__r.Package_Id__c
                FROM Artifact_Version__c
                WHERE Id = :currentRecord.Artifact_Version__c
                WITH SECURITY_ENFORCED
            ];
            version = new ArtifactVersion(thisVersion.Name, thisVersion.Artifact__r.Name, thisVersion);
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
        return version;
    }

    /**
     * @description this method gets all the artifact dependencies from the latest Artifact Version that was selected
     * by the user and adds them to the DX Project directories as part of the project metadata.
     * @see AbstractPackage
     * @see PackageDependency
     *
     * @return a list of package dependencies for the latest artifact version.
     */
    private List<PackageDependency> getArtifactDependencies() {
        List<PackageDependency> dependencies = new List<PackageDependency>();
        for (Artifact_Version__c thisVersion : ((AbstractPackage) thisArtifact).getPackageDependencies()) {
            PackageDependency dependency = new PackageDependency(thisVersion.Name, thisVersion.Version_number__c);
            dependencies.add(dependency);
        }
        return dependencies;
    }

    /**
     * @description this method creates a new attachment under the current artifact with the latest DX Project
     * information contained in a sfdx-project.json file.
     *
     * @param projectJson is the content of the sfdx-project.json file.
     *
     * @return a Salesforce Attachment with the latest DX Project information.
     */
    private Attachment createProjectDefinitionAttachment(String projectJson) {
        Attachment projectDefinitionJson = new Attachment();
        projectDefinitionJson.Name = attachmentName;
        projectDefinitionJson.Body = Blob.valueOf(projectJson);
        projectDefinitionJson.ParentId = currentRecord.Id;
        if (!attachments.isEmpty()) {
            projectDefinitionJson.Id = attachments[0].Id;
        }
        return projectDefinitionJson;
    }

    /**
     * @description this method creates a page reference redirection to take the user back to the artifact detail page
     * once the operation is complete.
     *
     * @return a page reference redirection to the current artifact's detail page.
     */
    private PageReference redirectToPreviousPage() {
        String comesFromDXPackageVersion = ApexPages.currentPage().getParameters().get('DXPackageVersion');
        PageReference thisPage;
        if (String.isNotBlank(comesFromDXPackageVersion)) {
            thisPage = Page.DXPackageVersion;
            thisPage.getParameters().put('Id', currentRecord.Id);
        } else {
            thisPage = new ApexPages.StandardController(currentRecord.Id.getSobjectType().newSObject(currentRecord.Id)).view();
        }
        thisPage.setRedirect(true);
        return thisPage;
    }

    /**
     * @description this method determines whether the package installation validation should be bypassed on the target
     * class or not. For certain scenarios like this page, validating the version of the given package is not required.
     * @see AbstractPackage
     *
     * @param enable a flag that sets the validation bypass before calling the target instance of AbstractPackage
     */
    private void setSkipInstallPackageValidation(Boolean enable) {
        if (thisArtifact instanceof UnlockedArtifact) {
            ((UnlockedArtifact) thisArtifact).setSkipPackageVersionValidation(enable);
        } else if (thisArtifact instanceof SecondGenerationManagedArtifact) {
            ((SecondGenerationManagedArtifact) thisArtifact).setSkipPackageVersionValidation(enable);
        }
    }

    /**
     * @description this method uses the Static Factory pattern to retrieve an abstract instance of an Artifact entity
     * that provides all the necessary services to work with the selected type of artifact.
     * @see ArtifactFactory
     * @see AbstractArtifact
     *
     * @return a flag indicating if the initialization was successful or it failed if the selected artifact type is not
     * supported.
     */
    private Boolean initArtifactInstance() {
        Boolean success = true;
        switch on currentRecord.Package_Type__c {
            when 'Unlocked' {
                thisArtifact = ArtifactFactory.getInstance(DXLabel.UNLOCKPACKAGE);
            }
            when 'Second-Generation Package' {
                thisArtifact = ArtifactFactory.getInstance(DXLabel.SECONDGENERATIONPACKAGE);
            }
            when else {
                success = false;
                addPageMessage(ApexPages.Severity.ERROR, Label.Unsupported_Metadata_Source);
            }
        }
        return success;
    }

    private List<Attachment> getAttachments() {
        List<Attachment> results = new List<Attachment>();
        try {
            results = [SELECT Body FROM Attachment WHERE Name = :attachmentName AND ParentId = :currentRecord.Id WITH SECURITY_ENFORCED];
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
        if (!results.isEmpty()) {
            try {
                String projectJson = results[0].Body.toString();
                projectJson = projectJson.replaceAll('"package":', '"packageName":').replaceAll('"default":', '"defaultArtifact":');
                thisProject = (DXProject) JSON.deserialize(projectJson, DXProject.class);
            } catch (JSONException jsonEx) {
                thisProject = createDefaultDXProject();
            }
        } else {
            thisProject = createDefaultDXProject();
        }
        return results;
    }

    /**
     * @description a utility method for displaying messages on the parent page.
     *
     * @param severity is the ApexPages.Severity enum value for the type of message.
     * @param message is the actual message to be shown to the user.
     */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}