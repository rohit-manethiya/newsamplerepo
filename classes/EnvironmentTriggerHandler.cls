public class EnvironmentTriggerHandler implements ITrigger {

    public EnvironmentTriggerHandler(){
    }

    public void bulkBefore(){
    }

    public void bulkAfter(){
        EnvironmentTriggerHelper.prepareData();
    }

    public void beforeInsert(SObject so){
    }

    public void beforeUpdate(SObject oldSo, SObject so){
        EnvironmentTriggerHelper.orgIdValidation((Environment__c) so);
    }

    public void beforeDelete(SObject so){
    }

    public void afterInsert(SObject so){

    }

    public void afterUpdate(SObject oldSo, SObject so){
        EnvironmentTriggerHelper.prepareData();
    }

    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }

    public void andFinally(){
        EnvironmentTriggerHelper.updateOrgCredentials();
    }
}