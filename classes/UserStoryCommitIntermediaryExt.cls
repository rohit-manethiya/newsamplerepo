public with sharing class   UserStoryCommitIntermediaryExt {
    public User_Story__c userStory { get; set; }
    public ApexPages.StandardController controller { get; set; }

    public List<Git_Backup__c> snapshots { get; set; }
    public Boolean showOptions { get; set; }
    public Boolean showError { get; set; }
    public Boolean showCreateDXBranchButton { get; set; }
    public String snapshotId { get; set; }
    public String repoId { get; set; }
    public String orgId { get; set; }
    public String targetPage { get; set; }
    public GlobalUtilities.deploymentFlowDetails flowDetails { get; set; }

    public String mainBranch { get; set; }

    public static final String[] FIELDS = new String[]{
            'Id', 'Name', 'Org_Credential__c', 'Environment__c', 'Org_Credential__r.Environment__c', 'Org_Credential__r.Org_Type__c', 'Base_Branch__c', 'Release__r.Base_Branch__c', 'Project__r.Deployment_Flow__r.Git_Repository__c', 'Release__r.Project__r.Deployment_Flow__r.Git_Repository__c'
    };

    public UserStoryCommitIntermediaryExt(ApexPages.StandardController stdController) {
        snapshotId = '';
        mainBranch = '';
        showOptions = false;
        showError = false;
        showCreateDXBranchButton = false;
        controller = stdController;
        targetPage = ApexPages.currentPage().getParameters().get('targetPage');
        if(!Test.isRunningTest()) {
            stdController.addFields(FIELDS);
        }
        try {
            this.userStory = [
                    SELECT Id, Name, Base_Branch__c, Release__r.Base_Branch__c, Environment__c, Org_Credential__c,
                            Project__r.Deployment_Flow__r.Git_Repository__c, Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                            Org_Credential__r.Org_Type__c
                    FROM User_Story__c
                    WHERE Id = :stdController.getId()
            ];
            getOptions();
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_USER_STORY));
        }
    }


    private void showErrorMessagesOnPage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
        showError = true;
        showOptions = false;
    }

    public void getOptions() {
        snapshots = new List<Git_Backup__c>();

        if(LicenseHelper.isLicensesExceeded()) {
            showErrorMessagesOnPage(Label.LICENSES_EXCEEDED);
            return;
        }

        if(!LicenseHelper.actionIsLicenseEnabled('commitFiles')) {
            showErrorMessagesOnPage(Label.CCM_License_Restriction);
            return;
        }

        if(!FeatureHelper.isChangeChangeManagementEnabled()) {
            showErrorMessagesOnPage(Label.FEATURE_NOT_SUPPORTED);
            return;
        }

        flowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');

        if(flowDetails.isCBMFlow) {
            // Get Main Branch of Deployment Flow
            mainBranch = flowDetails.flow.Main_Branch__c != null ? flowDetails.flow.Main_Branch__c : '';
            mainBranch = String.isNotEmpty(userStory.Base_Branch__c) ? userStory.Base_Branch__c : String.isNotEmpty(userStory.Release__r.Base_Branch__c) ? userStory.Release__r.Base_Branch__c : mainBranch;

            if(!Schema.SObjectType.Deployment_Flow__c.fields.Git_Repository__c.isAccessible() ||
                    !Schema.SObjectType.Deployment_Flow__c.fields.Main_Branch__c.isAccessible() ||
                    !Schema.SObjectType.Deployment_Flow_Step__c.fields.Branch__c.isAccessible() ||
                    !Schema.SObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.isAccessible() ||
                    !Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.isAccessible() ||
                    !Schema.SObjectType.Git_Repository__c.fields.Name.isAccessible() ||
                    !Schema.SObjectType.Git_Repository__c.fields.URI__c.isAccessible() ||
                    !Schema.SObjectType.Git_Backup__c.fields.Org__c.isAccessible() ||
                    !Schema.SObjectType.Git_Backup__c.fields.Git_Repository__c.isAccessible() ||
                    !Schema.SObjectType.Git_Backup__c.fields.Frequency__c.isAccessible() ||
                    !Schema.SObjectType.Git_Backup__c.fields.Git_Snapshot_Permissions__c.isAccessible() ||
                    !Schema.SObjectType.Git_Backup__c.fields.Branch__c.isAccessible()) {
                showErrorMessagesOnPage(Label.MISSING_PERMISSIONS_CBM_FLOW);
                return;
            }
        }

        // Check if Flow is Active
        if(flowDetails.flow == null || !flowDetails.flow.Active__c) {
            showErrorMessagesOnPage(Label.PROMOTION_FLOW_INACTIVE);
            return;
        }

        // Check if Commits are allowed
        if(flowDetails.flow != null && flowDetails.flow.Block_Commits__c) {
            showErrorMessagesOnPage(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED);
            return;
        }

        if(String.isBlank(userStory.Environment__c)) {
            showErrorMessagesOnPage(Label.USER_STORY_COMMIT_NO_ENVIRONMENT);
            return;
        }

        if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            snapshots = [
                    SELECT Id, Name, Org__c, Git_Repository__c, Git_Repository__r.Name, Org__r.Name,
                            Org__r.OwnerId, Org__r.Environment__c, Branch__c, Frequency__c, Git_Snapshot_Permissions__c
                    FROM Git_Backup__c
                    WHERE (Git_Snapshot_Permissions__c = '' OR Git_Snapshot_Permissions__c != 'Allow Snapshots Only')
                    AND Org__r.Environment__c = :userStory.Environment__c
                    AND (Git_Repository__c = :userStory.Project__r.Deployment_Flow__r.Git_Repository__c OR Git_Repository__c = :userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c)
                    LIMIT 100
            ];
        }

        if((userStory != null && snapshots.isEmpty() && userStory.Org_Credential__r.Org_Type__c == 'Scratch Org') || snapshots.isEmpty()) {
            //If no snapshot and it's Scratch Org, we look for the attachmet to see if scratch org was created from ArtifactUMP if so, we allow users to create it
            List<Attachment> attachments = new List<Attachment>();
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                attachments = [SELECT Body FROM Attachment WHERE ParentId = :userStory.Org_Credential__c AND Name = :DXLabel.METADATA_SOURCES LIMIT 1];
            }
            if(!attachments.isEmpty()) {
                Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(attachments.get(0).Body.toString());
                String mSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? String.valueOf(deserializedJsonMap.get('metadataSourceType')) : '';
                String mSource = deserializedJsonMap.containsKey('metadataSource') ? String.valueOf(deserializedJsonMap.get('metadataSource')) : '';
                if(String.isNotBlank(mSource) && String.isNotBlank(mSourceType)) {
                    showCreateDXBranchButton = true;
                    showErrorMessagesOnPage('DX Project has not been created would you like to create it?');
                    return;
                } else {
                    showErrorMessagesOnPage(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
                    return;
                }
            } else if(attachments.isEmpty() || snapshots.isEmpty()) {
                showErrorMessagesOnPage(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
                return;
            }
        }

        if(snapshots.size() == 1) {
            showError = false;
            showOptions = false;
            snapshotId = snapshots[0].Id;
            orgId = snapshots[0].Org__c;
            repoId = snapshots[0].Git_Repository__c;
            return;
        }

        if(snapshots.size() > 1) {
            showError = false;
            showOptions = true;
            return;
        }
    }

    // FL: manually fix Copado-auto-merge where 402 code wons over 438
    public String getAdditionalParams() {
        PageReference pr = new PageReference('/');
        for(String param : ApexPages.currentPage().getParameters().keySet()) {
            pr.getParameters().put(param, ApexPages.currentPage().getParameters().get(param));
        }
        pr.getParameters().remove('id');
        String pr1 = pr.getUrl().replace('/?', '').replace('/%3f', '').replace('/%3F', '');
        System.debug('pr1=' + pr1);
        return pr1.length() > 0 ? pr1 + '&' : '';
    }

    public PageReference createDXBranch() {
        String depFlowGitRepoId = '';
        Boolean repoFromProject = userStory.Project__r.Deployment_Flow__r.Git_Repository__c != null;
        Boolean repoFromRelease = userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c != null;

        depFlowGitRepoId = repoFromProject ? userStory.Project__r.Deployment_Flow__r.Git_Repository__c : repoFromRelease ? userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c : depFlowGitRepoId;

        SfdxAPI.createProjectBranch(userStory.Org_Credential__c, depFlowGitRepoId);
        return null;
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if(jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if(jobType == CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
                PageReference p = ApexPages.currentPage();
                p.getParameters().clear();
                p.getParameters().put('Id', userStory.Id);
                p.setRedirect(true);
                return p;
            }
        } else if(jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }
}