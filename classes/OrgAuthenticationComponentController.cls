/**
 * This is the controller for OrgAuthentication component
 */
public with sharing class OrgAuthenticationComponentController extends WizardHelper {
    // Non Constants
    public String currentOrgAuthenticateStep { get; set; }
    public String validationMessage { get; set; }
    public String selectedOperation { get; set; }
    public Org__c orgCredential { get; set; }
    public Boolean wizardFirstStep { get; set; }
    public Boolean useCustomSettingOrgCredential { get; set; }
    public Boolean validOrg { get; set; }
    public Boolean wrongOrgCredential { get; set; }
    public String newEnvironmentSelected { get ; set; }
    public String isDirectDiagramAuthentication { get ; set; }
    public String isCredentialNewOrExisting { get; set; }
    public Map<String, String> actionNameStatusMap { get; set; }
    public Boolean allowSkip { get; set; }
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper actionWrapper { get; set; }
    @TestVisible private Map<Id, Environment__c> environmentMap;
    private OrgAuthenticationInterface authenticateInterface;

    /**
     * Constructor
     * Prepares necessary service layer and also passes initial values to the OrgAuthentication component
     */
    public OrgAuthenticationComponentController() {
        initializeServiceClasses();
        isDirectDiagramAuthentication = ApexPages.currentPage().getParameters().get('diagramAuth');
        if(String.isNotBlank(environmentId) && String.isNotBlank(environmentName) && oauthStage == 'true') {
            getEnvironments();
            newEnvironmentSelected = environmentId + '##' + environmentName;
        }
        allowSkip = false;
        if(authenticateInterface != null) {
            actionNameStatusMap = authenticateInterface.getActionNames();
            orgCredential = authenticateInterface.getOrgCredential(useCustomSettingOrgCredential);
            currentOrgAuthenticateStep = authenticateInterface.getStep(); // this will return inner step by using OrgAuthenticationInterface interface
            checkOrgValidation();

            environmentMap = new Map<Id, Environment__c>();
            actionWrapper = new OrgAuthenticationWrapper.ResponseActionPollerWrapper();
            selectedOperation = YES;

            wrongOrgCredential = isAuthenticatedWithWrongOrgCredential();
        }
    }
    /**
     * Created to pass the org type that is selected in the UI to the service during authentication operation from the PipelineDiagram
     */
    public void setServiceOrgType() {
        if(authenticateInterface instanceof AuthenticateAnyOrgServiceController) {
            ((AuthenticateAnyOrgServiceController) authenticateInterface).orgType = orgCredential.Org_Type__c;
        }
    }

    /**
     * It is used to check if a user authenticate main org with wrong credentials
     *
     * @return if mainOrgList is not empty and it is first step, return true
     */
    private Boolean isAuthenticatedWithWrongOrgCredential() {
        User currentUser = getCurrentUser();
        String userOrgName = (currentUser.Alias + '-' + UserInfo.getOrganizationName()).left(80);

        List<Org__c> mainOrgList;
        if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            mainOrgList = [SELECT Id, Org_Type__c, Username__c, Custom_Domain__c, Oauth_Signature__c FROM Org__c WHERE Name = :userOrgName AND Username__c != :UserInfo.getUserName()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
        }
        return mainOrgList != null && !mainOrgList.isEmpty() && wizardFirstStep;
    }

    /**
     * Strategy pattern
     * Based on the page content, different services will be initialised by using OrgAuthenticationInterface interface
     * First step on wizard will initialize ProductionOrgServiceController()
     * Fifth step on wizard will initialize DefineProductionOrgServiceController()
     * Authentication any org from pipeline diagram will initialize AuthenticateAnyOrgServiceController()
     * Creating new environment from pipeline diagram will initialize ProductionOrgServiceController()
     * @see OrgAuthenticationInterface
     */
    private void initializeServiceClasses() {
        String oauthStage = ApexPages.currentPage().getParameters().get('authStage');
        String newOrg = ApexPages.currentPage().getParameters().get('newOrgCredential');
        wizardFirstStep = false;
        useCustomSettingOrgCredential = false;
        //String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm(); There is no way to get url in text class by using this so commented and changed with Apexpages
        String currentRequestURL = ApexPages.currentPage().getUrl();
        if(currentRequestURL.containsIgnoreCase(SetupPipelineOrder.OrgAuthenticationInstallWizard.name())) {
            authenticateInterface = new ProductionOrgServiceController();
            wizardFirstStep = true;
        } else if(currentRequestURL.containsIgnoreCase(SetupPipelineOrder.OrgAuthenticationWizard.name()) && String.isBlank(oauthStage) && String.isBlank(newOrg)) {
            authenticateInterface = new DefineProductionOrgServiceController();
            useCustomSettingOrgCredential = true;
        } else if(String.isNotBlank(oauthStage) && oauthStage == 'true') {
            authenticateInterface = new AuthenticateAnyOrgServiceController();
        } else if(String.isNotBlank(newOrg) && newOrg == 'true') {
            authenticateInterface = new NewEnvironmentServiceController();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Unsupported_Service));
        }
    }

    /**
     * This methods updates the internal step values
     * If the current step is orgauthenticate and user click on yes, update the production org id at custom setting
     */
    public void setStep() {
        try {
            OrgAuthenticationWrapper.SetStepWrapper setStepWrapper = new OrgAuthenticationWrapper.SetStepWrapper();
            setStepWrapper.currentInnerStep = currentOrgAuthenticateStep;
            setStepWrapper.createNewOrg = selectedOperation == YES ? false : true; // it will create new org credential if operation is "NO", check DefineProductionOrgServiceController
            OrgAuthenticationWrapper.SetStepReturnWrapper setStepReturnWrapper = authenticateInterface.setStep(JSON.serialize(setStepWrapper));
            currentOrgAuthenticateStep = setStepReturnWrapper.newInnerStep;
            actionNameStatusMap = setStepReturnWrapper.possibleActionStatusMap;
            actionWrapper.stopTakingSnapshotPoller = setStepReturnWrapper.stopTakingSnapshotPoller;
            actionWrapper.stopCreatingRecordsPoller = setStepReturnWrapper.stopCreatingRecordsPoller;
            actionWrapper.stopCreatingBranchesPoller = setStepReturnWrapper.stopCreatingBranchesPoller;
        } catch(DmlException dmlEx) {
            handleError(dmlEx.getDmlMessage(0), new List<String>(), '');
        } catch(Exception excp) {
            handleException(excp);
            return ;
        }
    }

    /**
     * Page redirection will work on page load based on some criteria by using the OrgAuthenticationInterface interface
     * @see initializeServiceClasses
     * @see OrgAuthenticationInterface
     *
     * @return any wizard step
     */
    public PageReference pageRedirectOnLoad() {
        try {
            return authenticateInterface.pageRedirectOnLoad();
        } catch(Exception excp) {
            handleException(excp);
            return null;
        }
    }

    /**
     * Org authentication will work by using the OrgAuthenticationInterface interface
     * @see initializeServiceClasses
     * @see OrgAuthenticationInterface
     *
     * @return Salesforce login page
     */
    public PageReference doOauth() {
        try {
            setServiceOrgType();
            return authenticateInterface.doOauth();
        } catch(Exception excp) {
            handleException(excp);
            return null;
        }
    }

    /**
     * This method is used to check if org credential is validated or not
     * IT is only one line and used at actionfunction because we can not do callout after DML statement.
     */
    public void checkOrgValidation() {
        if(selectedOperation == YES) {
            orgCredential = getUserOrgCredential();
        }
        validOrg = (orgCredential.Id != null && DeployAPI.validateOrg(orgCredential.Id)) ? true : false;
        validationMessage = validOrg ? Label.Credential_Authenticated_Successfully : Label.Credential_Not_Authenticated_Successfully;
    }

    /**
     * This is the main method to run all action by using the OrgAuthenticationInterface interface
     * @see initializeServiceClasses
     * @see OrgAuthenticationInterface
     */
    public void runAction() {
        try {
            actionWrapper = authenticateInterface.runAction();
            actionNameStatusMap = actionWrapper.possibleActionStatusMap;
            allowSkip = enableSkip();
        } catch(Exception excp) {
            handleException(excp);
            return ;
        }
    }
    /**
     * If snapshot operation took more than 2 hours enable skip button
     * @return Boolean allowSkip
     */
    private Boolean enableSkip() {
        setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        //snapshot record is not yet created dont wait
        if(String.isEmpty(setupWizardSettings.Git_Snapshot_Id__c)) {
            return false;
        } else {
            try {
                //security check
                if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                    Git_Backup__c currentSnapshot = [SELECT Id,CreatedDate FROM Git_Backup__c WHERE Id = :setupWizardSettings.Git_Snapshot_Id__c];
                    Long elapsedTime = (System.now().getTime() - currentSnapshot.CreatedDate.getTime()) / 3600000;
                    if(elapsedTime >= 1) {
                        return true;
                    }
                }
            } catch(Exception ex) {
                // record is deleted or not accessible so enable skip since status cannot be checked anymore
                return true;
            }
            return false;
        }
    }

    /**
     * This method is used to populate select radio options at component
     * YES, is representing to use existing production org as main org
     * NO, is representing to create new production org for pipeline
     *
     * @return selectoption values
     */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(YES, YES));
        options.add(new SelectOption(NO, NO));
        return options;
    }

    /**
     * This method populates autocomplete combobox to select an org credential.
     * @return list of possibles org credentials to select in Name field. Only first 100 results.
     */
    public List<Environment__c> getEnvironments() {
        if(environmentMap != null && !environmentMap.isEmpty()) {
            return environmentMap.values();
        }
        Set<Id> envIdsSet = new Set<Id>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            for(Deployment_Flow_Step__c dfs : [SELECT Destination_Environment__c, Source_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId]) {
                envIdsSet.add(dfs.Destination_Environment__c);
                envIdsSet.add(dfs.Source_Environment__c);
            }
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow_Step__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
            return null;
        }

        if(Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            List<Environment__c> envList = [SELECT Id, Name, Type__c FROM Environment__c WHERE Id NOT IN :envIdsSet ORDER BY Name LIMIT 1000];
            environmentMap = new Map<Id, Environment__c>(envList);
            return envList;
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Environment__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
            return null;
        }
    }

    /**
     * This is used to render Continue button at last step
     *
     * @return
     */
    public Boolean getAllActionIsDone() {
        setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        String actionName = String.isNotBlank(setupWizardSettings.Wizard_Last_Action__c) ? setupWizardSettings.Wizard_Last_Action__c : String.isNotBlank(setupWizardSettings.Diagram_Last_Action__c) ? setupWizardSettings.Diagram_Last_Action__c : '';
        return (String.isNotBlank(actionName) && actionName == 'AllActionsDone');
    }

    /**
     * Assign environment value in javascript function in OrgAuthentication.component
     * If Environment already exists, populate org Type.
     */
    public void checkAndAssignEnvironment() {
        String newEnvironmentSelectedId = newEnvironmentSelected.substringBefore('##');
        if(authenticateInterface instanceof NewEnvironmentServiceController) {
            ((NewEnvironmentServiceController) authenticateInterface).envName = newEnvironmentSelected;
            ((NewEnvironmentServiceController) authenticateInterface).envType = orgCredential.Org_Type__c;
        }
        if(newEnvironmentSelected.contains('##') && environmentMap.containsKey(newEnvironmentSelectedId)) {
            Environment__c env = environmentMap.get(newEnvironmentSelectedId);
            //this check is for prevent overriding selected type when method triggered with picklist change
            if(orgCredential.Name == env.Name.left(80)) {
                return;
            }
            orgCredential.Name = env.Name.left(80);
            orgCredential.Org_Type__c = env.Type__c;
            orgCredential.Environment__c = newEnvironmentSelectedId;
            isCredentialNewOrExisting = 'existing';
        } else {
            isCredentialNewOrExisting = String.isNotBlank(newEnvironmentSelected) ? 'isnew' : isCredentialNewOrExisting;
        }
    }

    public PageReference createNewEnvironmentConnection() {
        PageReference pReference = Page.OrgAuthenticationWizard;
        if(String.isNotBlank(pipelineId)) {
            pReference.getParameters().put(PIPELINE_ID, pipelineId);
        }
        if(String.isNotBlank(environmentId)) {
            pReference.getParameters().put(ENV_ID, environmentId);
        }
        String existingOrgId = '';
        if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            List<Org__c> orgList = [SELECT Id FROM Org__c WHERE Environment__c = :orgCredential.Environment__c AND Org_Type__c = :orgCredential.Org_Type__c LIMIT 1];
            existingOrgId = orgList.isEmpty() ? existingOrgId : orgList[0].Id;
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
            return null;
        }
        if(String.isNotBlank(existingOrgId)) {
            pReference.getParameters().put('orgId', existingOrgId);
        } else {
            String errorMessage = Label.Connection_Has_Not_Shared_With_You;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
            return null;
        }
        if(String.isNotBlank(newOrg) && newOrg == 'true') {
            pReference.getParameters().put('newOrgCredential', 'true');
        }

        String useStep = ApexPages.currentPage().getParameters().get('useStep');
        String flowStepId = ApexPages.currentPage().getParameters().get('flowStepId');
        if(String.isNotBlank(useStep)) {
            pReference.getParameters().put('useStep', useStep);
        }
        if(String.isNotBlank(flowStepId)) {
            pReference.getParameters().put('flowStepId', flowStepId);
        }

        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to open snapshot detail page in a new tab while taking production snapshot
     *
     * @return snapshot detail page
     */
    public PageReference goToSnapshot() {
        PageReference pReference = new PageReference('/' + setupWizardSettings.Git_Snapshot_Id__c);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to go to diagram of current pipeline when user does not want to add new env
     *
     * @return pipeline diagram
     */
    public PageReference goToDiagram() {
        PageReference pReference = Page.PipelineManager;
        pReference.getParameters().put('Id', pipelineId);
        pReference.getParameters().put('mode', 'diagram');
        pReference.setRedirect(true);
        return pReference;
    }
}