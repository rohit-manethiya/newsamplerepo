public with sharing class ComplianceRuleCriteriaSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Compliance_Rule_Criteria__c.Id,
            Compliance_Rule_Criteria__c.Node__c,
            Compliance_Rule_Criteria__c.Field__c,
            Compliance_Rule_Criteria__c.Field_Type__c,
            Compliance_Rule_Criteria__c.Operator__c,
            Compliance_Rule_Criteria__c.Value__c,
            Compliance_Rule_Criteria__c.Name,
            Compliance_Rule_Criteria__c.Order__c,
            Compliance_Rule_Criteria__c.Compliance_Rule__c
        };
    }

    public SObjectType getSObjectType() {
        return Compliance_Rule_Criteria__c.sObjectType;
    }

    public List<Compliance_Rule_Criteria__c> byComplianceRuleId(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .selectField('Compliance_Rule__r.Metadata_Type__c')
                .setCondition('Compliance_Rule__c IN :ids')
                .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL()
        );
    }
}