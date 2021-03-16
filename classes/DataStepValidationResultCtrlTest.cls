@IsTest
private with sharing class DataStepValidationResultCtrlTest {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void initializeWithStepId() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');

            // Exercise
            Test.startTest();
            DataStepValidationResultCtlr controller = new DataStepValidationResultCtlr();
            controller.dataStepId = step1.Id;

            String message = controller.validationResultMessage;
            String status = controller.validationStatus;
            String icon = controller.validationStatusIcon;
            Test.stopTest();

            // Verify
            System.assert(message.contains(String.format(Label.Number_Warnings_Found, new List<String>{ '1' })), 'It should be one warning');
            System.assertEquals('error', status, 'Status should be error');
            System.assertEquals('error.png', icon, 'Icon should be error.png');
        }
    }

    @IsTest
    private static void setStepId() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');

            // Exercise
            Test.startTest();
            DataStepValidationResultCtlr controller = new DataStepValidationResultCtlr();
            ApexPages.currentPage().getParameters().put('stepId', step1.Id);
            controller.setStepId();

            String message = controller.validationResultMessage;
            String status = controller.validationStatus;
            String icon = controller.validationStatusIcon;
            Test.stopTest();

            // Verify
            System.assert(message.contains(String.format(Label.Number_Warnings_Found, new List<String>{ '1' })), 'It should be one warning');
            System.assertEquals('error', status, 'Status should be error');
            System.assertEquals('error.png', icon, 'Icon should be error.png');
        }
    }

    @IsTest
    private static void setNewStep() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Exercise
            Test.startTest();
            DataStepValidationResultCtlr controller = new DataStepValidationResultCtlr();
            ApexPages.currentPage().getParameters().put('stepId', '');
            controller.setStepId();

            String message = controller.validationResultMessage;
            String status = controller.validationStatus;
            String icon = controller.validationStatusIcon;
            Test.stopTest();

            // Verify
            System.assertEquals(null, message, 'Message shoudl be null');
            System.assertEquals(null, status, 'Status should be null');
            System.assertEquals(null, icon, 'Icon should be null');
        }
    }

    @IsTest
    private static void refreshAttachment() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');

            // Exercise
            Test.startTest();
            DataStepValidationResultCtlr controller = new DataStepValidationResultCtlr();
            ApexPages.currentPage().getParameters().put('stepId', step1.Id);
            controller.setStepId();
            Attachment attachment = getAttachment(step1.Id);
            delete attachment;
            controller.refreshAttachment();

            String message = controller.validationResultMessage;
            String status = controller.validationStatus;
            String icon = controller.validationStatusIcon;
            Test.stopTest();

            // Verify
            System.assertEquals(Label.Step_Not_Validated, message, 'Message should be not validated');
            System.assertEquals('none', status, 'Status should be none');
            System.assertEquals('warning.png', icon, 'Icon should be warning.png');
        }
    }

    @IsTest
    private static void showErrors() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');

            // Exercise
            Test.startTest();
            DataStepValidationResultCtlr controller = new DataStepValidationResultCtlr();
            ApexPages.currentPage().getParameters().put('stepId', step1.Id);
            controller.setStepId();

            List<DataTemplateDeploymentValidationResult.ValidationError> errors = controller.validationErrors;
            Test.stopTest();

            // Verify
            System.assertEquals(1, errors.size(), 'It should be one error');
        }
    }

    private static void createData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, UserInfo.getUsername(), environments);
            Deployment__c deployment = TestDataFactory.createDeployment(
                'Test',
                Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
                credentials[0].Id
            );
            insert deployment;
            Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destOrg1;
            Step__c step1 = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not started', 1, null, '');
            Step__c step2 = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Data Template', 'Not started', 1, null, '');
            Step__c step3 = TestDataFactory.createStep(deployment.Id, 'Step 3', 'Data Template', 'Not started', 1, null, '');
            List<Step__c> steps = new List<Step__c>{ step1, step2, step3 };
            insert steps;
            DataTemplateDeploymentValidationResult result = new DataTemplateDeploymentValidationResult();
            result.addError('environment', 'objectName', 'message');
            Attachment attachment = new Attachment(
                ParentId = step1.Id,
                Name = DataTemplateDeploymentValidationResult.ATTACHMENT_NAME,
                Body = Blob.valueOf(JSON.serialize(result))
            );
            insert attachment;
        }
    }

    private static Step__c getStep(String stepName) {
        return [SELECT Id FROM Step__c WHERE Name = :stepName LIMIT 1];
    }

    private static Attachment getAttachment(String parentId) {
        return [
            SELECT Id, ParentId, Name
            FROM Attachment
            WHERE ParentId = :parentId AND Name = :DataTemplateDeploymentValidationResult.ATTACHMENT_NAME
            LIMIT 1
        ];
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }
}