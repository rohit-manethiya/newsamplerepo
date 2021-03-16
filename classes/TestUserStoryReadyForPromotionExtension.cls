@IsTest
private with sharing class TestUserStoryReadyForPromotionExtension {

    static TestUtilities tu = new TestUtilities();

    @TestSetup
    static void setupData() {
        TestUtilities.insertUser('ccd-ready-for-promotion-admin@ccd.com', 'System Administrator');
        TestUtilities.insertUser('ccd-ready-for-promotion-std@ccd.com', 'Standard User');

        User adminUser = [SELECT Id, Username FROM User WHERE Username = 'ccd-ready-for-promotion-admin@ccd.com'];
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'ccd-ready-for-promotion-std@ccd.com'];

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 100);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ps.Id);

        System.runAs(adminUser) {

            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
            TestUtilities.createTestDataForStandardPipeline(adminUser);

        }

    }

    @IsTest static void testUserStoryReadyForPromotionWithOnloadWarningEnv() {
        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test No Connection behavior';
        insert testStory;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        System.assert(usrfpe.pageMessagesMap.size() == 1);
        System.assertEquals(Label.USER_STORY_NEXT_ENV_NOT_FOUND, (String) usrfpe.pageMessagesMap.get(UserStoryReadyForPromoteExtension.ERROR)[0]);

    }

    @IsTest static void testUserStoryReadyForPromotionWithOnloadWarningConn() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            System.debug('dfs===> '+dfs);
        }
        Org__c devOrg = [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'Dev1 env' LIMIT 1];
        System.debug('devOrg====> '+devOrg);
        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test No Connection behavior';
        testStory.Org_Credential__c = devOrg.Id;
        testStory.Environment__c = devOrg.Environment__c;
        testStory.Project__c = testProject.Id;
        insert testStory;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        System.assert(usrfpe.pageMessagesMap.size() == 1);
        System.assertEquals(Label.USER_STORY_CONNECTION_BEHAVIOR_NOT_FOUND, (String) usrfpe.pageMessagesMap.get(UserStoryReadyForPromoteExtension.ERROR)[0]);

    }


    @IsTest static void testUserStoryReadyForPromotionWithOnloadWarningAtt() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        System.debug('cbItem===> '+cbItem);
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Connection_Behavior_Override__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            dfs.Connection_Behavior_Override__c = cbItem.Id;
        }
        update depFlows;
        Org__c devOrg = [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'Dev1 env' LIMIT 1];


        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test with Connection behavior';
        testStory.Org_Credential__c = devOrg.Id;
        testStory.Environment__c = devOrg.Environment__c;
        testStory.Project__c = testProject.Id;
        insert testStory;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        System.assert(usrfpe.pageMessagesMap.size() == 1);
        System.assertEquals(Label.NoCommitOnUs, (String) usrfpe.pageMessagesMap.get(UserStoryReadyForPromoteExtension.ERROR)[0]);
    }

    @IsTest static void testUserStoryReadyForPromotionWithOnloadWarningAlreadyPromote() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        System.debug('cbItem===> '+cbItem);
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Connection_Behavior_Override__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            dfs.Connection_Behavior_Override__c = cbItem.Id;
        }
        update depFlows;
        Org__c devOrg = [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'Dev1 env' LIMIT 1];


        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test with Connection behavior';
        testStory.Org_Credential__c = devOrg.Id;
        testStory.Environment__c = devOrg.Environment__c;
        testStory.Project__c = testProject.Id;
        testStory.Promote_Change__c = true;
        insert testStory;

        Attachment gitMetadataAtt = new Attachment(
                Name = 'Git MetaData',
                ParentId = testStory.Id,
                Body = Blob.valueOf('[{"t":"StaticResource","n":"deployment","b":"umit uckan","d":"2019-10-14","cb":"umit uckan","cd":"2019-10-14","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018ojWSEAY"},{"t":"ApexClass","n":"Test_TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"},{"t":"ApexClass","n":"TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"}]')
        );
        insert gitMetadataAtt;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        System.assert(usrfpe.pageMessagesMap.size() == 1);
        System.assertEquals(Label.USER_STORY_ALREADY_MARKED_FOR_PROMOTION, (String) usrfpe.pageMessagesMap.get(UserStoryReadyForPromoteExtension.WARNING)[0]);
        //usrfpe.populatePageMessagesMap();
        usrfpe.goBackToUserStory();
    }

    @IsTest static void testUserStoryReadyForPromotionWithoutWarning_EnvParameter() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        System.debug('cbItem===> '+cbItem);
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Connection_Behavior_Override__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            dfs.Connection_Behavior_Override__c = cbItem.Id;
        }
        update depFlows;
        Org__c devOrg = [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'Dev1 env' LIMIT 1];


        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test with Connection behavior';
        testStory.Org_Credential__c = devOrg.Id;
        testStory.Environment__c = devOrg.Environment__c;
        testStory.Project__c = testProject.Id;
        insert testStory;

        Attachment gitMetadataAtt = new Attachment(
                Name = 'Git MetaData',
                ParentId = testStory.Id,
                Body = Blob.valueOf('[{"t":"StaticResource","n":"deployment","b":"umit uckan","d":"2019-10-14","cb":"umit uckan","cd":"2019-10-14","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018ojWSEAY"},{"t":"ApexClass","n":"Test_TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"},{"t":"ApexClass","n":"TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"}]')
        );
        insert gitMetadataAtt;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        pr.getParameters().put('environment', testStory.Environment__c);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
    }

    @IsTest static void testUserStoryReadyForPromotionWithoutWarning() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        System.debug('cbItem===> '+cbItem);
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Connection_Behavior_Override__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            dfs.Connection_Behavior_Override__c = cbItem.Id;
        }
        update depFlows;
        Org__c devOrg = [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'Dev1 env' LIMIT 1];


        List<User_Story__c> us2InsertList = new List<User_Story__c>();
        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test with Connection behavior';
        testStory.Org_Credential__c = devOrg.Id;
        testStory.Environment__c = devOrg.Environment__c;
        testStory.Project__c = testProject.Id;
        testStory.Promote_Change__c = true;
        testStory.Apex_Code_Coverage__c = 100;
        us2InsertList.add(testStory);

        User_Story__c testStory4Dependency = new User_Story__c();
        testStory4Dependency.User_Story_Title__c = 'Test with Connection behavior';
        testStory4Dependency.Org_Credential__c = devOrg.Id;
        testStory4Dependency.Environment__c = devOrg.Environment__c;
        testStory4Dependency.Project__c = testProject.Id;
        testStory4Dependency.Promote_Change__c = true;
        testStory4Dependency.Apex_Code_Coverage__c = 100;
        us2InsertList.add(testStory4Dependency);
        insert us2InsertList;

        Team_Dependency__c td = new Team_Dependency__c();
        td.Provider_User_Story__c = testStory4Dependency.Id;
        td.Dependent_User_Story__c = testStory.Id;
        insert td;

        Attachment gitMetadataAtt = new Attachment(
                Name = 'Git MetaData',
                ParentId = testStory.Id,
                Body = Blob.valueOf('[{"t":"StaticResource","n":"deployment","b":"umit uckan","d":"2019-10-14","cb":"umit uckan","cd":"2019-10-14","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018ojWSEAY"},{"t":"ApexClass","n":"Test_TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"},{"t":"ApexClass","n":"TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"}]')
        );
        insert gitMetadataAtt;

        Test.startTest();
        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        usrfpe.getDeploymentFlowSteps();
        usrfpe.submitChanges();
        Test.stopTest();
    }

    @IsTest static void testUserStoryReadyForPromotionWithNotIncludedInThisFlowWarning() {
        Project__c testProject = [SELECT Id, Deployment_Flow__c FROM Project__c WHERE Name = 'Project 1' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        System.debug('cbItem===> '+cbItem);
        List<Deployment_Flow_Step__c> depFlows = [SELECT Id, Connection_Behavior_Override__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :testProject.Deployment_Flow__c];
        For(Deployment_Flow_Step__c dfs : depFlows){
            dfs.Connection_Behavior_Override__c = cbItem.Id;
        }
        update depFlows;

        Environment__c testEnvWOFlow = new Environment__c();
        testEnvwoFlow.Name = 'testEnvWOFlow env';
        testEnvwoFlow.Index_Back_Promotion_metadata__c = true;
        testEnvwoFlow.Type__c = 'Production/Developer';
        insert testEnvWOFlow;

        // Org Credential creation
        Org__c testOrgWOFlow = new Org__c();
        testOrgWOFlow.Name = UserInfo.getOrganizationName().left(80);
        testOrgWOFlow.Org_Type__c = 'Production/Developer';
        testOrgWOFlow.Username__c = 'Test_User';
        testOrgWOFlow.Environment__c =testEnvWOFlow.Id;
        insert testOrgWOFlow;

        User_Story__c testStory = new User_Story__c();
        testStory.User_Story_Title__c = 'Test with Connection behavior';
        testStory.Org_Credential__c = testOrgWOFlow.Id;
        testStory.Environment__c = testEnvWOFlow.Id;
        testStory.Project__c = testProject.Id;
        testStory.Promote_Change__c = true;
        testStory.Apex_Code_Coverage__c = 100;
        insert testStory;

        Attachment gitMetadataAtt = new Attachment(
                Name = 'Git MetaData',
                ParentId = testStory.Id,
                Body = Blob.valueOf('[{"t":"StaticResource","n":"deployment","b":"umit uckan","d":"2019-10-14","cb":"umit uckan","cd":"2019-10-14","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018ojWSEAY"},{"t":"ApexClass","n":"Test_TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"},{"t":"ApexClass","n":"TestCCDFullFlow","b":"umit uckan","d":"2019-09-18","cb":"umit uckan","cd":"2019-09-17","r":false,"cmm":"updated","snapshotCommitId":"a0P1n000018V1vSEAS"}]')
        );
        insert gitMetadataAtt;

        PageReference pr = Page.UserStoryReadyForPromote;
        pr.getParameters().put('id', testStory.Id);
        Test.setCurrentPage(pr);

        UserStoryReadyForPromoteExtension usrfpe = new UserStoryReadyForPromoteExtension(new ApexPages.StandardController((testStory)));
        usrfpe.getDeploymentFlowSteps();
        //usrfpe.populatePageMessagesMap();
        usrfpe.submitChanges();
    }
}