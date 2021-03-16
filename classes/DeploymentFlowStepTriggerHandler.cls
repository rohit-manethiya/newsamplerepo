public class DeploymentFlowStepTriggerHandler implements ITrigger{
 	
    //public class ApplicationException extends Exception {}
    
    public DeploymentFlowStepTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.new !=null) {
            DeploymentFlowStepTriggerHelper.prepareData();
        }
    }
 
    public void bulkAfter() {

        if (Trigger.isInsert || Trigger.isUpdate) {
            DeploymentFlowStepTriggerHelper.firePossibleFlowValidations(Trigger.new);
        }
    }
 
    public void beforeInsert(SObject so){
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
        // with v15.1 we are releasing a new feature parameter which is "NumberOfProductionEnvironment", so we need to update that parameter with following line. It will work on andFinally, because it should be triggered in all action, insert, update, delete, undelete
        if(Trigger.isExecuting) {
            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();
        }
    }
}