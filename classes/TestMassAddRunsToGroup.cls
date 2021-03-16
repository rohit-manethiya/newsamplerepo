@IsTest
private class TestMassAddRunsToGroup {

    @TestSetup static void setupTestData() {
        TestUtilities.enableLicenses(10, 10, 10);
    }

    private static testMethod void testMassAddRunsToGroupWithData() {

        CMTestMethodUtilities.enableSelenium();
        Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert seleniumSetting;
        Selenium_Test_Group__c seleniumTestGroup = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = seleniumSetting.id, Manage_Test_Runs_manually__c = true);
        insert seleniumTestGroup;
        Org__c org1 = testMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(Name = 'test suite1');
        insert ts1;

        Selenium_Test_Run__c tr = new Selenium_Test_Run__c(Name = 'test1',
                Selenium_Test_Suite__c = ts1.Id,
                Selenium_Settings__c = seleniumSetting.Id);

        List<Selenium_Test_Run__c> seleniumTestRunList = new List<Selenium_Test_Run__c>();
        seleniumTestRunList.add(tr);

        insert seleniumTestRunList;

        ApexPages.StandardSetController std = new ApexPages.StandardSetController(seleniumTestRunList);
        std.setSelected(seleniumTestRunList);

        MassAddRunsToGroup custom = new MassAddRunsToGroup(std);
        custom.dummy.Selenium_Test_Group__c = seleniumTestGroup.Id;

        System.assertEquals(1, std.getSelected().size());

        custom.cancel();
        custom.addTestRunsToGroup();

        seleniumTestRunList = [SELECT Id, Selenium_Test_Group__c FROM Selenium_Test_Run__c];
        System.debug('testRuns: ' + seleniumTestRunList);
        System.assertEquals(seleniumTestGroup.Id, seleniumTestRunList[0].Selenium_Test_Group__c);
    }

    private static testMethod void testMassAddRunsToGroupWithoutData() {
        CMTestMethodUtilities.enableSelenium();
        Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert seleniumSetting;
        Selenium_Test_Group__c seleniumTestGroup = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = seleniumSetting.id, Manage_Test_Runs_manually__c = true);
        insert seleniumTestGroup;
        Org__c org1 = testMethodUtilities.createOrg('Test org1', 'sandbox', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(Name = 'test suite1');
        insert ts1;

        Selenium_Test_Run__c tr = new Selenium_Test_Run__c(Name = 'test1',
                Selenium_Test_Suite__c = ts1.Id,
                Selenium_Settings__c = seleniumSetting.Id);

        List<Selenium_Test_Run__c> seleniumTestRunList = new List<Selenium_Test_Run__c>();
        seleniumTestRunList.add(tr);

        insert seleniumTestRunList;

        ApexPages.StandardSetController std = new ApexPages.StandardSetController(seleniumTestRunList);
        MassAddRunsToGroup custom = new MassAddRunsToGroup(std);

        custom.addTestRunsToGroup();

        System.assertEquals(true, ApexPages.hasMessages());
    }
}