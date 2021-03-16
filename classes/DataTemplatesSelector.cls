public with sharing class DataTemplatesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Data_Template__c.sObjectType;
    }
    
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Data_Template__c.Id, Data_Template__c.Name, Data_Template__c.Main_Object__c, Data_Template__c.Template_Source_Org__c };
    }

    public DataTemplatesSelector() {
        this(true);
    }

    public DataTemplatesSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Data_Template__c> byId(List<Id> recordIds) {
        return (List<Data_Template__c>) byId(new Set<Id>(recordIds));
    }

    public List<Data_Template__c> byId(Set<Id> recordIds) {
        return (List<Data_Template__c>) selectSObjectsById(recordIds);
    }
}