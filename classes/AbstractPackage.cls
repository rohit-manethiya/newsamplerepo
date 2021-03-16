public with sharing abstract class AbstractPackage extends AbstractArtifact implements IPackageBehavior {
    private List<ArtifactVersion> packageVersions;
    private String packageId;
    protected Boolean skipPackageVersionValidation = false;

    abstract void throwArtifactException();

    /** 
     * @description this method sets a flag to bypass the package version validation when an unlocked artifact is
     * installed in a Scratch Org.
     *
     * @param skipValidation is the flag that indicates whether a package version validation should be skipped or not
     * while installing the unlocked package.
     */
    public void setSkipPackageVersionValidation(Boolean skipValidation) {
        this.skipPackageVersionValidation = skipValidation;
    }

    public void setPackageVersions(List<ArtifactVersion> artifactVersions) {
        this.packageVersions = artifactVersions;
    }

    public List<ArtifactVersion> getPackageVersions() {
        if (this.packageVersions == null) {
            this.packageVersions = new List<ArtifactVersion>();
        }
        return this.packageVersions;
    }

    public void setPackageId(String packageId) {
        this.packageId = encode(packageId);
    }

    public String getPackageId() {
        return this.packageId;
    }

    public override void loadMetadata() {
        String scratchOrgId = getScratchOrgId();
        if (String.isBlank(scratchOrgId)) {
            throw new ArtifactException(Label.Load_MD_OrgId_Required);
        }
        if (getPackageVersions().isEmpty()) {
            throw new ArtifactException(Label.Select_package_to_install);
        }

        if (hasAccessTo(Org__c.SObjectType)) {
            //Need to add try catch
            List<Org__c> scratchOrgs = [
                SELECT Developer_Hub_Org__c
                FROM Org__c
                WHERE Id = :scratchOrgId AND Developer_Hub_Org__c != NULL
                WITH SECURITY_ENFORCED
            ];
            if (!scratchOrgs.isEmpty()) {
                setDevHubOrgId(scratchOrgs[0].Developer_Hub_Org__c);
            } else {
                throw new ArtifactException(Label.Developer_Hub_not_null);
            }
        }

        Map<String, String> attachmentMap = getDefaultAttachmentMap();
        String packageDetailsJson = generatePackageDetailsJson();
        if (String.isNotBlank(packageDetailsJson)) {
            attachmentMap.put(DXLabel.PACKAGE_DETAILS, packageDetailsJson);
        }

        sendLoadMetadataCallout(scratchOrgId, getDevHubOrgId(), JSON.serialize(attachmentMap));
    }

    public String generatePackageDetailsJson() {
        List<PackageDetail> packageDetails = getPackageDetails();
        String packageDetailsJson = '{"packages":' + JSON.serialize(packageDetails) + '}';
        return packageDetailsJson;
    }

    private List<PackageDetail> getPackageDetails() {
        List<PackageDetail> packageDetails = new List<PackageDetail>();
        Map<String, Sensitive_Information__c> sensitiveInfoMap = Sensitive_Information__c.getAll();
        for (ArtifactVersion packageVersion : getPackageVersions()) {
            Artifact_Version__c thisVersion = packageVersion.getVersion();
            Sensitive_Information__c packageInformation = sensitiveInfoMap.get(thisVersion.Id);
            PackageDetail packageDetail = createPackageDetail(thisVersion, packageInformation);
            packageDetails.add(packageDetail);
        }
        return packageDetails;
    }

    private PackageDetail createPackageDetail(Artifact_Version__c thisVersion, Sensitive_Information__c packageInformation) {
        PackageDetail packageDetail = new PackageDetail(
            // It is repeated because backend always take PackageId as SubcriberId. 
            thisVersion.Subscriber_Version_Id__c,
            thisVersion.Subscriber_Version_Id__c,
            thisVersion.Name,
            thisVersion.Version_number__c
        );
        if (packageInformation != null) {
            try {
                packageDetail.setInstallationKey(DeployAPI.decryptAPIKey(packageInformation.Password__c));
            } catch (Exception ex) {
                throw new ArtifactException(ex.getMessage());
            }
        }
        return packageDetail;
    }

    private void sendLoadMetadataCallout(String scratchOrgId, String devHubOrgId, String attachmentJson) {
        String callUrl = Settings.server_url + '/json/v1/package/install?targetOrgId=' + encode(scratchOrgId) + '&devHubOrgId=' + devhubOrgId;
        String dxRepositoryId = getDxRepositoryId();
        if (String.isNotBlank(dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + encode(dxRepositoryId);
        }
        SfdxAPIHelper.callDxJob(DXLabel.HTTP_POST, callUrl, attachmentJson, true, DXLabel.INSTALLED_PACKAGES);
    }

    public void createPackage(String description, String packageName, Boolean noNamespace, String packageType) {
        String callURL =
            Settings.server_url +
            '/json/v1/package/create?description=' +
            encode(description) +
            '&name=' +
            encode(packageName) +
            '&packageType=' +
            packageType +
            '&devHubOrgId=' +
            getDevHubOrgId() +
            '&artifactId=' +
            getArtifactId();
        if (noNamespace != null) {
            callURL += '&noNamespace=' + noNamespace;
        }

        Map<String, String> attachments = new Map<String, String>();
        attachments.put(DXLabel.PROJECT_FILE, generateProjectJson());
        try {
            sendDXRequest(callURL, DXLabel.HTTP_POST, JSON.serialize(attachments), DXLabel.CREATE_PACKAGE, false);
        } catch (Exception ex) {
            throw new PackageException(ex.getMessage());
        }
    }

    public void createPackageVersion(
        String orgDefinitionJSON,
        String branch,
        String sourceBranch,
        String installationKey,
        String tag,
        Artifact_Version__c version
    ) {
        String callURL =
            Settings.server_url +
            '/json/v1/package/version/create?&packageId=' +
            getPackageId() +
            '&devHubOrgId=' +
            getDevHubOrgId() +
            '&versionName=' +
            encode(version.Name) +
            '&versionNumber=' +
            version.Version_number__c +
            '&artifactId=' +
            getArtifactId();
        if (String.isNotBlank(branch)) {
            callURL += '&branch=' + encode(branch);
        }
        if (String.isNotBlank(sourceBranch)) {
            // TODO: IMPLEMENT IN THE FUTURE WHEN BACKEND IS READY TO HANDLE THIS PARAMETER (US-0012301)
            //callURL += '&sourceBranch=' + encode(sourceBranch);
        }
        if (String.isNotBlank(installationKey)) {
            callURL += '&installationKey=' + installationKey;
        } else {
            callURL += '&installationKeyByPass=true';
        }
        if (String.isNotBlank(tag)) {
            callURL += '&tag=' + encode(tag);
        }
        if (String.isNotBlank(version.Version_Description__c)) {
            callURL += '&versionDescription=' + encode(version.Version_Description__c);
        }

        Map<String, String> attachments = new Map<String, String>();
        orgDefinitionJSON = orgDefinitionJSON == null ? getDefaultOrgDefinitionJSON() : sfdxApiHelper.returnJsonAfterCorrection(orgDefinitionJSON);
        attachments.put(DXLabel.PROJECT_FILE, generateProjectJson());
        attachments.put(DXLabel.DEFINITION_FILE, orgDefinitionJSON);
        try {
            sendDXRequest(callURL, DXLabel.HTTP_POST, JSON.serialize(attachments), DXLabel.CREATE_PACKAGE_VERSION, true);
        } catch (Exception ex) {
            throw new PackageException(Label.Error_During_Package_Version_Creation + ': ' + ex.getMessage());
        }
    }

    private String getDefaultOrgDefinitionJSON() {
        ScratchOrgDefinition orgDefinition = new ScratchOrgDefinition();
        return JSON.serialize(orgDefinition, true);
    }

    public void promoteBetaPackageToReleased(Id artifactVersionId) {
        String projectJson = generateProjectJson();
        if (String.isBlank(projectJson) && getPackageId() == null && getDevHubOrgId() == null && artifactVersionId == null) {
            throw new PackageException('Required parameter(s) missing for promoting this beta version.');
        }
        String callURL =
            Settings.server_url +
            '/json/v1/promoteToReleased?packageId=' +
            getPackageId() +
            '&artifactId=' +
            getArtifactId() +
            '&devHubOrgId=' +
            getDevHubOrgId() +
            '&artifactVersionId=' +
            artifactVersionId;
        try {
            Map<String, String> attachments = new Map<String, String>();
            attachments.put(DXLabel.PROJECT_FILE, projectJson);
            sendDXRequest(callURL, DXLabel.HTTP_POST, JSON.serialize(attachments), DXLabel.PROMOTE_BETA_RELEASED, true);
        } catch (Exception ex) {
            throw new PackageException('An error occurred during artifact version promotion.' + ex.getMessage());
        }
    }

    public List<Artifact_Version__c> getPackageDependencies() {
        if (!hasAccessTo(Artifact_Dependency__c.SObjectType) || !hasAccessTo(Artifact_Version__c.SObjectType)) {
            return new List<Artifact_Version__c>();
        }

        List<Artifact_Version__c> artifactVersions = new List<Artifact_Version__c>();        
        Map<Id, Integer> versionIndexById = getVersionIndexById();
        Map<Integer,Artifact_Version__c> versionsByOrder = getVersionsByOrder(versionIndexById);
        
        // Put a in a list versions in the correct order.
        for (Integer j = 1; j <= versionsByOrder.size(); j++)  {
            artifactVersions.add(versionsByOrder.get(j));
        }
       
        return artifactVersions;
    }

    private Map<Id, Integer> getVersionIndexById() {
        Map<Id, Integer> versionIndexById = new Map<Id, Integer>();
        Integer i = 1;
        for (Artifact_Dependency__c thisDependency : [
            SELECT
                Name,
                Dependent_Artifact__c,
                Depending_Artifact__c,
                Depending_Artifact_Version__c,
                Depending_Artifact__r.Artifact_Version__c,
                Depends_on_the_latest_version__c
            FROM Artifact_Dependency__c
            WHERE Dependent_Artifact__c = :getArtifactId()
            ORDER BY Name ASC 
        ]) {
            if (thisDependency.Depends_on_the_latest_version__c) {
                versionIndexById.put(thisDependency.Depending_Artifact__r.Artifact_Version__c, i);
            } else {
                versionIndexById.put(thisDependency.Depending_Artifact_Version__c, i);
            }
            i++;
        }
        return versionIndexById;
    }

    private  Map<Integer,Artifact_Version__c> getVersionsByOrder(Map<Id, Integer> versionIndexById) {
        // TODO: ORDER THIS IN A MAP TO REFLECT WHICH ARTIFACTS ARE LATEST VERSIONS OF A PACKAGE TO INCLUDE THEM IN THE DEPENDENCIES SECTION AND WHICH ARE TO BE INCLUDED IN THE DIRECTORIES SECTION
        Map<Integer,Artifact_Version__c> versionsByOrder = new Map<Integer, Artifact_Version__c>();
        for(Artifact_Version__c version : [
            SELECT
                Id,
                Name,
                Artifact__c,
                Artifact__r.Package_Id__c,
                Branch__c,
                Is_released__c,
                Tag__c,
                Version_Description__c,
                Version_number__c,
                Artifact__r.Name,
                Subscriber_Version_Id__c
            FROM Artifact_Version__c
            WHERE Id IN :versionIndexById.keySet()

        ]) {
            versionsByOrder.put(versionIndexById.get(version.Id), version);
        }
        return versionsByOrder;
    }

    public override String generateMetadataSourcesJson() {
        if (getPackageVersions().isEmpty()) {
            throwArtifactException();
        }

        List<String> artifactIds = new List<String>();
        for (ArtifactVersion packageVersion : getPackageVersions()) {
            Artifact_Version__c thisVersion = packageVersion.getVersion();
            artifactIds.add(thisVersion.Subscriber_Version_Id__c);
        }
        return getFormattedMetadataSourcesJson();
    }

    public override String generateProjectJson() {
        if (getPackageVersions().isEmpty()) {
            throwArtifactException();
        }

        DXProject project = getDXProject();
        System.debug('Dx Project Generate projectJson: ' + project);
        project.setPackageAliases(getPackageAliasesMap());
        project.clearAliasesIfEmpty();
        if (project.getPackageDirectories().isEmpty()) {
            project.setPackageDirectories(getArtifactDirectories());
        }
        for (ProjectArtifact thisArtifact : project.getPackageDirectories()) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        System.debug('2 Dx Project Generate projectJson: ' + project);
        return getFormattedProjectJson(project);
    }

    private Map<String, String> getPackageAliasesMap() {
        Map<String, String> packageAliasesMap = new Map<String, String>();
        if (String.isNotBlank(getArtifactName())) {
            if (String.isNotBlank(getPackageId())) {
                packageAliasesMap.put(getArtifactName(), getPackageId());
            } else {
                packageAliasesMap.put(getArtifactName(), getArtifactId());
            }
        }
        System.debug('CG Package Versions: ' + getPackageVersions());
        for (ArtifactVersion version : getPackageVersions()) {
            Artifact_Version__c record = version.getVersion();
            if (record.Id != null) {
                packageAliasesMap.put(version.getArtifactName(), record.Subscriber_Version_Id__c);
            }
        }
        return packageAliasesMap;
    }

    private List<ProjectArtifact> getArtifactDirectories() {
        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        Map<String, ProjectArtifact> projectArtifactMap = new Map<String, ProjectArtifact>();
        artifactDirectories.add(new ProjectArtifact(DXLabel.DEFAULT_PATH, true));
        for (ArtifactVersion packageVersion : getPackageVersions()) {
            Artifact_Version__c thisVersion = packageVersion.getVersion();
            ProjectArtifact mainArtifact = createProjectArtifact(thisVersion);
            projectArtifactMap.put(thisVersion.Name, mainArtifact);
            if (!mainArtifact.getDefaultArtifact()) {
                ProjectArtifact existingArtifact = projectArtifactMap.get(packageVersion.getIncludedBy()); // TODO: VERIFY IF INCLUDED BY SHOULD BE Artifact_Version__c.Version_Name__c OR Artifact_Version__c.Artifact__r.Name instead of Artifact_Version__c.Name
                if (existingArtifact != null) {
                    PackageDependency dependency = new PackageDependency(thisVersion.Name, thisVersion.Version_number__c);
                    existingArtifact.addDependency(dependency);
                    projectArtifactMap.put(packageVersion.getIncludedBy(), existingArtifact);
                }
            }
        }
        artifactDirectories.addAll(projectArtifactMap.values());
        return artifactDirectories;
    }

    private ProjectArtifact createProjectArtifact(Artifact_Version__c thisVersion) {
        ProjectArtifact projectArtifact = new ProjectArtifact(
            thisVersion.Artifact__r.Name,
            thisVersion.Artifact__r.Package_Id__c,
            false,
            thisVersion
        );
        return projectArtifact;
    }

    public void updateProjectJsonAttachment() {
        String projectJson = generateProjectJson();
        try {
            List<Attachment> attachments = [
                SELECT Id, Body
                FROM Attachment
                WHERE ParentId = :getArtifactId() AND Name = :DXLabel.PROJECT_FILE
                WITH SECURITY_ENFORCED
            ];
            if (!attachments.isEmpty()) {
                attachments[0].Body = Blob.valueOf(projectJson);
                try {
                    SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, attachments);
                    update decision.getRecords()[0];
                } catch (NoAccessException ex) {
                    throw new ArtifactException(SObjectType.Attachment.Label + ': ' + Label.Insufficient_Access_Rights);
                }
            } else {
                createNewProjectJsonAttachment(projectJson);
            }
        } catch (QueryException queryEx) {
            throw new ArtifactException(SObjectType.Attachment.Label + ': ' + Label.Insufficient_Access_Rights);
        } catch (Exception ex) {
            createNewProjectJsonAttachment(projectJson);
        }
    }

    private void createNewProjectJsonAttachment(String projectJson) {
        Attachment projectJsonAttachment = new Attachment();
        projectJsonAttachment.Name = DXLabel.PROJECT_FILE;
        projectJsonAttachment.ParentId = getArtifactId();
        projectJsonAttachment.Body = Blob.valueOf(projectJson);
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Attachment>{ projectJsonAttachment });
            insert decision.getRecords();
        } catch (NoAccessException ex) {
            throw new ArtifactException(SObjectType.Attachment.Label + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    public class PackageException extends Exception {
    }
}