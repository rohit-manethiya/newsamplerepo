trigger GitRepositoryTrigger on Git_Repository__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(GitRepositoryTriggerHandler.class);
}