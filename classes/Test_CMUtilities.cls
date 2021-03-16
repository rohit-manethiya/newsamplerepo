@IsTest
private class Test_CMUtilities {
    
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();

        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
            ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'Production 0' {
                        productionOrg = org;
                    }
                    when 'Staging 0' {
                        stagingOrg = org;
                    }
                    when 'Dev1 0' {
                        dev1Org = org;
                    }
                    when 'Dev2 0' {
                        dev2Org = org;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults pipelineDefaults = new CopadoUserStoryTestDefaults.PipelineDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.ProjectDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setDataSize(Project__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Project__c project = (Project__c) pipelineDefaults.getTestData(Project__c.SObjectType)[0];
            Deployment_Flow__c pipeline = (Deployment_Flow__c) pipelineDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults pipelineConnectionsDefaults = new CopadoUserStoryTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'staging')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'staging')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'staging')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'master')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            ITestDefaults userStoryDefaults = new CopadoUserStoryTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, project.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, dev1Org.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setDataSize(User_Story__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }


    @IsTest static void generalNegativeTestOfCMUtilities() {
        User standardUser = [SELECT Id, Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        List<PermissionSetAssignment> permissionSets = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :standardUser.Id AND PermissionSetId = :ps.Id];
        delete permissionSets;

        System.runAs(standardUser) {
            Test.startTest();
            CMUtilities.getTestScriptById('');
            List<Apexpages.Message> pageMessages = ApexPages.getMessages();
            Boolean expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForTestScript)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForTestScript');


            CMUtilities.getTestScripts(new Set<Id>());
            pageMessages = ApexPages.getMessages();
            expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForTestScript)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForTestScript');


            CMUtilities.getTestScriptStepsByTest('');
            pageMessages = ApexPages.getMessages();
            expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForTestScriptStep)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForTestScriptStep');

            CMUtilities.getTestRuns(new Set<Id>());
            pageMessages = ApexPages.getMessages();
            expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForTestRun)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForTestRun');

            CMUtilities.getTestRunStepsByTestRun('');
            pageMessages = ApexPages.getMessages();
            expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForTestRunStep)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForTestRunStep');

            CMUtilities.getFlowStepsByFlow('');
            pageMessages = ApexPages.getMessages();
            expectedMessage = false;
            for(Apexpages.Message messageItem : pageMessages){
                if (messageItem.getDetail().contains(Label.PermissionForDeploymentFlowStep)) {
                    expectedMessage = true;
                }
            }
            System.assert(expectedMessage, 'page message should return Label.PermissionForDeploymentFlowStep');
            Test.stopTest();
        }
    }

    @IsTest static void generalTestOfCMUtilities() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'My new User Story'];
            Environment__c testEnvironmentDev1 = [SELECT Id FROM Environment__c WHERE Name = 'Dev1 0'];
            Deployment_Flow__c testPipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            List<Deployment_Flow_Step__c> deploymentFlowSteps = [SELECT Id FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testPipeline.Id];

            Test.startTest();

            ITestDefaults testScriptDefaults = new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.User_Story__c, testUserStory.Id)
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.Peer_Reviewer__c, standardUser.Id)
                .setDataSize(Test_Script__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Script__c testScript = (Test_Script__c) testScriptDefaults.getTestData(Test_Script__c.SObjectType)[0];

            ITestDefaults testScriptStepDefaults = new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.TestScriptStepDefaults.class)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Order__c, 1)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Action_Description__c, 'action 1')
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Expected_Result__c, 'result 1')
                .setDataSize(Test_Script_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.TestScriptStepDefaults.class)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Order__c, 2)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Action_Description__c, 'action 2')
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Expected_Result__c, 'result 2')
                .setDataSize(Test_Script_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.TestScriptStepDefaults.class)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Order__c, 3)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Action_Description__c, 'action 3')
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Expected_Result__c, 'result 3')
                .setDataSize(Test_Script_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.TestScriptStepDefaults.class)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Order__c, 4)
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Action_Description__c, 'action 4')
                .setFieldValue(Test_Script_Step__c.SObjectType, Test_Script_Step__c.Expected_Result__c, 'result 4')
                .setDataSize(Test_Script_Step__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            List<Test_Script_Step__c> testScriptSteps = (List<Test_Script_Step__c>) testScriptStepDefaults.getTestData(Test_Script_Step__c.SObjectType);

            // Test Run creation
            ITestDefaults testRunDefaults = new CopadoUserStoryTestDefaults.TestRunDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Environment__c, testEnvironmentDev1.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Tester__c, standardUser.Id)
                .setDataSize(Test_Run__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Run__c testRun = (Test_Run__c) testRunDefaults.getTestData(Test_Run__c.SObjectType)[0];

            Test_Script__c returnedTestScript = CMUtilities.getTestScriptById(testScript.Id);
            System.assertEquals(testScript.Test_Title__c, returnedTestScript.Test_Title__c, 'Equal test script title');
            System.assertEquals(testScript.User_Story__c, returnedTestScript.User_Story__c, 'Equal test script user story');

            Set<Id> testScriptIds = new Set<Id>();
            testScriptIds.add(testScript.Id);
            List<Test_Script__c> actualTestScripts = new List<Test_Script__c>{ testScript };
            List<Test_Script__c> returnedTestScripts = CMUtilities.getTestScripts(testScriptIds);
            System.assertEquals(actualTestScripts.size(), returnedTestScripts.size(), 'Equal test script list');

            List<Test_Script_Step__c> returnedTestScriptSteps = CMUtilities.getTestScriptStepsByTest(testScript.Id);
            System.assertEquals(testScriptSteps.size(), returnedTestScriptSteps.size(), 'Test script counts are equal');

            Set<Id> testRunsIds = new Set<Id>();
            testRunsIds.add(testRun.Id);
            List<Test_Run__c> actualTestRuns = new List<Test_Run__c>{ testRun };
            List<Test_Run__c> returnedTestRuns = CMUtilities.getTestRuns(testRunsIds);
            System.assertEquals(actualTestRuns.size(), returnedTestRuns.size(), 'Equal test run size');

            List<Test_Run_Step__c> returnedTestRunSteps = CMUtilities.getTestRunStepsByTestRun(testRun.Id);
            System.assertEquals(testScriptSteps.size(), returnedTestRunSteps.size(), 'Test run steps size should be equal to test script steps size');

            List<Deployment_Flow_Step__c> returnedDeploymentFlowSteps = CMUtilities.getFlowStepsByFlow(testPipeline.Id);
            System.assertEquals(deploymentFlowSteps.size(), returnedDeploymentFlowSteps.size(), 'Equal deployment flow step list size');
            Test.stopTest();
        }
    }
}