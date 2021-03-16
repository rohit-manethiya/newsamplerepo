public class DeploymentFlowTriggerHandler implements ITrigger{
 	
    public class ApplicationException extends Exception {}
    
    public DeploymentFlowTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Deployment_Flow__c st : (List<Deployment_Flow__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
        if(Trigger.new !=null)DeploymentFlowTriggerHelper.prepareData();
    }
 
    public void bulkAfter(){
        if(Trigger.new !=null)DeploymentFlowTriggerHelper.checkForCBMlicenses();
    }
 
    public void beforeInsert(SObject so){
        DeploymentFlowTriggerHelper.beforeCommon(so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        DeploymentFlowTriggerHelper.beforeCommon(so);
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