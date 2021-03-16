@isTest
private class TestEditOrg {
    private static String calloutResult = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';

    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @isTest
    static void testSave() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));
            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass');
            insert org;

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            PageReference returnedPage = controller.save();
            PageReference expectedPage = new ApexPages.StandardController(org).view();
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());
        }
    }

    @isTest
    static void testGetMetadataTypes() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            String b = '["ApexPage","ApexClass"]';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass');
            insert org;

            Test.startTest();
            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            Integer actual = controller.getMetadataTypes().size();
            System.assertEquals(2, actual);
            Test.stopTest();
        }
    }

    @isTest
    static void testValidateOrgNoAuthentication() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass', Test_Frequency__c = 'Daily');
            insert org;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));
            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            controller.validate();
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.ADD_AUTHENTICATION));
            Test.stopTest();
        }
    }

    @isTest
    static void testValidateOrg() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(
                Name = 'test',
                Metadata_Types__c = 'ApexPage,ApexClass',
                Oauth_Signature__c = 'test',
                Test_Frequency__c = 'Daily'
            );
            insert org;

            Test.startTest();

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));
            controller.validate();
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.OK_CREDENTIALS));

            org.Test_Frequency__c = 'Daily';
            update org;

            Test.stopTest();
        }
    }

    @isTest
    static void testValidateOrgWrongCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(
                Name = 'test',
                Metadata_Types__c = 'ApexPage,ApexClass',
                Oauth_Signature__c = 'test',
                Test_Frequency__c = 'Daily'
            );
            insert org;

            Test.startTest();
            calloutResult = '{"customerOrg":{"Name":"Copado Ltd 2","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            controller.validate();
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));

            Test.stopTest();
        }
    }

    @isTest
    static void testOrgTypesPicklist() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass');
            insert org;

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));

            Test.startTest();

            System.assert(!controller.orgTypes.isEmpty(), 'No picklist values were retrieved from the Org_Type__c field definition.');

            Boolean hasScratchOrgPatchOption = false;
            Boolean hasCustomDomainOption = false;
            for (SelectOption option : controller.orgTypes) {
                switch on option.getValue() {
                    when 'Scratch Org - Patch' {
                        hasScratchOrgPatchOption = true;
                    }
                    when 'Custom Domain' {
                        hasCustomDomainOption = true;
                    }
                }
            }

            System.assert(hasScratchOrgPatchOption, 'The Scratch Org - Patch option was not found but it should always be present');
            System.assert(hasCustomDomainOption, 'The Custom Domain option was not found but it should always be present');

            Test.stopTest();
        }
    }

    @isTest
    static void testOauthUrl() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass');
            insert org;

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));

            System.assert(!controller.orgTypes.isEmpty(), 'No picklist values were retrieved from the Org_Type__c field definition.');

            org.Org_Type__c = controller.orgTypes[0].getValue();
            controller.save();

            Test.startTest();
            PageReference pageRef = controller.doOauth();
            System.assert(pageRef.getUrl().contains('Authorize'));
            Test.stopTest();
        }
    }

    @isTest
    static void testPasswordParameter() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Org__c org = new Org__c(Name = 'test', Metadata_Types__c = 'ApexPage,ApexClass');
            insert org;

            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            controller.isLicenseEnabled();
            System.assertEquals(false, controller.showError);
            System.assertEquals(true, controller.showOptions);
        }
    }

    @isTest
    static void testOrgCodeAnalysisSettingNotFound() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));
            Org__c org = new Org__c(
                Name = 'test',
                Metadata_Types__c = 'ApexPage,ApexClass',
                Org_Type__c = 'Production/Developer',
                Oauth_Signature__c = 'test'
            );
            insert org;

            Test.startTest();
            EditOrg controller = new EditOrg(new ApexPages.StandardController(org));
            controller.orgCodeAnalysis();
            calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));
            controller.orgCodeAnalysis();
            System.assert(testMethodUtilities.hasMessage(Label.SCA_SETTINGS_NOT_FOUND));
            Test.stopTest();
        }
    }

    @isTest
    static void testOrgComplianceScan() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            calloutResult =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                UserInfo.getOrganizationId() +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(calloutResult, null));

            Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
            insert complianceSetting;

            Environment__c envProd = new Environment__c(
                Name = 'Prod Environment',
                Type__c = 'Production',
                Compliance_Rule_Group__c = complianceSetting.Id
            );
            insert envProd;

            Org__c org = new Org__c(name = 'test', metadata_types__c = 'Layout,Profile,PermissionSet', Environment__c = envProd.Id);
            insert org;

            Test.startTest();
            PageReference pref = Page.EditOrg;
            Test.setCurrentPage(pref);

            EditOrg ext = new EditOrg(new ApexPages.StandardController(org));
            //ext.getTypes();
            ext.orgComplianceScan();
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMPLIANCE_SCAN_REQUESTED));

            ext.runAllTest();
            ext.gotoDxOperations();
            Test.stopTest();
        }
    }

    @isTest
    static void testDeleteOrgCredential() {
        Environment__c envProd = new Environment__c(Name = 'Prod Environment', Type__c = 'Production');
        insert envProd;

        Org__c org = new Org__c(name = 'test', metadata_types__c = 'Layout,Profile,PermissionSet', Environment__c = envProd.Id);
        insert org;

        Test.startTest();
        PageReference pref = Page.EditOrg;
        Test.setCurrentPage(pref);

        EditOrg ext = new EditOrg(new ApexPages.StandardController(org));
        ext.deleteOrgCredential();
        List<Org__c> credential = [SELECT Id FROM Org__c WHERE Name = 'test'];
        System.assert(credential.isEmpty(), 'The org credential could not be deleted.');
        Test.stopTest();
    }
}