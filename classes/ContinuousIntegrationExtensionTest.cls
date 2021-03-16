@isTest
private class ContinuousIntegrationExtensionTest {
    @testSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    @isTest
    static void test() {
        Git_Repository__c git = new Git_Repository__c(Name = 'test git', URI__c = 'https://git.com');
        insert git;
        Org__c org = new Org__c(Name = 'test org');
        insert org;
        Continuous_Integration__c ci = new Continuous_Integration__c(Name = 'test ci',
                Destination_Org_Credential__c = org.Id,
                Git_Repository__c = git.Id);
        insert ci;
        Test.startTest();
        ContinuousIntegrationExtension ct = new ContinuousIntegrationExtension(new ApexPages.StandardController(ci));
        ct.getCI();
        System.assertNotEquals(null, ct.ciStatusImgUrl);

        String b = '{"Status":"Ok"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ct.showHookUrl();
        System.assertNotEquals(null, ct.hookUrl);
        ct.hideHookUrl();
        ct.messageName = 'test';
        ct.showMessage();

        System.assert(ct.isCIenabled);

        Test.stopTest();
    }
    @isTest
    static void testExe() {
        Git_Repository__c git = new Git_Repository__c(Name = 'test git', URI__c = 'https://git.com');
        insert git;
        Org__c org = new Org__c(Name = 'test org');
        insert org;
        Continuous_Integration__c ci = new Continuous_Integration__c(Name = 'test ci',
                Destination_Org_Credential__c = org.Id,
                Git_Repository__c = git.Id);
        insert ci;
        Test.startTest();
        ContinuousIntegrationExtension ct = new ContinuousIntegrationExtension(new ApexPages.StandardController(ci));
        ct.getCI();
        System.assertNotEquals(null, ct.ciStatusImgUrl);

        String b = '{"Status":"Ok"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        ct.executeCI();
        Test.stopTest();
    }
}