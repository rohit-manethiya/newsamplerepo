public without sharing class GitOrgCommitTriggerHandler implements ITrigger{
    public class ApplicationException extends Exception {}
 
    public GitOrgCommitTriggerHandler(){
    }
 
    public void bulkBefore(){

    }
 
    public void bulkAfter(){

    }
 
    public void beforeInsert(SObject so){
        GitOrgCommitTriggerHelper.setCommitDate((Git_Org_Commit__c)so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
        GitOrgCommitTriggerHelper.updateOrgLastCommit((Git_Org_Commit__c)so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        if(Trigger.isAfter) {
            GitOrgCommitTriggerHelper.updateOrgCredentialLastBackup();
        }
    }
}