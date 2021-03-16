@IsTest
private class TestStepEditionController {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void myUnitTest() {
        StepEditionController handler = new StepEditionController();

        Step__c testStep = new Step__c();
        testStep.Name = 'test';

        handler.setStep(testStep);

        System.assertEquals(true, handler.filtered);

        Step__c currentStep = handler.getStep();

        System.assertEquals(testStep, currentStep);
    }

    @IsTest
    private static void validateDataTemplate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Step__c step1 = getStep('Step 1');
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockNoErrors(sourceOrg, destinationOrg);

            // Exercise
            PageReference reference = Page.Deployment;
            reference.getParameters().put('stepId', step1.Id);
            Test.setCurrentPage(reference);

            Test.startTest();
            StepEditionController controller = new StepEditionController();
            controller.validateDataTemplateDeployment();
            Test.stopTest();

            // Verify
            Attachment attachment = getAttachment(step1.Id);
            DataTemplateDeploymentValidationResult result = (DataTemplateDeploymentValidationResult) JSON.deserialize(
                attachment.Body.toString(),
                DataTemplateDeploymentValidationResult.class
            );
            System.assertNotEquals(null, attachment, 'Step has result attached');
            System.assertEquals(0, result.getErrors().size(), 'Result should not have errors');
        }

    }

    private static final String OBJECT_NAME1 = 'Account';
    private static final String OBJECT_NAME2 = 'Contact';
    private static final String FIELD_NAME1 = 'Id';
    private static final String FIELD_NAME2 = 'Name';

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

    private static void createData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, UserInfo.getUsername(), environments);
            Data_Template__c dataTemplate = new Data_Template__c(
                Name = 'Test',
                Template_Source_Org__c = credentials[0].Id,
                Main_Object__c = OBJECT_NAME1
            );
            insert dataTemplate;
            Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id, Name = 'Test');
            insert dataSet;

            DataTemplateDetail templateDetail = new DataTemplateDetail();
            templateDetail.parentObjectsReferenceList = new List<DataTemplateDetail.RelationTemplateDetails>();
            templateDetail.childrenObjectsReferenceList = new List<DataTemplateDetail.RelationTemplateDetails>();
            templateDetail.selectableFieldsMap = new Map<String, DataTemplateDetail.CopadoSelectedField>();
            DataTemplateDetail.CopadoSelectedField field = new DataTemplateDetail.CopadoSelectedField();
            field.name = FIELD_NAME2;
            field.isSelected = true;
            templateDetail.selectableFieldsMap.put(field.name, field);

            Attachment attachment = new Attachment(
                ParentId = dataTemplate.Id,
                Name = DataTemplateDetail.ATTACHMENT_NAME,
                Body = Blob.valueOf(JSON.serialize(templateDetail))
            );
            insert attachment;
            Deployment__c deployment = TestDataFactory.createDeployment(
                'Test',
                Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
                credentials[0].Id
            );
            insert deployment;
            Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destOrg1;
            DataStepData stepData = new DataStepData();
            stepData.dataTemplateId = dataTemplate.Id;
            stepData.source = new DataStepData.StepSource();
            stepData.source.type = DataDeployRequest.Source.ENVIRONMENT;
            stepData.destination = new DataStepData.StepDestination();
            stepData.destination.type = DataDeployRequest.Destination.ENVIRONMENT;
            Step__c step1 = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not started', 1, null, JSON.serialize(stepData));
            stepData.source.type = DataDeployRequest.Source.DATASET;
            stepData.source.id = dataSet.Id;
            Step__c step2 = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Data Template', 'Not started', 2, null, JSON.serialize(stepData));
            List<Step__c> steps = new List<Step__c>{ step1, step2 };
            insert steps;
        }
    }

    private static List<Org__c> getOrgs() {
        return [SELECT Id FROM Org__c];
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

    private static void mockNoErrors(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 }
        );
    }

    private static void configureMock(
        Org__c sourceOrg,
        Org__c destinationOrg,
        List<String> sourceObjects,
        List<String> destinationObjects,
        List<String> sourceFields,
        List<String> destinationFields
    ) {
        configureMock(sourceOrg, destinationOrg, sourceObjects, destinationObjects, sourceFields, destinationFields, true, true);
    }

    private static void configureMock(
        Org__c sourceOrg,
        Org__c destinationOrg,
        List<String> sourceObjects,
        List<String> destinationObjects,
        List<String> sourceFields,
        List<String> destinationFields,
        Boolean objectUpdateableInDestination,
        Boolean fieldUpdateableInDestination
    ) {
        String globalDescribeSourceOrgUrl = String.format(
            DescribeSObjectService.GLOBAL_DESCRIBE_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(sourceOrg.Id, 'UTF-8') }
        );
        String globalDescribeSourceDestinationUrl = String.format(
            DescribeSObjectService.GLOBAL_DESCRIBE_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(destinationOrg.Id, 'UTF-8') }
        );
        String fieldDescribeSourceOrgUrl = String.format(
            DescribeSObjectService.DESCRIBE_FULL_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(sourceOrg.Id, 'UTF-8'), EncodingUtil.urlEncode(OBJECT_NAME1, 'UTF-8') }
        );
        String fieldDescribeDestinationOrgUrl = String.format(
            DescribeSObjectService.DESCRIBE_FULL_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(destinationOrg.Id, 'UTF-8'), EncodingUtil.urlEncode(OBJECT_NAME1, 'UTF-8') }
        );
        new HttpMock()
            .get(globalDescribeSourceOrgUrl, getGlobalMockResponse(sourceObjects, true))
            .get(globalDescribeSourceDestinationUrl, getGlobalMockResponse(destinationObjects, objectUpdateableInDestination))
            .get(fieldDescribeSourceOrgUrl, getFieldsMockResponse(sourceFields, true))
            .get(fieldDescribeDestinationOrgUrl, getFieldsMockResponse(destinationFields, fieldUpdateableInDestination))
            .mock();
    }

    private static DescribeSObjectService.DescribeGlobalResponse getGlobalMockResponse(
        List<String> objectNames,
        Boolean objectUpdateableInDestination
    ) {
        DescribeSObjectService.DescribeGlobalResponse mockResponse = new DescribeSObjectService.DescribeGlobalResponse();
        mockResponse.success = true;
        mockResponse.sobjects = new List<DescribeSObjectService.CopadoObject>();
        for (String objectName : objectNames) {
            mockResponse.sobjects.add(createTestObject(objectName, objectName, objectUpdateableInDestination));
        }
        return mockResponse;
    }

    private static DescribeSObjectService.CopadoObject createTestObject(String label, String name, Boolean objectUpdateableInDestination) {
        DescribeSObjectService.CopadoObject testObject = new DescribeSObjectService.CopadoObject();
        testObject.custom = false;
        testObject.label = label;
        testObject.name = name;
        testObject.queryable = true;
        testObject.triggerable = true;
        testObject.updateable = objectUpdateableInDestination;
        return testObject;
    }

    private static DescribeSObjectService.DescribeResponse getFieldsMockResponse(List<String> fieldNames, Boolean fieldUpdateableInDestination) {
        DescribeSObjectService.DescribeResponse mockResponse = new DescribeSObjectService.DescribeResponse();
        mockResponse.success = true;
        mockResponse.fields = new List<DescribeSObjectService.CopadoField>();
        for (String fieldName : fieldNames) {
            mockResponse.fields.add(createTestField(fieldName, fieldName, fieldUpdateableInDestination));
        }
        return mockResponse;
    }

    private static DescribeSObjectService.CopadoField createTestField(String label, String name, Boolean fieldUpdateableInDestination) {
        DescribeSObjectService.CopadoField testField = new DescribeSObjectService.CopadoField();
        testField.custom = false;
        testField.label = label;
        testField.name = name;
        testField.referenceTo = null;
        testField.filterable = true;
        testField.updateable = fieldUpdateableInDestination;
        return testField;
    }
}