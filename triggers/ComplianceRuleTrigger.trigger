trigger ComplianceRuleTrigger on Compliance_Rule__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ComplianceRuleTriggerHandler.class);
}