trigger UserStoryTrigger on User_Story__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(UserStoryTriggerHandler.class);
}