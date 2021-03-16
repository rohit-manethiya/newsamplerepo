public with sharing class ContinuousIntegrationTriggerHelper {

	public static List<Continuous_Integration_Permission__c> permissions = new List<Continuous_Integration_Permission__c>();
	public static Set<Id> deploymentJobIds = new Set<Id>();
    
	public static void prepareData(){
		permissions = new List<Continuous_Integration_Permission__c>();
        deploymentJobIds = new Set<Id>();
	}
	public static void createOwnerPermission(Continuous_Integration__c ci){
		Continuous_Integration_Permission__c cip = new Continuous_Integration_Permission__c();
		cip.User__c = ci.OwnerId;
		cip.Access__c = 'Run Continuous Integration';
		cip.Continuous_Integration__c = ci.Id;
		permissions.add(cip);
	}
    public static void resetPrePostBuildDeployments(Continuous_Integration__c oldCi, Continuous_Integration__c newCi){
        if(oldCi.status__c!='In Progress' && newCi.status__c=='In Progress'){
            if(newCi.Pre_Deployment_Jobs__c!=null)deploymentJobIds.add(newCi.Pre_Deployment_Jobs__c);
            if(newCi.Post_Success_Deployment_Jobs__c!=null)deploymentJobIds.add(newCi.Post_Success_Deployment_Jobs__c);
            if(newCi.Post_Failed_Deployment_Jobs__c!=null)deploymentJobIds.add(newCi.Post_Failed_Deployment_Jobs__c);
        }
    }
    public static void processJobUpdate(){
        List<Deployment__c> deployments = new List<Deployment__c>();
        for(Id i : deploymentJobIds){
            deployments.add(new Deployment__c(Id=i, Status__c='Draft'));
        }
        Utilities.Secure_DML(deployments, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
    }
}