public with sharing class ComplianceFindingTriggerHelper {
    private static Map<Id, String> complianceRuleMessageBydId = new Map<Id, String>();

    public static void prepareMaps() {
        if (Trigger.isDelete) {
            return;
        }
        Set<Id> complianceRulesIds = new Set<Id>();
        for (SObject so : Trigger.new) {
            Compliance_Finding__c finding = (Compliance_Finding__c) so;
            complianceRulesIds.add(finding.Compliance_Rule__c);
        }
        for (Compliance_Rule__c complianceRuleItem : [SELECT Id, Error_Message__c FROM Compliance_Rule__c WHERE Id = :complianceRulesIds]) {
            if (String.isNotBlank(complianceRuleItem.Error_Message__c)) {
                complianceRuleMessageBydId.put(complianceRuleItem.Id, complianceRuleItem.Error_Message__c);
            }
        }
    }

    public static void updateComplianceScanResults() {
        Set<Id> scanResultIds = new Set<Id>();

        if (Trigger.New != null) {
            for (SObject so : Trigger.New) {
                Compliance_Finding__c finding = (Compliance_Finding__c) so;
                scanResultIds.add(finding.Compliance_Scan_Result__c);
            }
        }

        if (Trigger.isDelete) {
            for (SObject so : Trigger.Old) {
                Compliance_Finding__c finding = (Compliance_Finding__c) so;
                scanResultIds.add(finding.Compliance_Scan_Result__c);
            }
        }

        List<Compliance_Scan_Result__c> scanResults = [SELECT Id FROM Compliance_Scan_Result__c WHERE Id IN :scanResultIds];
        System.debug('### Compliance Scan Results to Update:' + scanResults);
        Utilities.Secure_DML(scanResults, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Scan_Result__c);
    }

    public static void populateErrorMessage(Compliance_Finding__c finding) {
        if (complianceRuleMessageBydId.containsKey(finding.Compliance_Rule__c)) {
            finding.Rule_Error_Message__c = complianceRuleMessageBydId.get(finding.Compliance_Rule__c);
        }
    }
}