public without sharing class SeleniumTestRunTriggerHandler implements ITrigger{
    public class ApplicationException extends Exception {}
    public SeleniumTestRunTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(!LicenseHelper.isCSTEnabled())throw new ApplicationException(Label.SELENIUM_NOT_ENABLED);
    }
 
    public void bulkAfter(){
        SeleniumTestRunTriggerHelper.updateGroups();
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
    }
}