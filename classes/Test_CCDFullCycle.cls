/**
 * Created by COPADO\ucan on 9/2/19.
 */

@IsTest
private class Test_CCDFullCycle {
    @TestSetup
    static void setupData() {
        User sysUs = new User();
        sysUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        sysUs.LastName = 'LastName';
        sysUs.Email = 'test1@test1.com';
        sysUs.Username = 'psysUser000@amamama.com' + System.currentTimeMillis();
        sysUs.CompanyName = 'TEST';
        sysUs.Title = 'title';
        sysUs.Alias = 'alias';
        sysUs.TimeZoneSidKey = 'America/Los_Angeles';
        sysUs.EmailEncodingKey = 'UTF-8';
        sysUs.LanguageLocaleKey = 'en_US';
        sysUs.LocaleSidKey = 'en_US';

        User stdUs = new User();
        stdUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        stdUs.LastName = 'LastName';
        stdUs.Email = 'test2@test2.com';
        stdUs.Username = 'pstdUser002@amamama.com' + System.currentTimeMillis();
        stdUs.CompanyName = 'TEST';
        stdUs.Title = 'title2';
        stdUs.Alias = 'alias2';
        stdUs.TimeZoneSidKey = 'America/Los_Angeles';
        stdUs.EmailEncodingKey = 'UTF-8';
        stdUs.LanguageLocaleKey = 'en_US';
        stdUs.LocaleSidKey = 'en_US';

        insert new List<User>{ sysUs, stdUs };

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 10);

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = sysUs.Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void testManualAndAutomatedForwardPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Test.enableChangeDataCapture();

            for (User_Story__c usItem : usList) {
                usItem.Promote_Change__c = true;
                usItem.Exclude_From_CBM__c = false;
                usItem.Status__c = 'Ready for Testing';
            }
            update usList;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name
                FROM Promotion__c
            ];

            String usNames = '', destinationEnvName;

            System.assertEquals(1, promoResult.size());
            destinationEnvName = promoResult[0].Destination_Environment__r.Name;

            for (Promoted_User_Story__c pus : [SELECT Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promotion__c = :promoResult[0].Id]) {
                usNames += (usNames.length() > 0 ? ', ' : '') + pus.User_Story__r.Name;
            }

            Deployment__c deploymentItem = new Deployment__c(
                Name = 'CD: Deploy - ' + usNames + ' ➠ ' + destinationEnvName,
                Send_Deployment_Complete_email__c = true,
                From_Org__c = promoResult[0].Source_Org_Credential__c,
                Status__c = 'Draft',
                Promotion__c = promoResult[0].Id
            );
            insert deploymentItem;

            Destination_Org__c destOrg = new Destination_Org__c(
                Deployment__c = deploymentItem.Id,
                To_Org__c = promoResult[0].Destination_Org_Credential__c
            );
            insert destOrg;

            Step__c stepItem = new Step__c(
                Name = 'Git Promotion ' + promoResult[0].Name + ' merge into ' + destinationEnvName,
                Type__c = 'Git Promotion',
                CheckOnly__c = false,
                Order__c = 1,
                Commit_Id__c = '12345678987654321234567898765432123456789',
                dataJson__c = '{"testLevel":"NoTestRun"}',
                Branch__c = 'promotion/' + promoResult[0].Name + '-CDDeploy' + usNames + destinationEnvName,
                Deployment__c = deploymentItem.Id
            );
            insert stepItem;

            Quality_Gate__c qgItem = [SELECT Selenium_Test_Group__c FROM Quality_Gate__c WHERE Type__c = 'Selenium Test' LIMIT 1];
            qgItem.Selenium_Test_Group__c = stgItem.Id;
            update qgItem;

            Test.startTest();
            Attachment metadataAtt = new Attachment(
                Name = 'MetaData',
                Body = Blob.valueOf(
                    '[{"t":"ApexClass","n":"DeleteTHIS","b":"Umit Can Uckan","d":"2019-08-07","cb":"Umit Can Uckan","cd":"2019-08-07","r":false,"cmm":"updated","snapshotCommitId":"a0P************"}]'
                ),
                ParentId = stepItem.Id
            );

            Attachment gitPromotionAtt = new Attachment(
                Name = 'Git-Promotion.json',
                Body = Blob.valueOf(
                    '{"promotion_branch":"' +
                    stepItem.Branch__c +
                    '","flow_id":"a0A************","target_branch":"targetBranch","target_env":"a0G************","source_env":"a0G************","promoted_commits":["123456789098765432123456789"],"source_branch":"SourceBranch"}'
                ),
                ParentId = stepItem.Id
            );
            Attachment retrieveOnlyAtt = new Attachment(Name = 'RetrieveOnly.json', Body = Blob.valueOf('[]'), ParentId = stepItem.Id);

            List<Attachment> attList = new List<Attachment>{ metadataAtt, gitPromotionAtt, retrieveOnlyAtt };
            insert attList;

            List<Step__c> stepList = [SELECT Id, Name, Order__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :deploymentItem.Id];

            System.assertEquals(8, stepList.size());
            Test.stopTest();
        }
    }

    @IsTest
    static void testManualAndAutomatedForwardPromotionWithBasicMetadata() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Test.enableChangeDataCapture();

            for (User_Story__c usItem : usList) {
                usItem.Promote_Change__c = true;
                usItem.Exclude_From_CBM__c = false;
                usItem.Status__c = 'Ready for Testing';
            }
            update usList;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name
                FROM Promotion__c
            ];

            String usNames = '', destinationEnvName;

            System.assertEquals(1, promoResult.size());
            destinationEnvName = promoResult[0].Destination_Environment__r.Name;

            for (Promoted_User_Story__c pus : [SELECT Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promotion__c = :promoResult[0].Id]) {
                usNames += (usNames.length() > 0 ? ', ' : '') + pus.User_Story__r.Name;
            }

            Deployment__c deploymentItem = new Deployment__c(
                Name = 'CD: Deploy - ' + usNames + ' ➠ ' + destinationEnvName,
                Send_Deployment_Complete_email__c = true,
                From_Org__c = promoResult[0].Source_Org_Credential__c,
                Status__c = 'Draft',
                Promotion__c = promoResult[0].Id
            );
            insert deploymentItem;

            Destination_Org__c destOrg = new Destination_Org__c(
                Deployment__c = deploymentItem.Id,
                To_Org__c = promoResult[0].Destination_Org_Credential__c
            );
            insert destOrg;

            Step__c stepItemBasicMdt = new Step__c(
                Name = 'Basic Metadata',
                Type__c = 'MetaData',
                CheckOnly__c = false,
                Order__c = 1,
                dataJson__c = '{"testLevel":"NoTestRun"}',
                Deployment__c = deploymentItem.Id
            );
            insert stepItemBasicMdt;

            Quality_Gate__c qgItem = [SELECT Selenium_Test_Group__c FROM Quality_Gate__c WHERE Type__c = 'Selenium Test' LIMIT 1];
            qgItem.Selenium_Test_Group__c = stgItem.Id;
            update qgItem;

            Attachment metadataAttForBasicMetadata = new Attachment(
                Name = 'MetaData',
                Body = Blob.valueOf(
                    '[{"t":"ApexClass","n":"DeleteTHIS","b":"Umit Can Uckan","d":"2019-08-07","cb":"Umit Can Uckan","cd":"2019-08-07","r":false,"cmm":"updated","snapshotCommitId":"a0P************"}]'
                ),
                ParentId = stepItemBasicMdt.Id
            );

            Test.startTest();
            insert metadataAttForBasicMetadata;

            List<Step__c> stepList = [SELECT Id, Name, Order__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :deploymentItem.Id];

            System.assertEquals(8, stepList.size());
            Test.stopTest();
        }
    }

    @IsTest
    static void testManualAndAutomatedForwardPromotionWithBothMetadata() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Quality_Gate__c qgItem = [SELECT Selenium_Test_Group__c FROM Quality_Gate__c WHERE Type__c = 'Selenium Test' LIMIT 1];
            qgItem.Selenium_Test_Group__c = stgItem.Id;
            update qgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Test.enableChangeDataCapture();

            for (User_Story__c usItem : usList) {
                usItem.Promote_Change__c = true;
                usItem.Exclude_From_CBM__c = false;
                usItem.Status__c = 'Ready for Testing';
            }
            update usList;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name
                FROM Promotion__c
            ];

            String usNames = '', destinationEnvName;

            System.assertEquals(1, promoResult.size());
            destinationEnvName = promoResult[0].Destination_Environment__r.Name;

            for (Promoted_User_Story__c pus : [SELECT Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promotion__c = :promoResult[0].Id]) {
                usNames += (usNames.length() > 0 ? ', ' : '') + pus.User_Story__r.Name;
            }

            Deployment__c deploymentItem = new Deployment__c(
                Name = 'CD: Deploy - ' + usNames + ' ➠ ' + destinationEnvName,
                Send_Deployment_Complete_email__c = true,
                From_Org__c = promoResult[0].Source_Org_Credential__c,
                Status__c = 'Draft',
                Promotion__c = promoResult[0].Id
            );
            insert deploymentItem;

            Destination_Org__c destOrg = new Destination_Org__c(
                Deployment__c = deploymentItem.Id,
                To_Org__c = promoResult[0].Destination_Org_Credential__c
            );
            insert destOrg;

            Step__c stepItemBasicMdt = new Step__c(
                Name = 'Basic MetaData',
                Type__c = 'MetaData',
                CheckOnly__c = false,
                dataJson__c = '{"testLevel":"NoTestRun"}',
                Deployment__c = deploymentItem.Id
            );
            insert stepItemBasicMdt;

            Step__c stepItem = new Step__c(
                Name = 'Git Promotion ' + promoResult[0].Name + ' merge into ' + destinationEnvName,
                Type__c = 'Git Promotion',
                CheckOnly__c = false,
                Commit_Id__c = '12345678987654321234567898765432123456789',
                dataJson__c = '{"testLevel":"NoTestRun"}',
                Branch__c = 'promotion/' + promoResult[0].Name + '-CDDeploy' + usNames + destinationEnvName,
                Deployment__c = deploymentItem.Id
            );
            insert stepItem;

            Test.startTest();
            Attachment metadataAttBasicMdt = new Attachment(
                Name = 'MetaData',
                Body = Blob.valueOf(
                    '[{"t":"ApexClass","n":"DeleteTHIS","b":"Umit Can Uckan","d":"2019-08-07","cb":"Umit Can Uckan","cd":"2019-08-07","r":false,"cmm":"updated","snapshotCommitId":"a0P************"}]'
                ),
                ParentId = stepItemBasicMdt.Id
            );
            insert metadataAttBasicMdt;

            AttachmentTriggerHelper.stepFlag = false;
            AttachmentTriggerHelper.previousDeploymentId = null;
            AttachmentTriggerHelper.stepIds = new Set<Id>();
            AttachmentTriggerHelper.stepIdsForManual = new Set<Id>();
            AttachmentTriggerHelper.duplicateControlSet = new Set<String>();
            AttachmentTriggerHelper.connectoinBehaviorIdQualityGatesMap = new Map<Id, List<Quality_Gate__c>>();

            Attachment metadataAtt = new Attachment(
                Name = 'MetaData',
                Body = Blob.valueOf(
                    '[{"t":"ApexClass","n":"DeleteTHIS","b":"Umit Can Uckan","d":"2019-08-07","cb":"Umit Can Uckan","cd":"2019-08-07","r":false,"cmm":"updated","snapshotCommitId":"a0P************"}]'
                ),
                ParentId = stepItem.Id
            );

            Attachment gitPromotionAtt = new Attachment(
                Name = 'Git-Promotion.json',
                Body = Blob.valueOf(
                    '{"promotion_branch":"' +
                    stepItem.Branch__c +
                    '","flow_id":"a0A************","target_branch":"targetBranch","target_env":"a0G************","source_env":"a0G************","promoted_commits":["123456789098765432123456789"],"source_branch":"SourceBranch"}'
                ),
                ParentId = stepItem.Id
            );
            Attachment retrieveOnlyAtt = new Attachment(Name = 'RetrieveOnly.json', Body = Blob.valueOf('[]'), ParentId = stepItem.Id);

            List<Attachment> attList = new List<Attachment>{ metadataAtt, gitPromotionAtt, retrieveOnlyAtt };
            insert attList;
            Test.stopTest();

            List<Step__c> stepList = [SELECT Id, Name, Order__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :deploymentItem.Id];
            System.assertEquals(9, stepList.size(), 'Steps should not have been duplicated');
        }
    }

    @IsTest
    static void testScheduledForwardPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Promote_Change__c = true,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );

            insert userStory1;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;
            env4.Connection_Behavior__c = connectionBehaviorRecord.Id;
            update env4;

            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_PromotionSchedule ccdScheduleClass = new CCD_PromotionSchedule(1, new Set<Id>{ env1.Id });
            String strCrnExp = Datetime.now().addSeconds(5).format('s m H d M ? yyyy');
            String jobId = System.schedule(
                'ScheduleForwardPromotion ' +
                DateTime.Now() +
                '.' +
                math.mod(DateTime.now().getTime(), 1000),
                strCrnExp,
                ccdScheduleClass
            );

            List<CronTrigger> ctList = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];

            System.assertEquals(1, ctList.size());
            System.assertEquals(strCrnExp, ctList[0].CronExpression);
            Test.stopTest();
        }
    }

    @IsTest
    static void testScheduledForwardPromotionDuplicateControlHappyTest() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            ITestDefaults connectionBehaviorDefaults = new CCDFullCycleTestDefaults.ConnectionBehaviorDefaults()
                .setFieldDefaults()
                .setFieldValue(Connection_Behavior__c.SObjectType, Connection_Behavior__c.Back_Promotion_Behavior__c, 'Scheduled')
                .setDataSize(Connection_Behavior__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production Environment')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev3 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .setSObjectRelation(
                    Environment__c.SObjectType,
                    Connection_Behavior__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Environment__c.Connection_Behavior__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();
            Environment__c dev3Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) connectionBehaviorDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production Environment 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging Environment 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 Environment 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 Environment 0' {
                        dev2Environment = env;
                    }
                    when 'Dev3 Environment 0' {
                        dev3Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CCDFullCycleTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev3')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev3Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();
            Org__c dev3Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'prod 0' {
                        productionOrg = org;
                    }
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                    when 'dev2 0' {
                        dev2Org = org;
                    }
                    when 'dev3 0' {
                        dev3Org = org;
                    }
                }
            }

            Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
            if (String.isBlank(personalSetting.API_Key__c)) {
                personalSetting.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert personalSetting;
            }

            ITestDefaults seleniumSettingDefaults = new CCDFullCycleTestDefaults.SeleniumSettingDefaults()
                .setFieldDefaults()
                .setDataSize(Selenium_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.StaticCodeAnalysisSettingDefaults.class)
                .setDataSize(Static_Code_Analysis_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PipelineDefaults.class)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Static_Code_Analysis_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Static_Code_Analysis_Settings__c => 1 }
                )
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.ProjectDefaults.class)
                .setDataSize(Project__c.SObjectType, 1)
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.SeleniumTestGroupDefaults.class)
                .setDataSize(Selenium_Test_Group__c.SObjectType, 1)
                .setSObjectRelation(
                    Selenium_Test_Group__c.SObjectType,
                    Selenium_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Selenium_Test_Group__c.Selenium_Settings__c => 1 }
                )
                .setFieldValue(Selenium_Test_Group__c.SObjectType, Selenium_Test_Group__c.Environment__c, stagingEnvironment.Id)
                .includeDefaults(CCDFullCycleTestDefaults.UserStoryDefaults.class)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, stagingOrg.Id)
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment_Flow__c pipelineSetting = (Deployment_Flow__c) seleniumSettingDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            ITestDefaults pipelineConnectionDefaults = new CCDFullCycleTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev3Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev3')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'int')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .executeDML();

            ITestDefaults metadataGroupDefaults = new CCDFullCycleTestDefaults.MetadataGroupDefaults()
                .setFieldDefaults()
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'apex test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'compliance')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'selenium test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'static analysis')
                .generateDefaults()
                .executeDML();

            Static_Code_Analysis_Settings__c staticCodeAnalysisSetting = (Static_Code_Analysis_Settings__c) seleniumSettingDefaults.getTestData(
                Static_Code_Analysis_Settings__c.SObjectType
            )[0];

            Project__c project = (Project__c) seleniumSettingDefaults.getTestData(Project__c.SObjectType)[0];

            User_Story__c userStory = (User_Story__c) seleniumSettingDefaults.getTestData(User_Story__c.SObjectType)[0];

            Connection_Behavior__c connectionBehavior = (Connection_Behavior__c) connectionBehaviorDefaults.getTestData(
                Connection_Behavior__c.SObjectType
            )[0];

            Metadata_Group__c apexTest = new Metadata_Group__c();
            Metadata_Group__c compliance = new Metadata_Group__c();
            Metadata_Group__c seleniumTest = new Metadata_Group__c();
            Metadata_Group__c staticCodeAnalysis = new Metadata_Group__c();

            for (Metadata_Group__c mgItem : (List<Metadata_Group__c>) metadataGroupDefaults.getTestData(Metadata_Group__c.SObjectType)) {
                switch on mgItem.Name {
                    when 'apex test 0' {
                        apexTest = mgItem;
                    }
                    when 'compliance 0' {
                        compliance = mgItem;
                    }
                    when 'selenium test 0' {
                        seleniumTest = mgItem;
                    }
                    when 'static analysis 0' {
                        staticCodeAnalysis = mgItem;
                    }
                }
            }
            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults metadataGroupItemDefaults = new CCDFullCycleTestDefaults.MetadataGroupItemDefaults()
                .setFieldDefaults()
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Delete')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexTrigger')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Promotion')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'compliance')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Compliance Check')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'static Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Static Code Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Static_Code_Analysis_Settings__c, staticCodeAnalysisSetting.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Execution_Sequence__c, 'After')
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            ITestDefaults promotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            ITestDefaults promotion2Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, stagingOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Completed with errors')
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            UserStoryChangeEventTriggerHandler.apiKey = personalSetting.API_Key__c;
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(
                sysUser.Id,
                new Set<Id>{ dev1Environment.Id, dev2Environment.Id, dev3Environment.Id, stagingEnvironment.Id, productionEnvironment.Id }
            );
            DataBase.executeBatch(batchClass);
            Test.stopTest();
            List<Promotion__c> promotions = [
                SELECT Id, Source_Org_Credential__r.Name, Back_Promotion__c, Status__c, Destination_Org_Credential__r.Name
                FROM Promotion__c
            ];
            System.assertEquals(5, promotions.size(), 'Something is wrong on ccdCheckConnectionBehaviorAndPromote class!');
        }
    }

    @IsTest
    static void testScheduledForwardPromotionDuplicateControlUnhappyTest() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            ITestDefaults connectionBehaviorDefaults = new CCDFullCycleTestDefaults.ConnectionBehaviorDefaults()
                .setFieldDefaults()
                .setFieldValue(Connection_Behavior__c.SObjectType, Connection_Behavior__c.Back_Promotion_Behavior__c, 'Scheduled')
                .setDataSize(Connection_Behavior__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production Environment')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Integration Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev3 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .setSObjectRelation(
                    Environment__c.SObjectType,
                    Connection_Behavior__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Environment__c.Connection_Behavior__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();
            Environment__c dev3Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) connectionBehaviorDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production Environment 0' {
                        productionEnvironment = env;
                    }
                    when 'Integration Environment 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 Environment 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 Environment 0' {
                        dev2Environment = env;
                    }
                    when 'Dev3 Environment 0' {
                        dev3Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CCDFullCycleTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'int')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev3')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev3Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();
            Org__c dev3Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'prod 0' {
                        productionOrg = org;
                    }
                    when 'int 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                    when 'dev2 0' {
                        dev2Org = org;
                    }
                    when 'dev3 0' {
                        dev3Org = org;
                    }
                }
            }

            Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
            if (String.isBlank(personalSetting.API_Key__c)) {
                personalSetting.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert personalSetting;
            }

            ITestDefaults seleniumSettingDefaults = new CCDFullCycleTestDefaults.SeleniumSettingDefaults()
                .setFieldDefaults()
                .setDataSize(Selenium_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.StaticCodeAnalysisSettingDefaults.class)
                .setDataSize(Static_Code_Analysis_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PipelineDefaults.class)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Static_Code_Analysis_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Static_Code_Analysis_Settings__c => 1 }
                )
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.ProjectDefaults.class)
                .setDataSize(Project__c.SObjectType, 1)
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.SeleniumTestGroupDefaults.class)
                .setDataSize(Selenium_Test_Group__c.SObjectType, 1)
                .setSObjectRelation(
                    Selenium_Test_Group__c.SObjectType,
                    Selenium_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Selenium_Test_Group__c.Selenium_Settings__c => 1 }
                )
                .setFieldValue(Selenium_Test_Group__c.SObjectType, Selenium_Test_Group__c.Environment__c, stagingEnvironment.Id)
                .includeDefaults(CCDFullCycleTestDefaults.UserStoryDefaults.class)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, stagingOrg.Id)
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment_Flow__c pipelineSetting = (Deployment_Flow__c) seleniumSettingDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            ITestDefaults pipelineConnectionDefaults = new CCDFullCycleTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev3Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev3')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'int')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .executeDML();

            ITestDefaults metadataGroupDefaults = new CCDFullCycleTestDefaults.MetadataGroupDefaults()
                .setFieldDefaults()
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'apex test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'compliance')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'selenium test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'static analysis')
                .generateDefaults()
                .executeDML();

            Static_Code_Analysis_Settings__c staticCodeAnalysisSetting = (Static_Code_Analysis_Settings__c) seleniumSettingDefaults.getTestData(
                Static_Code_Analysis_Settings__c.SObjectType
            )[0];

            Project__c project = (Project__c) seleniumSettingDefaults.getTestData(Project__c.SObjectType)[0];

            User_Story__c userStory = (User_Story__c) seleniumSettingDefaults.getTestData(User_Story__c.SObjectType)[0];

            Connection_Behavior__c connectionBehavior = (Connection_Behavior__c) connectionBehaviorDefaults.getTestData(
                Connection_Behavior__c.SObjectType
            )[0];

            Metadata_Group__c apexTest = new Metadata_Group__c();
            Metadata_Group__c compliance = new Metadata_Group__c();
            Metadata_Group__c seleniumTest = new Metadata_Group__c();
            Metadata_Group__c staticCodeAnalysis = new Metadata_Group__c();

            for (Metadata_Group__c mgItem : (List<Metadata_Group__c>) metadataGroupDefaults.getTestData(Metadata_Group__c.SObjectType)) {
                switch on mgItem.Name {
                    when 'apex test 0' {
                        apexTest = mgItem;
                    }
                    when 'compliance 0' {
                        compliance = mgItem;
                    }
                    when 'selenium test 0' {
                        seleniumTest = mgItem;
                    }
                    when 'static analysis 0' {
                        staticCodeAnalysis = mgItem;
                    }
                }
            }
            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults metadataGroupItemDefaults = new CCDFullCycleTestDefaults.MetadataGroupItemDefaults()
                .setFieldDefaults()
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Delete')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexTrigger')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Promotion')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'compliance')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Compliance Check')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'static Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Static Code Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Static_Code_Analysis_Settings__c, staticCodeAnalysisSetting.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            ITestDefaults promotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            ITestDefaults promotion2Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, stagingOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Status__c, 'Merge Conflict')
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            UserStoryChangeEventTriggerHandler.apiKey = personalSetting.API_Key__c;
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(
                sysUser.Id,
                new Set<Id>{ dev1Environment.Id, dev2Environment.Id, dev3Environment.Id, stagingEnvironment.Id, productionEnvironment.Id }
            );
            DataBase.executeBatch(batchClass);
            Test.stopTest();
            List<Promotion__c> promotions = [
                SELECT Id, Source_Org_Credential__r.Name, Back_Promotion__c, Status__c, Destination_Org_Credential__r.Name
                FROM Promotion__c
            ];
            System.assertEquals(4, promotions.size(), 'Something is wrong on ccdCheckConnectionBehaviorAndPromote class!');
        }
    }

    @IsTest
    static void testManualAndAutomatedBackPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Test.enableChangeDataCapture();

            Promotion__c promotion = new Promotion__c(Project__c = testProject.Id);
            promotion.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion.Status__c = 'Draft';
            promotion.Release__c = testRelease.Id;
            promotion.Source_Org_Credential__c = devOrg1.Id;
            promotion.Source_Environment__c = env1.Id;
            promotion.Send_Deployment_Complete_email__c = true;
            insert promotion;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (User_Story__c us : usList) {
                Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                pus.Name = 'Promoted User Story: ' + us.Name;
                pusList.add(pus);
            }
            insert pusList;
            Test.getEventBus().deliver();

            promotion.Status__c = 'Completed';
            update promotion;

            Test.getEventBus().deliver();

            List<Promotion__c> backPromotionList = [SELECT Id, Name FROM Promotion__c WHERE Back_Promotion__c = true];

            System.assertEquals(2, backPromotionList.size());
        }
    }

    @IsTest
    static void testScheduledBackPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = false;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;
            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion = new Promotion__c(Project__c = testProject.Id);
            promotion.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion.Back_Promotion__c = false;
            promotion.Status__c = 'Completed';
            promotion.Release__c = testRelease.Id;
            promotion.Source_Org_Credential__c = devOrg1.Id;
            promotion.Source_Environment__c = env1.Id;
            promotion.Send_Deployment_Complete_email__c = true;
            insert promotion;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (User_Story__c us : usList) {
                Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                pus.Name = 'Promoted User Story: ' + us.Name;
                pusList.add(pus);
            }
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;

            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            String strCrnExp = Datetime.now().addSeconds(5).format('s m H d M ? yyyy');
            String jobId = System.schedule(
                'ScheduleBackPromotion ' +
                DateTime.Now() +
                '.' +
                math.mod(DateTime.now().getTime(), 1000),
                strCrnExp,
                ccdScheduleClass
            );

            List<CronTrigger> ctList = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];

            System.assertEquals(1, ctList.size());
            System.assertEquals(strCrnExp, ctList[0].CronExpression);
            Test.stopTest();
        }
    }

    @IsTest
    static void testManualAndAutomatedForwardPromotion_WithoutCCD() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Test.enableChangeDataCapture();

            for (User_Story__c usItem : usList) {
                usItem.Promote_Change__c = true;
                usItem.Exclude_From_CBM__c = false;
                usItem.Status__c = 'Ready for Testing';
            }
            update usList;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name
                FROM Promotion__c
            ];

            System.assertEquals(0, promoResult.size());
        }
    }

    @IsTest
    static void testManualAndAutomatedBackPromotion_WithoutCCD() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            Promotion__c promotion = new Promotion__c(Project__c = testProject.Id);
            promotion.Status__c = 'Draft';
            promotion.Release__c = testRelease.Id;
            promotion.Source_Org_Credential__c = devOrg1.Id;
            promotion.Source_Environment__c = env1.Id;
            promotion.Send_Deployment_Complete_email__c = true;
            insert promotion;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (User_Story__c us : usList) {
                Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                pus.Name = 'Promoted User Story: ' + us.Name;
                pusList.add(pus);
            }
            insert pusList;
            Test.startTest();
            promotion.Status__c = 'Completed';
            update promotion;
            List<Promotion__c> backPromotionList = [SELECT Id, Name FROM Promotion__c WHERE Back_Promotion__c = true];
            System.assertEquals(0, backPromotionList.size());
            Test.stopTest();
        }
    }

    @IsTest
    static void testManualwithoutPromotionOnDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Manual', '', scaSettings.Id);

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            Quality_Gate__c qgItem = [SELECT Selenium_Test_Group__c FROM Quality_Gate__c WHERE Type__c = 'Selenium Test' LIMIT 1];
            qgItem.Selenium_Test_Group__c = stgItem.Id;
            update qgItem;

            Deployment__c deploymentItem = new Deployment__c(
                Name = 'Test Manual',
                Send_Deployment_Complete_email__c = true,
                From_Org__c = devOrg1.Id,
                Status__c = 'Draft'
            );
            insert deploymentItem;

            Destination_Org__c destOrg = new Destination_Org__c(Deployment__c = deploymentItem.Id, To_Org__c = intOrg.Id);
            insert destOrg;

            Step__c stepItem = new Step__c(
                Name = 'Git Metadata ',
                Type__c = 'Git Metadata',
                CheckOnly__c = false,
                Order__c = 1,
                dataJson__c = '{"testLevel":"NoTestRun"}',
                Deployment__c = deploymentItem.Id
            );
            insert stepItem;

            Test.startTest();
            Attachment metadataAtt = new Attachment(
                Name = 'MetaData',
                Body = Blob.valueOf(
                    '[{"t":"ApexClass","n":"DeleteTHIS","b":"Umit Can Uckan","d":"2019-08-07","cb":"Umit Can Uckan","cd":"2019-08-07","r":false,"cmm":"updated","snapshotCommitId":"a0P************"}]'
                ),
                ParentId = stepItem.Id
            );
            insert metadataAtt;

            List<Step__c> stepList = [SELECT Id, Name, Order__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :deploymentItem.Id];

            System.assertEquals(8, stepList.size());
            Test.stopTest();
        }
    }

    // If you check Ready to promote and Promote and deploy checkbox at same time it was creating two promotions.
    @IsTest
    static void testAutomatedPromoteAndDeployUserStories() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory1.Promote_Change__c = true;
            userStory1.Promote_and_Deploy__c = true;
            update userStory1;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [SELECT Id, Name FROM Promotion__c];
            System.assertEquals(1, promoResult.size());

            List<Promoted_User_Story__c> pus = [
                SELECT Id, Name, User_Story__r.Name
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promoResult[0].Id
            ];
            System.assertEquals(1, pus.size());

            Test.stopTest();
        }
    }

    // checks the user status update from related connection behavior if the Story_Status_After_Deployment__c is not empty
    @IsTest
    static void testUserStoryStatusChangeAfterSuccessfulDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            connectionBehaviorRecord.Story_Status_After_Deployment__c = 'Completed';
            update connectionBehaviorRecord;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory1.Promote_Change__c = true;
            update userStory1;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [SELECT Id, Name, Status__c, Source_Org_Credential__c FROM Promotion__c];
            System.assertEquals(1, promoResult.size());

            List<Promoted_User_Story__c> pus = [
                SELECT Id, Name, User_Story__r.Name
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promoResult[0].Id
            ];
            System.assertEquals(1, pus.size());

            promoResult[0].Status__c = 'Completed';
            update promoResult;

            //Previous value
            System.assertEquals('Ready for Testing', userStory1.Status__c);
            //new value after a successful deployment
            System.assertEquals('Completed', [SELECT Id, Name, Status__c FROM User_Story__c WHERE Id = :userStory1.Id LIMIT 1].Status__c);

            Test.stopTest();
        }
    }

    // Auto back promotion with release field populated at user story.
    @IsTest
    static void testAutomatedBackPromotionWithRelease() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Release__c = testRelease.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            testPromotion.Release__c = testRelease.Id;
            testPromotion.Source_Org_Credential__c = devOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = true;
            testPromotion.Status__c = 'In Progress';
            insert testPromotion;

            Promoted_User_Story__c testPus = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
            insert testPus;

            Deployment__c testDeployment = new Deployment__c();
            testDeployment.Name = 'test deployment';
            testDeployment.Date__c = System.today();
            testDeployment.From_Org__c = devOrg1.Id;
            testDeployment.Status__c = 'Completed';
            testDeployment.Promotion__c = testPromotion.Id;
            insert testDeployment;

            Destination_Org__c testDestOrg = new Destination_Org__c();
            testDestOrg.Deployment__c = testDeployment.Id;
            testDestOrg.Status__c = 'Completed';
            testDestOrg.To_Org__c = devOrg1.Id;
            insert testDestOrg;

            Step__c testStep = new Step__c();
            testStep.Name = 'test step';
            testStep.dataJson__c = 'test';
            testStep.Deployment__c = testDeployment.Id;
            testStep.Order__c = 1;
            testStep.Status__c = 'Completed';
            testStep.Type__c = 'Git Promotion';
            insert testStep;

            Deployment_Job__c testDeploymentJob = new Deployment_Job__c();
            testDeploymentJob.Deployed__c = 1;
            testDeploymentJob.Destination_Org__c = testDestOrg.Id;
            testDeploymentJob.Status__c = 'Completed';
            testDeploymentJob.Step__c = testStep.Id;
            insert testDeploymentJob;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            testPromotion.Status__c = 'Completed';
            update testPromotion;

            Test.getEventBus().deliver();

            // Two back promotions will be created and one with the one normal promotion
            List<Promotion__c> promoResult = [SELECT Id, Name, Back_Promotion__c FROM Promotion__c];
            System.assertEquals(3, promoResult.size());

            // Two back promoted user stories will be created and one with the one normal promoted user story
            List<Promoted_User_Story__c> pus = [SELECT Id, Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE User_Story__c = :userStory1.Id];
            System.assertEquals(3, pus.size());

            Test.stopTest();
        }
    }

    @IsTest
    static void testScheduleDuplicatePusCreation() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            User_Story__c userStory3 = new User_Story__c(
                User_Story_Title__c = '3. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2, userStory3 };
            insert usList;

            Promotion__c completedForwardPromotion1 = new Promotion__c(
                Source_Environment__c = env1.Id,
                Source_Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion1;

            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = completedForwardPromotion1.Id);

            Promotion__c completedForwardPromotion2 = new Promotion__c(
                Source_Environment__c = env2.Id,
                Source_Org_Credential__c = devOrg2.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion2;

            Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = completedForwardPromotion2.Id);

            Promotion__c completedForwardPromotion3 = new Promotion__c(
                Source_Environment__c = env3.Id,
                Source_Org_Credential__c = devOrg3.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion3;
            Promoted_User_Story__c pus3 = new Promoted_User_Story__c(User_Story__c = userStory3.Id, Promotion__c = completedForwardPromotion3.Id);
            insert new List<Promoted_User_Story__c>{ pus1, pus2, pus3 };

            Promotion__c completedBackPromotion = new Promotion__c(
                Destination_Environment__c = env2.Id,
                Destination_Org_Credential__c = devOrg2.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed',
                Back_Promotion__c = true
            );
            insert completedBackPromotion;
            Promoted_User_Story__c pus4 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = completedBackPromotion.Id);
            insert pus4;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Test.startTest();

            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;

            CCD_BackPromotionBatch obj = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(obj);

            Test.stopTest();

            List<Promotion__c> promotions = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name,
                    (SELECT Name, User_Story__c FROM Promoted_User_Stories__r)
                FROM Promotion__c
                WHERE
                    Id != :completedForwardPromotion1.Id
                    AND Id != :completedForwardPromotion2.Id
                    AND Id != :completedForwardPromotion3.Id
                    AND Id != :completedBackPromotion.Id
            ];

            System.assertEquals(3, promotions.size());
            Integer totalPusCount = 0;
            for (Promotion__c promotion : promotions) {
                totalPusCount += promotion.Promoted_User_Stories__r.size();
            }
            //should be 5 instead of 6 since we already back promoted one of the user stories manually
            System.assertEquals(5, totalPusCount);
            Map<Id, Deployment__c> deployments = new Map<Id, Deployment__c>(
                [
                    SELECT Id, Name
                    FROM Deployment__c
                    WHERE
                        Promotion__c != :completedForwardPromotion1.Id
                        AND Promotion__c != :completedForwardPromotion2.Id
                        AND Promotion__c != :completedForwardPromotion3.Id
                        AND Promotion__c != :completedBackPromotion.Id
                ]
            );

            System.assertEquals(1, deployments.size());
            List<Step__c> steps = [SELECT Id, Name, dataJson__c FROM Step__c WHERE Deployment__c IN :deployments.keyset()];

            System.assertEquals(3, steps.size());
        }
    }

    @IsTest
    static void testScheduledDuplicatePusCreationPlusExcludeFromCBM() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            User_Story__c userStory3 = new User_Story__c(
                User_Story_Title__c = '3. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2, userStory3 };
            insert usList;

            Promotion__c completedForwardPromotion1 = new Promotion__c(
                Source_Environment__c = env1.Id,
                Source_Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion1;

            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = completedForwardPromotion1.Id);

            Promotion__c completedForwardPromotion2 = new Promotion__c(
                Source_Environment__c = env2.Id,
                Source_Org_Credential__c = devOrg2.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion2;

            Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = completedForwardPromotion2.Id);

            Promotion__c completedForwardPromotion3 = new Promotion__c(
                Source_Environment__c = env3.Id,
                Source_Org_Credential__c = devOrg3.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            insert completedForwardPromotion3;
            Promoted_User_Story__c pus3 = new Promoted_User_Story__c(User_Story__c = userStory3.Id, Promotion__c = completedForwardPromotion3.Id);
            insert new List<Promoted_User_Story__c>{ pus1, pus2, pus3 };

            Promotion__c completedBackPromotion = new Promotion__c(
                Destination_Environment__c = env2.Id,
                Destination_Org_Credential__c = devOrg2.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed',
                Back_Promotion__c = true
            );
            insert completedBackPromotion;
            Promoted_User_Story__c pus4 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = completedBackPromotion.Id);
            insert pus4;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Test.startTest();

            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;

            userStory2.Exclude_From_CBM__c = true;
            update userStory2;

            CCD_BackPromotionBatch obj = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(obj);

            Test.stopTest();

            List<Promotion__c> promotions = [
                SELECT
                    Id,
                    Name,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Source_Org_Credential__c,
                    Destination_Environment__c,
                    Destination_Org_Credential__c,
                    Back_Promotion__c,
                    Source_Environment__r.Name,
                    Destination_Environment__r.Name,
                    (SELECT Name, User_Story__c FROM Promoted_User_Stories__r)
                FROM Promotion__c
                WHERE
                    Id != :completedForwardPromotion1.Id
                    AND Id != :completedForwardPromotion2.Id
                    AND Id != :completedForwardPromotion3.Id
                    AND Id != :completedBackPromotion.Id
            ];

            System.assertEquals(3, promotions.size());
            Integer totalPusCount = 0;
            for (Promotion__c promotion : promotions) {
                totalPusCount += promotion.Promoted_User_Stories__r.size();
            }
            //should be 3 instead of 5 since we already back promoted one of the user stories manually plus Excluded 1 User Story from cbm
            System.assertEquals(3, totalPusCount);
            Map<Id, Deployment__c> deployments = new Map<Id, Deployment__c>(
                [
                    SELECT Id, Name
                    FROM Deployment__c
                    WHERE
                        Promotion__c != :completedForwardPromotion1.Id
                        AND Promotion__c != :completedForwardPromotion2.Id
                        AND Promotion__c != :completedForwardPromotion3.Id
                        AND Promotion__c != :completedBackPromotion.Id
                ]
            );

            System.assertEquals(1, deployments.size());
            List<Step__c> steps = [SELECT Id, Name, dataJson__c FROM Step__c WHERE Deployment__c IN :deployments.keyset()];

            System.assertEquals(3, steps.size());
        }
    }

    @IsTest
    static void testEmptyPromotionCreationOnBackPromotionSchedule() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Project__c = testProject.Id,
                Promote_Change__c = true,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );

            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Project__c = testProject.Id,
                Promote_Change__c = true,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );

            User_Story__c userStory3 = new User_Story__c(
                User_Story_Title__c = '3. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Project__c = testProject.Id,
                Promote_Change__c = true,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );

            User_Story__c userStory4 = new User_Story__c(
                User_Story_Title__c = '4. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Project__c = testProject.Id,
                Promote_Change__c = true,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );

            insert new List<User_Story__c>{ userStory1, userStory2, userStory3, userStory4 };
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;
            Promotion__c completedForwardPromotion1 = new Promotion__c(
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Source_Environment__c = env1.Id,
                Source_Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            Promotion__c completedForwardPromotion2 = new Promotion__c(
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Source_Environment__c = env1.Id,
                Source_Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            Promotion__c completedForwardPromotion3 = new Promotion__c(
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Source_Environment__c = env2.Id,
                Source_Org_Credential__c = devOrg2.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );
            Promotion__c completedForwardPromotion4 = new Promotion__c(
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Source_Environment__c = env4.Id,
                Source_Org_Credential__c = intOrg.Id,
                Project__c = testProject.Id,
                Status__c = 'Completed'
            );

            insert new List<Promotion__c>{
                completedForwardPromotion1,
                completedForwardPromotion2,
                completedForwardPromotion3,
                completedForwardPromotion4
            };
            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = completedForwardPromotion1.Id);
            Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = completedForwardPromotion2.Id);
            Promoted_User_Story__c pus3 = new Promoted_User_Story__c(User_Story__c = userStory3.Id, Promotion__c = completedForwardPromotion3.Id);
            Promoted_User_Story__c pus4 = new Promoted_User_Story__c(User_Story__c = userStory4.Id, Promotion__c = completedForwardPromotion4.Id);
            insert new List<Promoted_User_Story__c>{ pus1, pus2, pus3, pus4 };

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            env4.Connection_Behavior__c = connectionBehaviorRecord.Id;
            update env4;

            connectionBehaviorRecord.Max_Scheduled_Back_Promotion_Batch_Size__c = 10;
            update connectionBehaviorRecord;

            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_PromotionSchedule ccdScheduleClass = new CCD_PromotionSchedule(1, new Set<Id>{ env1.Id });

            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env1.Id, env2.Id, env3.Id, env4.Id, env5.Id });
            DataBase.executeBatch(batchClass);
            Test.stopTest();
            List<Promotion__c> promotions = [
                SELECT
                    Id,
                    Source_Org_Credential__r.Name,
                    Back_Promotion__c,
                    Status__c,
                    Destination_Org_Credential__r.Name,
                    (SELECT Id FROM Promoted_User_Stories__r)
                FROM Promotion__c
            ];
            for (Promotion__c promotion : promotions) {
                System.assertNotEquals(
                    0,
                    promotion.Promoted_User_Stories__r.size(),
                    'Something is wrong on PromotionChangeEventTriggerHandler class!'
                );
            }
            // 4 previously create promotions +
            // 1 to dev1 with 2 pus
            // 1 to dev2 with 2 pus
            // 1 to dev3 with 4 pus
            // makes 7 in total
            System.assertEquals(7, promotions.size(), 'Something is wrong on ccdCheckConnectionBehaviorAndPromote class!');
        }
    }

    @IsTest
    static void testScheduledBackPromotionDuplicatePrevention() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion1 = new Promotion__c(Project__c = testProject.Id);
            promotion1.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion1.Back_Promotion__c = false;
            promotion1.Status__c = 'Completed';
            promotion1.Release__c = testRelease.Id;
            promotion1.Source_Org_Credential__c = devOrg1.Id;
            promotion1.Source_Environment__c = env1.Id;
            promotion1.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion2 = new Promotion__c(Project__c = testProject.Id);
            promotion2.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion2.Back_Promotion__c = false;
            promotion2.Status__c = 'Completed';
            promotion2.Release__c = testRelease.Id;
            promotion2.Source_Org_Credential__c = devOrg1.Id;
            promotion2.Source_Environment__c = env1.Id;
            promotion2.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion3 = new Promotion__c(Project__c = testProject.Id);
            promotion3.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion3.Back_Promotion__c = false;
            promotion3.Status__c = 'Completed';
            promotion3.Release__c = testRelease.Id;
            promotion3.Source_Org_Credential__c = devOrg1.Id;
            promotion3.Source_Environment__c = env1.Id;
            promotion3.Send_Deployment_Complete_email__c = true;
            List<Promotion__c> promotions = new List<Promotion__c>{ promotion1, promotion2, promotion3 };
            insert promotions;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (Promotion__c promotion : promotions) {
                for (User_Story__c us : usList) {
                    Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                    pus.Name = 'Promoted User Story: ' + us.Name;
                    pusList.add(pus);
                }
            }
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(batchClass);
            List<Promotion__c> promotionsBeforeCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(3, promotionsBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            Test.stopTest();

            List<Promotion__c> promotionsAfterCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(5, promotionsAfterCCDWorks.size(), 'Something is wrong is PromotionChangeEventTriggerHandler!');
        }
    }

    @IsTest
    static void testTwoUserStoriesWithBackPromotionCriteriaAtConnectionBehaviorForScheduled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            connectionBehaviorRecord.Back_Promotion_Criteria__c = 'User_Story_Title__c = \'1. User Story for back Promotion Automated CCD test\' OR User_Story_Title__c = \'2. User Story for back Promotion Automated CCD test\'';
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion1 = new Promotion__c(Project__c = testProject.Id);
            promotion1.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion1.Back_Promotion__c = false;
            promotion1.Status__c = 'Completed';
            promotion1.Release__c = testRelease.Id;
            promotion1.Source_Org_Credential__c = devOrg1.Id;
            promotion1.Source_Environment__c = env1.Id;
            promotion1.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion2 = new Promotion__c(Project__c = testProject.Id);
            promotion2.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion2.Back_Promotion__c = false;
            promotion2.Status__c = 'Completed';
            promotion2.Release__c = testRelease.Id;
            promotion2.Source_Org_Credential__c = devOrg1.Id;
            promotion2.Source_Environment__c = env1.Id;
            promotion2.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion3 = new Promotion__c(Project__c = testProject.Id);
            promotion3.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion3.Back_Promotion__c = false;
            promotion3.Status__c = 'Completed';
            promotion3.Release__c = testRelease.Id;
            promotion3.Source_Org_Credential__c = devOrg1.Id;
            promotion3.Source_Environment__c = env1.Id;
            promotion3.Send_Deployment_Complete_email__c = true;
            List<Promotion__c> promotions = new List<Promotion__c>{ promotion1, promotion2, promotion3 };
            insert promotions;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (Promotion__c promotion : promotions) {
                for (User_Story__c us : usList) {
                    Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                    pus.Name = 'Promoted User Story: ' + us.Name;
                    pusList.add(pus);
                }
            }
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(batchClass);
            List<Promotion__c> promotionsBeforeCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(3, promotionsBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            List<Promoted_User_Story__c> promotedUserStoriesBeforeCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            System.assertEquals(6, promotedUserStoriesBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            Test.stopTest();

            List<Promotion__c> promotionsAfterCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(5, promotionsAfterCCDWorks.size(), 'Something is wrong is PromotionChangeEventTriggerHandler!');
            List<Promoted_User_Story__c> promotedUserStoriesAfterCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            // both user story included in 2 different promotions so number increased 4
            System.assertEquals(10, promotedUserStoriesAfterCCDWorks.size(), 'Something is wrong is your test setup!');
        }
    }

    @IsTest
    static void testOneUserStoriesWithBackPromotionCriteriaAtConnectionBehaviorForScheduled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            connectionBehaviorRecord.Back_Promotion_Criteria__c = 'User_Story_Title__c = \'1. User Story for back Promotion Automated CCD test\'';
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion1 = new Promotion__c(Project__c = testProject.Id);
            promotion1.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion1.Back_Promotion__c = false;
            promotion1.Status__c = 'Completed';
            promotion1.Release__c = testRelease.Id;
            promotion1.Source_Org_Credential__c = devOrg1.Id;
            promotion1.Source_Environment__c = env1.Id;
            promotion1.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion2 = new Promotion__c(Project__c = testProject.Id);
            promotion2.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion2.Back_Promotion__c = false;
            promotion2.Status__c = 'Completed';
            promotion2.Release__c = testRelease.Id;
            promotion2.Source_Org_Credential__c = devOrg1.Id;
            promotion2.Source_Environment__c = env1.Id;
            promotion2.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion3 = new Promotion__c(Project__c = testProject.Id);
            promotion3.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion3.Back_Promotion__c = false;
            promotion3.Status__c = 'Completed';
            promotion3.Release__c = testRelease.Id;
            promotion3.Source_Org_Credential__c = devOrg1.Id;
            promotion3.Source_Environment__c = env1.Id;
            promotion3.Send_Deployment_Complete_email__c = true;
            List<Promotion__c> promotions = new List<Promotion__c>{ promotion1, promotion2, promotion3 };
            insert promotions;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (Promotion__c promotion : promotions) {
                for (User_Story__c us : usList) {
                    Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                    pus.Name = 'Promoted User Story: ' + us.Name;
                    pusList.add(pus);
                }
            }
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(batchClass);
            List<Promotion__c> promotionsBeforeCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(3, promotionsBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            List<Promoted_User_Story__c> promotedUserStoriesBeforeCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            System.assertEquals(6, promotedUserStoriesBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            Test.stopTest();

            List<Promotion__c> promotionsAfterCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(5, promotionsAfterCCDWorks.size(), 'Something is wrong is PromotionChangeEventTriggerHandler!');
            List<Promoted_User_Story__c> promotedUserStoriesAfterCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            // only one user story included in 2 different promotions so number increased 2
            System.assertEquals(8, promotedUserStoriesAfterCCDWorks.size(), 'Something is wrong is your test setup!');
        }
    }

    @IsTest
    static void testZeroUserStoriesWithBackPromotionCriteriaAtConnectionBehaviorForScheduled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');
            connectionBehaviorRecord.Execute_promotions_in_parallel__c = true;
            connectionBehaviorRecord.Execute_back_promotions_in_parallel__c = false;
            connectionBehaviorRecord.Back_Promotion_Criteria__c = 'User_Story_Title__c = \'No user story\'';
            update connectionBehaviorRecord;

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Release__c = testRelease.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion1 = new Promotion__c(Project__c = testProject.Id);
            promotion1.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion1.Back_Promotion__c = false;
            promotion1.Status__c = 'Completed';
            promotion1.Release__c = testRelease.Id;
            promotion1.Source_Org_Credential__c = devOrg1.Id;
            promotion1.Source_Environment__c = env1.Id;
            promotion1.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion2 = new Promotion__c(Project__c = testProject.Id);
            promotion2.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion2.Back_Promotion__c = false;
            promotion2.Status__c = 'Completed';
            promotion2.Release__c = testRelease.Id;
            promotion2.Source_Org_Credential__c = devOrg1.Id;
            promotion2.Source_Environment__c = env1.Id;
            promotion2.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion3 = new Promotion__c(Project__c = testProject.Id);
            promotion3.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion3.Back_Promotion__c = false;
            promotion3.Status__c = 'Completed';
            promotion3.Release__c = testRelease.Id;
            promotion3.Source_Org_Credential__c = devOrg1.Id;
            promotion3.Source_Environment__c = env1.Id;
            promotion3.Send_Deployment_Complete_email__c = true;
            List<Promotion__c> promotions = new List<Promotion__c>{ promotion1, promotion2, promotion3 };
            insert promotions;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (Promotion__c promotion : promotions) {
                for (User_Story__c us : usList) {
                    Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotion.Id);
                    pus.Name = 'Promoted User Story: ' + us.Name;
                    pusList.add(pus);
                }
            }
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(batchClass);
            List<Promotion__c> promotionsBeforeCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(3, promotionsBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            List<Promoted_User_Story__c> promotedUserStoriesBeforeCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            System.assertEquals(6, promotedUserStoriesBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            Test.stopTest();

            List<Promotion__c> promotionsAfterCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(3, promotionsAfterCCDWorks.size(), 'Something is wrong is PromotionChangeEventTriggerHandler!');
            List<Promoted_User_Story__c> promotedUserStoriesAfterCCDWorks = [SELECT Id FROM Promoted_User_Story__c];
            // none of the user story included will be promoted
            System.assertEquals(6, promotedUserStoriesAfterCCDWorks.size(), 'Something is wrong is your test setup!');
        }
    }

    @IsTest
    static void testOneUserStoriesWithBackPromotionCriteriaAtConnectionBehaviorForAutomated() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            connectionBehaviorRecord.Back_Promotion_Criteria__c = 'User_Story_Title__c = \'1. User Story for forward Promotion Automated CCD test\'';
            update connectionBehaviorRecord;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Release__c = testRelease.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            testPromotion.Release__c = testRelease.Id;
            testPromotion.Source_Org_Credential__c = devOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = true;
            testPromotion.Status__c = 'In Progress';
            insert testPromotion;

            Promoted_User_Story__c testPus = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
            insert testPus;

            Deployment__c testDeployment = new Deployment__c();
            testDeployment.Name = 'test deployment';
            testDeployment.Date__c = System.today();
            testDeployment.From_Org__c = devOrg1.Id;
            testDeployment.Status__c = 'Completed';
            testDeployment.Promotion__c = testPromotion.Id;
            insert testDeployment;

            Destination_Org__c testDestOrg = new Destination_Org__c();
            testDestOrg.Deployment__c = testDeployment.Id;
            testDestOrg.Status__c = 'Completed';
            testDestOrg.To_Org__c = devOrg1.Id;
            insert testDestOrg;

            Step__c testStep = new Step__c();
            testStep.Name = 'test step';
            testStep.dataJson__c = 'test';
            testStep.Deployment__c = testDeployment.Id;
            testStep.Order__c = 1;
            testStep.Status__c = 'Completed';
            testStep.Type__c = 'Git Promotion';
            insert testStep;

            Deployment_Job__c testDeploymentJob = new Deployment_Job__c();
            testDeploymentJob.Deployed__c = 1;
            testDeploymentJob.Destination_Org__c = testDestOrg.Id;
            testDeploymentJob.Status__c = 'Completed';
            testDeploymentJob.Step__c = testStep.Id;
            insert testDeploymentJob;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            testPromotion.Status__c = 'Completed';
            update testPromotion;

            Test.getEventBus().deliver();

            // Two back promotions will be created and one with the one normal promotion
            List<Promotion__c> promoResult = [SELECT Id, Name, Back_Promotion__c FROM Promotion__c];
            System.assertEquals(3, promoResult.size());

            // Two back promoted user stories will be created and one with the one normal promoted user story
            List<Promoted_User_Story__c> pus = [SELECT Id, Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE User_Story__c = :userStory1.Id];
            System.assertEquals(3, pus.size());

            Test.stopTest();
        }
    }

    @IsTest
    static void testZeroUserStoriesWithBackPromotionCriteriaAtConnectionBehaviorForAutomated() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Release__c testRelease = CMTestMethodUtilities.createRelease('test release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            connectionBehaviorRecord.Back_Promotion_Criteria__c = 'User_Story_Title__c = \'no user story\'';
            update connectionBehaviorRecord;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env4.Id,
                Org_Credential__c = intOrg.Id,
                Release__c = testRelease.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            testPromotion.Release__c = testRelease.Id;
            testPromotion.Source_Org_Credential__c = devOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = true;
            testPromotion.Status__c = 'In Progress';
            insert testPromotion;

            Promoted_User_Story__c testPus = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
            insert testPus;

            Deployment__c testDeployment = new Deployment__c();
            testDeployment.Name = 'test deployment';
            testDeployment.Date__c = System.today();
            testDeployment.From_Org__c = devOrg1.Id;
            testDeployment.Status__c = 'Completed';
            testDeployment.Promotion__c = testPromotion.Id;
            insert testDeployment;

            Destination_Org__c testDestOrg = new Destination_Org__c();
            testDestOrg.Deployment__c = testDeployment.Id;
            testDestOrg.Status__c = 'Completed';
            testDestOrg.To_Org__c = devOrg1.Id;
            insert testDestOrg;

            Step__c testStep = new Step__c();
            testStep.Name = 'test step';
            testStep.dataJson__c = 'test';
            testStep.Deployment__c = testDeployment.Id;
            testStep.Order__c = 1;
            testStep.Status__c = 'Completed';
            testStep.Type__c = 'Git Promotion';
            insert testStep;

            Deployment_Job__c testDeploymentJob = new Deployment_Job__c();
            testDeploymentJob.Deployed__c = 1;
            testDeploymentJob.Destination_Org__c = testDestOrg.Id;
            testDeploymentJob.Status__c = 'Completed';
            testDeploymentJob.Step__c = testStep.Id;
            insert testDeploymentJob;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            testPromotion.Status__c = 'Completed';
            update testPromotion;

            Test.getEventBus().deliver();

            // no extra promotion will be created
            List<Promotion__c> promoResult = [SELECT Id, Name, Back_Promotion__c FROM Promotion__c];
            System.assertEquals(1, promoResult.size());

            // no extra promoted user story will be created
            List<Promoted_User_Story__c> pus = [SELECT Id, Name, User_Story__r.Name FROM Promoted_User_Story__c WHERE User_Story__c = :userStory1.Id];
            System.assertEquals(1, pus.size());

            Test.stopTest();
        }
    }

    @IsTest
    static void testScheduledBackPromotionWithDifferentProjects() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }
            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Scheduled', '');

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            List<Project__c> testProjects = new List<Project__c>{
                CMTestMethodUtilities.createProject('test project'),
                CMTestMethodUtilities.createProject('test project2')
            };
            Project__c testProject = testProjects[0];
            Project__c testProject2 = testProjects[1];
            testProject.Deployment_Flow__c = flowCBM.Id;
            testProject2.Deployment_Flow__c = flowCBM.Id;
            insert testProjects;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Type__c = 'Sandbox',
                Connection_Behavior__c = connectionBehaviorRecord.Id
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id
            );
            User_Story__c userStory2 = new User_Story__c(
                User_Story_Title__c = '2. User Story for back Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject2.Id
            );
            List<User_Story__c> usList = new List<User_Story__c>{ userStory1, userStory2 };
            insert usList;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));

            Promotion__c promotion1 = new Promotion__c(Project__c = testProject.Id);
            promotion1.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion1.Back_Promotion__c = false;
            promotion1.Status__c = 'Completed';
            promotion1.Source_Org_Credential__c = devOrg1.Id;
            promotion1.Source_Environment__c = env1.Id;
            promotion1.Send_Deployment_Complete_email__c = true;

            Promotion__c promotion2 = new Promotion__c(Project__c = testProject2.Id);
            promotion2.Connection_Behavior__c = connectionBehaviorRecord.Id;
            promotion2.Back_Promotion__c = false;
            promotion2.Status__c = 'Completed';
            promotion2.Source_Org_Credential__c = devOrg1.Id;
            promotion2.Source_Environment__c = env1.Id;
            promotion2.Send_Deployment_Complete_email__c = true;

            List<Promotion__c> promotions = new List<Promotion__c>{ promotion1, promotion2 };
            insert promotions;

            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = usList[0].Id, Promotion__c = promotions[0].Id);
            pus1.Name = 'Promoted User Story: ' + usList[0].Name;
            pusList.add(pus1);
            Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = usList[1].Id, Promotion__c = promotions[1].Id);
            pus2.Name = 'Promoted User Story: ' + usList[1].Name;
            pusList.add(pus2);
            insert pusList;

            Test.startTest();
            UserStoryChangeEventTriggerHandler.apiKey = ps.API_Key__c;
            CCD_BackPromotionSchedule ccdScheduleClass = new CCD_BackPromotionSchedule(1, new Set<Id>{ env4.Id });
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(sysUser.Id, new Set<Id>{ env4.Id });
            DataBase.executeBatch(batchClass);
            List<Promotion__c> promotionsBeforeCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(2, promotionsBeforeCCDWorks.size(), 'Something is wrong is your test setup!');
            Test.stopTest();

            List<Promotion__c> promotionsAfterCCDWorks = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(4, promotionsAfterCCDWorks.size(), 'Something is wrong is PromotionChangeEventTriggerHandler!');
        }
    }

    @IsTest
    static void testUSMovedBackToLowerEnvironmentPromotedUserStoriesOutdated() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            ITestDefaults connectionBehaviorDefaults = new CCDFullCycleTestDefaults.ConnectionBehaviorDefaults()
                .setFieldDefaults()
                .setFieldValue(Connection_Behavior__c.SObjectType, Connection_Behavior__c.Back_Promotion_Behavior__c, 'Scheduled')
                .setDataSize(Connection_Behavior__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production Environment')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev3 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();
            Environment__c dev3Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) connectionBehaviorDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production Environment 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging Environment 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 Environment 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 Environment 0' {
                        dev2Environment = env;
                    }
                    when 'Dev3 Environment 0' {
                        dev3Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CCDFullCycleTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev3')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev3Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();
            Org__c dev3Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'prod 0' {
                        productionOrg = org;
                    }
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                    when 'dev2 0' {
                        dev2Org = org;
                    }
                    when 'dev3 0' {
                        dev3Org = org;
                    }
                }
            }

            Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
            if (String.isBlank(personalSetting.API_Key__c)) {
                personalSetting.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert personalSetting;
            }

            ITestDefaults seleniumSettingDefaults = new CCDFullCycleTestDefaults.SeleniumSettingDefaults()
                .setFieldDefaults()
                .setDataSize(Selenium_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.StaticCodeAnalysisSettingDefaults.class)
                .setDataSize(Static_Code_Analysis_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PipelineDefaults.class)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Static_Code_Analysis_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Static_Code_Analysis_Settings__c => 1 }
                )
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.ProjectDefaults.class)
                .setDataSize(Project__c.SObjectType, 1)
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.SeleniumTestGroupDefaults.class)
                .setDataSize(Selenium_Test_Group__c.SObjectType, 1)
                .setSObjectRelation(
                    Selenium_Test_Group__c.SObjectType,
                    Selenium_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Selenium_Test_Group__c.Selenium_Settings__c => 1 }
                )
                .setFieldValue(Selenium_Test_Group__c.SObjectType, Selenium_Test_Group__c.Environment__c, stagingEnvironment.Id)
                .includeDefaults(CCDFullCycleTestDefaults.UserStoryDefaults.class)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, stagingOrg.Id)
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment_Flow__c pipelineSetting = (Deployment_Flow__c) seleniumSettingDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            ITestDefaults pipelineConnectionDefaults = new CCDFullCycleTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev3Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev3')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'int')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .executeDML();

            ITestDefaults metadataGroupDefaults = new CCDFullCycleTestDefaults.MetadataGroupDefaults()
                .setFieldDefaults()
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'apex test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'compliance')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'selenium test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'static analysis')
                .generateDefaults()
                .executeDML();

            Static_Code_Analysis_Settings__c staticCodeAnalysisSetting = (Static_Code_Analysis_Settings__c) seleniumSettingDefaults.getTestData(
                Static_Code_Analysis_Settings__c.SObjectType
            )[0];

            Project__c project = (Project__c) seleniumSettingDefaults.getTestData(Project__c.SObjectType)[0];

            User_Story__c userStory = (User_Story__c) seleniumSettingDefaults.getTestData(User_Story__c.SObjectType)[0];

            Connection_Behavior__c connectionBehavior = (Connection_Behavior__c) connectionBehaviorDefaults.getTestData(
                Connection_Behavior__c.SObjectType
            )[0];

            Metadata_Group__c apexTest = new Metadata_Group__c();
            Metadata_Group__c compliance = new Metadata_Group__c();
            Metadata_Group__c seleniumTest = new Metadata_Group__c();
            Metadata_Group__c staticCodeAnalysis = new Metadata_Group__c();

            for (Metadata_Group__c mgItem : (List<Metadata_Group__c>) metadataGroupDefaults.getTestData(Metadata_Group__c.SObjectType)) {
                switch on mgItem.Name {
                    when 'apex test 0' {
                        apexTest = mgItem;
                    }
                    when 'compliance 0' {
                        compliance = mgItem;
                    }
                    when 'selenium test 0' {
                        seleniumTest = mgItem;
                    }
                    when 'static analysis 0' {
                        staticCodeAnalysis = mgItem;
                    }
                }
            }
            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults metadataGroupItemDefaults = new CCDFullCycleTestDefaults.MetadataGroupItemDefaults()
                .setFieldDefaults()
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Delete')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexTrigger')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Promotion')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'compliance')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Compliance Check')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'static Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Static Code Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Static_Code_Analysis_Settings__c, staticCodeAnalysisSetting.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            stagingEnvironment.Connection_Behavior__c = connectionBehavior.Id;
            update stagingEnvironment;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            ITestDefaults promotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            UserStoryChangeEventTriggerHandler.apiKey = personalSetting.API_Key__c;
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(
                sysUser.Id,
                new Set<Id>{ dev1Environment.Id, dev2Environment.Id, dev3Environment.Id, stagingEnvironment.Id, productionEnvironment.Id }
            );
            DataBase.executeBatch(batchClass);
            Test.stopTest();
            List<Promotion__c> promotions = [
                SELECT Id, Source_Org_Credential__r.Name, Back_Promotion__c, Status__c, Destination_Org_Credential__r.Name
                FROM Promotion__c
            ];
            System.assertEquals(3, promotions.size(), 'Something is wrong on ccdCheckConnectionBehaviorAndPromote class!');
            System.assertEquals(
                3,
                [SELECT COUNT() FROM Promoted_User_Story__c WHERE Status__c = 'Active'],
                'There should be 3 promoted user stories Active'
            );
            userStory.Org_Credential__c = dev1Org.Id;
            userStory.Environment__c = dev1Environment.Id;
            update userStory;
            System.assertEquals(
                3,
                [SELECT COUNT() FROM Promoted_User_Story__c WHERE Status__c = 'Outdated'],
                'There should be 3 promoted user stories Outdated'
            );
        }
    }

    @IsTest
    static void testUSWithOutdatedPromotedUserStoriesScheduledBackPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            ITestDefaults connectionBehaviorDefaults = new CCDFullCycleTestDefaults.ConnectionBehaviorDefaults()
                .setFieldDefaults()
                .setFieldValue(Connection_Behavior__c.SObjectType, Connection_Behavior__c.Back_Promotion_Behavior__c, 'Scheduled')
                .setDataSize(Connection_Behavior__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production Environment')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev3 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();
            Environment__c dev3Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) connectionBehaviorDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production Environment 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging Environment 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 Environment 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 Environment 0' {
                        dev2Environment = env;
                    }
                    when 'Dev3 Environment 0' {
                        dev3Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CCDFullCycleTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev3')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev3Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();
            Org__c dev3Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'prod 0' {
                        productionOrg = org;
                    }
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                    when 'dev2 0' {
                        dev2Org = org;
                    }
                    when 'dev3 0' {
                        dev3Org = org;
                    }
                }
            }

            Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
            if (String.isBlank(personalSetting.API_Key__c)) {
                personalSetting.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert personalSetting;
            }

            ITestDefaults seleniumSettingDefaults = new CCDFullCycleTestDefaults.SeleniumSettingDefaults()
                .setFieldDefaults()
                .setDataSize(Selenium_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.StaticCodeAnalysisSettingDefaults.class)
                .setDataSize(Static_Code_Analysis_Settings__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PipelineDefaults.class)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Static_Code_Analysis_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Static_Code_Analysis_Settings__c => 1 }
                )
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.ProjectDefaults.class)
                .setDataSize(Project__c.SObjectType, 1)
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.SeleniumTestGroupDefaults.class)
                .setDataSize(Selenium_Test_Group__c.SObjectType, 1)
                .setSObjectRelation(
                    Selenium_Test_Group__c.SObjectType,
                    Selenium_Settings__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Selenium_Test_Group__c.Selenium_Settings__c => 1 }
                )
                .setFieldValue(Selenium_Test_Group__c.SObjectType, Selenium_Test_Group__c.Environment__c, stagingEnvironment.Id)
                .includeDefaults(CCDFullCycleTestDefaults.UserStoryDefaults.class)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, stagingOrg.Id)
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment_Flow__c pipelineSetting = (Deployment_Flow__c) seleniumSettingDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            ITestDefaults pipelineConnectionDefaults = new CCDFullCycleTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev3Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev3')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'int')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .executeDML();

            ITestDefaults metadataGroupDefaults = new CCDFullCycleTestDefaults.MetadataGroupDefaults()
                .setFieldDefaults()
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'apex test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'compliance')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'selenium test')
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.MetadataGroupDefaults.class)
                .setDataSize(Metadata_Group__c.SObjectType, 1)
                .setFieldValue(Metadata_Group__c.SObjectType, Metadata_Group__c.Name, 'static analysis')
                .generateDefaults()
                .executeDML();

            Static_Code_Analysis_Settings__c staticCodeAnalysisSetting = (Static_Code_Analysis_Settings__c) seleniumSettingDefaults.getTestData(
                Static_Code_Analysis_Settings__c.SObjectType
            )[0];

            Project__c project = (Project__c) seleniumSettingDefaults.getTestData(Project__c.SObjectType)[0];

            User_Story__c userStory = (User_Story__c) seleniumSettingDefaults.getTestData(User_Story__c.SObjectType)[0];

            Connection_Behavior__c connectionBehavior = (Connection_Behavior__c) connectionBehaviorDefaults.getTestData(
                Connection_Behavior__c.SObjectType
            )[0];

            Metadata_Group__c apexTest = new Metadata_Group__c();
            Metadata_Group__c compliance = new Metadata_Group__c();
            Metadata_Group__c seleniumTest = new Metadata_Group__c();
            Metadata_Group__c staticCodeAnalysis = new Metadata_Group__c();

            for (Metadata_Group__c mgItem : (List<Metadata_Group__c>) metadataGroupDefaults.getTestData(Metadata_Group__c.SObjectType)) {
                switch on mgItem.Name {
                    when 'apex test 0' {
                        apexTest = mgItem;
                    }
                    when 'compliance 0' {
                        compliance = mgItem;
                    }
                    when 'selenium test 0' {
                        seleniumTest = mgItem;
                    }
                    when 'static analysis 0' {
                        staticCodeAnalysis = mgItem;
                    }
                }
            }
            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults metadataGroupItemDefaults = new CCDFullCycleTestDefaults.MetadataGroupItemDefaults()
                .setFieldDefaults()
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Delete')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexTrigger')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'Contains')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, 'Promotion')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Type__c, 'ApexClass')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Operator__c, 'All')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Value__c, '')
                .setFieldValue(Metadata_Group_Item__c.SObjectType, Metadata_Group_Item__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Metadata_Group_Item__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, apexTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'compliance')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Compliance Check')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, compliance.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'selenium Test')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, seleniumTest.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'static Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Static Code Analysis')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Static_Code_Analysis_Settings__c, staticCodeAnalysisSetting.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'URL Callout')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Manual Approval')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.QualityGateDefaults.class)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Name, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Type__c, 'Pull Request')
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Quality_Gate__c.SObjectType, Quality_Gate__c.Metadata_Group__c, staticCodeAnalysis.Id)
                .setDataSize(Quality_Gate__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            stagingEnvironment.Connection_Behavior__c = connectionBehavior.Id;
            update stagingEnvironment;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok":"API Key generated","api_key":"new key value"}', null));
            Test.startTest();

            ITestDefaults promotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.Status__c, 'Outdated')
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            ITestDefaults backPromotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Back_Promotion__c, true)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, stagingOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.Status__c, 'Outdated')
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            ITestDefaults backPromotion2Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Back_Promotion__c, true)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, stagingOrg.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Org_Credential__c, dev2Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Destination_Environment__c, dev2Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.Status__c, 'Outdated')
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            ITestDefaults promotion2Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Connection_Behavior__c, connectionBehavior.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            UserStoryChangeEventTriggerHandler.apiKey = personalSetting.API_Key__c;
            CCD_BackPromotionBatch batchClass = new CCD_BackPromotionBatch(
                sysUser.Id,
                new Set<Id>{ dev1Environment.Id, dev2Environment.Id, dev3Environment.Id, stagingEnvironment.Id, productionEnvironment.Id }
            );
            DataBase.executeBatch(batchClass);
            Test.stopTest();
            List<Promotion__c> promotions = [
                SELECT Id, Source_Org_Credential__r.Name, Back_Promotion__c, Status__c, Destination_Org_Credential__r.Name
                FROM Promotion__c
            ];
            System.assertEquals(6, promotions.size(), 'Something is wrong on ccdCheckConnectionBehaviorAndPromote class!');
            System.assertEquals(
                3,
                [SELECT COUNT() FROM Promoted_User_Story__c WHERE Status__c = 'Active'],
                'There should be 3 promoted user stories Active'
            );
            System.assertEquals(
                3,
                [SELECT COUNT() FROM Promoted_User_Story__c WHERE Status__c = 'Outdated'],
                'There should be 3 promoted user stories Outdated'
            );
        }
    }

    @IsTest
    static void testOneUserStoriesWithPromotionCriteriaAtConnectionBehaviorForAutomated() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            connectionBehaviorRecord.Story_Status_After_Deployment__c = 'Completed';
            connectionBehaviorRecord.Promotion_Criteria__c = 'User_Story_Title__c = \'1. User Story for forward Promotion Automated CCD test\'';
            update connectionBehaviorRecord;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory1.Promote_Change__c = true;
            update userStory1;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [SELECT Id, Name, Status__c, Source_Org_Credential__c FROM Promotion__c];
            System.assertEquals(1, promoResult.size());

            List<Promoted_User_Story__c> pus = [
                SELECT Id, Name, User_Story__r.Name
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promoResult[0].Id
            ];
            System.assertEquals(1, pus.size());

            promoResult[0].Status__c = 'Completed';
            update promoResult;

            //Previous value
            System.assertEquals('Ready for Testing', userStory1.Status__c);
            //new value after a successful deployment
            System.assertEquals('Completed', [SELECT Id, Name, Status__c FROM User_Story__c WHERE Id = :userStory1.Id LIMIT 1].Status__c);

            Test.stopTest();
        }
    }

    @IsTest
    static void testZeroUserStoriesWithPromotionCriteriaAtConnectionBehaviorForAutomated() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Selenium_Settings__c seleniumSetting = new Selenium_Settings__c(
                Name = 'uucka Quick Test Settings',
                Provider__c = 'Custom/Other',
                Webdriver_URL__c = 'https://webdriver.copado.com',
                Selected_Platforms__c = '[copado]chrome'
            );
            insert seleniumSetting;

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
            insert gitRepo;

            Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest'
            );
            insert scaSettings;

            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            flowCBM.Static_Code_Analysis_Settings__c = scaSettings.Id;
            insert flowCBM;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;

            Connection_Behavior__c connectionBehaviorRecord = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            connectionBehaviorRecord.Story_Status_After_Deployment__c = 'Completed';
            connectionBehaviorRecord.Promotion_Criteria__c = 'User_Story_Title__c = \'no user story\'';
            update connectionBehaviorRecord;

            Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
            Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
            Environment__c env3 = new Environment__c(Name = 'Dev3 Environment', Type__c = 'Sandbox');
            Environment__c env4 = new Environment__c(
                Name = 'Integration Environment',
                Connection_Behavior__c = connectionBehaviorRecord.Id,
                Type__c = 'Sandbox'
            );
            Environment__c env5 = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
            List<Environment__c> envList = new List<Environment__c>{ env1, env2, env3, env4, env5 };
            insert envList;

            Org__c devOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_Dev1OrgId', null, null, System.now(), env1.Id);
            Org__c devOrg2 = CMTestMethodUtilities.createOrg('Dev2', 'Sandbox', 'SFDC_Dev2OrgId', null, null, System.now(), env2.Id);
            Org__c devOrg3 = CMTestMethodUtilities.createOrg('Dev3', 'Sandbox', 'SFDC_Dev3OrgId', null, null, System.now(), env3.Id);
            Org__c intOrg = CMTestMethodUtilities.createOrg('Int', 'Sandbox', 'SFDC_IntOrgId', null, null, System.now(), env4.Id);
            Org__c prodOrg = CMTestMethodUtilities.createOrg('Prod', 'Production', 'SFDC_ProdOrgId', null, null, System.now(), env5.Id);
            List<Org__c> orgList = new List<Org__c>{ devOrg1, devOrg2, devOrg3, intOrg, prodOrg };
            insert orgList;

            Selenium_Test_Group__c stgItem = new Selenium_Test_Group__c(
                Name = 'Regression Test - ' + env4.Name,
                Selenium_Settings__c = seleniumSetting.Id,
                Environment__c = env4.Id,
                Type__c = 'Regression Test',
                Description__c = 'Test Quality gate',
                Manage_Test_Runs_manually__c = false
            );
            insert stgItem;

            Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(env1.Id, env4.Id, flowCBM.Id);
            dfs1.Branch__c = 'dev1';

            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env4.Id, flowCBM.Id);
            dfs2.Branch__c = 'dev2';

            Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flowCBM.Id);
            dfs3.Branch__c = 'dev3';

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flowCBM.Id);
            dfs4.Branch__c = 'int';

            List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>{ dfs1, dfs2, dfs3, dfs4 };
            insert dfsList;

            User_Story__c userStory1 = new User_Story__c(
                User_Story_Title__c = '1. User Story for forward Promotion Automated CCD test',
                Environment__c = env1.Id,
                Org_Credential__c = devOrg1.Id,
                Project__c = testProject.Id,
                Exclude_From_CBM__c = false,
                Status__c = 'Ready for Testing'
            );
            insert userStory1;

            Test.startTest();
            Test.enableChangeDataCapture();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory1.Promote_Change__c = true;
            update userStory1;

            Test.getEventBus().deliver();

            List<Promotion__c> promoResult = [SELECT Id, Name, Status__c, Source_Org_Credential__c FROM Promotion__c];
            System.assertEquals(0, promoResult.size());
            Test.stopTest();
        }
    }
}