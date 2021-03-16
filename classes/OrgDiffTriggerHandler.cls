public without sharing class OrgDiffTriggerHandler implements ITrigger{
 	public class ApplicationException extends Exception {}
    
    public OrgDiffTriggerHandler(){
    }
 
    public void bulkBefore(){
        //prevent any DML for non Copado enabled users
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(OrgDiff__c st : (List<OrgDiff__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
		if(!LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    	if(!FeatureHelper.isFeatureEnabled('Org Difference'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Org Difference');
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    	if(!FeatureHelper.isFeatureEnabled('Org Difference'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Org Difference');
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