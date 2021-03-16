trigger MaintainDeploymentJobs on Step__c (after insert) {
	Set<Id> ids = new Set<Id>();
	for(Step__c s:Trigger.new){
		ids.add(s.deployment__c);
	}
	DeployJobHelper.upsertDeployJobs(ids);
	
}