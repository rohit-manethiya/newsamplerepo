@isTest
private class DescribeSObjectService_Test {
    @IsTest
    private static void getOrgObjects() {
        // Setup
        // placeholders, not used in http mock
        String orgId = 'orgId';

        String url = String.format(DescribeSObjectService.GLOBAL_DESCRIBE_ENDPOINT, new List<String>{ EncodingUtil.urlEncode(orgId, 'UTF-8') });
        DescribeSObjectService.DescribeGlobalResponse mockResponse = getGlobalMockResponse();
        new HttpMock().get(url, mockResponse).mock();

        // Exercise
        Test.startTest();
        DescribeSObjectService service = new DescribeSObjectService(orgId);
        DescribeSObjectService.DescribeGlobalResponse response = service.getObjects();
        Test.stopTest();

        // Verify
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(false, response.sobjects.isEmpty(), 'Response objects list should not be empty');
        System.assertEquals(mockResponse.sobjects.get(0).name, response.sobjects.get(0).name, 'Object name should be the same');
        System.assert(!mockResponse.sobjects.get(0).isCustomMetadataType(), 'Object should not be a Custom Metadata Type');
        System.assert(!mockResponse.sobjects.get(0).isPlatformEvent(), 'Object should not be a Platform Event');
        System.assert(!mockResponse.sobjects.get(0).isDisabled(), 'Object should not be disabled');
        System.assertEquals(mockResponse.sobjects.get(0).compareTo(response.sobjects.get(0)), 0, 'Both objects should be equals');
    }

    @IsTest
    private static void getAllObjectFields() {
        // Setup
        // placeholders, not used in http mock
        String orgId = 'orgId';
        String objectName = 'objectName';

        String url = String.format(
            DescribeSObjectService.DESCRIBE_FULL_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(orgId, 'UTF-8'), EncodingUtil.urlEncode(objectName, 'UTF-8') }
        );
        DescribeSObjectService.DescribeResponse mockResponse = getFieldsMockResponse();
        new HttpMock().get(url, mockResponse).mock();

        // Exercise
        Test.startTest();
        DescribeSObjectService service = new DescribeSObjectService(orgId);
        DescribeSObjectService.DescribeResponse response = service.getFields(objectName);
        Test.stopTest();

        // Verify
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(false, response.fields.isEmpty(), 'Response fields list should not be empty');
        System.assertEquals(mockResponse.fields.get(0).name, response.fields.get(0).name, 'Field name should be the same');
        System.assert(!mockResponse.fields.get(0).isCompound(), 'Field should not be compound');
        System.assert(!mockResponse.fields.get(0).isId(), 'Field should not be an Id');
        System.assert(!mockResponse.fields.get(0).isReference(), 'Field should not be a reference');
        System.assertEquals(mockResponse.fields.get(0).compareTo(response.fields.get(0)), 0, 'Both fields should be equals');
    }

    @IsTest
    private static void getCreateableObjectFields() {
        // Setup
        // placeholders, not used in http mock
        String orgId = 'orgId';
        String objectName = 'objectName';

        String url = String.format(
            DescribeSObjectService.DESCRIBE_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(orgId, 'UTF-8'), EncodingUtil.urlEncode(objectName, 'UTF-8') }
        );
        DescribeSObjectService.DescribeResponse mockResponse = getFieldsMockResponse();
        new HttpMock().get(url, mockResponse).mock();

        // Exercise
        Test.startTest();
        DescribeSObjectService service = new DescribeSObjectService(orgId);
        DescribeSObjectService.DescribeResponse response = service.getCreateableUpdateableFields(objectName);
        Test.stopTest();

        // Verify
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(false, response.fields.isEmpty(), 'Response fields list should not be empty');
        System.assertEquals(mockResponse.fields.get(0).name, response.fields.get(0).name, 'Field name should be the same');
        System.assert(!mockResponse.fields.get(0).isCompound(), 'Field should not be compound');
        System.assert(!mockResponse.fields.get(0).isId(), 'Field should not be an Id');
        System.assert(!mockResponse.fields.get(0).isReference(), 'Field should not be a reference');
        System.assertEquals(mockResponse.fields.get(0).compareTo(response.fields.get(0)), 0, 'Both fields should be equals');
    }

    private static DescribeSObjectService.DescribeGlobalResponse getGlobalMockResponse() {
        DescribeSObjectService.DescribeGlobalResponse mockResponse = new DescribeSObjectService.DescribeGlobalResponse();
        mockResponse.success = true;
        mockResponse.sobjects = new List<DescribeSObjectService.CopadoObject>{
            createTestObject('Contact', 'Contact'),
            createTestObject('Account', 'Account')
        };
        return mockResponse;
    }

    private static DescribeSObjectService.CopadoObject createTestObject(String label, String name) {
        DescribeSObjectService.CopadoObject testObject = new DescribeSObjectService.CopadoObject();
        testObject.custom = false;
        testObject.label = label;
        testObject.name = name;
        testObject.queryable = true;
        testObject.triggerable = true;
        testObject.updateable = true;
        return testObject;
    }

    private static DescribeSObjectService.DescribeResponse getFieldsMockResponse() {
        DescribeSObjectService.DescribeResponse mockResponse = new DescribeSObjectService.DescribeResponse();
        mockResponse.success = true;
        mockResponse.fields = new List<DescribeSObjectService.CopadoField>{ createTestField('Name', 'Name'), createTestField('Id', 'Id') };
        return mockResponse;
    }

    private static DescribeSObjectService.CopadoField createTestField(String label, String name) {
        DescribeSObjectService.CopadoField testField = new DescribeSObjectService.CopadoField();
        testField.custom = false;
        testField.label = label;
        testField.name = name;
        testField.referenceTo = null;
        testField.filterable = true;
        return testField;
    }
}