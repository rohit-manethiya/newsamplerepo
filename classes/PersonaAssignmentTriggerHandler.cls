public class PersonaAssignmentTriggerHandler implements ITrigger{
    
    public PersonaAssignmentTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.new !=null)PersonaAssignmentHelper.prepareData(Trigger.new);
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
        PersonaAssignmentHelper.setDefaultValues((User_Persona_Assignment__c) so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        PersonaAssignmentHelper.setDefaultValues((User_Persona_Assignment__c) so);
	}
    
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        PersonaAssignmentHelper.processAssignment((User_Persona_Assignment__c)oldSo, (User_Persona_Assignment__c)so);
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    
    public void andFinally(){
        PersonaAssignmentHelper.doFutureProcessing();
    }
}