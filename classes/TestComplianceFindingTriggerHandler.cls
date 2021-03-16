@isTest
private class TestComplianceFindingTriggerHandler {
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    @isTest
    static void environmentScanResult() {
        System.runAs(getStandarUserWithLicense()) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                Environment__c = environments[0].Id
            );
            insert complianceScanResult;

            Environment__c environment = [
                SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c
                FROM Environment__c
                WHERE Id = :environments[0].Id
            ];
            System.assertEquals(complianceScanResult.Status__c, environment.Compliance_Status__c);

            Test.startTest();

            String currentNamespace = TestComplianceFindingTriggerHandler.class
                .getName()
                .substringBefore('TestComplianceFindingTriggerHandler')
                .removeEnd('.')
                .toLowerCase();
            currentNamespace = String.isNotBlank(currentNamespace) ? currentNamespace + '__' : currentNamespace;

            List<Schema.PicklistEntry> severityPle = Schema.getGlobalDescribe()
                .get(currentNamespace + 'Compliance_Rule__c')
                .getDescribe()
                .fields.getMap()
                .get(currentNamespace + 'Severity__c')
                .getDescribe()
                .getPicklistValues();

            List<Schema.PicklistEntry> actionPle = Schema.getGlobalDescribe()
                .get(currentNamespace + 'Compliance_Rule__c')
                .getDescribe()
                .fields.getMap()
                .get(currentNamespace + 'Action__c')
                .getDescribe()
                .getPicklistValues();

            Compliance_Rule__c complianceRuleOne = new Compliance_Rule__c(
                Name = 'Rule A',
                Severity__c = severityPle[0].getValue(),
                Action__c = actionPle[0].getValue(),
                Record_Count__c = 1,
                Record_Count_Criteria__c = 'Number of groups',
                Matching_Criteria__c = 'Greater or equal'
            );
            Compliance_Rule__c complianceRuleTwo = new Compliance_Rule__c(
                Name = 'Rule A',
                Severity__c = severityPle[1].getValue(),
                Action__c = actionPle[1].getValue(),
                Record_Count__c = 1,
                Record_Count_Criteria__c = 'Number of groups',
                Matching_Criteria__c = 'Greater or equal'
            );
            insert new List<Compliance_Rule__c>{ complianceRuleOne, complianceRuleTwo };

            Compliance_Finding__c complianceFinding = new Compliance_Finding__c(
                Compliance_Rule__c = complianceRuleOne.Id,
                Compliance_Scan_Result__c = complianceScanResult.Id
            );
            insert complianceFinding;
            System.assertEquals(true, complianceFinding.Id != null);

            update complianceFinding;
            delete complianceFinding;
            undelete complianceFinding;

            Test.stopTest();
        }
    }

    @IsTest
    static void testPopulateErrorMessage() {
        System.runAs(getStandarUserWithLicense()) {
            ITestDefaults testSetupData = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(ComplianceFindingTestDefaults.ComplianceScanResultDefaults.class)
                .setSObjectRelation(
                    Compliance_Scan_Result__c.SObjectType,
                    Environment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Compliance_Scan_Result__c.Environment__c => 1 }
                )
                .includeDefaults(ComplianceFindingTestDefaults.ComplianceRuleDefaults.class)
                .setDataSize(Environment__c.SObjectType, 1)
                .setDataSize(Compliance_Scan_Result__c.SObjectType, 1)
                .setDataSize(Compliance_Rule__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Compliance_Scan_Result__c complianceScanResult = (Compliance_Scan_Result__c) testSetupData.getTestData(
                Compliance_Scan_Result__c.SObjectType
            )[0];
            Compliance_Rule__c complianceRule = (Compliance_Rule__c) testSetupData.getTestData(Compliance_Rule__c.SObjectType)[0];

            Test.startTest();
            Compliance_Finding__c complianceFinding = new Compliance_Finding__c(
                Compliance_Rule__c = complianceRule.Id,
                Compliance_Scan_Result__c = complianceScanResult.Id
            );
            insert complianceFinding;
            Test.stopTest();
            Compliance_Finding__c assertComplianceFinding = [
                SELECT Id, Rule_Error_Message__c
                FROM Compliance_Finding__c
                WHERE Id = :complianceFinding.Id
            ];
            System.assertEquals(complianceRule.Error_Message__c, assertComplianceFinding.Rule_Error_Message__c, 'Error message does not match');
        }
    }

    private static User getStandarUserWithLicense() {
        User standardUser = [SELECT Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true, true);
        return standardUser;
    }
}