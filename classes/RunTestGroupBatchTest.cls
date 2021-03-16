@IsTest
private with sharing class RunTestGroupBatchTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        TestMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, true);
    }

    @IsTest
    private static void testBehavior() {
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        testPromotion.Source_Org_Credential__c = testOrg1.Id;
        testPromotion.Destination_Environment__c = env2.Id;
        testPromotion.Destination_Org_Credential__c = testOrg2.Id;
        insert testPromotion;

        Set<Id> promotionIds = new Set<Id>();
        List<Promotion__c> promotions = new List<Promotion__c>();
        promotions.add(testPromotion);

        List<User_Story__c> userStories = new List<User_Story__c>();
        for (Promotion__c p : promotions) {
            promotionIds.add(p.Id);
            User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
            testUserStory.Environment__c = env1.Id;
            testUserStory.Project__c = testProject.Id;
            testUserStory.Promote_Change__c = true;
            testUserStory.Promote_and_Deploy__c = true;
            userStories.add(testUserStory);
        }
        insert userStories;
        System.assertNotEquals(0, userStories.size());

        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        Integer counter = 0;
        for (User_Story__c u : userStories) {
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = u.Id;
            pus.Promotion__c = promotions[counter].Id;
            promotedStories.add(pus);
            counter++;
            if (counter == (promotions.size() - 1))
                counter = 0;
        }
        insert promotedStories;
        System.assertNotEquals(0, promotedStories.size());

        System.assert(LicenseHelper.isCSTEnabled());

        // now setup a test group.
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
        insert g;
        Org__c org1 = TestMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = TestMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;
        Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = org1.id);
        insert goc1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts1;

        Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts2;

        Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = org2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert goc2;

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete goc2;

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete gts2;

        Selenium_Settings__c s2 = new Selenium_Settings__c(Name = 'test settings 2', Webdriver_URL__c = 'http://drive2.me');
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert s2;
        g.Selenium_Settings__c = s2.Id;

        SeleniumTestRunTriggerHelper.inTrigger = false;
        // set the Group Environment as Prod
        g.Environment__c = env2.Id;
        g.Type__c = 'Regression Test';
        update g;

        Selenium_Test_Group__c g2 = new Selenium_Test_Group__c(Name = 'test group2', Selenium_Settings__c = s.id);
        g2.Environment__c = env2.Id;
        insert g2;
        User_Story_Selenium_Test__c ug = new User_Story_Selenium_Test__c(
            Name = 'test group2',
            User_Story__c = userStories.get(0).Id,
            Selenium_Test_Group__c = g2.Id
        );
        insert ug;

        Test.startTest();
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Integer numOfGroups = RunTestGroupsBatch.runSeleniumTestsOfPromotionId(
            testPromotion.Id,
            RunTestGroupsBatch.ENV_DEST,
            RunTestGroupsBatch.MODE_ALL_TESTS
        );
        System.assertEquals(2, numOfGroups); // verify that the two test groups were found and sent for execution

        Test.stopTest(); // since batch apex is async, this will force it to stop before executing further method lines.
    }
}