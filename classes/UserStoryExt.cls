public with sharing class UserStoryExt {
    public User_Story__c userStory { get; set; }
    public String userStoriesAheadBehindTitle { get; set; }
    private String namespace;

    public UserStoryExt(ApexPages.StandardController stdController) {
        isLicenseAndFeatureEnabled();
        namespace = Settings.ns;
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>{
                    namespace + 'Base_Branch__c', namespace + 'Project__r.' + namespace + 'Deployment_Flow__c', namespace + 'Release__r.' + namespace + 'Project__r.' + namespace + 'Deployment_Flow__c', namespace + 'Release__r.' + namespace + 'Base_Branch__c', namespace + 'Environment__r.Name', namespace + 'Org_Credential__r.' + namespace + 'Org_Type__c'
            });
        }
        this.userStory = (User_Story__c) stdController.getRecord();
        if(userStory != null && userStory.Id != null) {
            checkForLastCommitNoChanges(userStory.Id);
        }
    }

    public void isLicenseAndFeatureEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewUserStoryPage')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCM_or_CAD_License)));
        }
        if(!FeatureHelper.isChangeChangeManagementEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Change_Management_Feature_Not_Enabled));
        }
        return;
    }

    public List<GlobalUtilities.flowStepWrapper> getDeploymentFlowSteps() {
        List<GlobalUtilities.flowStepWrapper> visualFlowSteps = GlobalUtilities.getDeploymentFlowSteps(userStory);
        userStoriesAheadBehindTitle = GlobalUtilities.userStoriesAheadBehindTitle;
        if(visualFlowSteps.isEmpty() && String.isNotBlank(userStory.Org_Credential__c) && String.isNotBlank(userStory.Project__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Org_Credential_Not_Included_In_Deployment_Flow));
        }
        return visualFlowSteps;
    }

    private void checkForLastCommitNoChanges(Id usId) {
        if(Schema.SObjectType.User_Story_Commit__c.isAccessible() && Schema.SObjectType.User_Story_Commit__c.isQueryable()) {
            List<User_Story_Commit__c> commits = [SELECT Id, Snapshot_Commit__r.Status__c FROM User_Story_Commit__c WHERE User_Story__c = :usId ORDER BY Snapshot_Commit__r.Commit_Date__c DESC LIMIT 1];
            if(!commits.isEmpty()) {
                if(commits[0].Snapshot_Commit__r.Status__c == 'No changes') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.COMMIT_NO_CHANGES));
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Commit__c.label);
        }

    }

}