public class SeleniumTestGroupOCTriggerHandler implements ITrigger{
 	public class ApplicationException extends Exception {}
    
    public SeleniumTestGroupOCTriggerHandler(){
    }
 
    public void bulkBefore(){
    }
 
    public void bulkAfter(){
        Map<Id,Selenium_Test_Group__c> affectedGroups = new Map<Id,Selenium_Test_Group__c>();
        if(Trigger.new !=null)for(SObject so: Trigger.new){
			Selenium_Group_Org_Credential__c goc = (Selenium_Group_Org_Credential__c)so;
            affectedGroups.put(goc.Selenium_Test_Group__c,new Selenium_Test_Group__c(id=goc.Selenium_Test_Group__c));
        }
        if(Trigger.old !=null)for(SObject so: Trigger.old){
            Selenium_Group_Org_Credential__c goc = (Selenium_Group_Org_Credential__c)so;
            affectedGroups.put(goc.Selenium_Test_Group__c,new Selenium_Test_Group__c(id=goc.Selenium_Test_Group__c));
        }
        update affectedGroups.values();
    }

    public void beforeCommon(SObject so){
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