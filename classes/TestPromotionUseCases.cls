@IsTest
private with sharing class TestPromotionUseCases {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String PRODUCTION = 'Production';
    private static final String STAGING = 'Staging';
    private static final String DEV_1 = 'Dev1';
    private static final String DEV_2 = 'Dev2';
    private static final String PRODUCTION_0 = 'Production 0';
    private static final String STAGING_0 = 'Staging 0';
    private static final String DEV1_0 = 'Dev1 0';
    private static final String DEV2_0 = 'Dev2 0';
    private static final String STAGING_BRANCH = 'staging';
    private static final String DEV_1_BRANCH = 'dev1';
    private static final String DEV_2_BRANCH = 'dev2';
    private static final String MERGE_STRING = 'merge';
    private static final String PROJECT_0 = 'MyProject 0';

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
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, PRODUCTION)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, STAGING)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, DEV_1)
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, DEV_2)
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
                .setFieldValue(Org__c.SObjectType, Org__c.Name, PRODUCTION)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, STAGING)
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_1)
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_2)
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c dev1Org = new Org__c();
            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'Dev1 0' {
                        dev1Org = org;
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
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV_1_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV_2_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'master')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            ITestDefaults userStoryDefaults = new CopadoPromotionTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, project.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, dev1Org.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        User_Story__c.SObjectType => new Set<Schema.SObjectField>{ User_Story__c.User_Story_Title__c }
                    }
                )
                .setDataSize(User_Story__c.SObjectType, 4)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void testPromoteandDeploy() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Environment__c, Promote_and_Deploy__c
                FROM User_Story__c
                WHERE User_Story_Title__c = 'My new User Story 0'
            ];

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            testUserStory.Promote_and_Deploy__c = true;
            update testUserStory;

            // Assertions
            Promotion__c assertPromotion = [
                SELECT
                    Id,
                    Name,
                    Back_Promotion__c,
                    Source_Org_Credential__c,
                    Source_Environment__c,
                    Destination_Org_Credential__r.Name,
                    Destination_Environment__r.Name
                FROM Promotion__c
                WHERE Source_Org_Credential__c = :testUserStory.Org_Credential__c AND Source_Environment__c = :testUserStory.Environment__c
            ];
            System.assertEquals(STAGING_0, assertPromotion.Destination_Org_Credential__r.Name, 'Destination Org Credential is not ' + STAGING_0);
            System.assertEquals(STAGING_0, assertPromotion.Destination_Environment__r.Name, 'Destination Environment is not ' + STAGING_0);

            Promoted_User_Story__c assertPromotedUSerStory = [
                SELECT Id, Name, Promotion__c, User_Story__c
                FROM Promoted_User_Story__c
                WHERE User_Story__c = :testUserStory.Id
            ];
            System.assertEquals(assertPromotion.Id, assertPromotedUSerStory.Promotion__c, 'Promoted user story is not a child of Promotion');
        }
    }

    @IsTest
    static void testCreatePromotionAddUserStories() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Environment__c sourceEnvironment = [SELECT Id FROM Environment__c WHERE Name = :DEV1_0 LIMIT 1];
            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];

            Test.startTest();
            Pagereference newPromotionPage = Page.PromotionEdit;
            Test.setCurrentPage(newPromotionPage);

            // Standard Controller and Extension controller are not loaded here, because is not needed and there is nothing to test inside.
            Promotion__c newPromotion = new Promotion__c();
            newPromotion.Source_Environment__c = sourceEnvironment.Id;
            newPromotion.Project__c = currentProject.Id;

            insert newPromotion;

            Promotion__c currentPromotion = [
                SELECT
                    Id,
                    Name,
                    Source_Environment__c,
                    Source_Environment__r.Name,
                    Destination_Environment__c,
                    Destination_Environment__r.Name,
                    Source_Org_Credential__c,
                    Source_Org_Credential__r.Name,
                    Destination_Org_Credential__c,
                    Destination_Org_Credential__r.Name
                FROM Promotion__c
                WHERE Id = :newPromotion.Id
            ];

            ApexPages.StandardController promotionSc = new ApexPages.StandardController(currentPromotion);
            PromoteChangesExtension viewPromotionController = new PromoteChangesExtension(promotionSc);
            // Assertions start
            System.assertEquals(DEV1_0, currentPromotion.Source_Environment__r.Name, 'Source Environment Name is not ' + DEV1_0);
            System.assertEquals(DEV1_0, currentPromotion.Source_Org_Credential__r.Name, 'Source Org Credential Name is not ' + DEV1_0);
            System.assertEquals(STAGING_0, currentPromotion.Destination_Environment__r.Name, 'Destination Environment Name is not ' + STAGING_0);
            System.assertEquals(
                STAGING_0,
                currentPromotion.Destination_Org_Credential__r.Name,
                'Destination Org Credential Name is not ' + STAGING_0
            );
            // Assertions end

            viewPromotionController.listUserStories();

            List<PromoteChangesExtension.userStoryWrapper> assertUserStories = viewPromotionController.userStories;
            for (PromoteChangesExtension.userStoryWrapper userStoriesWrapper : viewPromotionController.userStories) {
                userStoriesWrapper.selected = true;
            }

            viewPromotionController.addStoriesToPromotion();

            // Assertions
            System.assertEquals(4, assertUserStories.size(), 'Number of User Stories listed ready to promote is not 4');
            Set<Id> assertUserStoriesAdded = new Set<Id>();
            List<Promoted_User_Story__c> assertUSaddedToPromotion = [
                SELECT Id, User_Story__c
                FROM Promoted_User_Story__c
                WHERE User_Story__c = :viewPromotionController.promotedIdsSet
            ];
            System.assertEquals(
                viewPromotionController.promotedIdsSet.size(),
                assertUSaddedToPromotion.size(),
                'Number of User stories added is not equal to promoted user stories inserted'
            );
            for (Promoted_User_Story__c promotedUs : assertUSaddedToPromotion) {
                assertUserStoriesAdded.add(promotedUs.User_Story__c);
            }
            System.assert(
                viewPromotionController.promotedIdsSet.containsAll(assertUserStoriesAdded),
                'User Stories added are is not same as user stories in which promoted user stories were created.'
            );
            // Assertions end
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreatePromotionExcludeAutoresolve() {
        String excludeFromAutoresolve = 'ApexClass;ApexComponent;ApexPage';
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        Deployment_Flow__c currentPipeline = [
            SELECT Id, Name, Git_Repository__c, Active__c
            FROM Deployment_Flow__c
            WHERE Name = 'MyPipeline 0'
            LIMIT 1
        ];
        currentPipeline.Exclude_From_Auto_Resolve__c = excludeFromAutoresolve;
        update currentPipeline;
        System.runAs(standardUser) {
            Environment__c sourceEnvironment = [SELECT Id FROM Environment__c WHERE Name = :DEV1_0 LIMIT 1];
            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];

            Test.startTest();
            Pagereference newPromotionPage = Page.PromotionEdit;
            Test.setCurrentPage(newPromotionPage);

            // Standard and Extension controller are not loaded here, because is not needed and there is nothing to test inside.
            Promotion__c newPromotion = new Promotion__c();

            newPromotion.Source_Environment__c = sourceEnvironment.Id;
            newPromotion.Project__c = currentProject.Id;

            insert newPromotion;

            Promotion__c currentPromotion = [SELECT Id, Name, Exclude_From_Auto_Resolve__c FROM Promotion__c WHERE Id = :newPromotion.Id];

            // Assertions
            System.assertEquals(
                excludeFromAutoresolve,
                currentPromotion.Exclude_From_Auto_Resolve__c,
                'Types excluded from autoresolve are not the selected ones'
            );
            // Assertions end

            Test.stopTest();
        }
    }

    @IsTest
    static void testMinimumCoverage() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Org__c userStoryOrgCredential = [SELECT Id FROM Org__c WHERE Name = :DEV1_0 LIMIT 1];
            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];
            ITestDefaults userStoryDefaults = new CopadoPromotionTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, currentProject.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, userStoryOrgCredential.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Promote_Change__c, false)
                .setDataSize(User_Story__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
            String assertError;

            Test.startTest();

            User_Story__c currentUserStory = (User_Story__c) userStoryDefaults.getTestData(User_Story__c.SObjectType)[0];
            currentUserStory.Has_Apex_Code__c = true;
            currentUserStory.Promote_Change__c = true;
            try {
                update currentUserStory;
            } catch (Exception ex) {
                assertError = ex.getDmlMessage(0);
            }
            System.assertEquals(
                'This User Story does not meet the required Apex coverage threshold to be promoted.',
                assertError,
                'Message about minium test coverage is not the correct one'
            );
            Test.stopTest();
        }
    }

    @IsTest
    static void testPromotionValidation() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Map<String, String> environmentsByName = new Map<String, String>();
            for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0, :PRODUCTION_0)]) {
                environmentsByName.put(env.Name, env.Id);
            }

            Deployment_Flow__c currentPipeline = [
                SELECT Id, Name, Git_Repository__c, Active__c
                FROM Deployment_Flow__c
                WHERE Name = 'MyPipeline 0'
                LIMIT 1
            ];

            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // Assert stage 1
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage1 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 1').get(environmentsByName.get(STAGING_0))
            );
            System.assertEquals(2, assertionStage1.size(), 'The number of environments in stage 1 is not 2');

            System.assertEquals(DEV1_0, assertionStage1[0].currentEnvironment.Name, 'Environment 1 name in stage 1 is not ' + DEV1_0);
            System.assertEquals(
                DEV_1_BRANCH,
                assertionStage1[0].currentStep.Branch__c,
                'Environment 1 branch name in stage 1 is not ' + DEV_1_BRANCH
            );
            System.assertEquals(false, assertionStage1[0].isDestinationEnv, 'Environment 1 in stage 1 is not marked as Destination Environment');
            System.assertEquals(4, assertionStage1[0].userStoriesAhead, 'In Environment 2 there are not only 4 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage1[0].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            System.assertEquals(DEV2_0, assertionStage1[1].currentEnvironment.Name, 'Environment 2 name in stage 1 is not ' + DEV2_0);
            System.assertEquals(
                DEV_2_BRANCH,
                assertionStage1[1].currentStep.Branch__c,
                'Environment 2 branch name in stage 1 is not ' + DEV_2_BRANCH
            );
            System.assertEquals(false, assertionStage1[1].isDestinationEnv, 'Environment 2 in stage 1 is not marked as Destination Environment');
            System.assertEquals(0, assertionStage1[1].userStoriesAhead, 'In Environment 2 there are not only 4 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage1[1].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            // Assert stage 2
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage2 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 2').get(environmentsByName.get(PRODUCTION_0))
            );
            System.assertEquals(1, assertionStage2.size(), 'The number of environments in stage 2 is not 1');

            System.assertEquals(STAGING_0, assertionStage2[0].currentEnvironment.Name, 'Environment name in stage 2 is not ' + STAGING_0);
            System.assertEquals(
                STAGING_BRANCH,
                assertionStage2[0].currentStep.Branch__c,
                'Environment branch name in stage 2 is not ' + STAGING_BRANCH
            );
            System.assertEquals(true, assertionStage2[0].isDestinationEnv, 'Environment  in stage 2 is marked as Destination Environment');
            System.assertEquals(0, assertionStage2[0].userStoriesAhead, 'In staging environment there are more than 0 User Stories Ahead in stage 2');
            System.assertEquals(
                0,
                assertionStage2[0].userStoriesBehind,
                'In staging environment there are more than 0 User Stories Behind in stage 2'
            );

            // Assert stage Final
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStageFinal = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 3').get('Final')
            );
            System.assertEquals(1, assertionStageFinal.size(), 'The number of environments in final stage is not 1');

            System.assertEquals(
                PRODUCTION_0,
                assertionStageFinal[0].currentEnvironment.Name,
                'Environment name in final stage is not ' + PRODUCTION_0
            );
            System.assertEquals(
                'master',
                assertionStageFinal[0].currentStep.Destination_Branch__c,
                'Environment branch name in final stage is not "master" '
            );
            System.assertEquals(true, assertionStageFinal[0].isDestinationEnv, 'Environment  in final stage is marked as Destination Environment');
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesBehind,
                'In production environment there are more than 0 User Stories Ahead in final stage'
            );
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesAhead,
                'In production environment there are more than 0 User Stories Behind in final stage'
            );
            // Assertions end

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environmentsByName.get(DEV1_0));
            ApexPages.currentPage().getParameters().put('toId', environmentsByName.get(STAGING_0));
            ApexPages.currentPage().getParameters().put('pathType', MERGE_STRING);
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code block

            System.assertEquals(MERGE_STRING, currentPipelineController.newOverlay.pathType, 'Path type is not ' + MERGE_STRING);
            System.assertEquals(DEV1_0, currentPipelineController.newOverlay.fromEnvName, 'Source org is not ' + DEV1_0);
            System.assertEquals(STAGING_0, currentPipelineController.newOverlay.toEnvName, 'Destination org is not ' + STAGING_0);
            System.assertEquals(4, currentPipelineController.newOverlay.userStories.size(), 'Number of user stories is not 4');

            currentPipelineController.createPromotionforValidation();

            Test.stopTest();

            // Assertions
            Promotion__c currentPromotionWrapper = currentPipelineController.promotionListWrapper[0].promotion; // Created for better readability
            Promotion__c assertCurrentPromotion = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :DEV1_0 AND Destination_Environment__r.Name = :STAGING_0
                LIMIT 1
            ];

            System.assertNotEquals(null, assertCurrentPromotion.Id, 'Promotion is not created');
            System.assertEquals(
                1,
                currentPipelineController.promotionListWrapper.size(),
                'Promotion list wrapper is not populated correctly with 1 record'
            );
            System.assertEquals(
                assertCurrentPromotion.Name,
                currentPromotionWrapper.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Destination_Environment__c,
                currentPromotionWrapper.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Source_Environment__c,
                currentPromotionWrapper.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Project__c,
                currentPromotionWrapper.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals('Scheduled', currentPromotionWrapper.Status__c, 'Status of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotion.Status__c,
                currentPromotionWrapper.Status__c,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
        }
    }

    @IsTest
    static void testPromotionCreationAndDeploy() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Map<String, String> environmentsByName = new Map<String, String>();
            for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0, :PRODUCTION_0)]) {
                environmentsByName.put(env.Name, env.Id);
            }

            Deployment_Flow__c currentPipeline = [
                SELECT Id, Name, Git_Repository__c, Active__c
                FROM Deployment_Flow__c
                WHERE Name = 'MyPipeline 0'
                LIMIT 1
            ];

            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environmentsByName.get(DEV1_0));
            ApexPages.currentPage().getParameters().put('toId', environmentsByName.get(STAGING_0));
            ApexPages.currentPage().getParameters().put('pathType', MERGE_STRING);
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code Block

            currentPipelineController.createPromotion();

            // Assertions
            Promotion__c currentPromotionWrapper = currentPipelineController.promotionListWrapper[0].promotion; // Created for better readability
            Promotion__c assertCurrentPromotion = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :DEV1_0 AND Destination_Environment__r.Name = :STAGING_0
                LIMIT 1
            ];

            System.assertNotEquals(null, assertCurrentPromotion.Id, 'Promotion is not created');
            System.assertEquals(
                1,
                currentPipelineController.promotionListWrapper.size(),
                'Promotion list wrapper is not populated correctly with 1 record'
            );
            System.assertEquals(
                assertCurrentPromotion.Name,
                currentPromotionWrapper.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Destination_Environment__c,
                currentPromotionWrapper.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Source_Environment__c,
                currentPromotionWrapper.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Project__c,
                currentPromotionWrapper.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals('Draft', currentPromotionWrapper.Status__c, 'Draft of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotion.Status__c,
                currentPromotionWrapper.Status__c,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
        }
    }

    @IsTest
    static void testPromotionPromoteAndDeploy() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Map<String, String> environmentsByName = new Map<String, String>();
            for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0, :PRODUCTION_0)]) {
                environmentsByName.put(env.Name, env.Id);
            }

            Deployment_Flow__c currentPipeline = [
                SELECT Id, Name, Git_Repository__c, Active__c
                FROM Deployment_Flow__c
                WHERE Name = 'MyPipeline 0'
                LIMIT 1
            ];

            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environmentsByName.get(DEV1_0));
            ApexPages.currentPage().getParameters().put('toId', environmentsByName.get(STAGING_0));
            ApexPages.currentPage().getParameters().put('pathType', MERGE_STRING);
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code block

            currentPipelineController.createPromotionListAndDeploy();

            // Assertions
            Promotion__c currentPromotionWrapper = currentPipelineController.promotionListWrapper[0].promotion; // Created for better readability
            Promotion__c assertCurrentPromotion = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :DEV1_0 AND Destination_Environment__r.Name = :STAGING_0
                LIMIT 1
            ];

            System.assertNotEquals(null, assertCurrentPromotion.Id, 'Promotion is not created');
            System.assertEquals(
                1,
                currentPipelineController.promotionListWrapper.size(),
                'Promotion list wrapper is not populated correctly with 1 record'
            );
            System.assertEquals(
                assertCurrentPromotion.Name,
                currentPromotionWrapper.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Destination_Environment__c,
                currentPromotionWrapper.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Source_Environment__c,
                currentPromotionWrapper.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Project__c,
                currentPromotionWrapper.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals('Scheduled', currentPromotionWrapper.Status__c, 'Draft of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotion.Status__c,
                currentPromotionWrapper.Status__c,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
        }
    }

    @IsTest
    static void testMergeConflictCheckbox() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        System.runAs(standardUser) {
            Environment__c sourceEnvironment = [SELECT Id FROM Environment__c WHERE Name = :DEV1_0 LIMIT 1];
            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];

            Test.startTest();
            Pagereference newPromotionPage = Page.PromotionEdit;
            Test.setCurrentPage(newPromotionPage);

            // Standard Controller and Extension controller are not loaded here, because is not needed and there is nothing to test inside.
            Promotion__c newPromotion = new Promotion__c();
            newPromotion.Source_Environment__c = sourceEnvironment.Id;
            newPromotion.Project__c = currentProject.Id;

            insert newPromotion;

            Promotion__c currentPromotion = [
                SELECT
                    Id,
                    Name,
                    Merge_Conflict__c,
                    Status__c,
                    Source_Environment__c,
                    Source_Environment__r.Name,
                    Destination_Environment__c,
                    Destination_Environment__r.Name,
                    Source_Org_Credential__c,
                    Source_Org_Credential__r.Name,
                    Destination_Org_Credential__c,
                    Destination_Org_Credential__r.Name
                FROM Promotion__c
                WHERE Id = :newPromotion.Id
            ];

            ApexPages.StandardController promotionSc = new ApexPages.StandardController(currentPromotion);
            PromoteChangesExtension viewPromotionController = new PromoteChangesExtension(promotionSc);
            // Assertions start
            System.assertEquals(DEV1_0, currentPromotion.Source_Environment__r.Name, 'Source Environment Name is not ' + DEV1_0);
            System.assertEquals(DEV1_0, currentPromotion.Source_Org_Credential__r.Name, 'Source Org Credential Name is not ' + DEV1_0);
            System.assertEquals(STAGING_0, currentPromotion.Destination_Environment__r.Name, 'Destination Environment Name is not ' + STAGING_0);
            System.assertEquals(
                STAGING_0,
                currentPromotion.Destination_Org_Credential__r.Name,
                'Destination Org Credential Name is not ' + STAGING_0
            );
            System.assertEquals(false, currentPromotion.Merge_Conflict__c, 'Merge Conflict has to be FALSE');
            System.assertEquals('Draft', currentPromotion.Status__c, 'Status is not "Draft"');
            // Assertions end

            currentPromotion.Status__c = 'Merge Conflict';
            update currentPromotion;

            currentPromotion = [SELECT Id, Name, Merge_Conflict__c, Status__c FROM Promotion__c WHERE Id = :currentPromotion.Id];
            System.assertEquals(true, currentPromotion.Merge_Conflict__c, 'Merge Conflict has to be TRUE');
            System.assertEquals('Merge Conflict', currentPromotion.Status__c, 'Status is not "Merge Conflict"');

            currentPromotion.Status__c = 'Completed';
            update currentPromotion;

            currentPromotion = [SELECT Id, Name, Merge_Conflict__c, Status__c FROM Promotion__c WHERE Id = :currentPromotion.Id];
            System.assertEquals(true, currentPromotion.Merge_Conflict__c, 'Merge Conflict has to be TRUE');
            System.assertEquals('Completed', currentPromotion.Status__c, 'Status is not "Completed"');

            Test.stopTest();
        }
    }

    @IsTest
    static void testBackPromotionFromPipeline() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);

        System.runAs(standardUser) {
            Deployment_Flow__c currentPipeline = [
                SELECT Id, Name, Git_Repository__c, Active__c
                FROM Deployment_Flow__c
                WHERE Name = 'MyPipeline 0'
                LIMIT 1
            ];

            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];

            Map<String, String> environmentsByName = new Map<String, String>();
            for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0, :PRODUCTION_0)]) {
                environmentsByName.put(env.Name, env.Id);
            }

            Map<String, String> orgCredentialsByName = new Map<String, String>();
            for (Org__c orgCredItem : [SELECT Id, Name FROM Org__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0)]) {
                orgCredentialsByName.put(orgCredItem.Name, orgCredItem.Id);
            }

            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Environment__c, Promote_and_Deploy__c
                FROM User_Story__c
                WHERE User_Story_Title__c = 'My new User Story 0'
            ];
            testUserStory.Org_Credential__c = orgCredentialsByName.get(STAGING_0);
            testUserStory.Environment__c = environmentsByName.get(STAGING_0);
            update testUserStory;

            ITestDefaults promotionDefaults = new CopadoPromotionTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Completed')
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.OwnerId, standardUser.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, currentProject.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, orgCredentialsByName.get(DEV1_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, environmentsByName.get(DEV1_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, orgCredentialsByName.get(STAGING_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, environmentsByName.get(STAGING_0))
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CopadoPromotionTestDefaults.PromotedUserStoryDefaults.class)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, testUserStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // Assert stage 1
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage1 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 1').get(environmentsByName.get(STAGING_0))
            );
            System.debug('assertions: ' + assertionStage1);
            System.assertEquals(2, assertionStage1.size(), 'The number of environments in stage 1 is not 2');

            System.assertEquals(DEV1_0, assertionStage1[0].currentEnvironment.Name, 'Environment 1 name in stage 1 is not ' + DEV1_0);
            System.assertEquals(
                DEV_1_BRANCH,
                assertionStage1[0].currentStep.Branch__c,
                'Environment 1 branch name in stage 1 is not ' + DEV_1_BRANCH
            );

            System.assertEquals(false, assertionStage1[0].isDestinationEnv, 'Environment 1 in stage 1 is not marked as Destination Environment');
            System.assertEquals(3, assertionStage1[0].userStoriesAhead, 'In Environment 2 there are not only 3 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage1[0].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            System.assertEquals(DEV2_0, assertionStage1[1].currentEnvironment.Name, 'Environment 2 name in stage 1 is not ' + DEV2_0);
            System.assertEquals(
                DEV_2_BRANCH,
                assertionStage1[1].currentStep.Branch__c,
                'Environment 2 branch name in stage 1 is not ' + DEV_2_BRANCH
            );
            System.assertEquals(false, assertionStage1[1].isDestinationEnv, 'Environment 2 in stage 1 is not marked as Destination Environment');
            System.assertEquals(0, assertionStage1[1].userStoriesAhead, 'In Environment 2 there are not User Stories Ahead in stage 1');
            System.assertEquals(1, assertionStage1[1].userStoriesBehind, 'In Environment 2 there should be 1 User Stories Behind in stage 1');

            // Assert stage 2
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage2 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 2').get(environmentsByName.get(PRODUCTION_0))
            );
            System.assertEquals(1, assertionStage2.size(), 'The number of environments in stage 2 is not 1');

            System.assertEquals(STAGING_0, assertionStage2[0].currentEnvironment.Name, 'Environment name in stage 2 is not ' + STAGING_0);
            System.assertEquals(
                STAGING_BRANCH,
                assertionStage2[0].currentStep.Branch__c,
                'Environment branch name in stage 2 is not ' + STAGING_BRANCH
            );
            System.assertEquals(true, assertionStage2[0].isDestinationEnv, 'Environment  in stage 2 is marked as Destination Environment');
            System.assertEquals(1, assertionStage2[0].userStoriesAhead, 'In staging environment there should be 1 User Stories Ahead in stage 2');
            System.assertEquals(
                0,
                assertionStage2[0].userStoriesBehind,
                'In staging environment there are more than 0 User Stories Behind in stage 2'
            );

            // Assert stage Final
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStageFinal = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 3').get('Final')
            );
            System.assertEquals(1, assertionStageFinal.size(), 'The number of environments in final stage is not 1');

            System.assertEquals(
                PRODUCTION_0,
                assertionStageFinal[0].currentEnvironment.Name,
                'Environment name in final stage is not ' + PRODUCTION_0
            );
            System.assertEquals(
                'master',
                assertionStageFinal[0].currentStep.Destination_Branch__c,
                'Environment branch name in final stage is not "master" '
            );
            System.assertEquals(true, assertionStageFinal[0].isDestinationEnv, 'Environment  in final stage is marked as Destination Environment');
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesBehind,
                'In production environment there are more than 0 User Stories Ahead in final stage'
            );
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesAhead,
                'In production environment there are more than 0 User Stories Behind in final stage'
            );
            // Assertions end

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environmentsByName.get(STAGING_0));
            ApexPages.currentPage().getParameters().put('toId', environmentsByName.get(DEV2_0));
            ApexPages.currentPage().getParameters().put('pathType', 'pull');
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code block

            System.assertEquals('pull', currentPipelineController.newOverlay.pathType, 'Path type is not pull');
            System.assertEquals(STAGING_0, currentPipelineController.newOverlay.fromEnvName, 'Source org is not ' + STAGING_0);
            System.assertEquals(DEV2_0, currentPipelineController.newOverlay.toEnvName, 'Destination org is not ' + DEV2_0);
            System.assertEquals(1, currentPipelineController.newOverlay.userStories.size(), 'Number of user stories is not 1');

            currentPipelineController.createPromotionListAndDeploy();

            Test.stopTest();

            // Assertions
            Promotion__c currentPromotionWrapper = currentPipelineController.promotionListWrapper[0].promotion; // Created for better readability
            Promotion__c assertCurrentPromotion = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :STAGING_0 AND Destination_Environment__r.Name = :DEV2_0 AND Back_Promotion__c = true
            ];

            System.assertNotEquals(null, assertCurrentPromotion.Id, 'Promotion is not created');
            System.assertEquals(
                1,
                currentPipelineController.promotionListWrapper.size(),
                'Promotion list wrapper is not populated correctly with 1 record'
            );
            System.assertEquals(
                assertCurrentPromotion.Name,
                currentPromotionWrapper.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Destination_Environment__c,
                currentPromotionWrapper.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Source_Environment__c,
                currentPromotionWrapper.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Project__c,
                currentPromotionWrapper.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals('Scheduled', currentPromotionWrapper.Status__c, 'Status of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotion.Status__c,
                currentPromotionWrapper.Status__c,
                'Status of Promotion created and Status of Promotion shown in the list is not the same'
            );
        }
    }

    @IsTest
    static void testBackPromotionFromPipelineProjectAndRelease() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);

        System.runAs(standardUser) {
            Deployment_Flow__c currentPipeline = [
                SELECT Id, Name, Git_Repository__c, Active__c
                FROM Deployment_Flow__c
                WHERE Name = 'MyPipeline 0'
                LIMIT 1
            ];

            Project__c currentProject = [SELECT Id FROM Project__c WHERE Name = :PROJECT_0 LIMIT 1];

            Map<String, String> environmentsByName = new Map<String, String>();
            for (Environment__c env : [SELECT Id, Name FROM Environment__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0, :PRODUCTION_0)]) {
                environmentsByName.put(env.Name, env.Id);
            }

            Map<String, String> orgCredentialsByName = new Map<String, String>();
            for (Org__c orgCredItem : [SELECT Id, Name FROM Org__c WHERE Name IN (:DEV1_0, :DEV2_0, :STAGING_0)]) {
                orgCredentialsByName.put(orgCredItem.Name, orgCredItem.Id);
            }

            List<User_Story__c> testUserStories = [
                SELECT Id, Org_Credential__c, Environment__c, Promote_and_Deploy__c, Project__c, Release__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :new List<String>{ 'My new User Story 0', 'My new User Story 1' }
                LIMIT 2
            ];

            ITestDefaults promotionDefaults = new CopadoPromotionTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Completed')
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.OwnerId, standardUser.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, currentProject.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, orgCredentialsByName.get(DEV1_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, environmentsByName.get(DEV1_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, orgCredentialsByName.get(STAGING_0))
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, environmentsByName.get(STAGING_0))
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CopadoPromotionTestDefaults.PromotedUserStoryDefaults.class)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, testUserStories[0].Id)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoPromotionTestDefaults.PromotedUserStoryDefaults.class)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, testUserStories[1].Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .includeDefaults(CopadoUserStoryTestDefaults.ReleaseDefaults.class)
                .setFieldValue(Release__c.SObjectType, Release__c.Project__c, currentProject.Id)
                .setDataSize(Release__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Release__c currentRelease = (Release__c) promotionDefaults.getTestData(Release__c.SObjectType)[0];

            testUserStories[0].Org_Credential__c = orgCredentialsByName.get(STAGING_0);
            testUserStories[0].Environment__c = environmentsByName.get(STAGING_0);
            testUserStories[1].Org_Credential__c = orgCredentialsByName.get(STAGING_0);
            testUserStories[1].Environment__c = environmentsByName.get(STAGING_0);
            testUserStories[1].Project__c = null;
            testUserStories[1].Release__c = currentRelease.Id;
            update testUserStories;

            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // Assert stage 1
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage1 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 1').get(environmentsByName.get(STAGING_0))
            );
            System.assertEquals(2, assertionStage1.size(), 'The number of environments in stage 1 is not 2');

            System.assertEquals(DEV1_0, assertionStage1[0].currentEnvironment.Name, 'Environment 1 name in stage 1 is not ' + DEV1_0);
            System.assertEquals(
                DEV_1_BRANCH,
                assertionStage1[0].currentStep.Branch__c,
                'Environment 1 branch name in stage 1 is not ' + DEV_1_BRANCH
            );

            System.assertEquals(false, assertionStage1[0].isDestinationEnv, 'Environment 1 in stage 1 is not marked as Destination Environment');
            System.assertEquals(2, assertionStage1[0].userStoriesAhead, 'In Environment 2 there are not only 3 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage1[0].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            System.assertEquals(DEV2_0, assertionStage1[1].currentEnvironment.Name, 'Environment 2 name in stage 1 is not ' + DEV2_0);
            System.assertEquals(
                DEV_2_BRANCH,
                assertionStage1[1].currentStep.Branch__c,
                'Environment 2 branch name in stage 1 is not ' + DEV_2_BRANCH
            );
            System.assertEquals(false, assertionStage1[1].isDestinationEnv, 'Environment 2 in stage 1 is not marked as Destination Environment');
            System.assertEquals(0, assertionStage1[1].userStoriesAhead, 'In Environment 2 there are not User Stories Ahead in stage 1');
            System.assertEquals(2, assertionStage1[1].userStoriesBehind, 'In Environment 2 there should be 2 User Stories Behind in stage 1');

            // Assert stage 2
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage2 = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 2').get(environmentsByName.get(PRODUCTION_0))
            );
            System.assertEquals(1, assertionStage2.size(), 'The number of environments in stage 2 is not 1');

            System.assertEquals(STAGING_0, assertionStage2[0].currentEnvironment.Name, 'Environment name in stage 2 is not ' + STAGING_0);
            System.assertEquals(
                STAGING_BRANCH,
                assertionStage2[0].currentStep.Branch__c,
                'Environment branch name in stage 2 is not ' + STAGING_BRANCH
            );
            System.assertEquals(true, assertionStage2[0].isDestinationEnv, 'Environment  in stage 2 is marked as Destination Environment');
            System.assertEquals(2, assertionStage2[0].userStoriesAhead, 'In staging environment there should be 2 User Stories Ahead in stage 2');
            System.assertEquals(
                0,
                assertionStage2[0].userStoriesBehind,
                'In staging environment there are more than 0 User Stories Behind in stage 2'
            );

            // Assert stage Final
            List<PipelineManagerExtension.EnvironmentWrapper> assertionStageFinal = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get('Stage 3').get('Final')
            );
            System.assertEquals(1, assertionStageFinal.size(), 'The number of environments in final stage is not 1');

            System.assertEquals(
                PRODUCTION_0,
                assertionStageFinal[0].currentEnvironment.Name,
                'Environment name in final stage is not ' + PRODUCTION_0
            );
            System.assertEquals(
                'master',
                assertionStageFinal[0].currentStep.Destination_Branch__c,
                'Environment branch name in final stage is not "master" '
            );
            System.assertEquals(true, assertionStageFinal[0].isDestinationEnv, 'Environment  in final stage is marked as Destination Environment');
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesBehind,
                'In production environment there are more than 0 User Stories Ahead in final stage'
            );
            System.assertEquals(
                0,
                assertionStageFinal[0].userStoriesAhead,
                'In production environment there are more than 0 User Stories Behind in final stage'
            );
            // Assertions end

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environmentsByName.get(STAGING_0));
            ApexPages.currentPage().getParameters().put('toId', environmentsByName.get(DEV2_0));
            ApexPages.currentPage().getParameters().put('pathType', 'pull');
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code block

            System.assertEquals('pull', currentPipelineController.newOverlay.pathType, 'Path type is not pull');
            System.assertEquals(STAGING_0, currentPipelineController.newOverlay.fromEnvName, 'Source org is not ' + STAGING_0);
            System.assertEquals(DEV2_0, currentPipelineController.newOverlay.toEnvName, 'Destination org is not ' + DEV2_0);
            System.assertEquals(2, currentPipelineController.newOverlay.userStories.size(), 'Number of user stories is not 2');

            currentPipelineController.createPromotionListAndDeploy();

            Test.stopTest();

            // Assertions
            Promotion__c currentPromotionsWrapperProject = new Promotion__c();
            Promotion__c currentPromotionsWrapperRelease = new Promotion__c();

            Promotion__c assertCurrentPromotionProject = new Promotion__c();
            Promotion__c assertCurrentPromotionRelease = new Promotion__c();

            for (PipelineManagerExtension.PromotionWrapper currentPromotionWrapper : currentPipelineController.promotionListWrapper) {
                if (currentPromotionWrapper.promotion.Project__c != null) {
                    currentPromotionsWrapperProject = currentPromotionWrapper.promotion;
                } else if (currentPromotionWrapper.promotion.Release__c != null) {
                    currentPromotionsWrapperRelease = currentPromotionWrapper.promotion;
                }
            }
            List<Promotion__c> assertCurrentPromotions = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :STAGING_0 AND Destination_Environment__r.Name = :DEV2_0 AND Back_Promotion__c = true
            ];

            for (Promotion__c promotionItem : [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :STAGING_0 AND Destination_Environment__r.Name = :DEV2_0 AND Back_Promotion__c = true
            ]) {
                if (promotionItem.Project__c != null) {
                    assertCurrentPromotionProject = promotionItem;
                } else if (promotionItem.Release__c != null) {
                    assertCurrentPromotionRelease = promotionItem;
                }
            }

            System.assertEquals(
                2,
                currentPipelineController.promotionListWrapper.size(),
                'Promotion list wrapper is not populated correctly with 2 record'
            );
            System.assertEquals(
                assertCurrentPromotionProject.Name,
                currentPromotionsWrapperProject.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionProject.Destination_Environment__c,
                currentPromotionsWrapperProject.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionProject.Source_Environment__c,
                currentPromotionsWrapperProject.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionProject.Project__c,
                currentPromotionsWrapperProject.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(null, currentPromotionsWrapperProject.Release__c, 'Release must be empty');
            System.assertEquals(null, assertCurrentPromotionProject.Release__c, 'Release must be empty');
            System.assertEquals('Scheduled', assertCurrentPromotionProject.Status__c, 'Status of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotionProject.Status__c,
                currentPromotionsWrapperProject.Status__c,
                'Status of Promotion created and Status Promotion shown in the list is not the same'
            );

            System.assertEquals(
                assertCurrentPromotionRelease.Name,
                currentPromotionsWrapperRelease.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionRelease.Destination_Environment__c,
                currentPromotionsWrapperRelease.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionRelease.Source_Environment__c,
                currentPromotionsWrapperRelease.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotionRelease.Release__c,
                currentPromotionsWrapperRelease.Release__c,
                'Release of Promotion created and Release shown in the list is not the same'
            );
            System.assertEquals(null, currentPromotionsWrapperRelease.Project__c, 'Project must be empty');
            System.assertEquals(null, assertCurrentPromotionRelease.Project__c, 'Project must be empty');
            System.assertEquals('Scheduled', assertCurrentPromotionRelease.Status__c, 'Status of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotionRelease.Status__c,
                currentPromotionsWrapperRelease.Status__c,
                'Status of Promotion created and Status Promotion shown in the list is not the same'
            );
        }
    }
}