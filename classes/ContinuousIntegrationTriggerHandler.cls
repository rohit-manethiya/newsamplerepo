public with sharing class ContinuousIntegrationTriggerHandler implements ITrigger{
    
    public class ApplicationException extends Exception {}

    public ContinuousIntegrationTriggerHandler(){
    }
 
    public void bulkBefore(){
        //prevent any DML for non Copado enabled users
        if(!LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Continuous_Integration__c st : (List<Continuous_Integration__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
    }
 
    public void bulkAfter(){
        ContinuousIntegrationTriggerHelper.prepareData();
    }

    public void beforeCommon(SObject so) {
        if(!FeatureHelper.isFeatureEnabled('Continuous Integration'))so.addError(Label.FEATURE_NOT_SUPPORTED + ' Continuous Integration');
    }
 
    public void beforeInsert(SObject so){
        beforeCommon(so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        beforeCommon(so);
    }

    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    	ContinuousIntegrationTriggerHelper.createOwnerPermission((Continuous_Integration__c)so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        ContinuousIntegrationTriggerHelper.resetPrePostBuildDeployments((Continuous_Integration__c)oldSo, (Continuous_Integration__c)so); 
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
    	if(Trigger.isInsert)Utilities.Secure_DML(ContinuousIntegrationTriggerHelper.permissions, Utilities.DML_Action.INS, schema.Sobjecttype.Continuous_Integration_Permission__c);
        if(Trigger.isUpdate)ContinuousIntegrationTriggerHelper.processJobUpdate();
    }
}