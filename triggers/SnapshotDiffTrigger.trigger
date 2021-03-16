trigger SnapshotDiffTrigger on Snapshot_Difference__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(SnapshotDiffTriggerHandler.class);
}