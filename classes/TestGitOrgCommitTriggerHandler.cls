@IsTest
private class TestGitOrgCommitTriggerHandler {

    static testMethod void test_before_insert() {

        Integer BATCH_SIZE = 3;
        List<Org__c> testOrgs = new List<Org__c>();
        for(Integer i = 0; i < BATCH_SIZE; i++) {
            Org__c testOrg = testMethodUtilities.createOrg('My test org' + i, 'Production', 'testOrgId' + i, '', '', null);
            testOrg.Last_Git_Backup_Datetime__c = null;
            testOrg.Last_Git_Backup_Status__c = '';
            testOrgs.add(testOrg);
        }
        insert testOrgs;
        System.assertEquals(testOrgs.size(), 3);

        List<Git_Org_Commit__c> testGOCs = new List<Git_Org_Commit__c>();
        for(Integer i = 0; i < BATCH_SIZE; i++) {
            Git_Org_Commit__c testGoc = new Git_Org_Commit__c();
            testGoc.Status__c = 'In Progress';
            testGoc.Commit_Id__c = '213234283748243' + i;
            testGoc.Org__c = testOrgs[i].Id;
            testGoc.Commit_Date__c = null;

            testGOCs.add(testGoc);
        }
        Test.startTest();
        insert testGOCs;
        System.assertEquals(testGOCs.size(), 3);
        Test.stopTest();
    }
}