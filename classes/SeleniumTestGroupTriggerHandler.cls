public class SeleniumTestGroupTriggerHandler implements ITrigger{
 	public class ApplicationException extends Exception {}
    
    public SeleniumTestGroupTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.isInsert || Trigger.isUpdate)SeleniumTestGroupTriggerHelper.prepareDataBefore();
    }
 
    public void bulkAfter(){
        if(Trigger.new !=null)SeleniumTestGroupTriggerHelper.prepareData();
    }

    public void beforeCommon(SObject so){
        SeleniumTestGroupTriggerHelper.isValidGroupType((Selenium_Test_Group__c)so);
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
        SeleniumTestGroupTriggerHelper.checkStatusChanged((Selenium_Test_Group__c)oldSo, (Selenium_Test_Group__c)so);
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        SeleniumTestGroupTriggerHelper.sendCalloutsIfAny();
    }
}