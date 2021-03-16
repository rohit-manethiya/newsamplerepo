@isTest
private class TestApexTestResultTriggerHandler{
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void coverageUnusedMethods(){
        Org__c testOrg = testMethodUtilities.createOrg('My test org', 'Production', 'testOrgId', '', '', null);
        insert testOrg;
        Apex_Test_Result__c testAtr = new Apex_Test_Result__c();
        testAtr.Org__c = testOrg.Id;
        testAtr.Status__c = 'Errors';
        insert testAtr;
        update testAtr;
        delete testAtr;
        system.assertEquals(0, [select Id from Apex_Test_Result__c where Id=:testAtr.Id].size());
        undelete testAtr;
        system.assertEquals(1, [select Id from Apex_Test_Result__c where Id=:testAtr.Id].size());
    }
    static testMethod void test_after_insert_OKs() {
        Integer BATCH_SIZE = 3;
        List<Org__c> testOrgs = new List<Org__c>();
        for(Integer i=0; i<BATCH_SIZE; i++){
            Org__c testOrg = testMethodUtilities.createOrg('My test org'+i, 'Production', 'testOrgId'+i, '', '', null);
            testOrg.Last_Apex_Tests_Datetime__c = null;
            testOrg.Last_Apex_Tests_Status__c = '';
            testOrgs.add(testOrg);
        }
        insert testOrgs;
        
        List<Apex_Test_Result__c> testATRs = new List<Apex_Test_Result__c>();
        for(Integer i=0; i<BATCH_SIZE; i++){
            Apex_Test_Result__c testAtr = new Apex_Test_Result__c();
            testAtr.Org__c = testOrgs[i].Id;
            testAtr.Status__c = 'Success';
            testATRs.add(testAtr);
        }
        
        Test.startTest();
        insert testATRs;
        Test.stopTest();
        
        Set<Id> resultIdSet = new Set<Id>();
        for(Apex_Test_Result__c a : testATRs){
            resultIdSet.add(a.Id);
        }
        
        List<Apex_Test_Result__c> results = [select Id, Org__c, Org__r.Last_Apex_Tests_Datetime__c, Org__r.Last_Apex_Tests_Status__c from Apex_Test_Result__c where Id IN :resultIdSet];
        system.assertEquals(3, results.size());
        for(Apex_Test_Result__c a : results){
            system.assert(a.Org__r.Last_Apex_Tests_Datetime__c != null);
            system.assertEquals('OK', a.Org__r.Last_Apex_Tests_Status__c);
        }
    }
    static testMethod void test_after_insert_Errors() {
        Integer BATCH_SIZE = 3;
        List<Org__c> testOrgs = new List<Org__c>();
        for(Integer i=0; i<BATCH_SIZE; i++){
            Org__c testOrg = testMethodUtilities.createOrg('My test org'+i, 'Production', 'testOrgId'+i, '', '', null);
            testOrg.Last_Apex_Tests_Datetime__c = null;
            testOrg.Last_Apex_Tests_Status__c = '';
            testOrgs.add(testOrg);
        }
        insert testOrgs;
        
        List<Apex_Test_Result__c> testATRs = new List<Apex_Test_Result__c>();
        for(Integer i=0; i<BATCH_SIZE; i++){
            Apex_Test_Result__c testAtr = new Apex_Test_Result__c();
            testAtr.Org__c = testOrgs[i].Id;
            testAtr.Status__c = 'Errors';
            testATRs.add(testAtr);
        }
        
        Test.startTest();
        insert testATRs;
        Test.stopTest();
        
        Set<Id> resultIdSet = new Set<Id>();
        for(Apex_Test_Result__c a : testATRs){
            resultIdSet.add(a.Id);
        }
        
        List<Apex_Test_Result__c> results = [select Id, Org__c, Org__r.Last_Apex_Tests_Datetime__c, Org__r.Last_Apex_Tests_Status__c from Apex_Test_Result__c where Id IN :resultIdSet];
        system.assertEquals(3, results.size());
        for(Apex_Test_Result__c a : results){
            system.assert(a.Org__r.Last_Apex_Tests_Datetime__c != null);
            system.assertEquals('Error', a.Org__r.Last_Apex_Tests_Status__c);
        }
    }
}