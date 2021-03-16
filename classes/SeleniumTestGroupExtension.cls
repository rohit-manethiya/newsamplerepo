public with sharing class SeleniumTestGroupExtension {
    public Selenium_Test_Group__c grp { get; set; }
    public SeleniumTestGroupExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Group__c.fields.getMap().keySet()));

        this.grp = (Selenium_Test_Group__c) stdController.getRecord();
    }
    public PageReference runGroup() {
        try {
            if(Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                if([SELECT Id FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :grp.Id].size() == 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MissingGroupRecord));
                    return null;
                } else {
                    WebhookAPI.runSeleniumTestGroup(grp.Id, DeployAPI.getUserAPIKey());
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Run__c.label);
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return new PageReference('/' + grp.Id);
    }
}