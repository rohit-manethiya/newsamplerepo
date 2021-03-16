public without sharing class TestRunTriggerHandler implements ITrigger{
    
    public TestRunTriggerHandler(){
    }
 
    public void bulkBefore(){
       if(Trigger.new !=null)TestRunTriggerHelper.prepareData(Trigger.new);
    }
 
    public void bulkAfter(){
        TestRunTriggerHelper.insertTestRunSteps();
    }
 
    public void beforeInsert(SObject so){
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        TestRunTriggerHelper.updateTestRunInformation(so);
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