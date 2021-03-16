public with sharing class OrgsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Org__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {


        return new List<SObjectField>{
            Org__c.Id,
            Org__c.Name,
            Org__c.Metadata_Types__c,
            Org__c.Disable_Validation__c,
            Org__c.Oauth_Signature__c,
            Org__c.Validated_Status__c,
            Org__c.Org_Type__c
        };


    }

    public OrgsSelector() {
        this(true);
    }

    public OrgsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Org__c> byId(List<Id> recordIds) {


        return byId(new Set<Id>(recordIds));


    }

    public List<Org__c> byId(Set<Id> recordIds) {
        return (List<Org__c>) selectSObjectsById(recordIds);
    }
}