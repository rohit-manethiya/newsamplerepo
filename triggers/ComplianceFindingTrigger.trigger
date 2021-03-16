trigger ComplianceFindingTrigger on Compliance_Finding__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ComplianceFindingTriggerHandler.class);
}