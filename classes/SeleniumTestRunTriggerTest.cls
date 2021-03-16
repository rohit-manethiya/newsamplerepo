@IsTest
private class SeleniumTestRunTriggerTest {
    @TestSetup
    static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void test_part1() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
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
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts2;
        System.assertEquals(2, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Group__c WHERE id = :g.Id AND Status__c = '']);
        List<Selenium_Test_Run__c> runs = [SELECT id FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id];

        //1st queued
        runs.get(0).Last_Status__c = 'Queued';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(0);
        System.assertEquals('In Progress', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //2nd queued
        runs.get(1).Last_Status__c = 'Queued';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        System.assertEquals('In Progress', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //1st in progress
        runs.get(0).Last_Status__c = 'In Progress';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(0);
        System.assertEquals('In Progress', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //2nd in progress
        runs.get(1).Last_Status__c = 'In Progress';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        System.assertEquals('In Progress', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //1st fails
        runs.get(0).Last_Status__c = 'Completed with Errors';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(0);
        Datetime now = System.now();
        Selenium_Test_Group__c g0 = [SELECT Status__c, Status_Date__c FROM Selenium_Test_Group__c WHERE id = :g.Id];
        System.assertEquals('In Progress', g0.Status__c);

        //2nd fails
        runs.get(1).Last_Status__c = 'Completed with Errors';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        Datetime now2 = System.now();
        Selenium_Test_Group__c g1 = [SELECT Status__c, Status_Date__c FROM Selenium_Test_Group__c WHERE id = :g.Id];
        System.assertEquals('Completed with Errors', g1.Status__c);
    }

    @IsTest
    private static void test_part2() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id);
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
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert goc1;
        System.assertEquals(0, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts1.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts1;
        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g.Id, Selenium_Test_Suite__c = ts2.id);
        SeleniumTestRunTriggerHelper.inTrigger = false;
        insert gts2;
        System.assertEquals(2, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id]);

        System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Group__c WHERE id = :g.Id AND Status__c = '']);
        List<Selenium_Test_Run__c> runs = [SELECT id FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g.Id];

        // pre-set the values as the next test expects.
        runs.get(1).Last_Status__c = 'Completed with Errors';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);

        //now 1st ok
        runs.get(0).Last_Status__c = 'Completed Successfully';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(0);
        Datetime now = System.now();
        Selenium_Test_Group__c g0 = [SELECT Status__c, Status_Date__c FROM Selenium_Test_Group__c WHERE id = :g.Id];
        System.assertEquals('Completed with Errors', g0.Status__c);
        System.assertEquals(now.format('yyyy-MM-dd, HH:mm'), g0.Status_Date__c.format('yyyy-MM-dd, HH:mm'));

        //now 2nd ok
        runs.get(1).Last_Status__c = 'Completed Successfully';
        Datetime now2 = System.now();
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        Selenium_Test_Group__c g1 = [SELECT Status__c, Status_Date__c FROM Selenium_Test_Group__c WHERE id = :g.Id];
        System.assertEquals('Completed Successfully', g1.Status__c);
        System.assertEquals(now2.format('yyyy-MM-dd, HH:mm'), g1.Status_Date__c.format('yyyy-MM-dd, HH:mm'));

        //now 2nd
        runs.get(1).Last_Status__c = 'Provider Failure';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //now 2nd staring
        runs.get(1).Last_Status__c = 'Starting';
        SeleniumTestRunTriggerHelper.inTrigger = false;
        update runs.get(1);
        System.assertEquals('In Progress', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);

        //only 1 run success
        SeleniumTestRunTriggerHelper.inTrigger = false;
        delete runs.get(1);
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Selenium_Test_Group__c WHERE id = :g.Id].Status__c);
    }
}