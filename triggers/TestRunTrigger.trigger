trigger TestRunTrigger on Test_Run__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(TestRunTriggerHandler.class);
}