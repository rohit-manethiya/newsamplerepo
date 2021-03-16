public with sharing class SeleniumTestResult {
    ApexPages.StandardController sc = null;
    public SeleniumTestResult(ApexPages.StandardController stdController)  { 
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Result__c.fields.getMap().keySet()));
       sc = stdController;
    } 
      
    public String fileBody {
        get {
            Selenium_Test_Result__c r = (Selenium_Test_Result__c)sc.getRecord();
            if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                for (Attachment a : [SELECT id, body, name FROM Attachment WHERE ParentId = :r.id AND Name LIKE 'Selenese%.html' ORDER BY CreatedDate DESC LIMIT 1]) {
                    return a.body.toString();
                }
            }
            return '(no data to display)';
        }
    }
}