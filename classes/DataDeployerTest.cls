@IsTest
private class DataDeployerTest {
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
            Org__c org = [SELECT Id FROM Org__c];

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataTemplate.Id)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .sourceCredentialId(org.Id)
                .destinationType(DataDeployRequest.Destination.ENVIRONMENT)
                .destinationCredentialId(org.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Id = :deploymentId];
            System.assertNotEquals(0, deployments.size(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deploymentId];
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
            Org__c org = [SELECT Id FROM Org__c];

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.DATASET)
                .sourceDataSetId(dataSet.Id)
                .destinationType(DataDeployRequest.Destination.ENVIRONMENT)
                .destinationCredentialId(org.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Id = :deploymentId];
            System.assertNotEquals(0, deployments.size(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deploymentId];
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
            Org__c org = [SELECT Id FROM Org__c];

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .sourceCredentialId(org.Id)
                .destinationType(DataDeployRequest.Destination.DATASET)
                .destinationDataSetId(dataSet.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Id = :deploymentId];
            System.assertNotEquals(0, deployments.size(), 'Deployment record should be created.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deploymentId];
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
            Org__c org = [SELECT Id FROM Org__c];
            new HttpMock().get('/json/v1/deployNow/', '{}').mock();

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .sourceCredentialId(org.Id)
                .destinationType(DataDeployRequest.Destination.DATASET)
                .destinationDataSetId(dataSet.Id)
                .deployNow(true);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id = :deploymentId];
            System.assertNotEquals(0, deployments.size(), 'Deployment record should be created.');
            System.assertEquals('Scheduled', deployments[0].Status__c, 'Deployment should have Scheduled status.');

            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deploymentId];
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

    @IsTest
    private static void invalidRequests() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Setup
            createTestData();
            Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c];
            Org__c org = [SELECT Id FROM Org__c];

            // Exercise + Verify
            Test.startTest();
            List<DataDeployRequest> invalidRequests = new List<DataDeployRequest>();

            invalidRequests.add(new DataDeployRequest());
            invalidRequests.add(new DataDeployRequest().sourceType(DataDeployRequest.Source.ENVIRONMENT));
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.ENVIRONMENT).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.DATASET).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.BRANCH).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest()
                    .dataTemplateId(dataSet.Data_Template__c)
                    .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                    .destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest()
                    .dataTemplateId(dataSet.Data_Template__c)
                    .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                    .destinationType(DataDeployRequest.Destination.BRANCH)
            );
            for (DataDeployRequest invalidRequest : invalidRequests) {
                try {
                    DataDeployer dataDeployer = new DataDeployer(invalidRequest);
                } catch (DataDeployer.DataDeployerException e) {
                    System.assert(true, 'No validation exception was thrown');
                }
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void getTypeFromString() {
        User standardUser = getStandardUserWithLicense();
        System.runAs(standardUser) {
            // Exercise + Verify
            Test.startTest();
            System.assertEquals(
                DataDeployRequest.Source.ENVIRONMENT,
                DataDeployRequest.sourceTypeFromString('ENVIRONMENT'),
                'Enum value should be ENVIRONMENT'
            );
            System.assertEquals(DataDeployRequest.Source.DATASET, DataDeployRequest.sourceTypeFromString('DATASET'), 'Enum value should be DATASET');
            System.assertEquals(DataDeployRequest.Source.BRANCH, DataDeployRequest.sourceTypeFromString('BRANCH'), 'Enum value should be BRANCH');
            System.assertEquals(
                DataDeployRequest.Destination.ENVIRONMENT,
                DataDeployRequest.destinationTypeFromString('ENVIRONMENT'),
                'Enum value should be ENVIRONMENT'
            );
            System.assertEquals(
                DataDeployRequest.Destination.DATASET,
                DataDeployRequest.destinationTypeFromString('DATASET'),
                'Enum value should be DATASET'
            );
            System.assertEquals(
                DataDeployRequest.Destination.BRANCH,
                DataDeployRequest.destinationTypeFromString('BRANCH'),
                'Enum value should be BRANCH'
            );
            Test.stopTest();
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
}