public with sharing class ComplianceRulesSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Compliance_Rule__c.Id, Compliance_Rule__c.Metadata_Type__c };
    }

    public SObjectType getSObjectType() {
        return Compliance_Rule__c.sObjectType;
    }

    public List<Compliance_Rule__c> byId(Set<Id> ids) {
        return Database.query(newQueryFactory().setEnforceFLS(true).setCondition('id IN :ids').toSOQL());
    }
}