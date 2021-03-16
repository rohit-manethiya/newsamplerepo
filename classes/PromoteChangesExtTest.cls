@IsTest
private with sharing class PromoteChangesExtTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        }
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, SObjectType.Settings__c);
        User standardUser = getStandardUser();
        TestUtilities.assignLicense(standardUser.Username, true, false, true);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, true);
        CMTestMethodUtilities.enableSelenium();
    }

    @IsTest
    private static void fullTest() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

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

            User_Story_Metadata__c usm1 = new User_Story_Metadata__c(
                Name = 'US-0006186 CustomObject.Account',
                Metadata_API_Name__c = 'CustomObject.Account',
                User_Story__c = userStories[0].Id,
                Status__c = 'Potential Conflict'
            );
            User_Story_Metadata__c usm2 = new User_Story_Metadata__c(
                Name = 'US-0000777 CustomObject.Account',
                Metadata_API_Name__c = 'CustomObject.Account',
                User_Story__c = userStories[1].Id,
                Status__c = 'Potential Conflict'
            );
            insert new List<User_Story_Metadata__c>{ usm1, usm2 };

            Static_Code_Analysis_Result__c scar = new Static_Code_Analysis_Result__c(User_Story__c = userStories[0].Id);
            insert scar;
            Static_Code_Analysis_Violation__c vio = new Static_Code_Analysis_Violation__c(Priority__c = 1, Static_Code_Analysis_Result__c = scar.Id);
            insert vio;

            // Manual tasks
            List<Deployment_Task__c> deploymentTasks = new List<Deployment_Task__c>();
            deploymentTasks.add(
                new Deployment_Task__c(
                    Name = 'Task1',
                    Perform_in_Source_Org__c = true,
                    Perform_in_Destination_Orgs__c = false,
                    Task_Description__c = 'Do this...',
                    User_Story__c = userStories.get(0).Id
                )
            );
            deploymentTasks.add(
                new Deployment_Task__c(
                    Name = 'Task2',
                    Perform_in_Source_Org__c = false,
                    Perform_in_Destination_Orgs__c = true,
                    Task_Description__c = 'Do that...',
                    User_Story__c = userStories.get(1).Id
                )
            );
            insert deploymentTasks;

            // Metadata selections via the grid
            List<Attachment> attachments = new List<Attachment>();
            Attachment att1 = new Attachment(
                ParentId = userStories.get(0).Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]')
            );
            Attachment att2 = new Attachment(
                ParentId = userStories.get(1).Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]')
            );
            attachments.add(att1);
            attachments.add(att2);
            insert attachments;

            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Project__c = testProject.Id;
            testPromotion.Source_Environment__c = env1.Id;
            //testPromotion.Source_Org_Credential__c = testOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = false;
            insert testPromotion;
            testPromotion = [
                SELECT
                    Id,
                    Release__c,
                    Project__c,
                    Send_Deployment_Complete_email__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c
                FROM Promotion__c
                WHERE Id = :testPromotion.Id
            ];

            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.listUserStories();
            System.assertEquals(2, ext.userStories.size());
            //System.assertEquals(0, ext.getUserStoryMetadatas().size());
            PromoteChangesExtension.getisChatterEnabled();

            ext.addStoriesToPromotion();
            System.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();

            //Reload Constructor
            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.listUserStories();
            ext.getSeleniumTestGroups();
            ext.calculateSCAScores();
            System.assertEquals(null, ext.worstSCAscore);
            System.assertEquals(5, ext.averageSCAscore);
            ext.checkBackPromotions();
            ext.isFirst = true;

            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            System.assertEquals(0, ext.promotedIdsSet.size());

            ext.listUserStories();
            // now add all again
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(2, ext.promotedIdsSet.size());

            ext.reloadPromotion();
            ext.openResolveConflictsPage();
            ext.resetDom();
            ext.enableMetadataTab();
            ext.enableSeleniumTab();
            Test.stopTest();
        }
    }

    @IsTest
    private static void fullTestWithRelease() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow__c);
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);

            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.SObjectType.Project__c);

            Release__c testRelease = CMTestMethodUtilities.createRelease('My Release');
            testRelease.Project__c = testProject.Id;
            Utilities.Secure_DML(testRelease, Utilities.DML_Action.INS, schema.SObjectType.Release__c);

            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory3'));
            userStories.get(0).Project__c = testProject.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;
            userStories.get(0).Release__c = testRelease.Id;

            userStories.get(1).Project__c = testProject.Id;
            userStories.get(1).Environment__c = env1.Id;
            userStories.get(1).Promote_Change__c = true;
            userStories.get(1).Release__c = testRelease.Id;
            Utilities.Secure_DML(userStories, Utilities.DML_Action.INS, schema.SObjectType.User_Story__c);
            // Manual tasks
            List<Deployment_Task__c> deploymentTasks = new List<Deployment_Task__c>();
            deploymentTasks.add(
                new Deployment_Task__c(
                    Name = 'Task1',
                    Perform_in_Source_Org__c = true,
                    Perform_in_Destination_Orgs__c = false,
                    Task_Description__c = 'Do this...',
                    User_Story__c = userStories.get(0).Id
                )
            );
            deploymentTasks.add(
                new Deployment_Task__c(
                    Name = 'Task2',
                    Perform_in_Source_Org__c = false,
                    Perform_in_Destination_Orgs__c = true,
                    Task_Description__c = 'Do that...',
                    User_Story__c = userStories.get(1).Id
                )
            );
            Utilities.Secure_DML(deploymentTasks, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Task__c);

            // Metadata selections via the grid
            List<Attachment> attachments = new List<Attachment>();
            Attachment att1 = new Attachment(
                ParentId = userStories.get(0).Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]')
            );
            Attachment att2 = new Attachment(
                ParentId = userStories.get(1).Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]')
            );
            attachments.add(att1);
            attachments.add(att2);
            Utilities.Secure_DML(attachments, Utilities.DML_Action.INS, schema.SObjectType.Attachment);

            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Release__c = testRelease.Id;
            testPromotion.Source_Environment__c = env1.Id;
            //testPromotion.Source_Org_Credential__c = testOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = false;
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
            testPromotion = [
                SELECT
                    Id,
                    Release__c,
                    Project__c,
                    Send_Deployment_Complete_email__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c
                FROM Promotion__c
                WHERE Id = :testPromotion.Id
            ];

            // Success Active CCM Flow
            PageReference pref = Page.PromoteChanges;
            pref.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref);
            PromoteChangesExtension ext2 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext2.listUserStories();
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext2.validateDeployment());

            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.listUserStories();
            //ext.listUserStories();
            System.assertEquals(2, ext.userStories.size());

            ext.addStoriesToPromotion();
            System.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();

            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            System.assertEquals(0, ext.promotedIdsSet.size());

            // now add all again
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(2, ext.promotedIdsSet.size());
            Test.stopTest();
        }
    }

    @IsTest
    private static void fullTestWarnings() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
            Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);

            Git_Repository__c g = new Git_Repository__c(Name = 'g');
            Utilities.Secure_DML(g, Utilities.DML_Action.INS, schema.SObjectType.Git_Repository__c);
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, g.Id, 'master');
            insert new List<Deployment_Flow__c>{ flow, flowCBM };
            System.assert(flowCBM.Id != null);

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
            dfs4.Branch__c = 'env1';
            insert new List<Deployment_Flow_Step__c>{ dfs, dfs4 };
            System.assert(dfs4.Id != null);

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.SObjectType.Project__c);
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);

            // Success Valid CBM Flow
            testProject.Deployment_Flow__c = flowCBM.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.SObjectType.Project__c);
            flowCBM.Active__c = true;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            PageReference pref2 = Page.PromoteChanges;
            pref2.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref2);
            PromoteChangesExtension ext2 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext2.listUserStories();
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext2.validateDeployment());

            // Warning Invalid CBM Flow - Main Branch = null
            flowCBM.Main_Branch__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            PageReference pref3 = Page.PromoteChanges;
            pref3.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref3);
            PromoteChangesExtension ext3 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext3.listUserStories();
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext3.validateDeployment());

            // Warning Invalid CBM Flow - Git Repository = null
            flowCBM.Main_Branch__c = 'master';
            flowCBM.Git_Repository__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            PageReference pref4 = Page.PromoteChanges;
            pref4.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref4);
            PromoteChangesExtension ext4 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext4.listUserStories();
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext4.validateDeployment());

            // Warning Inactive CCM Flow
            flow.Active__c = false;
            Utilities.Secure_DML(flow, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.SObjectType.Project__c);
            PageReference pref5 = Page.PromoteChanges;
            pref5.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref5);
            PromoteChangesExtension ext5 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext5.listUserStories();
            System.assert(testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assert(!ext5.validateDeployment());
            Test.stopTest();
        }
    }

    @IsTest
    private static void fullTestWarningsCCM() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
            Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);

            Git_Repository__c g = new Git_Repository__c(Name = 'g');
            Utilities.Secure_DML(g, Utilities.DML_Action.INS, schema.SObjectType.Git_Repository__c);
            Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', false, g.Id, 'master');
            insert new List<Deployment_Flow__c>{ flow, flowCBM };
            System.assert(flowCBM.Id != null);

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
            Environment__c env3 = new Environment__c(Name = 'UAT Environment', Type__c = 'Sandbox');
            insert new List<Environment__c>{ env1, env2, env3 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
            dfs2.Branch__c = 'env1';
            insert new List<Deployment_Flow_Step__c>{ dfs, dfs2 };

            flowCBM.Active__c = true;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.SObjectType.Project__c);
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);

            // Success Valid CBM Flow
            PageReference pref = Page.PromoteChanges;
            pref.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref);
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext.validateDeployment());

            // Copado License: Warning Invalid CBM Flow - Main Branch = null
            flowCBM.Main_Branch__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            PageReference pref2 = Page.PromoteChanges;
            pref2.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref2);
            PromoteChangesExtension ext2 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext2.validateDeployment());

            // Copado License: Warning Invalid CBM Flow - Git Repository = null
            flowCBM.Git_Repository__c = null;
            flowCBM.Main_Branch__c = 'master';
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            PageReference pref3 = Page.PromoteChanges;
            pref3.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref3);
            PromoteChangesExtension ext3 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext3.validateDeployment());

            // Warning Inactive CCM Flow
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.SObjectType.Project__c);
            PageReference pref4 = Page.PromoteChanges;
            pref4.getParameters().put('id', testPromotion.Id);
            Test.setCurrentPage(pref4);
            PromoteChangesExtension ext4 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assert(!ext4.validateDeployment());
            Test.stopTest();
        }
    }

    @IsTest
    private static void testWithSelenium() {
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c = 'http://drive.me');
        Utilities.Secure_DML(s, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Settings__c);
        Feature__c f = new Feature__c(Name = 'Selenium Testing', Enabled__c = true, Quantity__c = 10);
        Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);

        System.runAs(getStandardUser()) {
            // Copado
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            // Selenium
            Selenium_Test_Group__c g1 = new Selenium_Test_Group__c(
                Name = 'source regression group',
                Selenium_Settings__c = s.Id,
                Type__c = 'Regression Test',
                Environment__c = env1.Id
            );
            Selenium_Test_Group__c g2 = new Selenium_Test_Group__c(
                Name = 'destination regression group',
                Selenium_Settings__c = s.Id,
                Type__c = 'Regression Test',
                Environment__c = env2.Id
            );
            Selenium_Test_Group__c g3 = new Selenium_Test_Group__c(
                Name = 'source user story group',
                Selenium_Settings__c = s.Id,
                Type__c = 'User Story Test',
                Environment__c = env1.Id
            );
            Selenium_Test_Group__c g4 = new Selenium_Test_Group__c(
                Name = 'destination user story group',
                Selenium_Settings__c = s.Id,
                Type__c = 'User Story Test',
                Environment__c = env2.Id
            );
            insert new List<Selenium_Test_Group__c>{ g1, g2, g3, g4 };

            Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(Name = 'test suite1');
            Utilities.Secure_DML(ts1, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Test_Suite__c);

            Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(
                Selenium_Test_Group__c = g1.Id,
                Org_Credential__c = testOrg1.Id
            );
            Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(
                Selenium_Test_Group__c = g2.Id,
                Org_Credential__c = testOrg2.Id
            );
            Selenium_Group_Org_Credential__c goc3 = new Selenium_Group_Org_Credential__c(
                Selenium_Test_Group__c = g3.Id,
                Org_Credential__c = testOrg1.Id
            );
            Selenium_Group_Org_Credential__c goc4 = new Selenium_Group_Org_Credential__c(
                Selenium_Test_Group__c = g4.Id,
                Org_Credential__c = testOrg2.Id
            );
            SeleniumTestRunTriggerHelper.inTrigger = false;
            insert new List<Selenium_Group_Org_Credential__c>{ goc1, goc2, goc3, goc4 };

            Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g1.Id, Selenium_Test_Suite__c = ts1.Id);
            Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g2.Id, Selenium_Test_Suite__c = ts1.Id);
            Selenium_Group_Test_Suite__c gts3 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g3.Id, Selenium_Test_Suite__c = ts1.Id);
            Selenium_Group_Test_Suite__c gts4 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g4.Id, Selenium_Test_Suite__c = ts1.Id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            insert new List<Selenium_Group_Test_Suite__c>{ gts1, gts2, gts3, gts4 };
            System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g1.Id]);
            System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g2.Id]);
            System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g3.Id]);
            System.assertEquals(1, [SELECT COUNT() FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :g4.Id]);

            // CCM

            //TestUtilities.enableLicenses(10, 10, 10);
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow__c);
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);

            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.SObjectType.Project__c);

            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
            userStories.get(0).Project__c = testProject.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;

            userStories.get(1).Project__c = testProject.Id;
            userStories.get(1).Environment__c = env1.Id;
            userStories.get(1).Promote_Change__c = true;
            Utilities.Secure_DML(userStories, Utilities.DML_Action.INS, schema.SObjectType.User_Story__c);

            List<User_Story_Selenium_Test__c> usST = new List<User_Story_Selenium_Test__c>();
            usST.add(
                new User_Story_Selenium_Test__c(
                    Name = 'us1 Source Env Test Group',
                    User_Story__c = userStories.get(0).Id,
                    Selenium_Test_Group__c = g3.Id
                )
            );
            usST.add(
                new User_Story_Selenium_Test__c(
                    Name = 'us2 Destination Env Test Group',
                    User_Story__c = userStories.get(1).Id,
                    Selenium_Test_Group__c = g4.Id
                )
            );
            Utilities.Secure_DML(usST, Utilities.DML_Action.INS, schema.SObjectType.User_Story_Selenium_Test__c);

            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Project__c = testProject.Id;
            testPromotion.Source_Environment__c = env1.Id;
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
            testPromotion = [
                SELECT
                    Id,
                    Release__c,
                    Project__c,
                    Send_Deployment_Complete_email__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c
                FROM Promotion__c
                WHERE Id = :testPromotion.Id
            ];

            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.listUserStories();
            System.assertEquals(2, ext.userStories.size());

            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(2, ext.promotedIdsSet.size());
            ext.getSeleniumTestGroups();

            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            System.assertEquals(0, ext.promotedIdsSet.size());
            ext.getSeleniumTestGroups();
            System.Test.setCurrentPage(new PageReference('/'));
            System.assertEquals(false, ext.getIsSeleniumRunning());
            String jmmkeys = ext.jobsManagerMatchingKeys;
            String exc = ext.excludeds;
            ext.refreshSeleniumTestGroups();

            ext.runTestsSourceRegression();
            ext.runTestsSourceUserStory();
            ext.runTestsDestinationRegression();
            ext.runTestsDestinationUserStory();
            Test.stopTest();
        }
    }

    @IsTest
    private static void testBackPromotion() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        System.runAs(getStandardUser()) {
            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            insert flowCBM;
            PromoteChangesExtension.getEnvsAndBranchesOfDeploymentFlow(flowCBM.Id);
            System.assert(flowCBM.Id != null);

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c envDev2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
            Environment__c envInt = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            insert new List<Environment__c>{ envDev1, envDev2, envInt };

            Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
            Org__c orgDev2 = CMTestMethodUtilities.createOrg('MyOrgDev2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), envDev2.Id);
            Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
            insert new List<Org__c>{ orgDev1, orgDev2, orgInt };

            Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
            Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev2.Id, Branch__c = 'dev2');
            Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
            insert new List<Git_Backup__c>{ gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt };

            Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
            stepDev1ToInt.Branch__c = 'dev1';
            Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
            stepDev2ToInt.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ stepDev1ToInt, stepDev2ToInt };

            Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(
                Git_Backup__c = gitSnapshotDev1.Id,
                Org__c = orgDev1.Id,
                Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974',
                Commit_Date__c = Date.today().addDays(-3),
                Commit_Message__c = 'test 1',
                Status__c = 'Complete'
            );
            insert snapshotCommit1;

            // Case 1. Dev1 has 1 user story with one 'Complete' commit. UserStory1 appears as 'Ahead' in stepDev1ToInt
            User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
            userStory1.Org_Credential__c = orgDev1.Id;
            userStory1.Project__c = testProject.Id;
            insert userStory1;

            User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommit1.Id);
            insert userStoryCommit1;

            Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
            testPromotion1.Status__c = 'Completed';
            insert testPromotion1;
            Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
            insert promotedUserStory1;
            userStory1.Org_Credential__c = orgInt.Id;
            userStory1.Environment__c = envInt.Id;
            update userStory1;

            Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev2.Id);

            insert testBackPromotion1;

            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testBackPromotion1));
            ext.listUserStories();
            System.assertEquals(1, ext.userStories.size());
            ext.addStoriesToPromotion();
            System.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(1, ext.promotedIdsSet.size());
            Test.stopTest();
        }
    }

    @IsTest
    private static void testUSMetadatas() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;

            User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory ');
            userStory.Project__c = testProject.Id;
            userStory.Environment__c = env1.Id;
            userStory.Promote_Change__c = true;
            insert userStory;

            List<User_Story_Metadata__c> userStoryMetadatas = new List<User_Story_Metadata__c>();
            for (Integer i = 0; i < 5200; i++) {
                User_Story_Metadata__c usMetadata = new User_Story_Metadata__c(
                    Name = 'US-' + i + ' CustomObject.Account',
                    Metadata_API_Name__c = 'CustomObject.Account',
                    User_Story__c = userStory.Id,
                    Status__c = 'Potential Conflict',
                    Last_Commit_Date__c = System.now().addMinutes(i)
                );
                userStoryMetadatas.add(usMetadata);
            }
            insert userStoryMetadatas;

            userStoryMetadatas = new List<User_Story_Metadata__c>();
            for (Integer i = 0; i < 4000; i++) {
                User_Story_Metadata__c usMetadata = new User_Story_Metadata__c(
                    Name = 'US-' + i + ' CustomObject.Account',
                    Metadata_API_Name__c = 'CustomObject.Account',
                    User_Story__c = userStory.Id,
                    Status__c = 'Potential Conflict',
                    Last_Commit_Date__c = System.now().addMinutes(i)
                );
                userStoryMetadatas.add(usMetadata);
            }
            insert userStoryMetadatas;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            insert testPromotion;

            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.listUserStories();
            System.assertEquals(1, ext.userStories.size());
            //System.assertEquals(0, ext.getUserStoryMetadatas().size());

            ext.createNewUs();

            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertNotEquals(0, pageMessages.size());

            // Check that the error message you are expecting is in pageMessages
            Boolean messageFound = false;
            for (ApexPages.Message message : pageMessages) {
                if (message.getDetail() == Label.No_Outdated_User_Story_Metadata && message.getSeverity() == ApexPages.Severity.WARNING) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);

            ext.userStories[0].selected = true;
            ext.addStoriesToPromotion();

            //Reload Constructor
            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            //Integer metadatasSize = ext.getUserStoryMetadatas().size();
            //System.assert(true, metadatasSize < 9201);
            Test.stopTest();
        }
    }

    @IsTest
    private static void testBaseBranchValidation() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            insert TestUtilities.getTestSettings();
            TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
            Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
            insert feature;

            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            flow.Exclude_From_Auto_Resolve__c = 'ApexClass';
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            Release__c release = new Release__c(Name = 'Release 1');
            insert release;

            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;

            User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('MyStory 1');
            userStory1.Project__c = testProject.Id;
            userStory1.Environment__c = env1.Id;
            userStory1.Promote_Change__c = true;
            User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('MyStory 2');
            userStory2.Project__c = testProject.Id;
            userStory2.Environment__c = env1.Id;
            userStory2.Promote_Change__c = true;
            insert new List<User_Story__c>{ userStory1, userStory2 };

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            testPromotion.Release__c = release.Id;
            insert testPromotion;
            List<Promotion__c> promotions = new List<Promotion__c>();
            promotions = [SELECT Id, Project__c, Source_Environment__c, Exclude_From_Auto_Resolve__c FROM Promotion__c WHERE Id = :testPromotion.Id];
            System.assert(promotions.size() > 0);
            System.assertEquals('ApexClass', promotions[0].Exclude_From_Auto_Resolve__c);

            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
            Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotion.Id);
            insert new List<Promoted_User_Story__c>{ pus1, pus2 };

            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assertEquals(2, ext.promotedWrappedStories.size());
            System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT));

            release.Base_Branch__c = 'int';
            update release;

            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assertEquals(2, ext.promotedWrappedStories.size());
            System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT));

            userStory1.Base_Branch__c = 'patch5';
            update userStory1;

            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assertEquals(2, ext.promotedWrappedStories.size());
            System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStory1.Name));

            userStory2.Base_Branch__c = 'patch7';
            update userStory2;

            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assertEquals(2, ext.promotedWrappedStories.size());
            System.assertEquals(
                false,
                testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStory1.Name + ', ' + userStory2.Name)
            );

            Test.stopTest();
        }
    }

    @IsTest
    private static void testOutdatedUserStories() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;

            User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory ');
            userStory.Project__c = testProject.Id;
            userStory.Environment__c = env1.Id;
            userStory.Promote_Change__c = true;
            User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('MyStory ');
            userStory1.Project__c = testProject.Id;
            userStory1.Environment__c = env1.Id;
            userStory1.Promote_Change__c = true;
            insert new List<User_Story__c>{ userStory, userStory1 };

            List<User_Story_Metadata__c> userStoryMetadatas = new List<User_Story_Metadata__c>();
            for (Integer i = 0; i < 5; i++) {
                User_Story_Metadata__c usMetadata = new User_Story_Metadata__c(
                    Name = 'US-' + i + ' CustomObject.Account',
                    Metadata_API_Name__c = 'CustomObject.Account',
                    User_Story__c = userStory1.Id,
                    Status__c = 'Potential Conflict',
                    Last_Commit_Date__c = System.now().addMinutes(i)
                );
                userStoryMetadatas.add(usMetadata);
            }
            userStoryMetadatas[3].Last_Commit_Date__c = System.now().addDays(3);
            userStoryMetadatas[3].User_Story__c = userStory.Id;
            insert userStoryMetadatas;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            testPromotion.Order_by__c = 'name';
            insert testPromotion;

            Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = testPromotion.Id);
            insert new List<Promoted_User_Story__c>{ pus, pus1 };

            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            ext.resetDom();
            ext.getPromotedUserStories();
            ext.getUserStoryMetadatas();

            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertNotEquals(0, pageMessages.size());

            // Check that the error message you are expecting is in pageMessages
            Boolean messageFound = false;
            for (ApexPages.Message message : pageMessages) {
                if (message.getSeverity() == ApexPages.Severity.WARNING) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);

            ext.createNewUs();
            Test.stopTest();
        }
    }

    @IsTest
    private static void testEmptyPipelineOnProject() {
        System.runAs(getStandardUser()) {
            Test.startTest();
            Project__c project = CMTestMethodUtilities.createProject('My Project');

            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert new List<Environment__c>{ env1, env2 };

            Org__c org1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c org2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert new List<Org__c>{ org1, org2 };

            Deployment_Flow__c pipeline = CMTestMethodUtilities.createCCMFlow('Standard Pipeline', true);
            insert pipeline;
            Deployment_Flow_Step__c flowStep = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, pipeline.Id);
            insert flowStep;

            project.Deployment_Flow__c = pipeline.Id;
            insert project;

            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.get(0).Project__c = project.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;
            insert userStories;

            User_Story_Metadata__c userStoryMetadata = new User_Story_Metadata__c(
                Name = 'US-0006186 CustomObject.Account',
                Metadata_API_Name__c = 'CustomObject.Account',
                User_Story__c = userStories[0].Id,
                Status__c = 'Potential Conflict'
            );
            insert new List<User_Story_Metadata__c>{ userStoryMetadata };

            // Metadata selections via the grid
            List<Attachment> attachments = new List<Attachment>();
            Attachment att1 = new Attachment(
                ParentId = userStories.get(0).Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]')
            );
            attachments.add(att1);
            insert attachments;

            Promotion__c promotion = new Promotion__c();
            promotion.Project__c = project.Id;
            promotion.Source_Environment__c = env1.Id;
            promotion.Source_Org_Credential__c = org1.Id;
            promotion.Send_Deployment_Complete_email__c = false;
            insert promotion;
            promotion = [
                SELECT
                    Release__c,
                    Project__c,
                    Send_Deployment_Complete_email__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c
                FROM Promotion__c
                WHERE Id = :promotion.Id
            ];

            project.Deployment_Flow__c = null;
            update project;

            PromoteChangesExtension controller = new PromoteChangesExtension(new ApexPages.StandardController(promotion));
            Boolean success = controller.validateDeployment();
            System.assert(!success, 'A promotion without a pipeline cannot be successfully validated.');
            Test.stopTest();
        }
    }

    private static User getStandardUser() {
        User user = [SELECT Username FROM User WHERE Username = 'test_user@myorg.com'];
        return user;
    }
}