@IsTest
private with sharing class SeleniumTestRunResultsTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void test_SeleniumTestRun_Result() {
        Selenium_Settings__c se = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert se;
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case__c c = new Selenium_Test_Case__c(Name = 'UnitTest');
        insert c;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = s.Id, Selenium_Test_Case__c = c.Id);
        insert cs;

        Selenium_Test_Run__c run = new Selenium_Test_Run__c(Selenium_Test_Suite__c = s.Id, Batch_No__c = 1, Selenium_Settings__c = se.id);
        insert run;

        Selenium_Test_Result__c r = new Selenium_Test_Result__c(
            Selenium_Test_Run__c = run.Id,
            Platform__c = 'dummy',
            Selenium_Test_Suite__c = s.Id,
            Batch_No__c = 1
        );
        insert r;

        PageReference pageRef = Page.SeleniumTestRunDetailOverride;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', run.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(run);
        SeleniumTestRunResults controller = new SeleniumTestRunResults(std);

        // empty, no attachments
        System.assertNotEquals(null, controller.getReports());

        // empty. incorrect filename
        Attachment a = new Attachment(parentId = r.Id, name = 'dummy', body = Blob.valueOf('dummy'));
        insert a;
        System.assertNotEquals(null, controller.getReports());
        System.assertEquals(0, controller.getReports().size());

        // works.
        Attachment a1 = new Attachment(parentId = r.Id, name = 'Selenese-dummy.html', body = Blob.valueOf('dummy'));
        insert a1;
        System.assertNotEquals(null, controller.getReports());
        System.assertEquals(1, controller.getReports().size());
    }
}