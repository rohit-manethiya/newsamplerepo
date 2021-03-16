@IsTest
private class TestGitBackupTrigger {
    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_OrgTrigger() {
        BatchHelper.enforceScheduler();
        CronJobDetail cjd = [SELECT Id FROM CronJobDetail WHERE Name = 'Copado' AND JobType = '7' LIMIT 1];
        if(BatchHelper.isCopadoScheduled()) {
            System.abortJob([SELECT Id FROM CronTrigger WHERE CronJobDetailId = :cjd.Id LIMIT 1].Id);
        }
        System.assertEquals(false, BatchHelper.isCopadoScheduled());

        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert org;
        update org;
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        update gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
        update gitBackup;
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Git Backup'));
        System.assertEquals(true, BatchHelper.isCopadoScheduled());
    }
}