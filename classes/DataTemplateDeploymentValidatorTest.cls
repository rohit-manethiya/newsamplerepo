@IsTest
private with sharing class DataTemplateDeploymentValidatorTest {
    private static final String OBJECT_NAME1 = 'Account';
    private static final String OBJECT_NAME2 = 'Contact';
    private static final String FIELD_NAME1 = 'Id';
    private static final String FIELD_NAME2 = 'Name';

    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void validateWithoutErrors() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockNoErrors(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertEquals(0, result.getErrors().size(), 'Result should not contain errors');
        }
    }

    @IsTest
    private static void objectNotAvailalableInSource() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockObjectNotAvailableInSource(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
    }

    @IsTest
    private static void objectNotAvailableInDestination() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockObjectNotAvailableInDestination(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
    }

    @IsTest
    private static void objectNotUpdateableInDestination() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockObjectNotUpdateableInDestination(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
    }

    @IsTest
    private static void fieldNotAvailableInSource() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockFieldNotAvailableInSource(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
    }

    @IsTest
    private static void fieldNotAvailableInDestination() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockFieldNotAvailableInDestination(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
    }

    @IsTest
    private static void fieldNotUpdateableInDestination() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            List<Org__c> orgs = getOrgs();
            Org__c sourceOrg = orgs[0];
            Org__c destinationOrg = orgs[1];
            mockFieldNotUpdateableInDestination(sourceOrg, destinationOrg);

            // Exercise
            Test.startTest();
            DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplate.Id, sourceOrg.Id, destinationOrg.Id);
            DataTemplateDeploymentValidationResult result = validator.validate();
            Test.stopTest();

            // Verify
            System.assertNotEquals(0, result.getErrors().size(), 'Result should contain errors');
        }
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
        }
    }

    private static Data_Template__c getDataTemplate() {
        return [SELECT Id FROM Data_Template__c LIMIT 1];
    }

    private static List<Org__c> getOrgs() {
        return [SELECT Id FROM Org__c];
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

    private static void mockObjectNotAvailableInSource(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 }
        );
    }

    private static void mockObjectNotAvailableInDestination(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 }
        );
    }

    private static void mockObjectNotUpdateableInDestination(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            false,
            true
        );
    }

    private static void mockFieldNotAvailableInSource(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 }
        );
    }

    private static void mockFieldNotAvailableInDestination(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1 }
        );
    }

    private static void mockFieldNotUpdateableInDestination(Org__c sourceOrg, Org__c destinationOrg) {
        configureMock(
            sourceOrg,
            destinationOrg,
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ OBJECT_NAME1, OBJECT_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            new List<String>{ FIELD_NAME1, FIELD_NAME2 },
            true,
            false
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