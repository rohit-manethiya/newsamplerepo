/**
 * This is the main controller for creating new environment by clicking on plus icon at pipeline diagram page
 */
public with sharing class NewEnvironmentServiceController extends WizardHelper implements OrgAuthenticationInterface {
    private Map<String, String> possibleActionStatusMap = new Map<String, String>();
    public String envName { get; set; }
    public String envType { get; set; }
    /**
     * This method is used to populate possible actions for environment setup inner step
     * Map will store action name and status. Status values are "Pending", "In Progress" and "Done"
     * @return PossibleActionOrder Enum values
     */
    public Map<String, String> getActionNames() {
        for(NewEnvironmentServiceController.PossibleActionOrder pa : NewEnvironmentServiceController.PossibleActionOrder.values()) {
            possibleActionStatusMap.put(pa.name(), ActionStatus.Pending.name());
        }
        return possibleActionStatusMap;
    }
    /**
     * This is order of the possible actions for DefineProductionOrgServiceController
     */
    private enum PossibleActionOrder {
        RecordsCreated,
        AllActionsDone
    }
    /**
     * It is used to get necessary org credential
     *
     * @return Org Credential record
     */
    public Org__c getOrgCredential(Boolean useCustomSetting) {
        return getOrgCredentialFromURL();
    }
    /**
     * It is used to define inner step in controller.
     * It will always start with new environment creation
     *
     * @return last step that implemented
     */
    public String getStep() {
        Org__c org = getOrgCredentialFromURL();
        Boolean authenticateOrg = (org.Id != null && org.Username__c != null) ? true : false;
        return authenticateOrg ? ORG_VALIDATION : NEW_ENV;
    }
    /**
     * It is used to do necessary changes at current step and move to next step
     *
     * @param jsonValue will store OrgAuthenticationWrapper.SetStepWrapper value in JSON, parse it first
     *
     * @return OrgAuthenticationWrapper.SetStepReturnWrapper
     */
    public OrgAuthenticationWrapper.SetStepReturnWrapper setStep(String jsonValue) {
        OrgAuthenticationWrapper.SetStepWrapper setStepWrapper = new OrgAuthenticationWrapper.SetStepWrapper();
        if(String.isNotBlank(jsonValue)) {
            setStepWrapper = (OrgAuthenticationWrapper.SetStepWrapper) JSON.deserialize(jsonValue, OrgAuthenticationWrapper.SetStepWrapper.class);
        } else {
            throw new NewEnvironmentServiceException(Label.Missing_value_in_call);
        }
        OrgAuthenticationWrapper.SetStepReturnWrapper setStepReturnWrapper = new OrgAuthenticationWrapper.SetStepReturnWrapper();
        if(setStepWrapper.currentInnerStep == NEW_ENV) {
            setStepReturnWrapper.newInnerStep = ORG_VALIDATION;
        } else if(setStepWrapper.currentInnerStep == ORG_VALIDATION) {
            setStepReturnWrapper.newInnerStep = ENV_SETUP;
            createDeploymentFlowStep();
            createOrgSnapshot();
            setStepReturnWrapper.stopCreatingRecordsPoller = false;
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.InProgress.name());
            setStepReturnWrapper.possibleActionStatusMap = possibleActionStatusMap;
            updateSetupWizardCustomSetting(null, null, null, null, null, null, PossibleActionOrder.RecordsCreated.name());
        }
        return setStepReturnWrapper;
    }
    /**
     * It is used to authenticate org credential
     * Define URL to be redirected after authentication and pass parameter by using "startURL"
     *
     * @return backend endpoint "/Authorize/sforceLogin"
     */
    public PageReference doOauth() {
        User currentUser = getCurrentUser();
        Org__c org = getOrgCredentialFromURL();
        if(String.isBlank(org.Name)) {
            org.Name = envName.left(80);
        }
        org.Org_Type__c = envType;
        try {
            Utilities.Secure_DML(org, Utilities.DML_Action.UPS, schema.SObjectType.Org__c);
        } catch(Exception excp) {
            throw new NewEnvironmentServiceException(excp.getMessage());
        }
        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, UTF_8) + '&url=' + EncodingUtil.urlEncode(currentUser.API_URL__c, UTF_8);
        if(org.Org_Type__c == 'Sandbox') {
            urlParameters += '&sandbox=true';
        } else if(org.Org_Type__c == 'Custom Domain') {
            urlParameters += '&domain=' + EncodingUtil.urlEncode(org.Custom_Domain__c, UTF_8);
        }
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), UTF_8);
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), UTF_8);
        urlParameters += '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), UTF_8);
        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();
        String newComponentName = getNextComponentName(currentRequestURL, false);
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
        if(String.isNotBlank(pipelineId)) {
            newComponentURL += '?pipelineId=' + pipelineId;
        }
        if(String.isNotBlank(environmentId)) {
            newComponentURL += '&envId=' + environmentId;
        }
        if(String.isNotBlank(envName)) {
            newComponentURL += '&envName=' + EncodingUtil.urlEncode(envName, UTF_8);
        }
        if(String.isNotBlank(branchName)) {
            newComponentURL += '&branch=' + EncodingUtil.urlEncode(branchName, UTF_8);
        }
        if(String.isNotBlank(org.Id)) {
            newComponentURL += '&orgId=' + org.Id;
        }
        if(String.isNotBlank(newOrg) && newOrg == 'true') {
            newComponentURL += '&newOrgCredential=true';
        }
        String useStep = ApexPages.currentPage().getParameters().get('useStep');
        String flowStepId = ApexPages.currentPage().getParameters().get('flowStepId');
        if(String.isNotBlank(useStep)) {
            newComponentURL += '&useStep=' + useStep;
        }
        if(String.isNotBlank(flowStepId)) {
            newComponentURL += '&flowStepId=' + flowStepId;
        }
        urlParameters += '&startURL=' + EncodingUtil.urlEncode(newComponentURL, UTF_8);
        String herokuServer = Settings.server_url;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        PageReference pr = new PageReference(urlOauth);
        return pr;
    }
    /**
     * It is used to redirect to necessary step on page load
     * For this case it will always stay on page
     *
     * @return null
     */
    public PageReference pageRedirectOnLoad() {
        return null;
    }
    /**
     * It is used to run possible action
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper runAction() {
        if(String.isNotBlank(setupWizardSettings.Diagram_Last_Action__c) && setupWizardSettings.Diagram_Last_Action__c == PossibleActionOrder.RecordsCreated.name()) {
            return getRecordsStatus();
        } else {
            return null;
        }
    }
    /**
     * This method is creating a deployment flow step for given deployment flow in the url
     * Update deployment flow coordinates field by adding new flow step coordinates
     */
    public void createDeploymentFlowStep() {
        String useStep = ApexPages.currentPage().getParameters().get('useStep');
        String flowStepId = ApexPages.currentPage().getParameters().get('flowStepId');
        Org__c org = getOrgCredentialFromURL();
        User currentUser = getCurrentUser();
        Deployment_Flow_Step__c dfs = new Deployment_Flow_Step__c();
        dfs.Source_Environment__c = org.Environment__c;
        dfs.Destination_Environment__c = environmentId;
        dfs.Deployment_Flow__c = pipelineId;
        dfs.Branch__c = org.Name.toLowerCase().removeStartIgnoreCase(currentUser.Alias).trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
        try {
            if(String.isNotBlank(useStep) && useStep == 'true' && String.isNotBlank(flowStepId)) {
                dfs.Id = flowStepId;
                Utilities.Secure_DML(dfs, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow_Step__c);
            } else {
                Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);
            }
        } catch(DmlException dmlEx) {
            throw dmlEx;
        } catch(Exception excp) {
            throw new NewEnvironmentServiceException(excp.getMessage());
        }
    }
    /**
     * This method is creating a snapshot for org
     * When snapshot is done, update stopCreatingSnapshotPoller boolean variable with true to stop creating snapshot action poller
     */
    public void createOrgSnapshot() {
        Org__c org = getOrgCredentialFromURL();
        User currentUser = getCurrentUser();
        String branchName = org.Name.toLowerCase().removeStartIgnoreCase(currentUser.Alias).trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
        Deployment_Flow__c pipeline = getPipelineFromURL();
        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, pipeline.Git_Repository__c, branchName);
        Boolean isScratchOrg = String.isNotBlank(org.Org_Type__c) ? (org.Org_Type__c.containsIgnoreCase('Scratch') ? true : false) : false;
        if(snapshot.Id == null && !isScratchOrg) {
            // TODO check field level access before insert
            Git_Backup__c gitSnapshot = new Git_Backup__c();
            gitSnapshot.Name = org.Name + System.now();
            gitSnapshot.Branch__c = branchName;
            gitSnapshot.Git_Repository__c = pipeline.Git_Repository__c;
            gitSnapshot.Org__c = org.Id;
            gitSnapshot.Frequency__c = 'None';
            gitSnapshot.Git_Snapshot_Permissions__c = 'Allow Commits Only';
            try {
                Utilities.Secure_DML(gitSnapshot, Utilities.DML_Action.INS, schema.SObjectType.Git_Backup__c);
            } catch(Exception excp) {
                throw new NewEnvironmentServiceException(excp.getMessage());
            }
        }
    }
    /**
     * This is used to check the status for records
     * If everything is done, update the status as 'Done'
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper getRecordsStatus() {
        Org__c org = getOrgCredentialFromURL();
        String environmentId = ApexPages.currentPage().getParameters().get(ENV_ID);
        List<Deployment_Flow_Step__c> deploymentFlowStepList = new List<Deployment_Flow_Step__c>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            deploymentFlowStepList = [SELECT Id FROM Deployment_Flow_Step__c WHERE Source_Environment__c = :org.Environment__c AND Destination_Environment__c = :environmentId AND Deployment_Flow__c = :pipelineId AND CreatedById = :UserInfo.getUserId()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow_Step__c.label;
            throw new NewEnvironmentServiceException(errorMessage);
        }
        Deployment_Flow__c pipeline = getPipelineFromURL();
        User currentUser = getCurrentUser();
        String branchNames = org.Name.toLowerCase().removeStartIgnoreCase(currentUser.Alias).trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, pipeline.Git_Repository__c, branchNames);
        OrgAuthenticationWrapper.ResponseActionPollerWrapper responseActionWrapper = new OrgAuthenticationWrapper.ResponseActionPollerWrapper();
        Boolean isScratchOrg = String.isNotBlank(org.Org_Type__c) ? (org.Org_Type__c.containsIgnoreCase('Scratch') ? true : false) : false;
        if(!deploymentFlowStepList.isEmpty() && snapshot.Id != null) {
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.Done.name());
            responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
            GitBranchRequestWrapper requestWrapper = prepareGitBranchRequest(pipeline.Git_Repository__c, deploymentFlowStepList[0].Id);
            Boolean isCalloutSuccesful = doCalloutForPipelineSetup(requestWrapper);
            updateSetupWizardCustomSetting(null, null, null, null, null, null, PossibleActionOrder.AllActionsDone.name());
            return responseActionWrapper;
        } else if(isScratchOrg) {
            responseActionWrapper.stopCreatingRecordsPoller = false;
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.Done.name());
            return responseActionWrapper;
        }
        possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.InProgress.name());
        responseActionWrapper.stopCreatingRecordsPoller = false;
        responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
        return responseActionWrapper;
    }
    public class NewEnvironmentServiceException extends Exception {
    }
    /**
    * This method prepares pipeline setup request for production org snapshot and branch creation
    * @return GitBranchRequestWrapper
    * @see GitBranchRequestWrapper
    * */
    public GitBranchRequestWrapper prepareGitBranchRequest(String gitRepoId, String currentFlowStepId) {
        List<String> branchNames = new List<String>();
        String mainBranchName = '';
        if(Schema.SObjectType.Deployment_Flow_Step__c.isAccessible() && Schema.SObjectType.Deployment_Flow_Step__c.isQueryable()) {
            List<Deployment_Flow_Step__c> currentFlowSteps = [SELECT Id, Branch__c, Deployment_Flow__r.Main_Branch__c FROM Deployment_Flow_Step__c WHERE Id = :currentFlowStepId];
            if(!currentFlowSteps.isEmpty()) {
                branchNames.add(currentFlowSteps[0].Branch__c);
                mainBranchName = currentFlowSteps[0].Deployment_Flow__r.Main_Branch__c;
            }
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow_Step__c.label;
            throw new NewEnvironmentServiceException(errorMessage);
        }
        String productionSnapshotId = '';
        if(Schema.SObjectType.Git_Backup__c.isAccessible() && Schema.SObjectType.Git_Backup__c.isQueryable()) {
            List<Git_Backup__c> masterSnapshot = [SELECT Id FROM Git_Backup__c WHERE Branch__c = :mainBranchName AND Git_Repository__c = :gitRepoId];
            productionSnapshotId = masterSnapshot.isEmpty() ? '' : masterSnapshot[0].Id;
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.label;
            throw new NewEnvironmentServiceException(errorMessage);
        }
        GitBranchSnapshot gitBranchSnapshot = new GitBranchSnapshot(productionSnapshotId, false);
        GitBranchRepository gitBranchRepository = new GitBranchRepository(false, branchNames);
        GitBranchRequestWrapper gitBranchRequestWrapper = new GitBranchRequestWrapper(gitBranchRepository, gitBranchSnapshot);
        return gitBranchRequestWrapper;
    }
    /**
    * This method calls pipeline setup endpoint for branch creation and taking production snapshot
    * Returns true if call is succesfull, false if there is a error
    * This endpoint returns started, we do the polling with copado notification record to decide if process ended
    * @return Boolean
    * */
    public Boolean doCalloutForPipelineSetup(GitBranchRequestWrapper requestWrapper) {
        //prepare request headers & body
        String copadoURL = Settings.server_url;
        String api_key = DeployAPI.getUserAPIKey();
        String url = copadoURL + '/json/v1/pipeline/setup?api_key=' + api_key;
        String postBody = JSON.serialize(requestWrapper);
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        DeployAPI.setAuthHeaders(req);//to authenticate against heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setBody(postBody);
        req.setMethod('POST');
        //make callout
        HttpResponse res = http.send(req);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse response = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.class);
        if(String.isNotBlank(response.error)) {
            throw new NewEnvironmentServiceException(response.error);
        } else {
            return true;
        }
    }
    public class GitBranchRequestWrapper {
        GitBranchRepository repository;
        GitBranchSnapshot snapshot;
        public GitBranchRequestWrapper(GitBranchRepository repository, GitBranchSnapshot snapshot) {
            this.repository = repository;
            this.snapshot = snapshot;
        }
    }
    public class GitBranchRepository {
        Boolean createMainBranch;
        Boolean createGitIgnore;
        List<String> newBranchNames;
        public GitBranchRepository(Boolean createMainBranch, List<String> newBranchNames) {
            this.createMainBranch = createMainBranch;
            this.createGitIgnore = false;
            this.newBranchNames = new List<String>();
            this.newBranchNames.addAll(newBranchNames);
        }
    }
    public class GitBranchSnapshot {
        String id; //production org snapshot id
        Boolean perform;
        public GitBranchSnapshot(String id, Boolean perform) {
            this.id = id;
            this.perform = perform;
        }
    }
}