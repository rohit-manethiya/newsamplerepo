@isTest
public class TestEditBackupExtension {
    @testSetup
    static void setupData() {
        TestUtilities.getTestSettingsMultilicense();
    }

    @isTest
    static void testSuccess() {
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_CCM__c = false;
        license.Enable_Copado__c = true;
        license.Enable_CST__c = false;
        license.Enable_CAD__c = false;
        license.Enable_CCH__c = false;
        insert license;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2', 'http://www.bitbucket.org/');
        insert gitRepo;
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        org.Metadata_Types__c = 'ApexClass,ApexPage';
        insert org;
        List<String> types = new List<String>();
        types.add('ApexClass');
        types.add('ApexPage');
        MetadataTypesHelper.metadataTypes = types;

        // Start with null Git Backup
        Git_Backup__c gitBackup = new Git_Backup__c();
        PageReference pref = Page.EditGitBackup;
        pref.getParameters().put('id', null);
        Test.setCurrentPage(pref);

        EditBackupExtension ext = new EditBackupExtension(new ApexPages.StandardController(gitBackup));
        ext.backup = testMethodUtilities.create('DemoBackup', 'master', 'None', gitRepo, null, org);
        ext.setTypes(ext.GetTypes());
        System.assertEquals(2, ext.types.size());
        System.assertEquals(2, ext.GetMetadataTypes().size());
        System.assertEquals(2, ext.GetTypes().size());
        System.assertEquals(4, ext.GetFrequencyOptions().size());
        ext.init();
        ext.reRender();

        ext.orgChanged();
        ext.backup.Org__c = org.Id;

        pref = ext.save();
        System.assert(pref.getUrl() != Page.editOrg.getUrl());
    }
    @isTest
    static void testError() {
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_CCM__c = false;
        license.Enable_Copado__c = true;
        license.Enable_CST__c = false;
        license.Enable_CAD__c = false;
        license.Enable_CCH__c = false;
        insert license;

        TestUtilities.insertUser('TestEditBackupExtension_Error@test.com', 'System Administrator');
        User user = [SELECT Id, Name FROM User WHERE Username = 'TestEditBackupExtension_Error@test.com' LIMIT 1];
        license.SetupOwnerId = user.Id;
        update license;
        System.runAs(user) {
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2', 'http://www.bitbucket.org/');
            insert gitRepo;
            Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
            insert org;

            // Start with null Git Backup
            Git_Backup__c gitBackup = new Git_Backup__c();
            PageReference pref = Page.EditGitBackup;
            pref.getParameters().put('id', null);
            Test.setCurrentPage(pref);

            EditBackupExtension ext = new EditBackupExtension(new ApexPages.StandardController(gitBackup));
            ext.backup = testMethodUtilities.create('DemoBackup', 'master', 'Daily', gitRepo, null, org);

            Test.startTest();
            TestUtilities.exceedCopadoLicenses();
            pref = ext.save();

            //TODO: refactor. license exeeded cannot be tested like this since LMO featue management.
            //System.assert(testMethodUtilities.hasMessage(Label.LICENSES_EXCEEDED));
            //TestUtilities.enableLicenses(2, 2, 2);

            ext.backup.Git_Snapshot_Permissions__c = 'Allow Commits Only';

            pref = ext.save();
            System.assert(testMethodUtilities.hasMessage(Label.COMMIT_ONLY_SNAPSHOTS_CANNOT_BE_SCHEDULED));
            Test.stopTest();
        }

    }
    @isTest
    static void testExistingGitBackup() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_CCM__c = false;
        license.Enable_Copado__c = true;
        license.Enable_CST__c = false;
        license.Enable_CAD__c = false;
        license.Enable_CCH__c = false;
        insert license;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2', 'http://www.bitbucket.org/');
        insert gitRepo;
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        org.Metadata_Types__c = 'ApexClass,ApexPage,StaticResource';
        insert org;
        Org__c org2 = testMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN', 'USERNAME2', System.now());
        insert org2;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        gitBackup.Metadata_Types__c = 'ApexClass,ApexPage,StaticResource';
        insert gitBackup;

        Test.startTest();
        PageReference pref = Page.EditGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        Test.setCurrentPage(pref);

        EditBackupExtension ext = new EditBackupExtension(new ApexPages.StandardController(gitBackup));
        System.assert(ext.backup != null);
        System.assertEquals(3, ext.selectedTypes.size());
        System.assert(ext.isStaticResourcesSelected);

        gitBackup.Metadata_Types__c = null;
        update gitBackup;
        PageReference pref2 = Page.EditGitBackup;
        pref2.getParameters().put('id', gitBackup.Id);
        Test.setCurrentPage(pref2);

        EditBackupExtension ext2 = new EditBackupExtension(new ApexPages.StandardController(gitBackup));
        System.assert(ext2.isStaticResourcesSelected);
        Test.stopTest();
    }

    @isTest
    static void testDeleteGitSnapshot() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_CCM__c = false;
        license.Enable_Copado__c = true;
        license.Enable_CST__c = false;
        license.Enable_CAD__c = false;
        license.Enable_CCH__c = false;
        insert license;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2', 'http://www.bitbucket.org/');
        insert gitRepo;
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        org.Metadata_Types__c = 'ApexClass,ApexPage,StaticResource';
        insert org;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        gitBackup.Metadata_Types__c = 'ApexClass,ApexPage,StaticResource';
        insert gitBackup;

        Test.startTest();
        PageReference pref = Page.EditGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        Test.setCurrentPage(pref);

        EditBackupExtension ext = new EditBackupExtension(new ApexPages.StandardController(gitBackup));
        ext.deleteGitSnapshot();
        List<Git_Backup__c> snapshot = [SELECT Id FROM Git_Backup__c WHERE Name = 'backupname'];
        System.assert(snapshot.isEmpty(), 'The git snapshot could not be deleted.');

        Test.stopTest();
    }
}