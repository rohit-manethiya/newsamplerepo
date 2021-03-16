@IsTest
private with sharing class SeleniumGroupTriggersTest {
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
    private static void test() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c stg = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
        insert stg;

        PageReference pageRef = Page.SeleniumRunGroup;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(stg.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(stg);
        SeleniumTestGroupExtension testRedirectPage = new SeleniumTestGroupExtension(sc);
        testRedirectPage.runGroup();

        Org__c org1 = testMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = testMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;
        Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = stg.Id, Org_Credential__c = org1.id);
        insert goc1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id]);

        Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = stg.Id, Selenium_Test_Suite__c = ts1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts1;
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id]);

        Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = stg.Id, Selenium_Test_Suite__c = ts2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts2;
        System.assertEquals(2, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id]);

        Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = stg.Id, Org_Credential__c = org2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert goc2;
        System.assertEquals(4, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id]);

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete goc2;
        System.assertEquals(2, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id]);

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete gts2;
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id AND Selenium_Settings__c = :s.Id]);

        Selenium_Settings__c s2 = new Selenium_Settings__c(Name = 'test settings 2', Webdriver_URL__c = 'http://drive2.me');
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert s2;
        stg.Selenium_Settings__c = s2.Id;
        stg.Manage_Test_Runs_manually__c = false;

        testRedirectPage.runGroup();
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update stg;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id AND Selenium_Settings__c = :s.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :stg.Id AND Selenium_Settings__c = :s2.Id]);
    }

    @IsTest
    private static void testManuallyManaged() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id, Manage_Test_Runs_manually__c = true);
        insert g;
        Org__c org1 = testMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = testMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;
        Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = org1.id);
        insert goc1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts2;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = org2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert goc2;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete goc2;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete gts2;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id AND Selenium_Settings__c = :s.Id]);

        Selenium_Settings__c s2 = new Selenium_Settings__c(Name = 'test settings 2', Webdriver_URL__c = 'http://drive2.me');
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert s2;
        g.Selenium_Settings__c = s2.Id;

        SeleniumTestRunTriggerHelper.inTrigger = false;
        update g;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id AND Selenium_Settings__c = :s.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id AND Selenium_Settings__c = :s2.Id]);
    }

    @IsTest
    private static void testGroupValidations() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;
        Org__c testOrg3 = CMTestMethodUtilities.createOrg('MyOrg3', 'Production3', 'SFDC_OrgId3', null, null, system.now(), env1.Id);
        insert testOrg3;

        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
        insert g;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;

        Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = testOrg1.id);
        insert goc1;
        Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = testOrg3.id);
        insert goc2;

        g.Environment__c = env2.Id;
        try {
            update g;
        } catch (Exception e) {
            System.assert(true, e.getMessage().contains(Label.ENV_NOT_MATCHING));
        }

        Selenium_Group_Org_Credential__c goc3 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = testOrg2.id);
        insert goc3;
        System.assertEquals(3, [SELECT COUNT() FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c = :g.Id]);

        g.Environment__c = env1.Id;
        try {
            update g;
        } catch (Exception e) {
            System.assert(true, e.getMessage().contains(Label.ENV_NOT_MATCHING));
        }

        delete goc3;
        update g;
        System.assertEquals(2, [SELECT COUNT() FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c = :g.Id]);
    }

    @IsTest
    private static void testGroupCallout() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
        insert g;
        Org__c org1 = testMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g.Id, Org_Credential__c = org1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert goc1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts1;
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id AND Selenium_Settings__c = :s.Id]);

        Selenium_Test_Run__c tr = [SELECT Id FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id];
        tr.Last_Status__c = 'Completed successfully';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update tr;
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Selenium_Test_Group__c WHERE Id = :g.Id].Status__c);
    }
}