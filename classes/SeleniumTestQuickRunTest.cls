@IsTest
private with sharing class SeleniumTestQuickRunTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void SeleniumTestQuickRun() {
        Selenium_Settings__c se = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c='http://drive.me');
        insert se;
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name='UnitTest');
        insert s;
        Selenium_Test_Case__c c = new Selenium_Test_Case__c(Name='UnitTest');
        insert c;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c=s.Id, Selenium_Test_Case__c=c.Id);
        insert cs;

        Selenium_Test_Run__c run = new Selenium_Test_Run__c(Selenium_Test_Suite__c=s.Id, Selenium_Settings__c=se.id);
        insert run;

        String expectSuiteId, expectRunId, expectSettingsId;

        List<String> aliases = new List<String>{'RnD0312', 'rNd78'};

        for(String alias : aliases) {
            System.debug('#TEST# Try running caseId. custom setting should be created before.');

            PageReference pageRef = Page.SeleniumTestQuickRun;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('caseId', c.Id);

            SeleniumTestQuickRun controller = new SeleniumTestQuickRun();
            controller.userAlias = alias;
            pageRef = controller.quickRun();
            System.assertEquals(null, pageRef);
            controller.settings.Webdriver_URL__c = 'http://copado.com/wd/hub/';
            controller.settings.Default_Org_Credential__c = null;
            pageRef = controller.save();
            System.assertNotEquals(null, pageRef);

            expectSuiteId = controller.suite.Id;
            expectRunId = controller.run.Id;
            expectSettingsId = controller.settings.Id;

            System.debug('s '+controller.suite.Id+' '+controller.suite.Name);
            System.debug('e '+controller.settings.Id+' '+controller.settings.Name);
            System.debug('r '+controller.run.Id+' '+controller.run.Name);


            System.debug('#TEST# Try running caseId again');
            pageRef = Page.SeleniumTestQuickRun;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('caseId', c.Id);
            controller = new SeleniumTestQuickRun();
            controller.userAlias = alias;
            pageRef = controller.quickRun();
            System.debug('s '+controller.suite.Id+' '+controller.suite.Name);
            System.debug('e '+controller.settings.Id+' '+controller.settings.Name);
            System.debug('r '+controller.run.Id+' '+controller.run.Name);
            System.debug('#TEST# ... confirming');
            pageRef = controller.quickRunConfirmed();
            System.assertNotEquals(null, pageRef);

            // no new objects should be used
            System.assertEquals(expectSuiteId, controller.suite.Id);
            System.assertEquals(expectRunId, controller.run.Id);
            System.assertEquals(expectSettingsId, controller.settings.Id);

            System.debug('#TEST# Try running suite');
            pageRef = Page.SeleniumTestQuickRun;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('suiteId', expectSuiteId);
            controller = new SeleniumTestQuickRun();
            controller.userAlias = alias;
            pageRef = controller.quickRun();
            System.assertNotEquals(null, pageRef);

            // no new objects should be used
            System.assertEquals(expectSuiteId, controller.suite.Id);
            System.assertEquals(expectRunId, controller.run.Id);
            System.assertEquals(expectSettingsId, controller.settings.Id);
        }
    }

    @IsTest
    private static void TestErrorMsgForAlreadyRunning(){
        Selenium_Settings__c se = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c='http://drive.me');
        insert se;
        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name='UnitTest');
        insert s;
        Selenium_Test_Case__c c = new Selenium_Test_Case__c(Name='UnitTest');
        insert c;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c=s.Id, Selenium_Test_Case__c=c.Id);
        insert cs;
        Selenium_Test_Run__c run = new Selenium_Test_Run__c(Selenium_Test_Suite__c=s.Id, Last_Status__c='In Progress', Selenium_Settings__c=se.id);
        insert run;

        // Set runId and mode param in page
        PageReference pageRef = Page.SeleniumTestQuickRun;
        Test.setCurrentPage(pageRef);
        //ApexPages.currentPage().getParameters().put('mode', 'continue');
        ApexPages.currentPage().getParameters().put('runId', run.Id);

        SeleniumTestQuickRun controller = new SeleniumTestQuickRun();
        //controller.userAlias = alias;
        pageRef = controller.quickRun();
        system.assert(TestMethodUtilities.hasMessage(Label.This_test_is_already_running));
    }
}