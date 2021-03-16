public class PersonaTriggerHandler implements ITrigger{
    
    public PersonaTriggerHandler(){
    }
 
    public void bulkBefore(){
      PersonaTriggerHelper.prepareData();
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
      
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
      
	}
    
    public void beforeDelete(SObject so){
        PersonaTriggerHelper.setAffected(so);
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
        PersonaTriggerHelper.callBatchDelete();
    }
}