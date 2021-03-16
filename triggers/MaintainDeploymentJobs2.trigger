trigger MaintainDeploymentJobs2 on Destination_Org__c (after insert) {
	Set<Id> ids = new Set<Id>();
	for(Destination_Org__c s:Trigger.new){
		ids.add(s.deployment__c);
	}
	DeployJobHelper.upsertDeployJobs(ids);
}