global with sharing class Scheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		if(FeatureHelper.isFeatureEnabled('Apex Test'))database.executebatch(new TestBatch(),1);
		if(FeatureHelper.isFeatureEnabled('Git Backup'))database.executebatch(new BackupBatch(),1);
		DeployAPI.checkSyncFeatures();
	}
}