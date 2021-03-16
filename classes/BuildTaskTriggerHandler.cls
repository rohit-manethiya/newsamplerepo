public with sharing class BuildTaskTriggerHandler implements ITrigger{
    public static boolean skipSendingEmails = false;
	public class ApplicationException extends Exception{}
	public BuildTaskTriggerHandler(){
    }
 
    public void bulkBefore(){
        //prevent any DML for non Copado enabled users
		if(!LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Build_Task__c st : (List<Build_Task__c>)Trigger.New){
                    st.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
		if(Trigger.new !=null)BuildTaskTriggerHelper.prepareData(Trigger.new);
    }
 
    public void bulkAfter(){
        if(Trigger.isUpdate){
            BuildTaskTriggerHelper.prepareBuildTaskCallouts(Trigger.new);
        }
    }

    public void beforeCommon(SObject so) {
        if(!FeatureHelper.isFeatureEnabled('Continuous Integration'))so.addError(Label.FEATURE_NOT_SUPPORTED + ' Continuous Integration');
    }
 
    public void beforeInsert(SObject so){
        beforeCommon(so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        beforeCommon(so);
        BuildTaskTriggerHelper.setLatestInformationOn_CI((Build_Task__c) oldSo, (Build_Task__c) so);
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
        BuildTaskTriggerHelper.setLatestInformationOn_CI(null,(Build_Task__c) so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        BuildTaskTriggerHelper.addUserToEmailList((Build_Task__c) oldSo, (Build_Task__c)so);
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        update BuildTaskTriggerHelper.ciMap.values();
        if(!skipSendingEmails)BuildTaskTriggerHelper.sendEmails();
        BuildTaskTriggerHelper.doBuildTaskCallouts();
    }
}