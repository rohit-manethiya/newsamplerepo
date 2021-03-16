@IsTest
private with sharing class SeleniumTestCasePromoteRollbackTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, true, false, false);
    }

    @IsTest
    private static void test_Rollback_No_Prev_Version() {
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case__c tc1 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '1');
        insert tc1;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = s.Id, Selenium_Test_Case__c = tc1.Id);
        insert cs;

        PageReference pageRef = Page.SeleniumTestCaseRollback;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', tc1.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(tc1);
        SeleniumTestCasePromoteRollback controller = new SeleniumTestCasePromoteRollback(std);
        controller.initRollback();

        System.assertEquals(false, controller.isPromote);
        System.assertEquals(false, controller.processIsDone);
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.TEST_CASE_NO_PREV_VERSION));
    }

    @IsTest
    private static void test_Rollback_Success() {
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case__c tc1 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '1');
        insert tc1;

        Selenium_Test_Case__c tc2 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '2', Previous_Version__c = tc1.Id);
        insert tc2;

        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = s.Id, Selenium_Test_Case__c = tc2.Id);
        insert cs;

        PageReference pageRef = Page.SeleniumTestCaseRollback;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', tc2.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(tc2);
        SeleniumTestCasePromoteRollback controller = new SeleniumTestCasePromoteRollback(std);
        controller.initRollback();

        System.assertEquals(false, controller.isPromote);
        System.assertEquals(false, controller.processIsDone);
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.TEST_CASE_NO_PREV_VERSION));
        System.assertEquals(1, controller.testCasePerSuite.size());
        System.assertEquals(tc2.Id, controller.testCasePerSuite.get(0).tcs.Selenium_Test_Case__c);
        System.assertEquals(true, controller.testCasePerSuite.get(0).selected);

        controller.promoteOrRollback();
        System.assertEquals(true, controller.processIsDone);
        System.assertEquals(tc1.Id, [SELECT Selenium_Test_Case__c FROM Selenium_Test_Case_Per_Suite__c WHERE id = :cs.Id].Selenium_Test_Case__c);

        //check nothing to rollback
        controller.promoteOrRollback();
        System.assertEquals(false, testMethodUtilities.hasMessage('Test Case (Version:'));
    }

    @IsTest
    private static void test_Promote_No_Prev_Version() {
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case__c tc1 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '1');
        insert tc1;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = s.Id, Selenium_Test_Case__c = tc1.Id);
        insert cs;

        PageReference pageRef = Page.SeleniumTestCasePromote;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', tc1.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(tc1);
        SeleniumTestCasePromoteRollback controller = new SeleniumTestCasePromoteRollback(std);
        controller.initPromote();

        System.assertEquals(true, controller.isPromote);
        System.assertEquals(false, controller.processIsDone);
        System.assertEquals(true, testMethodUtilities.hasMessage('There is no previous version'));
    }

    @IsTest
    private static void test_Promote_Success() {
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case__c tc1 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '1');
        insert tc1;

        Selenium_Test_Case__c tc2 = new Selenium_Test_Case__c(Name = 'UnitTest', Version__c = '2', Previous_Version__c = tc1.Id);
        insert tc2;

        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = s.Id, Selenium_Test_Case__c = tc1.Id);
        insert cs;

        PageReference pageRef = Page.SeleniumTestCasePromote;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', tc2.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(tc2);
        SeleniumTestCasePromoteRollback controller = new SeleniumTestCasePromoteRollback(std);
        controller.initPromote();

        System.assertEquals(true, controller.isPromote);
        System.assertEquals(false, controller.processIsDone);
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.TEST_CASE_NO_NEXT_VERSION));
        System.assertEquals(1, controller.testCasePerSuite.size());
        System.assertEquals(tc1.Id, controller.testCasePerSuite.get(0).tcs.Selenium_Test_Case__c);
        System.assertEquals(true, controller.testCasePerSuite.get(0).selected);

        controller.testCasePerSuite.get(0).selected = false;
        controller.promoteOrRollback();
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.SELECT_AT_LEAST_ONE_ITEM));
        controller.testCasePerSuite.get(0).selected = true;
        controller.promoteOrRollback();
        System.assertEquals(true, controller.processIsDone);
        System.assertEquals(false, controller.showList);
        System.assertEquals(tc2.Id, [SELECT Selenium_Test_Case__c FROM Selenium_Test_Case_Per_Suite__c WHERE id = :cs.Id].Selenium_Test_Case__c);

        //check nothing to promote
        controller.promoteOrRollback();
        System.assertEquals(false, testMethodUtilities.hasMessage('Test Case (Version:'));
    }
}