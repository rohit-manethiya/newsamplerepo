public with sharing class DeploymentsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Deployment__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Deployment__c.Id, Deployment__c.Name, Deployment__c.From_Org__c };
    }

    public DeploymentsSelector() {
        this(true);
    }

    public DeploymentsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Deployment__c> byId(List<Id> recordIds) {
        return (List<Deployment__c>) byId(new Set<Id>(recordIds));
    }

    public List<Deployment__c> byId(Set<Id> recordIds) {
        return (List<Deployment__c>) selectSObjectsById(recordIds);
    }
}