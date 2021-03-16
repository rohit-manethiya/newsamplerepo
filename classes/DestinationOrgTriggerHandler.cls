public without sharing class DestinationOrgTriggerHandler implements ITrigger{
	public class ApplicationException extends Exception {}
    public DestinationOrgTriggerHandler(){
    }
 
    public void bulkBefore(){
        DestinationOrgTriggerHelper.prepareData();
    }
 
    public void bulkAfter(){
    }

    public void beforeCommon(SObject so){
    }
 
    public void beforeInsert(SObject so){
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
        DestinationOrgTriggerHelper.addHistory((Destination_Org__c)so, 'created');
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
 
    public void afterDelete(SObject so){
        DestinationOrgTriggerHelper.addHistory((Destination_Org__c)so, 'deleted');
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        DestinationOrgTriggerHelper.insertHistory();
    }
}