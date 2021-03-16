trigger PersonaTrigger on Persona__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(PersonaTriggerHandler.class);
}