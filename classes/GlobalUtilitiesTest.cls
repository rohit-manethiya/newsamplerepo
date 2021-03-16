@IsTest
private with sharing class GlobalUtilitiesTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void testDeploymentFlowDetails() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert new List<Deployment_Flow__c>{ flow, flowCBM };
        System.assert(flowCBM.Id != null);

        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
        insert new List<Environment__c>{ env1, env2 };

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
        insert new List<Org__c>{ testOrg1, testOrg2 };

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        dfs2.Branch__c = 'env1';
        insert new List<Deployment_Flow_Step__c>{ dfs, dfs2 };
        System.assert(dfs2.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        User_Story__c userStory = CMTestMethodUtilities.createUserStory('test');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        insert userStory;
        System.assert(userStory.Id != null);

        Test.startTest();

        // Invalid CBM Flow - Main Branch = null
        flowCBM.Main_Branch__c = null;
        update flowCBM;
        GlobalUtilities.deploymentFlowDetails deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Invalid CBM Flow - Git Repository = null
        flowCBM.Main_Branch__c = 'master';
        flowCBM.Git_Repository__c = null;
        update flowCBM;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Inactive CBM Flow
        flowCBM.Active__c = false;
        flowCBM.Git_Repository__c = gitRepo.Id;
        update flowCBM;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(false, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(true, deploymentFlowDetails.isCBMFlow);

        // Inactive CCM Flow
        testProject.Deployment_Flow__c = flow.Id;
        update testProject;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Active CCM Flow
        flow.Active__c = false;
        update flow;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        List<GlobalUtilities.flowStepWrapper> flowSteps = GlobalUtilities.getDeploymentFlowSteps(userStory);
        Integer commitsCount = GlobalUtilities.getCommitCount(userStory.Id);
        System.assertEquals(false, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        Test.stopTest();
    }

    @IsTest
    private static void testUserStoriesAheadCalculation() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c>{ envDev1, envInt, envProd };

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', 'SFDC_OrgId4', null, null, System.now(), envProd.Id);
        insert new List<Org__c>{ orgDev1, orgInt, orgProd };

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgProd.Id, Branch__c = 'master');
        insert new List<Git_Backup__c>{ gitSnapshotDev1, gitSnapshotInt, gitSnapshotProd };

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        insert new List<Deployment_Flow_Step__c>{ stepDev1ToInt, stepIntToProd };

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotDev1.Id,
            Org__c = orgDev1.Id,
            Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974',
            Commit_Date__c = Date.today().addDays(-5),
            Commit_Message__c = 'test 1',
            Status__c = 'Complete'
        );
        Git_Org_Commit__c snapshotCommit2 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotInt.Id,
            Org__c = orgInt.Id,
            Commit_Id__c = 'b5adccf3937495e8928d1023c5a5c644198b10293',
            Commit_Date__c = Date.today().addDays(-3),
            Commit_Message__c = 'test 2',
            Status__c = 'Complete'
        );
        Git_Org_Commit__c snapshotCommit3 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotDev1.Id,
            Org__c = orgDev1.Id,
            Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876',
            Commit_Date__c = Date.today().addDays(-1),
            Commit_Message__c = 'test 3',
            Status__c = 'Complete'
        );
        insert new List<Git_Org_Commit__c>{ snapshotCommit1, snapshotCommit2, snapshotCommit3 };
        Test.setCreatedDate(snapshotCommit1.Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(snapshotCommit2.Id, Datetime.now().addDays(-3));
        Test.setCreatedDate(snapshotCommit3.Id, Datetime.now().addDays(-1));

        System.debug('### START Case 1.');
        // Case 1. Dev1 has 2 user stories with no commits. Both are not ahead.
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Project__c = testProject.Id;

        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('userStory2 Dev1');
        userStory2.Org_Credential__c = orgDev1.Id;
        userStory2.Project__c = testProject.Id;

        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('userStory3 Dev1');
        userStory3.Org_Credential__c = orgDev1.Id;
        userStory3.Project__c = testProject.Id;
        insert new List<User_Story__c>{ userStory1, userStory2, userStory3 };

        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 2.');
        // Case 2. UserStory1 has 1 'Complete' commit therefore it appears as 'Ahead' in stepDev1ToInt
        User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommit1.Id);
        insert userStoryCommit1;
        Test.setCreatedDate(userStoryCommit1.Id, Datetime.now().addDays(-5));
        userStory1.Promote_Change__c = true;
        update userStory1;
        System.assertEquals(1, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 3.');
        // Case 3. UserStory1 is Promoted to Int. UserStory1 then appears as 'Ahead' in stepIntToProd
        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotion1.Status__c = 'Completed';
        insert testPromotion1;
        Test.setCreatedDate(testPromotion1.Id, Datetime.now().addDays(-4));
        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
        insert promotedUserStory1;
        Test.setCreatedDate(promotedUserStory1.Id, Datetime.now().addDays(-4));
        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Environment__c = envInt.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesAhead(stepIntToProd).size());
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 4.');
        // Case 4. UserStory1 gets a commit in Int. UserStory1 still appears as 'Ahead' in stepIntToProd
        User_Story_Commit__c userStoryCommit2 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommit2.Id);
        insert userStoryCommit2;
        Test.setCreatedDate(userStoryCommit2.Id, Datetime.now().addDays(-1));

        Test.startTest();
        List<User_Story__c> listUserStoriesAhead = GlobalUtilities.getUserStoriesAhead(stepIntToProd);
        System.assertEquals(1, listUserStoriesAhead.size());
        // ensure VF required fields are not null
        for (User_Story__c userStoryAhead : listUserStoriesAhead) {
            System.assertEquals(userStoryAhead.Org_Credential__r.Org_Type__c, 'Sandbox');
        }

        System.debug('### START Case 5-6 Temporary.');
        // Case 5. UserStory1 was returned to Dev1. UserStory1 is still ahead in stepDev1ToInt
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Environment__c = envDev1.Id;

        System.debug('### START Case 7.');
        // Case 7. UserStory2 has a Deployment Task only and UserStory3 has an External CI Job only. UserStory2 and UserStory3 are now ahead
        Deployment_Task__c deploymentTask = new Deployment_Task__c(
            Name = 'Manual Task',
            Order__c = 1,
            Type__c = 'Manual Task',
            Status__c = 'Draft',
            User_Story__c = userStory2.Id
        );
        insert deploymentTask;

        External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
        insert externalCISetting;
        External_CI_Job__c externalCIJob = new External_CI_Job__c(
            Name = 'Job1',
            User_Story__c = userStory3.Id,
            External_CI_Setting__c = externalCISetting.Id
        );
        insert externalCIJob;

        userStory2.Promote_Change__c = true;
        userStory3.Promote_Change__c = true;
        update new List<User_Story__c>{ userStory1, userStory2, userStory3 };
        System.assertEquals(3, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        UserStoryCounter.InvocableVariables variable = new UserStoryCounter.InvocableVariables();
        variable.type = 'ahead';
        variable.pipelineId = flowCBM.Id;
        variable.environmentId = envDev1.Id;
        List<UserStoryCounter.InvocableVariables> variables = new List<UserStoryCounter.InvocableVariables>{ variable };
        System.assertEquals(3, UserStoryCounter.getUserStoryCount(variables)[0], 'There should be 3 user stories ahead');

        List<GlobalUtilities.flowStepWrapper> flowSteps = GlobalUtilities.getDeploymentFlowSteps(userStory1);

        GlobalUtilities.updateUserStoryBaseBranch(userStory3.Id, 'test');

        System.assertEquals(3, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());
        Test.stopTest();
    }

    @IsTest
    private static void testUserStoriesBehindCalculation() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envDev2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c>{ envDev1, envDev2, envInt, envProd };

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', 'SFDC_OrgId4', null, null, System.now(), envProd.Id);
        insert new List<Org__c>{ orgDev1, orgDev2, orgInt, orgProd };

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev2.Id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgProd.Id, Branch__c = 'master');
        insert new List<Git_Backup__c>{ gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt, gitSnapshotProd };

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        stepDev1Toint.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        stepDev2ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        stepIntToProd.Destination_Branch__c = 'master';
        insert new List<Deployment_Flow_Step__c>{ stepDev1ToInt, stepDev2ToInt, stepIntToProd };

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Git_Org_Commit__c snapshotCommitDev1 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotDev1.Id,
            Org__c = orgDev1.Id,
            Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974',
            Commit_Date__c = Date.today().addDays(-5),
            Commit_Message__c = 'test 1',
            Status__c = 'Complete'
        );
        Git_Org_Commit__c snapshotCommitInt1 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotInt.Id,
            Org__c = orgInt.Id,
            Commit_Id__c = 'b8adccf3937495e8928d1023c5a5c644198b1234',
            Commit_Date__c = Date.today().addDays(-3),
            Commit_Message__c = 'test 2',
            Status__c = 'Complete'
        );
        Git_Org_Commit__c snapshotCommitInt2 = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotInt.Id,
            Org__c = orgInt.Id,
            Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876',
            Commit_Date__c = Date.today().addDays(-1),
            Commit_Message__c = 'test 3',
            Status__c = 'Complete'
        );
        Git_Org_Commit__c snapshotCommitDev1b = new Git_Org_Commit__c(
            Git_Backup__c = gitSnapshotDev1.Id,
            Org__c = orgDev1.Id,
            Commit_Id__c = 'b6adccf3937495e8928d1023c5a5c644198b0694',
            Commit_Date__c = Date.today(),
            Commit_Message__c = 'test 4',
            Status__c = 'Complete'
        );
        insert new List<Git_Org_Commit__c>{ snapshotCommitDev1, snapshotCommitInt1, snapshotCommitInt2, snapshotCommitDev1b };
        Test.setCreatedDate(snapshotCommitDev1.Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(snapshotCommitInt1.Id, Datetime.now().addDays(-3));

        System.debug('### START Case 1');
        // Case 1. No user stories behind in Dev1
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;

        User_Story_Commit__c userStoryCommitDev1 = new User_Story_Commit__c(
            User_Story__c = userStory1.Id,
            Snapshot_Commit__c = snapshotCommitDev1.Id
        );
        insert userStoryCommitDev1;
        Test.setCreatedDate(userStoryCommitDev1.Id, Datetime.now().addDays(-5));

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());

        System.debug('### START Case 2');
        // Case 2. UserStory1 is Promoted to Int. UserStory1 appears as 'Behind' in stepDev2ToInt
        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotion1.Status__c = 'Completed';
        insert testPromotion1;
        Test.setCreatedDate(testPromotion1.Id, Datetime.now().addDays(-4));

        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
        insert promotedUserstory1;
        Test.setCreatedDate(promotedUserStory1.Id, Datetime.now().addDays(-4));

        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Environment__c = envInt.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        UserStoryCounter.InvocableVariables variable = new UserStoryCounter.InvocableVariables();
        variable.type = 'behind';
        variable.pipelineId = flowCBM.Id;
        variable.environmentId = envDev2.Id;
        List<UserStoryCounter.InvocableVariables> variables = new List<UserStoryCounter.InvocableVariables>{ variable };
        System.assertEquals(1, UserStoryCounter.getUserStoryCount(variables)[0], 'There should be 1 user story behind');

        promotedUserStory1.Status__c = 'Outdated';
        update promotedUserStory1;
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());
        promotedUserStory1.Status__c = 'Active';
        update promotedUserStory1;
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('*** START Case 3');
        // UserStory1 does not appear as 'Behind' in stepDev1ToInt
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepIntToProd).size());
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 5');
        // UserStory1 is Promoted to Production. UserStory1 still appears as 'Behind' in stepDev2ToInt
        Promotion__c testPromotion2 = CMTestMethodUtilities.createPromotion(testProject.Id, envInt.Id);
        testPromotion2.Status__c = 'Completed';
        insert testPromotion2;
        Test.setCreatedDate(testPromotion2.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory1b = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion2.Id);
        insert promotedUserstory1b;
        Test.setCreatedDate(promotedUserStory1b.Id, Datetime.now().addDays(-2));
        Test.startTest();
        userStory1.Org_Credential__c = orgProd.Id;
        userStory1.Environment__c = envProd.Id;
        update userStory1;
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 6');
        // Back Promote UserStory1 to Dev2. StepDev2ToInt will not have 'Behind' userStories
        Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev2.Id);
        testBackPromotion1.Status__c = 'Completed';
        testBackPromotion1.Source_Environment__c = envInt.Id;
        testBackPromotion1.Source_Org_Credential__c = orgInt.Id;
        insert testBackPromotion1;
        Promoted_User_Story__c backPromotedUserStory1 = new Promoted_User_Story__c(
            User_Story__c = userStory1.Id,
            Promotion__c = testBackPromotion1.Id
        );
        insert backPromotedUserstory1;
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 7');
        // UserStory1 was returned to Dev1 and Recommitted. UserStory1 is 'Ahead' again in stepDev1ToInt
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Environment__c = envDev1.Id;
        update userStory1;

        User_Story_Commit__c userStoryCommitDev1b = new User_Story_Commit__c(
            User_Story__c = userStory1.Id,
            Snapshot_Commit__c = snapshotCommitDev1b.Id
        );
        insert userStoryCommitDev1b;

        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());
        Test.stopTest();
    }

    @IsTest
    private static void testUserStoriesBehindNoCommitsCalculation() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envDev2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c>{ envDev1, envDev2, envInt, envProd };

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', 'SFDC_OrgId4', null, null, System.now(), envProd.Id);
        insert new List<Org__c>{ orgDev1, orgDev2, orgInt, orgProd };

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev2.Id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgProd.Id, Branch__c = 'master');
        insert new List<Git_Backup__c>{ gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt, gitSnapshotProd };

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        stepDev1ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        stepDev2ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        stepIntToProd.Destination_Branch__c = 'master';
        insert new List<Deployment_Flow_Step__c>{ stepDev1ToInt, stepDev2ToInt, stepIntToProd };

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev2');
        userStory1.Org_Credential__c = orgDev2.Id;
        userStory1.Project__c = testProject.Id;

        // UserStory2 has a Deployment Task only and UserStory3 has an External CI Job only. UserStory2 and UserStory3 are promoted to Int. Then they are Behind in Dev2
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('userStory2 Dev1');
        userStory2.Org_Credential__c = orgDev1.Id;
        userStory2.Project__c = testProject.Id;

        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('userStory3 Dev1');
        userStory3.Org_Credential__c = orgDev1.Id;
        userStory3.Project__c = testProject.Id;
        insert new List<User_Story__c>{ userStory1, userStory2, userStory3 };

        Deployment_Task__c deploymentTask = new Deployment_Task__c(
            Name = 'Manual Task',
            Order__c = 1,
            Type__c = 'Manual Task',
            Status__c = 'Draft',
            User_Story__c = userStory2.Id
        );
        insert deploymentTask;

        External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
        insert externalCISetting;
        External_CI_Job__c externalCIJob = new External_CI_Job__c(
            Name = 'Job1',
            User_Story__c = userStory3.Id,
            External_CI_Setting__c = externalCISetting.Id
        );
        insert externalCIJob;

        Promotion__c testPromotionDev1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotionDev1.Status__c = 'Completed';
        insert testPromotionDev1;
        Test.setCreatedDate(testPromotionDev1.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotionDev1.Id);
        insert promotedUserStory2;
        Test.setCreatedDate(promotedUserStory2.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory3 = new Promoted_User_Story__c(User_Story__c = userStory3.Id, Promotion__c = testPromotionDev1.Id);
        insert promotedUserStory3;
        Test.setCreatedDate(promotedUserStory3.Id, Datetime.now().addDays(-2));

        List<User_Story__c> listUserStoriesBehind = GlobalUtilities.getUserStoriesBehind(stepDev2ToInt);
        System.assertEquals(2, listUserStoriesBehind.size()); // UserStory2 and UserStory3 are 'Behind' to Dev2
        // ensure VF required fields are not null
        for (User_Story__c userStoryBehind : listUserStoriesBehind) {
            System.assertEquals(userStoryBehind.Org_Credential__r.Org_Type__c, 'Sandbox');
        }

        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(userStory1));
    }

    @IsTest
    private static void testUserStoryDependency() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
        insert new List<Environment__c>{ env1, env2 };
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
        testOrg1.Default_Credential__c = true;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Sandbox', 'SFDC_OrgId_2', null, null, System.now(), env2.Id);
        testOrg2.Default_Credential__c = true;
        insert new List<Org__c>{ testOrg1, testOrg2 };
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('test');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('testnotDependency');
        userStory2.Environment__c = env1.Id;
        userStory2.Org_Credential__c = testOrg1.Id;
        userStory2.Project__c = testProject.Id;
        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('testDependency');
        userStory3.Environment__c = env2.Id;
        userStory3.Org_Credential__c = testOrg2.Id;
        userStory3.Project__c = testProject.Id;
        insert new List<User_Story__c>{ userStory, userStory2, userStory3 };
        Team_Dependency__c td = new Team_Dependency__c();
        td.Provider_User_Story__c = userStory2.Id;
        td.Dependent_User_Story__c = userStory.Id;
        Team_Dependency__c td2 = new Team_Dependency__c();
        td2.Provider_User_Story__c = userStory3.Id;
        td2.Dependent_User_Story__c = userStory.Id;
        insert new List<Team_Dependency__c>{ td, td2 };

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert new List<Deployment_Flow_Step__c>{ stepDev1ToInt };

        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, env2.Id);
        testPromotion1.Status__c = 'Completed';
        testPromotion1.Source_Environment__c = env2.Id;
        testPromotion1.Destination_Environment__c = env1.Id;
        testPromotion1.Back_Promotion__c = true;
        insert testPromotion1;
        Promoted_User_Story__c pusBack = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotion1.Id);
        insert pusBack;

        List<User_Story__c> usDep = GlobalUtilities.getUserStoriesDependencies(new Set<Id>{ userStory.Id }, env1.Id);
        //there are two dependencies to US1 but US3 has been taken back in a time to US1
        System.assertEquals(usDep.size(), 1);

        // ensure VF required fields are not null
        User_Story__c userStory4 = GlobalUtilities.getUserStoryById(userStory3.Id);
        System.assertEquals(userStory4.Org_Credential__r.Org_Type__c, 'Sandbox');
    }

    @IsTest
    private static void testFlowSteps() {
        TestUtilities tu = new TestUtilities();

        String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] > 0
            ? 'copado__'
            : 'none';
        Blob key = Crypto.generateAesKey(256);

        // Create user record
        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator']
                .Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
            }
        );

        //TestUtilities.assignLicense(String.valueOf(tu.item('User',0).get('Username')), true, true, true, true, true);

        // Create copado license record
        tu.insertSObject(
            'Copado_License__c',
            new Map<String, Object>{
                'Enable_Copado__c' => true,
                'Enable_CCM__c' => true,
                'Enable_CST__c' => true,
                'Enable_CAD__c' => true,
                'Enable_CCH__c' => true,
                'SetupOwnerId' => tu.item('User', 0).Id
            }
        );

        // Create settings record
        tu.insertSObject(
            'Settings__c',
            new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Enabled_Multi_Licenses__c' => true,
                'CAD_Licenses__c' => 10,
                'CCH_Licenses__c' => 10,
                'CCM_Licenses__c' => 10,
                'Copado_Licenses__c' => 10,
                'CST_Licenses__c' => 10,
                'CryptoKEY__c' => EncodingUtil.base64Encode(key),
                'Namespace__c' => namespace
            }
        );

        System.runAs((User) tu.item('User', 0)) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create git repo record
            tu.insertSObject(
                'Git_Repository__c',
                new Map<String, Object>{
                    'Name' => 'Git Repo',
                    'URI__c' => 'www.test.com',
                    'Pull_Request_Base_URL__c' => 'www.test.com/[TARGET_BRANCH_NAME]/[SOURCE_BRANCH_NAME]',
                    'Git_Provider__c' => 'Others'
                }
            );

            // Create git snapshot record
            tu.insertSObject(
                'Git_Backup__c',
                new Map<String, Object>{
                    'Name' => 'Git Snapshot',
                    'Branch__c' => 'master',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Last_Backup__c' => Date.today(),
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Main_Branch__c' => 'master',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Active__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'dev1'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'dev2'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'uat'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'production'
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{ 'Name' => 'My project', 'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            List<GlobalUtilities.flowStepWrapper> flowStepsfirst = GlobalUtilities.getDeploymentFlowSteps(
                [
                    SELECT
                        Id,
                        Base_Branch__c,
                        Org_Credential__c,
                        Org_Credential__r.Org_Type__c,
                        User_Story_Title__c,
                        Environment__c,
                        Project__c,
                        Release__c,
                        Release__r.Base_Branch__c,
                        Project__r.Deployment_Flow__c,
                        Release__r.Project__r.Deployment_Flow__c
                    FROM User_Story__c
                    WHERE Id = :tu.item('User_Story__c', 0).Id
                ]
            );

            // Create snapshot commit record
            tu.insertSObjects(
                'Git_Org_Commit__c',
                1,
                new Map<String, Object>{
                    'Git_Backup__c' => tu.item('Git_Backup__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id,
                    'Commit_Id__c' => '10472f5b2df76332516be948ccb0df426d7e766f',
                    'Status__c' => 'Complete',
                    'Git_Operation__c' => 'Commit Files',
                    'Commit_Message__c' => 'US-0005041: Test run will be tested on this user story'
                }
            );

            // Create user story commit record
            tu.insertSObjects(
                'User_Story_Commit__c',
                1,
                new Map<String, Object>{
                    'Name' => 'US-0005041 10472f5',
                    'External_Id__c' => 'a170Y0000033VvrQAE_10472f5b2df76332516be948ccb0df426d7e766f',
                    'Snapshot_Commit__c' => tu.item('Git_Org_Commit__c', 0).Id,
                    'User_Story__c' => tu.item('User_Story__c', 0).Id
                }
            );

            GlobalUtilities.getPromotedUserStoriesUSBehind((Deployment_Flow_Step__c) tu.item('Deployment_Flow_Step__c', 0));
            Test.stopTest();
        }
    }
}