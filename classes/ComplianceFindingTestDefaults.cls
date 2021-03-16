public with sharing class ComplianceFindingTestDefaults {
    public with sharing class ComplianceScanResultDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Compliance_Scan_Result__c.Status__c => 'Completed - Findings detected'
            };
            testDataFieldDefaultsByObject.put(Compliance_Scan_Result__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class ComplianceRuleDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Compliance_Rule__c.Name => 'Rule A',
                Compliance_Rule__c.Severity__c => 'Medium',
                Compliance_Rule__c.Action__c => 'Continue with alert',
                Compliance_Rule__c.Record_Count__c => 1,
                Compliance_Rule__c.Record_Count_Criteria__c => 'Number of groups',
                Compliance_Rule__c.Matching_Criteria__c => 'Greater or equal',
                Compliance_Rule__c.Error_Message__c => 'Rule Error Message'
            };
            testDataFieldDefaultsByObject.put(Compliance_Rule__c.SObjectType, defaults);
            return this;
        }
    }
}