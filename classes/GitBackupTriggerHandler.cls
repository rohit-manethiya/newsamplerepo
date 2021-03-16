public without sharing class GitBackupTriggerHandler implements ITrigger{
    String feature = !LicenseHelper.isCopadoEnabled()?'CCM Git Backup':'Git Backup';
 	public class ApplicationException extends Exception {}
    public GitBackupTriggerHandler(){
    }
 
    public void bulkBefore(){
        //prevent any DML for non Copado enabled users
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Git_Backup__c st : (List<Git_Backup__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
		if(Trigger.isInsert && !LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
        if(!FeatureHelper.isFeatureEnabled('Git Backup'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Git Backup');
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        if(!FeatureHelper.isFeatureEnabled('Git Backup'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Git Backup');
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    	GitBackupTriggerHelper.isScheduled((Git_Backup__c)so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    	GitBackupTriggerHelper.isScheduled((Git_Backup__c)so);
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
    	GitBackupTriggerHelper.enforceScheduler();
    }
}