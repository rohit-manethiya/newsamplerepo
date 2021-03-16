@isTest
private class TestCloneSeleniumTestCaseExtension {
    @testSetup static void setupTestData(){
        TestUtilities.enableLicenses(10, 10, 10);
    }
    static testMethod void testClone(){
        CMTestMethodUtilities.enableSelenium();
        Selenium_Test_Case__c tc = new Selenium_Test_Case__c(name = 'Test x');
        insert tc;
        Attachment a = new Attachment(Name='Copado.SeleniumTestCase.json', ParentId=tc.Id, body=Blob.valueOf('{"name": "Test x"}'));
        insert a;
        
        CloneSeleniumTestCaseExtension ext = new CloneSeleniumTestCaseExtension(new ApexPages.StandardController(tc));
        ext.doClone();
        tc = [SELECT Id, Name, Version__c FROM Selenium_Test_Case__c WHERE name = 'Test x-v2'];
        System.assertEquals('2', tc.Version__c);
        //System.assertEquals(1, [select count() from Selenium_Test_Case__c where name = 'Test x-v2']);
    }
}