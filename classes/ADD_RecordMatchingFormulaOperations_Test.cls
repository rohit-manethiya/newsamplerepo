@IsTest
private class ADD_RecordMatchingFormulaOperations_Test {

    @TestSetup
    private static void setup(){
        User runningUser = createRunningUser();
        assignUserPermissions(runningUser.Id);
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
    }

    @IsTest
    private static void getRecordMatchingFormula() {
        System.runAs(getRunningUser()) {
            // Setup
            Record_Matching_Formula__c recordMatchingFormula = new Record_Matching_Formula__c(Name = 'Test');
            insert recordMatchingFormula;

            // Exercise
            Test.startTest();
            List<Record_Matching_Formula__c> recordMatchingFormulas = ADD_RecordMatchingFormulaOperations.getRecordMatchingFormulas(
                recordMatchingFormula.Id
            );
            Test.stopTest();

            // Verify
            System.assertEquals(1, recordMatchingFormulas.size(), 'Record not found');
        }
    }

    @IsTest
    private static void getOrgObjects() {
        System.runAs(getRunningUser()) {
            // Setup
            // placeholders, not used in http mock
            String orgId = 'orgId';

            String url = String.format(DescribeSObjectService.GLOBAL_DESCRIBE_ENDPOINT, new List<String>{ EncodingUtil.urlEncode(orgId, 'UTF-8') });
            DescribeSObjectService.DescribeGlobalResponse mockResponse = getGlobalMockResponse();
            new HttpMock().get(url, mockResponse).mock();

            // Exercise
            Test.startTest();
            String result = ADD_RecordMatchingFormulaOperations.getOrgObjects(orgId);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Result should not be null');

            ADD_RecordMatchingFormulaOperations.GlobalDescribe objects = (ADD_RecordMatchingFormulaOperations.GlobalDescribe) JSON.deserialize(
                result,
                ADD_RecordMatchingFormulaOperations.GlobalDescribe.class
            );
            // number of options depends on object conditions (e.g. is custom metadata), but in this case the mock is simple
            System.assertEquals(mockResponse.sobjects.size(), objects.options.size(), 'It should be the same number of options as returned objects');
        }
    }

    @IsTest
    private static void getObjectFields() {
        System.runAs(getRunningUser()) {
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
            String result = ADD_RecordMatchingFormulaOperations.getPickListValues(orgId, objectName);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Result should not be null');

            ADD_RecordMatchingFormulaOperations.FilterableFields fields = (ADD_RecordMatchingFormulaOperations.FilterableFields) JSON.deserialize(
                result,
                ADD_RecordMatchingFormulaOperations.FilterableFields.class
            );
            // number of options depends on field conditions (e.g. is compound), but in this case the mock is simple
            System.assertEquals(
                mockResponse.fields.size() + 1,
                fields.options.size(),
                'It should be the same number of options as returned objects, plus None option'
            );
        }
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

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        return users[1];
    }

    private static User getRunningUser() {
        User runningUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User') AND IsActive = TRUE LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(runningUser.Username), true, true, true, true, true, true);
        return runningUser;
    }

    private static void assignUserPermissions(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :userId
        ];
        if (assignments.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        }
    }
}