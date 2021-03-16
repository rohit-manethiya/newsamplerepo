@IsTest
private with sharing class SettingsTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.setTestSettingsEE();
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void testFull() {
        Test.startTest();

        Settings con = new Settings();
        System.assertNotEquals(null, con.urlBase);
        System.assertNotEquals(null, Settings.ns);
        System.assertNotEquals(null, Settings.copado_site);
        System.assertNotEquals(null, Settings.server_url);

        Test.stopTest();
    }

    @IsTest
    private static void testConstructors() {
        Settings s1 = new Settings(new ApexPages.StandardController(new Org__c()));
        Settings s2 = new Settings(new GitCommitLookupController());
        System.assert(s1 != s2);
        Settings s3 = new Settings(new webhookLookupController());
        Settings s4 = new Settings(new ScratchOrgStatusCtrl());
        System.assert(s3 != s4);
        Settings s5 = new Settings(new ScratchOrgMetadataController());
        Settings s6 = new Settings(new GitCommit_GridController());
        System.assert(s5 != s6);
        Settings s7 = new Settings(new ScratchOrgDisplayController());
        Settings s8 = new Settings(new ManageGitBranchesController());
        System.assert(s7 != s8);
        Settings s9 = new Settings(new DXOperationController());
        Settings s10 = new Settings(new ManageRepositoryBranchesController());
        System.assert(s9 != s10);
    }

    @IsTest
    private static void testGitCommitChangesControllerInit() {
        Org__c o1 = testMethodUtilities.createOrg('test', 'Production/Developer', null, null, null, System.now());
        insert o1;
        Git_Repository__c gr = testMethodUtilities.createGitRepository('Test repo', 'testUri');
        insert gr;
        Git_Backup__c gitBackup = new Git_Backup__c(Name = 'test', Frequency__c = 'none', Org__c = o1.Id, Git_Repository__c = gr.Id);
        insert gitBackup;
        User_Story__c us = CMTestMethodUtilities.createUserStory('test');
        insert us;

        PageReference pref = new PageReference('/apex/test');
        pref.getParameters().put('snapshotId', gitBackup.Id);
        pref.getParameters().put('userStoryId', us.Id);
        Test.setCurrentPage(pref);

        Settings s = new Settings(new GitCommitChangesController());
        s.userStoryObj = us;
        String result = s.getUserStoryAsJSON();

        System.assertEquals(true, result.contains('User_Story__c'));
    }

    @IsTest
    private static void testLicenseWrapper() {
        Settings.LicenseWrapper s = new Settings.LicenseWrapper(true, true, true, true, true, true);
        System.assertEquals(true, s.hasCAD);
        String currentLicenses = Settings.getCurrentUserLicenses();
    }
}