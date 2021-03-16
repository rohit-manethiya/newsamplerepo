@IsTest
private with sharing class ValidateOrgTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.setTestSettingsEE();
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void testSuccess() {
        Org__c testOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', null);
        insert testOrg;

        PageReference pref = Page.validateOrg;
        pref.getParameters().put('id', testOrg.id);
        Test.setCurrentPage(pref);

        Test.startTest();
        ValidateOrgExtension ext = new ValidateOrgExtension(new ApexPages.StandardController(testOrg));
        String b =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            testOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        PageReference pageRef = ext.validateOrg();
        Test.stopTest();
        Org__c result = [SELECT Id, Validated_date__c, sfdc_org_id__c FROM Org__c WHERE Id = :testOrg.Id LIMIT 1];
        System.assertEquals('/' + ((String) testOrg.Id).substring(0, 15), pageRef.getUrl());
    }

    @IsTest
    private static void testEditOrg() {
        Org__c testOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME2', null);
        insert testOrg;
        EditOrg ctrl = new EditOrg(new ApexPages.StandardController(testOrg));
        ctrl.save();
        ctrl.doOauth();
    }
}