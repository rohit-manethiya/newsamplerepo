@IsTest
private with sharing class TestAppHome {
    @TestSetup
    static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    @IsTest
    static void testInitSuccess() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        envList.add(envDev);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        Org__c orgDev = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', orgId, null, null, System.now(), envDev.Id);
        orgList.add(orgDev);
        insert orgList;

        appHome con = new appHome();
        Test.startTest();
        String b =
            '{"transactions":[{"id":"402881a23e3c17b7013e3c17c8770000","date":"Apr 24, 2013 2:49:51 PM","customerOrgId":"' +
            UserInfo.getOrganizationId() +
            '","credits":-25,"type":"Free credits","userId":"' +
            UserInfo.getUserId() +
            '","jobInfo":"New account free credits"},{"id":"402881a23e3c17b7013e3c17c8770000","date":"Apr 24, 2013 2:49:51 PM","customerOrgId":"' +
            UserInfo.getOrganizationId() +
            '","credits":25,"type":"Free credits","userId":"' +
            UserInfo.getUserId() +
            '","jobInfo":"New account free credits"}],"customerOrg":{"Name":"Copado Ltd","orgId":"' +
            UserInfo.getOrganizationId() +
            '","autoRecharge":false,"credits":25,"id":1},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            UserInfo.getOrganizationId() +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"fl@copado.com","userFullName__is_set":true,"userFullName":"Federico Larsen","userId__is_set":true,"userId":"' +
            UserInfo.getUserId() +
            '","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"fl@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.getTransactions();
        Test.stopTest();
        System.assertEquals(1, con.transactionsList.size());
    }

    @IsTest
    static void testVlocityOperations() {
        appHome con = new appHome();
        Test.startTest();
        con.vlocityFeatureOperations();
        Feature__c vlocityFeature = con.getVlocityFeature();
        System.assertNotEquals(null, vlocityFeature);
        System.assertEquals(
            con.canToggleVlocity,
            FeatureManagement.checkPermission('Enable_Vlocity_Integration'),
            'This custom permission flag is reflecting incorrect Vlocity access information.'
        );
        Test.stopTest();
    }

    @IsTest
    static void testInitError() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        envList.add(envDev);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        Org__c orgDev = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', orgId, null, null, System.now(), envDev.Id);
        orgList.add(orgDev);
        insert orgList;

        appHome con = new appHome();
        Test.startTest();
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.getTransactions();
        Test.stopTest();
        System.assert(testMethodUtilities.hasMessage('Attempt to de-reference a null object'));
    }

    @IsTest
    static void testCSTBindButtons() {
        appHome con = new appHome();
        Test.startTest();
        PageReference p = con.cstBindExtensionToOrg();
        // This would return a url without API key, hence the /<APIKEY>/ at the end
        System.assert(p.getUrl().startsWith('copado:setupext//'));
    }

    @IsTest
    static void testResetAPIKeyError() {
        appHome con = new appHome();
        Test.startTest();
        con.getAPIKey();
        con.createAPIKey();
        Test.stopTest();
        System.assert(testMethodUtilities.hasMessage('Methods defined as TestMethod do not support Web service callouts'));
    }

    @IsTest
    static void testResetAPIKeySuccess() {
        appHome con = new appHome();
        Test.startTest();
        con.getAPIKey();
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.createAPIKey();
        System.assertEquals(true, String.isNotBlank(con.responseBody));
        con.updatePrivateSettings();
        Test.stopTest();
    }

    /**
     * Test happy path of the callout.
     */
    @IsTest
    static void testRefreshCopadoInstallation() {
        String b = '{"ok":"Features refreshed correctly","isSuccess":true,"isFinished":true}';
        appHome con = new appHome();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.refreshFeatures();
        System.assert(ApexPages.getMessages()[0].getDetail().contains('Features refreshed correctly'));
        System.assertEquals(ApexPages.Severity.CONFIRM, ApexPages.getMessages()[0].getSeverity());
        Test.stopTest();
    }

    /**
     * Test an error coming from the callout.
     */
    @IsTest
    static void testRefreshCopadoInstallationError() {
        String b = '{"error":"An error has occurred","isSuccess":true,"isFinished":true}';
        appHome con = new appHome();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.refreshFeatures();
        System.assert(ApexPages.getMessages()[0].getDetail().contains('An error has occurred'));
        System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
        Test.stopTest();
    }

    @IsTest
    static void testRegisterCopado() {
        PageReference pageRef = Page.AppHome;
        Test.setCurrentPage(pageRef);

        String response = '{"isSuccess":true, "isFinished":true}';
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        appHome appHomeController = new appHome();
        System.assert(!appHomeController.isApplicationRegistered, 'Application should not be registered');
        appHomeController.registerCopado();
        System.assert(appHomeController.isApplicationRegistered, 'Application should be registered');
        Test.stopTest();

        System.assertEquals(ApexPages.Severity.CONFIRM, ApexPages.getMessages()[0].getSeverity(), 'Expected severity message should be CONFIRM');
        System.assertEquals('Copado Application Registered Successfully', ApexPages.getMessages()[0].getDetail(), 'Notification message unexpected');
    }
}