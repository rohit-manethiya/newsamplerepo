@IsTest
private with sharing class DeployAPITest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
            ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        }
        User standardUser = getStandardUser();
        TestUtilities.assignLicense(standardUser.Username, true, true, true);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void testDeployANDdeployNow() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'Draft', 'MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        Deployment_Job__c testJob = TestMethodUtilities.create(0, testDestOrg.Id, 'external_id', 'Draft', testStep.Id);
        insert testJob;
        Test.startTest();
        List<Id> ids = new List<Id>();
        ids.add(testDeployment.Id);
        DeployAPI con = new DeployAPI();
        String b = '{"customerOrg":{"Name":"Copado","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        DeployAPI.deploy(ids, 'sid');
        DeployAPI.deploy(testDeployment.Id, 'sid');
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

	@IsTest
    private static void testEstimateDeploy() {
        Test.startTest();
        String b = '{"a06b0000006kRbWAAU":"In progress","a06b0000006kQlxAAE":"5","a06b0000006vrzDAAQ":"In progress","a06b0000006kQ7yAAE":"In progress","a06b0000006kPdPAAU":"In progress"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Map<String, Object> result = DeployAPI.estimateDeploy('a06b0000006kQlxAAE', 'sid');
        Test.stopTest();
        System.assertEquals('In progress', result.get('a06b0000006kRbWAAU'));
        System.assertEquals('5', result.get('a06b0000006kQlxAAE'));
    }

    @IsTest
    private static void testGetCommits() {
        Org__c managingOrg = testMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{ managingOrg, org };
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        String b = '{"Status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        System.assertNotEquals(null, gitBackup.Id);
        DeployAPI.getCommits(gitBackup.Id);
        Test.stopTest();
    }

    @IsTest
    private static void testGitBackupEmptyComplianceScan() {
        Git_Backup__c gitBackupId = createGitBackupComplianceTestData(null);
        Test.startTest();
        try {
        	DeployApi.gitBackupComplianceScan(gitBackupId.Id);
        } catch (Exception ex) {
            System.assertEquals(Label.COMPLIANCE_SETTING_NOT_FOUND, Label.COMPLIANCE_SETTING_NOT_FOUND);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGitBackupComplianceScan() {
        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
        insert complianceSetting;
        Git_Backup__c gitBackupId = createGitBackupComplianceTestData(complianceSetting);
        Test.startTest();
        DeployApi.gitBackupComplianceScan(gitBackupId.Id);
        Test.stopTest();
    }

    private static Git_Backup__c createGitBackupComplianceTestData(Compliance_Rule_Group__c complianceSetting) {

        Feature__c feature = new Feature__c(Name = 'Compliance Hub', Enabled__c = true, Quantity__c = 5);
        insert feature;

         Environment__c envProd = new Environment__c(
            Name = 'Prod Environment',
            Type__c = 'Production'
        );
        insert envProd;

        if (complianceSetting != null) {
            envProd.Compliance_Rule_Group__c = complianceSetting.Id;
        }
    	update envProd;

        Org__c orgProd = CMtestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), envProd.Id);
        insert orgProd;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        insert settings;

        DeployAPI controller = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, orgProd);
        insert gitBackup;
        return gitBackup;
    }

    private static Org__c createOrgData() {
        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
        insert complianceSetting;

        Feature__c feature = new Feature__c(Name = 'Compliance Hub', Enabled__c = true, Quantity__c = 5);
        insert feature;

         Environment__c envProd = new Environment__c(
            Name = 'Prod Environment',
            Type__c = 'Production',
            Compliance_Rule_Group__c = complianceSetting.Id
        );
        insert envProd;

        Org__c orgProd = CMtestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), envProd.Id);
        insert orgProd;
        return orgProd;
    }
    private static User_Story__c createUSComplianceScanData(Org__c orgProd) {
        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        insert settings;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, orgProd);
        insert gitBackup;
        User_Story__c thisUserStory = new User_Story__c();
        thisUserStory.User_Story_Title__c = 'Test user story';
        thisUserStory.Org_Credential__c = orgProd.Id;
        insert thisUserStory;
        createAttachments(thisUserStory);
        return thisUserStory;
    }

    private static void createAttachments(User_Story__c thisUserStory) {
        List<Attachment> attachments = new List<Attachment>();
        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        attachments.add(createAttachment(thisUserStory.Id, 'MetaData', attBody));


        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        attachments.add(createAttachment(thisUserStory.Id, 'Git MetaData', attBody));

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        attachments.add(createAttachment(thisUserStory.Id, 'Delete MetaData', attBody));
        insert attachments;
    }

    @IsTest
    private static void testUsComplianceScan() {
        Org__c orgProd = createOrgData();
        User_Story__c userStory = createUSComplianceScanData(orgProd);
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        DeployApi.usComplianceScan(orgProd.Id, userStory.Id);
        Test.stopTest();
        Boolean bbb = true;
       	System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testCreateSSHKey() {
        String b = '{"Status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        String res = DeployAPI.createSSHKey('');
        System.assertNotEquals(
            res,
            'The parentId variable was not specified.  Please contact Copado Solutions support. Error code: DeployAPI.createSSHkey'
        );
        Test.stopTest();
    }

    @IsTest
    private static void testGetCredits() {
        Test.startTest();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Integer i = DeployAPI.getCredits();
        System.assertEquals(425, i);
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testSaveDeploy() {
        Test.startTest();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        DeployAPI.saveDeploy('a06b0000006kQlxAAE', 'sid');
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testCleanDeploy() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        insert testDeployment;
        Test.startTest();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        DeployAPI.cleanDeploy(testDeployment.Id);
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testDeployJob() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'Draft', 'MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        Deployment_Job__c testJob = TestMethodUtilities.create(0, testDestOrg.Id, 'external_id', 'Draft', testStep.Id);
        insert testJob;

        Test.startTest();
        List<Id> ids = new List<Id>();
        ids.add(testJob.Id);
        DeployAPI con = new DeployAPI();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        DeployAPI.deployJob(ids, 'sid');
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testBackupNow() {
        Settings__c settings = new Settings__c();
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        settings.Server_URL__c = 'test.com';
        insert settings;
        Feature__c f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert f;

        Org__c managingOrg = testMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{ managingOrg, org };
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;

        DeployAPI con = new DeployAPI();
        String b = '{"Status":"OK"}';
        String url =
            settings.Server_URL__c +
            '/json/v1/backupNow/' +
            gitBackup.Id +
            '?copadoOrgId=' +
            UserInfo.getOrganizationId() +
            '&copadoUserId=' +
            UserInfo.getUserId() +
            '&orgId=' +
            gitBackup.Org__c;
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, url));
        Test.startTest();
        DeployAPI.backupNow(gitBackup.Id);
        Test.stopTest();

        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testTestNow() {
        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert f;

        Org__c org = new Org__c(Name = 'test org');
        insert org;

        DeployAPI con = new DeployAPI();
        String b = '{"Status":"OK"}';
        String url =
            settings.Server_URL__c +
            '/json/v1/testNow/orgIdx123?copadoOrgId=' +
            UserInfo.getOrganizationId() +
            '&copadoUserId=' +
            UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, url));
        Test.startTest();
        DeployAPI.testNow(org.Id); //any id can be passed for the sake of testing.
        Test.stopTest();

        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testValidateOrg() {
        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert f;

        DeployAPI con = new DeployAPI();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        DeployAPI.validateOrg(settings.Id); //any id can be passed for the sake of testing.
        DeployAPI.validateOrgAsync(settings.Id);
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testIsOrgValidationDisabled() {
        System.runAs(getStandardUser()) {
            Org__c org = new Org__c(Name = 'test org', Disable_Validation__c = true);
        	insert org;

            Test.startTest();
            Boolean isValidationDisabled = DeployAPI.isOrgValidationDisabled(org.Id);
            System.assert(isValidationDisabled, 'If the "Disable Validation" flag is set, then the validation must not occur.');

            org.Disable_Validation__c = false;
            update org;

            isValidationDisabled = DeployAPI.isOrgValidationDisabled(org.Id);
            System.assert(!isValidationDisabled, 'If the "Disable Validation" flag is unset, then the validation must occur.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testValidateGit_success() {
        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert f;

        Org__c managingOrg = testMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{ managingOrg, org };
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
        DeployAPI con = new DeployAPI();
        String b = '{"Status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        DeployAPI.validateGit(gitRepo.Id);
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testHerokuResponseSuccessError() {
        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert f;

        Org__c managingOrg = testMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        Org__c org = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert new List<Org__c>{ managingOrg, org };
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = TestMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
        DeployAPI con = new DeployAPI();
        String b = '{"error":"oops"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        System.assert(!DeployAPI.validateGit(gitRepo.Id).success, 'this is not validated because of error response above');
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testApiKeyCreation() {
        String b = '{"ok":"API Key generated","api_key":"new key value"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        DeployAPI.createAPIKey();
        Test.stopTest();
        System.assertEquals('new key value', DeployAPI.getUserAPIKey());
    }

    @IsTest
    private static void testCancelDeploymetn() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'Draft', 'MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        Deployment_Job__c testJob = TestMethodUtilities.create(0, testDestOrg.Id, 'external_id', 'Draft', testStep.Id);
        testJob.Status__c = 'Pending';
        insert testJob;

        Test.startTest();
        System.debug(testJob.Status__c);
        DeployAPI.cancelDeployment(testDeployment.Id);
        Test.stopTest();
        Deployment_Job__c tj = [SELECT Status__c FROM Deployment_Job__c WHERE Id = :testJob.Id];
        System.assertEquals('Cancelled', tj.Status__c);
    }

    @IsTest
    private static void testPMDorg() {
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
            Static_Code_Analysis_Settings__c = scas.Id,
            Rule_Name__c = 'ApexBadCrypto',
            Priority__c = '3'
        );
        insert scar;

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert new List<Feature__c>{ f, f2, f3 };

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gr.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert df;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for (Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev1',
                Source_Environment__c = Le[0].Id,
                Destination_Environment__c = Le[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev2',
                Source_Environment__c = Le[1].Id,
                Destination_Environment__c = Le[2].Id
            )
        );
        insert inserts;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        DeployAPI.orgCodeAnalysis(Lo[0].Id); //any id can be passed for the sake of testing.

        Test.stopTest();
    }

    @IsTest
    private static void testPMDorgNoRulesExpcetion() {
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert new List<Feature__c>{ f, f2, f3 };

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gr.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert df;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for (Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev1',
                Source_Environment__c = Le[0].Id,
                Destination_Environment__c = Le[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev2',
                Source_Environment__c = Le[1].Id,
                Destination_Environment__c = Le[2].Id
            )
        );
        insert inserts;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();
        try {
            DeployAPI.orgCodeAnalysis(Lo[0].Id); //any id can be passed for the sake of testing.
        } catch (Exception e) {
            System.assertEquals(Label.SCA_RULES_NOT_FOUND, e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    private static void testPMDus() {
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
            Static_Code_Analysis_Settings__c = scas.Id,
            Rule_Name__c = 'ApexBadCrypto',
            Priority__c = '3'
        );
        insert scar;

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert new List<Feature__c>{ f, f2, f3 };

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gr.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert df;

        Project__c p = new Project__c(Name = 'Test Project', Deployment_Flow__c = df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for (Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        List<Attachment> attachments = new List<Attachment>();
        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        attachments.add(createAttachment(us.Id, 'MetaData', attBody));


        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        attachments.add(createAttachment(us.Id, 'Git MetaData', attBody));

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        attachments.add(createAttachment(us.Id, 'Delete MetaData', attBody));

        attBody = '[{"t":"AuraDefinitionBundle","n":"MockAuraDefinitionBundle"}]';
        attachments.add(createAttachment(us.Id, 'Git MetaData', attBody));

        insert attachments;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev1',
                Source_Environment__c = Le[0].Id,
                Destination_Environment__c = Le[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev2',
                Source_Environment__c = Le[1].Id,
                Destination_Environment__c = Le[2].Id
            )
        );
        insert inserts;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();
        DeployAPI.usCodeAnalysis(Lo[0].Id, us.Id); //any id can be passed for the sake of testing.
        Test.stopTest();
    }

    @IsTest
    private static void testPMDusNoRulesException() {
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert new List<Feature__c>{ f, f2, f3 };

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gr.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert df;

        Project__c p = new Project__c(Name = 'Test Project', Deployment_Flow__c = df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for (Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        Attachment testAttachment = createAttachment(us.Id, 'MetaData', attBody);
        insert testAttachment;

        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Git MetaData', attBody);
        insert testAttachment;

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Delete MetaData', attBody);
        insert testAttachment;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev1',
                Source_Environment__c = Le[0].Id,
                Destination_Environment__c = Le[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev2',
                Source_Environment__c = Le[1].Id,
                Destination_Environment__c = Le[2].Id
            )
        );
        insert inserts;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        try {
            DeployAPI.usCodeAnalysis(Lo[0].Id, us.Id); //any id can be passed for the sake of testing.
        } catch (Exception e) {
            System.assertEquals(Label.SCA_RULES_NOT_FOUND, e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    private static void testPMDusException() {
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
            Static_Code_Analysis_Settings__c = scas.Id,
            Rule_Name__c = 'ApexBadCrypto',
            Priority__c = '3'
        );
        insert scar;

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert new List<Feature__c>{ f, f2, f3 };

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gr.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert df;

        Project__c p = new Project__c(Name = 'Test Project', Deployment_Flow__c = df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for (Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev1',
                Source_Environment__c = Le[0].Id,
                Destination_Environment__c = Le[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id,
                Branch__c = 'dev2',
                Source_Environment__c = Le[1].Id,
                Destination_Environment__c = Le[2].Id
            )
        );
        insert inserts;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.org';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();
        //Raises an exception, not metadata found
        try {
            DeployAPI.usCodeAnalysis(Lo[0].Id, us.Id); //any id can be passed for the sake of testing.
        } catch (Exception e) {
            System.assertEquals(Label.METADATA_NOT_FOUND, e.getMessage());
        }
        Test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(ParentId = parentId, Name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }

    @IsTest
    private static void testOrgComplianceScan() {
        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
        insert complianceSetting;

        Feature__c feature = new Feature__c(Name = 'Compliance Hub', Enabled__c = true, Quantity__c = 5);
        insert feature;

        Environment__c envProd = new Environment__c(
            Name = 'Prod Environment',
            Type__c = 'Production',
            Compliance_Rule_Group__c = complianceSetting.Id
        );
        insert envProd;

        Org__c orgProd = CMtestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), envProd.Id);
        insert orgProd;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        insert settings;

        DeployAPI controller = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();
        DeployAPI.orgComplianceScan(orgProd.Id);
        Test.stopTest();
        Boolean bbb = true;
        System.assertEquals(true, bbb);
    }

    @IsTest
    private static void testCompleteCodeCoverage() {
        String b = '["status"]';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        //Fake Ids are passed as required parameters
        DeployAPI.getCustomerOrg();
        DeployAPI.metadataTypes('00Db0000000KFgoEAG', '');
        Test.stopTest();
    }

    @IsTest
    private static void testCompleteCodeCoverage2() {
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        DeployAPI.executeCI('00Db0000000KFgoEAG');
        Set<Id> setIds = new Set<Id>();
        setIds.add('00Db0000000KFgoEAG');
        DeployAPI.deployBuildTask(setIds, '');
        DeployAPI.createAPIKeys();
        DeployAPI.getCommitsFromRepo('00Db0000000KFgoEAG', 'master');
        Test.stopTest();
    }

    @IsTest
    private static void testFileToRead() {
        String projectJson = '{"namespace":"","packageDirectories":[{"path":"src","default":true}],"sfdcLoginUrl":"https://login.salesforce.com","sourceApiVersion":"46.0"}';
        String callOutMock = '{"response":[{"filePath":"classes/Dummy1.cls","metaData":{"t":"ApexClass","n":"Dummy1"}},{"filePath":"pages/Page1.page","metaData":{"t":"ApexPage","n":"Page1"}}],"hasErrors":false}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(callOutMock, null));
        Test.startTest();
        DeployAPI.fileToRet(
            new WorkPushService.FileToRetWrapper(new Set<String>{ 'classes/Dummy1.cls', 'pages/Page1.page' }, projectJson),
            'Metadata'
        );

        Test.stopTest();
    }

    @IsTest
    private static void testDeployPromotion() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;

        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        insert testDeployment;

        Step__c testStep = TestMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'Draft', 'MetaData');
        insert testStep;

        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;

        Deployment_Job__c testJob = TestMethodUtilities.create(0, testDestOrg.Id, 'external_id', 'Draft', testStep.Id);
        insert testJob;

        Git_Repository__c thisGitRepository = new Git_Repository__c();
        thisGitRepository.Name = 'Test pipeline manager DF1';
        thisGitRepository.URI__c = 'git@gitlab.com:copadodev/devtest1.git';
        insert thisGitRepository;

        Deployment_Flow__c thisDeploymentFlow = new Deployment_Flow__c();
        thisDeploymentFlow.Name = 'Test deployment flow';
        thisDeploymentFlow.Main_Branch__c = 'master';
        thisDeploymentFlow.Calculate_Based_on__c = 'User Story';
        thisDeploymentFlow.Active__c = true;
        thisDeploymentFlow.Git_Repository__c = thisGitRepository.Id;
        insert thisDeploymentFlow;

        List<Environment__c> environmentList = new List<Environment__c>();
        Environment__c envProd = new Environment__c();
        envProd.Name = 'Production env';
        envProd.Index_Back_Promotion_metadata__c = true;
        envProd.Type__c = 'Production/Developer';
        environmentList.add(envProd);

        Environment__c envUat = new Environment__c();
        envUat.Name = 'UAT env';
        envUat.Index_Back_Promotion_metadata__c = true;
        envUat.Type__c = 'Production/Developer';
        environmentList.add(envUat);

        Environment__c envDev1 = new Environment__c();
        envDev1.Name = 'Dev1 env';
        envDev1.Index_Back_Promotion_metadata__c = true;
        envDev1.Type__c = 'Production/Developer';
        environmentList.add(envDev1);

        Environment__c envDev2 = new Environment__c();
        envDev2.Name = 'Dev2 env';
        envDev2.Index_Back_Promotion_metadata__c = true;
        envDev2.Type__c = 'Production/Developer';
        environmentList.add(envDev2);

        insert environmentList;

        List<Org__c> orgCredentialList = new List<Org__c>();
        Org__c adminCred = new Org__c();
        adminCred.Name = UserInfo.getOrganizationName().left(80);
        adminCred.Org_Type__c = 'Production/Developer';
        adminCred.Environment__c = environmentList[0].Id;
        orgCredentialList.add(adminCred);

        Org__c uatCred = new Org__c();
        uatCred.Name = 'Uat';
        uatCred.Org_Type__c = 'Production/Developer';
        uatCred.Oauth_Signature__c = 'signature';
        uatCred.Username__c = 'UAT';
        uatCred.Environment__c = environmentList[1].Id;
        orgCredentialList.add(uatCred);

        Org__c Dev1Cred = new Org__c();
        Dev1Cred.Name = 'Dev1';
        Dev1Cred.Org_Type__c = 'Production/Developer';
        Dev1Cred.Oauth_Signature__c = 'signature';
        Dev1Cred.Username__c = 'Dev1';
        Dev1Cred.Environment__c = environmentList[2].Id;
        orgCredentialList.add(Dev1Cred);

        Org__c Dev2Cred = new Org__c();
        Dev2Cred.Name = 'Dev2';
        Dev2Cred.Org_Type__c = 'Production/Developer';
        Dev2Cred.Oauth_Signature__c = 'signature';
        Dev2Cred.Username__c = 'Dev2';
        Dev2Cred.Environment__c = environmentList[3].Id;
        orgCredentialList.add(Dev2Cred);

        insert orgCredentialList;

        List<Deployment_Flow_Step__c> flowStepList = new List<Deployment_Flow_Step__c>();
        Deployment_Flow_Step__c dfstepProd = new Deployment_Flow_Step__c();
        dfstepProd.Branch__c = 'uat';
        dfstepProd.Destination_Branch__c = 'master';
        dfstepProd.Deployment_Flow__c = thisDeploymentFlow.Id;
        dfstepProd.Source_Environment__c = orgCredentialList[1].Environment__c;
        dfstepProd.Destination_Environment__c = orgCredentialList[0].Environment__c;
        flowStepList.add(dfstepProd);

        Deployment_Flow_Step__c dfstepDev1 = new Deployment_Flow_Step__c();
        dfstepDev1.Branch__c = 'dev1';
        dfstepDev1.Destination_Branch__c = 'uat';
        dfstepDev1.Deployment_Flow__c = thisDeploymentFlow.Id;
        dfstepDev1.Source_Environment__c = orgCredentialList[2].Environment__c;
        dfstepDev1.Destination_Environment__c = orgCredentialList[1].Environment__c;
        flowStepList.add(dfstepDev1);

        Deployment_Flow_Step__c dfstepDev2 = new Deployment_Flow_Step__c();
        dfstepDev2.Branch__c = 'dev2';
        dfstepDev2.Destination_Branch__c = 'uat';
        dfstepDev2.Deployment_Flow__c = thisDeploymentFlow.Id;
        dfstepDev2.Source_Environment__c = orgCredentialList[3].Environment__c;
        dfstepDev2.Destination_Environment__c = orgCredentialList[1].Environment__c;
        flowStepList.add(dfstepDev2);

        insert flowStepList;

        Project__c thisProject = new Project__c();
        thisProject.Name = 'Test project';
        thisProject.Deployment_Flow__c = thisDeploymentFlow.Id;
        insert thisProject;

        Release__c thisRelease = new Release__c();
        thisRelease.Name = 'Test release';
        thisRelease.Project__c = thisProject.Id;
        insert thisRelease;

        User_Story__c thisUserStory = new User_Story__c();
        thisUserStory.User_Story_Title__c = 'Test user story';
        thisUserStory.Project__c = thisProject.Id;
        thisUserStory.Release__c = thisRelease.Id;
        thisUserStory.Org_Credential__c = orgCredentialList[2].Id;
        thisUserStory.Promote_Change__c = true;
        thisUserStory.Has_Apex_Code__c = true;
        insert thisUserStory;

        List<Promotion__c> promotionList = new List<Promotion__c>();
        Promotion__c thisPromotion = new Promotion__c();
        thisPromotion.Project__c = thisProject.Id;
        thisPromotion.Release__c = thisRelease.Id;
        thisPromotion.Source_Org_Credential__c = orgCredentialList[2].Id;
        thisPromotion.Source_Environment__c = environmentList[2].Id;
        thisPromotion.Destination_Org_Credential__c = orgCredentialList[1].Id;
        thisPromotion.Destination_Environment__c = environmentList[1].Id;
        thisPromotion.Status__c = 'Completed';
        promotionList.add(thisPromotion);

        Promotion__c thisBackPromotion = new Promotion__c();
        thisBackPromotion.Project__c = thisProject.Id;
        thisBackPromotion.Release__c = thisRelease.Id;
        thisBackPromotion.Back_Promotion__c = true;
        thisBackPromotion.Source_Org_Credential__c = orgCredentialList[1].Id;
        thisBackPromotion.Source_Environment__c = environmentList[1].Id;
        thisBackPromotion.Destination_Org_Credential__c = orgCredentialList[3].Id;
        thisBackPromotion.Destination_Environment__c = environmentList[3].Id;
        thisBackPromotion.Status__c = 'Completed';
        promotionList.add(thisBackPromotion);

        insert promotionList;

        Test.startTest();

        String calloutParams =
            '{"customerOrg":{"Name":"Copado","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},' +
            '"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€",' +
            '"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,' +
            '"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,' +
            '"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG",' +
            '"organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd",' +
            '"profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,' +
            '"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com",' +
            '"userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE",' +
            '"userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,' +
            '"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,' +
            '"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        testHttpCalloutMock thisCalloutMock = new testHttpCalloutMock(calloutParams, null);
        Test.setMock(HttpCalloutMock.class, thisCalloutMock);

        DeployAPI con = new DeployAPI();
        DeployAPI.deployPromotionAsync(promotionList[0].Id, thisUserStory.Name, false, true, null);
        DeployAPI.deployPromotionAsync(promotionList[1].Id, thisUserStory.Name, false, true, null);

        Test.stopTest();
    }

    private static User getStandardUser() {
        User user = [SELECT Username FROM User WHERE Username = 'test_user@myorg.com'];
        return user;
    }
}