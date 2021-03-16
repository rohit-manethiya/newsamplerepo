@IsTest
private with sharing class DataStepValidatorResultHandlerTest {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void createAttachment() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step2 = getStep('Step 2');

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidationResult result = new DataTemplateDeploymentValidationResult();
            result.addError('environment', 'objectName', 'new attachment');
            DataStepValidatorResultHandler handler = new DataStepValidatorResultHandler(step2.Id);
            handler.handle(result);
            Test.stopTest();

            // Verify
            Attachment updatedAttachment = getAttachment(step2.Id);
            DataTemplateDeploymentValidationResult updatedResult = (DataTemplateDeploymentValidationResult) JSON.deserialize(
                updatedAttachment.Body.toString(),
                DataTemplateDeploymentValidationResult.class
            );
            System.assertEquals(result.getErrors()[0].message, updatedResult.getErrors()[0].message, 'Result should be attached');
        }
    }

    @IsTest
    private static void overwriteAttachment() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');
            Attachment existingAttachment = getAttachment(step1.Id);
            DataTemplateDeploymentValidationResult existingResult = (DataTemplateDeploymentValidationResult) JSON.deserialize(
                existingAttachment.Body.toString(),
                DataTemplateDeploymentValidationResult.class
            );

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidationResult result = new DataTemplateDeploymentValidationResult();
            result.addError('environment', 'objectName', 'overwrite attachment');
            DataStepValidatorResultHandler handler = new DataStepValidatorResultHandler(step1.Id);
            handler.handle(result);
            Test.stopTest();

            // Verify
            Attachment updatedAttachment = getAttachment(step1.Id);
            DataTemplateDeploymentValidationResult updatedResult = (DataTemplateDeploymentValidationResult) JSON.deserialize(
                updatedAttachment.Body.toString(),
                DataTemplateDeploymentValidationResult.class
            );
            System.assertNotEquals(existingResult.getErrors()[0].message, updatedResult.getErrors()[0].message, 'Result should have changed');
            System.assertEquals(result.getErrors()[0].message, updatedResult.getErrors()[0].message, 'Result should be updated');
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
            Step__c step2 = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Data Template', 'Not started', 2, null, '');
            Step__c step3 = TestDataFactory.createStep(deployment.Id, 'Step 3', 'Data Template', 'Not started', 3, null, '');
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
            SELECT Id, ParentId, Name, Body
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