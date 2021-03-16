public with sharing class UserStoryComplianceScanController {
    public User_Story__c userStory {get; set;}
    
    public UserStoryComplianceScanController(ApexPages.StandardController std) {
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStory = [SELECT Id, Org_Credential__c, User_Story_Title__c, Project__c, Release__c, Developer__c, Status__c, Progress__c FROM User_Story__c WHERE Id = :std.getId() LIMIT 1];
        }
    }
    
    public void requestComplianceScan() {
        if(FeatureHelper.isComplianceHubEnabled()){
            if(LicenseHelper.actionIsLicenseEnabled('requestComplianceScan')){
                try {
                    DeployAPI.usComplianceScan(userStory.Org_Credential__c, userStory.Id);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.COMPLIANCE_SCAN_REQUESTED));
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__',Label.CCH_or_CCM_License)));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED+' Compliance Hub'));
        }
    }
}