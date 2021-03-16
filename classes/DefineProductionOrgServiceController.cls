/**
 * This is the main controller for authentication defining which org credential will be production org credential
 */
public with sharing class DefineProductionOrgServiceController extends WizardHelper implements OrgAuthenticationInterface {

    private Boolean runTakingSnapshotJobOnce = false;
    private List<Copado_Notification__c> copadoNotificationList;
    private String copadoNotificationId;
    private String copadoJobId;
    private Map<String, String> possibleActionStatusMap = new Map<String, String>();

    /**
     * This method is used to populate possible actions for environment setup inner step
     * Map will store action name and status. Status values are "Pending", "In Progress" and "Done"
     * @return PossibleActionOrder Enum values
     */
    public Map<String, String> getActionNames() {
        for(DefineProductionOrgServiceController.PossibleActionOrder pa : DefineProductionOrgServiceController.PossibleActionOrder.values()) {
            possibleActionStatusMap.put(pa.name(), ActionStatus.Pending.name());
        }
        return possibleActionStatusMap;
    }

    /**
     * This is order of the possible actions for DefineProductionOrgServiceController
     */
    private enum PossibleActionOrder {
        CreateSnapshot,
        RecordsCreated,
        TakeSnapshot, //TODO delete take snapshot
        AllActionsDone
    }

    /**
     * It is used to get necessary org credential
     *
     * @return Org Credential record
     */
    public Org__c getOrgCredential(Boolean useCustomSetting) {
        return useCustomSetting ? getOrgCredentialFromCustomSetting() : getUserOrgCredential();
    }

    /**
     * It is used to define inner step in controller.
     *
     * @return last step that implemented
     */
    public String getStep() {
        Org__c org = getOrgCredentialFromCustomSetting();

        Boolean authenticateOrg = (org.Id != null && org.Oauth_Signature__c != null) ? true : false;
        Boolean environmentSetupCompleted = String.isNotBlank(setupWizardSettings.Git_Snapshot_Id__c) ? true : false;

        return environmentSetupCompleted ? ENV_SETUP : authenticateOrg ? ORG_VALIDATION : ORG_AUTHENTICATE;
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
            throw new DefineProductionOrgServiceException(Label.Missing_value_in_call);
        }
        System.debug('**f**setStepWrapper : ' + setStepWrapper);

        OrgAuthenticationWrapper.SetStepReturnWrapper setStepReturnWrapper = new OrgAuthenticationWrapper.SetStepReturnWrapper();

        if(setStepWrapper.currentInnerStep == ORG_AUTHENTICATE) {
            if(!setStepWrapper.createNewOrg) {
                Org__c org = getUserOrgCredential();
                updateSetupWizardCustomSetting(null, org.Id, null, null, null, null, null);
            }

            setStepReturnWrapper.newInnerStep = ORG_VALIDATION;
        } else if(setStepWrapper.currentInnerStep == ORG_VALIDATION) {
            setStepReturnWrapper.newInnerStep = ENV_SETUP;
            updateDeploymentFlowSteps();
            createOrgSnapshot();
            //TODO run http callout
            setStepReturnWrapper.stopCreatingRecordsPoller = false;
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.InProgress.name());
            setStepReturnWrapper.possibleActionStatusMap = possibleActionStatusMap;
            updateSetupWizardCustomSetting(null, null, null, null, null, PossibleActionOrder.RecordsCreated.name(), null);
        }
        System.debug('**f**setStepReturnWrapper : ' + setStepReturnWrapper);
        return setStepReturnWrapper;
    }

    /**
     * It is used to authenticate org credential
     * Define URL to be redirected after authentication and pass parameter by using "startURL"
     *
     * @param jsonValue will store OrgAuthenticationWrapper.SetStepWrapper value in JSON, parse it first
     *
     * @return backend endpoint "/Authorize/sforceLogin"
     */
    public PageReference doOauth() {
        List<Environment__c> envList = new List<Environment__c>();
        if(Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            envList = [SELECT Id FROM Environment__c WHERE Org_ID__c = :UserInfo.getOrganizationId()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new DefineProductionOrgServiceException(errorMessage);
        }
        User currentUser = getCurrentUser();
        String userAlias = !envList.isEmpty() ? currentUser.Alias + '-' : '';

        Org__c org = new Org__c();
        org.Name = (userAlias + 'Production').left(80);
        org.Org_Type__c = 'Production/Developer';
        try {
            Utilities.Secure_DML(org, Utilities.DML_Action.INS, schema.SObjectType.Org__c);
        } catch(Exception excp) {
            throw new DefineProductionOrgServiceException(excp.getMessage());
        }

        updateSetupWizardCustomSetting(null, org.Id, null, null, null, null, null);

        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, UTF_8) + '&url=' + EncodingUtil.urlEncode(currentUser.API_URL__c, UTF_8);
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), UTF_8);
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), UTF_8);
        urlParameters += '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), UTF_8);

        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();
        String lightningUrl = UserInfo.getUiThemeDisplayed().startsWithIgnoreCase('Theme4') ? '/one/one.app#/alohaRedirect/' : '';
        String newComponentName = getNextComponentName(currentRequestURL, false);
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + lightningUrl + '/apex/' + namespace + newComponentName;
        urlParameters += '&startURL=' + EncodingUtil.urlEncode(newComponentURL, UTF_8);

        String herokuServer = Settings.server_url;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        System.debug('**f**urlOauth : ' + urlOauth);
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
        if(String.isNotBlank(setupWizardSettings.Wizard_Last_Action__c) && setupWizardSettings.Wizard_Last_Action__c == PossibleActionOrder.RecordsCreated.name()) {
            return getRecordsStatus();
        } else if(String.isNotBlank(setupWizardSettings.Wizard_Last_Action__c) && setupWizardSettings.Wizard_Last_Action__c == PossibleActionOrder.TakeSnapshot.name()) {
            return takeOrgSnapshot();
        } else {
            return null;
        }
    }

    /**
     * This method is updating a deployment flow steps to populate Destination
     * Update Wizard_Last_Action__c field of custom setting with "PossibleActionOrder.CreateSnapshot"
     * When process is done, update stopUpdatingDeploymentFlowStepsPoller boolean variable with true to stop updating deployment flow steps poller
     */
    public void updateDeploymentFlowSteps() {
        Org__c org = getOrgCredentialFromCustomSetting();
        System.debug('**f**update deployment flow steps');
        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            System.debug('**f**setupWizardSettings.Pipeline_Id__c : ' + setupWizardSettings.Pipeline_Id__c);

            for(Deployment_Flow_Step__c dfs : [SELECT Id, Branch__c, Destination_Branch__c, Destination_Environment__c, Source_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :setupWizardSettings.Pipeline_Id__c]) {
                System.debug('**f**dfs : ' + dfs);
                if((dfs.Destination_Branch__c != null && dfs.Destination_Branch__c.toLowerCase() == 'master' && dfs.Destination_Environment__c == null)) {
                    dfs.Destination_Environment__c = org.Environment__c;
                    dfsList.add(dfs);
                }
            }
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow_Step__c.label;
            throw new DefineProductionOrgServiceException(errorMessage);
        }
        System.debug('**f**dfsList : ' + dfsList);
        if(!dfsList.isEmpty()) {
            try {
                Utilities.Secure_DML(dfsList, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow_Step__c);
            } catch(Exception excp) {
                throw new DefineProductionOrgServiceException(excp.getMessage());
            }
        }
    }

    /**
     * This method is creating a snapshot for only production org
     * When snapshot is done, update stopCreatingSnapshotPoller boolean variable with true to stop creating snapshot action poller
     * When snapshot is done, update stopTakingSnapshotPoller boolean variable with false to start taking snapshot action poller
     */
    public void createOrgSnapshot() {
        Org__c org = getOrgCredentialFromCustomSetting();
        System.debug('**f**setupWizardSettings.Git_Snapshot_Id__c : ' + setupWizardSettings.Git_Snapshot_Id__c);
        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, setupWizardSettings.Git_Repository_Id__c, 'master');
        System.debug('**f**snapshot : ' + snapshot);
        Git_Backup__c gitSnapshot = new Git_Backup__c();
        if(String.isBlank(setupWizardSettings.Git_Snapshot_Id__c) && snapshot.Id == null) {
            // TODO check field level access before insert
            gitSnapshot.Name = org.Name + System.now();
            gitSnapshot.Branch__c = 'master';
            gitSnapshot.Git_Repository__c = setupWizardSettings.Git_Repository_Id__c;
            gitSnapshot.Org__c = org.Id;
            gitSnapshot.Frequency__c = 'None';
            gitSnapshot.Git_Snapshot_Permissions__c = 'Allow Snapshots & Commits';

            try {
                Utilities.Secure_DML(gitSnapshot, Utilities.DML_Action.INS, schema.SObjectType.Git_Backup__c);
            } catch(Exception excp) {
                throw new DefineProductionOrgServiceException(excp.getMessage());
            }
        }
        String snapshotId = snapshot.Id == null ? gitSnapshot.Id : snapshot.Id;
        // it will only update custom setting if it is wizard process, newOrgCredentail.Id should be null to save this
        if(String.isNotBlank(snapshotId)) {
            updateSetupWizardCustomSetting(null, null, null, null, snapshotId, null, null);
        }
    }

    /**
     * This method is taking a snapshot for production org
     * First checking if the "Git Backup" feature is enabled
     * To take a snapshot used "backupNow" method at DeployAPI.
     * When snapshot is done, update stopTakingSnapshotPoller boolean variable with true to stop taking snapshot action poller
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper takeOrgSnapshot() {
        if(!FeatureHelper.isFeatureEnabled(GIT_BACKUP)) {
            throw new DefineProductionOrgServiceException(Label.FEATURE_NOT_SUPPORTED + ' ' + GIT_BACKUP);
        }

        getNotificationList();
        if(!runTakingSnapshotJobOnce && copadoNotificationList.isEmpty()) {
            try {
                if(String.isNotBlank(setupWizardSettings.Git_Snapshot_Id__c)) {
                    Git_Backup__c gitSnapshot = new Git_Backup__c();
                    if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                        gitSnapshot = [SELECT Id, Name FROM Git_Backup__c WHERE Id = :setupWizardSettings.Git_Snapshot_Id__c];
                    } else {
                        String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.label;
                        throw new DefineProductionOrgServiceException(errorMessage);
                    }
                    GitBranchRequestWrapper requestWrapper = prepareGitBranchRequest(gitSnapshot.Id, setupWizardSettings.Pipeline_Id__c);
                    doCalloutForPipelineSetup(requestWrapper);

                }
            } catch(Exception excp) {
                throw new DefineProductionOrgServiceException(excp.getMessage());
            }
            runTakingSnapshotJobOnce = true;
        }
        Boolean isTakingSnapshotDone = getStatusForTakingSnapshot();
        System.debug('**f**isTakingSnapshotDone : ' + isTakingSnapshotDone);
        OrgAuthenticationWrapper.ResponseActionPollerWrapper responseActionWrapper = new OrgAuthenticationWrapper.ResponseActionPollerWrapper();
        if(isTakingSnapshotDone) {
            updateSetupWizardCustomSetting(null, null, null, null, null, String.valueOf(PossibleActionOrder.AllActionsDone), null);
            possibleActionStatusMap.put(PossibleActionOrder.TakeSnapshot.name(), ActionStatus.Done.name());
            responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
            responseActionWrapper.stopTakingSnapshotPoller = true;
            return responseActionWrapper;
        }
        possibleActionStatusMap.put(PossibleActionOrder.TakeSnapshot.name(), ActionStatus.InProgress.name());
        responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
        responseActionWrapper.stopTakingSnapshotPoller = false;
        return responseActionWrapper;
    }

    /**
     * It is used to get existing copado notification records for taking snapshot
     */
    private void getNotificationList() {
        try {
            if(Schema.SObjectType.Copado_Notification__c.isAccessible() && Schema.SObjectType.Copado_Notification__c.isQueryable()) {
                System.debug('**f**copadoNotificationId : ' + copadoNotificationId);
                System.debug('**f**copadoNotificationList : ' + copadoNotificationList);
                if(copadoNotificationList == null || copadoNotificationList.isEmpty()) {
                    copadoNotificationList = [SELECT Id, status__c, isSuccess__c, isFinished__c FROM Copado_Notification__c WHERE Type__c = :PIPELINE_SETUP AND Matching_Key__c = :copadoJobId AND CreatedById = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1];
                    if(!copadoNotificationList.isEmpty()) {
                        copadoNotificationId = copadoNotificationList[0].Id;
                    }
                } else {
                    if(String.isNotBlank(copadoNotificationId)) {
                        copadoNotificationList = [SELECT status__c, isSuccess__c, isFinished__c FROM Copado_Notification__c WHERE Id = :copadoNotificationId LIMIT 1];
                    }
                }
            } else {
                String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
                throw new DefineProductionOrgServiceException(errorMessage);
            }
        } catch(Exception excp) {
            throw new DefineProductionOrgServiceException(excp.getMessage());
        }
    }

    /**
     * This method is used to find copado notification object to check status of taking snapshot for orgs
     *
     * @return true if the job is success, false if job is failed for some reason
     */
    private Boolean getStatusForTakingSnapshot() {
        System.debug('**f**copadoNotificationList : ' + copadoNotificationList);
        if(!copadoNotificationList.isEmpty() && copadoNotificationList[0].isFinished__c) {
            if(!copadoNotificationList[0].isSuccess__c) {
                //we wont do the callout again so after error page go to last page
                updateSetupWizardCustomSetting(String.valueOf(SetupPipelineOrder.SetupWizardFinish), null, null, null, null, null, null);
                String errorMessage = copadoNotificationList[0].status__c + ' ' + Label.Pipeline_Complete_Setup_Manually;
                throw new DefineProductionOrgServiceException(errorMessage);
            }
            return copadoNotificationList[0].isSuccess__c ? true : false;
        }
        return false;
    }

    /**
     * This is used to check the status for records
     * If everything is done, update the status as 'Done'
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper getRecordsStatus() {
        System.debug('DefineProductionOrgservice');
        Org__c org = getOrgCredentialFromCustomSetting();
        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            dfsList = [SELECT Id FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :setupWizardSettings.Pipeline_Id__c AND Destination_Environment__c = :org.Environment__c];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new DefineProductionOrgServiceException(errorMessage);
        }

        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, setupWizardSettings.Git_Repository_Id__c, 'master');
        OrgAuthenticationWrapper.ResponseActionPollerWrapper responseActionWrapper = new OrgAuthenticationWrapper.ResponseActionPollerWrapper();
        if( snapshot != null) {//!dfsList.isEmpty() &&   if we skip template there is no deployment flow
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.Done.name());
            possibleActionStatusMap.put(PossibleActionOrder.TakeSnapshot.name(), ActionStatus.InProgress.name());
            responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
            responseActionWrapper.stopTakingSnapshotPoller = false;
            updateSetupWizardCustomSetting(null, null, null, null, null, PossibleActionOrder.TakeSnapshot.name(), null);
            return responseActionWrapper;
        }
        possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.InProgress.name());
        responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
        return responseActionWrapper;

    }

    /**
    * This method prepares pipeline setup request for production org snapshot and branch creation
    * @return GitBranchRequestWrapper
    * @see GitBranchRequestWrapper
    * */
    public GitBranchRequestWrapper prepareGitBranchRequest(String snapshotId, String currentFlowId){
        List<String> branchNames = new List<String>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isAccessible() && Schema.SObjectType.Deployment_Flow_Step__c.isQueryable()){
            List<Deployment_Flow_Step__c> currentFlowSteps = [SELECT Id, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :currentFlowId];
            if(!currentFlowSteps.isEmpty()){
                for(Deployment_Flow_Step__c dfs : currentFlowSteps){
                    if(String.isNotBlank(dfs.Branch__c)){
                        branchNames.add(dfs.Branch__c);
                    }
                }
            }
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow_Step__c.label;
            throw new DefineProductionOrgServiceException(errorMessage);
        }

        GitBranchSnapshot gitBranchSnapshot = new GitBranchSnapshot(snapshotId, true);
        GitBranchRepository gitBranchRepository = new GitBranchRepository(true, branchNames);
        GitBranchRequestWrapper gitBranchRequestWrapper = new GitBranchRequestWrapper(gitBranchRepository, gitBranchSnapshot);
        return gitBranchRequestWrapper;
    }

    /**
    * This method calls pipeline setup endpoint for branch creation and taking production snapshot
    * Returns true if call is succesfull, false if there is a error
    * This endpoint returns started, we do the polling with copado notification record to decide if process ended
    * @return Boolean
    * */
    public Boolean doCalloutForPipelineSetup(GitBranchRequestWrapper requestWrapper){
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
        if(String.isNotBlank(response.error)){
            throw new DefineProductionOrgServiceException(response.error);
        } else {
            copadoJobId = response.copadoJobId;
            JobsManager.createRunningJob(response.copadoJobId, PIPELINE_SETUP, setupWizardSettings.Pipeline_Id__c, 'Starting...');
            return true;
        }
    }

    public class DefineProductionOrgServiceException extends Exception {
    }

    public class GitBranchRequestWrapper {
        GitBranchRepository repository;
        GitBranchSnapshot snapshot;

        public GitBranchRequestWrapper(GitBranchRepository repository, GitBranchSnapshot snapshot){
            this.repository = repository;
            this.snapshot = snapshot;
        }
    }

    public class GitBranchRepository {
        Boolean createMainBranch;
        Boolean createGitIgnore;
        List<String> newBranchNames;

        public GitBranchRepository(Boolean createMainBranch, List<String> newBranchNames){
            this.createMainBranch = createMainBranch;
            this.createGitIgnore = true;
            this.newBranchNames = new List<String>();
            this.newBranchNames.addAll(newBranchNames);
        }
    }

    public class GitBranchSnapshot {
        String id;
        Boolean perform;

        public GitBranchSnapshot(String id, Boolean perform){
            this.id = id;
            this.perform = perform;
        }
    }
}