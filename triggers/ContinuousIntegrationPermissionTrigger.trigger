trigger ContinuousIntegrationPermissionTrigger on Continuous_Integration_Permission__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ContinuousIntegrationPermTrgHandler.class);
}