public with sharing class UserStoryCodeAnalysisRequestController {
    public User_Story__c userStory {get; set;}
    
    public UserStoryCodeAnalysisRequestController(ApexPages.StandardController std) {
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStory = [SELECT Id, Org_Credential__c, User_Story_Title__c, Project__c, Release__c, Developer__c, Status__c, Progress__c FROM User_Story__c WHERE Id = :std.getId() LIMIT 1];
        }
    }
    
    public void requestCodeScan() {
        try {
            if(LicenseHelper.actionIsLicenseEnabled('requestStaticCodeAnalysis')){
                DeployAPI.usCodeAnalysis(userStory.Org_Credential__c, userStory.Id);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.USER_STORY_ANALYSIS_REQUESTED));
            } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_License_Restriction));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
}