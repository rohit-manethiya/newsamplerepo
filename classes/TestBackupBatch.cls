@IsTest
private class TestBackupBatch {
    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_backup_daily() {
        Org__c validatedOrg = testMethodUtilities.createOrg('testOrg', 'Production', 'myOrgId', 'token', 'username', System.now());
        insert validatedOrg;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitbackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, validatedOrg);
        insert gitbackup;

        List<Org__c> scope_orgs = new List<Org__c>();
        List<Git_Backup__c> scope_backups = new List<Git_Backup__c>();
        scope_orgs.add(validatedOrg);
        scope_backups.add(gitbackup);

        Test.startTest();

        String b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + validatedOrg.sfdc_org_id__c + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        BackupBatch batchApex = new BackupBatch();
        Database.BatchableContext dbc;
        batchApex.start(dbc);
        batchApex.execute(dbc, scope_backups);
        batchApex.finish(dbc);
        Test.stopTest();
    }
    static testMethod void test_backup_weekly() {
        Org__c validatedOrg = testMethodUtilities.createOrg('testOrg', 'Production', 'myOrgId', 'token', 'username', System.now());
        insert validatedOrg;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitbackup = testMethodUtilities.create('backupname', 'branchName', 'Weekly', gitRepo, null, validatedOrg);
        insert gitbackup;

        List<Org__c> scope_orgs = new List<Org__c>();
        List<Git_Backup__c> scope_backups = new List<Git_Backup__c>();
        scope_orgs.add(validatedOrg);
        scope_backups.add(gitbackup);

        Test.startTest();

        String b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + validatedOrg.sfdc_org_id__c + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        BackupBatch batchApex = new BackupBatch();
        Database.BatchableContext dbc;
        batchApex.start(dbc);
        batchApex.execute(dbc, scope_backups);
        batchApex.finish(dbc);
        Test.stopTest();
    }
    static testMethod void test_backup_monthly() {
        Org__c validatedOrg = testMethodUtilities.createOrg('testOrg', 'Production', 'myOrgId', 'token', 'username', System.now());
        insert validatedOrg;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitbackup = testMethodUtilities.create('backupname', 'branchName', 'Monthly', gitRepo, null, validatedOrg);
        insert gitbackup;

        List<Org__c> scope_orgs = new List<Org__c>();
        List<Git_Backup__c> scope_backups = new List<Git_Backup__c>();
        scope_orgs.add(validatedOrg);
        scope_backups.add(gitbackup);

        Test.startTest();

        String b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + validatedOrg.sfdc_org_id__c + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        BackupBatch batchApex = new BackupBatch();
        Database.BatchableContext dbc;
        batchApex.start(dbc);
        batchApex.execute(dbc, scope_backups);
        batchApex.finish(dbc);
        Test.stopTest();
    }
}