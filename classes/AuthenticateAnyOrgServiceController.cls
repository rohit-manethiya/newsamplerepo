/**
 * This is the main controller for authentication any org credential by clicking Authenticate button at Pipeline Diagram
 */
public with sharing class AuthenticateAnyOrgServiceController extends WizardHelper implements OrgAuthenticationInterface {

    private Map<String, String> possibleActionStatusMap = new Map<String, String>();
    public String orgType { get; set; }

    /**
     * This method is used to populate possible actions for environment setup inner step
     * Map will store action name and status. Status values are "Pending", "In Progress" and "Done"
     * @return PossibleActionOrder Enum values
     */
    public Map<String, String> getActionNames() {
        for(AuthenticateAnyOrgServiceController.PossibleActionOrder pa : AuthenticateAnyOrgServiceController.PossibleActionOrder.values()) {
            possibleActionStatusMap.put(pa.name(), ActionStatus.Pending.name());
        }
        return possibleActionStatusMap;
    }

    /**
     * This is order of the possible actions for DefineProductionOrgServiceController
     */
    private enum PossibleActionOrder {
        CreateBranch,
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
     * Do not create snapshot in this case, so we will skip environment setup and go to finish
     *
     * @return last step that implemented
     */
    public String getStep() {
        Org__c org = getOrgCredentialFromURL();
        Boolean authenticateOrg = (org.Id != null && org.Oauth_Signature__c != null) ? true : false;

        return authenticateOrg ? ORG_VALIDATION : ORG_AUTHENTICATE;
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
            throw new AuthenticateAnyOrgServiceException(Label.Missing_value_in_call);
        }

        OrgAuthenticationWrapper.SetStepReturnWrapper setStepReturnWrapper = new OrgAuthenticationWrapper.SetStepReturnWrapper();

        if(setStepWrapper.currentInnerStep == ORG_VALIDATION) {
            setStepReturnWrapper.newInnerStep = ENV_SETUP;
            updateDeploymentFlowSteps();
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
        List<Environment__c> envList = new List<Environment__c>();
        if(Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            envList = [SELECT Id FROM Environment__c WHERE Org_ID__c = :UserInfo.getOrganizationId()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new AuthenticateAnyOrgServiceException(errorMessage);
        }
        User currentUser = getCurrentUser();
        String userAlias = !envList.isEmpty() ? currentUser.Alias + '-' : '';

        Org__c org = getOrgCredentialFromURL();
        org.Name = (userAlias + environmentName).left(80);
        org.Org_Type__c = String.isNotBlank(orgType) ? orgType : null;
        try {
            Utilities.Secure_DML(org, Utilities.DML_Action.UPS, schema.SObjectType.Org__c);
        } catch(Exception excp) {
            throw new AuthenticateAnyOrgServiceException(excp.getMessage());
        }
        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, UTF_8) + '&url=' + EncodingUtil.urlEncode(currentUser.API_URL__c, UTF_8);
        if(org.Org_Type__c == 'Sandbox') {
            urlParameters += '&sandbox=true';
        }
//        if(org.Org_Type__c == 'Custom Domain') {
//            urlParameters += '&domain=' + EncodingUtil.urlEncode(org.Custom_Domain__c, 'UTF-8');
//        }
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), UTF_8);
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), UTF_8);
        urlParameters += '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), UTF_8);

        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();
        String lightningUrl = UserInfo.getUiThemeDisplayed().startsWithIgnoreCase('Theme4') ? '/one/one.app#/alohaRedirect/' : '';
        String newComponentName = getNextComponentName('OrgAuthenticationWizard', false);
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + lightningUrl + '/apex/' + namespace + newComponentName;

        if(String.isNotBlank(pipelineId)) {
            newComponentURL += '?pipelineId=' + pipelineId;
        }
        if(String.isNotBlank(environmentId)) {
            newComponentURL += '&envId=' + environmentId;
        }
        if(String.isNotBlank(environmentName)) {
            newComponentURL += '&envName=' + EncodingUtil.urlEncode(environmentName, UTF_8);
        }
        if(String.isNotBlank(oauthStage) && oauthStage == 'true') {
            newComponentURL += '&authStage=true';
        }
        if(String.isNotBlank(branchName)) {
            newComponentURL += '&branch=' + EncodingUtil.urlEncode(branchName, UTF_8);
        }
        if(String.isNotBlank(org.Id)) {
            newComponentURL += '&orgId=' + org.Id;
        }
        urlParameters += '&startURL=' + EncodingUtil.urlEncode(newComponentURL, UTF_8);
        System.debug('urlParameters... ' + urlParameters);

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
     * This method is updating a deployment flow steps to populate Destination and Source Environment fields after environment is created
     * When process is done, update stopUpdatingDeploymentFlowStepsPoller boolean variable with true to stop updating deployment flow steps poller
     */
    public void updateDeploymentFlowSteps() {
        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        Org__c org = getOrgCredentialFromURL();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            for(Deployment_Flow_Step__c dfs : [SELECT Id, Branch__c, Destination_Branch__c, Destination_Environment__c, Source_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId]) {
                if((dfs.Destination_Branch__c != null && String.isNotBlank(branchName)) && (dfs.Destination_Branch__c.toLowerCase() == branchName)) {
                    dfs.Destination_Environment__c = org.Environment__c;
                    dfsList.add(dfs);
                } else if(String.isNotBlank(branchName) && dfs.Branch__c.toLowerCase() == branchName) {
                    dfs.Source_Environment__c = org.Environment__c;
                    dfsList.add(dfs);
                }
            }
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new AuthenticateAnyOrgServiceException(errorMessage);
        }

        if(!dfsList.isEmpty()) {
            try {
                Utilities.Secure_DML(dfsList, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow_Step__c);
            } catch(Exception excp) {
                throw new AuthenticateAnyOrgServiceException(excp.getMessage());
            }
        }
    }

    /**
     * This method is creating a snapshot for org
     * When snapshot is done, update stopCreatingSnapshotPoller boolean variable with true to stop creating snapshot action poller
     */
    public void createOrgSnapshot() {
        Org__c org = getOrgCredentialFromURL();
        User currentUser = getCurrentUser();
        String branchNames = org.Name.removeStartIgnoreCase(currentUser.Alias).toLowerCase().trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
        Deployment_Flow__c pipeline = getPipelineFromURL();
        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, pipeline.Git_Repository__c, branchNames);

        if(snapshot.Id == null) {
            // TODO check field level access before insert
            Git_Backup__c gitSnapshot = new Git_Backup__c();
            gitSnapshot.Name = org.Name + System.now();
            gitSnapshot.Branch__c = branchNames;
            gitSnapshot.Git_Repository__c = pipeline.Git_Repository__c;
            gitSnapshot.Org__c = org.Id;
            gitSnapshot.Frequency__c = 'None';
            gitSnapshot.Git_Snapshot_Permissions__c = 'Allow Commits Only';

            try {
                System.debug('**f**gitSnapshot : ' + gitSnapshot);
                Utilities.Secure_DML(gitSnapshot, Utilities.DML_Action.INS, schema.SObjectType.Git_Backup__c);
            } catch(Exception excp) {
                throw new AuthenticateAnyOrgServiceException(excp.getMessage());
            }
        }
    }

    /**
     * This is used to check the status for records
     * If everything is done, update the status as 'Done'
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper getRecordsStatus() {
        Org__c org = getOrgCredentialFromURL();

        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            dfsList = [SELECT Id FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId AND (Destination_Environment__c = :org.Environment__c OR Source_Environment__c = :org.Environment__c)];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new AuthenticateAnyOrgServiceException(errorMessage);
        }

        Deployment_Flow__c pipeline = getPipelineFromURL();
        User currentUser = getCurrentUser();
        String branchNames = org.Name.toLowerCase().removeStartIgnoreCase(currentUser.Alias).trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
        Git_Backup__c snapshot = checkIfSnapshotExist(org.Id, pipeline.Git_Repository__c, branchNames);

        OrgAuthenticationWrapper.ResponseActionPollerWrapper responseActionWrapper = new OrgAuthenticationWrapper.ResponseActionPollerWrapper();
        if(!dfsList.isEmpty() && snapshot.Id != null) {
            possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.Done.name());
            responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
            //responseActionWrapper.stopCreatingBranchesPoller = false;
            updateSetupWizardCustomSetting(null, null, null, null, null, null, PossibleActionOrder.AllActionsDone.name());
            return responseActionWrapper;
        }
        possibleActionStatusMap.put(PossibleActionOrder.RecordsCreated.name(), ActionStatus.InProgress.name());
        responseActionWrapper.stopCreatingRecordsPoller = false;
        responseActionWrapper.possibleActionStatusMap = possibleActionStatusMap;
        return responseActionWrapper;
    }

    public class AuthenticateAnyOrgServiceException extends Exception {
    }
}