public with sharing class DXOperationController extends ScratchOrgWizardPageBase {
    public Map<String, String> actionMap { get; set; }
    public Map<String, String> actionDetailMap { get; set; }
    public String selectedAction { get; set; }
    public String selectedOperation { get; set; }
    public String selectedOrgId { get; set; }
    public String dxDeploymentFlowMode { get; set; }
    public String dxDeploymentFlowGitRepo { get; set; }
    public String dxBranchName { get; set; }
    public Boolean enableActions { get; set; }
    public Boolean disableOperationPicklist { get; set; }
    public Boolean disableLoadMetadataPanel { get; set; }
    public Boolean disablePanels { get; set; }
    public Boolean showSchedule { get; set; }
    public Artifact__c newArtifact { get; set; }
    public List<SelectOption> orgCredentialOptions { get; set; }
    public List<SelectOption> operationOptions { get; set; }
    public transient List<Git_Org_Commit__c> snapshotCommits { get; set; }
    public transient List<User_Story_Commit__c> userStoryCommits { get; set; }
    public transient List<Artifact__c> artifacts { get; set; }
    public transient List<Scratch_Org_Definition__c> orgDefinitionTemplates { get; set; }
    public transient List<Scratch_Org_Project_Template__c> projectTemplates { get; set; }
    public List<Org__c> activeScratchOrgs { get; set; }
    public List<Org__c> deletedScratchOrgs { get; set; }
    public Object metadataSourceType { get; set; }
    public Object metadataSource { get; set; }
    public UserStoryInfoWrapper userStoryInfo { get; set; }

    public DXOperationController() {
        initDefaults();

        String recordId = ApexPages.currentPage().getParameters().get('id');
        if (String.isNotBlank(recordId)) {
            initRecord(recordId);
            getOperationActions();
            if (selectedOperation != '0') {
                disableOperationPicklist = true;
            }
        } else {
            initOperationOptions();
        }
        enableSelectedPanels();
    }

    private void initDefaults() {
        selectedOperation = '0';
        userStoryInfo = new UserStoryInfoWrapper();
        disableOperationPicklist = false;
        disableLoadMetadataPanel = false;
        disablePanels = false;
        newArtifact = new Artifact__c();
        orgCredentialOptions = new List<SelectOption>();
        //False positive for CronTrigger?
        showSchedule = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'Copado DX Schedulable'] == 0;
    }

    private void initRecord(String recordId) {
        String objectAPIName = ((Id) recordId).getSobjectType().getDescribe().getName();
        if (objectAPIName == Org__c.SObjectType.getDescribe().getName()) {
            selectedOrgId = recordId;
            initOrgCredentialDefaults();
        } else if (objectAPIName == User_Story__c.SObjectType.getDescribe().getName()) {
            userStoryInfo.usId = recordId;
            initUserStoryDefaults();
        }
    }

    private void initOrgCredentialDefaults() {
        if (!hasAccessTo(Org__c.SObjectType)) {
            // Not removed to avoid call getOrgWhereClause if it is not needed
            return;
        }
        initOrgCredential();
    }

    private void initUserStoryDefaults() {
        if (!dxIsEnabledOnPipeline()) {
            return;
        }
        selectedOperation = '3';
    }

    public void loadSubmenu() {
        enableActions = false;
        selectedOrgId = null;
        userStoryInfo = new UserStoryInfoWrapper();
        actionMap = new Map<String, String>();
        actionDetailMap = new Map<String, String>();

        switch on selectedOperation {
            when '1', '2' {
                initOrgCredentialOptions();
            }
            when '4' {
                getPlanningOperationActions();
                enableActions = true;
            }
        }
    }

    public void getOperationActions() {
        enableActions = false;
        actionMap = new Map<String, String>();
        actionDetailMap = new Map<String, String>();

        switch on selectedOperation {
            when '1' {
                getScratchOrgActions();
                getAdditionalActionsFor(Git_Org_Commit__c.SObjectType);
                if (String.isNotBlank(selectedOrgId)) {
                    enableActions = true;
                }
            }
            when '2' {
                getDevHubActions();
                if (String.isNotBlank(selectedOrgId)) {
                    enableActions = true;
                }
            }
            when '3' {
                if (!dxIsEnabledOnPipeline()) {
                    return;
                }
                setCurrentUserStory();
                getUserStoryActions();
                getAdditionalActionsFor(User_Story_Commit__c.SObjectType);
                enableActions = true;
            }
        }
    }

    private void getScratchOrgActions() {
        if (String.isBlank(selectedOrgId)) {
            return;
        }
        if (hasAccessTo(Git_Repository__c.SObjectType)) {
            addAction(Label.DXOperation_OrgStatus, 'gsos', Label.Org_Status_Detail);
        }
    }

    private void getDevHubActions() {
        if (String.isBlank(selectedOrgId)) {
            return;
        }
        addAction(Label.DXOperation_CreateSO, 'cso', Label.Create_Scratch_Org_Detail);
        addAction(Label.DXOperation_ManageSOs, 'mso', Label.Manage_Scratch_Org_Detail);
    }

    private void setCurrentUserStory() {
        //Not reported by sonarqube
        try {
            List<User_Story__c> userStories = [
                SELECT Org_Credential__c, Org_Credential__r.Org_Type__c, Org_Credential__r.Name
                FROM User_Story__c
                WHERE Id = :userStoryInfo.usId AND Org_Credential__c != null AND Org_Credential__r.Org_Type__c = 'Scratch Org'
                WITH SECURITY_ENFORCED
            ];

            if (!userStories.isEmpty()) {
                User_Story__c thisUserStory = userStories[0];
                userStoryInfo.usOrgName = thisUserStory.Org_Credential__r.Name;
                userStoryInfo.usOrgId = thisUserStory.Org_Credential__c;
                selectedOrgId = thisUserStory.Org_Credential__c;
            }
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, User_Story__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    private void getUserStoryActions() {
        addAction(Label.DXOperation_CreateSO, 'csous', Label.Create_Scratch_Org_Detail);
    }

    private void getPlanningOperationActions() {
        addAction(Label.DXOperation_ManageDefinitionTemplate, 'mdt', Label.Definition_Template_Detail);
        addAction(Label.DXOperation_ManageProjectTemplate, 'mpt', Label.Project_Template_Details);
        if (hasAccessTo(Artifact__c.SObjectType)) {
            addAction(Label.DXOperation_ManageArtifacts, 'ma', Label.Artifacts_Detail);
        }
    }

    private void getAdditionalActionsFor(SObjectType thisObjectType) {
        if (hasAccessTo(thisObjectType)) {
            addAction(Label.DXOperation_CommitHistory, 'ch', Label.Commit_History_Detail);
            addAction(Label.DXOperation_LoadData, 'ld', Label.Optional_Configuration_Detail);
            addAction(Label.DXOperation_LoadMetadata, 'lm', Label.Load_Metadata_Detail);
        }
    }

    private void addAction(String name, String key, String description) {
        actionMap.put(name, key);
        actionDetailMap.put(name, description);
    }

    public void initOperationOptions() {
        operationOptions = new List<SelectOption>();
        operationOptions.add(new SelectOption('0', Label.NONE_SELECTED));
        if (hasAccessTo(Org__c.SObjectType)) {
            operationOptions.add(new SelectOption('1', Label.DXOperationType_ScratchOrg));
            operationOptions.add(new SelectOption('2', Label.DXOperationType_DevHub));
        }
        if (hasAccessTo(User_Story__c.SObjectType)) {
            operationOptions.add(new SelectOption('3', Label.DXOperationType_US));
        }
        operationOptions.add(new SelectOption('4', Label.DXOperationType_Planning));
    }

    public void initOrgCredentialOptions() {
        resetOrgLists();
        String operation = selectedOperation;
        orgCredentialOptions.add(new SelectOption('', Label.NONE_SELECTED));
        if (!hasAccessTo(Org__c.SObjectType)) {
            // Not removed to avoid call getOrgWhereClause if it is not needed
            return;
        }
        String whereClause = getOrgWhereClause(selectedOperation);
        List<Org__c> orgCredentials;
        try {
            orgCredentials = getOrgCredentials(whereClause);
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            return;
        }
        if (operation == '2') {
            if (selectedAction == 'mso') {
                for (Org__c org : orgCredentials) {
                    if (org.Org_Type__c == 'Scratch Org' || org.Org_Type__c == 'Scratch Org - Test Only') {
                        switch on org.Scratch_Org_Status__c {
                            when 'Active' {
                                activeScratchOrgs.add(org);
                            }
                            when 'Deleted' {
                                deletedScratchOrgs.add(org);
                            }
                        }
                    }
                }
            }
        }

        List<SelectOption> options = new List<SelectOption>();
        for (Org__c org : orgCredentials) {
            Boolean addOption = false;
            switch on operation {
                when '1' {
                    addOption = org.Org_Type__c == 'Scratch Org';
                }
                when '2' {
                    addOption = org.is_Developer_Hub_Org__c;
                }
                when '4' {
                    addOption = selectedAction == 'ma';
                }
            }
            if (addOption) {
                options.add(new SelectOption(org.Id, org.Name));
            }
        }
        orgCredentialOptions.addAll(Utilities.selectOptionSortByLabel(options));
    }

    private void resetOrgLists() {
        activeScratchOrgs = new List<Org__c>();
        deletedScratchOrgs = new List<Org__c>();
        orgCredentialOptions = new List<SelectOption>();
    }

    private void initOrgCredential() {
        String whereClause = getOrgWhereClause(selectedOperation);
        List<Org__c> orgCredentials;
        try {
            orgCredentials = getOrgCredentials(whereClause);
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            return;
        }
        if (!orgCredentials.isEmpty()) {
            Org__c thisOrg = orgCredentials[0];
            switch on thisOrg.Org_Type__c {
                when 'Scratch Org', 'Scratch Org - Test Only' {
                    selectedOperation = '1';
                }
                when else {
                    if (thisOrg.is_Developer_Hub_Org__c) {
                        selectedOperation = '2';
                    } else {
                        addPageMessage(ApexPages.Severity.WARNING,Label.Scratch_Org_Operation_Expired_Warning + 'project/DX-' + selectedOrgId.substring(3, 15));
                        disablePanels = true;
                        return;
                    }
                }
            }
            orgCredentialOptions.add(new SelectOption(thisOrg.Id, thisOrg.Name));
        } else {
            addPageMessage(ApexPages.Severity.WARNING, Label.Scratch_Org_Operation_Expired_Warning + 'project/DX-' + selectedOrgId.substring(3, 15));
        }
    }

    private String getOrgWhereClause(String operation) {
        String whereClause = '';
        if (operation == '0' || operation == '1' || operation == '2') {
            String formattedDate = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            whereClause += ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > ' + formattedDate + ')';
            switch on operation {
                when '0' {
                    if (String.isNotBlank(selectedOrgId)) {
                        whereClause += ' AND Id =\'' + String.escapeSingleQuotes(selectedOrgId) + '\'';
                    }
                }
                when '2' {
                    if (selectedAction == 'mso') {
                        if (String.isNotBlank(selectedOrgId)) {
                            whereClause +=
                                ' AND Developer_Hub_Org__c =\'' +
                                String.escapeSingleQuotes(selectedOrgId) +
                                '\' AND Scratch_Org_Status__c != null';
                        }
                    }
                }
                when else {
                    whereClause += ' AND Org_Type__c != \'Scratch Org - Test Only\'';
                }
            }
        }
        return whereClause;
    }

    private List<Org__c> getOrgCredentials(String whereClause) {
        String queryString = 'SELECT Name, Org_Type__c, Is_Developer_Hub_Org__c, Scratch_Org_Status__c, Username__c, OwnerId, Scratch_Org_Expiration_Date__c, CreatedById FROM Org__c';
        if (String.isNotBlank(whereClause)) {
            queryString += ' WHERE ' + whereClause + ' WITH SECURITY_ENFORCED';
        }
        return Database.query(queryString);
    }

    public PageReference enableSelectedPanels() {
        if (String.isBlank(selectedAction)) {
            selectedAction = ApexPages.currentPage().getParameters().get('actionName');
        }

        switch on selectedAction {
            when 'ch' {
                retrieveCommits();
            }
            when 'mso', 'ma' {
                initOrgCredentialOptions();
            }
            when 'mdt' {
                selectedOrgId = null;
                retrieveDefinitionTemplates();
            }
            when 'mpt' {
                selectedOrgId = null;
                retrieveProjectTemplates();
            }
            when 'csous' {
                List<User_Story__c> userStories = [
                    SELECT Org_Credential__c
                    FROM User_Story__c
                    WHERE Id = :userStoryInfo.usId AND Org_Credential__c != null
                ];
                if (!userStories.isEmpty()) {
                    User_Story__c thisUserStory = userStories[0];
                    addPageMessage(ApexPages.Severity.WARNING, Label.DX_US_ALREADY_HAS_AN_ORG);
                    return redirectTo(Page.CreateUserStoryScratchOrg, thisUserStory.Id);
                }
            }
            when 'lm' {
                loadMetadataSources();
            }
        }
        return null;
    }

    private void retrieveCommits() {
        if (String.isNotBlank(userStoryInfo.usId)) {
            retrieveUserStoryCommits();
        } else if (String.isNotBlank(selectedOrgId)) {
            retrieveSnapshotCommits();
        }
    }

    private void retrieveUserStoryCommits() {
        userStoryCommits = new List<User_Story_Commit__c>();
        try {
            userStoryCommits = [
                SELECT Name, Snapshot_Commit__c, View_in_Git__c
                FROM User_Story_Commit__c
                WHERE User_Story__c = :userStoryInfo.usId
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR,User_Story_Commit__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    private void retrieveSnapshotCommits() {
        snapshotCommits = new List<Git_Org_Commit__c>();
        try {
            snapshotCommits = [
                SELECT Name, Git_Operation__c, Commit_Date__c, Commit_Message__c, Git_Backup__c, Status__c, View_in_Git__c
                FROM Git_Org_Commit__c
                WHERE Org__c = :selectedOrgId
                WITH SECURITY_ENFORCED
                ORDER BY Commit_Date__c DESC
                LIMIT 10
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR,Git_Org_Commit__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    public void retrieveArtifacts() {
        artifacts = new List<Artifact__c>();
        try {
            artifacts = [
                SELECT Name, Description__c, Org_Credential__c, Artifact_Repository__c, RecordTypeId, RecordType.Name, Package_Type__c
                FROM Artifact__c
                WHERE Org_Credential__c = :selectedOrgId
                WITH SECURITY_ENFORCED
                LIMIT 999
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Artifact__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    public void retrieveDefinitionTemplates() {
        orgDefinitionTemplates = new List<Scratch_Org_Definition__c>();
        try {
            orgDefinitionTemplates = [
                SELECT Name, Developer_Hub_Org__c, Duration_in_days__c
                FROM Scratch_Org_Definition__c
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1000
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR,Scratch_Org_Definition__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    public void retrieveProjectTemplates() {
        projectTemplates = new List<Scratch_Org_Project_Template__c>();
        try {
            projectTemplates = [
                SELECT Name, Api_Version__c, Namespace__c, SFDC_Login_Url__c, Source_Org_Credential__c
                FROM Scratch_Org_Project_Template__c
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1000
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR,Scratch_Org_Project_Template__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
    }

    private PageReference redirectTo(PageReference thisPage, String recordId) {
        if (String.isNotBlank(recordId)) {
            thisPage.getParameters().put('id', recordId);
        }
        thisPage.setRedirect(true);
        return thisPage;
    }

    private void loadMetadataSources() { 
        List<Attachment> attachments = new List<Attachment>();
        if (String.isNotBlank(selectedOrgId)) {
            if (hasAccessTo(Attachment.SObjectType)) {
                attachments = getAttachmentsByParent(selectedOrgId);
            }
            String environmentId;
            try {
                environmentId = [SELECT Environment__c FROM Org__c WHERE Id = :selectedOrgId WITH SECURITY_ENFORCED].Environment__c;
            } catch (System.QueryException ex) {
                addPageMessage(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            }
            if (String.isNotBlank(environmentId)) {
                List<Deployment_Flow_Step__c> flowSteps = new List<Deployment_Flow_Step__c>();
                try {
                    flowSteps = [
                        SELECT Deployment_Flow__r.Git_Repository__c, Deployment_Flow__r.Copado_DX_Mode__c
                        FROM Deployment_Flow_Step__c
                        WHERE Source_Environment__c = :environmentId
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                    ];
                } catch (System.QueryException ex) {
                    addPageMessage(ApexPages.Severity.ERROR,Deployment_Flow_Step__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
                }
                if (!flowSteps.isEmpty()) {
                    Deployment_Flow_Step__c thisStep = flowSteps[0];
                    dxDeploymentFlowMode = thisStep.Deployment_Flow__r.Copado_DX_Mode__c;
                    dxDeploymentFlowGitRepo = thisStep.Deployment_Flow__r.Git_Repository__c;
                }
            }
        } else if (String.isNotBlank(userStoryInfo.usId)) {
            List<User_Story__c> userStories;
            try {
                userStories = [
                    SELECT Org_Credential__c, Org_Credential__r.Org_Type__c
                    FROM User_Story__c
                    WHERE Id = :userStoryInfo.usId AND Org_Credential__c != null
                    WITH SECURITY_ENFORCED
                ];
            } catch (System.QueryException ex) {
                addPageMessage(ApexPages.Severity.ERROR,User_Story__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            }
            if (!userStories.isEmpty()) {
                User_Story__c thisUserStory = userStories[0];
                selectedOrgId = thisUserStory.Org_Credential__c;
                String orgType = thisUserStory.Org_Credential__r.Org_Type__c;
                if (String.isNotBlank(orgType) && orgType != 'Scratch Org' && orgType != 'Scratch Org - Test Only') {
                    addPageMessage(ApexPages.Severity.WARNING, Label.Scratch_Org_Selection_Validation);
                    disableLoadMetadataPanel = true;
                } else {
                    attachments = getAttachmentsByParent(selectedOrgId);
                }
            }
        }

        if (!attachments.isEmpty()) {
            loadMetadataFromAttachment(attachments);
        }
    }

    private List<Attachment> getAttachmentsByParent(Id parentId) {
        List<Attachment> attachments = new List<Attachment>();
        try {
            attachments = [
                SELECT Body
                FROM Attachment
                WHERE ParentId = :parentId AND Name LIKE '%metadataSources%'
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Attachment.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return attachments;
    }

    private void loadMetadataFromAttachment(List<Attachment> attachments) {
        Map<String, Object> metadataSourceMap = (Map<String, Object>) JSON.deserializeUntyped(attachments.get(0).Body.toString());
        if (metadataSourceMap == null) {
            return;
        }
        metadataSource = metadataSourceMap.get('metadataSource');
        metadataSourceType = metadataSourceMap.get('metadataSourceType');
        if (metadataSourceType == DXLabel.BRANCH) {
            String orgName;

            if (String.isNotBlank(selectedOrgId)) {
                try {
                    orgName = [SELECT Name FROM Org__c WHERE Id = :selectedOrgId WITH SECURITY_ENFORCED].Name;
                } catch (System.QueryException ex) {
                    addPageMessage(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
                }
            } else {
                orgName = Label.DX_Operation_Load_Warning_Message1;
            }
            String eMessages = orgName + Label.DX_Operation_Load_Warning_Message2 + metadataSource + DXLabel.BRANCH + Label.DX_Operation_Load_Warning_Message3;
            addPageMessage(ApexPages.Severity.WARNING, eMessages);
            disableLoadMetadataPanel = true;
        }
    }

    public PageReference jobStatusNotification() {
        Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
        Boolean jobFinished = pageParameters.get('jobFinished') == 'true';

        if (jobFinished) {
            Boolean jobSuccess = pageParameters.get('jobSuccess') == 'true';
            if (jobSuccess) {
                String jobType = pageParameters.get('jobType');
                if (String.isNotBlank(jobType)) {
                    if (jobType == DXLabel.CREATE_ORG) {
                        addPageMessage(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success);
                    } else if (jobType == DXLabel.LOAD_METADATA) {
                        addPageMessage(ApexPages.Severity.CONFIRM, Label.Load_Metadata_Success);
                    } else if (jobType == DXLabel.ORG_IDE_DETAILS) {
                        addPageMessage(ApexPages.Severity.CONFIRM, Label.Password_Success);
                    } else if (jobType == DXLabel.DELETE_ORG) {
                        return redirectTo(Page.DXOperation, null);
                    }
                }
            } else {
                String jobMessage = pageParameters.get('jobMessage');
                if (String.isNotBlank(jobMessage)) {
                    addPageMessage(ApexPages.Severity.ERROR, jobMessage);
                }
            }
        }
        return null;
    }

    public void setBranchName() {
        dxBranchName = ApexPages.currentPage().getParameters().get('branchName');
    }

    public void scheduleDxJob() {
        if (showSchedule) {
            System.schedule(SfdxSchedulable.JOB_NAME, SfdxSchedulable.CRON_EXP, new SfdxSchedulable());
            showSchedule = false;
        }
    }

    private Boolean dxIsEnabledOnPipeline() {
        Boolean isEnabled = true;
        Deployment_Flow__c thisPipeline = getUserStoryPipeline();
        if (thisPipeline == null) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DX_NO_US_FLOW);
            isEnabled = false;
        } else if (!thisPipeline.Enable_Copado_DX__c) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DX_NOT_ENABLED_DF);
            isEnabled = false;
        } else if (thisPipeline.Deployment_Flow_Steps__r.isEmpty()) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DF_HAS_NO_DX_TARGET);
            isEnabled = false;
        }
        if (!isEnabled) {
            disablePanels = true;
        }
        return isEnabled;
    }

    private Deployment_Flow__c getUserStoryPipeline() {
        User_Story__c thisUserStory = new User_Story__c();
        List<User_Story__c> userStories = new List<User_Story__c>();
        try {
            userStories = [
                SELECT Name, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM User_Story__c
                WHERE Id = :userStoryInfo.usId
                WITH SECURITY_ENFORCED
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, User_Story__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        if (!userStories.isEmpty()) {
            thisUserStory = userStories[0];
            userStoryInfo.usName = thisUserStory.Name;
        }

        String pipelineId;
        if (thisUserStory.Project__r.Deployment_Flow__c != null) {
            pipelineId = thisUserStory.Project__r.Deployment_Flow__c;
        } else if (thisUserStory.Release__r.Project__r.Deployment_Flow__c != null) {
            pipelineId = thisUserStory.Release__r.Project__r.Deployment_Flow__c;
        }
        Deployment_Flow__c thisPipeline;
        try {
            List<Deployment_Flow__c> pipelines = [
                SELECT
                    Enable_Copado_DX__c,
                    Copado_DX_Mode__c,
                    (SELECT Id FROM Deployment_Flow_Steps__r WHERE Enable_as_Scratch_Org_Destination__c != null)
                FROM Deployment_Flow__c
                WHERE Id = :pipelineId
                WITH SECURITY_ENFORCED
            ];
            if (!pipelines.isEmpty()) {
                thisPipeline = pipelines[0];
            }
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR,Deployment_Flow__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }

        return thisPipeline;
    }

    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if (!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING, thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    public with sharing class UserStoryInfoWrapper {
        public String usName { get; set; }
        public String usId { get; set; }
        public String usOrgName { get; set; }
        public String usOrgId { get; set; }
    }
}