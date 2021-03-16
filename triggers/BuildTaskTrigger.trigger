trigger BuildTaskTrigger on Build_Task__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(BuildTaskTriggerHandler.class);
}