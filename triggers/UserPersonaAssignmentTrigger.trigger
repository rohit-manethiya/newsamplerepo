trigger UserPersonaAssignmentTrigger on User_Persona_Assignment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(PersonaAssignmentTriggerHandler.class);
}