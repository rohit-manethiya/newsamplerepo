public with sharing class SeleniumTestRunResults {
    public Selenium_Test_Run__c obj {get; set;}
	public List<Selenium_Test_Result__c> lastResults {get; set;}
	public Integer count_all {get; set;}
	public Integer count_finished {get; set;}
	public Integer count_errors {get; set;}
    private ApexPages.StandardController stdController;

    public SeleniumTestRunResults(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Run__c.fields.getMap().keySet()));
        refreshRunningData();
    }

    public PageReference refreshRunningData() {
        this.obj = (Selenium_Test_Run__c)stdController.getRecord();
        this.lastResults = new List<Selenium_Test_Result__c>();
        this.count_all = 0;
        this.count_finished = 0;
        this.count_errors = 0;

        if(this.obj.Id!=null) {
            Integer Batch_No;
            if(Schema.sObjectType.Selenium_Test_Run__c.isQueryable() && Schema.sObjectType.Selenium_Test_Run__c.isAccessible()) {
                this.obj = [SELECT Id, Name, Batch_No__c, Last_Status__c FROM Selenium_Test_Run__c WHERE Id = :this.obj.Id];
                Batch_No = Integer.valueOf(this.obj.Batch_No__c)-1;
                if(Schema.sObjectType.Selenium_Test_Result__c.isQueryable() && Schema.sObjectType.Selenium_Test_Result__c.isAccessible()) {
                    this.lastResults = [SELECT Id, Name, Platform__c, Status__c FROM Selenium_Test_Result__c WHERE Selenium_Test_Run__c = :this.obj.Id AND Batch_No__c = :Batch_No ORDER BY CreatedDate LIMIT 10];
                    for (Selenium_Test_Result__c a : this.lastResults) {
                        this.count_all += 1;
                        this.count_finished += a.Status__c.startsWith('Completed') ? 1 : 0;
                        this.count_finished += a.Status__c.startsWith('Fail') ? 1 : 0;
                        this.count_errors += a.Status__c.contains('error') || a.Status__c.contains('Fail') ? 1 : 0;
                    }
                }
            }
        }
        System.debug(this.obj);
        return null;
    }

    public class ReportWrapper{
        public String name {get;set;}
        public String selenese {get;set;}

        public ReportWrapper(String n, String s){
            this.name = n;
            this.selenese = s;
        }
    }

    public List<ReportWrapper> getReports() {
        List<ReportWrapper> reports = new List<ReportWrapper>();
    	if(this.obj.Id!=null) {
	    	//Integer Batch_No = Integer.valueOf(this.obj.Batch_No__c)-1;
            Integer Batch_No = 0;
            if(Schema.sObjectType.Selenium_Test_Result__c.isQueryable() && Schema.sObjectType.Selenium_Test_Result__c.isAccessible()) {
                for (List<aggregateResult> ts : [SELECT MAX(Batch_No__c) batch FROM Selenium_Test_Result__c WHERE Selenium_Test_Run__c = :this.obj.Id]) {
                    for (AggregateResult t : ts) {
                        System.debug('-' + t);
                        Batch_No = Integer.valueOf(t.get('batch'));
                    }
                }
            }

            Map<Id,Selenium_Test_Result__c> rMap = new Map<Id,Selenium_Test_Result__c>();
            if(Schema.sObjectType.Selenium_Test_Result__c.isQueryable() && Schema.sObjectType.Selenium_Test_Result__c.isAccessible()) {
                rMap = new Map<Id, Selenium_Test_Result__c>([SELECT Id, Platform__c FROM Selenium_Test_Result__c WHERE Selenium_Test_Run__c = :this.obj.Id AND Batch_No__c = :Batch_No ORDER BY CreatedDate LIMIT 10]);
            }

            if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                for (Attachment a : [SELECT Id, Name, Body, Parent.Name FROM Attachment WHERE ParentId in :rMap.keySet() AND Name LIKE 'Selenese%.html' ORDER BY CreatedDate DESC LIMIT 10]) {
                    if (rMap.get(a.ParentId) != null) {
                        reports.add(new ReportWrapper(rMap.get(a.ParentId).Platform__c, a.Body.toString()));
                        rMap.remove(a.ParentId);
                    }
                }
            }
        }
        // reverse the list order, so we preserve the platform selection order.
        List<ReportWrapper> reports1 = new List<ReportWrapper>();
        for(Integer i=reports.size()-1; i>=0 ; i--) {
            reports1.add(reports.get(i));
        }
        return reports1;
	}
}