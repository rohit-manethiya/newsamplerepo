@IsTest
private class DeployDataActionTest {
    @TestSetup
    private static void setup() {
        setupUser();
    }

    @IsTest
    private static void deployDataTemplate() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Setup
            createTestData();
            Data_Template__c dataTemplate = [SELECT Id FROM Data_Template__c];

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createDeployDataTemplateRequest(dataTemplate.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            System.assert(!deploymentIds.isEmpty(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c IN :deploymentIds];
            System.assertEquals(1, steps.size(), 'Deployment should have one step.');

            Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
            System.assertEquals(dataTemplate.Id, stepData.get('dataTemplateId'), 'Data Template Id from Step dataJson should match');
            System.assertEquals(
                'ENVIRONMENT',
                ((Map<String, Object>) stepData.get('source')).get('type'),
                'Source type in Step dataJson should be ENVIRONMENT'
            );
            System.assertEquals(
                'ENVIRONMENT',
                ((Map<String, Object>) stepData.get('destination')).get('type'),
                'Destination type in Step dataJson should be ENVIRONMENT'
            );
        }
    }

    @IsTest
    private static void deployDataSet() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Setup
            createTestData();
            Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c];

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createDeployDataSetRequest(dataSet.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            System.assert(!deploymentIds.isEmpty(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c IN :deploymentIds];
            System.assertEquals(1, steps.size(), 'Deployment should have one step.');

            Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
            System.assertEquals(
                'DATASET',
                ((Map<String, Object>) stepData.get('source')).get('type'),
                'Source type in Step dataJson should be DATASET'
            );
            System.assertEquals(
                dataSet.Id,
                ((Map<String, Object>) stepData.get('source')).get('id'),
                'Source Id from Step dataJson should match the record Id'
            );
            System.assertEquals(
                'ENVIRONMENT',
                ((Map<String, Object>) stepData.get('destination')).get('type'),
                'Destination type in Step dataJson should be ENVIRONMENT'
            );
        }
    }

    @IsTest
    private static void generateDataSet() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Setup
            createTestData();
            Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c];

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createGenerateDataSetRequest(dataSet.Data_Template__c, dataSet.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            System.assert(!deploymentIds.isEmpty(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c IN :deploymentIds];
            System.assertEquals(1, steps.size(), 'Deployment should have one step.');

            Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
            System.assertEquals(dataSet.Data_Template__c, stepData.get('dataTemplateId'), 'Data Template Id from Step dataJson should match');
            System.assertEquals(
                'ENVIRONMENT',
                ((Map<String, Object>) stepData.get('source')).get('type'),
                'Source type in Step dataJson should be ENVIRONMENT'
            );
            System.assertEquals(
                'DATASET',
                ((Map<String, Object>) stepData.get('destination')).get('type'),
                'Destination type in Step dataJson should be DATASET'
            );
            System.assertEquals(
                dataSet.Id,
                ((Map<String, Object>) stepData.get('destination')).get('id'),
                'Destination Id from Step dataJson should match the record Id'
            );
        }
    }

    @IsTest
    private static void generateDataSetNow() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Setup
            createTestData();
            Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c];
            new HttpMock().get('/json/v1/deployNow/', '{}').mock();

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createGenerateDataSetRequest(dataSet.Data_Template__c, dataSet.Id);
            request.deployNow = true;
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            System.assert(!deploymentIds.isEmpty(), 'Deployment record should be created.');

            List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id IN :deploymentIds];
            System.assertEquals('Scheduled', deployments[0].Status__c, 'Deployment should have Scheduled status.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c IN :deploymentIds];
            System.assertEquals(1, steps.size(), 'Deployment should have one step.');

            Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
            System.assertEquals(dataSet.Data_Template__c, stepData.get('dataTemplateId'), 'Data Template Id from Step dataJson should match');
            System.assertEquals(
                'ENVIRONMENT',
                ((Map<String, Object>) stepData.get('source')).get('type'),
                'Source type in Step dataJson should be ENVIRONMENT'
            );
            System.assertEquals(
                'DATASET',
                ((Map<String, Object>) stepData.get('destination')).get('type'),
                'Destination type in Step dataJson should be DATASET'
            );
            System.assertEquals(
                dataSet.Id,
                ((Map<String, Object>) stepData.get('destination')).get('id'),
                'Destination Id from Step dataJson should match the record Id'
            );

            List<Data_Set__c> dataSets = [SELECT Id, Last_Generated_Date__c FROM Data_Set__c WHERE Id = :dataSet.Id];
            System.assertNotEquals(null, dataSets[0].Last_Generated_Date__c, 'Data Set last generated date should be updated.');
        }
    }

    private static void setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
    }

    private static User getStandardUserWithLicense() {
        User standardUser = [
            SELECT Id, Name, LastName, Email, Username
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User') AND IsActive = TRUE
            LIMIT 1
        ];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true, true);
        return standardUser;
    }

    private static void createTestData() {
        Data_Template__c dataTemplate = new Data_Template__c();
        insert dataTemplate;
        Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id);
        insert dataSet;
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;
    }

    private static DeployDataAction.Request createDeployDataTemplateRequest(Id dataTemplateId) {
        return createRequest(dataTemplateId, 'ENVIRONMENT', 'ENVIRONMENT', null, null, null, null, null, null, false);
    }

    private static DeployDataAction.Request createDeployDataSetRequest(Id dataSetId) {
        return createRequest(null, 'DATASET', 'ENVIRONMENT', null, null, dataSetId, null, null, null, false);
    }

    private static DeployDataAction.Request createGenerateDataSetRequest(Id dataTemplateId, Id dataSetId) {
        return createRequest(dataTemplateId, 'ENVIRONMENT', 'DATASET', null, null, null, dataSetId, null, null, false);
    }

    private static DeployDataAction.Request createRequest(
        String dataTemplateId,
        String sourceType,
        String destinationType,
        String sourceCredentialId,
        String destinationCredentialId,
        String sourceDataSetId,
        String destinationDataSetId,
        String sourceBranchName,
        String destinationBranchName,
        Boolean deployNow
    ) {
        DeployDataAction.Request request = new DeployDataAction.Request();
        request.dataTemplateId = dataTemplateId;
        request.sourceType = sourceType;
        request.destinationType = destinationType;
        request.sourceCredentialId = sourceCredentialId;
        request.destinationCredentialId = destinationCredentialId;
        request.sourceDataSetId = sourceDataSetId;
        request.destinationDataSetId = destinationDataSetId;
        request.sourceBranchName = sourceBranchName;
        request.destinationBranchName = destinationBranchName;
        request.deployNow = deployNow;
        return request;
    }
}