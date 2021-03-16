@IsTest
private class TestBackupNow {
    private static final String APPLY_ENV_VARS = 'applyEnvVars';
    private static final String APPLY_YAML = 'applyYAML';
    private static final String OPTION_FALSE = 'false';

    @TestSetup static void setupData() {
        TestUtilities.enableLicenses(1, 1, 1, 1, 1, 1);
        TestUtilities.insertAdminUsers(new List<String>{
                'user1-TestBackupNow@test-copado.org', 'user2-TestBackupNow@test-copado.org'
        });
    }
    static testMethod void testBackupSuccess() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        String b = '{"ok":"Git validated"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + UserInfo.getOrganizationId() + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c managingOrg = testMethodUtilities.createOrg('OrgName', 'Production', UserInfo.getOrganizationId(), 'SFDC_TOKEN', 'USERNAME', System.now());
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{
                managingOrg, org
        };

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        gitBackup.Git_Snapshot_Permissions__c = 'Allow Snapshots Only';
        insert gitBackup;

        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.id);
        pref.getParameters().put('commitComment', 'my commit comment');
        pref.getParameters().put(APPLY_ENV_VARS, OPTION_FALSE);
        pref.getParameters().put(APPLY_YAML, OPTION_FALSE);
        Test.setCurrentPage(pref);

        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));

        ext.doBackup();
        System.debug('################# testBackup_success: ' + ApexPages.getMessages());
        System.assert(testMethodUtilities.hasMessage(Label.BACKUP_STARTED));
        ext.doTestConnections();

        ext.getMetadata_url();
        ext.getQuery_url();
        ext.goToGitCommitPage();
        Test.stopTest();
        System.assertEquals(true, ext.testConnections());
    }

    static testMethod void testBackupErrorsFailGit() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        Org__c managingOrg = testMethodUtilities.createOrg('OrgName', 'Production', UserInfo.getOrganizationId(), 'SFDC_TOKEN', 'USERNAME', System.now());
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', null, 'SFDC_TOKEN', 'USERNAME', null);
        insert new List<Org__c>{
                managingOrg, org
        };

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        Test.startTest();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));
        b = '{"error":"Git not validated"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, 'https://server.com/json/v1/validateGit/?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        Test.setCurrentPage(pref);

        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        String error = ext.getValidation();
        System.assert(error.contains(Label.ERROR_TEST_GIT_CONNECTIONS));
        System.assertEquals(true, ext.pageHasErrors);
        ext.goToGitCommitPage();
        Test.stopTest();
    }

    static testMethod void testBackupErrorsFailOrg() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        Org__c managingOrg = testMethodUtilities.createOrg('OrgName', 'Production', UserInfo.getOrganizationId(), 'SFDC_TOKEN', 'USERNAME', System.now());
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', null, 'SFDC_TOKEN', 'USERNAME', null);
        insert new List<Org__c>{
                managingOrg, org
        };

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        String boolStr = '';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        boolStr = '{"Status":"Ok"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateGit/?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        pref.getParameters().put(APPLY_ENV_VARS, OPTION_FALSE);
        pref.getParameters().put(APPLY_YAML, OPTION_FALSE);
        Test.setCurrentPage(pref);

        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        ext.doBackup();
        ext.getValidation();
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));
        System.assertEquals(true, ext.pageHasErrors);
        Test.stopTest();
    }

    static testMethod void testBackupErrorsCustomerOrgMissing() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert org;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        String boolStr = '{"Status":"Ok"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        boolStr = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + org.sfdc_org_id__c + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        pref.getParameters().put(APPLY_ENV_VARS, OPTION_FALSE);
        pref.getParameters().put(APPLY_YAML, OPTION_FALSE);
        Test.setCurrentPage(pref);

        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        ext.doBackup();
        System.debug('#################' + ApexPages.getMessages());
        /*
         * removed because causes false positives while displaying the backup. saying credentials are not validated
         * when the developer doesn't own the org credential.
         * 
         */
        Test.stopTest();
    }

    static testMethod void testBackupErrorsMissingLicenses() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        String b = '{"ok":"Git validated"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + UserInfo.getOrganizationId() + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c managingOrg = testMethodUtilities.createOrg('OrgName', 'Production', UserInfo.getOrganizationId(), 'SFDC_TOKEN', 'USERNAME', System.now());
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{
                managingOrg, org
        };

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        List<Copado_License__c> licenses = new List<Copado_License__c>();
        List<User> users = [SELECT Id, Name FROM User WHERE Username = 'user1-TestBackupNow@test-copado.org' OR Username = 'user2-TestBackupNow@test-copado.org' LIMIT 2];
        if(users.size() == 2) {
            licenses.add(new Copado_License__c(SetupOwnerId = users[0].Id, Enable_Copado__c = true, Enable_CCM__c = false, Enable_CST__c = true));
            licenses.add(new Copado_License__c(SetupOwnerId = users[1].Id, Enable_Copado__c = true, Enable_CCM__c = true, Enable_CST__c = false));
        }
        Utilities.Secure_DML(licenses, Utilities.DML_Action.INS, schema.SObjectType.Copado_License__c);
        // Reduce the available Copado licenses to 1 to exceed them

        /*
        With Features LMO controlled, since cannot be changed after @testSetup method


        TestUtilities.enableLicenses(1, 2, 2);

        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.id);
        pref.getParameters().put('comment', 'my commit comment');
        pref.getParameters().put('applyEnvVars', 'false');
        Test.setCurrentPage(pref);        
             
        
        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        system.debug('################# testBackup_success: '+ApexPages.getMessages());
        system.assert(testMethodUtilities.hasMessage(Label.FEATURE_NOT_SUPPORTED));
        system.assert(testMethodUtilities.hasMessage(Label.LICENSES_EXCEEDED));

        Test.stopTest();
        */

    }

    static testMethod void testBackupComplianceScan() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        String boolStr = '{"ok":"Git validated"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, null));
        boolStr = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + UserInfo.getOrganizationId() + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, null));

        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
        insert complianceSetting;

        Feature__c feature2 = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        insert feature2;

        Environment__c envProd = new Environment__c(Name = 'Prod Environment', Type__c = 'Production', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envProd;

        Org__c managingOrg = testMethodUtilities.createOrg('OrgName', 'Production', UserInfo.getOrganizationId(), 'SFDC_TOKEN', 'USERNAME', System.now());
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        org.Environment__c = envProd.Id;
        insert new List<Org__c>{
                managingOrg, org
        };

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Compliance Hub'));


        //With Features LMO controlled, since cannot be changed after @testSetup method

        //TestUtilities.enableLicenses(2, 0, 0, 0, 1);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        
        
        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        Test.setCurrentPage(pref);
        
        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        
        ext.gitBackupComplianceScan();
        System.debug('################# testBackup_Compliance_Scan_success: '+ApexPages.getMessages());
        System.assert(testMethodUtilities.hasMessage(Label.COMPLIANCE_SCAN_REQUESTED));
        Test.stopTest();
    }

    static testMethod void testGetCommits() {
        testMethodUtilities.upsertOrgwideSettings();
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;

        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert org;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;

        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        String boolStr = '{"Status":"Ok"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        boolStr = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' + org.sfdc_org_id__c + '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(boolStr, 'https://server.com/json/v1/validateOrg/' + org.Id + '?sid=' + UserInfo.getSessionId() + '&url=' + EncodingUtil.urlEncode('endpoint.com', 'UTF-8')));

        Test.startTest();
        PageReference pref = Page.ViewGitBackup;
        pref.getParameters().put('id', gitBackup.Id);
        pref.getParameters().put(APPLY_ENV_VARS, OPTION_FALSE);
        pref.getParameters().put(APPLY_YAML, OPTION_FALSE);
        Test.setCurrentPage(pref);

        BackupNow ext = new BackupNow(new ApexPages.StandardController(gitBackup));
        ext.getCommits();
        System.assertEquals(false, ext.pageHasErrors);
        Test.stopTest();
    }
}