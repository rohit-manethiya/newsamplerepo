trigger ComplianceScanResultTrigger on Compliance_Scan_Result__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ComplianceScanResultTriggerHandler.class);
}