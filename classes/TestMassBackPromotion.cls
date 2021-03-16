@IsTest
private with sharing class TestMassBackPromotion {
    private static final String EMPTY_STRING = '';
    private static final String ADMIN_USER = 'test_admin@myorg.com';
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    private static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();

        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Integration')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
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
            Environment__c integrationEnvironment = new Environment__c();
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
                    when 'Integration 0' {
                        integrationEnvironment = env;
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
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Staging')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Integration')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, integrationEnvironment.Id)
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
            Org__c integrationOrg = new Org__c();
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
                    when 'Integration 0' {
                        integrationOrg = org;
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
                .includeDefaults(CopadoUserStoryTestDefaults.ReleaseDefaults.class)
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
                .setSObjectRelation(
                    Release__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Release__c.Project__c => 1 }
                )
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setDataSize(Project__c.SObjectType, 1)
                .setDataSize(Release__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Project__c project = (Project__c) pipelineDefaults.getTestData(Project__c.SObjectType)[0];
            Release__c release = (Release__c) pipelineDefaults.getTestData(Release__c.SObjectType)[0];
            Deployment_Flow__c pipeline = (Deployment_Flow__c) pipelineDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults pipelineConnectionsDefaults = new CopadoUserStoryTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'integration')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, integrationEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'integration')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, integrationEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'integration')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, integrationEnvironment.Id)
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

            ITestDefaults userStoryDefaultsFromIntegration = new CopadoUserStoryTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        User_Story__c.SObjectType => new Set<Schema.SObjectField>{ User_Story__c.User_Story_Title__c }
                    }
                )
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Promote_Change__c, true)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Exclude_From_CBM__c, false)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Status__c, 'Completed')
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, project.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Release__c, release.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, integrationOrg.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, integrationEnvironment.Id)
                .setDataSize(User_Story__c.SObjectType, 4)
                .includeDefaults(CopadoMassBackPromotionTestDefaults.PromotionDefaults.class)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Completed')
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.OwnerId, standardUser.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, integrationOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, integrationEnvironment.Id)
                .setDataSize(Promotion__c.SObjectType, 4)
                .includeDefaults(CopadoMassBackPromotionTestDefaults.PromotedUserStoryDefaults.class)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    User_Story__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.User_Story__c => 1 }
                )
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .setDataSize(Promoted_User_Story__c.SObjectType, 4)
                .generateDefaults()
                .executeDML();

            ITestDefaults userStoryDefaultsFromProduction = new CopadoUserStoryTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        User_Story__c.SObjectType => new Set<Schema.SObjectField>{ User_Story__c.User_Story_Title__c }
                    }
                )
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Promote_Change__c, true)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Exclude_From_CBM__c, false)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Status__c, 'Completed')
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, project.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Release__c, release.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, productionOrg.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, productionEnvironment.Id)
                .setDataSize(User_Story__c.SObjectType, 4)
                .includeDefaults(CopadoMassBackPromotionTestDefaults.PromotionDefaults.class)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Completed')
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.OwnerId, standardUser.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, stagingOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, productionOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, productionEnvironment.Id)
                .setDataSize(Promotion__c.SObjectType, 4)
                .includeDefaults(CopadoMassBackPromotionTestDefaults.PromotedUserStoryDefaults.class)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    User_Story__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.User_Story__c => 1 }
                )
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .setDataSize(Promoted_User_Story__c.SObjectType, 4)
                .generateDefaults()
                .executeDML();
        }
    }

    /**
     * Having created 4 user stories from staging, mass back promote 4 stories to integration
     */
    @IsTest
    static void massBackPromote4UserStoriesFromPipelineComingFromMiddleEnvironment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c integrationEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : [SELECT Name FROM Environment__c]) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Integration 0' {
                        integrationEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            Project__c relatedProject = [SELECT Id FROM Project__c LIMIT 1];
            Release__c relatedRelease = [SELECT Id FROM Release__c LIMIT 1];

            List<User_Story__c> userStories = [SELECT Name FROM User_Story__c WHERE Environment__c = :productionEnvironment.Id];

            Deployment_Flow__c pipeline = [SELECT Git_Repository__c, Active__c FROM Deployment_Flow__c LIMIT 1];

            Test.startTest();

            PageReference submitPage = Page.PipelineManager;
            submitPage.getParameters().put('id', pipeline.Id);
            Test.setCurrentPage(submitPage);

            PipelineManagerExtension pipelineManagerExtensionController = new PipelineManagerExtension(new ApexPages.StandardController((pipeline)));

            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');
            System.assert(ApexPages.getMessages().isEmpty(), 'The should not be messages in the page.');

            BranchManagementExtension branchManagementExtensionController = new BranchManagementExtension(
                new ApexPages.StandardController((pipeline))
            );

            branchManagementExtensionController.prepareRebase();
            System.assertEquals(
                stagingEnvironment.Id,
                branchManagementExtensionController.rebaseSourceEnvironments[2].getValue(),
                'Sources should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseSource = stagingEnvironment.Id;

            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(
                relatedProject.Id,
                branchManagementExtensionController.projects[1].getValue(),
                'Projects should have been populated accordingly'
            );
            System.assertEquals(
                relatedRelease.Id,
                branchManagementExtensionController.releases[1].getValue(),
                'Releases should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseProject = relatedProject.Id;
            branchManagementExtensionController.rebaseRelease = relatedRelease.Id;
            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(
                4,
                branchManagementExtensionController.rebaseUserStoriesWrapper.size(),
                'Expected number of User Stories should be 4'
            );

            System.assertEquals(4, userStories.size(), 'Existing User Stories should be 4');
            System.assertEquals(
                userStories[0].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[0].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[1].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[1].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[2].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[2].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[3].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[3].userStory.Id,
                'User Story in wrapper is not the expected one'
            );

            List<BranchManagementExtension.RebaseEnvironmentWrapper> rebaseSources = branchManagementExtensionController.rebaseSources;
            System.assertEquals(1, rebaseSources.size(), 'Expected number of Rebase Sources should be 1');
            System.assert(rebaseSources[0].isSelected, 'Rebase Source should be selected');

            List<BranchManagementExtension.UserStoryWrapper> rebaseUserStoriesWrapper = branchManagementExtensionController.rebaseUserStoriesWrapper;
            System.assertEquals(4, rebaseUserStoriesWrapper.size(), 'Expected number of Rebase User Stories Wrappers should be 4');
            System.assert(rebaseUserStoriesWrapper[0].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[1].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[2].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[3].isSelected, 'Rebase User Story Wrapper should be selected');

            Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> usEnvironmentAvailabilityMap = branchManagementExtensionController.usEnvironmentAvailabilityMap;
            System.assertEquals(4, usEnvironmentAvailabilityMap.size(), 'Expected available Environments should be 4');
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );

            branchManagementExtensionController.createRebasePromotionsAndDeploy();

            List<Promotion__c> promotions = [
                SELECT Source_Environment__c, Destination_Environment__c, Project__c, Release__c, Status__c
                FROM Promotion__c
                WHERE Back_Promotion__c = true
            ];

            System.assertEquals(1, promotions.size(), 'Existing promotions should be 1');

            System.assertEquals(stagingEnvironment.Id, promotions[0].Source_Environment__c, 'Source_Environment__c should be Staging');
            System.assertEquals(integrationEnvironment.Id, promotions[0].Destination_Environment__c, 'Destination_Environment__c should be Integration');
            System.assertEquals(relatedProject.Id, promotions[0].Project__c, 'Related project is not the expected one');
            System.assertEquals(relatedRelease.Id, promotions[0].Release__c, 'Related release is not the expected one');
            System.assertEquals('Scheduled', promotions[0].Status__c, 'Status should be Scheduled');

            List<Promoted_User_Story__c> promotedUserStories = [
                SELECT User_Story__c, Promotion__c, Name
                FROM Promoted_User_Story__c
                WHERE Promotion__r.Back_Promotion__c = true
                ORDER BY User_Story__c DESC
            ];

            System.assertEquals(4, promotedUserStories.size(), 'Existing Promoted User Stories should be 8');

            System.assertEquals(promotions[0].Id, promotedUserStories[0].Promotion__c, 'Related Promotion is not the expected one');
            System.assertEquals(promotions[0].Id, promotedUserStories[1].Promotion__c, 'Related Promotion is not the expected one');
            System.assertEquals(promotions[0].Id, promotedUserStories[2].Promotion__c, 'Related Promotion is not the expected one');
            System.assertEquals(promotions[0].Id, promotedUserStories[3].Promotion__c, 'Related Promotion is not the expected one');

            System.assertEquals(userStories[3].Id, promotedUserStories[0].User_Story__c, 'Related User Story is not the expected one');
            System.assertEquals(userStories[2].Id, promotedUserStories[1].User_Story__c, 'Related User Story is not the expected one');
            System.assertEquals(userStories[1].Id, promotedUserStories[2].User_Story__c, 'Related User Story is not the expected one');
            System.assertEquals(userStories[0].Id, promotedUserStories[3].User_Story__c, 'Related User Story is not the expected one');

            System.assertEquals(
                'Promoted User Story: ' + userStories[3].Name,
                promotedUserStories[0].Name,
                'Name should be Promoted User Story: ' + userStories[3].Name
            );
            System.assertEquals(
                'Promoted User Story: ' + userStories[2].Name,
                promotedUserStories[1].Name,
                'Name should be Promoted User Story: ' + userStories[2].Name
            );
            System.assertEquals(
                'Promoted User Story: ' + userStories[1].Name,
                promotedUserStories[2].Name,
                'Name should be Promoted User Story: ' + userStories[1].Name
            );
            System.assertEquals(
                'Promoted User Story: ' + userStories[0].Name,
                promotedUserStories[3].Name,
                'Name should be Promoted User Story: ' + userStories[0].Name
            );

            Test.stopTest();
        }
    }

    /**
     * Having 4 user stories from dev 1 and deployed to integration, mass back promote 4 stories from integration to dev 2
     */
    @IsTest
    static void massBackPromote4UserStoriesFromPipelineComingFromPreviousEnvironment() {
        User standardUser = [SELECT Id FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c integrationEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : [SELECT Name FROM Environment__c]) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Integration 0' {
                        integrationEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c integrationOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();

            for (Org__c org : [SELECT Name FROM Org__c]) {
                switch on org.Name {
                    when 'Production 0' {
                        productionOrg = org;
                    }
                    when 'Staging 0' {
                        stagingOrg = org;
                    }
                    when 'Integration 0' {
                        integrationOrg = org;
                    }
                    when 'Dev2 0' {
                        dev2Org = org;
                    }
                }
            }

            Project__c relatedProject = [SELECT Id FROM Project__c LIMIT 1];
            Release__c relatedRelease = [SELECT Id FROM Release__c LIMIT 1];

            Deployment_Flow__c pipeline = [SELECT Git_Repository__c, Active__c FROM Deployment_Flow__c LIMIT 1];

            List<User_Story__c> userStories = [SELECT Name FROM User_Story__c WHERE Environment__c = :integrationEnvironment.Id];

            Test.startTest();

            PageReference submitPage = Page.PipelineManager;
            submitPage.getParameters().put('id', pipeline.Id);
            Test.setCurrentPage(submitPage);

            PipelineManagerExtension pipelineManagerExtensionController = new PipelineManagerExtension(new ApexPages.StandardController((pipeline)));

            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');
            System.assert(ApexPages.getMessages().isEmpty(), 'The should not be messages in the page.');

            BranchManagementExtension branchManagementExtensionController = new BranchManagementExtension(
                new ApexPages.StandardController((pipeline))
            );

            branchManagementExtensionController.prepareRebase();
            System.assertEquals(
                integrationEnvironment.Id,
                branchManagementExtensionController.rebaseSourceEnvironments[1].getValue(),
                'Sources should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseSource = integrationEnvironment.Id;

            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(
                relatedProject.Id,
                branchManagementExtensionController.projects[1].getValue(),
                'Projects should have been populated accordingly'
            );
            System.assertEquals(
                relatedRelease.Id,
                branchManagementExtensionController.releases[1].getValue(),
                'Releases should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseProject = relatedProject.Id;
            branchManagementExtensionController.rebaseRelease = relatedRelease.Id;
            branchManagementExtensionController.getRebaseUserStories();
            System.assertEquals(
                4,
                branchManagementExtensionController.rebaseUserStoriesWrapper.size(),
                'Expected number of User Stories should be 4'
            );

            System.assertEquals(4, userStories.size(), 'Existing User Stories should be 4');
            System.assertEquals(
                userStories[0].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[0].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[1].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[1].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[2].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[2].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                userStories[3].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[3].userStory.Id,
                'User Story in wrapper is not the expected one'
            );

            List<BranchManagementExtension.RebaseEnvironmentWrapper> rebaseSources = branchManagementExtensionController.rebaseSources;
            System.assertEquals(2, rebaseSources.size(), 'Expected number of Rebase Sources should be 2');
            System.assert(rebaseSources[0].isSelected, 'Rebase Source should be selected');
            System.assert(rebaseSources[1].isSelected, 'Rebase Source should be selected');

            List<BranchManagementExtension.UserStoryWrapper> rebaseUserStoriesWrapper = branchManagementExtensionController.rebaseUserStoriesWrapper;
            System.assertEquals(4, rebaseUserStoriesWrapper.size(), 'Expected number of Rebase User Stories Wrappers should be 4');
            System.assert(rebaseUserStoriesWrapper[0].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[1].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[2].isSelected, 'Rebase User Story Wrapper should be selected');
            System.assert(rebaseUserStoriesWrapper[3].isSelected, 'Rebase User Story Wrapper should be selected');

            Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> usEnvironmentAvailabilityMap = branchManagementExtensionController.usEnvironmentAvailabilityMap;
            System.assertEquals(4, usEnvironmentAvailabilityMap.size(), 'Expected available Environments should be 4');
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                !usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[0].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );

            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[0].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[1].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[2].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isAvailable,
                'Environment should be available'
            );
            System.assert(
                usEnvironmentAvailabilityMap.get(rebaseUserStoriesWrapper[3].userStory.Id)
                    .get(rebaseSources[1].step.Source_Environment__c)
                    .isSelected,
                'Environment should be selected'
            );

            branchManagementExtensionController.createRebasePromotionsAndDeploy();

            List<Promotion__c> promotions = [
                SELECT Source_Environment__c, Destination_Environment__c, Project__c, Release__c, Status__c
                FROM Promotion__c
                WHERE Back_Promotion__c = true
            ];

            System.assertEquals(1, promotions.size(), 'Existing promotions should be 1');

            System.assertEquals(integrationEnvironment.Id, promotions[0].Source_Environment__c, 'Source_Environment__c should be Staging');
            System.assertEquals(dev2Environment.Id, promotions[0].Destination_Environment__c, 'Destination_Environment__c should be Dev 2');
            System.assertEquals(relatedProject.Id, promotions[0].Project__c, 'Related project is not the expected one');
            System.assertEquals(relatedRelease.Id, promotions[0].Release__c, 'Related release is not the expected one');
            System.assertEquals('Scheduled', promotions[0].Status__c, 'Status should be Scheduled');

            Test.stopTest();
        }
    }

    /**
     * Having 4 user stories from dev 1 to integration, and 4 user stories from staging to production, mass back promote 4 user stories
     * from integration to dev 2, and 4 user stories from staging to integration
     */
    @IsTest
    static void multipleSourceMassBackPromote4UserStoriesFromPipeline() {
        User standardUser = [SELECT Id FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c integrationEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : [SELECT Name FROM Environment__c]) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Integration 0' {
                        integrationEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c integrationOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();

            for (Org__c org : [SELECT Name FROM Org__c]) {
                switch on org.Name {
                    when 'Production 0' {
                        productionOrg = org;
                    }
                    when 'Staging 0' {
                        stagingOrg = org;
                    }
                    when 'Integration 0' {
                        integrationOrg = org;
                    }
                    when 'Dev1 0' {
                        dev1Org = org;
                    }
                    when 'Dev2 0' {
                        dev2Org = org;
                    }
                }
            }

            Project__c relatedProject = [SELECT Id FROM Project__c LIMIT 1];
            Release__c relatedRelease = [SELECT Id FROM Release__c LIMIT 1];

            Deployment_Flow__c pipeline = [SELECT Git_Repository__c, Active__c FROM Deployment_Flow__c LIMIT 1];

            List<User_Story__c> integrationUserStories = new List<User_Story__c>();
            List<User_Story__c> stagingUserStories = new List<User_Story__c>();
            for (User_Story__c userStory : [SELECT Name, Environment__c FROM User_Story__c]) {
                if (userStory.Environment__c == integrationEnvironment.Id) {
                    integrationUserStories.add(userStory);
                } else if (userStory.Environment__c == productionEnvironment.Id) {
                    stagingUserStories.add(userStory);
                }
            }

            Test.startTest();

            PageReference submitPage = Page.PipelineManager;
            submitPage.getParameters().put('id', pipeline.Id);
            Test.setCurrentPage(submitPage);

            PipelineManagerExtension pipelineManagerExtensionController = new PipelineManagerExtension(new ApexPages.StandardController((pipeline)));

            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');
            System.assert(ApexPages.getMessages().isEmpty(), 'The should not be messages in the page.');

            BranchManagementExtension branchManagementExtensionController = new BranchManagementExtension(
                new ApexPages.StandardController((pipeline))
            );

            branchManagementExtensionController.prepareRebase();
            System.assertEquals(
                integrationEnvironment.Id,
                branchManagementExtensionController.rebaseSourceEnvironments[1].getValue(),
                'Sources should have been populated accordingly'
            );
            System.assertEquals(
                stagingEnvironment.Id,
                branchManagementExtensionController.rebaseSourceEnvironments[2].getValue(),
                'Sources should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseSource = integrationEnvironment.Id;
            branchManagementExtensionController.getRebaseUserStories();

            branchManagementExtensionController.rebaseProject = relatedProject.Id;
            branchManagementExtensionController.rebaseRelease = relatedRelease.Id;
            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(4, integrationUserStories.size(), 'Retrieved User Stories should be 4');
            System.assertEquals(
                integrationUserStories.size(),
                branchManagementExtensionController.rebaseUserStoriesWrapper.size(),
                'Expected number of User Stories should be 4'
            );

            System.assertEquals(
                integrationUserStories[0].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[0].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                integrationUserStories[1].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[1].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                integrationUserStories[2].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[2].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                integrationUserStories[3].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[3].userStory.Id,
                'User Story in wrapper is not the expected one'
            );

            branchManagementExtensionController.createRebasePromotions();

            branchManagementExtensionController.resetPromotions();

            System.assert(ApexPages.getMessages().isEmpty(), 'Page should not have any message');
            System.assert(!branchManagementExtensionController.rebasePromotionsCreated, 'rebasePromotionsCreated check should be false');
            System.assert(!branchManagementExtensionController.rebaseDeploymentsCompleted, 'rebaseDeploymentsCompleted check should be false');
            System.assert(!branchManagementExtensionController.enabledRebasePromotionPoller, 'enabledRebasePromotionPoller check should be false');
            System.assert(!branchManagementExtensionController.showHiddenCheckboxes, 'showHiddenCheckboxes check should be false');
            System.assertEquals(EMPTY_STRING, branchManagementExtensionController.rebaseSource, 'rebaseSource should be empty');
            System.assertEquals(EMPTY_STRING, branchManagementExtensionController.rebaseProject, 'rebaseProject should be empty');
            System.assertEquals(EMPTY_STRING, branchManagementExtensionController.rebaseRelease, 'rebaseRelease should be empty');
            System.assert(branchManagementExtensionController.projects.isEmpty(), 'Page should not have any project');
            System.assert(branchManagementExtensionController.releases.isEmpty(), 'Page should not have any release');
            System.assert(branchManagementExtensionController.rebaseSources.isEmpty(), 'Page should not have any rebase source');
            System.assert(
                branchManagementExtensionController.rebaseUserStoriesWrapper.isEmpty(),
                'Page should not have any rebase user story wrapper'
            );

            branchManagementExtensionController.rebaseSource = stagingEnvironment.Id;

            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(
                relatedProject.Id,
                branchManagementExtensionController.projects[1].getValue(),
                'Projects should have been populated accordingly'
            );
            System.assertEquals(
                relatedRelease.Id,
                branchManagementExtensionController.releases[1].getValue(),
                'Releases should have been populated accordingly'
            );

            branchManagementExtensionController.rebaseProject = relatedProject.Id;
            branchManagementExtensionController.rebaseRelease = relatedRelease.Id;
            branchManagementExtensionController.getRebaseUserStories();

            System.assertEquals(4, stagingUserStories.size(), 'Retrieved User Stories should be 4');
            System.assertEquals(
                stagingUserStories.size(),
                branchManagementExtensionController.rebaseUserStoriesWrapper.size(),
                'Expected number of User Stories should be 4'
            );

            System.assertEquals(
                stagingUserStories[0].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[0].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                stagingUserStories[1].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[1].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                stagingUserStories[2].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[2].userStory.Id,
                'User Story in wrapper is not the expected one'
            );
            System.assertEquals(
                stagingUserStories[3].Id,
                branchManagementExtensionController.rebaseUserStoriesWrapper[3].userStory.Id,
                'User Story in wrapper is not the expected one'
            );

            branchManagementExtensionController.createRebasePromotions();

            List<Promotion__c> promotions = [SELECT Status__c FROM Promotion__c WHERE Back_Promotion__c = true];

            System.assertEquals(2, promotions.size(), 'Existing promotions should be 2');

            System.assertEquals('Draft', promotions[0].Status__c, 'Status should be Draft');
            System.assertEquals('Draft', promotions[1].Status__c, 'Status should be Draft');

            branchManagementExtensionController.deployPromotions();

            List<Promotion__c> promotionsAfterDeploy = [SELECT Status__c FROM Promotion__c WHERE Back_Promotion__c = true];

            System.assertEquals(2, promotionsAfterDeploy.size(), 'Existing promotions should be 2');

            System.assertEquals('Scheduled', promotionsAfterDeploy[0].Status__c, 'Status should be Scheduled');
            System.assertEquals('Scheduled', promotionsAfterDeploy[1].Status__c, 'Status should be Scheduled');

            Test.stopTest();
        }
    }
}