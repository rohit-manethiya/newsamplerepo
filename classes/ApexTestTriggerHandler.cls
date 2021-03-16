public without sharing class ApexTestTriggerHandler implements ITrigger{
 
    public ApexTestTriggerHandler(){
    }
 
    public void bulkBefore(){
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    	if(!FeatureHelper.isFeatureEnabled('Apex Test'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Apex Test');
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
    }
}