/**
 * This is generic class for wizard components
 */
public with sharing virtual class WizardHelper {
    // Non Constant
    public Setup_Wizard_Steps__c setupWizardSettings { get; set; }
    public UIDesignHelper.CustomExceptionData errorMessage { get; set; }
    public String errorMessageJSON { get; set; }
    public String namespace { get; set; }
    public String environmentName { get; set; }
    public String isOrgAuthentication { get; set; }
    public String newOrg { get; set; }
    public String oauthStage { get; set; }
    public String isNewPipeline { get; set; }
    public String pipelineId { get; set; }
    public String branchName { get; set; }
    public String environmentId { get; set; }

    // Constants
    public final String ORG_AUTHENTICATE = 'authOrg';
    public final String ORG_VALIDATION = 'orgvalidation';
    public final String ENV_SETUP = 'environmentsetup';
    public final String NEW_ENV = 'createOrgCredential';
    public final String UTF_8 = 'UTF-8';
    public final String GIT_ORG_BACKUP = 'GitOrgBackup';
    public final String PIPELINE_SETUP = 'PipelineSetupJob';
    public final String GIT_BACKUP = 'Git Backup';
    public final String PIPELINE_ID = 'pipelineId';
    public final String NEW_PIPELINE = 'newPipeline';
    public final String ENV_ID = 'envId';
    public final String YES = 'Yes';
    public final String NO = 'No';
    public final String CURRENT_PAGE = 'currentPage';

    /**
     * This is order of the wizard pages
     */
    public enum SetupPipelineOrder {
        SetupWizardStart,
        OrgAuthenticationInstallWizard,
        CopadoLicensesWizard,
        PipelineSettingsWizard,
        PipelineTemplatesWizard,
        OrgAuthenticationWizard,
        SetupWizardFinish
    }

    /**
     * This is order of the possible action status
     */
    public enum ActionStatus {
        Pending,
        InProgress,
        Done
    }

    public WizardHelper() {
        setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        errorMessage = new UIDesignHelper.CustomExceptionData();
        errorMessageJSON = '';
        namespace = Settings.ns;

        environmentName = ApexPages.currentPage().getParameters().get('envName');
        newOrg = ApexPages.currentPage().getParameters().get('newOrgCredential');
        oauthStage = ApexPages.currentPage().getParameters().get('authStage');
        pipelineId = ApexPages.currentPage().getParameters().get(PIPELINE_ID);
        branchName = ApexPages.currentPage().getParameters().get('branch');
        isNewPipeline = ApexPages.currentPage().getParameters().get(NEW_PIPELINE);
        environmentId = ApexPages.currentPage().getParameters().get('envId');
        isOrgAuthentication = ApexPages.currentPage().getParameters().get('isOrgAuthentication');
    }

    /**
     * generic json parser for UIDesignHelper.CustomExceptionData wrapper class
     * @param eMessage
     * @param jsonString
     * @return UIDesignHelper.CustomExceptionData wrapper class value
     */
    public void jsonParser(String jsonString) {
        errorMessage = (UIDesignHelper.CustomExceptionData) JSON.deserialize(jsonString, UIDesignHelper.CustomExceptionData.class);
    }

    /**
     * Updating custom setting values
     *
     * @param newStepValue
     * @param Org_Credential_Id__c
     * @param Git_Repository_Id__c
     * @param Pipeline_Id__c
     * @param Git_Snapshot_Id__c
     */
    public void updateSetupWizardCustomSetting(String newStepValue, String orgCredentialId, String gitRepoId, String pipelineId, String snapshotId, String wizardActionName, String diagramActionName) {
        setupWizardSettings.Last_Step__c = String.isNotBlank(newStepValue) ? newStepValue : setupWizardSettings.Last_Step__c;
        setupWizardSettings.Org_Credential_Id__c = String.isNotBlank(orgCredentialId) ? orgCredentialId : setupWizardSettings.Org_Credential_Id__c;
        setupWizardSettings.Git_Repository_Id__c = String.isNotBlank(gitRepoId) ? gitRepoId : setupWizardSettings.Git_Repository_Id__c;
        setupWizardSettings.Pipeline_Id__c = String.isNotBlank(pipelineId) ? pipelineId : setupWizardSettings.Pipeline_Id__c;
        setupWizardSettings.Git_Snapshot_Id__c = String.isNotBlank(snapshotId) ? snapshotId : setupWizardSettings.Git_Snapshot_Id__c;
        setupWizardSettings.Wizard_Last_Action__c = String.isNotBlank(wizardActionName) ? wizardActionName : setupWizardSettings.Wizard_Last_Action__c;
        setupWizardSettings.Diagram_Last_Action__c = String.isNotBlank(diagramActionName) ? diagramActionName : setupWizardSettings.Diagram_Last_Action__c;
        Utilities.Secure_DML(setupWizardSettings, Utilities.DML_Action.UPS, schema.SObjectType.Setup_Wizard_Steps__c);
    }

    /**
     * This method is used to check user licenses on component load function
     * If there is licenses assigned, update the "Last_Step__c" field of the custom setting with "PipelineSettings" value
     * Do not check isQueryable for custom settings.
     *
     * @return Boolean false if no licenses assigned
     * @return Boolean true if user has license
     */
    public List<Copado_License__c> doesUserHaveLicense() {
        //no need to add security check because this is a custom setting
        return [
                SELECT Id, Enable_CCM__c, Enable_Copado__c
                FROM Copado_License__c
                WHERE SetupOwnerId = :UserInfo.getUserId() AND (Enable_Copado__c = TRUE OR Enable_CCM__c = TRUE)
        ];
    }

    /**
    * This methods check if git repository is validated
    *
    * @return Boolean
    */
    public Boolean isGitRepositoryValidated(String gitRepositoryId) {
        DeployAPI.validateGitResult validation = DeployAPI.validateGit(gitRepositoryId);
        if(validation.success == false) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, validation.message);
        }
        return validation.success;
    }

    /**
    * This methods handles rendering error panel for exceptions
    *
    * @return void
    */
    public void handleException(Exception excp) {
        List<String> stepsToFix = new List<String>{
        };
        if(String.isNotBlank(excp.getMessage()) && excp.getMessage().startsWithIgnoreCase(Label.INSUFFICENT_ACCESS)) {
            stepsToFix.add(Label.Update_Permission);
        }
        errorMessage = new UIDesignHelper.CustomExceptionData(ApexPages.Severity.ERROR, excp.getMessage(), stepsToFix, 0, '', '');
        errorMessageJSON = JSON.serialize(errorMessage);
    }

    /**
    * This methods handles rendering error panel for exceptions
    *
    * @return void
    */
    public void handleError(String errorMsg, List<String> stepsToFix, String actionName) {
        errorMessage = new UIDesignHelper.CustomExceptionData(ApexPages.Severity.ERROR, errorMsg, stepsToFix, 0, '', actionName);
        errorMessageJSON = JSON.serialize(errorMessage);
    }

    /**
     * This methods redirects to the previous component by using SetupPipelineOrder enum.
     * Checking the existing page url host and comparing with next step page's host, it is necessary for salesforce security (false positive issue)
     * Usage:
     * 1- After clicking on "Ok I'll try again" button at the end of ErrorComponent
     *
     * @return next component pages
     */
    public PageReference goToPreviousComponent() {
        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();

        Integer currentComponentOrder = 0;
        for(SetupPipelineOrder spo : SetupPipelineOrder.values()) {
            if(currentRequestURL.containsIgnoreCase(String.valueOf(spo))) {
                currentComponentOrder = spo.ordinal();
            }
        }
        Integer order = currentComponentOrder - 1;
        String newComponentName = String.valueOf(SetupPipelineOrder.values()[order]);
        updateSetupWizardCustomSetting(newComponentName, null, null, null, null, null, null);

        String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
        PageReference pReference = new PageReference(newComponentURL);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * This methods redirects to the next component by using SetupPipelineOrder enum.
     * Checking the existing page url host and comparing with next step page's host, it is necessary for salesforce security (false positive issue)
     * Usage:
     * 1- After clicking on "Continue" button at the end of Component steps
     * 2- If component steps are already completed it will be called at construction (PipelineSettingComponentController, OrgAuthenticationComponentController)
     *
     * @return next component pages
     */
    public PageReference goToNextComponent() {
        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = ApexPages.currentPage().getUrl();
        //String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();
        String newComponentName = getNextComponentName(currentRequestURL, true);
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
        String pipelineId = ApexPages.currentPage().getParameters().get(PIPELINE_ID);
        PageReference pReference = new PageReference(newComponentURL);
        if(String.isNotBlank(pipelineId)) {
            pReference.getParameters().put(PIPELINE_ID, pipelineId);
        }
        if(String.isNotBlank(isNewPipeline) && isNewPipeline == 'true') {
            pReference.getParameters().put(NEW_PIPELINE, isNewPipeline);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * This methods redirects to the next component by using SetupPipelineOrder enum and existing Custom setting value stored in "Last_Step__c"
     *
     * @param existingLastStepValue Custom setting value stored in "Last_Step__c"
     *
     * @return next component pages
     */
    public PageReference goToNextComponent(String existingLastStepValue) {
        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        if(String.isBlank(existingLastStepValue)) {
            Schema.DescribeSObjectResult result = Deployment_Flow__c.SObjectType.getDescribe();
            PageReference pipelineTabReference = new PageReference('/' + result.getKeyPrefix()); //return to Pipeline tab
            pipelineTabReference.setRedirect(true);
            return pipelineTabReference;
        }
        String newComponentName = getNextComponentName(existingLastStepValue, false);
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
        PageReference pReference = new PageReference(newComponentURL);
        if(String.isNotBlank(isNewPipeline) && isNewPipeline == 'true') {
            pReference.getParameters().put(NEW_PIPELINE, isNewPipeline);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * This method is used to find next component order by using given existing component name
     * Before redirect to next page, we have to update custom setting "Last_Step__c" field with new component name, so other parameters are null
     *
     * @param valueToCheck existing component name for current step
     * @param checkNext true for asking the next step custom setting value, false for auto redirection
     *
     * @return order number of the next component in SetupPipelineOrder enum
     */
    public String getNextComponentName(String valueToCheck, Boolean checkNext) {
        Integer currentComponentOrder = 0;
        for(SetupPipelineOrder spo : SetupPipelineOrder.values()) {
            if(valueToCheck.containsIgnoreCase(String.valueOf(spo))) {
                currentComponentOrder = spo.ordinal();
            }
        }
        Integer order = checkNext ? (currentComponentOrder + 1) : currentComponentOrder;
        // Checking the total page size for wizard to avoid error for last step
        Integer validComponentOrder = order == SetupPipelineOrder.values().size() ? (order - 1) : order;
        String newComponentName = String.valueOf(SetupPipelineOrder.values()[validComponentOrder]);
        if(String.isBlank(oauthStage) && String.isBlank(newOrg)) {
            updateSetupWizardCustomSetting(newComponentName, null, null, null, null, null, null);
        }
        return newComponentName;
    }

    /**
     * This method is used to retrieve main org with copado package is installed,
     * Check it with current user's email
     *
     * @return Org Credential record
     */
    public Org__c getUserOrgCredential() {
        List<Org__c> mainOrgList;
        if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            mainOrgList = [SELECT Id, Org_Type__c, Username__c, Custom_Domain__c, Oauth_Signature__c FROM Org__c WHERE Username__c = :UserInfo.getUserName()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
        }
        return (mainOrgList != null && !mainOrgList.isEmpty()) ? mainOrgList[0] : new Org__c();
    }

    /**
     * This method is used to retrieve last created org for orgAuthentication process
     *
     * @return Org Credential record
     */
    public Org__c getOrgCredentialFromCustomSetting() {
        List<Org__c> mainOrgList;
        if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            mainOrgList = [SELECT Id, Name, Org_Type__c, Username__c, Custom_Domain__c, Oauth_Signature__c, Environment__c FROM Org__c WHERE Id = :setupWizardSettings.Org_Credential_Id__c];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
        }
        return (mainOrgList != null && !mainOrgList.isEmpty()) ? mainOrgList[0] : new Org__c();
    }

    /**
     * This method is used to retrieve org credential from url
     *
     * @return Org Credential record
     */
    public Org__c getOrgCredentialFromURL() {
        Org__c org = new Org__c();
        String orgId = ApexPages.currentPage().getParameters().get('orgId');
        if(String.isNotBlank(orgId)) {
            if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
                org = [SELECT Id, Name, Org_Type__c, Custom_Domain__c, Oauth_Signature__c, Username__c, Environment__c, Environment__r.Type__c FROM Org__c WHERE Id = :orgId];
            } else {
                String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
                handleError(errorMessage, new List<String>{
                        Label.Update_Permission
                }, CURRENT_PAGE);
            }
        }
        return org;
    }

    /**
     * This method is used to retrieve pipeline from url
     *
     * @return Deployment_Flow__c record
     */
    public Deployment_Flow__c getPipelineFromURL() {
        Deployment_Flow__c pipeline = new Deployment_Flow__c();
        String pipelineId = ApexPages.currentPage().getParameters().get(PIPELINE_ID);
        if(String.isNotBlank(pipelineId)) {
            if(Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                pipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Id = :pipelineId];
            } else {
                String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow__c.label;
                handleError(errorMessage, new List<String>{
                        Label.Update_Permission
                }, CURRENT_PAGE);
            }
        }
        return pipeline;
    }

    /**
     * This method is used to check if existing org has a snapshot
     *
     * @return Git_Backup__c record
     */
    public Git_Backup__c checkIfSnapshotExist(Id orgId, Id repoId, String branchName) {
        List<Git_Backup__c> snapshotList = new List<Git_Backup__c>();
        if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            snapshotList = [SELECT Id FROM Git_Backup__c WHERE Org__c = :orgId AND Git_Repository__c = :repoId AND Branch__c = :branchName LIMIT 1];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
        }
        return !snapshotList.isEmpty() ? snapshotList[0] : new Git_Backup__c();
    }

    /**
     * This method is used to retrieve current user information
     *
     * @return
     */
    public User getCurrentUser() {
        User currentUser = new User();
        if(Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
            currentUser = [SELECT API_URL__c, Alias FROM User WHERE Id = :UserInfo.getUserId()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            handleError(errorMessage, new List<String>{
                    Label.Update_Permission
            }, CURRENT_PAGE);
            return null;
        }
        return currentUser;
    }

    public Boolean hasValidCopadoOrgCredential() {
        Org__c userOrgCredential = getUserOrgCredential();
        Boolean userHasOrg = userOrgCredential.Id != null ? true : false;
        Boolean userHasValidOrg = (userHasOrg && DeployAPI.validateOrg(userOrgCredential.Id)) ? true : false;
        if(!userHasOrg || (userHasOrg && !userHasValidOrg)) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * Generates user API key after authenticating to the copado org credential
     * @see future
     * @see DeployAPI
     */
    @Future(Callout=true)
    public static void generateUserAPIKey() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if(String.isBlank(ps.API_Key__c)) {
            DeployAPI.createAPIKey();
        }
    }

    /**
     * This method is used to redirect to the Pipeline tab
     * It is called by commandlink at components by clicking "Save & Close"
     * @return
     */
    public PageReference goToHomePage() {
        PageReference pageRef = new PageReference('/' + Schema.SObjectType.Deployment_Flow__c.getKeyPrefix());
        pageRef.setRedirect(true);
        return pageRef;
    }
}