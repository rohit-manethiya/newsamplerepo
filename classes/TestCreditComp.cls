@IsTest
private class TestCreditComp {
    @TestSetup static void setupTestData() {
        insert TestUtilities.getTestSettings();
    }

    static testMethod void testSuccess() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        envList.add(envDev);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        Org__c orgDev = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', orgId, null, null, System.now(), envDev.Id);
        orgList.add(orgDev);
        insert orgList;

        Test.startTest();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        creditsCompController con = new creditsCompController();
        Test.stopTest();
        System.assertEquals(false, con.showError);
        System.assertEquals('', con.errorMessage);
    }

    static testMethod void testInitError() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        envList.add(envDev);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        Org__c orgDev = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', orgId, null, null, System.now(), envDev.Id);
        orgList.add(orgDev);
        insert orgList;

        Test.startTest();
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        creditsCompController con = new creditsCompController();
        Test.stopTest();
        System.assertEquals(true, con.showError);
        System.assertEquals('System.NullPointerException: Attempt to de-reference a null object', con.errorMessage);
    }

    static testMethod void testLicenseManagerPageReference() {
        creditsCompController con = new creditsCompController();
        System.assertEquals(con.getLicenseManagerReference().getUrl(), Page.LicenseManager.setRedirect(true).getUrl());
    }
}