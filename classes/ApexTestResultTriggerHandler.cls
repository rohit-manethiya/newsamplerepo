public without sharing class ApexTestResultTriggerHandler implements ITrigger{
    
 
    public ApexTestResultTriggerHandler(){
    }
 
    public void bulkBefore(){
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    	ApexTestResultTriggerHelper.updateOrgLastTestStatus((Apex_Test_Result__c)so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
    	update ApexTestResultTriggerHelper.orgMap.values();
    }
}