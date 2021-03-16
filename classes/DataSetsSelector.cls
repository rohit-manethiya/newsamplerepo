public with sharing class DataSetsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Data_Set__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Data_Set__c.Id, Data_Set__c.Name, Data_Set__c.Data_Template__c, Data_Set__c.Last_Generated_Date__c };
    }

    public DataSetsSelector() {
        this(true);
    }

    public DataSetsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Data_Set__c> byId(List<Id> recordIds) {
        return (List<Data_Set__c>) byId(new Set<Id>(recordIds));
    }

    public List<Data_Set__c> byId(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Id IN :recordIds');

        fflib_SObjectSelector dataTemplatesSelector = new DataTemplatesSelector();
        dataTemplatesSelector.configureQueryFactoryFields(query, 'Data_Template__r');

        return (List<Data_Set__c>) Database.query(query.toSOQL());
    }
}