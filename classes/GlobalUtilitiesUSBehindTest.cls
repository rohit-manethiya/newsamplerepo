@IsTest
private with sharing class GlobalUtilitiesUSBehindTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
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

            Git_Org_Commit__c snapshotCommitInt1 = new Git_Org_Commit__c(
                Git_Backup__c = gitSnapshotInt.Id,
                Org__c = orgInt.Id,
                Commit_Id__c = 'b8adccf3937495e8928d1023c5a5c644198b1234',
                Commit_Date__c = Date.today().addDays(-5),
                Commit_Message__c = 'test 2',
                Status__c = 'Complete'
            );
            Git_Org_Commit__c snapshotCommitInt2 = new Git_Org_Commit__c(
                Git_Backup__c = gitSnapshotInt.Id,
                Org__c = orgInt.Id,
                Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876',
                Commit_Date__c = Date.today().addDays(-2),
                Commit_Message__c = 'test 2',
                Status__c = 'Complete'
            );
            Git_Org_Commit__c snapshotCommitProd = new Git_Org_Commit__c(
                Git_Backup__c = gitSnapshotProd.Id,
                Org__c = orgProd.Id,
                Commit_Id__c = 'b6adccf3937495e8928d1023c5a5c644198b23423',
                Commit_Date__c = Date.today(),
                Commit_Message__c = 'test 3',
                Status__c = 'Complete'
            );
            insert new List<Git_Org_Commit__c>{ snapshotCommitInt1, snapshotCommitInt2, snapshotCommitProd };

            Test.setCreatedDate(snapshotCommitInt1.Id, Datetime.now().addDays(-5));
            Test.setCreatedDate(snapshotCommitInt2.Id, Datetime.now().addDays(-2));
            Test.setCreatedDate(snapshotCommitProd.Id, Datetime.now().addDays(-1));
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void testUserStoriesBehindCalculationCaseOne() {
        Org__c org = [SELECT Id FROM Org__c WHERE Name = 'OrgInt'];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'test project'];
        Git_Org_Commit__c goc = [SELECT Id FROM Git_Org_Commit__c WHERE Commit_Id__c = 'b8adccf3937495e8928d1023c5a5c644198b1234'];
        Deployment_Flow_Step__c dfs = [
            SELECT Id, Destination_Environment__c, Deployment_Flow__c
            FROM Deployment_Flow_Step__c
            WHERE Branch__c = 'dev1'
        ];

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = org.Id;
        userStory1.Project__c = project.Id;
        insert userStory1;

        User_Story_Commit__c userStoryCommitInt1 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = goc.Id);
        insert userStoryCommitInt1;
        Test.setCreatedDate(userStoryCommitInt1.Id, Datetime.now().addDays(-5));

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(dfs).size()); // Since they are not promoted to anywhere they dont show up as behind anymore
    }

    @IsTest
    private static void testUserStoriesBehindCalculationCaseTwo() {
        Org__c org = [SELECT Id FROM Org__c WHERE Name = 'OrgProd'];
        Environment__c env = [SELECT Id FROM Environment__c WHERE Name = 'Integration Environment'];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'test project'];
        Deployment_Flow_Step__c dfs = [
            SELECT Id, Destination_Environment__c, Source_Environment__c, Deployment_Flow__c
            FROM Deployment_Flow_Step__c
            WHERE Branch__c = 'dev1'
        ];

        // UserStory1 is promoted to Prod. It still appears as 'Behind' in Dev1 and Dev2
        Promotion__c testPromotionInt1 = CMTestMethodUtilities.createPromotion(project.Id, env.Id);
        testPromotionInt1.Status__c = 'Completed';
        insert testPromotionInt1;
        Test.setCreatedDate(testPromotionInt1.Id, Datetime.now().addDays(-4));

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = org.Id;
        userStory1.Project__c = project.Id;
        insert userStory1;

        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotionInt1.Id);
        insert promotedUserStory1;
        Test.setCreatedDate(promotedUserStory1.Id, Datetime.now().addDays(-4));

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(dfs).size()); // UserStory2 is 'Behind' to Dev1
    }

    @IsTest
    private static void testUserStoriesBehindCalculationCaseThree() {
        String prodOrgId = '';
        String intOrgId = '';
        for (Org__c org : [SELECT Id, Name FROM Org__c WHERE Name = 'OrgProd' OR Name = 'OrgInt']) {
            if (org.Name == 'OrgProd') {
                prodOrgId = org.Id;
            } else if (org.Name == 'OrgInt') {
                intOrgId = org.Id;
            }
        }

        String devEnvId = '';
        String intEnvId = '';
        for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name = 'Dev1 Environment' OR Name = 'Integration Environment']) {
            if (env.Name == 'Dev1 Environment') {
                devEnvId = env.Id;
            } else if (env.Name == 'Integration Environment') {
                intEnvId = env.Id;
            }
        }

        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'test project'];
        Deployment_Flow_Step__c dfs = [
            SELECT Id, Destination_Environment__c, Source_Environment__c, Deployment_Flow__c
            FROM Deployment_Flow_Step__c
            WHERE Branch__c = 'dev1'
        ];

        // UserStory1 is back promoted to Dev1. UserStory is no longer 'Behind' in Dev1
        Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(project.Id, devEnvId);
        testBackPromotion1.Status__c = 'Completed';
        testBackPromotion1.Source_Environment__c = intEnvId;
        testBackPromotion1.Source_Org_Credential__c = intOrgId;
        insert testBackPromotion1;
        Test.setCreatedDate(testBackPromotion1.Id, Datetime.now().addDays(-3));

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = prodOrgId;
        userStory1.Project__c = project.Id;
        insert userStory1;

        Promoted_User_Story__c backPromotedUserStory1 = new Promoted_User_Story__c(
            User_Story__c = userStory1.Id,
            Promotion__c = testBackPromotion1.Id
        );
        insert backPromotedUserStory1;
        Test.setCreatedDate(backPromotedUserStory1.Id, Datetime.now().addDays(-3));

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(dfs).size());
    }

    @IsTest
    private static void testUserStoriesBehindCalculationCaseFour() {
        String prodOrgId = '';
        String intOrgId = '';
        for (Org__c org : [SELECT Id, Name FROM Org__c WHERE Name = 'OrgProd' OR Name = 'OrgInt']) {
            if (org.Name == 'OrgProd') {
                prodOrgId = org.Id;
            } else if (org.Name == 'OrgInt') {
                intOrgId = org.Id;
            }
        }

        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'test project'];
        Deployment_Flow_Step__c dfs = [
            SELECT Id, Destination_Environment__c, Source_Environment__c, Deployment_Flow__c
            FROM Deployment_Flow_Step__c
            WHERE Branch__c = 'int'
        ];
        Git_Org_Commit__c goc = [SELECT Id FROM Git_Org_Commit__c WHERE Commit_Id__c = 'b6adccf3937495e8928d1023c5a5c644198b23423'];

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = prodOrgId;
        userStory1.Project__c = project.Id;
        insert userStory1;

        // UserStory1 recieves a commit in Prod. It is now 'Behind' in Int.
        User_Story_Commit__c userStoryCommitProd = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = goc.Id);
        insert userStoryCommitProd;
        Test.setCreatedDate(userStoryCommitProd.Id, Datetime.now().addDays(-1));
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(dfs).size());
    }

    @IsTest
    private static void testUserStoriesBehindCalculationCaseFive() {
        String prodOrgId = '';
        String intOrgId = '';
        for (Org__c org : [SELECT Id, Name FROM Org__c WHERE Name = 'OrgProd' OR Name = 'OrgInt']) {
            if (org.Name == 'OrgProd') {
                prodOrgId = org.Id;
            } else if (org.Name == 'OrgInt') {
                intOrgId = org.Id;
            }
        }

        String prodEnvId = '';
        String intEnvId = '';
        for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name = 'Production Environment' OR Name = 'Integration Environment']) {
            if (env.Name == 'Production Environment') {
                prodEnvId = env.Id;
            } else if (env.Name == 'Integration Environment') {
                intEnvId = env.Id;
            }
        }

        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'test project'];
        Deployment_Flow_Step__c dfs = [
            SELECT Id, Destination_Environment__c, Source_Environment__c, Deployment_Flow__c
            FROM Deployment_Flow_Step__c
            WHERE Branch__c = 'int'
        ];

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = prodOrgId;
        userStory1.Project__c = project.Id;
        insert userStory1;

        // UserStory1 is back promoted to Int. It is now 'Behind' again in Dev1, even though it was back promoted before.
        Promotion__c testBackPromotion2 = CMTestMethodUtilities.createBackPromotion(project.Id, intEnvId);
        testBackPromotion2.Status__c = 'Completed';
        testBackPromotion2.Source_Environment__c = prodEnvId;
        testBackPromotion2.Source_Org_Credential__c = prodOrgId;
        insert testBackPromotion2;

        Promoted_User_Story__c backPromotedUserStory1b = new Promoted_User_Story__c(
            User_Story__c = userStory1.Id,
            Promotion__c = testBackPromotion2.Id
        );
        insert backPromotedUserStory1b;

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(dfs).size());
    }
}