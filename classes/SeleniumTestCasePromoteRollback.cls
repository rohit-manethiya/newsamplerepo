public with sharing class SeleniumTestCasePromoteRollback {
    public ApexPages.StandardController controller;
	Selenium_Test_Case__c tc;
    public List<TestCaseVersion> testCasePerSuite {get;set;}
    public boolean isPromote {get;set;}
    public Id testCaseIdToLookup {get;set;} // id of the testcase or its parent.
    public Selenium_Test_Case__c testCaseToUpdate {get;set;}
    public boolean processIsDone {get;set;}
    public boolean showList {get;set;}
    
    public class TestCaseVersion{
        public Selenium_Test_Case_per_Suite__c tcs{get;set;}
        public Boolean selected {get;set;}
        public TestCaseVersion(Selenium_Test_Case_per_Suite__c tcs, Boolean selected){
            this.tcs = tcs;
            this.selected = selected;
        }
    }
    
    public SeleniumTestCasePromoteRollback (ApexPages.StandardController std){
        showList = true;
        processIsDone = false;
        controller = std;
        //std.addFields(new List<String>{'Id','Name','Version__c','Previous_Version__c','Previous_Version__r.Version__c'});
        //tc = (Selenium_Test_Case__c)std.getRecord();
        if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
            tc = [SELECT Id, Name, Version__c, Previous_Version__c, Previous_Version__r.Version__c FROM Selenium_Test_Case__c WHERE Id = :std.getId()];
        }else{
            tc = (Selenium_Test_Case__c)std.getRecord();
        }
    }
    
    public void initPromote() {
        isPromote = true;
        testCaseIdToLookup = tc.Previous_Version__c;
        List<Selenium_Test_Case__c> ls = new List<Selenium_Test_Case__c>();
        if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
            ls = [SELECT Id, Name, Version__c, Previous_Version__c, Previous_Version__r.Version__c FROM Selenium_Test_Case__c WHERE Id = :tc.Id];
        }
        testCaseToUpdate = ls.size()>0?ls.get(0):null;
        if(testCaseToUpdate ==null && !processIsDone){
		    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.WARNING, Label.TEST_CASE_NO_NEXT_VERSION));
            showList = false;
        }
        reloadList();
    }
    
    public void initRollback() {
        isPromote = false;
        testCaseIdToLookup = tc.Id;
        if(String.isBlank(tc.Previous_Version__c) || !Schema.sObjectType.Selenium_Test_Case__c.isQueryable() || !Schema.sObjectType.Selenium_Test_Case__c.isAccessible()){
            testCaseToUpdate = null;
        }
        else{
            testCaseToUpdate = [SELECT Id, Name, Version__c FROM Selenium_Test_Case__c WHERE id =:tc.Previous_Version__c];
        }
        processIsDone = false;
        if(testCaseToUpdate==null && !processIsDone){
		    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.WARNING, Label.TEST_CASE_NO_PREV_VERSION));
            showList = false;
        }
        reloadList();
    }
    
    private void reloadList(){
        if(processIsDone)return;
        testCasePerSuite = new List<TestCaseVersion>();
        if(Schema.sObjectType.Selenium_Test_Case_per_Suite__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case_per_Suite__c.isAccessible()) {
            for(Selenium_Test_Case_per_Suite__c tcs:[SELECT Id, Name, Selenium_Test_Case__c, Selenium_Test_Case__r.Name, Selenium_Test_Case__r.Version__c, Selenium_Test_Suite__c, Selenium_Test_Suite__r.Name
                                                     FROM  Selenium_Test_Case_per_Suite__c WHERE Selenium_Test_Case__c = :testCaseIdToLookup]){
                testCasePerSuite.add(new TestCaseVersion(tcs,true));
            }
        }
        if(testCasePerSuite.size()==0) {
            if(isPromote) {
                if(testCaseToUpdate!=null)ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.WARNING,(tc.Previous_Version__c!=null?
                                                                                        ('The previous Test Case (Version: '+tc.Previous_Version__r.Version__c+') is not being used on any Test Suite, so there is nothing to promote to '+tc.Version__c)
                                                                                        :'There is no previous version. This is the first version of the Test Case.')) );
            }else{
                if(tc.Previous_Version__r.Version__c!=null)ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.WARNING, 'This Test Case (Version: '+tc.Version__c+') is not being used on any Test Suite, so there is nothing to rollback to.') );
	        }
        }
    }
    
    public PageReference promoteOrRollback() {
        List<Selenium_Test_Case_per_Suite__c> toBeUpdated = new List<Selenium_Test_Case_per_Suite__c>();
        for(TestCaseVersion t:testCasePerSuite){
            if(t.selected){
                System.debug('-- tbu '+t.tcs.Id+' tc '+t.tcs.Selenium_Test_Case__c+' new '+testCaseToUpdate.Id);
                toBeUpdated.add(new Selenium_Test_Case_per_Suite__c(Id = t.tcs.Id, Selenium_Test_Case__c = testCaseToUpdate.Id));
            }
        }
        if(toBeUpdated.size()== 0) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR,Label.SELECT_AT_LEAST_ONE_ITEM));
            return null;
        }
        if(!Schema.sObjectType.Selenium_Test_Case_per_Suite__c.fields.Selenium_Test_Case__c.isUpdateable()){
            return null;
        }
        Utilities.Secure_DML(toBeUpdated, Utilities.DML_Action.UPD, schema.Sobjecttype.Selenium_Test_Case_per_Suite__c);
        //update toBeUpdated;
        processIsDone = true;
        showList = false;
        String msg = isPromote?Label.TC_PROMOTED_SUCCESS + toBeUpdated.size():Label.TC_ROLLBACK_SUCCESS + toBeUpdated.size();

        ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.CONFIRM, msg));
        return null;
    }
}