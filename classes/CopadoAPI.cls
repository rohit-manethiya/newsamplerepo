/**
 * Service class to implement the service layer of copado deployments
 *
 * This class works as a services to be called from Rest interface CopadoAPIRest as well as from APEX by 
 * this package in self or a final user by CopadoAPI.listDeployments()
 *
 * @author: Martin
 */
public class CopadoAPI {

	public static final String DEPLOY_TYPE_ALL = 'ALL';
	public static final String DEPLOY_TYPE_OUTSANDING = 'OUTSTANDING';
	/**
	 * This method will retrive all Deployments
	 */
	public static Deployment__c[] listDeployments(){
		return [SELECT Id,Name, Status__c, From_Org__c FROM Deployment__c ORDER BY CreatedDate DESC];
	}

	/**
	 * TODO: complete comments
	 *
	 * @param 
	 */
	public static Deployment__c getDeployment(String deploymentId){
		//TODO: check with FEDE if we realy need to retrive the whole related info of a deploy ???
		return [SELECT Id,Name, Status__c, From_Org__c, Date__c, (SELECT Id,Name,Order__c, Status__c, Type__c FROM Steps__r), (SELECT Id,Name,Status__c, To_org__c, To_org__r.Name FROM Destination_Orgs__r), (SELECT Id,Name,CreatedDate FROM Attachments ORDER BY CreatedDate DESC) FROM Deployment__c WHERE Id=:deploymentId];
	}

	/**
	 * This method will create all Deployments
	 */
	public static void createDeployment(Deployment__c deployment){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void updateDeployment(Deployment__c deployment){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void removeDeployment(String deploymentId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void removeDestinationOrg(String deploymentId, String destinationOrg){
		Utilities.Secure_DML([SELECT Id FROM Destination_Org__c WHERE Deployment__c =:deploymentId AND To_Org__c = :destinationOrg] , Utilities.DML_Action.DEL, schema.Sobjecttype.Destination_Org__c);
	}

	/**
	 * The org destinations by deployment Id
	 */
	public static Destination_Org__c[] getDestinationsOrg(String deploymentId){
		return Utilities.getDestinationOrgsByDeploymentId(deploymentId);

		//TODO add validation and helty flags to destination
        //if (!DeployAPI.validateOrg(org.Id)){
        //
        /*if(org.id != null && !org.Disable_Validation__c){
            org = utilities.getOrgById(org.id);
            if(org.oauth_signature__c == null && org.password__c == null){
                Apexpages.addMessage(new apexpages.Message(apexpages.severity.info,Label.ADD_AUTHENTICATION));
                return null;
            }
            else{
                if (!DeployAPI.validateOrg(org.Id)){
                	*/
	}

	/**
	 * TODO: complete comments
	 */
	public static Destination_Org__c addDestinationOrg(String deploymentId, String destinationOrg){
		return (Destination_Org__c)Utilities.Secure_DML(new Destination_Org__c(
				To_Org__c = destinationOrg,
				Deployment__c = deploymentId
			), Utilities.DML_Action.INS, Schema.SObjectType.Destination_Org__c);
	}

	
	/**
	 * This method will retrive all Deployments
	 */
	public static Step__c[] listSteps(String deploymentId){
		return Utilities.getStepsByDeploymentId(deploymentId);
	}

	/**
	 * This method will create all Deployments
	 */
	public static void createStep(String deploymentId, Step__c step){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void updateStep(String deploymentId, Step__c step, String items){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void removeStep(String stepId){
		Utilities.Secure_DML(Utilities.getStepById(stepId), Utilities.DML_Action.DEL, schema.Sobjecttype.Step__c);
	}

	/**
	 * TODO: complete comments
	 */
	public static void scheduleDeployment(String deploymentId, Datetime deployTime){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void deploy(String deploymentId, String type){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void cancelDeploy(String deploymentId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getDeployHistory(String deploymentId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getDeployHistoryLog(String deploymentId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getStepHistory(String stepId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getStepHistoryDetail(String stepId){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getJobsByDeployment(String deploymentId, String status){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getJobsByStep(String stepId, String status){
		//TODO
	}

	/**
	 * TODO: complete comments
	 */
	public static void getDeployStatus(String deploymentId){
		//TODO
	}



}