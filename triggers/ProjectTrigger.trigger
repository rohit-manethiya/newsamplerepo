trigger ProjectTrigger on Project__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerFactory.createAndExecuteHandler(ProjectTriggerHandler.class);

}