@IsTest
private with sharing class TestRegisterCopado {
    private static final String DEFAULT_COPADO_NAMESPACE = 'copado__';
    // The default backend server for playgrounds is Google Cloud Platform
    private static final String DEFAULT_COPADO_BACKEND_URL = 'https://api.backend.copado.com';

    @TestSetup
    static void testSetup() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void testPopulateDefaultSettings() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            RegisterCopado.setDefaultSettings(DEFAULT_COPADO_BACKEND_URL);
            Test.stopTest();
        }

        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        System.assertEquals(DEFAULT_COPADO_NAMESPACE, orgDefaultSetting.Namespace__c, 'Incorrect namespace in default setting');
        System.assertEquals(DEFAULT_COPADO_BACKEND_URL, orgDefaultSetting.Server_URL__c, 'Incorrect Server URL in default setting');
    }

    @IsTest
    static void testDoNotPopulateDefaultSettings() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        orgDefaultSetting.Namespace__c = 'TestNamespace';
        orgDefaultSetting.Server_URL__c = 'TestServerURL';
        upsert orgDefaultSetting;

        System.runAs(sysUser) {
            Test.startTest();
            RegisterCopado.setDefaultSettings(DEFAULT_COPADO_BACKEND_URL);
            Test.stopTest();
        }

        orgDefaultSetting = Settings__c.getOrgDefaults();
        System.assertEquals('TestNamespace', orgDefaultSetting.Namespace__c, 'Incorrect namespace in default setting');
        System.assertEquals('TestServerURL', orgDefaultSetting.Server_URL__c, 'Incorrect Server URL in default setting');
    }

    @IsTest
    static void testRegisterCopado() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            String response = '{"isSuccess":true, "isFinished":true}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            Test.startTest();
            RegisterCopado.setUpCopadoRegistration();
            Test.stopTest();
        }

        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        System.assert(String.isNotBlank(orgDefaultSetting.CryptoKEY__c), 'Crypto key should have been populated');
    }

    // This not possible from a functional perspective but we handle it in case of an unexpected scenario
    @IsTest
    static void testRegisterCopadoCryptoKeyAlreadyExists() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        orgDefaultSetting.CryptoKEY__c = 'CryptoKeyTest';
        upsert orgDefaultSetting;

        System.runAs(sysUser) {
            String response = '{"isSuccess": true, "isFinished": true}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            Test.startTest();
            RegisterCopado.setUpCopadoRegistration();
            Test.stopTest();
        }

        orgDefaultSetting = Settings__c.getOrgDefaults();
        System.assertEquals('CryptoKeyTest', orgDefaultSetting.CryptoKEY__c, 'Crypto key should not have been changed');
    }
}