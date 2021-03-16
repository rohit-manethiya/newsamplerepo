trigger ApexTestTrigger on Apex_Test_Result__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ApexTestTriggerHandler.class);

}