trigger DeploymentTime on Deployment__c (after update) {
	List<Id> ids = new List<Id>();
	for(Deployment__c dn : Trigger.new){
		Deployment__c o = Trigger.oldMap.get(dn.id);
		if(dn.Deployment_command_sent__c!=null && o.Deployment_command_sent__c==null){
			ids.add(o.id);
		}
	}
	if(ids.size()>0)DeployAPI.deploy(ids, UserInfo.getSessionId());
}