/**
 * @description this class and its component are responsible for all the metadata-related operations such as source
 * selection, loading or generating the proper definition/configuration files in JSON format.
 */
public with sharing class ScratchOrgMetadataController extends ScratchOrgWizardComponentBase {
    private Map<String, Artifact_Version__c> versionMap;
    private Map<String, Id> artifactNameToId;
    public Boolean canViewArtifact { get; set; }
    public Boolean canViewGitRepository { get; set; }
    public Boolean canViewOrg { get; set; }
    public Boolean canCreateProjectTemplate { get; set; }
    public Boolean canUpdateProjectTemplate { get; set; }
    public Boolean showArtifactVersions { get; private set; }
    //public String convertSource { get; set; }
    public String typeName { get; set; }
    public String branchGridMode { get; set; }
    public String selectedTemplateName { get; set; }
    public String selectedReleaseName { get; set; }
    public String selectedRepositoryName { get; set; }
    public String selectedMetadataFormat { get; set; }
    public Id selectedArtifactId { get; set; }
    public Id selectedVersionId { get; set; }
    public Id selectedTemplateId { get; set; }
    public Id selectedReleaseId { get; set; }
    public Id selectedRepositoryId { get; set; }
    public List<ArtifactVersion> selectedPackageList { get; set; }
    public List<Id> selectedArtifactIds { get; set; }
    public AbstractArtifact thisArtifact { get; private set; }
    public DXProject thisDxProject { get; set; }
    public MetadataSource thisMetadataSource { get; private set; }
    public List<SelectOption> selectedArtifacts { get; set; }
    public List<SelectOption> artifactOptions { get; set; }
    public List<SelectOption> artifactVersionOptions {
        get {
            versionMap = new Map<String, Artifact_Version__c>();
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', Label.NONE_SELECTED));
            if (String.isNotBlank(selectedArtifactId)) {
                try {
                    for (Artifact_Version__c thisVersion : [
                        SELECT
                            Name,
                            Artifact__c,
                            Artifact__r.Name,
                            Artifact__r.Package_Id__c,
                            Artifact__r.Package_Namespace__c,
                            Artifact__r.Artifact_Repository__c,
                            Subscriber_Version_Id__c,
                            Version_number__c,
                            Version_Description__c
                        FROM Artifact_Version__c
                        WHERE Artifact__c = :selectedArtifactId AND Subscriber_Version_Id__c != NULL
                        WITH SECURITY_ENFORCED
                    ]) {
                        options.add(new SelectOption(thisVersion.Id, thisVersion.Name));
                        versionMap.put(thisVersion.Id, thisVersion);
                    }
                } catch (QueryException queryEx) {
                    addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
                }
            }
            return options;
        }
    }
    public List<SelectOption> metadataFormatOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption(DXLabel.METADATA_API, DXLabel.METADATA_API));
            options.add(new SelectOption(DXLabel.DX_FORMAT, DXLabel.DX_FORMAT));    
            return options;
        }
    }

    public ScratchOrgMetadataController() {
        canViewArtifact = hasAccessTo(Artifact__c.SObjectType);
        canViewGitRepository = hasAccessTo(Git_Repository__c.SObjectType);
        canViewOrg = hasAccessTo(Org__c.SObjectType);
        if (!canViewArtifact || !canViewGitRepository || !canViewOrg) {
            return;
        }
        canCreateProjectTemplate = Scratch_Org_Project_Template__c.SObjectType.getDescribe().isCreateable();
        canUpdateProjectTemplate = Scratch_Org_Project_Template__c.SObjectType.getDescribe().isUpdateable();
        if (!canCreateProjectTemplate || !canUpdateProjectTemplate) {
            addPageMessage(ApexPages.Severity.WARNING, SObjectType.Scratch_Org_Project_Template__c.label + ': ' + Label.Insufficient_Access_Rights);
            return;
        }
        resetDom();
        selectedArtifacts.add(new SelectOption(DXLabel.DEFAULT_PATH, DXLabel.DEFAULT_PATH));
        readProjectTemplate();
    }

    /**
     * @description this method uses the Static Factory pattern to retrieve an abstract instance of an Artifact entity
     * that provides all the necessary services to work with the selected type of artifact.
     * @see ArtifactFactory
     * @see AbstractArtifact
     *
     */
    private void initArtifactInstance() {
        thisArtifact = ArtifactFactory.getInstance(typeName);
        if (thisArtifact == null) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Unsupported_Metadata_Source);
        }
    }
 
    /**
     * @description this method gathers all the artifact information that has been set up by the user and turns it
     * into an actual configuration using the AbstractArtifact instance that was initialized when the component loaded.
     * Once the artifact setup is complete, a dynamic callout is sent from the selected artifact service to the
     * backend to being loading all the selected metadata sources into the target scratch org.
     *
     * @return a reference to the main DX Operations page where the backend job will be tracked by the application
     * using Copado Notifications. The user will be notified once the job ends.
     * @see AbstractArtifact
     */
    public PageReference loadMetadata() {
        String dxBranchName = getDxBranchName();
        if (
            String.isNotBlank(dxBranchName) &&
            dxBranchName.startsWith(DXLabel.PROJECT_BRANCH) &&
            selectedMetadataFormat == DXLabel.METADATA_API
        ) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Branch_Format_Is_Not_Matched + ' ' + dxBranchName);
            return null;
        }

        try {
            setArtifactParameters();
            thisArtifact.loadMetadata();
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.WARNING, ex.getMessage());
            return null;
        }

        PageReference dxOperationPage = Page.DXOperation;
        Id devHubOrgId = getDevHubOrgId();
        if (String.isNotBlank(devHubOrgId)) {
            dxOperationPage.getParameters().put('id', devHubOrgId);
        }
        dxOperationPage.setRedirect(true);
        return dxOperationPage;
    }

    /**
     * @description a method that is used by the component to reset all the controller variables when an action
     * requires it, such as when selecting a different metadata source type from the options list.
     */
    public void resetDom() {
        thisDXProject = new DXProject('', 'https://login.salesforce.com', '45.0');
        thisMetadataSource = new MetadataSource('', '', null);
        setShowTemplateButtons(true);
        selectedArtifacts = new List<SelectOption>();
        selectedArtifactIds = new List<Id>();
        selectedPackageList = new List<ArtifactVersion>();
    }

    /**
     * @description gets all the artifact information selected by the user and puts it into the AbstractArtifact
     * instance to prepare the project configuration before sending the load metadata command to the backend.
     * @see AbstractArtifact
     */
    public void setArtifactParameters() {
        if (thisArtifact == null) {
            return;
        }
        String dxBranchName = getDxBranchName();
        thisArtifact.setDxRepositoryId(getDxRepositoryId());
        thisArtifact.setScratchOrgId(getSelectedOrgIdFromDxOperation());
        thisArtifact.setDXProject(thisDxProject);
        if (thisArtifact instanceof AbstractPackage) {
            ((AbstractPackage) thisArtifact).setPackageVersions(selectedPackageList);
        } else if (thisArtifact instanceof BranchArtifact) {
            ((BranchArtifact) thisArtifact).setRepositoryId(selectedRepositoryId);
            ((BranchArtifact) thisArtifact).setDxRepositoryId(selectedRepositoryId);
            ((BranchArtifact) thisArtifact).setBranchName(dxBranchName);
            ((BranchArtifact) thisArtifact).setConvertSource(selectedMetadataFormat);
        } else if (thisArtifact instanceof PatchArtifact) {
            ((PatchArtifact) thisArtifact).setRepositoryId(selectedRepositoryId);
            ((PatchArtifact) thisArtifact).setDxRepositoryId(selectedRepositoryId);
            ((PatchArtifact) thisArtifact).setBranchName(dxBranchName);
            ((PatchArtifact) thisArtifact).setConvertSource(selectedMetadataFormat);
        }
        String sourceSelections = getSourceSelections();
        if (String.isNotBlank(sourceSelections)) {
            thisArtifact.setMetadataSource(sourceSelections);
        } else {
            if (String.isNotBlank(dxBranchName)) {
                thisArtifact.setMetadataSource(dxBranchName);
            }
        }
    }

    /**
     * @description this method is specific to the CreateUserStoryScratchOrg page. It generates all the artifact
     * directory configuration once the user is done with the artifact setup stage and clicks Next.
     * @see CreateUserStoryScratchOrgController
     */
    public void setDXProjectPackageDirectories() {
        List<ProjectArtifact> artifacts = new List<ProjectArtifact>();
        switch on typeName {
            when 'unlocked', 'managed' {
                artifacts.add(new ProjectArtifact(DXLabel.DEFAULT_PATH, true));
                for (ArtifactVersion version : selectedPackageList) {
                    Artifact_Version__c thisVersion = version.getVersion();
                    artifacts.add(new ProjectArtifact(thisVersion.Name, false));
                }
            }
            when 'artifact' {
                List<Id> artifactIds = new List<Id>();
                String sourceSelections = getSourceSelections();
                if (String.isNotBlank(sourceSelections)) {
                    artifactIds.addAll(sourceSelections.split(','));
                }
                artifacts.add(new ProjectArtifact(DXLabel.DEFAULT_PATH, true));
                try {
                    for (Artifact__c artifact : [SELECT Name FROM Artifact__c WHERE Id IN :artifactIds WITH SECURITY_ENFORCED]) {
                        artifacts.add(new ProjectArtifact(artifact.Name, false));
                    }
                } catch (QueryException queryEx) {
                    addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
                }
            }
            when 'branch' {
                String sourceBranch = ApexPages.currentPage().getParameters().get('nextStepParam');
                artifacts.add(new ProjectArtifact(sourceBranch, true));
            }
            when 'patch' {
                String sourceBranch = ApexPages.currentPage().getParameters().get('nextStepParam');
                thisMetadataSource.setIsPatch(true);
                thisMetadataSource.setSource(sourceBranch);
                setSourceSelections(sourceBranch);
                artifacts.add(new ProjectArtifact(DXLabel.DEFAULT_PATH, true));
            }
        }
        for (ProjectArtifact artifact : artifacts) {
            artifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        thisDxProject.setPackageDirectories(artifacts);
        thisDxProject.clearAliasesIfEmpty();
    }

    /**
     * @description this method generates a list of available org credential options with orgs that own at least one
     * artifact that can be loaded into the target scratch org. From the returned list, the user will be able to
     * select one or more artifacts and artifact version to load into the scratch org.
     *
     * @return a SelectOption list with org credential options.
     */
    public List<SelectOption> getOrgCredentialsWithArtifactsList() {
        List<SelectOption> orgCredentials = new List<SelectOption>();
        orgCredentials.add(new SelectOption('', Label.NONE_SELECTED));

        if (!hasAccessTo(Artifact__c.SObjectType)) {
            return orgCredentials;
        }

        String whereClauseArtifact = typeName == DXLabel.ARTIFACT ||
            typeName == DXLabel.UNLOCKPACKAGE ||
            typeName == DXLabel.SECONDGENERATIONPACKAGE
            ? ' Org_Credential__c != null AND Artifact_Repository__c != null'
            : '';
        Id recordTypeId = getArtifactRecordTypeId();
        if (String.isNotBlank(recordTypeId)) {
            whereClauseArtifact += ' AND RecordTypeId =\'' + String.escapeSingleQuotes(recordTypeId) + '\'';
        }
        if (String.isBlank(whereClauseArtifact)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Unsupported_Metadata_Source);
            return null;
        }
        try {
            Set<Id> orgIds = new Set<Id>();
            for (Artifact__c artifact : getArtifacts(whereClauseArtifact)) {
                orgIds.add(artifact.Org_Credential__c);
            }
            String whereClause = ' (Scratch_Org_Expiration_Date__c = null OR Scratch_Org_Expiration_Date__c > TODAY) AND Org_Type__c != \'Scratch Org - Test Only\'';
            for (Org__c org : getOrgCredentials(whereClause)) {
                if (orgIds.contains(org.Id)) {
                    orgCredentials.add(new SelectOption(org.Id, org.Name));
                }
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
        orgCredentials = Utilities.selectOptionSortByLabel(orgCredentials);
        return orgCredentials;
    }

    /**
     * @description a method for getting the proper Record Type Id based on the selected artifact type.
     *
     * @return the Salesforce Record Type Id of the selected Artifact__c type.
     */
    private Id getArtifactRecordTypeId() {
        Id artifactRecordTypeId;
        switch on typeName {
            when 'artifact' {
                artifactRecordTypeId = String.valueOf(SObjectType.Artifact__c.getRecordTypeInfosByName().get('Git Package').getRecordTypeId());
            }
            when 'unlocked', 'managed' {
                artifactRecordTypeId = String.valueOf(SObjectType.Artifact__c.getRecordTypeInfosByName().get('Salesforce Package').getRecordTypeId());
            }
        }
        return artifactRecordTypeId;
    }

    /**
     * @description when a source org is selected by the user from the available org options (or if the user has
     * selected an Org Definition template with a preset org in it), this method retrieves all the artifacts owned
     * by that org. This applies to Unlocked and Second-Generation Managed artifacts.
     */
    public void getOrgArtifacts() {
        ApexPages.getMessages().clear();
        artifactNameToId = new Map<String, Id>();
        artifactOptions = new List<SelectOption>();
        selectedArtifactIds = new List<Id>();
        showArtifactVersions = false;
        resetSourceSelections();

        if (String.isBlank(getSelectedOrgId())) {
            return;
        }

        switch on typeName {
            when 'unlocked', 'managed' {
                artifactOptions.add(new SelectOption('', Label.NONE_SELECTED));
            }
        }

        String whereClause = getArtifactWhereClause();

        try {
            for (Artifact__c artifact : getArtifacts(whereClause)) {
                artifactOptions.add(new SelectOption(artifact.Id, artifact.Name));
                artifactNameToId.put(artifact.Name, artifact.Id);
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }

        String metadataSourceString = String.valueOf(getMetadataSource());
        if (String.isNotBlank(metadataSourceString)) {
            thisMetadataSource = new MetadataSource(metadataSourceString, typeName, selectedRepositoryId);
            thisMetadataSource.setArtifactIds(metadataSourceString.split(','));
        }
    }

    /**
     * @description this method generates a dynamic SOQL "WHERE" clause for retrieving a list of artifacts that
     * belong to an org that was selected by the user.
     *
     * @return a string with the SOQL filter for querying Artifact__c records.
     */
    private String getArtifactWhereClause() {
        String whereClause = '';
        switch on typeName {
            when 'unlocked', 'managed', 'artifact' {
                whereClause = ' Artifact_Repository__c != null';
                String selectedOrgId = getSelectedOrgId();
                if (String.isNotBlank(selectedOrgId)) {
                    whereClause += ' AND Org_Credential__c = \'' + String.escapeSingleQuotes(selectedOrgId) + '\'';
                }
                switch on typeName {
                    when 'unlocked' {
                        whereClause += ' AND Package_Type__c = \'Unlocked\' AND Package_Id__c != null';
                    }
                    when 'managed' {
                        whereClause += ' AND Package_Type__c = \'Second-Generation Package\' AND Package_Id__c != null';
                    }
                }
            }
        }

        Id recordTypeId = getArtifactRecordTypeId();
        if (String.isNotBlank(recordTypeId)) {
            whereClause += ' AND RecordTypeId =\'' + String.escapeSingleQuotes(recordTypeId) + '\'';
        }

        return whereClause;
    }

    /**
     * @description a generic method for querying Artifact__c records by providing a SOQL "WHERE" clause.
     *
     * @param whereClause is the SOQL filter to be applied to the query.
     *
     * @return a list of Artifact__c records that were retrieved from the query.
     */
    private List<Artifact__c> getArtifacts(String whereClause) {
        return (List<Artifact__c>) Database.query(getQueryString(whereClause, 'Artifact__c', new List<String>{ 'Name', 'Org_Credential__c' }));
    }

    /**
     * @description a generic method for querying Org__c records by providing a SOQL "WHERE" clause.
     *
     * @param whereClause is the SOQL filter to be applied to the query.
     *
     * @return a list of Org__c records that were retrieved from the query.
     */
    private List<Org__c> getOrgCredentials(String whereClause) {
        return (List<Org__c>) Database.query(getQueryString(whereClause, 'Org__c', new List<String>{ 'Name' }));
    }

    /**
     * @description a generic method for generating a SOQL query string clause with all the required fields, filters
     * and security-related statements.
     *
     * @param whereClause is the SOQL filter to be applied to the query.
     * @param sObjectType is the SObject name against which the query is to be run.
     * @param fields is the list of fields that need to be retrieved for the selected SObject.
     *
     * @return a SOQL query string for the selected SObject.
     */
    private String getQueryString(String whereClause, String sObjectType, List<String> fields) {
        String queryString = 'SELECT ' + String.join(fields, ',') + ' FROM ' + sObjectType;
        if (String.isNotBlank(whereClause)) {
            queryString += ' WHERE ' + whereClause;
        }
        queryString += ' WITH SECURITY_ENFORCED';
        return queryString;
    }

    /**
     * @description this method is used to reset the Artifact Versions options list when a user selects a different
     * source artifact. When the selection changes, a new list of artifact versions is displayed for the selected
     * artifact.
     */
    public void populateArtifactVersions() {
        if (String.isNotBlank(selectedVersionId)) {
            selectedVersionId = null;
        }
        showArtifactVersions = true;
    }

    /**
     * @description this method reads a Scratch Org Project Template that was selected by the user from the database.
     * The org template contains information that will be used to generate the Scratch Org Project (sfdx-project.json)
     * file.
     */
    public void readProjectTemplate() {
        selectedTemplateId = ApexPages.currentPage().getParameters().get('templateId');
        if (String.isBlank(selectedTemplateId)) {
            selectedTemplateName = '';
            setSelectedOrgId(null);
            resetSourceSelections();
            artifactOptions = new List<SelectOption>();
            return;
        }

        try {
            Scratch_Org_Project_Template__c template = [
                SELECT
                    Name,
                    Project_JSON__c,
                    Developer_Hub_Org__c,
                    Source_Org_Credential__c,
                    Source_Metadata_Type__c,
                    Namespace__c,
                    SFDC_Login_Url__c,
                    Api_Version__c
                FROM Scratch_Org_Project_Template__c
                WHERE Id = :selectedTemplateId
                WITH SECURITY_ENFORCED
            ];
            typeName = template.Source_Metadata_Type__c;
            if (String.isBlank(typeName)) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.Unsupported_Metadata_Source);
                return;
            }
            selectType();
            selectedTemplateName = template.Name;
            if (template.Source_Org_Credential__c != null) {
                setSelectedOrgId(template.Source_Org_Credential__c);
            }

            getOrgCredentialsWithArtifactsList();
            getOrgArtifacts();
            setSelectedTemplateProjectJson(template);

            List<Id> artifactIds = new List<Id>();
            for (ProjectArtifact thisProjectArtifact : thisDXProject.getPackageDirectories()) {
                Id artifactId = artifactNameToId.get(thisProjectArtifact.getPath());
                if (String.isNotBlank(artifactId)) {
                    artifactIds.add(artifactId);
                }
            }
            thisMetadataSource = new MetadataSource(String.join(artifactIds, ','), typeName, selectedRepositoryId);
            thisMetadataSource.setArtifactIds(artifactIds);
            updateSourceSelections();
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Read_DX_Project_Template_Error + ' ' + ex.getMessage());
        }
    }

    /**
     * @description this method attempts to generate a DXProject entity from the project JSON string that is stored
     * in the Scratch Org Definition Template record. If deserialization fails, a default DXProject will be
     * initialized instead.
     *
     * @param template is the Scratch_Org_Project_Template__c record that was read when a user selected it from the
     * available template options.
     */
    private void setSelectedTemplateProjectJson(Scratch_Org_Project_Template__c template) {
        try {
            String projectJson = template.Project_JSON__c;
            projectJson = projectJson.replaceAll('"package":', '"packageName":');
            projectJson = projectJson.replaceAll('"default":', '"defaultArtifact":');
            thisDXProject = (DXProject) JSON.deserialize(projectJson, DXProject.class);
        } catch (JSONException ex) {
            thisDXProject = new DXProject(
                template.Namespace__c,
                String.isNotBlank(template.Sfdc_Login_Url__c) ? template.Sfdc_Login_Url__c : 'https://login.salesforce.com',
                String.isNotBlank(template.Api_Version__c) ? template.Api_Version__c : '45.0'
            );
        }
    }

    /**
     * @description when a user selects a different type of artifact or artifact version(s), the source selections
     * are reset and replaced by the newly selected sources.
     */
    public void updateSourceSelections() {
        resetSourceSelections();
        if (!thisMetadataSource.getArtifactIds().isEmpty()) {
            setSourceSelections(String.join(thisMetadataSource.getArtifactIds(), ','));
        } else {
            setSourceSelections(String.join(selectedArtifactIds, ','));
        }
    }

    /**
     * @description when a user types in a repository name directly into the Repository lookup field without
     * actually opening the search window, the entered repository id is not getting automatically populated by
     * Salesforce, that's why this method queries the repository's id each time a user changes the input of
     * that field on the UI and sets the corresponding id on the selectedRepositoryId variable.
     */
    public void getRepoBranches() {
        if (String.isBlank(this.selectedRepositoryId) && String.isNotBlank(this.selectedRepositoryName)) {
            try {
                List<Git_Repository__c> repositories = [
                    SELECT Id
                    FROM Git_Repository__c
                    WHERE Name = :this.selectedRepositoryName
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (!repositories.isEmpty()) {
                    this.selectedRepositoryId = repositories[0].Id;
                }
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }
        }
    }

    /**
     * @description called by the Save As Template button to insert a new Scratch_Org_Project_Template__c record into
     * the database.
     */
    public void newTemplate() {
        saveProjectTemplate(true);
    }

    /**
     * @description called by the Update Template button to update an existing Scratch_Org_Project_Template__c record
     * in the database.
     */
    public void updateTemplate() {
        saveProjectTemplate(false);
    }

    /**
     * @description saves a Scratch_Org_Project_Template__c record to the database (new or existing) holding all the
     * information entered by the user.
     *
     * @param isNew is a flag indicating if the record should be saved as a new one or be updated.
     */
    private void saveProjectTemplate(Boolean isNew) {
        if (String.isBlank(selectedTemplateName)) {
            addPageMessage(ApexPages.Severity.ERROR, Label.SOD_Template_Name_Validation);
            return;
        }
        if (String.isBlank(getSourceSelections())) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Artifact_Selection_Validation);
            return;
        }

        setArtifactParameters();
        Scratch_Org_Project_Template__c projectTemplate = createProjectTemplate();

        try {
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPSERTABLE,
                new List<Scratch_Org_Project_Template__c>{ projectTemplate }
            );
            upsert decision.getRecords();
            if (isNew) {
                selectedTemplateId = projectTemplate.Id;
            }
            addPageMessage(ApexPages.Severity.CONFIRM, Label.DX_Template_Success);
        } catch (NoAccessException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + ex.getMessage());
            return;
        }
    }

    /**
     * @description creates a Scratch_Org_Project_Template__c record for the template that the user is
     * creating/updating with all the information pulled from the component form.
     *
     * @return the Scratch_Org_Project_Template__c to insert/update.
     */
    private Scratch_Org_Project_Template__c createProjectTemplate() {
        Scratch_Org_Project_Template__c template = new Scratch_Org_Project_Template__c();
        template.Id = selectedTemplateId;
        template.Name = selectedTemplateName;
        template.Project_JSON__c = thisArtifact.generateProjectJson();
        template.Namespace__c = thisDXProject.getNamespace();
        template.Api_Version__c = thisDXProject.getSourceApiVersion();
        template.SFDC_Login_Url__c = thisDXProject.getSfdcLoginUrl();
        template.Source_Metadata_Type__c = typeName;
        Id selectedOrgId = getSelectedOrgId();
        if (String.isNotBlank(selectedOrgId)) {
            template.Source_Org_Credential__c = selectedOrgId;
        }
        return template;
    }

    /**
     * @description used for enabling or disabling the Next button on the parent page (used by
     * CreateUserStoryScratchOrg).
     *
     * @param disable is a flag indicating if the button should be disabled or not.
     */
    private void setDisableNextButton(Boolean disable) {
        if (getPageController() != null) {
            if (getPageController() instanceof CreateUserStoryScratchOrgController) {
                ((CreateUserStoryScratchOrgController) getPageController()).disableNextButton = disable;
            }
        }
    }

    /**
     * @description when the selected artifact type is Branch or Patch, a user can click on "Refresh Cache" to get the
     * latest state of the source repository and list all of its branches in the table. The command is sent to the
     * backend using one of the repository-oriented AbstractArtifact services which are BranchArtifact and PatchArtifact
     * in this case.
     *
     * @see BranchArtifact
     * @see PatchArtifact
     */
    public void refreshBranchCache() {
        switch on typeName {
            when 'branch' {
                setArtifactParameters();
                ((BranchArtifact) thisArtifact).retrieveBranchesFromRepository();
            }
            when 'patch' {
                setArtifactParameters();
                ((PatchArtifact) thisArtifact).retrieveBranchesFromRepository();
            }
            when else {
                throw new UnsupportedOperationException(Label.UnSupportedOperation);
            }
        }
    }

    /**
     * @description gets a list of available Salesforce API versions.
     *
     * @return a SelectOption list with available Salesforce API versions.
     */
    public List<SelectOption> getVersions() {
        return VersionPicklistValues.prepareSFVersionPicklist();
    }

    /**
     * @description when the selected metadata source type is Patch, the user must select a Release__c record whose
     * repository will be then set as the selected repository where the Patch branch is located.
     */
    public void setRepository() {
        selectedRepositoryId = null;
        selectedRepositoryName = '';
        if (!hasAccessTo(Release__c.SObjectType)) {
            return;
        }
        try {
            Release__c thisRelease = [
                SELECT Name, Version__c, Base_Branch__c, Project__c, Project__r.Deployment_Flow__c, Project__r.Deployment_Flow__r.Git_Repository__c
                FROM Release__c
                WHERE Id = :selectedReleaseId
                WITH SECURITY_ENFORCED
            ];

            Map<String, Boolean> errorMessageMap = new Map<String, Boolean>{
                Label.Release_Does_Not_Have_Version => String.isBlank(thisRelease.Version__c),
                Label.Selected_Release_Does_Not_Have_Branch => String.isBlank(thisRelease.Base_Branch__c),
                Label.Selected_Release_Does_Not_Have_Project => String.isBlank(thisRelease.Project__c),
                Label.Release_Project_Does_Not_Have_DF => String.isBlank(thisRelease.Project__r.Deployment_Flow__c),
                Label.Release_Has_No_Git_Related => String.isBlank(thisRelease.Project__r.Deployment_Flow__r.Git_Repository__c)
            };
            for (String message : errorMessageMap.keySet()) {
                Boolean addMessage = errorMessageMap.get(message);
                if (addMessage) {
                    addPageMessage(ApexPages.Severity.WARNING, message);
                }
            }
            selectedRepositoryId = thisRelease.Project__r.Deployment_Flow__r.Git_Repository__c;
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Release_Selection_Error + ': ' + queryEx.getMessage());
        }
    }

    /**
     * @description resets the controller parameters and initializes a new AbstractArtifact entity based on the metadata
     * source type that was selected by the user.
     *
     * @see AbstractArtifact
     */
    public void selectType() {
        String selectedType = ApexPages.currentPage().getParameters().get('typeName');
        if (String.isNotBlank(selectedType)) {
            typeName = selectedType;
        }

        selectedPackageList = new List<ArtifactVersion>();
        setSelectedOrgId(null);
        resetSourceSelections();
        initArtifactInstance();
        if (String.isNotBlank(typeName)) {
            switch on typeName {
                when 'patch', 'branch' {
                    ScratchOrgWizardPageBase pageController = getPageController();
                    if (pageController != null) {
                        if (pageController instanceof CreateUserStoryScratchOrgController) {
                            branchGridMode = 'userStoryWizard';
                        } else if (pageController instanceof DXOperationController) {
                            branchGridMode = 'dxOperations';
                        }
                    }
                    setDisableNextButton(true);
                }
                when else {
                    setDisableNextButton(false);
                }
            }
        }
    }

    /**
     * @description when a user wants to remove one of the artifact versions he selected from an Unlocked or Second
     * Generation Managed package, this method will remove that record from the artifact version list.
     */
    public void removePackage() {
        Id versionId = ApexPages.currentPage().getParameters().get('aVersion');
        if (String.isBlank(versionId)) {
            return;
        }

        Map<String, ArtifactVersion> artifactMap = new Map<String, ArtifactVersion>();
        for (ArtifactVersion version : selectedPackageList) {
            Artifact_Version__c thisVersion = version.getVersion();
            artifactMap.put(version.getOrder() + thisVersion.Name, version);
        }

        for (Integer i = 0; i < selectedPackageList.size(); i++) {
            ArtifactVersion packageVersion = selectedPackageList[i];
            Artifact_Version__c thisVersion = packageVersion.getVersion();
            if (thisVersion.Id == versionId) {
                String key = packageVersion.getOrder() + thisVersion.Name;
                artifactMap.remove(key);
                for (Integer j = 0; j < selectedPackageList.size(); j++) {
                    ArtifactVersion dependency = selectedPackageList[j];
                    if (thisVersion.Name == dependency.getIncludedBy()) {
                        Artifact_Version__c dependencyVersion = dependency.getVersion();
                        String dependencyKey = dependency.getOrder() + dependencyVersion.Name;
                        artifactMap.remove(dependencyKey);
                    }
                }
            }
        }

        selectedPackageList.clear();
        Integer newOrder = 0;
        for (ArtifactVersion version : artifactMap.values()) {
            version.setOrder(newOrder + 1);
            selectedPackageList.add(version);
            newOrder++;
        }
        artifactMap.clear();
    }

    /**
     * @description when a user selects an artifact version he wants to install in a selected scratch org, this method
     * will add that version to the artifact versions list.
     */
    public void addValuesToSelectedPackages() {
        // TODO: DO NOT ALLOW THE USER TO SELECT MORE THAN ONE VERSION FROM EACH PACKAGE
        Boolean isValidSelection = validateSelectedVersion();
        if (!isValidSelection) {
            return;
        }
        if (versionMap == null) {
            return;
        }
        Artifact_Version__c artifactVersion = versionMap.get(selectedVersionId);
        if (artifactVersion == null) {
            return;
        }

        Set<Id> artifactIds = new Set<Id>();
        artifactIds.add(artifactVersion.Artifact__c);
        thisArtifact.setArtifactId(artifactVersion.Artifact__c);
        if (thisArtifact instanceof AbstractPackage) {
            ((AbstractPackage) thisArtifact).setPackageId(artifactVersion.Artifact__r.Package_Id__c);
            setDxRepositoryId(artifactVersion.Artifact__r.Artifact_Repository__c);
        }
        Integer currentOrder = selectedPackageList.size();
        for (Artifact_Version__c thisVersion : ((AbstractPackage) thisArtifact).getPackageDependencies()) {
            ArtifactVersion newVersion = createArtifactVersion(currentOrder, artifactVersion.Name, thisVersion.Artifact__r.Name, thisVersion);
            selectedPackageList.add(newVersion);
            artifactIds.add(thisVersion.Artifact__c);
            currentOrder++;
        }
        // Main version is added the last. Dependencies must be added first. 
        ArtifactVersion version = createArtifactVersion(
            selectedPackageList.size(),
            'User Selected',
            artifactVersion.Artifact__r.Name,
            artifactVersion
        );
        selectedPackageList.add(version);
        setSourceSelections(String.join(new List<Id>(artifactIds), ','));
    }

    /**
     * @description before adding a selected artifact version to the artifact versions list, this method ensures that
     * the user is not trying to add the same artifact version twice.
     *
     * @return a flag indicating if the selected artifact version is a valid one or not.
     */
    private Boolean validateSelectedVersion() {
        Boolean success = true;
        if (String.isBlank(selectedVersionId)) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Select_valid_version);
            success = false;
        } else {
            for (ArtifactVersion packageVersion : selectedPackageList) {
                Artifact_Version__c thisVersion = packageVersion.getVersion();
                if (thisVersion.Id == selectedVersionId) {
                    String warningMessage = String.format(
                        Label.Already_selected_package,
                        new List<String>{ thisVersion.Artifact__r.Name, thisVersion.Name }
                    );
                    addPageMessage(ApexPages.Severity.WARNING, warningMessage);
                    success = false;
                }
            }
        }
        return success;
    }

    /**
     * @description this method creates an ArtifactVersion entity that will hold information about any artifact
     * version selected by the user. This information will later be appended to the DX Project JSON file as part of
     * the project that will be loaded into a target scratch org.
     *
     * @param order is the order in which artifact versions come in the project definition file (order of installation).
     * @param includedBy is the dependency by which the given artifact is being added to the DX project. It can be
     * either a manual selection by a user or an actual version dependency retrieved by the system.
     * @param artifactName is the name of the selected artifact.
     * @param thisVersion is the Artifact_Version__c record in Salesforce.
     *
     * @return a new ArtifactVersion entity ready to be included in a DX project.
     */
    private ArtifactVersion createArtifactVersion(Integer order, String includedBy, String artifactName, Artifact_Version__c thisVersion) {
        ArtifactVersion version = new ArtifactVersion(includedBy, artifactName, thisVersion);
        version.setOrder(order + 1);
        return version;
    }

    /**
     * @description clears the current source selections (be it a collection of artifact ids or a source branch) and
     * empties the sourceSelections variable.
     */
    private void resetSourceSelections() {
        setSourceSelections('');
    }

    /**
     * @description checks if the user has read access to a Salesforce Object and displays an error message otherwise.
     *
     * @param thisObjectType is the SObject type being evaluated.
     *
     * @return a flag indicating if a user has access to the given SObject type or not.
     */
    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if (!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING, thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
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