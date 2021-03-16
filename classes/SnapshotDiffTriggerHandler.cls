public with sharing class SnapshotDiffTriggerHandler implements ITrigger{
 	public class ApplicationException extends Exception {}
    
    public SnapshotDiffTriggerHandler(){
    }
 
    public void bulkBefore(){
        //prevent any DML for non Copado enabled users
		if(!LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Snapshot_Difference__c st : (List<Snapshot_Difference__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
    }
 
    public void bulkAfter(){
    }
 
    public void beforeCommon(SObject so) {
        if(!FeatureHelper.isFeatureEnabled('Snapshot Difference'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Snapshot Difference');
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