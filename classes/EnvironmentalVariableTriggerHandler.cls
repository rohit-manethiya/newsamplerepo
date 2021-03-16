public class EnvironmentalVariableTriggerHandler implements ITrigger {
    
    public EnvironmentalVariableTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(!Trigger.isDelete) {
            EnvironmentalVariableTriggerHelpler.prepareData();
        }
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    	EnvironmentalVariableTriggerHelpler.checkForDuplicates((Environmental_Variable__c)so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        EnvironmentalVariableTriggerHelpler.checkForDuplicatesUpdate((Environmental_Variable__c)so);
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