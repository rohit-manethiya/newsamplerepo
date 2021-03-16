public with sharing class MassAddRunsToGroup {

    public List<Selenium_Test_Run__c> runs;
    public AuxiliaryObject__c dummy { get; set; }
    public ApexPages.StandardSetController con;

    public MassAddRunsToGroup(ApexPages.StandardSetController std) {
        con = std;
        runs = (List<Selenium_Test_Run__c>) std.getSelected();
        System.debug('MassAddRunsToGroup selected... ' + runs.size());
        dummy = new AuxiliaryObject__c ();
    }

    public PageReference cancel() {
        return con.cancel();
    }

    public PageReference addTestRunsToGroup() {
        List<Selenium_Test_Run__c> seleniumTestRunList = new List<Selenium_Test_Run__c>();
        if(!Schema.SObjectType.Selenium_Test_Run__c.fields.Selenium_Test_Group__c.isUpdateable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.SObjectType.Selenium_Test_Run__c.label + ': ' + Label.Insufficient_Access_Rights));
            return null;
        }
        for(Selenium_Test_Run__c str : runs) {
            seleniumTestRunList.add(new Selenium_Test_Run__c(Id = str.Id, Selenium_Test_Group__c = dummy.Selenium_Test_Group__c));
        }
        System.debug('MassAddRunsToGroup updating... ' + seleniumTestRunList.size());
        if(!seleniumTestRunList.isEmpty()) {
            Database.SaveResult[] res = null;
            if(Schema.SObjectType.Selenium_Test_Run__c.isUpdateable()) {
                res = Database.update(seleniumTestRunList, false);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.SObjectType.Selenium_Test_Run__c.label + ': ' + Label.Insufficient_Access_Rights));
                return null;
            }

            Boolean hasError = false;
            for(Database.SaveResult sr : res) {
                if(!sr.isSuccess()) {
                    hasError = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sr.getErrors()[0].getMessage()));
                }
            }

            if(hasError){
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.SELECT_AT_LEAST_ONE_RECORD));
            return null;
        }
        return new PageReference('/' + dummy.Selenium_Test_Group__c);
    }
}