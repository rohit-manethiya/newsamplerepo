@IsTest
public with sharing class TestJobWaitingExtension {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    private static final String USER_STORY_QUERY = 'SELECT Id, Name, Base_Branch__c, Project__c, Release__c, Project__r.Deployment_Flow__r.Main_Branch__c, Release__r.Base_Branch__c FROM User_Story__c WHERE User_Story_Title__c = \'My new User Story\' LIMIT 1';
    private static final MockHttpResponseGenerator FAKERESPONSE = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);

    @TestSetup static void setupTestData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults pipelineDefaults = new CopadoUserStoryTestDefaults.PipelineDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.ReleaseDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.ProjectDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryDefaults.class)
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
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setDataSize(Project__c.SObjectType, 1)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setDataSize(Release__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest static void userStoryValidation() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            TestUtilities testUtils = new TestUtilities();
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            Environment__c env1 = new Environment__c();
            env1.Name = 'Dev1';
            env1.Org_ID__c = 'SFDC_OrgId';
            Environment__c env2 = new Environment__c();
            env2.Name = 'Dev2';
            env2.Org_ID__c = 'SFDC_OrgId2';
            Environment__c env3 = new Environment__c();
            env3.Name = 'Int';
            env3.Org_ID__c = 'SFDC_OrgId3';
            Environment__c env4 = new Environment__c();
            env4.Name = 'UAT';
            env4.Org_ID__c = 'SFDC_OrgId4';
            Environment__c env5 = new Environment__c();
            env5.Name = 'Prod';
            env5.Org_ID__c = 'SFDC_OrgId5';
            insert new List<SObject>{
                    env1, env2, env3, env4, env5
            };

            // Create org credentials record
            Org__c org1 = new Org__c();
            org1.Name = 'OrgDev1';
            org1.Org_Type__c = 'Sandbox';
            org1.SFDC_Org_ID__c = 'SFDC_OrgId';
            org1.Token__c = null;
            org1.Username__c = null;
            org1.Validated_Date__c = System.now();
            org1.Environment__c = env1.Id;
            Org__c org2 = new Org__c();
            org2.Name = 'OrgDev2';
            org2.Org_Type__c = 'Sandbox';
            org2.SFDC_Org_ID__c = 'SFDC_OrgId2';
            org2.Token__c = null;
            org2.Username__c = null;
            org2.Validated_Date__c = System.now();
            org2.Environment__c = env2.Id;
            Org__c org3 = new Org__c();
            org3.Name = 'OrgInt';
            org3.Org_Type__c = 'Sandbox';
            org3.SFDC_Org_ID__c = 'SFDC_OrgId3';
            org3.Token__c = null;
            org3.Username__c = null;
            org3.Validated_Date__c = System.now();
            org3.Environment__c = env3.Id;
            Org__c org4 = new Org__c();
            org4.Name = 'OrgUAT';
            org4.Org_Type__c = 'Sandbox';
            org4.SFDC_Org_ID__c = 'SFDC_OrgId4';
            org4.Token__c = null;
            org4.Username__c = null;
            org4.Validated_Date__c = System.now();
            org4.Environment__c = env4.Id;
            Org__c org5 = new Org__c();
            org5.Name = 'OrgProd';
            org5.Org_Type__c = 'Production';
            org5.SFDC_Org_ID__c = 'SFDC_OrgId5';
            org5.Token__c = null;
            org5.Username__c = null;
            org5.Validated_Date__c = System.now();
            org5.Environment__c = env5.Id;
            insert new List<SObject>{
                    org1, org2, org3, org4, org5
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            Deployment_Flow_Step__c dfs1 = new Deployment_Flow_Step__c();
            dfs1.Source_Environment__c = env1.Id;
            dfs1.Destination_Environment__c = env3.Id;
            dfs1.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs2 = new Deployment_Flow_Step__c();
            dfs2.Source_Environment__c = env2.Id;
            dfs2.Destination_Environment__c = env3.Id;
            dfs2.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs3 = new Deployment_Flow_Step__c();
            dfs3.Source_Environment__c = env3.Id;
            dfs3.Destination_Environment__c = env4.Id;
            dfs3.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs4 = new Deployment_Flow_Step__c();
            dfs4.Source_Environment__c = env4.Id;
            dfs4.Destination_Environment__c = env5.Id;
            dfs4.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            insert new List<SObject>{
                    dfs1, dfs2, dfs3, dfs4
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => env1.Id,
                    'Org_Credential__c' => org1.Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_validation');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            System.assertEquals(1, controller.pageMessagesMap.size());
            System.assertEquals(1, controller.getPageMessageSize());

            controller.prepareValidation();

            Id promotionId = [SELECT Id FROM Promotion__c WHERE Status__c = 'Validation' LIMIT 1].Id;

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.runValidation();

            controller.getIsValidationPollerEnabled();

            // Create deployment record
            Deployment__c deployment = new Deployment__c();
            deployment.Name = 'Deployment';
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.From_Org__c = org1.Id;
            deployment.Schedule__c = '';
            deployment.Status__c = 'Completed';
            deployment.Promotion__c = promotionId;
            insert deployment;
            controller.waitForDeployment();

            // Create 1 copado notification
            Copado_Notification__c notification = new Copado_Notification__c();
            notification.Type__c = 'Promotion';
            notification.status__c = 'Starting';
            notification.isSuccess__c = false;
            notification.isFinished__c = false;
            notification.Name = 'PROGRESS_STATUS_COPADO';
            notification.ParentId__c = promotionId;
            insert notification;
            controller.waitForDeployment();

            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForDeployment();

            notification.isSuccess__c = true;
            update notification;
            controller.waitForDeployment();

            // Create 1 step
            Step__c sStep = new Step__c();
            sStep.Deployment__c = deployment.Id;
            insert sStep;

            // Create 1 destination org
            Destination_Org__c destinationOrg = new Destination_Org__c();
            destinationOrg.Deployment__c = deployment.Id;
            destinationOrg.To_Org__c = org3.Id;
            insert destinationOrg;

            // Create 1 deployment job
            Deployment_Job__c deploymentJob = new Deployment_Job__c();
            deploymentJob.Step__c = sStep.Id;
            deploymentJob.Destination_Org__c = destinationOrg.Id;
            insert deploymentJob;
            Test.stopTest();
            controller.waitForDeployment();
        }
    }

    @IsTest static void userStoryValidationRefreshPage() {	
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            TestUtilities testUtils = new TestUtilities();
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            Environment__c env1 = new Environment__c();
            env1.Name = 'Dev1';
            env1.Org_ID__c = 'SFDC_OrgId';
            Environment__c env2 = new Environment__c();
            env2.Name = 'Dev2';
            env2.Org_ID__c = 'SFDC_OrgId2';
            Environment__c env3 = new Environment__c();
            env3.Name = 'Int';
            env3.Org_ID__c = 'SFDC_OrgId3';
            Environment__c env4 = new Environment__c();
            env4.Name = 'UAT';
            env4.Org_ID__c = 'SFDC_OrgId4';
            Environment__c env5 = new Environment__c();
            env5.Name = 'Prod';
            env5.Org_ID__c = 'SFDC_OrgId5';
            insert new List<SObject>{
                    env1, env2, env3, env4, env5
            };

            // Create org credentials record
            Org__c org1 = new Org__c();
            org1.Name = 'OrgDev1';
            org1.Org_Type__c = 'Sandbox';
            org1.SFDC_Org_ID__c = 'SFDC_OrgId';
            org1.Token__c = null;
            org1.Username__c = null;
            org1.Validated_Date__c = System.now();
            org1.Environment__c = env1.Id;
            Org__c org2 = new Org__c();
            org2.Name = 'OrgDev2';
            org2.Org_Type__c = 'Sandbox';
            org2.SFDC_Org_ID__c = 'SFDC_OrgId2';
            org2.Token__c = null;
            org2.Username__c = null;
            org2.Validated_Date__c = System.now();
            org2.Environment__c = env2.Id;
            Org__c org3 = new Org__c();
            org3.Name = 'OrgInt';
            org3.Org_Type__c = 'Sandbox';
            org3.SFDC_Org_ID__c = 'SFDC_OrgId3';
            org3.Token__c = null;
            org3.Username__c = null;
            org3.Validated_Date__c = System.now();
            org3.Environment__c = env3.Id;
            Org__c org4 = new Org__c();
            org4.Name = 'OrgUAT';
            org4.Org_Type__c = 'Sandbox';
            org4.SFDC_Org_ID__c = 'SFDC_OrgId4';
            org4.Token__c = null;
            org4.Username__c = null;
            org4.Validated_Date__c = System.now();
            org4.Environment__c = env4.Id;
            Org__c org5 = new Org__c();
            org5.Name = 'OrgProd';
            org5.Org_Type__c = 'Production';
            org5.SFDC_Org_ID__c = 'SFDC_OrgId5';
            org5.Token__c = null;
            org5.Username__c = null;
            org5.Validated_Date__c = System.now();
            org5.Environment__c = env5.Id;
            insert new List<SObject>{
                    org1, org2, org3, org4, org5
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            Deployment_Flow_Step__c dfs1 = new Deployment_Flow_Step__c();
            dfs1.Source_Environment__c = env1.Id;
            dfs1.Destination_Environment__c = env3.Id;
            dfs1.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs2 = new Deployment_Flow_Step__c();
            dfs2.Source_Environment__c = env2.Id;
            dfs2.Destination_Environment__c = env3.Id;
            dfs2.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs3 = new Deployment_Flow_Step__c();
            dfs3.Source_Environment__c = env3.Id;
            dfs3.Destination_Environment__c = env4.Id;
            dfs3.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            Deployment_Flow_Step__c dfs4 = new Deployment_Flow_Step__c();
            dfs4.Source_Environment__c = env4.Id;
            dfs4.Destination_Environment__c = env5.Id;
            dfs4.Deployment_Flow__c = testUtils.item('Deployment_Flow__c', 0).Id;
            insert new List<SObject>{
                    dfs1, dfs2, dfs3, dfs4
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => env1.Id,
                    'Org_Credential__c' => org1.Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_validation');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            System.assertEquals(1, controller.pageMessagesMap.size());
            System.assertEquals(1, controller.getPageMessageSize());

            controller.prepareValidation();

            Id promotionId = [SELECT Id FROM Promotion__c WHERE Status__c = 'Validation' LIMIT 1].Id;

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.runValidation();
            controller.getIsValidationPollerEnabled();

            // Create deployment record
            Deployment__c deployment = new Deployment__c();
            deployment.Name = 'Deployment';
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.From_Org__c = org1.Id;
            deployment.Schedule__c = '';
            deployment.Status__c = 'Completed';
            deployment.Promotion__c = promotionId;
            insert deployment;
            controller.waitForDeployment();

            // Create 1 copado notification
            Copado_Notification__c notification = new Copado_Notification__c();
            notification.Type__c = 'Promotion';
            notification.status__c = 'Starting';
            notification.isSuccess__c = false;
            notification.isFinished__c = false;
            notification.Name = 'PROGRESS_STATUS_COPADO';
            notification.ParentId__c = promotionId;
            insert notification;
            controller.waitForDeployment();

            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForDeployment();

            pageRef.getParameters().put('jobStarted',notification.Id);
            controller.checkCopadoNotificationStatus();

            notification.isSuccess__c = true;
            update notification;
            controller.waitForDeployment();
            Test.stopTest();
        }
    }

    @IsTest static void userStoryPullRequest() {
        TestUtilities testUtils = new TestUtilities();

        String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] > 0 ? 'copado__' : 'none';
        Blob key = Crypto.generateAesKey(256);

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);

        //TestUtilities.assignLicense(String.valueOf(testUtils.item('User',0).get('Username')), true, true, true, true, true);

        // Create copado license record
        testUtils.insertSObject('Copado_License__c', new Map<String, Object>{
                'Enable_Copado__c' => true,
                'Enable_CCM__c' => true,
                'Enable_CST__c' => true,
                'Enable_CAD__c' => true,
                'Enable_CCH__c' => true,
                'SetupOwnerId' => currentUser.Id
        });

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
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
        });

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create git repo record
            testUtils.insertSObject('Git_Repository__c', new Map<String, Object>{
                    'Name' => 'Git Repo',
                    'URI__c' => 'www.test.com',
                    'Pull_Request_Base_URL__c' => 'www.test.com/[TARGET_BRANCH_NAME]/[SOURCE_BRANCH_NAME]',
                    'Git_Provider__c' => 'Others'
            });

            // Create git snapshot record
            testUtils.insertSObject('Git_Backup__c', new Map<String, Object>{
                    'Name' => 'Git Snapshot',
                    'Branch__c' => 'master',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Last_Backup__c' => Date.today(),
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Main_Branch__c' => 'master',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'dev1'
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'dev2'
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'uat'
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id,
                    'Branch__c' => 'production'
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create snapshot commit record
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Id__c' => '10472f5b2df76332516be948ccb0df426d7e766f',
                    'Status__c' => 'Complete',
                    'Git_Operation__c' => 'Commit Files',
                    'Commit_Message__c' => 'US-0005041: Test run will be tested on this user story'
            });

            // Create user story commit record
            testUtils.insertSObjects('User_Story_Commit__c', 1, new Map<String, Object>{
                    'Name' => 'US-0005041 10472f5',
                    'External_Id__c' => 'a170Y0000033VvrQAE_10472f5b2df76332516be948ccb0df426d7e766f',
                    'Snapshot_Commit__c' => testUtils.item('Git_Org_Commit__c', 0).Id,
                    'User_Story__c' => testUtils.item('User_Story__c', 0).Id
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_pullRequest');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);
            System.assertEquals(1, controller.pageMessagesMap.size());
            System.assertEquals(1, controller.getPageMessageSize());
            controller.preparationPullRequest();
        }
    }

    @IsTest static void userStoryCommit() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Message__c' => 'test message'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_commitChanges');
            pageRef.getParameters().put('ep', 'commit');
            pageRef.getParameters().put('sId', testUtils.item('Git_Backup__c', 0).Id);
            pageRef.getParameters().put('cId', testUtils.item('Git_Org_Commit__c', 0).Id);
            pageRef.getParameters().put('mBranch', 'branchName');
            pageRef.getParameters().put('cType', 'Commit Files');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.commitCallOut();
            Test.stopTest();

            controller.getIsCommitChangesPollerEnabled();
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'GitCommit',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('Git_Backup__c', 0).Id
            });
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(3, controller.pageMessagesMap.size());

            controller.getReturnUrl();
        }
    }

    @IsTest static void userStoryCommitRefreshPage() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Message__c' => 'test message'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_commitChanges');
            pageRef.getParameters().put('ep', 'commit');
            pageRef.getParameters().put('sId', testUtils.item('Git_Backup__c', 0).Id);
            pageRef.getParameters().put('cId', testUtils.item('Git_Org_Commit__c', 0).Id);
            pageRef.getParameters().put('mBranch', 'branchName');
            pageRef.getParameters().put('cType', 'Commit Files');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.commitCallOut();
            Test.stopTest();

            controller.getIsCommitChangesPollerEnabled();
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'GitCommit',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('Git_Backup__c', 0).Id
            });
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForCommitChanges();
            System.assertEquals(2, controller.pageMessagesMap.size());

            pageRef.getParameters().put('&jobStarted', notification.Id);
            controller.checkCopadoNotificationStatus();
            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(3, controller.pageMessagesMap.size());

            controller.getReturnUrl();
        }
    }

    @IsTest static void userStoryCommitOrgValidateDateNull() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Message__c' => 'test message'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_commitChanges');
            pageRef.getParameters().put('ep', 'commit');
            pageRef.getParameters().put('sId', testUtils.item('Git_Backup__c', 0).Id);
            pageRef.getParameters().put('cId', testUtils.item('Git_Org_Commit__c', 0).Id);
            pageRef.getParameters().put('mBranch', 'branchName');
            pageRef.getParameters().put('cType', 'Commit Files');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.commitCallOut();
            System.assertEquals(2, controller.pageMessagesMap.size());
            Test.stopTest();
        }
    }

    @IsTest static void userStoryDestructiveChanges() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Message__c' => 'test message'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_commitChanges');
            pageRef.getParameters().put('ep', 'commit');
            pageRef.getParameters().put('sId', testUtils.item('Git_Backup__c', 0).Id);
            pageRef.getParameters().put('cId', testUtils.item('Git_Org_Commit__c', 0).Id);
            pageRef.getParameters().put('mBranch', 'branchName');
            pageRef.getParameters().put('cType', 'Destructive Changes');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.commitCallOut();
            Test.stopTest();

            controller.getIsCommitChangesPollerEnabled();
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'GitDeletion',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('Git_Backup__c', 0).Id
            });
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(3, controller.pageMessagesMap.size());
        }
    }

    @IsTest static void userStoryApexTestRun() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_apexTestRun');
            pageRef.getParameters().put('testClassList', 'Test_AccountTrigger,Test_ContactTrigger');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.apexTestRunCallOut();
            Test.stopTest();

            controller.getIsApexTestRunPollerEnabled();
            controller.waitForApexTestRun();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'ApexTestRunner',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('User_Story__c', 0).Id
            });
            controller.waitForApexTestRun();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForApexTestRun();

            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForApexTestRun();

            System.assertEquals(3, controller.pageMessagesMap.size());
        }
    }

    @IsTest static void userStoryApexTestRunRefreshPage() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_apexTestRun');
            pageRef.getParameters().put('testClassList', 'Test_AccountTrigger,Test_ContactTrigger');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('User_Story__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.apexTestRunCallOut();
            Test.stopTest();

            controller.getIsApexTestRunPollerEnabled();
            controller.waitForApexTestRun();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'ApexTestRunner',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('User_Story__c', 0).Id
            });
            controller.waitForApexTestRun();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForApexTestRun();
            System.assertEquals(2, controller.pageMessagesMap.size());

            pageRef.getParameters().put('jobStarted', notification.Id);
            controller.checkCopadoNotificationStatus();
            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForApexTestRun();

            System.assertEquals(3, controller.pageMessagesMap.size());
        }
    }

    @IsTest static void snapshotCommit() {
        TestUtilities testUtils = new TestUtilities();

        // Create settings record
        testUtils.insertSObject('Settings__c', new Map<String, Object>{
                'Copado_Site__c' => 'https://copado.secure.force.com',
                'Server_URL__c' => 'https://app-api.copado.com',
                'Namespace__c' => 'none'
        });

        // User record
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            // Create current sprint record
            testUtils.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'org_id__c' => 'SFDC_OrgId'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            testUtils.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    testUtils.item('Environment__c', 0), testUtils.item('Environment__c', 1), testUtils.item('Environment__c', 2), testUtils.item('Environment__c', 3), testUtils.item('Environment__c', 4)
            };

            // Create org credentials record
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 0).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 1).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 2).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 3).Id
            });
            testUtils.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => testUtils.item('Environment__c', 4).Id
            });
            insert new List<SObject>{
                    testUtils.item('Org__c', 0), testUtils.item('Org__c', 1), testUtils.item('Org__c', 2), testUtils.item('Org__c', 3), testUtils.item('Org__c', 4)
            };

            // Create deployment flow record
            testUtils.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true
            });

            // Create deployment flow steps record
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            testUtils.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => testUtils.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => testUtils.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });
            insert new List<SObject>{
                    testUtils.item('Deployment_Flow_Step__c', 0), testUtils.item('Deployment_Flow_Step__c', 1), testUtils.item('Deployment_Flow_Step__c', 2), testUtils.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            testUtils.insertSObject('Project__c', new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => testUtils.item('Deployment_Flow__c', 0).Id
            });

            // Create 3 user story to fill sobjectlist
            testUtils.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => testUtils.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => testUtils.item('Project__c', 0).Id,
                    'Environment__c' => testUtils.item('Environment__c', 0).Id,
                    'Org_Credential__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git repository
            testUtils.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create 1 git backup
            testUtils.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => testUtils.item('Git_Repository__c', 0).Id,
                    'Org__c' => testUtils.item('Org__c', 0).Id
            });

            // Create 1 git org commit
            testUtils.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                    'Git_Backup__c' => testUtils.item('Git_Backup__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Status__c' => 'Pending',
                    'Org__c' => testUtils.item('Org__c', 0).Id,
                    'Commit_Message__c' => 'test message'
            });

            PageReference pageRef = Page.UserStoryPageWaitingFor;
            pageRef.getParameters().put('type', 'co_commitChanges');
            pageRef.getParameters().put('ep', 'commit');
            pageRef.getParameters().put('sId', testUtils.item('Git_Backup__c', 0).Id);
            pageRef.getParameters().put('cId', testUtils.item('Git_Org_Commit__c', 0).Id);
            pageRef.getParameters().put('mBranch', 'branchName');
            pageRef.getParameters().put('cType', 'Commit Files');
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stndController = new ApexPages.StandardController(testUtils.item('Git_Backup__c', 0));
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.commitCallOut();
            Test.stopTest();

            controller.getIsCommitChangesPollerEnabled();
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            // Create 1 copado notification
            testUtils.insertSObjects('Copado_Notification__c', 1, new Map<String, Object>{
                    'Type__c' => 'GitCommit',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => testUtils.item('Git_Backup__c', 0).Id
            });
            controller.waitForCommitChanges();

            System.assertEquals(1, controller.pageMessagesMap.size());

            Copado_Notification__c notification = (Copado_Notification__c) testUtils.item('Copado_Notification__c', 0);
            notification.isFinished__c = true;
            notification.isSuccess__c = false;
            notification.status__c = 'done';
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(2, controller.pageMessagesMap.size());

            notification.isSuccess__c = true;
            update notification;
            controller.waitForCommitChanges();

            System.assertEquals(3, controller.pageMessagesMap.size());

            controller.getReturnUrl();
        }
    }

    /**
     * Test Commit Main Branch assignation. 
     * In this case: 
     *    - User story have populated "Base Branch", in this case, this base branch wins. 
     */
    @IsTest
    static void tesGetMainBranchUserStoryWthBranch() {
        User standardUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            User_Story__c currentUserStory = Database.query(USER_STORY_QUERY);
            currentUserStory.Base_Branch__c = 'devBranch';
            update currentUserStory;

            ApexPages.StandardController stndController = new ApexPages.StandardController(currentUserStory);
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, FAKERESPONSE);
            String mainBranch = controller.getMainBranch(currentUserStory);
            System.assertEquals('devBranch', mainBranch, 'Main Branch is not User Story Base Branch');
            Test.stopTest();
        }
    }

     /**
     * Test Commit Main Branch assignation. 
     * In this case: 
     *    - User story have populated a Release, an that release have populated "Base Branch". Release Base Branch Wins.
     */
    @IsTest
    static void tesGetMainBranchReleaseWithBranch() {
        User standardUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            Release__c currentRelease = [SELECT Id, Name, Base_Branch__c FROM Release__c WHERE Name = 'MyNextRelease 0' LIMIT 1];
            currentRelease.Base_Branch__c = 'releaseBranch';
            User_Story__c userStoryToUpdate = [SELECT Id, Name, Release__c FROM User_Story__c WHERE User_Story_Title__c = 'My new User Story' LIMIT 1];
            userStoryToUpdate.Release__c = currentRelease.Id;
            List<SObject> updateTestRecords = new List<SObject>{currentRelease, userStoryToUpdate};
            update updateTestRecords;

            User_Story__c currentUserStory = Database.query(USER_STORY_QUERY);

            ApexPages.StandardController stndController = new ApexPages.StandardController(currentUserStory);
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, FAKERESPONSE);
            String mainBranch = controller.getMainBranch(currentUserStory);
            System.assertEquals('releaseBranch', mainBranch, 'Main Branch is not Release Base Branch');
            Test.stopTest();
        }
    }

     /**
     * Test Commit Main Branch assignation. 
     * In this case: 
     *    - User story have populated Pipeline "Base Branch" Different from master.
     */
    @IsTest
    static void tesGetMainBranchPipelineBranchNotMaster() {
        User standardUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            Deployment_Flow__c currentPipeline = [SELECT Id, Name, Main_Branch__c FROM Deployment_Flow__c WHERE Name = 'MyPipeline 0' LIMIT 1];
            currentPipeline.Main_Branch__c = 'pipelineBranch';
            update currentPipeline;
            User_Story__c currentUserStory = Database.query(USER_STORY_QUERY);

            ApexPages.StandardController stndController = new ApexPages.StandardController(currentUserStory);
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, FAKERESPONSE);
            String mainBranch = controller.getMainBranch(currentUserStory);
            System.assertEquals('pipelineBranch', mainBranch, 'Main Branch is not Pipeline Base Branch');
            Test.stopTest();
        }
    }

     /**
     * Test Commit Main Branch assignation. 
     * In this case: 
     *    - User story have NOT populated Pipeline "Base Branch". So main branch is master.
     */
    @IsTest
    static void tesGetMainBranchPipelineBranchIsMaster() {
        User standardUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            User_Story__c currentUserStory = Database.query(USER_STORY_QUERY);

            ApexPages.StandardController stndController = new ApexPages.StandardController(currentUserStory);
            JobWaitingExtension controller = new JobWaitingExtension(stndController);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, FAKERESPONSE);
            String mainBranch = controller.getMainBranch(currentUserStory);
            System.assertEquals('master', mainBranch, 'Main Branch is not master');
            Test.stopTest();
        }
    }
}