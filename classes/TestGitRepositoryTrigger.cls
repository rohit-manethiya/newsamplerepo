@IsTest
private class TestGitRepositoryTrigger {
    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    @IsTest
    static void test() {
        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        update gitRepo;
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Git Backup'));
        delete gitRepo;

        /*
        //TODO: refeactor. combine this with TestGiBackupTrigger and setup a negavite test

        Feature__c feature = new Feature__c(name='Git Backup', Enabled__c = false);
        insert feature;
        System.assertEquals(false,FeatureHelper.isFeatureEnabled('Git Backup'));

        Test.startTest();
        TestUtilities.exceedCopadoLicenses();
        try {
            update gitRepo;
            System.assert(false,'this must fail');
        } catch(Exception e){
            System.assert(true, e.getMessage().contains(Label.LICENSES_EXCEEDED));
        }
        TestUtilities.enableLicenses(2, 2, 2);

        try {
            update gitRepo;
            System.assert(false,'this must fail');
        } catch(Exception e){
            System.assert(true, e.getMessage().contains(Label.FEATURE_NOT_SUPPORTED + ': Git Backup'));
        }
        Test.stopTest();
        */
    }
}