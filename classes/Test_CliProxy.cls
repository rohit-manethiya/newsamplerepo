@IsTest
public with sharing class Test_CliProxy {
    @TestSetup
    public static void setUpData() {
        User sysUs = new User();
        sysUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        sysUs.LastName = 'LastName';
        sysUs.Email = 'test1@test1.com';
        sysUs.Username = 'psysUser000@clitest.com' + System.currentTimeMillis();
        sysUs.CompanyName = 'TEST';
        sysUs.Title = 'title';
        sysUs.Alias = 'alias';
        sysUs.TimeZoneSidKey = 'America/Los_Angeles';
        sysUs.EmailEncodingKey = 'UTF-8';
        sysUs.LanguageLocaleKey = 'en_US';
        sysUs.LocaleSidKey = 'en_US';

        User stdUs = new User();
        stdUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        stdUs.LastName = 'LastName';
        stdUs.Email = 'test2@test2.com';
        stdUs.Username = 'pstdUser002@amamama.com' + System.currentTimeMillis();
        stdUs.CompanyName = 'TEST';
        stdUs.Title = 'title2';
        stdUs.Alias = 'alias2';
        stdUs.TimeZoneSidKey = 'America/Los_Angeles';
        stdUs.EmailEncodingKey = 'UTF-8';
        stdUs.LanguageLocaleKey = 'en_US';
        stdUs.LocaleSidKey = 'en_US';
        insert new List<User>{
                sysUs, stdUs
        };

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 1);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', 2);
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 2);

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = sysUs.Id, PermissionSetId = ps.Id);
    }

    @IsTest
    public static void noLicense() {
        Test.startTest();
        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        WorkSetService.WorkSetWrapper wrks = new WorkSetService.WorkSetWrapper();
        wrks.criteria = 'Id';
        wrks.value = 'value';
        CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
        reqBody.mainService = 'work';
        reqBody.subService = 'set';
        reqBody.body = JSON.serialize(wrks);
        RestContext.request = req;
        RestContext.response = res;
        String response = CliProxy.doPost();

        CliSfDataWrapper resp = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
        System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.ERROR.name());
        System.assertEquals(resp.message, Label.CCM_License_Restriction);

        Test.stopTest();
    }

    @IsTest
    public static void noInterfaceFound() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        Test.startTest();
        System.runAs(u) {
            RestResponse res = new RestResponse();
            RestRequest req = new RestRequest();
            WorkSetService.WorkSetWrapper wrks = new WorkSetService.WorkSetWrapper();
            wrks.criteria = 'Id';
            wrks.value = 'value';
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'wr';
            reqBody.subService = 'st';
            reqBody.body = JSON.serialize(wrks);
            RestContext.request = commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            System.debug(response);

            CliSfDataWrapper resp = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);

            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.ERROR.name());
            System.assertEquals(resp.message, Label.UnSupportedOperation);
        }

        Test.stopTest();
    }
    public static RestRequest commonRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/clioperations';  //Request URL
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(body);

        return req;
    }

}