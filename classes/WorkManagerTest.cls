/*
 *   WorkManager Unit Tests
 *   Created by: ucan@copado.com
 *   Description: Unit Test for WorkManager Controller
 */
@isTest
private class WorkManagerTest {
    @testSetup
    static void setupTestData() {
        TestUtilities.getAllMultilicense();
    }
    static void setupTestDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
        profile p = [SELECT id FROM Profile WHERE name = 'System Administrator'];
        User user1 = new User(
            firstname = 'Wm',
            lastname = 'User',
            alias = 'xyz1',
            email = 'copado-test-2@test.org',
            emailencodingkey = 'UTF-8',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = 'copado-test-WM@test.org'
        );
        insert user1;

        PermissionSet ps = [SELECT ID FROM PermissionSet WHERE Name = 'Copado_User'];
        System.runAs(user1) {
            insert new PermissionSetAssignment(AssigneeId = user1.Id, PermissionSetId = ps.Id);
        }
    }

    /*
        This Method will test the constructor for the 4 default panels, meaning there is no Configuration saved
        The user is part of the teams
     */
    @isTest
    static void loadWorkManagerDefault() {
        setupTestDataDML();
        User u1 = [SELECT id, Username, work_manager_panels__c FROM user WHERE username = 'copado-test-WM@test.org'];

        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.assignLicense(u1.username, true, true, true, true, true);
        String ns = WorkManager.ns;
        //Create Team and team members for user assigned to the sprint
        Team__c tTest = new Team__c();
        tTest.Active__c = true;
        insert tTest;

        Team_Member__c tm = new Team_Member__c();
        tm.Team__c = tTest.Id;
        tm.Member__c = u1.Id;
        insert tm;

        //Sprint To Use
        List<Sprint__c> sToInsert = new List<Sprint__c>();
        Sprint__c s = new Sprint__c();
        s.Start_Date__c = date.today().addDays(-8);
        s.End_Date__c = date.today().addDays(8);
        s.Team__c = tTest.Id;
        sToInsert.add(s);

        Sprint__c nextS = new Sprint__c();
        nextS.Start_Date__c = date.today().addDays(20);
        nextS.End_Date__c = date.today().addDays(28);
        nextS.Team__c = tTest.Id;
        sToInsert.add(nextS);

        insert sToInsert;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;

        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert env1;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        testOrg1.Default_Credential__c = true;
        insert testOrg1;

        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Epic__c e = new Epic__c();
        insert e;

        List<User_Story__c> usList = new List<User_Story__c>();
        //First User Story, in Backlog, no Sprint
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('Backlog US');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        userStory.Sprint__c = null;
        userStory.Status__c = 'Backlog';
        userStory.Epic__c = e.Id;
        usList.add(userStory);

        //User Story In Sprint
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('Draft US');
        userStory2.Environment__c = env1.Id;
        userStory2.Org_Credential__c = testOrg1.Id;
        userStory2.Project__c = testProject.Id;
        userStory2.Sprint__c = s.Id;
        userStory2.Status__c = 'Draft';
        usList.add(userStory2);

        //Add two extra us for backlog and backburner to Apply Ranks
        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('Stay at Backlog US');
        userStory3.Environment__c = env1.Id;
        userStory3.Org_Credential__c = testOrg1.Id;
        userStory3.Project__c = testProject.Id;
        userStory3.Sprint__c = null;
        userStory3.Status__c = 'Backlog';
        usList.add(userStory3);

        User_Story__c userStory4 = CMTestMethodUtilities.createUserStory('Stay at Backburner US');
        userStory4.Environment__c = env1.Id;
        userStory4.Org_Credential__c = testOrg1.Id;
        userStory4.Project__c = testProject.Id;
        userStory4.Sprint__c = null;
        userStory4.Status__c = 'Backburner';
        usList.add(userStory4);

        insert usList;
        List<String> colArray = new List<String>{ ns + 'User_Story_Title__c', ns + 'Story_Points_SFDC__c' };
        List<String> currentTableOrderArray = new List<String>{ 'Status: Backlog', 'Status: Backburner', 'Developer: Wm User', 'Developer: Wm User' };
        List<SelectOption> usRelations, availablePanelStates;
        User_Story__c usItem;
        String currentFieldApiSelections;

        Test.startTest();

        System.runAs(u1) {
            Test.setCurrentPageReference(ApexPages.currentPage());
            WorkManager wM = new WorkManager();
            Id tempId = wM.cSprintId;
            tempId = wM.nSprintId;
            String tempStr = wM.workManagerPanel;
            List<WorkManager.TableWrapper> twList = new List<WorkManager.TableWrapper>();
            List<WorkManager.PWrapper> pwList = new List<WorkManager.PWrapper>();

            twList.add(
                WorkManager.prepareUsList(
                    'Status: Backlog',
                    'Status__c != \'Backburner\'  AND Status__c != \'Cancelled\' AND Status__c != \'Rejected\' AND Sprint__c = null',
                    '',
                    '',
                    '',
                    '',
                    ''
                )
            );
            pwList.add(new WorkManager.PWrapper('Backlog', 'Status', colArray, '', '', ''));

            twList.add(WorkManager.prepareUsList('Status: Backburner', 'Status__c = \'Backburner\' AND Sprint__c = null', '', '', '', '350', ''));
            pwList.add(new WorkManager.PWrapper('Backburner', 'Status', colArray, '', '', ''));

            twList.add(WorkManager.prepareUsList('Developer: ' + u1.id + ':changeOnBackend', 'Developer__c =\'' + u1.id + '\'', '', '', '', '', ''));
            pwList.add(new WorkManager.PWrapper('Wm User', 'Developer', colArray, '', '', ''));

            twList.add(
                WorkManager.prepareUsList(
                    'Developer: ' +
                    String.valueOf(u1.id).subString(0, 15) +
                    ':changeOnBackend',
                    'Developer__c =\'' +
                    u1.id +
                    '\'',
                    '',
                    '',
                    '',
                    '200',
                    ''
                )
            );
            pwList.add(new WorkManager.PWrapper('Wm User', 'Developer', colArray, '', '', ''));
            WorkManager.saveCurrentTables(JSON.serialize(pwList), JSON.serialize(twList), 'Default', currentTableOrderArray);
            System.debug(
                'current users wmp field ==> ' +
                [SELECT id, Username, work_manager_panels__c FROM user WHERE id = :userInfo.getUserId()]
                .work_manager_panels__c
            );
            List<WorkManager.UserStates> initialStates = WorkManager.initialStates;
            System.assertEquals(1, initialStates.size());
            System.assertEquals('Default', initialStates[0].lastState);
            List<WorkManager.PanelData> initPanelData = initialStates[0].panelData;
            System.debug('initPanelData==> ' + initPanelData);
            System.assertEquals(1, initPanelData.size());
            System.assertEquals(4, initPanelData[0].pWrappers.size());
            WorkManager.addConfig('Test', 'Default', '', 'create', '');
            WorkManager.addConfig('Test', 'Default', '', 'update', '2000');
            WorkManager.changeConfig('Default');
            WorkManager.removeConfig('Test');
            WorkManager.saveNewClause(userStory4.id, ns + 'Status__c', 'Backlog');
            WorkManager.saveStatusOrders(new List<String>{ userStory.id, userStory2.id, userStory3.id, userStory4.id }, 'Backlog');
            usRelations = wM.usRelations;
            availablePanelStates = wM.availablePanelStates;
            wM.reInitList();
            usItem = wM.inputUs;
            currentFieldApiSelections = wM.currentFieldApiSelection;
            wM.clearInputUs();

            PageReference myVfPage = Page.WorkManager;
            Test.setCurrentPageReference(myVfPage);
            System.currentPageReference().getParameters().put('cIndex', '1');
            System.currentPageReference().getParameters().put('rIndex', '0');
            System.currentPageReference().getParameters().put('aQuery', 'project__c = \'' + testProject.id + '\'');
            wM.addLine();
            wM.addLine();
            wM.addLine();
            wM.removeLine();
            wm.showInputUs();
            wM.EditCriterias();
        }
        Test.stopTest();
    }
}