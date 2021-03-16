trigger OrgTrigger on Org__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(OrgTriggerHandler.class);
}