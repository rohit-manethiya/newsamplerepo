@IsTest
private class TestSalesforceFlowStepController {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    /**
     * In order to not to rely on existent flows in the org, since this metadata type is not creatable
     * (Error: DML operation Insert not allowed on FlowDefinitionView), we expect the execution to fail
     * for a non existent flow that we make sure it does not exist by generating a random name.
     */
    @IsTest
    private static void testExecuteSelectedFlowFromDataJsonWithoutNamespace() {

        createTestFlowExecution('');

    }

    /**
     * In order to not to rely on existent flows in the org, since this metadata type is not creatable
     * (Error: DML operation Insert not allowed on FlowDefinitionView), we expect the execution to fail
     * for a non existent flow that we make sure it does not exist by generating a random name.
     */
    @IsTest
    private static void testExecuteSelectedFlowFromDataJsonWithNamespace() {

        createTestFlowExecution('copado.');
    }

    private static void createTestFlowExecution(String namespace) {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            final String randomFlowName = namespace + 'TestFlow' + Math.random();
            final String expectedResult = String.format(Label.ERROR_FLOW_EXECUTION, new List<Object>{ 'Invalid type: ' + randomFlowName });
            final Map<String, Object> parameterValuesByName = new Map<String, Object>{ 'Copado Org Id' => '{!CopadoOrg.OrgId}' };
            final Map<String, Object> selectedFlowWithParameters = new Map<String, Object>{
                'flowApiName' => randomFlowName,
                'type' => 'wait',
                'flowParameters' => parameterValuesByName
            };
            Test.startTest();
            final String result = SalesforceFlowStepController.executeSelectedFlow(selectedFlowWithParameters);

            Test.stopTest();
            System.assertEquals(expectedResult, result, 'Flow execution should have failed for non existent flow.');
        }
    }
}