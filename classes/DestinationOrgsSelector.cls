public with sharing class DestinationOrgsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Destination_Org__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Destination_Org__c.Id, Destination_Org__c.Deployment__c, Destination_Org__c.To_Org__c };
    }

    public DestinationOrgsSelector() {
        this(true);
    }

    public DestinationOrgsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Destination_Org__c> byId(List<Id> recordIds) {
        return (List<Destination_Org__c>) byId(new Set<Id>(recordIds));
    }

    public List<Destination_Org__c> byId(Set<Id> recordIds) {
        return (List<Destination_Org__c>) selectSObjectsById(recordIds);
    }

    public List<Destination_Org__c> byDeploymentId(List<Id> deploymentIds) {
        return (List<Destination_Org__c>) byDeploymentId(new Set<Id>(deploymentIds));
    }

    public List<Destination_Org__c> byDeploymentId(Set<Id> deploymentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Deployment__c IN :deploymentIds');

        fflib_SObjectSelector deploymentsSlector = new DeploymentsSelector();
        deploymentsSlector.configureQueryFactoryFields(query, 'Deployment__r');

        return (List<Destination_Org__c>) Database.query(query.toSOQL());
    }
}