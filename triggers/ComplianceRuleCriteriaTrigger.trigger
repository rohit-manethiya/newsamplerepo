trigger ComplianceRuleCriteriaTrigger on Compliance_Rule_Criteria__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
	TriggerFactory.createAndExecuteHandler(ComplianceRuleCriteriaTriggerHandler.class);
}