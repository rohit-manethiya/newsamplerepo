@IsTest
private class TestOrgTrigger {
    @TestSetup static void setupTestData() {
        insert TestUtilities.getTestSettings();
    }
    static testMethod void test_OrgTrigger() {
        BatchHelper.enforceScheduler();
        CronJobDetail cjd = [SELECT Id FROM CronJobDetail WHERE Name = 'Copado' AND JobType = '7' LIMIT 1];
        if(BatchHelper.isCopadoScheduled()) {
            System.abortJob([SELECT Id FROM CronTrigger WHERE CronJobDetailId = :cjd.Id LIMIT 1].Id);
        }
        System.assertEquals(false, BatchHelper.isCopadoScheduled());

        Org__c testOrg = testMethodUtilities.createOrg('OrgName2', 'Sandbox', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        testOrg.Test_Frequency__c = 'Daily';
        insert testOrg;

        System.assertEquals(true, BatchHelper.isCopadoScheduled());
    }
    static testMethod void test_environmentCreation() {
        Org__c testOrg = testMethodUtilities.createOrg('OrgName2', 'Sandbox', 'null', 'SFDC_TOKEN', 'USERNAME', null);
        insert testOrg;

        testOrg.SFDC_Org_ID__c = '000000000000000000_100000000000000001';
        update testOrg;

        List<Environment__c> results_envs = [SELECT Id, Name, Org_ID__c FROM Environment__c WHERE Org_ID__c = '000000000000000000'];
        System.assertEquals(1, results_envs.size());
        List<Org__c> results_orgs = [SELECT Id, Environment__c, SFDC_Org_ID__c FROM Org__c];
        System.assertEquals(results_envs[0].Id, results_orgs[0].Environment__c);
    }
}