@IsTest
private class TestDeploymentTrigger {
    @TestSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
    }
    @TestSetup
    static void setupDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, true);
    }
    static testMethod void testBuildTaskUpdate() {
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name = 'My CI 1', Active__c = true, Status__c = 'Draft');
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name = 'My CI 2', Active__c = true, Status__c = 'Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        insert cis;

        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(new Build_Task__c(Continuous_Integration__c = ci1.Id, Duration__c = 1, Status__c = 'Pending'));
        bts.add(new Build_Task__c(Continuous_Integration__c = ci2.Id, Duration__c = 2, Status__c = 'Pending'));
        insert bts;

        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;

        Deployment__c testDeployment1 = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        Deployment__c testDeployment2 = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        testDeployment1.Build_Task__c = bts[0].Id;
        testDeployment2.Build_Task__c = bts[1].Id;
        insert testDeployment1;
        insert testDeployment2;
        List<Deployment__c> deployments = new List<Deployment__c>();
        testDeployment1.Status__c = 'Completed Successfully';
        testDeployment2.Status__c = 'Completed with Errors';
        deployments.add(testDeployment1);
        deployments.add(testDeployment2);
        update deployments;

        List<Build_Task__c> results = [
            SELECT Id, Continuous_Integration__c, Status__c
            FROM Build_Task__c
            WHERE Continuous_Integration__c = :cis[0].Id OR Continuous_Integration__c = :cis[1].Id
        ];
        for (Build_Task__c r : results) {
            if (r.Continuous_Integration__c == cis[0].Id) {
                System.assertEquals('Success', r.Status__c);
            }
            if (r.Continuous_Integration__c == cis[1].Id) {
                System.assertEquals('Failed', r.Status__c);
            }
        }
    }
    static testMethod void testDeploymentHistory() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;

        Org__c testFromOrg2 = testMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME2', System.now());
        insert testFromOrg2;

        Deployment__c testDeployment1 = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment1;

        System.assertNotEquals(
            0,
            [
                SELECT COUNT()
                FROM Deployment_History__c
                WHERE
                    Deployment__c = :testDeployment1.Id
                    AND Deployment_Id__c = :testDeployment1.id
                    AND Event__c = 'Created'
                    AND Object__c = 'Deployment'
            ]
        );

        testDeployment1.From_Org__c = testFromOrg2.Id;
        testDeployment1.Name = 'changed x';
        testDeployment1.Status__c = 'In progress';
        testDeployment1.Date__c = System.now();
        update testDeployment1;

        System.assertNotEquals(
            0,
            [
                SELECT COUNT()
                FROM Deployment_History__c
                WHERE
                    Deployment__c = :testDeployment1.Id
                    AND Deployment_Id__c = :testDeployment1.id
                    AND Event__c = 'Updated'
                    AND Object__c = 'Deployment'
                    AND Field__c = 'Deployment Name'
            ]
        );

        testDeployment1.From_Org__c = null;
        update testDeployment1;

        Destination_Org__c dorg = new Destination_Org__c(Deployment__c = testDeployment1.Id, To_Org__c = testFromOrg.Id);
        insert dorg;
        delete dorg;

        delete testDeployment1;

        System.assertNotEquals(
            0,
            [
                SELECT COUNT()
                FROM Deployment_History__c
                WHERE Deployment_Id__c = :testDeployment1.Id AND Event__c = 'Deleted' AND Object__c = 'Deployment'
            ]
        );
    }
    static testMethod void testCompletePromotions() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
        insert env2;
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('Integration', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        dfs.Branch__c = 'dev1';
        insert dfs;

        Promotion__c promotion1 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = testProject.Id);
        insert promotion1;

        User_Story__c userStory = new User_Story__c(
            User_Story_Title__c = 'US1',
            Environment__c = env1.Id,
            Org_Credential__c = testOrg1.Id,
            Project__c = testProject.Id,
            Promote_and_Deploy__c = true
        );
        insert userStory;

        Promoted_User_Story__c pus = new Promoted_User_Story__c();
        pus.User_Story__c = userStory.Id;
        pus.Promotion__c = promotion1.Id;
        insert pus;

        Test.startTest();
        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testOrg1.Id,
            'Deploy now',
            'In progress'
        );
        deployment.Promotion__c = promotion1.Id;
        insert deployment;

        Destination_Org__c destinationOrg1 = testMethodUtilities.create(deployment.id, 'Pending', testOrg1.Id);
        insert destinationOrg1;
        Step__c step1 = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        insert step1;

        System.debug('### Update Deployment Job to Success');
        Deployment_Job__c deploymentJob1 = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE Step__c = :step1.Id AND destination_org__c = :destinationOrg1.Id
        ];
        System.assertEquals('Pending', deploymentJob1.Status__c);
        deploymentJob1.Status__c = 'Success';
        deploymentJob1.Deployed__c = 100;
        update deploymentJob1;

        // Verify that the Step and the Deployment are Completed Successfully
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Step__c WHERE Id = :step1.Id].Status__c);
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);

        // Verify that the Promotion is Completed Successfully and the User Story Environment is the target environment
        System.assertEquals('Completed', [SELECT Status__c FROM Promotion__c WHERE Id = :promotion1.Id].Status__c);
        System.assertEquals(env2.Id, [SELECT Environment__c FROM User_Story__c WHERE Id = :userStory.Id].Environment__c);
        Test.stopTest();
    }

    @IsTest
    static void testLatestDeploymentOnEnvironment() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(2);
        List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, 'latest-deployment@trigger.xyz', environments);

        // Deployment creation
        String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
            .get('Metadata Deployment')
            .getRecordTypeId();
        Deployment__c firstDeployment = TestDataFactory.createDeployment(
            'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 1',
            metadataDeploymentRecordTypeId,
            credentials[0].Id
        );
        firstDeployment.Status__c = 'Draft';
        insert firstDeployment;

        Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(firstDeployment.Id, credentials[1].Id);
        insert destOrg1;

        Test.startTest();
        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(null, environments[1].Latest_Deployment__c, 'Latest Deployment should not be updated for Draft status');

        firstDeployment.Status__c = 'In progress';
        update firstDeployment;

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(
            firstDeployment.Id,
            environments[1].Latest_Deployment__c,
            'Latest Deployment should be updated for in progress deployment'
        );
        System.assertEquals(
            'In progress',
            environments[1].Latest_Deployment_Status__c,
            'Latest Deployment Status should be updated when deployment status changes'
        );

        firstDeployment.Status__c = 'Completed Successfully';
        update firstDeployment;

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(
            'Completed Successfully',
            environments[1].Latest_Deployment_Status__c,
            'Latest Deployment Status should be updated when deployment status changes'
        );

        // Deployment creation
        Deployment__c secondDeployment = TestDataFactory.createDeployment(
            'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 2',
            metadataDeploymentRecordTypeId,
            credentials[0].Id
        );
        secondDeployment.Status__c = 'Draft';
        insert secondDeployment;

        Destination_Org__c destOrg2 = TestDataFactory.createDestinationOrg(secondDeployment.Id, credentials[1].Id);
        insert destOrg2;

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(firstDeployment.Id, environments[1].Latest_Deployment__c, 'Latest Deployment should not change for Draft deployment');
        secondDeployment.Status__c = 'Scheduled';
        update secondDeployment;

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertNotEquals(
            secondDeployment.Id,
            environments[1].Latest_Deployment__c,
            'Latest Deployment should not change for Scheduled deployment'
        );

        secondDeployment.Status__c = 'Completed with Errors';
        update secondDeployment;

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(
            secondDeployment.Id,
            environments[1].Latest_Deployment__c,
            'Latest Deployment should be updated for Completed status deployment'
        );
        System.assertEquals(
            'Completed with Errors',
            environments[1].Latest_Deployment_Status__c,
            'Latest Deployment Status should be updated when deployment status changes'
        );

        secondDeployment.Paused__c = true;
        secondDeployment.Status__c = 'In progress';
        update secondDeployment;
        Test.stopTest();

        environments = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id IN :environments
        ];

        System.assertEquals(
            'Paused',
            environments[1].Latest_Deployment_Status__c,
            'Latest Deployment Status should be updated when deployment status changes'
        );
    }

    @IsTest
    static void testPausedStatusOnDeployment() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(2);
        List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, 'latest-deployment@trigger.xyz', environments);
        Environment__c destination = environments[1];

        // Deployment creation
        String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
            .get('Metadata Deployment')
            .getRecordTypeId();
        Deployment__c firstDeployment = TestDataFactory.createDeployment(
            'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 1',
            metadataDeploymentRecordTypeId,
            credentials[0].Id
        );
        firstDeployment.Status__c = 'Draft';
        insert firstDeployment;

        Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(firstDeployment.Id, credentials[1].Id);
        insert destOrg1;

        Step__c step1 = TestDataFactory.createStep(firstDeployment.Id, 'Step 1', 'MetaData', 'Not started', 1, null, '');
        Step__c step2 = TestDataFactory.createStep(
            firstDeployment.Id,
            'Step 2',
            'Manual Task',
            'Not started',
            2,
            null,
            '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":""}'
        );
        Step__c step3 = TestDataFactory.createStep(firstDeployment.Id, 'Step 3', 'Git MetaData', 'Not started', 3, null, '');
        List<Step__c> steps = new List<Step__c>{ step1, step2, step3 };
        insert steps;

        Deployment_Job__c depJob1 = new Deployment_Job__c(Step__c = step1.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
        Deployment_Job__c depJob2 = new Deployment_Job__c(Step__c = step2.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
        Deployment_Job__c depJob3 = new Deployment_Job__c(Step__c = step3.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
        List<Deployment_Job__c> depJobs = new List<Deployment_Job__c>{ depJob1, depJob2, depJob3 };
        insert depJobs;

        firstDeployment.Status__c = 'Scheduled';
        update firstDeployment;

        Test.startTest();
        String response = '{"isSuccess":true, "isFinished":true}';
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        depJobs[0].Status__c = 'In progress';
        update depJobs[0];

        steps[0].Status__c = 'In progress';
        update steps[0];

        destination = [
            SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
            FROM Environment__c
            WHERE Id = :destination.Id
        ];
        System.assertEquals(firstDeployment.Id, destination.Latest_Deployment__c, 'Latest Deployment should be populated');

        step1 = [SELECT Id, Status__c, Name FROM Step__c WHERE Id = :steps[0].Id];
        System.assertEquals('In progress', step1.Status__c, 'Metadata step with order 1 should be in progress');

        depJobs[0].Status__c = 'Success';
        update depJobs[0];

        Test.stopTest();
    }

    @IsTest
    private static void testCheckonlyDeployment() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        String requestBody = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(requestBody, null));

        List<Environment__c> environments = new List<Environment__c>();
        environments.add(new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox'));
        environments.add(new Environment__c(Name = 'Integration Environment', Type__c = 'Production'));

        List<Org__c> orgs = new List<Org__c>();
        orgs.add(CMTestMethodUtilities.createOrg('Dev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), environments[0].Id));
        orgs.add(CMTestMethodUtilities.createOrg('Integration', 'Production', 'SFDC_OrgId2', null, null, System.now(), environments[1].Id));
        insert orgs;

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(environments[0].Id, environments[1].Id, flowCBM.Id);
        dfs.Branch__c = 'dev1';
        insert dfs;

        Promotion__c promotion = new Promotion__c(Source_Environment__c = environments[0].Id, Project__c = testProject.Id);
        insert promotion;

        User_Story__c userStory = new User_Story__c(
            User_Story_Title__c = 'US1',
            Environment__c = environments[0].Id,
            Org_Credential__c = orgs[0].Id,
            Project__c = testProject.Id,
            Promote_and_Deploy__c = true
        );
        insert userStory;

        Promoted_User_Story__c promotedStory = new Promoted_User_Story__c();
        promotedStory.User_Story__c = userStory.Id;
        promotedStory.Promotion__c = promotion.Id;
        insert promotedStory;

       
        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            orgs[0].Id,
            'Deploy now',
            'In progress'
        );
        deployment.Promotion__c = promotion.Id;
        insert deployment;

        Destination_Org__c destinationOrg1 = testMethodUtilities.create(deployment.id, 'Pending', orgs[0].Id);
        insert destinationOrg1;
        Test.startTest();
        List<Step__c> steps = new List<Step__c>();
        Step__c step1 = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not started', 1, null, '');
        step1.CheckOnly__c = true;
        steps.add(step1);

        Step__c step2 = TestDataFactory.createStep(deployment.Id,'Step 2','Manual Task','Not started',2,null,'{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":""}');
        steps.add(step2);

        insert steps;

        List<Deployment_Job__c> deploymentJobs = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE Step__c IN :steps AND destination_org__c = :destinationOrg1.Id
        ];
        deploymentJobs[0].Status__c = 'Success';
        deploymentJobs[0].Deployed__c = 100;

        deploymentJobs[1].Status__c = 'Success';
        deploymentJobs[1].Deployed__c = 100;
        update deploymentJobs;

        // Verify that the Deployment are Completed Successfully
        System.assertEquals('Completed Successfully',[SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c,'Deployment status should be Completed successfully');

        // Verify that the Promotion is Validated and the User Story Environment is not changed
        System.assertEquals('Validated' ,[SELECT Status__c FROM Promotion__c WHERE Id = :promotion.Id].Status__c,'Promition status should be validated for check only deployments');
        System.assertEquals(environments[0].Id ,[SELECT Environment__c FROM User_Story__c WHERE Id = :userStory.Id].Environment__c,'Environment on user story should be unchanged for check only deployments');
        Test.stopTest();
    }
}