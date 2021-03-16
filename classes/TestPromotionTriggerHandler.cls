@IsTest
private class TestPromotionTriggerHandler {
    private class ApplicationException extends Exception {}
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    private static final String ADMIN_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_admin@myorg.com\' LIMIT 1';
    @testSetup 
    static void setupData() {
        TestUtilities.enableLicenses(10,10,10,10,10,100);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    static testMethod void deletePromotion(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;
            Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(TestProject.Id, null);
            TestPromotion.Destination_Environment__c = null;
            insert TestPromotion;

            delete TestPromotion;
            System.assertEquals(0, [SELECT Id FROM Promotion__c WHERE Id=:TestPromotion.Id].size());
            undelete TestPromotion;
            System.assertEquals(1, [SELECT Id FROM Promotion__c WHERE Id=:TestPromotion.Id].size());
            Test.stopTest();
        }
    }
    static testMethod void TestSettingOfFlow_insert(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('Test project');
            insert testProject;
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            insert env1;
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            insert env2;
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            insert testOrg1;

            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert testOrg2;
            Test.startTest();
            Deployment_Flow__c testPipeline = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert testPipeline;
            Deployment_Flow_Step__c testPipelineConnection = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, testPipeline.Id);
            insert testPipelineConnection;

            testProject.Deployment_Flow__c = testPipeline.Id;
            update testProject;

            
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            testPromotion.Destination_Environment__c = null;
            insert testPromotion;
            Test.stopTest();

            Promotion__c assertPromotion = [SELECT Id, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:TestPromotion.Id LIMIT 1];
            System.assertEquals(env2.Id, assertPromotion.Destination_Environment__c);
            System.assertEquals(testOrg1.Id, assertPromotion.Source_Org_Credential__c);
            System.assertEquals(testOrg2.Id, assertPromotion.Destination_Org_Credential__c);
        }
    }
    static testMethod void TestSettingOfFlow_update(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            insert TestProject;
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
            insert env1;
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Production Environment', 'SFDC_OrgId2');
            insert env2;

            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            insert TestOrg1;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert TestOrg2;
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            TestProject.Deployment_Flow__c = flow.Id;
            update TestProject;

            Promotion__c TestPromotion = new Promotion__c();
            TestPromotion.Project__c = TestProject.Id;
            TestPromotion.Source_Environment__c = env1.Id;
            TestPromotion.Send_Deployment_Complete_email__c = false;
            insert TestPromotion;

            Promotion__c result = [SELECT Id, Source_Environment__c, Destination_Environment__c FROM Promotion__c WHERE Id=:TestPromotion.Id limit 1];
            
            System.assertEquals(env2.Id, result.Destination_Environment__c );
            TestPromotion.Destination_Environment__c = null;
            update TestPromotion;
            Test.stopTest();

            result = [SELECT Id, Source_Environment__c, Destination_Environment__c FROM Promotion__c WHERE Id=:TestPromotion.Id limit 1];
            System.assertEquals(env2.Id, result.Destination_Environment__c );
        }
    }
    static testMethod void triggerTest() {        
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;
            List<Environment__c> envList = new List<Environment__c>();
            Environment__c env1 = new Environment__c(Name='UAT Environment', Type__c='Production');
            Environment__c env2 = new Environment__c(Name='Production Environment', Type__c='Production');
            insert envList;


            List<Org__c> orgList = new List<Org__c>();
            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            orgList.add(TestOrg1);
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            orgList.add(TestOrg2);
            insert orgList;
            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            
            Set<Id> promotionIds = new Set<Id>();
            List<Promotion__c> promotions = new List<Promotion__c>();
            for(Integer i=0; i<10; i++){
                Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(TestProject.Id, env1.Id);
                promotions.add(TestPromotion);
            }
            insert promotions;
            System.debug('########################## PROMOTIONS == '+promotions.size());
            
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Promotion__c p : promotions){
                promotionIds.add(p.Id);
                for(Integer i=0; i<5; i++){
                    User_Story__c TestUserStory = CMTestMethodUtilities.createUserStory('Test');
                    TestUserStory.Environment__c = env1.Id;
                    TestUserStory.Project__c = TestProject.Id;
                    TestUserStory.Promote_Change__c = true;
                    TestUserStory.Promote_and_Deploy__c = true;
                    userStories.add(TestUserStory);
                }
            }
            insert userStories;
            
            System.debug('########################## USER STORIES == '+userStories.size());
            List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
            Integer counter = 0;
            for(User_Story__c u : userStories){
                Promoted_User_Story__c pus = new Promoted_User_Story__c();
                pus.User_Story__c = u.Id;
                pus.Promotion__c = promotions[counter].Id;
                promotedStories.add(pus);
                counter++;
                if(counter==(promotions.size()-1))counter=0;
            }
            insert promotedStories;
            
            System.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
            
            //Test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
            //updated to Completed. Then, the User Stories will be updated as well.
            List<Deployment__c> deploys = new List<Deployment__c>();
            for(Promotion__c p : promotions){
                //p.Status__c = 'Completed';
                deploys.add(new Deployment__c(name='Test',promotion__c=p.Id));
            }
            insert deploys;
            for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
            update deploys;
            

            update promotions;
            Test.stopTest();
            
            List<Promoted_User_Story__c> results = [SELECT Id, User_Story__c, Promotion__c, User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c
                                                FROM Promoted_User_Story__c
                                                WHERE Promotion__c IN :promotionIds];
            for(Promoted_User_Story__c pus : results){
                System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
                System.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);
                System.assertEquals(env2.Id, pus.User_Story__r.Environment__c);
            }
        }
    }
    static testMethod void triggerTestValIdations() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
        
            Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
            insert feature;
            
            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'g');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
            insert flow;
            Deployment_Flow__c CBMflow = CMTestMethodUtilities.createCBMFlow('flow', true, gitRepo.Id, 'master');
            insert CBMflow;
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;
            
            Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert env1;
            Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
            insert env2;
            Environment__c env3 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert env3;
            Environment__c env4 = new Environment__c(Name='Integration Environment',Type__c='Production');
            insert env4;
            
            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            insert TestOrg1;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert TestOrg2;
            Test.startTest();
            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flow.Id);
            dfs2.Branch__c = 'branch2';
            insert dfs2;
            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, CBMFlow.Id);
            dfs4.Branch__c = 'branch4';
            insert dfs4;

            Promotion__c promotion = CMTestMethodUtilities.createPromotion(TestProject.Id, env1.Id);
            try {
                insert promotion;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assert(true, e.getMessage().contains(Label.PROMOTION_FLOW_INACTIVE));                  
            }
            flow.Active__c = true;
            update flow;
                    
            // Run Test as a CCM User
            User user = Database.query(ADMIN_USER_QUERY);
            System.runAs(user) {
                TestUtilities.assignLicense(user.Username, false, true, false);
                Project__c TestProject2 = CMTestMethodUtilities.createProject('Test project 2');
                TestProject2.Deployment_Flow__c = flow.Id;
                insert TestProject2;
                    
                Org__c TestOrg3 = CMTestMethodUtilities.createOrg('MyOrg3', 'Sandbox', 'SFDC_OrgId3', null, null, System.now(), env3.Id);
                insert TestOrg3;
                Org__c TestOrg4 = CMTestMethodUtilities.createOrg('MyOrg4', 'Production', 'SFDC_OrgId4', null, null, System.now(), env4.Id);
                insert TestOrg4;
                            
                Promotion__c promotion2 = CMTestMethodUtilities.createPromotion(TestProject2.Id, env3.Id);
                
                // InvalId destination Org since it's not a Sandbox
                try {
                    insert promotion2;
                    System.assert(false, 'This must fail');
                } catch (Exception e) {
                    System.debug('MESSAGE: ' + e.getMessage());
                    System.assertEquals(true, e.getMessage().contains(Label.CCM_DESTINATION_ORG_INVALID));                  
                }
                System.assert(true, env4.Type__c.contains('Production'));
                env4.Type__c = 'Sandbox';
                update env4;
                TestOrg4.Org_Type__c = 'Sandbox';
                update TestOrg4;
                System.assertEquals('Sandbox', env4.Type__c);
                
                // InvalId CBM Flow since there is no Git Repository nor Main Branch
                try {
                    insert promotion2;
                    System.assert(false, 'This must fail');
                } catch (Exception e) {
                    System.assertEquals(true, e.getMessage().contains(Label.CBM_FLOW_INVALID));                  
                }
                TestProject2.Deployment_Flow__c = CBMflow.Id;
                update TestProject2;
        
                // ValId CBM Promotion
                insert promotion2;
                System.assertEquals(true, promotion2.Id != null); 
                
                User_Story__c us = CMTestMethodUtilities.createUserStory('Test');
                us.Environment__c = env3.Id;
                us.Org_Credential__c = TestOrg3.Id;
                us.Project__c = TestProject2.Id;
                us.Promote_Change__c = true;
                us.Promote_and_Deploy__c = true;
                insert us;
        
                Promoted_User_Story__c pus = new Promoted_User_Story__c();
                pus.User_Story__c = us.Id;
                pus.Promotion__c = promotion2.Id;
                insert pus;
        
                //Test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
                //updated to Completed. Then, the User Stories will be updated as well.
                Deployment__c deployment = new Deployment__c(Name = 'Test', Promotion__c = promotion2.Id);
                insert deployment;
                System.assertEquals(true, deployment.Id != null);
                deployment.Status__c='Completed Successfully';
                update deployment;
                
                pus = [SELECT User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                                FROM Promoted_User_Story__c
                                                WHERE Id = :pus.Id];
                System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
                System.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);         
                System.assertEquals(env4.Id, pus.User_Story__r.Environment__c);
            }
            Test.stopTest();
        }
    }
    static testMethod void triggerTestValIdationsWithRelease() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=6);
            insert feature;
            Feature__c feature2 = new Feature__c(Name='Git Backup', Enabled__c=true);
            insert feature2;
            
            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'g');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
            insert flow;
            Deployment_Flow__c CBMflow = CMTestMethodUtilities.createCBMFlow('flow', false, gitRepo.Id, 'master');
            insert CBMflow;
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;
            
            Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert env1;
            Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
            insert env2;
            Environment__c env3 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert env3;
            Environment__c env4 = new Environment__c(Name='Integration Environment',Type__c='Production');
            insert env4;
            
            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            insert TestOrg1;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            insert TestOrg2;

            Test.startTest();
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flow.Id);
            insert dfs2;
            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, CBMFlow.Id);
            dfs4.Branch__c = 'branch4';
            insert dfs4;
            
            CBMflow.Active__c = true;
            update CBMflow;
            
            Release__c TestRelease = CMTestMethodUtilities.createRelease('Test');
            TestRelease.Project__c = TestProject.Id;
            insert TestRelease;
            
            Promotion__c promotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            promotion.Release__c = TestRelease.Id;
            try {
                insert promotion;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assert(true, e.getMessage().contains(Label.PROMOTION_FLOW_INACTIVE));                  
            }
            flow.Active__c = true;
            update flow;
                    
            // Run Test as a CCM User
            User user = Database.query(ADMIN_USER_QUERY);
            System.runAs(user) {
                TestUtilities.assignLicense(user.Username, false, true, false);
                Project__c TestProject2 = CMTestMethodUtilities.createProject('Test project 2');
                TestProject2.Deployment_Flow__c = flow.Id;
                insert TestProject2;
                    
                Org__c TestOrg3 = CMTestMethodUtilities.createOrg('MyOrg3', 'Sandbox', 'SFDC_OrgId3', null, null, System.now(), env3.Id);
                insert TestOrg3;
                Org__c TestOrg4 = CMTestMethodUtilities.createOrg('MyOrg4', 'Production', 'SFDC_OrgId4', null, null, System.now(), env4.Id);
                insert TestOrg4;
                            
                Release__c TestRelease2 = CMTestMethodUtilities.createRelease('Test Release');
                TestRelease2.Project__c = TestProject2.Id;
                insert TestRelease2;
                
                Promotion__c promotion2 = CMTestMethodUtilities.createPromotion(null, env3.Id);
                promotion2.Release__c = TestRelease2.Id;

                // InvalId destination Org since it's not a Sandbox
                try {
                    insert promotion2;
                    System.assert(false, 'This must fail');
                } catch (Exception e) {
                    System.assertEquals(true, e.getMessage().contains(Label.CCM_DESTINATION_ORG_INVALID));                  
                }
                System.assert(true, env4.Type__c.contains('Production'));
                env4.Type__c = 'Sandbox';
                update env4;
                TestOrg4.Org_Type__c = 'Sandbox';
                update TestOrg4;
                System.assertEquals('Sandbox', env4.Type__c);
                
                // InvalId CBM Flow since there is no Git Repository nor Main Branch
                try {
                    insert promotion2;
                    System.assert(false, 'This must fail');
                } catch (Exception e) {
                    System.assertEquals(true, e.getMessage().contains(Label.CBM_FLOW_INVALID));                  
                }
                TestProject2.Deployment_Flow__c = CBMflow.Id;
                update TestProject2;
        
                // ValId CBM Promotion
                insert promotion2;
                System.assertEquals(true, promotion2.Id != null); 
                
                User_Story__c us = CMTestMethodUtilities.createUserStory('Test');
                us.Environment__c = env3.Id;
                us.Org_Credential__c = TestOrg3.Id;
                us.Project__c = TestProject2.Id;
                us.Promote_Change__c = true;
                us.Promote_and_Deploy__c = true;
                insert us;
        
                Promoted_User_Story__c pus = new Promoted_User_Story__c();
                pus.User_Story__c = us.Id;
                pus.Promotion__c = promotion2.Id;
                insert pus;
        
                //Test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
                //updated to Completed. Then, the User Stories will be updated as well.
                Deployment__c deployment = new Deployment__c(Name = 'Test', Promotion__c = promotion2.Id);
                insert deployment;
                System.assertEquals(true, deployment.Id != null);
                deployment.Status__c='Completed Successfully';
                update deployment;
                
                pus = [SELECT User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                                FROM Promoted_User_Story__c
                                                WHERE Id = :pus.Id];
                System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
                System.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);         
                System.assertEquals(env4.Id, pus.User_Story__r.Environment__c);
                Test.stopTest();
            }
        }            
    }
    static testMethod void TestSetSourceOrgFROMEnvironment(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            insert TestProject;
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
            insert env1;
            Org__c TestOrg = CMTestMethodUtilities.createOrg('OrgName','Production', 'SFDC_OrgId','','USERNAME', System.now(), env1.Id);
            insert TestOrg;
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
            insert env2;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('OrgName2','Sandbox', 'SFDC_OrgId2','','USERNAME2', System.now(), env2.Id);
            insert TestOrg2;
            
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            TestProject.Deployment_Flow__c = flow.Id;
            update TestProject;
            
            Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(TestProject.Id, env1.Id);
            insert TestPromotion;
            Test.stopTest();
            
            Promotion__c result = [SELECT Id, Source_Environment__c, Source_Org_Credential__c FROM Promotion__c WHERE Id=:TestPromotion.Id limit 1];
            System.assertEquals(TestOrg.Id, result.Source_Org_Credential__c);
        }
    }
    
    static testMethod void TestSetDefaultEnvironment(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            insert TestProject;
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
            insert env1;
            Org__c TestOrg = CMTestMethodUtilities.createOrg('OrgName2','Production', 'SFDC_OrgId2','','USERNAME2', System.now(), env1.Id);
            insert TestOrg;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('OrgName3','Production', 'SFDC_OrgId3','','USERNAME3', System.now(), env1.Id);
            TestOrg2.Default_Credential__c = true;
            insert TestOrg2;
            
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId4');
            insert env2;
            Org__c TestOrg4 = CMTestMethodUtilities.createOrg('OrgName4','Sandbox', 'SFDC_OrgId4','','USERNAME4', System.now(), env2.Id);
            TestOrg4.Default_Credential__c = true;
            insert TestOrg4;
            Org__c TestOrg5 = CMTestMethodUtilities.createOrg('OrgName5','Sandbox', 'SFDC_OrgId5','','USERNAME5', System.now(), env2.Id);
            insert TestOrg5;
            
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            TestProject.Deployment_Flow__c = flow.Id;
            update TestProject;
            
            Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(TestProject.Id, env1.Id);
            insert TestPromotion;
            Test.stopTest();
            
            Promotion__c result = [SELECT Id, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:TestPromotion.Id LIMIT 1];
            System.assertEquals(TestOrg2.Id, result.Source_Org_Credential__c);
            System.assertEquals(TestOrg4.Id, result.Destination_Org_Credential__c);
        }
    }
    
    static testMethod void triggerTestwithRelease() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();        
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;

            List<Environment__c> envList = new List<Environment__c>();
            Environment__c env1 = new Environment__c(Name='UAT Environment');
            envList.add(env1);
            Environment__c env2 = new Environment__c(Name='Production Environment');
            envList.add(env2);
            insert envList;

            Release__c TestRelease = CMTestMethodUtilities.createRelease('Test Release');
            TestRelease.Project__c = TestProject.Id;
            insert TestRelease;

            List<Org__c> orgList = new List<Org__c>();
            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            orgList.add(TestOrg1);
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            orgList.add(TestOrg2);
            insert orgList;
            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            
            Set<Id> promotionIds = new Set<Id>();
            List<Promotion__c> promotions = new List<Promotion__c>();
            for(Integer i=0; i<5; i++){
                Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
                TestPromotion.Release__c = TestRelease.Id;
                promotions.add(TestPromotion);
            }
            insert promotions;
            System.debug('########################## PROMOTIONS == '+promotions.size());
            
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Promotion__c p : promotions){
                promotionIds.add(p.Id);
                for(Integer i=0; i<5; i++){
                    User_Story__c TestUserStory = CMTestMethodUtilities.createUserStory('Test');
                    TestUserStory.Environment__c = env1.Id;
                    TestUserStory.Project__c = TestProject.Id;
                    TestUserStory.Promote_Change__c = true;
                    userStories.add(TestUserStory);
                }
            }
            insert userStories;
            System.debug('########################## USER STORIES == '+userStories.size());
            List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
            Integer counter = 0;
            for(User_Story__c u : userStories){
                Promoted_User_Story__c pus = new Promoted_User_Story__c();
                pus.User_Story__c = u.Id;
                pus.Promotion__c = promotions[counter].Id;
                promotedStories.add(pus);
                counter++;
                if(counter==(promotions.size()-1))counter=0;
            }
            insert promotedStories;
            System.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
            //Test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
            //updated to Completed. Then, the User Stories will be updated as well.
            List<Deployment__c> deploys = new List<Deployment__c>();
            for(Promotion__c p : promotions){
                //p.Status__c = 'Completed';
                deploys.add(new Deployment__c(Name='Test',Promotion__c = p.Id));
            }
            insert deploys;
            for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
            update deploys;
            

            update promotions;
            Test.stopTest();
            
            List<Promoted_User_Story__c> results = [SELECT Id, User_Story__c, Promotion__c, User_Story__r.Promote_Change__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c
                                                FROM Promoted_User_Story__c
                                                WHERE Promotion__c IN :promotionIds];
            for(Promoted_User_Story__c pus : results){
                System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
                System.assertEquals(env2.Id, pus.User_Story__r.Environment__c);
            }
        }
    }


    static testMethod void TestRunDestinationTestsUponCompletion(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {

            // "simulate" an API Key, since Testmethods do not support webservice callouts insIde DeployAPI.createAPIKey();
            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if(String.isBlank(ps.API_Key__c)){
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            System.assert(LicenseHelper.isCopadoEnabled());
            System.assert(LicenseHelper.isCSTEnabled());
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flow.Id;
            insert TestProject;

            List<Environment__c> envList = new List<Environment__c>();
            Environment__c env1 = new Environment__c(Name='UAT Environment');
            envList.add(env1);
            Environment__c env2 = new Environment__c(Name='Production Environment');
            envList.add(env2);
            insert envList;

            Release__c TestRelease = CMTestMethodUtilities.createRelease('Test Release');
            TestRelease.Project__c = TestProject.Id;
            insert TestRelease;

            List<Org__c> orgList = new List<Org__c>();
            Org__c TestOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            orgList.add(TestOrg1);
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            orgList.add(TestOrg2);
            insert orgList;
            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            
            Set<Id> promotionIds = new Set<Id>();
            List<Promotion__c> promotions = new List<Promotion__c>();
            for(Integer i=0; i<5; i++){
                Promotion__c TestPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
                TestPromotion.Release__c = TestRelease.Id;
                promotions.add(TestPromotion);
            }
            insert promotions;
            System.debug('########################## PROMOTIONS == '+promotions.size());
            
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Promotion__c p : promotions){
                promotionIds.add(p.Id);
                for(Integer i=0; i<5; i++){
                    User_Story__c TestUserStory = CMTestMethodUtilities.createUserStory('Test');
                    TestUserStory.Environment__c = env1.Id;
                    TestUserStory.Project__c = TestProject.Id;
                    TestUserStory.Promote_Change__c = true;
                    userStories.add(TestUserStory);
                }
            }
            insert userStories;
            System.debug('########################## USER STORIES == '+userStories.size());
            List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
            Integer counter = 0;
            for(User_Story__c u : userStories){
                Promoted_User_Story__c pus = new Promoted_User_Story__c();
                pus.User_Story__c = u.Id;
                pus.Promotion__c = promotions[counter].Id;
                promotedStories.add(pus);
                counter++;
                if(counter>=(promotions.size()-1))counter=0;
            }
            insert promotedStories;
            System.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
            
            //Test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
            //updated to Completed. Then, the User Stories will be updated as well.
            List<Deployment__c> deploys = new List<Deployment__c>();
            for(Promotion__c p : promotions){
                //p.Status__c = 'Completed';
                deploys.add(new Deployment__c(Name='Test',Promotion__c=p.Id));
            }
            insert deploys;
            for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
            update deploys;

            Selenium_Settings__c s = new Selenium_Settings__c(Name = 'Test settings', Webdriver_URL__c='http://drive.me');
            insert s;
            Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(Name='Test suite1');
            insert ts1;
            Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(Name='Test suite2');
            insert ts2;
            
            List<Selenium_Test_Group__c> Testgroups = new List<Selenium_Test_Group__c>();
            {
                Selenium_Test_Group__c g;
                
                g = new Selenium_Test_Group__c();
                g.Name = 'source regression';
                g.Selenium_Settings__c = s.Id;
                g.Type__c = 'Regression Test';
                g.Environment__c = TestOrg1.Environment__c;
                Testgroups.add(g);
                
                g = new Selenium_Test_Group__c();
                g.Name = 'source userstory';
                g.Selenium_Settings__c = s.Id;
                g.Type__c = 'User Story Test';
                g.Environment__c = TestOrg1.Environment__c;
                Testgroups.add(g);
                
                g = new Selenium_Test_Group__c();
                g.Name = 'dest regression';
                g.Selenium_Settings__c = s.Id;
                g.Type__c = 'Regression Test';
                g.Environment__c = TestOrg2.Environment__c;
                Testgroups.add(g);
                        
                g = new Selenium_Test_Group__c();
                g.Name = 'dest userstory';
                g.Selenium_Settings__c = s.Id;
                g.Type__c = 'User Story Test';
                g.Environment__c = TestOrg2.Environment__c;
                Testgroups.add(g);
        
                insert Testgroups;
            }
            
            User_Story_Selenium_Test__c usxTest1 = new User_Story_Selenium_Test__c();
            usxTest1.Selenium_Test_Group__c = Testgroups.get(1).Id;
            usxTest1.User_Story__c = userStories.get(0).Id;
            insert usxTest1;
            User_Story_Selenium_Test__c usxTest2 = new User_Story_Selenium_Test__c();
            usxTest2.Selenium_Test_Group__c = Testgroups.get(3).Id;
            usxTest2.User_Story__c = userStories.get(0).Id;
            insert usxTest2;
            
            System.assertEquals(TestOrg1.Environment__c, Testgroups.get(0).Environment__c);
            System.assertEquals(TestOrg1.Environment__c, Testgroups.get(1).Environment__c);
            System.assertEquals(TestOrg2.Environment__c, Testgroups.get(2).Environment__c);
            System.assertEquals(TestOrg2.Environment__c, Testgroups.get(3).Environment__c);

            // now get the Test groups of each user story
            List<Id> userstoryTestIds = new List<Id>();
            List<Id> promIds = new List<Id>();
            promIds.add(promotions.get(0).Id);
            List<User_Story_Selenium_Test__c> tuss = [SELECT Selenium_Test_Group__c, Selenium_Test_Group__r.Name,
                                                    Selenium_Test_Group__r.Type__c, Selenium_Test_Group__r.Environment__c  
                                                    FROM User_Story_Selenium_Test__c WHERE User_Story__c IN
                                                    (SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c IN :promIds)];
            for(User_Story_Selenium_Test__c a : tuss) {
                System.debug('*** '+a);
                
            }
            
            String b = '{}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
            
            List<Id> groupIds = new List<Id>();
            for(Selenium_Test_Group__c g1: Testgroups ) groupIds.add(g1.Id);
            System.assertEquals(4, groupIds.size());
            

            update promotions;
            Test.stopTest();
            
            Testgroups = [SELECT Name, Status__c,Environment__c FROM Selenium_Test_Group__c WHERE Id IN :groupIds];
            System.assertEquals(4, Testgroups.size());
            for(Selenium_Test_Group__c g1 : Testgroups ) {
                System.debug(g1 + ' g1.Status__c='+g1.Status__c);
            }

            for(Selenium_Test_Group__c g1 : Testgroups ) {
                if(TestOrg1.Environment__c == g1.Environment__c ){
                    System.assertEquals(null, g1.Status__c);
                }else {
                    System.assertEquals('In Progress', g1.Status__c);
                }
            }
        }
	}

    static testMethod void TestBackPromotion() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
            insert feature;
            
            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            insert flowCBM;
            System.assert(flowCBM.Id != null);
            
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            TestProject.Deployment_Flow__c = flowCBM.Id;
            insert TestProject;
            
            Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert envDev1;
            Environment__c envDev2 = new Environment__c(Name='Integration Environment',Type__c='Production');
            insert envDev2;
            Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            insert envInt;
            
            Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
            insert orgDev1;
            Org__c orgDev2 = CMTestMethodUtilities.createOrg('MyOrgDev2', 'Sandbox', 'SFDC_OrgId2', null, null, System.now(), envDev2.Id);
            insert orgDev2;
            Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
            insert orgInt;

            Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
            Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev2.Id, Branch__c = 'dev2');
            Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
            insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt};

            Test.startTest();
            Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
            stepDev1ToInt.Branch__c = 'dev1';
            Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
            stepDev2ToInt.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{stepDev1ToInt, stepDev2ToInt};

            Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.Id, Commit_Id__c='b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c=Date.today().addDays(-3),Commit_Message__c='Test 1',Status__c = 'Complete');
            insert snapshotCommit1;

            // Case 1. Dev1 has 1 user story with one 'Complete' commit. UserStory1 appears as 'Ahead' in stepDev1ToInt
            User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
            userStory1.Org_Credential__c = orgDev1.Id;
            userStory1.Project__c = TestProject.Id;
            insert userStory1;
            
            User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommit1.Id);
            insert userStoryCommit1;

            Promotion__c TestPromotion1 = CMTestMethodUtilities.createPromotion(TestProject.Id, envDev1.Id);
            TestPromotion1.Status__c = 'Completed';
            insert TestPromotion1;
            Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = TestPromotion1.Id);
            insert promotedUserStory1;
            userStory1.Org_Credential__c = orgInt.Id;
            userStory1.Environment__c = envInt.Id;
            update userStory1;

            System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

            Promotion__c TestBackPromotion1 = CMTestMethodUtilities.createBackPromotion(TestProject.Id, envDev2.Id);

            flowCBM.Git_Repository__c = null;
            update flowCBM;

            try {
                insert TestBackPromotion1;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assert(true, e.getMessage().contains(Label.BACK_PROMOTION_NOT_ENABLED));                  
            }

            flowCBM.Git_Repository__c = gitRepo.Id;
            update flowCBM;

            insert TestBackPromotion1;
            System.assert(TestBackPromotion1.Id != null);
            TestBackPromotion1 = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id = :TestBackPromotion1.Id];
            System.assertEquals(envInt.Id, TestBackPromotion1.Source_Environment__c);
            System.assertEquals(orgInt.Id, TestBackPromotion1.Source_Org_Credential__c);
            System.assertEquals(envDev2.Id, TestBackPromotion1.Destination_Environment__c);
            System.assertEquals(orgDev2.Id, TestBackPromotion1.Destination_Org_Credential__c);
            Test.stopTest();
        }
    }

    static testMethod void TestDestinationOrgFROMEnvironment(){
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Project__c TestProject = CMTestMethodUtilities.createProject('Test project');
            insert TestProject;
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
            insert env1;
            Org__c TestOrg = CMTestMethodUtilities.createOrg('OrgName','Production', 'SFDC_OrgId','','USERNAME', System.now(), env1.Id);
            insert TestOrg;
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
            insert env2;
            Org__c TestOrg2 = CMTestMethodUtilities.createOrg('OrgName2','Sandbox', 'SFDC_OrgId2','','USERNAME2', System.now(), env2.Id);
            insert TestOrg2;
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow__c flow2 = CMTestMethodUtilities.createCCMFlow('Standard flow 2', true);
            insert flow2;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            TestProject.Deployment_Flow__c = flow.Id;
            update TestProject;
            Project__c TestProject2 = CMTestMethodUtilities.createProject('Test project 2');
            TestProject2.Deployment_Flow__c = flow2.Id;
            insert TestProject2;

            Release__c release1 = new Release__c(Name = 'Release 1');
            insert release1;
            Release__c release2 = new Release__c(Name = 'Release 2', Project__c = TestProject.Id);
            insert release2;
            Release__c release3 = new Release__c(Name = 'Release 3', Project__c = TestProject2.Id);
            insert release3;
            
            Promotion__c promotion1 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = TestProject.Id, Release__c = release1.Id);
            insert promotion1;
            
            Promotion__c result = [SELECT Id, Source_Environment__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:promotion1.Id LIMIT 1];
            System.assertEquals(TestOrg2.Id, result.Destination_Org_Credential__c);

            Promotion__c promotion2 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = TestProject.Id, Release__c = release2.Id);
            insert promotion2;

            Promotion__c result2 = [SELECT Id, Source_Environment__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:promotion2.Id LIMIT 1];
            System.assertEquals(TestOrg2.Id, result2.Destination_Org_Credential__c);

            try {
                Promotion__c promotion3 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = TestProject.Id, Release__c = release3.Id);
                insert promotion3;
                throw new ApplicationException('This should fail'); 
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(Label.Same_Deployment_Flow_Linked_To_Release));
            }
            Test.stopTest();
        }
    }
}