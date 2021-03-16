public with sharing class StepsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Step__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Step__c.Id, Step__c.Deployment__c, Step__c.dataJSON__c, Step__c.Type__c };
    }

    public StepsSelector() {
        this(true);
    }

    public StepsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Step__c> byId(List<Id> recordIds) {
        return (List<Step__c>) byId(new Set<Id>(recordIds));
    }

    public List<Step__c> byId(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Id IN :recordIds');

        fflib_SObjectSelector deploymentsSlector = new DeploymentsSelector();
        deploymentsSlector.configureQueryFactoryFields(query, 'Deployment__r');

        return (List<Step__c>) Database.query(query.toSOQL());
    }
}