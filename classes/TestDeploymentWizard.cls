@IsTest
private class TestDeploymentWizard {
    @TestSetup
    static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static void setupDataDML() {
        TestUtilities.insertUser('user1-TestDeploymentWizard@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense('user1-TestDeploymentWizard@test-copado.org', false, true, false);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false);

        TestMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void testStepDescription() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Pending',
            'Apex'
        );
        insert testStep;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
        ext.selectedStep = testStep.Id;
        ext.useStep();
        ext.step.Type__c = 'Bulk Data';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_BULK_DATA, ext.stepDescription);
        ext.step.Type__c = 'Data';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_DATA, ext.stepDescription);
        ext.step.Type__c = 'Full Profiles';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_FULL_PROFILES, ext.stepDescription);
        ext.step.Type__c = 'MetaData';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_METADATA, ext.stepDescription);
        ext.step.Type__c = null;
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_NONE_SELECTED, ext.stepDescription);
        ext.step.Type__c = 'Translations';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_TRANSLATIONS, ext.stepDescription);
        ext.step.Type__c = 'Users';
        ext.updateStepDescription();
        System.assertEquals(Label.STEP_DESCRIPTION_USERS, ext.stepDescription);
    }
    static testMethod void testExtension_Part1() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
        System.assertEquals(0, ApexPages.getMessages().size());

        ext.step_createDeployment = false;
        ext.goto_createDeployment();
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(true, ext.step_createDeployment);

        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testFromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        ext.deployment.Name = null;
        ext.deployment.From_Org__c = null;
        ext.save_deployment(); // TESTING NOW WORKING HERE... HELP NEEDED FROM THE WOL
        ext.step_addStep = false; // TESTING NOW WORKING HERE... HELP NEEDED FROM THE WOLF
        ext.deployment.Name = 'Test deployment';
        ext.deployment.From_Org__c = testFromOrg.Id;

        // user presses next:
        System.assertEquals(false, ext.step_addStep);
        Test.stopTest();
    }
    static testMethod void testExtension_Part2() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        testDeployment.From_Org__c = testFromOrg.Id;
        insert testDeployment;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testFromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        ext.step_addStep = false;
        ext.save_deployment();
        System.assertEquals(true, ext.step_addStep);
        System.assertEquals(0, ApexPages.getMessages().size());

        // User is on step 2
        ext.newStep();
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(true, ext.step_Step_edit);

        // Add step information and save it.
        ext.step.Name = 'Sample Step';
        ext.step.Order__c = 1;
        ext.step.Type__c = 'MetaData';
        ext.step.Deployment__c = ext.deployment.Id;
        insert ext.step;
        ext.selectedStep = ext.step.Id;
        ext.useStep();
        System.assertEquals(true, ext.step_Step_edit);
        System.assertEquals(0, ApexPages.getMessages().size());

        ext.goto_selectDestinationOrgs();
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(true, ext.step_selectDestinationOrgs);

        // Create new destination org;
        ext.newDestOrg();
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(true, ext.step_DestOrg_edit);
        ext.newStep();
        System.assertEquals(ext.selectedStep, null);
        ext.newDestOrg();
        System.assertEquals(ext.step_DestOrg_edit, true);
        DeploymentWizardExtension.UserWrapper a = new DeploymentWizardExtension.UserWrapper();
    }
    static testMethod void testExtension_Part3() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        testDeployment.From_Org__c = testFromOrg.Id;
        insert testDeployment;
        Step__c testStep1 = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Draft',
            'Apex'
        );
        insert testStep1;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
        ext.step_DestOrg_edit = true;

        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testFromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        ext.destinationOrg.To_Org__c = testFromOrg.Id;
        //ext.destinationOrg.Status__c = 'Not started';
        System.debug('##### ' + testFromOrg.Id + ' ' + testDeployment.Id);
        ext.saveDestOrg();
        System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@' + ApexPages.getMessages());
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(false, ext.step_DestOrg_edit);
        System.assertEquals(true, ext.step_selectDestinationOrgs);

        // Now setup a schedule
        b = '{"a06b0000006kRbWAAU":"In progress","a06b0000006kQlxAAE":"Complete","a06b0000006vrzDAAQ":"Complete","a06b0000006kQ7yAAE":"Complete","a06b0000006kPdPAAU":"Complete"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ext.goto_setupSchedule();
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(true, ext.step_setupSchedule);
        System.assertEquals(false, ext.step_selectDestinationOrgs);
        System.assertEquals(true, ext.getScheduleOptions().size() == 2);
    }
    static testMethod void testExtension_Part4() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        testDeployment.From_Org__c = testFromOrg.Id;
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Draft',
            'Apex'
        );
        insert testStep;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        // TEST A NON VALIDATED ORG
        testFromOrg.SFDC_Org_ID__c = UserInfo.getOrganizationId();
        testFromOrg.Validated_Date__c = null;
        update testFromOrg;
        ext.goto_setupSchedule();
        Test.startTest();
        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testFromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        System.assertEquals(true, ext.getScheduleOptions().size() == 2);
        ext.deployment.Schedule__c = 'Deploy later';
        ext.scheduleShowDate();

        //System.assert(TestMethodUtilities.hasMessage(Label.CUSTOMER_ORG_NOT_VALIDATED));

        // Schedule deploy later - WITH NO ERROR MESSAGES (0rgs validated);
        testFromOrg.SFDC_Org_ID__c = 'TESTNOTEXISTING';
        testFromOrg.Validated_Date__c = System.today();
        update testFromOrg;
        ext.goto_setupSchedule();
        ext.deployment.Schedule__c = 'Deploy later';
        System.assertEquals(true, ext.getScheduleOptions().size() == 2);
        ext.scheduleShowDate();
        System.assert(TestMethodUtilities.hasMessage(Label.CUSTOMER_ORG_NOT_EXISTS));
        Test.stopTest();
    }
    static testMethod void testExtension_Part5() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg(
            'OrgName',
            'Production',
            UserInfo.getOrganizationId(),
            'SFDC_TOKEN',
            'USERNAME',
            System.now()
        );
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Pending'
        );
        testDeployment.From_Org__c = testFromOrg.Id;
        insert testDeployment;
        Step__c testStep1 = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Draft',
            'Apex'
        );
        insert testStep1;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        // Schedule deploy later - TEST SUCCESS
        testFromOrg.SFDC_Org_ID__c = UserInfo.getOrganizationId();
        testFromOrg.Validated_Date__c = System.today();
        update testFromOrg;

        Test.startTest();
        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testFromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        ext.goto_setupSchedule();
        System.assertEquals(true, ext.getScheduleOptions().size() == 2);
        ext.deployment.Schedule__c = 'Deploy later';
        ext.scheduleShowDate();
        System.assertEquals(true, ext.showDateField);
    }
    static testMethod void testConfirmAndClose() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        String creditsJSON = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(creditsJSON, null));
        ext.deployment.Date__c = null;
        ext.deployment.Schedule__c = 'Deploy later';
        Test.startTest();
        pref = ext.confirmAll();

        //System.assert(TestMethodUtilities.hasMessage(Label.DEPLOYLATER_DT_MUST_BE_FUTURE));
        System.assertEquals(0, ApexPages.getMessages().size());
        System.assertEquals(null, pref);

        Test.stopTest();
    }
    static testMethod void testPostEstimationsPart() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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
        // Insert Test Steps and Attachments
        List<Step__c> steps = new List<Step__c>();
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Not started',
            'Apex'
        );
        steps.add(testStep); // 1 credit
        Step__c testStep2 = TestMethodUtilities.create(
            'Custom Settings',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Not started',
            'Custom Settings'
        );
        steps.add(testStep2); // 11 credits
        Step__c testStep3 = TestMethodUtilities.create(
            'Users',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            2,
            'Not started',
            'Users'
        );
        steps.add(testStep3); // 1 credit
        Step__c testStep4 = TestMethodUtilities.create(
            'MetaData',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            3,
            'Not started',
            'MetaData'
        );
        steps.add(testStep4); // 6 credits
        Step__c testStep5 = TestMethodUtilities.create(
            'Translations',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            4,
            'Not started',
            'Translations'
        );
        steps.add(testStep5);
        insert steps;

        List<Attachment> attachments = new List<Attachment>();
        Attachment testAttachment2 = TestMethodUtilities.createAttachment(
            testStep2.Id,
            'Custom Settings',
            '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}'
        );
        attachments.add(testAttachment2);
        Attachment testAttachment3 = TestMethodUtilities.createAttachment(
            testStep3.Id,
            'Users',
            '{"userIds":["0050Y000000K2I9QAK"],"fromSuffix":"dev","toSuffix":"uat","active":true,"userTerritories":false}'
        );
        attachments.add(testAttachment3);
        Attachment testAttachment4 = TestMethodUtilities.createAttachment(
            testStep4.Id,
            'MetaData',
            '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]'
        );
        attachments.add(testAttachment4);
        Attachment testAttachment5 = TestMethodUtilities.createAttachment(
            testStep5.Id,
            'Translations',
            '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]'
        );
        attachments.add(testAttachment5);
        insert attachments;
        List<Step__c> updateList = new List<Step__c>();
        testStep2.Attachment_Id__c = testAttachment2.Id;
        updateList.add(testStep2);
        testStep3.Attachment_Id__c = testAttachment3.Id;
        updateList.add(testStep3);
        testStep4.Attachment_Id__c = testAttachment4.Id;
        updateList.add(testStep4);
        testStep5.Attachment_Id__c = testAttachment5.Id;
        updateList.add(testStep5);
        update updateList;

        Destination_Org__c destOrg = TestMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
        insert destOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        ext.goto_selectDestinationOrgs();

        ext.deployment.Date__c = System.today().addDays(1);
        ext.deployment.Schedule__c = 'Deploy later';
        ext.step_setupSchedule = true;
        Test.startTest();
        List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
        estimations = ext.getEstimations();
        System.debug('########################################################' + estimations);
        System.assertEquals(1, ext.destinationOrgs.size());
        System.assertEquals(29, ext.totalEstimations);
        System.assert(estimations.size() > 0);
        System.assertEquals(1, estimations[0].credits);

        // AUTO DEPLOYMENT.DATE=NULL
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":0,"credits":0,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ext.deployment.Date__c = null;
        ext.creditCheckAndValidations();
        ext.confirmAll();
        pref = ext.confirm();
        System.assert(TestMethodUtilities.hasMessage(Label.DEPLOYLATER_DT_MUST_BE_FUTURE));
        System.assertEquals(null, pref);

        //AUTO RECHARGE ENABLED
        b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"minCredits":1000,"credits":1348,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ext.deployment.Date__c = System.today().addDays(1);

        ext.deployCall();
        Test.stopTest();

        ext.creditCheckAndValidations();
        ext.confirmAll();
        pref = ext.confirm();
        System.debug('### PAGE MESSAGES: ' + ApexPages.getMessages());
    }
    static testMethod void testNotEnoughCredits() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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
        // Insert Test Steps and Attachments
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Not started',
            'Apex'
        );
        insert testStep; // 1 credit
        Step__c testStep2 = TestMethodUtilities.create(
            'Custom Settings',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Not started',
            'Custom Settings'
        );
        insert testStep2; // 11 credits
        Attachment testAttachment2 = TestMethodUtilities.createAttachment(
            testStep2.Id,
            'Custom Settings',
            '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}'
        );
        insert testAttachment2;
        testStep2.Attachment_Id__c = testAttachment2.Id;
        update testStep2;
        Step__c testStep3 = TestMethodUtilities.create(
            'Users',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            2,
            'Not started',
            'Users'
        );
        insert testStep3; // 1 credit
        Attachment testAttachment3 = TestMethodUtilities.createAttachment(
            testStep3.Id,
            'Users',
            '{"userIds":["0050Y000000K2I9QAK"],"fromSuffix":"dev","toSuffix":"uat","active":true,"userTerritories":false}'
        );
        insert testAttachment3;
        testStep3.Attachment_Id__c = testAttachment3.Id;
        update testStep3;
        Step__c testStep4 = TestMethodUtilities.create(
            'MetaData',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            3,
            'Not started',
            'MetaData'
        );
        insert testStep4; // 6 credits
        Attachment testAttachment4 = TestMethodUtilities.createAttachment(
            testStep4.Id,
            'MetaData',
            '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]'
        );
        insert testAttachment4;
        testStep4.Attachment_Id__c = testAttachment4.Id;
        update testStep4;
        Step__c testStep5 = TestMethodUtilities.create(
            'Translations',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            4,
            'Not started',
            'Translations'
        );
        insert testStep5;
        Attachment testAttachment5 = TestMethodUtilities.createAttachment(
            testStep5.Id,
            'Translations',
            '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]'
        );
        insert testAttachment5; // 10 credits (5 * 2)
        testStep5.Attachment_Id__c = testAttachment5.Id;
        update testStep5;
        Destination_Org__c destOrg = TestMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
        insert destOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        ext.goto_selectDestinationOrgs();

        ext.deployment.Date__c = System.today().addDays(1);
        ext.deployment.Schedule__c = 'Deploy later';
        ext.step_setupSchedule = true;
        Test.startTest();
        List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
        estimations = ext.getEstimations();
        System.debug('########################################################' + estimations);
        System.assertEquals(1, ext.destinationOrgs.size());
        System.assertEquals(29, ext.totalEstimations);
        System.assert(estimations.size() > 0);
        System.assertEquals(1, estimations[0].credits);

        // NOT ENOUGH CREDITS
        System.debug('############################## NOT ENOUGH CREDITS ###########################');
        System.assertEquals(29, ext.totalEstimations);
        System.assert(estimations.size() > 0);
        System.assertEquals(1, estimations[0].credits);
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":0,"credits":0,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ext.deployment.Schedule__c = 'Deploy now';
        ext.deployment.Date__c = System.today().addDays(0);
        ext.creditCheckAndValidations();
        ext.confirmAll();
        pref = ext.confirm();
        System.debug('~£~£~£~£~£~£~££~£~£~£~£~ PAGE MESSAGES: ' + ApexPages.getMessages());
        System.assertEquals(false, ext.goToDeployment);
    }
    static testMethod void testAutoRechargeNotEnabled() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Not started',
            'Apex'
        );
        insert testStep;
        Destination_Org__c destOrg = TestMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
        insert destOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        ext.deployment.Date__c = System.today();
        ext.deployment.Schedule__c = 'Deploy now';
        ext.step_setupSchedule = true;
        ext.getDestinationOrgs();
        String b = '{"' + testStep.Id + '":"1"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
        estimations = ext.getEstimations();
        System.assert(estimations.size() > 0);
        System.assertEquals(1, estimations[0].credits);

        // AUTO RECHARGE NOT ENABLED
        b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":1000,"credits":1348,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ext.creditCheckAndValidations();
        ext.confirmAll();
        pref = ext.confirm();
    }

    static testMethod void testGotoStep_straight_away() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('a', 'b', 'c', 'd', 'e', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create('a', System.now(), System.now(), testFromOrg.Id, 'c', 'd');
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'e', 'f');
        insert testStep;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        pref.getParameters().put('stepId', testStep.Id);
        pref.getParameters().put('gotoStep', 'deployNow');
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
        Test.stopTest();
        System.assertEquals(true, ext.step_addStep);
    }
    static testMethod void test_delete_methods() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('a', 'b', 'c', 'd', 'e', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = TestMethodUtilities.create('a', System.now(), System.now(), testFromOrg.Id, 'c', 'd');
        insert testDeployment;
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Not started',
            'Apex'
        );
        insert testStep;
        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'b', testFromOrg.Id);
        insert testDestOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        Test.startTest();
        ext.selectedStep = testStep.Id;
        ext.deleteStep();
        System.assert([SELECT Id FROM Step__c WHERE Id = :testStep.Id].size() == 0);
        ext.selectedDestOrg = testDestOrg.Id;
        ext.deleteDestOrg();
        System.assert([SELECT Id FROM Destination_Org__c WHERE Id = :testDestOrg.Id].size() == 0);
        Test.stopTest();
    }
    static testMethod void testEstimateDeployment() {
        setupDataDML();
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
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
        // Insert Test Steps and Attachments
        List<Step__c> steps = new List<Step__c>();
        Step__c testStep = TestMethodUtilities.create(
            'Apex',
            'b',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            0,
            'Not started',
            'Apex'
        );
        steps.add(testStep); // 1 credit
        Step__c testStep2 = TestMethodUtilities.create(
            'Custom Settings',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            1,
            'Not started',
            'Custom Settings'
        );
        steps.add(testStep2); // 11 credits
        Step__c testStep3 = TestMethodUtilities.create(
            'Users',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            2,
            'Not started',
            'Users'
        );
        steps.add(testStep3); // 1 credit
        Step__c testStep4 = TestMethodUtilities.create(
            'MetaData',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            3,
            'Not started',
            'MetaData'
        );
        steps.add(testStep4); // 6 credits
        Step__c testStep5 = TestMethodUtilities.create(
            'Translations',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            4,
            'Not started',
            'Translations'
        );
        steps.add(testStep5);
        insert steps;

        Attachment testAttachment2 = TestMethodUtilities.createAttachment(
            steps[1].Id,
            'Custom Settings',
            '{"fromSuffix":"","toSuffix":"","settings":["Apex Test","Branch Management","Continuous Integration","Full Permission Sets step","Full Profiles step","Git Backup","Git MetaData","Org Difference","Selenium Testing","Snapshot Difference","Translations step"],"sco":"Feature (Feature__c)","csName":"Feature__c","prevRes":[{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Apex Test","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Branch Management","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Continuous Integration","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Permission Sets step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Full Profiles step","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git Backup","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Git MetaData","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Org Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Selenium Testing","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Snapshot Difference","s":true},{"type":"List","SetupOwnerId":"00D0Y000000qcpuUAA","Name":"Translations step","s":true}]}'
        );
        insert testAttachment2;
        testStep2.Attachment_Id__c = testAttachment2.Id;
        update steps[1];

        Attachment testAttachment3 = TestMethodUtilities.createAttachment(
            steps[2].Id,
            'Users',
            '{"userIds":["0050Y000000K2I9QAK"],"fromSuffix":"dev","toSuffix":"uat","active":true,"userTerritories":false}'
        );
        insert testAttachment3;
        testStep3.Attachment_Id__c = testAttachment3.Id;
        update steps[2];

        Attachment testAttachment4 = TestMethodUtilities.createAttachment(
            steps[3].Id,
            'MetaData',
            '[{"n":"MarketingProfile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Support Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Custom%3A Sales Profile","s":true,"d":"2017-02-01","b":"David Roberto Venegas","cd":"2016-12-26","cb":"Federico Larsen","t":"Profile"},{"n":"Persona_Permission_Manager","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_View","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"},{"n":"Branch_Management_Permissions_Manage","s":true,"d":"2017-02-01","b":"Federico Larsen","cd":"2017-01-31","cb":"Federico Larsen","t":"PermissionSet"}]'
        );
        insert testAttachment4;
        testStep4.Attachment_Id__c = testAttachment4.Id;
        update steps[3];

        Attachment testAttachment5 = TestMethodUtilities.createAttachment(
            steps[4].Id,
            'Translations',
            '[{"t":"Translations","n":"en_US","s":true},{"t":"Translations","n":"es","s":true}]'
        );
        insert testAttachment5; // 10 credits (5 * 2)
        testStep5.Attachment_Id__c = testAttachment5.Id;
        update steps[4];

        String gitMetadata = '[';
        Integer metadataSize = 20;
        for (Integer i = 1; i <= metadataSize; i++) {
            gitMetadata = gitMetadata + '{"t":"CustomObject","n":"Account' + i + '","cmm":"updated"}';
            if (i != metadataSize)
                gitMetadata = gitMetadata + ',';
            if (i == metadataSize)
                gitMetadata = gitMetadata + ']';
        }
        Step__c testStep6 = TestMethodUtilities.create(
            'Git MetaData',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            5,
            'Not started',
            'Git MetaData'
        );
        insert testStep6; // 50 credits
        Attachment testAttachment6 = TestMethodUtilities.createAttachment(testStep6.Id, 'MetaData', gitMetadata);
        insert testAttachment6;
        testStep6.Attachment_Id__c = testAttachment6.Id;
        update testStep6;
        String deleteMetadata = '[';
        metadataSize = 6;
        for (Integer i = 1; i <= metadataSize; i++) {
            deleteMetadata = deleteMetadata + '{"t":"ApexClass","n":"AccountOperations' + i + '","s":true}';
            if (i != metadataSize)
                deleteMetadata = deleteMetadata + ',';
            if (i == metadataSize)
                deleteMetadata = deleteMetadata + ']';
        }
        Step__c testStep7 = TestMethodUtilities.create(
            'Delete MetaData',
            '0',
            '{"testLevel":"NoTestRun","replacements":[]}',
            testDeployment.Id,
            6,
            'Not started',
            'Delete MetaData'
        );
        insert testStep7; // 11 credits
        Attachment testAttachment7 = TestMethodUtilities.createAttachment(testStep7.Id, 'Delete MetaData', deleteMetadata);
        insert testAttachment7;
        testStep7.Attachment_Id__c = testAttachment7.Id;
        update testStep7;

        Test.startTest();

        Destination_Org__c destOrg = TestMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
        Utilities.Secure_DML(destOrg, Utilities.DML_Action.INS, schema.SObjectType.Destination_Org__c);

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.Id);
        Test.setCurrentPage(pref);

        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));

        ext.goto_selectDestinationOrgs();
        ext.moveUp();
        ext.moveDown();
        ext.getfromOrgFiltered();
        ext.getStepTypes();
        ext.deployment.Date__c = System.today().addDays(1);
        ext.deployment.Schedule__c = 'Deploy later';
        ext.step_setupSchedule = true;

        List<DeploymentWizardExtension.Estimation> estimations = new List<DeploymentWizardExtension.Estimation>();
        estimations = ext.getEstimations();
        Test.stopTest();
        System.debug('########################################################' + estimations);
        System.debug(ext.totalEstimations);
        System.assertEquals(1, ext.destinationOrgs.size());
        System.assertEquals(55, ext.totalEstimations);
        System.assert(estimations.size() > 0);
        System.assertEquals(11, estimations[1].credits);
    }
}