@isTest
private class TestNewDeploymentEmailController {
    private static final String EMPTY_STRING = '';

    @testSetup
    private static void setup() {
        TestUtilities.setTestSettingsEE();
    }

    @isTest
    private static void deploymentIdNotProvided() {
        // Exercise
        Test.startTest();

        NewDeploymentEmailController controller = new NewDeploymentEmailController();
        controller.deploymentId = null;

        controller.getErrorMessages();
        controller.getDeploymentSteps();
        controller.getRecordUrl();

        Test.stopTest();

        // Verify
        System.assertEquals(null, controller.deployment, 'Deployment should be null');
        System.assertEquals(Label.RECORD_NOT_FOUND, controller.statusMessage);
    }

    @isTest
    private static void errorAttachmentNotFound() {
        // Setup
        Deployment__c deployment = createDeployment();

        // Exercise
        Test.startTest();

        NewDeploymentEmailController controller = new NewDeploymentEmailController();
        controller.deploymentId = deployment.Id;

        controller.getErrorMessages();
        controller.getDeploymentSteps();
        controller.getRecordUrl();

        Test.stopTest();

        // Verify
        System.assertNotEquals(null, controller.deployment, 'Deployment should not be null');
        System.assertEquals(
            Label.NO_ERROR_ATTACHMENT_FOUND,
            controller.statusMessageErrorMessages,
            'Error status message should be related to attchament not found'
        );
    }

    @isTest
    private static void errorMessagesAvailable() {
        // Setup
        Deployment__c deployment = createDeployment();
        List<Deployment_Job__c> deploymentJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deployment.Id AND Step__r.Type__c = 'Git Metadata'
            ORDER BY Step__r.Order__c ASC
        ];
        String attBody = '[{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: 1","t":""},{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: 2","t":""}]';
        Attachment testAttachment = createAttachment(deployment.Id, deploymentJobs[0].Id + '.json', attBody);
        insert testAttachment;
        attBody = '{"sourceDomain":"https://yulio30-dev-ed.my.salesforce.com/","targetDomain":"https://eu19.salesforce.com/","results":[{"l":"Error","m":{"deployedRecords":0,"failedRecords":0,"exception":"Exception upserting data to OrgCredentialId: a0T1n000007L9xdEAC. [InvalidFieldFault [ApiQueryFault [ApiFault  exceptionCode=No such column CustomerPriority__c on entity Account. If you are attempting to use a custom field, be sure to append the __c after the custom field name. Please reference your WSDL or the describe call for the appropriate names."},"t":""}]}';
        testAttachment = createAttachment(deployment.Id, deploymentJobs[1].Id + '.json', attBody);
        insert testAttachment;

        // Exercise
        Test.startTest();

        NewDeploymentEmailController controller = new NewDeploymentEmailController();
        controller.deploymentId = deployment.Id;

        List<NewDeploymentEmailController.WrapperError> wrapperErrors = controller.getErrorMessages();
        controller.getDeploymentSteps();
        controller.getRecordUrl();

        Test.stopTest();

        // Verify
        System.assertEquals(EMPTY_STRING, controller.statusMessage, 'Status message should be empty');
        System.assertEquals(EMPTY_STRING, controller.statusMessageErrorMessages, 'Error status message should be empty');
        System.assertEquals(
            '[ApexClass DeploymetEmailController] unexpected token: 1',
            wrapperErrors[0].message,
            'Received error message is not the expected one'
        );
        System.assertEquals(
            '[ApexClass DeploymetEmailController] unexpected token: 2',
            wrapperErrors[1].message,
            'Received error message is not the expected one'
        );
        System.assertEquals(
            'Exception upserting data to OrgCredentialId: a0T1n000007L9xdEAC. [InvalidFieldFault [ApiQueryFault [ApiFault  exceptionCode=No such column CustomerPriority__c on entity Account. If you are attempting to use a custom field, be sure to append the __c after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
            wrapperErrors[2].message,
            'Received error message is not the expected one'
        );
    }

    @isTest
    private static void dataTemplateStepStatus() {
        // Setup
        Deployment__c deployment = createDeployment();
        List<Deployment_Job__c> deploymentJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deployment.Id AND Step__r.Type__c = 'Data Template'
            ORDER BY Step__r.Order__c ASC
        ];
        String attBody = '{"sourceDomain":"https://um3.salesforce.com/","targetDomain":"https://um3.salesforce.com/","results":[{"l":"DV Price Book Entry","m":{"templateId":"a1L1v00000eKb49EAC","templateName":"DV Price Book Entry","objectName":"PricebookEntry","deployedRecords":45,"failedRecords":2,"generatedIds":4},"t":""},{"l":"DV Product","m":{"templateId":"a1L1v00000eKb4EEAS","templateName":"DV Product","objectName":"Product2","deployedRecords":19,"failedRecords":0,"generatedIds":0},"t":""},{"l":"DV Price Book","m":{"templateId":"a1L1v00000eKb4JEAS","templateName":"DV Price Book","objectName":"Pricebook2","deployedRecords":4,"failedRecords":0,"generatedIds":0},"t":""}]}';
        Attachment testAttachment = createAttachment(deployment.Id, deploymentJobs[0].Id + '.json', attBody);
        insert testAttachment;

        // Exercise
        Test.startTest();

        NewDeploymentEmailController controller = new NewDeploymentEmailController();
        controller.deploymentId = deployment.Id;

        controller.getErrorMessages();
        List<NewDeploymentEmailController.WrapperStep> steps = controller.getDeploymentSteps();
        controller.getRecordUrl();

        Test.stopTest();

        // Verify
        for (NewDeploymentEmailController.WrapperStep step : steps) {
            if (step.type == 'Data Template') {
                System.assertEquals('Completed with Warnings', step.status, 'Data Template step status should be Completed with Warnings');
            }
        }
    }

    @isTest
    private static void attachmentMaxSizeError() {
        // Setup
        Deployment__c deployment = createDeployment();
        List<Deployment_Job__c> deploymentJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deployment.Id AND Step__r.Type__c = 'Git MetaData'
        ];
        String attBody = '{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: \u0027(\u0027","t":""},';
        for (Integer i = 0; i <= 11; i++) {
            attBody += attBody;
        }
        attBody = attBody.substring(0, attBody.length() - 1); //removes last comma.
        Attachment testAttachment = createAttachment(deployment.Id, deploymentJobs[0].Id + '.json', '[' + attBody + ']');
        insert testAttachment;
        List<Attachment> attr = [SELECT Id, BodyLength FROM Attachment WHERE Id = :testAttachment.Id];

        // Exercise
        Test.startTest();

        NewDeploymentEmailController controller = new NewDeploymentEmailController();
        controller.deploymentId = deployment.Id;

        controller.getErrorMessages();
        controller.getDeploymentSteps();
        controller.getRecordUrl();

        Test.stopTest();

        // Verify
        System.assert(attr[0].BodyLength > NewDeploymentEmailController.MAX_BODY_LENGTH, 'Attachment should be bigger than defined max size');
        System.assertEquals(Label.MAX_FILE_SIZE_EXCEEDED, controller.statusMessageErrorMessages, 'Error message should be related to file size');
    }

    private static Deployment__c createDeployment() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 1, 'Not started', 'Git MetaData');
        insert testStep;
        Step__c testStep2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', testDeployment.Id, 2, 'Not started', 'Git MetaData');
        insert testStep2;
        Step__c testStep3 = testMethodUtilities.create('Step 3', 'attId', 'JSONString', testDeployment.Id, 3, 'Not started', 'Data Template');
        insert testStep3;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        return testDeployment;
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(parentId = parentId, name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }
}