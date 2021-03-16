@IsTest
private class TestUserStoryManagement {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String MY_NEW_USER_STORY = 'My new User Story 0';
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
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Metadata_Types_in_Selection__c, 'ApexClass')
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        User_Story__c.SObjectType => new Set<Schema.SObjectField>{ User_Story__c.User_Story_Title__c }
                    }
                )
                .setDataSize(User_Story__c.SObjectType, 2)
                .generateDefaults()
                .executeDML();
        }
    }

    /**
     * Creation of new User Story of type "Investigation"
     */
    @IsTest
    static void testNewInvestigationUserStory() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            Id investigationRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName()
                .get('Investigation')
                .getRecordTypeId();

            User_Story__c investigatioUserStory = new User_Story__c();
            investigatioUserStory.RecordTypeId = investigationRecordTypeId;

            insert investigatioUserStory;

            // Setting up data to make assertions
            User_Story__c userStoryCreated = [SELECT Id, RecordTypeId FROM User_Story__c WHERE Id = :investigatioUserStory.Id LIMIT 1];

            System.assert(userStoryCreated.Id != null);
            System.assertEquals(investigationRecordTypeId, userStoryCreated.RecordTypeId);
        }
    }

    /**
     * New User Story with basic data creation.
     */
    @IsTest
    static void testNewUserStoryWithBasicData() {
        Org__c orgCredentialDev1 = [SELECT Id, Name, Environment__c FROM Org__c WHERE Name LIKE 'Dev1%' LIMIT 1];
        Project__c pipelineProject = [SELECT Id, Name FROM Project__c WHERE Name LIKE 'MyProject%' LIMIT 1];

        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            String namespace = Settings.ns;
            Id userStoryRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('User_Story').getRecordTypeId();

            Test.startTest();
            User_Story__c myUserStory = new User_Story__c();
            myUserStory.RecordTypeId = userStoryRecordTypeId;
            myUserStory.User_Story_Title__c = MY_NEW_USER_STORY;
            myUserStory.Project__c = pipelineProject.Id;
            myUserStory.Org_Credential__c = orgCredentialDev1.Id;

            insert myUserStory;

            // Setting up data to make assertions
            User_Story__c userStoryCreated = [
                SELECT
                    Id,
                    Org_Credential__c,
                    Org_Credential__r.Org_Type__c,
                    Project__c,
                    Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__c,
                    Environment__c
                FROM User_Story__c
                WHERE Id = :myUserStory.Id
                LIMIT 1
            ];
            Test.setCurrentPage(Page.UserStory);
            ApexPages.StandardController sc = new ApexPages.StandardController(userStoryCreated);
            UserStoryExt userStoryController = new UserStoryExt(sc);
            List<GlobalUtilities.flowStepWrapper> userStoryDeploymentSteps = userStoryController.getDeploymentFlowSteps();
            Set<String> assertEnviroments = new Set<String>{ 'Dev1 0', 'Staging 0', 'Production 0' };

            System.assert(userStoryCreated.Environment__c != null);
            System.assertEquals(orgCredentialDev1.Environment__c, userStoryCreated.Environment__c);
            System.assert(!userStoryDeploymentSteps.isEmpty());
            System.assert(userStoryDeploymentSteps.size() == 3);

            for (GlobalUtilities.flowStepWrapper step : userStoryDeploymentSteps) {
                System.assert(assertEnviroments.contains(step.environment));
            }
        }
        Test.stopTest();
    }

    /**
     * Check functionality on button Ready to Promote
     */
    @IsTest
    static void testUserStoryReadyToPromote() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Environment__c, Environment__r.Name, Project__c, Promote_Change__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];

            Test.startTest();
            PageReference submitPage = Page.UserStoryReadyForPromote;
            submitPage.getParameters().put('id', testUserStory.Id);
            Test.setCurrentPage(submitPage);

            UserStoryReadyForPromoteExtension userStoryReadytoPromoteController = new UserStoryReadyForPromoteExtension(
                new ApexPages.StandardController((testUserStory))
            );
            List<GlobalUtilities.flowStepWrapper> userStoryDeploymentSteps = userStoryReadytoPromoteController.getDeploymentFlowSteps();

            // Assertions.
            System.assert(userStoryReadytoPromoteController.pageMessagesMap.size() == 1);
            System.assertEquals(
                Label.USER_STORY_CONNECTION_BEHAVIOR_NOT_FOUND,
                (String) userStoryReadytoPromoteController.pageMessagesMap.get(UserStoryReadyForPromoteExtension.ERROR)[0]
            );
            System.assert(userStoryReadytoPromoteController.dependenciesList.isEmpty());
            System.assert(userStoryReadytoPromoteController.qualityGateList.isEmpty());
            System.assert(!userStoryDeploymentSteps.isEmpty());
            System.assert(userStoryDeploymentSteps.size() == 3);

            Set<String> assertEnviroments = new Set<String>{ 'Dev1 0', 'Staging 0', 'Production 0' };
            System.assertEquals(testUserStory.Environment__c, userStoryReadytoPromoteController.currentUserStory.Environment__c);
            System.assertEquals('Staging 0', userStoryReadytoPromoteController.nextEnvironment);
            for (GlobalUtilities.flowStepWrapper step : userStoryDeploymentSteps) {
                System.assert(assertEnviroments.contains(step.environment));
            }
            //

            PageReference resultUserStory = userStoryReadytoPromoteController.submitChanges();

            // Assertions
            System.assertEquals(new PageReference('/' + testUserStory.Id).getUrl(), resultUserStory.getUrl());
            System.assert([SELECT Id, Promote_Change__c FROM User_Story__c WHERE Id = :testUserStory.Id].Promote_Change__c);

            Test.stopTest();
        }
    }

    /**
     * Test behaviour when using SCA in negative when there are no settings.
     */
    @IsTest
    static void testUserStoryNoSCASettings() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Environment__c, Environment__r.Name, Project__c, Promote_Change__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];

            String userStoryAttachmentContent = '[{"t":"ApexClass","n":"CommitedApexClass","b":"DeveloperName","d":"2019-09-18","cb":"DeveloperName","cd":"2019-07-10","r":false,"cmm":"updated","snapshotCommitId":"a0X0X00000lI1ZTUA0"}]';

            List<Attachment> userStoryAttachments = new List<Attachment>();
            Attachment attachmentItem = new Attachment();
            attachmentItem.Name = 'Git MetaData';
            attachmentItem.ParentId = testUserStory.Id;
            attachmentItem.Body = Blob.valueOf(userStoryAttachmentContent);
            userStoryAttachments.add(attachmentItem);
            insert userStoryAttachments;

            Test.startTest();
            PageReference submitPage = Page.UserStoryCodeAnalysisRequested;
            submitPage.getParameters().put('id', testUserStory.Id);
            Test.setCurrentPage(submitPage);
            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');

            UserStoryCodeAnalysisRequestController codeAnalysisRequestController = new UserStoryCodeAnalysisRequestController(
                new ApexPages.StandardController((testUserStory))
            );
            codeAnalysisRequestController.requestCodeScan();
            ApexPages.Message pageMessage = ApexPages.getMessages()[0];
            System.assertEquals(ApexPages.Severity.ERROR, pageMessage.getSeverity(), 'Message severity should be ERROR');
            System.assertEquals(Label.SCA_SETTINGS_NOT_FOUND, pageMessage.getSummary(), 'Unexpected message received');
            Test.stopTest();
        }
    }

    /**
     * Checks pull request button behaviour
     */
    @IsTest
    static void testUserStoryOpenPullRequest() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Environment__c, Environment__r.Name, Project__c, Promote_Change__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];
            ITestDefaults gitOrgCommitDefaults = new CopadoUserStoryTestDefaults.GitOrgCommitDefaults()
                .setFieldDefaults()
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Org__c, testUserStory.Org_Credential__c)
                .setDataSize(Git_Org_Commit__c.SObjectType, 1)
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryCommitDefaults.class)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.User_Story__c, testUserStory.Id)
                .setDataSize(User_Story_Commit__c.SObjectType, 1)
                .setSObjectRelation(
                    User_Story_Commit__c.SObjectType,
                    Git_Org_Commit__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story_Commit__c.Snapshot_Commit__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Test.startTest();
            PageReference submitPage = Page.UserStoryPageWaitingFor;
            submitPage.getParameters().put('id', testUserStory.Id);
            submitPage.getParameters().put('type', 'co_pullRequest');
            Test.setCurrentPage(submitPage);
            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');

            JobWaitingExtension jobWaitingExtensionController = new JobWaitingExtension(new ApexPages.StandardController((testUserStory)));
            PageReference openPullRequestPage = jobWaitingExtensionController.preparationPullRequest();

            System.assertNotEquals(null, openPullRequestPage, 'The open pull request page should not be null');
            Test.stopTest();
        }
    }

    /**
     * Test here have scenario with attachment and JSON field empty
     */
    @IsTest
    static void testUserStoryCreateDeploymentTaskApexScript() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];

            Test.startTest();
            PageReference deploymentTaskPage = Page.EditDeploymentTask;
            Test.setCurrentPage(deploymentTaskPage);
            System.assertEquals(deploymentTaskPage, ApexPages.currentPage(), 'The current page is not the expected one');

            DeploymentTaskExtension deploymentTaskExtensionController = new DeploymentTaskExtension(
                new ApexPages.StandardController(new Deployment_Task__c(User_Story__c = testUserStory.Id))
            );
            deploymentTaskExtensionController.task.Name = 'Apex Script';
            deploymentTaskExtensionController.task.Type__c = 'Apex';
            deploymentTaskExtensionController.task.Status__c = 'Draft';
            deploymentTaskExtensionController.task.Perform_Manual_Task__c = 'Before Deployment';
            deploymentTaskPage.getParameters().put('detail', 'System.debug(\'This is an Apex Script\');');
            PageReference taskDetailPage = deploymentTaskExtensionController.saveAction();
            Test.setCurrentPage(taskDetailPage);

            System.assertEquals(
                new PageReference('/' + deploymentTaskExtensionController.task.Id).getUrl(),
                taskDetailPage.getUrl(),
                'The returned PageReference is not the expected one'
            );
            Deployment_Task__c createdDeploymentTask = [
                SELECT Id, Name, User_Story__c, Type__c, Status__c, Perform_Manual_Task__c, dataJSON__c
                FROM Deployment_Task__c
                WHERE Id = :deploymentTaskExtensionController.task.Id
                LIMIT 1
            ];
            deploymentTaskExtensionController = new DeploymentTaskExtension(new ApexPages.StandardController(createdDeploymentTask));

            System.assertEquals(
                'Apex Script',
                deploymentTaskExtensionController.task.Name,
                'Deployment Task Name populated is different from inserted'
            );
            System.assertEquals('Apex', deploymentTaskExtensionController.task.Type__c, 'Deployment Task Type populated is not Apex');
            System.assertEquals('Draft', deploymentTaskExtensionController.task.Status__c, 'Deployment Task Status populated is not Draft');
            System.assertEquals(
                'Before Deployment',
                deploymentTaskExtensionController.task.Perform_Manual_Task__c,
                'Deployment Task Name populated is Before Deployment'
            );
            System.assertEquals(
                null,
                deploymentTaskExtensionController.task.dataJSON__c,
                'The Apex Script should not have been saved in the dataJSON field'
            );
            System.assertEquals(
                1,
                [SELECT COUNT() FROM Attachment WHERE ParentId = :deploymentTaskExtensionController.task.Id AND Name = 'Apex'],
                'The Apex Script attachment should have been created'
            );

            Test.stopTest();
        }
    }

    /**
     * Test here have scenario without attachment but with parameters in JSON field.
     */
    @IsTest
    static void testUserStoryCreateDeploymentTaskDataTemplate() {
        String dataJsonString = '{"dataTemplateId":"a1W0X0000042ooe","dataTemplateName":"My Data Template"}';
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];

            Test.startTest();
            PageReference deploymentTaskPage = Page.EditDeploymentTask;
            Test.setCurrentPage(deploymentTaskPage);
            System.assertEquals(deploymentTaskPage, ApexPages.currentPage(), 'The current page is not the expected one');

            DeploymentTaskExtension deploymentTaskExtensionController = new DeploymentTaskExtension(
                new ApexPages.StandardController(new Deployment_Task__c(User_Story__c = testUserStory.Id))
            );
            deploymentTaskExtensionController.task.Name = 'Data Template task';
            deploymentTaskExtensionController.task.Type__c = 'Data Template';
            deploymentTaskExtensionController.task.Status__c = 'Draft';
            deploymentTaskExtensionController.task.Perform_Manual_Task__c = 'Before Deployment';

            deploymentTaskPage.getParameters().put('detail', dataJsonString);

            PageReference taskDetailPage = deploymentTaskExtensionController.saveAction();
            Test.setCurrentPage(taskDetailPage);

            System.assertEquals(
                0,
                [SELECT COUNT() FROM Attachment WHERE ParentId = :deploymentTaskExtensionController.task.Id],
                'The should not be created'
            );
            System.assertEquals(
                new PageReference('/' + deploymentTaskExtensionController.task.Id).getUrl(),
                taskDetailPage.getUrl(),
                'The returned PageReference is not the expected one'
            );
            Deployment_Task__c createdDeploymentTask = [
                SELECT Id, Name, User_Story__c, Type__c, Status__c, Perform_Manual_Task__c, dataJSON__c
                FROM Deployment_Task__c
                WHERE Id = :deploymentTaskExtensionController.task.Id
                LIMIT 1
            ];
            deploymentTaskExtensionController = new DeploymentTaskExtension(new ApexPages.StandardController(createdDeploymentTask));

            System.assertEquals(
                'Data Template task',
                deploymentTaskExtensionController.task.Name,
                'Deployment Task Name populated is different from inserted'
            );
            System.assertEquals(
                'Data Template',
                deploymentTaskExtensionController.task.Type__c,
                'Deployment Task Type populated is not Data Template'
            );
            System.assertEquals('Draft', deploymentTaskExtensionController.task.Status__c, 'Deployment Task Status populated is not Draft');
            System.assertEquals(
                'Before Deployment',
                deploymentTaskExtensionController.task.Perform_Manual_Task__c,
                'Deployment Task Name populated is Before Deployment'
            );
            System.assertEquals(
                dataJsonString,
                deploymentTaskExtensionController.task.dataJSON__c,
                'Deployment Task Data Template info is different from inserted'
            );

            Test.stopTest();
        }
    }

    /**
     * Test here have scenario of manual task creation: no attachment, parameters are saved in JSON field.
     */
    @IsTest
    static void testUserStoryCreateManualTask() {
        String assertJsonString = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"This is my manual task","Task_Owner":"000000000000000","Notify_Task_Owner":""}';
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];

            Test.startTest();
            PageReference deploymentTaskPage = Page.EditDeploymentTask;
            Test.setCurrentPage(deploymentTaskPage);
            System.assertEquals(deploymentTaskPage, ApexPages.currentPage(), 'The current page is not the expected one');

            DeploymentTaskExtension deploymentTaskExtensionController = new DeploymentTaskExtension(
                new ApexPages.StandardController(new Deployment_Task__c(User_Story__c = testUserStory.Id))
            );
            deploymentTaskExtensionController.task.Name = 'Manual task';
            deploymentTaskExtensionController.task.Type__c = 'Manual Task';
            deploymentTaskExtensionController.task.Status__c = 'Draft';
            deploymentTaskExtensionController.task.Perform_Manual_Task__c = 'Before Deployment';
            deploymentTaskExtensionController.task.Perform_in_Destination_Orgs__c = true;
            deploymentTaskExtensionController.task.Task_Description__c = 'This is my manual task';

            /** This blocks simulates how javascript sends info to Save method */
            Map<String, Object> manualTask = new Map<String, Object>{
                'Notify_Task_Owner' => '',
                'Task_Owner' => '000000000000000', // if it is blank, this is default value
                'Task_Description' => deploymentTaskExtensionController.task.Task_Description__c,
                'Perform_in_Destination_Orgs' => deploymentTaskExtensionController.task.Perform_in_Destination_Orgs__c,
                'Perform_in_Source_Org' => false
            };
            /** End of block */

            deploymentTaskPage.getParameters().put('detail', JSON.serialize(manualTask));
            PageReference taskDetailPage = deploymentTaskExtensionController.saveAction();
            Test.setCurrentPage(taskDetailPage);

            System.assertEquals(
                0,
                [SELECT COUNT() FROM Attachment WHERE ParentId = :deploymentTaskExtensionController.task.Id],
                'The attachment should not be created'
            );
            System.assertEquals(
                new PageReference('/' + deploymentTaskExtensionController.task.Id).getUrl(),
                taskDetailPage.getUrl(),
                'The returned PageReference is not the expected one'
            );
            Deployment_Task__c createdDeploymentTask = [
                SELECT Id, Name, User_Story__c, Type__c, Status__c, Perform_Manual_Task__c, dataJSON__c
                FROM Deployment_Task__c
                WHERE Id = :deploymentTaskExtensionController.task.Id
                LIMIT 1
            ];
            deploymentTaskExtensionController = new DeploymentTaskExtension(new ApexPages.StandardController(createdDeploymentTask));

            System.assertEquals('Manual task', deploymentTaskExtensionController.task.Name, 'Manual Task Name populated is different from inserted');
            System.assertEquals('Manual Task', deploymentTaskExtensionController.task.Type__c, 'Manual Task Type populated is not Manual Task');
            System.assertEquals('Draft', deploymentTaskExtensionController.task.Status__c, 'Manual Task Status populated is not Draft');
            System.assertEquals(
                'Before Deployment',
                deploymentTaskExtensionController.task.Perform_Manual_Task__c,
                'Manual Task Name populated is not Before Deployment'
            );
            System.assertEquals(assertJsonString, deploymentTaskExtensionController.task.dataJSON__c, 'Manual Task info is different from inserted');

            Test.stopTest();
        }
    }

    /**
     * Checks functionality for Test Run and Execute test run button
     */
    @IsTest
    static void testUserStoryCreateTestScriptAndRun() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];
            Environment__c testEnvironmentDev1 = [SELECT Id FROM Environment__c WHERE Name = 'Dev1 0'];

            Test.startTest();

            ITestDefaults testScriptDefaults = new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.User_Story__c, testUserStory.Id)
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.Peer_Reviewer__c, standardUser.Id)
                .setDataSize(Test_Script__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Script__c testScript = (Test_Script__c) testScriptDefaults.getTestData(Test_Script__c.SObjectType)[0];
            PageReference createTestStepsPage = Page.CreateTestScriptSteps;
            createTestStepsPage.getParameters().put('tId', testScript.Id);
            Test.setCurrentPage(createTestStepsPage);
            System.assertEquals(createTestStepsPage, ApexPages.currentPage(), 'The current page is not the expected one');

            CreateTestScriptStepsController testScriptsStepsController = new CreateTestScriptStepsController();
            List<CreateTestScriptStepsController.stepRow> steps = testScriptsStepsController.getSteps();
            System.assert(steps.isEmpty(), 'Steps list at the beginning should be empty');

            testScriptsStepsController.dummyStep.Action_Description__c = 'Test Action Description';
            testScriptsStepsController.dummyStep.Expected_Result__c = 'Test Expected Result';
            testScriptsStepsController.dummyStep.Guidance_notes__c = 'Test Guidance Notes';
            testScriptsStepsController.addRow();
            steps = testScriptsStepsController.getSteps();
            System.assertEquals(1, steps.size(), 'Steps list should contain 1 step');
            PageReference testScriptRecordPage = testScriptsStepsController.returnToTestScript();
            System.assertEquals(
                new PageReference('/' + testScript.Id).getUrl(),
                testScriptRecordPage.getUrl(),
                'Returned page should be Test Script record page'
            );

            ITestDefaults testRunDefaults = new CopadoUserStoryTestDefaults.TestRunDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Environment__c, testEnvironmentDev1.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Tester__c, standardUser.Id)
                .setDataSize(Test_Run__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Run__c testRun = (Test_Run__c) testRunDefaults.getTestData(Test_Run__c.SObjectType)[0];
            PageReference executeTestRunPage = Page.ExecuteTestRun;
            executeTestRunPage.getParameters().put('id', testRun.Id);
            Test.setCurrentPage(executeTestRunPage);
            System.assertEquals(executeTestRunPage, ApexPages.currentPage(), 'The current page is not the expected one');

            ApexPages.StandardController testRunStandardController = new ApexPages.StandardController(testRun);
            ExecuteTestRunExtension executeTestRunController = new ExecuteTestRunExtension(testRunStandardController);
            List<Test_Run_Step__c> testRunSteps = executeTestRunController.steps;
            System.assertEquals(1, testRunSteps.size(), 'There should be 1 Test Run Step');
            testRunSteps[0].Actual_Result__c = 'Test Actual Result';
            executeTestRunController.thisStepId = testRunSteps[0].Id;
            executeTestRunController.thisStepStatus = 'Passed';
            executeTestRunController.updateTestRunStatus();
            System.assertEquals('Passed', executeTestRunController.testRun.Status__c, 'Test Run Status should be \'Passed\'');

            PageReference testRunRecordPage = testRunStandardController.save();
            // Needed since testRecordPageUrl returns the record page with the Id of 15 characters instead of 18
            System.assertEquals(
                new PageReference('/' + testRun.Id).getUrl().left(16),
                testRunRecordPage.getUrl(),
                'Returned page should be Test Run record page'
            );

            Test.stopTest();
        }
    }

    /**
     * Checks functionality for Test Run, Execute test run button and add comments in test run
     */
    @IsTest
    static void testUserStoryCreateTestScriptAndRunWithComments() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];
            Environment__c testEnvironmentDev1 = [SELECT Id FROM Environment__c WHERE Name = 'Dev1 0'];

            Test.startTest();

            ITestDefaults testScriptDefaults = new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.User_Story__c, testUserStory.Id)
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.Peer_Reviewer__c, standardUser.Id)
                .setDataSize(Test_Script__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Script__c testScript = (Test_Script__c) testScriptDefaults.getTestData(Test_Script__c.SObjectType)[0];
            PageReference createTestStepsPage = Page.CreateTestScriptSteps;
            createTestStepsPage.getParameters().put('tId', testScript.Id);
            Test.setCurrentPage(createTestStepsPage);
            System.assertEquals(createTestStepsPage, ApexPages.currentPage(), 'The current page is not the expected one');

            CreateTestScriptStepsController testScriptsStepsController = new CreateTestScriptStepsController();
            List<CreateTestScriptStepsController.stepRow> steps = testScriptsStepsController.getSteps();
            System.assert(steps.isEmpty(), 'Steps list at the beginning should be empty');

            testScriptsStepsController.dummyStep.Action_Description__c = 'Test Action Description';
            testScriptsStepsController.dummyStep.Expected_Result__c = 'Test Expected Result';
            testScriptsStepsController.dummyStep.Guidance_notes__c = 'Test Guidance Notes';
            testScriptsStepsController.addRow();
            testScriptsStepsController.dummyStep.Action_Description__c = 'My second Action Description';
            testScriptsStepsController.dummyStep.Expected_Result__c = 'Test Expected Result number two';
            testScriptsStepsController.addRow();
            steps = testScriptsStepsController.getSteps();
            System.assertEquals(2, steps.size(), 'Steps list should contain 2 steps');
            PageReference testScriptRecordPage = testScriptsStepsController.returnToTestScript();
            System.assertEquals(
                new PageReference('/' + testScript.Id).getUrl(),
                testScriptRecordPage.getUrl(),
                'Returned page should be Test Script record page'
            );

            ITestDefaults testRunDefaults = new CopadoUserStoryTestDefaults.TestRunDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Environment__c, testEnvironmentDev1.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Tester__c, standardUser.Id)
                .setDataSize(Test_Run__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Run__c testRun = (Test_Run__c) testRunDefaults.getTestData(Test_Run__c.SObjectType)[0];
            PageReference executeTestRunPage = Page.ExecuteTestRun;
            executeTestRunPage.getParameters().put('id', testRun.Id);
            Test.setCurrentPage(executeTestRunPage);
            System.assertEquals(executeTestRunPage, ApexPages.currentPage(), 'The current page is not the expected one');

            ApexPages.StandardController testRunStandardController = new ApexPages.StandardController(testRun);
            ExecuteTestRunExtension executeTestRunController = new ExecuteTestRunExtension(testRunStandardController);
            List<Test_Run_Step__c> testRunSteps = executeTestRunController.steps;
            System.assertEquals(2, testRunSteps.size(), 'There should be 2 Test Run Step');
            testRunSteps[0].Actual_Result__c = 'Comments';
            executeTestRunController.thisStepId = testRunSteps[0].Id;
            executeTestRunController.thisStepStatus = 'Passed with comments';
            executeTestRunController.updateTestRunStatus();
            executeTestRunController.thisStepId = testRunSteps[1].Id;
            executeTestRunController.thisStepStatus = 'Passed';
            executeTestRunController.updateTestRunStatus();
            System.assertEquals(
                'Passed with comments',
                executeTestRunController.testRun.Status__c,
                'Test Run Status should be \'Passed with comments\''
            );

            PageReference testRunRecordPage = testRunStandardController.save();
            // Needed since testRecordPageUrl returns the record page with the Id of 15 characters instead of 18
            System.assertEquals(
                new PageReference('/' + testRun.Id).getUrl().left(16),
                testRunRecordPage.getUrl(),
                'Returned page should be Test Run record page'
            );
            Test_Run__c assertTestRun = [
                SELECT Id, Name, Status__c, Steps_Completed__c, Steps_Passed__c, Test_Completion__c, Percent_Passed__c
                FROM Test_Run__c
                WHERE Id = :testRun.Id
            ];
            System.assertEquals('Passed with comments', assertTestRun.Status__c, 'Test Run Status should be \'Passed with comments\'');
            System.assertEquals(2, assertTestRun.Steps_Completed__c, 'There must be 2');
            System.assertEquals(2, assertTestRun.Steps_Passed__c, 'There must be 2');
            System.assertEquals(100, assertTestRun.Test_Completion__c, 'There must be 100%');
            System.assertEquals(100, assertTestRun.Percent_Passed__c, 'There must be 100%');

            Test.stopTest();
        }
    }

    /**
     * Checks functionality for Test Run, Execute test run button and one step is failed.
     */
    @IsTest
    static void testUserStoryCreateTestScriptAndRunAndFailStep() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :MY_NEW_USER_STORY];
            Environment__c testEnvironmentDev1 = [SELECT Id FROM Environment__c WHERE Name = 'Dev1 0'];

            Test.startTest();

            ITestDefaults testScriptDefaults = new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.User_Story__c, testUserStory.Id)
                .setFieldValue(Test_Script__c.SObjectType, Test_Script__c.Peer_Reviewer__c, standardUser.Id)
                .setDataSize(Test_Script__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Script__c testScript = (Test_Script__c) testScriptDefaults.getTestData(Test_Script__c.SObjectType)[0];
            PageReference createTestStepsPage = Page.CreateTestScriptSteps;
            createTestStepsPage.getParameters().put('tId', testScript.Id);
            Test.setCurrentPage(createTestStepsPage);
            System.assertEquals(createTestStepsPage, ApexPages.currentPage(), 'The current page is not the expected one');

            CreateTestScriptStepsController testScriptsStepsController = new CreateTestScriptStepsController();
            List<CreateTestScriptStepsController.stepRow> steps = testScriptsStepsController.getSteps();
            System.assert(steps.isEmpty(), 'Steps list at the beginning should be empty');

            testScriptsStepsController.dummyStep.Action_Description__c = 'Test Action Description';
            testScriptsStepsController.dummyStep.Expected_Result__c = 'Test Expected Result';
            testScriptsStepsController.dummyStep.Guidance_notes__c = 'Test Guidance Notes';
            testScriptsStepsController.addRow();
            testScriptsStepsController.dummyStep.Action_Description__c = 'My second Action Description';
            testScriptsStepsController.dummyStep.Expected_Result__c = 'Test Expected Result number two';
            testScriptsStepsController.addRow();
            steps = testScriptsStepsController.getSteps();
            System.assertEquals(2, steps.size(), 'Steps list should contain 2 steps');
            PageReference testScriptRecordPage = testScriptsStepsController.returnToTestScript();
            System.assertEquals(
                new PageReference('/' + testScript.Id).getUrl(),
                testScriptRecordPage.getUrl(),
                'Returned page should be Test Script record page'
            );

            ITestDefaults testRunDefaults = new CopadoUserStoryTestDefaults.TestRunDefaults()
                .setFieldDefaults()
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Test_Script__c, testScript.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Environment__c, testEnvironmentDev1.Id)
                .setFieldValue(Test_Run__c.SObjectType, Test_Run__c.Tester__c, standardUser.Id)
                .setDataSize(Test_Run__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test_Run__c testRun = (Test_Run__c) testRunDefaults.getTestData(Test_Run__c.SObjectType)[0];
            PageReference executeTestRunPage = Page.ExecuteTestRun;
            executeTestRunPage.getParameters().put('id', testRun.Id);
            Test.setCurrentPage(executeTestRunPage);
            System.assertEquals(executeTestRunPage, ApexPages.currentPage(), 'The current page is not the expected one');

            ApexPages.StandardController testRunStandardController = new ApexPages.StandardController(testRun);
            ExecuteTestRunExtension executeTestRunController = new ExecuteTestRunExtension(testRunStandardController);
            List<Test_Run_Step__c> testRunSteps = executeTestRunController.steps;
            System.assertEquals(2, testRunSteps.size(), 'There should be 2 Test Run Step');
            executeTestRunController.thisStepId = testRunSteps[0].Id;
            executeTestRunController.thisStepStatus = 'Failed';
            executeTestRunController.updateTestRunStatus();
            executeTestRunController.thisStepId = testRunSteps[1].Id;
            executeTestRunController.thisStepStatus = 'Passed';
            executeTestRunController.updateTestRunStatus();
            System.assertEquals('Failed', executeTestRunController.testRun.Status__c, 'Test Run Status should be \'Failed\'');

            PageReference testRunRecordPage = testRunStandardController.save();
            // Needed since testRecordPageUrl returns the record page with the Id of 15 characters instead of 18
            System.assertEquals(
                new PageReference('/' + testRun.Id).getUrl().left(16),
                testRunRecordPage.getUrl(),
                'Returned page should be Test Run record page'
            );
            Test_Run__c assertTestRun = [
                SELECT Id, Name, Status__c, Steps_Completed__c, Steps_Passed__c, Test_Completion__c, Percent_Passed__c
                FROM Test_Run__c
                WHERE Id = :testRun.Id
            ];
            System.assertEquals('Failed', assertTestRun.Status__c, 'Test Run Status should be \'Failed\'');
            System.assertEquals(2, assertTestRun.Steps_Completed__c, 'There must be 2');
            System.assertEquals(1, assertTestRun.Steps_Passed__c, 'There must be 1');
            System.assertEquals(100, assertTestRun.Test_Completion__c, 'There must be 100%');
            System.assertEquals(50, assertTestRun.Percent_Passed__c, 'There must be 50%');

            Test.stopTest();
        }
    }

    /**
     * Merge Conflict in user story validation.
     */
    @IsTest
    static void testUserStoryValidationMergeConflict() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Metadata_Types_in_Selection__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];

            Test.startTest();
            PageReference submitPage = Page.UserStoryPageWaitingFor;
            submitPage.getParameters().put('id', testUserStory.Id);
            submitPage.getParameters().put('type', 'co_validation');
            Test.setCurrentPage(submitPage);
            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');

            JobWaitingExtension jobWaitingExtensionController = new JobWaitingExtension(new ApexPages.StandardController((testUserStory)));
            jobWaitingExtensionController.prepareValidation();

            Promotion__c currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Status__c = 'Validation' LIMIT 1];
            currentPromotion.Status__c = 'Merge Conflict';
            update currentPromotion;

            testUserStory = [
                SELECT Id, Org_Credential__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c, Last_Validation_Deployment__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];
            currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Id = :currentPromotion.Id LIMIT 1];

            System.assertEquals('Merge Conflict', currentPromotion.Status__c, 'Status is not "Merge Conflict"');
            System.assertEquals(currentPromotion.Id, testUserStory.Last_Validation_Promotion__c, 'Promotion is not correct');
            System.assertEquals(null, testUserStory.Last_Validation_Deployment__c, 'Deployment record must be blank');
            System.assertEquals('Merge Conflict', testUserStory.Last_Validation_Deployment_Status__c, 'Status is not "Merge Conflict"');

            Test.stopTest();
        }
    }

    /**
     * Validation Deployment Completed Succesfully
     */
    @IsTest
    static void testUserStoryValidationCompleted() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Metadata_Types_in_Selection__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];

            Test.startTest();
            PageReference submitPage = Page.UserStoryPageWaitingFor;
            submitPage.getParameters().put('id', testUserStory.Id);
            submitPage.getParameters().put('type', 'co_validation');
            Test.setCurrentPage(submitPage);
            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');

            JobWaitingExtension jobWaitingExtensionController = new JobWaitingExtension(new ApexPages.StandardController((testUserStory)));
            jobWaitingExtensionController.prepareValidation();

            Promotion__c currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Status__c = 'Validation' LIMIT 1];

            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, testUserStory.Org_Credential__c)
                .setFieldValue(Deployment__c.SObjectType, Deployment__c.Promotion__c, currentPromotion.Id)
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.CheckOnly__c, true)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Git MetaData')
                .setDataSize(Deployment__c.SObjectType, 1)
                .setDataSize(Step__c.SObjectType, 1)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment__c testDeployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];
            testDeployment.Status__c = 'Completed Successfully';
            update testDeployment;

            testUserStory = [
                SELECT Id, Org_Credential__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c, Last_Validation_Deployment__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
                LIMIT 1
            ];
            currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Id = :currentPromotion.Id LIMIT 1];

            System.assertEquals('Validated', currentPromotion.Status__c, 'Status is not "Validated"');
            System.assertEquals(currentPromotion.Id, testUserStory.Last_Validation_Promotion__c, 'Promotion is not correct');
            System.assertEquals(testDeployment.Id, testUserStory.Last_Validation_Deployment__c, 'Deployment record is not correct');
            System.assert(testUserStory.Last_Validation_Deployment_Status__c.contains('Validated'), 'Status is not "Validated"');

            Test.stopTest();
        }
    }

    /**
     * Validation Deployment Completed With Errors
     */
    @IsTest
    static void testUserStoryValidationWithErrors() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c testUserStory = [
                SELECT Id, Org_Credential__c, Metadata_Types_in_Selection__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
            ];

            Test.startTest();
            PageReference submitPage = Page.UserStoryPageWaitingFor;
            submitPage.getParameters().put('id', testUserStory.Id);
            submitPage.getParameters().put('type', 'co_validation');
            Test.setCurrentPage(submitPage);
            System.assertEquals(submitPage, ApexPages.currentPage(), 'The current page is not the expected one');

            JobWaitingExtension jobWaitingExtensionController = new JobWaitingExtension(new ApexPages.StandardController((testUserStory)));
            jobWaitingExtensionController.prepareValidation();

            Promotion__c currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Status__c = 'Validation' LIMIT 1];

            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, testUserStory.Org_Credential__c)
                .setFieldValue(Deployment__c.SObjectType, Deployment__c.Promotion__c, currentPromotion.Id)
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.CheckOnly__c, true)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Git MetaData')
                .setDataSize(Deployment__c.SObjectType, 1)
                .setDataSize(Step__c.SObjectType, 1)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment__c testDeployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];
            testDeployment.Status__c = 'Completed with Errors';
            update testDeployment;

            testUserStory = [
                SELECT Id, Org_Credential__c, Last_Validation_Promotion__c, Last_Validation_Deployment_Status__c, Last_Validation_Deployment__c
                FROM User_Story__c
                WHERE User_Story_Title__c = :MY_NEW_USER_STORY
                LIMIT 1
            ];
            currentPromotion = [SELECT Id, Name, Status__c FROM Promotion__c WHERE Id = :currentPromotion.Id LIMIT 1];

            System.assertEquals('Validation failed', currentPromotion.Status__c, 'Status is not "Completed with errors"');
            System.assertEquals(currentPromotion.Id, testUserStory.Last_Validation_Promotion__c, 'Promotion is not correct');
            System.assertEquals(testDeployment.Id, testUserStory.Last_Validation_Deployment__c, 'Deployment record is not correct');
            System.assert(testUserStory.Last_Validation_Deployment_Status__c.contains('Validation failed'), 'Status is not "Completed with errors"');

            Test.stopTest();
        }
    }

    /**
     * Project - Index Metadata Calculations
     */
    @IsTest
    static void testIndexMetadataInProject() {
        String userStoryAttachmentContent = '[{"t":"ApexClass","n":"CommitedApexClass","b":"DeveloperName","d":"2019-09-18","cb":"DeveloperName","cd":"2019-07-10","r":false,"cmm":"updated","snapshotCommitId":"a0X0X00000lI1ZTUA0"}]';
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            List<Attachment> userStoryAttachments = new List<Attachment>();
            Map<Id, User_Story__c> userStoriesById = new Map<Id, User_Story__c>([SELECT Id, Name, Project__c FROM User_Story__c LIMIT 2]);
            Set<Id> userStoryIds = userStoriesById.keySet();

            for (Id userStoryId : userStoryIds) {
                Attachment attachmentItem = new Attachment();
                attachmentItem.Name = 'Git Metadata';
                attachmentItem.ParentId = userStoryId;
                attachmentItem.Body = Blob.valueOf(userStoryAttachmentContent);
                userStoryAttachments.add(attachmentItem);
            }

            insert userStoryAttachments;

            Test.startTest();
            Project__c testProject = [SELECT Id, Name, Index_Metadata__c FROM Project__c WHERE Id = :userStoriesById.values()[0].Project__c LIMIT 1];
            testProject.Index_Metadata__c = true;
            update testProject;

            Test.stopTest();

            List<User_Story_Metadata__c> assertMetadataUserStories = [
                SELECT Id, Name, Status__c, Metadata_API_Name__c, Unique_ID__c, User_Story__c, User_Story__r.Name
                FROM User_Story_Metadata__c
                WHERE User_Story__c = :userStoryIds
            ];
            System.assertEquals(
                userStoryIds.size(),
                assertMetadataUserStories.size(),
                'User Story metadata records created are different from number of user stories'
            );

            for (User_Story_Metadata__c usMetadataItem : assertMetadataUserStories) {
                System.assertEquals(usMetadataItem.User_Story__c + '_' + usMetadataItem.Metadata_API_Name__c, usMetadataItem.Unique_ID__c);
                System.assertEquals('ApexClass.CommitedApexClass', usMetadataItem.Metadata_API_Name__c, 'API Name is not correct');
                System.assertEquals(
                    usMetadataItem.User_Story__r.Name + ' ApexClass.CommitedApexClass',
                    usMetadataItem.Name,
                    'Metadata name in record is not correct'
                );
                System.assertEquals('Potential Conflict', usMetadataItem.Status__c, 'Status must be "Potential Conflict"');
            }
        }
    }

    /**
     * Stop Indexing Metadata User Story
     */
    @IsTest
    static void testStopIndexingMetadataUserStory() {
        String userStoryAttachmentContent = '[{"t":"ApexClass","n":"CommitedApexClass","b":"DeveloperName","d":"2019-09-18","cb":"DeveloperName","cd":"2019-07-10","r":false,"cmm":"updated","snapshotCommitId":"a0X0X00000lI1ZTUA0"}]';
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            User_Story__c userStory1 = new User_Story__c();
            User_Story__c userStory2 = new User_Story__c();
            List<User_Story_Metadata__c> userStoriesMetadata = new List<User_Story_Metadata__c>();
            List<User_Story__c> userStories = [SELECT Id, Name, Project__c, Stop_Indexing_Metadata__c FROM User_Story__c LIMIT 2];

            Project__c testProject = [SELECT Id, Name, Index_Metadata__c FROM Project__c WHERE Id = :userStories[0].Project__c LIMIT 1];
            testProject.Index_Metadata__c = true;
            update testProject;

            for (User_Story__c userStoryItem : userStories) {
                if (userStories.indexOf(userStoryItem) == 0) {
                    userStory1 = userStoryItem;
                } else if (userStories.indexOf(userStoryItem) == 1) {
                    userStory2 = userStoryItem;
                }

                User_Story_Metadata__c usMetadataItem = new User_Story_Metadata__c();
                usMetadataItem.User_Story__c = userStoryItem.Id;
                usMetadataItem.Metadata_API_Name__c = 'ApexClass.CommitedApexClass';
                usMetadataItem.Unique_ID__c = userStoryItem.Id + '_' + usMetadataItem.Metadata_API_Name__c;
                usMetadataItem.Name = userStoryItem.Name + ' ApexClass.CommitedApexClass';
                userStoriesMetadata.add(usMetadataItem);
            }
            insert userStoriesMetadata;

            Test.startTest();

            UserStoryMetadataExt userStoryMetadataController = new UserStoryMetadataExt(new ApexPages.StandardController(userStoriesMetadata[0]));
            System.assertEquals(
                'ApexClass.CommitedApexClass',
                userStoryMetadataController.usMetadata.Metadata_API_Name__c,
                'Metadata API Name is not the expected'
            );
            System.assertEquals(userStory1.Id, userStoryMetadataController.usMetadata.User_Story__c, 'User Story is not the expected one');

            System.assertEquals(1, userStoryMetadataController.usMetadataList.size(), 'List must contains records');
            System.assertEquals(
                'ApexClass.CommitedApexClass',
                userStoryMetadataController.usMetadataList[0].Metadata_API_Name__c,
                'Metadata API Name is not the expected'
            );
            System.assertEquals(userStory2.Id, userStoryMetadataController.usMetadataList[0].User_Story__c, 'User Story is not the expected one');

            userStory2.Stop_Indexing_Metadata__c = true;
            update userStory2;

            Test.stopTest();

            userStoryMetadataController = new UserStoryMetadataExt(new ApexPages.StandardController(userStoriesMetadata[0]));
            System.assertEquals(
                'ApexClass.CommitedApexClass',
                userStoryMetadataController.usMetadata.Metadata_API_Name__c,
                'Metadata API Name is not the expected'
            );
            System.assertEquals(userStory1.Id, userStoryMetadataController.usMetadata.User_Story__c, 'User Story is not the expected one');
            System.assert(userStoryMetadataController.usMetadataList.isEmpty(), 'List must be empty');
        }
    }
}