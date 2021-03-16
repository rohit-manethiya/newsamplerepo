@isTest
private class TestManageSeleniumTestingExt {

    static final String LICENSE_USERNAME = 'futureuser777@test-copado.org';
    @testSetup static void setupData() {
        TestUtilities.enableLicenses(10, 10, 10);


    }
    private static void setupDataDML() {
        insertUser();
        assignCCMLicense();

        // NR: all this is necessary to enable CCM/CST/CBM
        //upsert new Settings__c(Namespace__c = 'none', Enabled_Multi_Licenses__c = true );
        Copado_License__c lics = Copado_License__c.getInstance();
        lics.Enable_CST__c = true;
        lics.Enable_CCM__c = true;
        lics.Enable_Copado__c = true;
        upsert lics;
        // "simulate" an API Key, since testmethods do not support webservice callouts inside DeployAPI.createAPIKey();
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }
        system.assert(LicenseHelper.isCopadoEnabled());
        system.assert(LicenseHelper.isCCMEnabled());
        system.assert(LicenseHelper.isCSTEnabled());
    }
    @Future
    public static void insertUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User futureUser = new User(firstname = 'Future', lastname = 'User',
                alias = 'future',
                email = 'test@test.org',
                emailencodingkey = 'UTF-8',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = p.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = LICENSE_USERNAME
        );
        insert(futureUser);
    }
    @Future(callout = true)
    public static void assignCCMLicense() {
        User u = [SELECT Id FROM User WHERE username = :LICENSE_USERNAME];
        String copadoLicenses = '0';
        String ccmLicenses = '1';
        String cstLicenses = '0';
        String multiLicenses = 'true';
        String b = '{"customerOrg":{"Name":"Copado Development Org","orgId":"00D24000000aZrZEAU","autoRecharge":false,"credits":99818,"userId":"005240000012JyBAAU","copadoLicenses":' + copadoLicenses + ',"ccmLicenses":' + ccmLicenses + ',"cstLicenses":' + cstLicenses + ',"multiLicenses":' + multiLicenses + ',"id":73011},"userInfo":{"accessibilityMode__is_set":true}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        LicenseManagerController con = new LicenseManagerController();
        con.dummyUser.ManagerId = u.Id;
        con.assignCopado = false;
        con.assignCCM = true;
        con.assignCST = true;
        con.addUser();
    }

    static testMethod void userStoryTest() {
        setupDataDML();
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        List<User_Story__c> userStories = new List<User_Story__c>();
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory3'));
        userStories.get(0).Project__c = testProject.Id;
        userStories.get(0).Environment__c = env1.Id;
        userStories.get(0).Promote_Change__c = true;

        userStories.get(1).Project__c = testProject.Id;
        userStories.get(1).Environment__c = env1.Id;
        userStories.get(1).Promote_Change__c = true;
        insert userStories;

        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = testMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('usId', userStories.get(0).Id);

        ManageSeleniumTestingExt mst = new ManageSeleniumTestingExt();
        mst.mockGroup.Selenium_Settings__c = s.Id;
        mst.populateSTG(env1.Name);
        mst.Save();
        mst.selectedSuites.add(mst.allSuites[0]);
        mst.selectedOrgs.add(mst.allOrgs[0]);
        mst.Save();
        List<User_Story_Selenium_Test__c> Lusst = [SELECT Id FROM User_Story_Selenium_Test__c WHERE User_Story__c = :userStories.get(0).Id];
        System.assertEquals(1, Lusst.size());

        // check that a user story test exists
        String groupExId = userStories.get(0).Id + '_' + env1.Id;
        System.Debug(groupExId);
        List<Selenium_Test_Group__c> Lstg = [SELECT Id, Selenium_Settings__c FROM Selenium_Test_Group__c WHERE External_Id__c = :groupExId];
        System.assertEquals(1, Lstg.size());

        List<Selenium_Group_Test_Suite__c> Lsgts = [SELECT Id FROM Selenium_Group_Test_Suite__c WHERE Selenium_Test_Group__c = :Lstg[0].Id];
        System.assertEquals(1, Lsgts.size());

        List<Selenium_Group_Org_Credential__c> Lsgoc = [SELECT Id FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c = :Lstg[0].Id];
        System.assertEquals(1, Lsgoc.size());
        mst.populateSTG();
        mst.back();
        Test.stopTest();
    }

    static testMethod void regressionTest() {
        setupDataDML();
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        List<User_Story__c> userStories = new List<User_Story__c>();
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
        userStories.add(CMTestMethodUtilities.createUserStory('MyStory3'));
        userStories.get(0).Project__c = testProject.Id;
        userStories.get(0).Environment__c = env1.Id;
        userStories.get(0).Promote_Change__c = true;

        userStories.get(1).Project__c = testProject.Id;
        userStories.get(1).Environment__c = env1.Id;
        userStories.get(1).Promote_Change__c = true;
        insert userStories;

        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = testMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('regression', 'true');
        ApexPages.currentPage().getParameters().put('flowId', flow.Id);

        ManageSeleniumTestingExt mst = new ManageSeleniumTestingExt();
        mst.mockGroup.Selenium_Settings__c = s.Id;
        mst.populateSTG(env1.Name);
        mst.selectedSuites.add(mst.allSuites[0]);
        mst.selectedOrgs.add(mst.allOrgs[0]);
        mst.Save();

        // check that a regression test exists
        String groupExId = env1.Id;
        System.Debug(groupExId);
        List<Selenium_Test_Group__c> Lstg = [SELECT Id, Selenium_Settings__c FROM Selenium_Test_Group__c WHERE External_Id__c = :groupExId];
        System.assertEquals(1, Lstg.size());
        ApexPages.currentPage().getParameters().put('groupId', Lstg[0].Id);
        mst.editSeleniumGroup_and_subRecords();
        mst.Save();

        List<Selenium_Group_Test_Suite__c> Lsgts = [SELECT Id FROM Selenium_Group_Test_Suite__c WHERE Selenium_Test_Group__c = :Lstg[0].Id];
        System.assertEquals(1, Lsgts.size());

        List<Selenium_Group_Org_Credential__c> Lsgoc = [SELECT Id FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c = :Lstg[0].Id];
        System.assertEquals(1, Lsgoc.size());
        List<List<Selenium_Test_Group__c>> stgList = mst.stGroup4RelatedList;
        mst.deleteSeleniumGroup_and_subRecords();

        Test.stopTest();
    }

    static testMethod void preselectedTests() {
        setupDataDML();
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        insert s;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name = 'test suite1');
        insert ts1;
        Org__c org2 = testMethodUtilities.createOrg('Test org2', 'sandbox', 'org-id-2', 'tk-2', 'test2@test.com', System.now());
        insert org2;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name = 'test suite2');
        insert ts2;

        // check that a regression test exists
        String groupExId = env1.Id;
        Selenium_Test_Group__c stg = new Selenium_Test_Group__c();
        stg.External_Id__c = groupExId;
        stg.Environment__c = env1.Id;
        stg.Type__c = Label.REGRESSION_TEST;
        stg.Name = Label.REGRESSION_TEST + ' - ' + ts1.Name + ' - ' + env1.Name;
        stg.Selenium_Settings__c = s.Id;
        upsert stg stg.External_Id__c;

        Selenium_Group_Test_Suite__c sgts = new Selenium_Group_Test_Suite__c();
        sgts.Selenium_Test_Group__c = stg.Id;
        sgts.Selenium_Test_Suite__c = ts1.Id;
        sgts.External_Id__c = '' + ts1.Id + stg.Id;
        upsert sgts sgts.External_Id__c;

        Selenium_Group_Org_Credential__c sgoc = new Selenium_Group_Org_Credential__c();
        sgoc.Org_Credential__c = testOrg1.Id;
        sgoc.Selenium_Test_Group__c = stg.Id;
        sgoc.External_Id__c = '' + testOrg1.Id + stg.Id;
        upsert sgoc sgoc.External_Id__c;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('regression', 'true');
        ApexPages.currentPage().getParameters().put('flowId', flow.Id);

        ManageSeleniumTestingExt mst = new ManageSeleniumTestingExt();
        Test.stopTest();
    }
}