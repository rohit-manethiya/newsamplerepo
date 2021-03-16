trigger ContinuousIntegrationTrigger on Continuous_Integration__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ContinuousIntegrationTriggerHandler.class);
}