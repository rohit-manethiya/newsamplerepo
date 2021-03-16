/**
 * This is the controller for PipelineSettings component
 * User can create pipeline by selecting "Github", "GitLab", "Bitbucket", "Microsoft Team Service" or "Others"
 */
public with sharing class PipelineSettingsComponentController extends WizardHelper {
    public PipelineSettingsOrder currentPipelineStep;
    public String currentPipelineStepName { get; set; }
    public Deployment_Flow__c newPipeline { get; set; }
    public Git_Repository__c gitRepository { get; set; }
    public String gitAuthTypeValue { get; set; }
    public String gitRepositoryUsername { get; set; }
    public String gitRepositoryPassword { get; set; }
    public String gitRepositoryRepoName { get; set; }
    public String gitRepositoryExtraHeaders { get; set; }
    public String gitRepositorySshKey { get; set; }
    public Boolean isUrlsPopulatedByMethod { get; set; }
    private Boolean isGitRepoValid { get; set; }
    private String providerBranchBaseUrl { get; set; }
    private String providerCommitBaseUrl { get; set; }
    private String providerPullBaseUrl { get; set; }
    private String providerTagBaseUrl { get; set; }
    @TestVisible private Map <Id, Git_Repository__c> gitRepositoryMap { get; set; }

    //Constants
    private final String BRANCH_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/{1}/';
    private final String COMMIT_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/commit/';
    private final String PR_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/';
    private final String TAG_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/{1}/';
    private final String VS_BRANCH_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/{1}/';
    private final String VS_COMMIT_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/';
    private final String VS_PR_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/';
    private final String VS_TAG_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/{1}/';
    private final String GITHUB_COM = 'github.com';
    private final String BITBUCKET_ORG = 'bitbucket.org';
    private final String GITLAB_COM = 'gitlab.com';
    private final String VISUALSTUDIO_COM = 'visualstudio.com';
    private final String BITBUCKET_PROVIDER = 'Bitbucket';
    private final String MTS_PROVIDER = 'Microsoft Team Service';
    private final String EXTRA_HEADERS = 'Extra Headers';
    private final String MAIN_PIPELINE = 'Main Pipeline';
    private final String USERNAME = '{Username}';
    private final String REPOSITORY_NAME = '{RepositoryName}';
    @TestVisible private final String HTTPS_STRING = 'https';
    @TestVisible private final String SSH_STRING = 'ssh';

    /**
     * This is order of the pipeline settings internal steps
     */
    public enum PipelineSettingsOrder {
        PipelineName,
        GitRepositorySelection,
        GitAuthenticationDetails,
        GitAuthenticationSuccess,
        GitBaseUrls
    }

    public PipelineSettingsComponentController() {
        List<Copado_License__c> userHasLicense = doesUserHaveLicense();
        if(userHasLicense.isEmpty()){
            handleError('You need a license to continue', new List<String>{'Ask your System Administrator to assign you license'}, 'PipelineSettings');
            return;
        }
        newPipeline = new Deployment_Flow__c();
        gitRepository = new Git_Repository__c();
        currentPipelineStepName = getStep();
        isUrlsPopulatedByMethod = false;
        isGitRepoValid = false;
        if(currentPipelineStepName == PipelineSettingsOrder.GitAuthenticationDetails.name()) {
            prepareAuthStep();
        } else if(currentPipelineStepName == PipelineSettingsOrder.GitBaseUrls.name()) {
            populateURLFields();
        }
    }

    /**
    * This method checks for last pipeline step. available steps are...
    * 1. Pipeline record creation
    * 2. Selecting git repo for pipeline
    * 3. If git repo hast auth
    * @return String internal step name
    * */
    public String getStep() {
        try {
            Boolean noActiveFlow = false;
            Boolean hasGitRepository = false;
            Boolean hasValidatedGitRepository = false;
            List<Deployment_Flow__c> deploymentFlowList = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Id = :setupWizardSettings.Pipeline_Id__c WITH SECURITY_ENFORCED];
            
            noActiveFlow = deploymentFlowList.isEmpty();
    
            if(!noActiveFlow) {
                newPipeline = deploymentFlowList[0];
                hasGitRepository = deploymentFlowList[0].Git_Repository__c != null;
            }
    
            if(hasGitRepository) {
                gitRepository = [SELECT Id, Name, Git_Provider__c, URI__c, Branch_Base_URL__c, Commit_Base_URL__c, Pull_Request_Base_URL__c, Tag_Base_URL__c FROM Git_Repository__c WHERE Id = :newPipeline.Git_Repository__c WITH SECURITY_ENFORCED];
                if(!String.isBlank(gitRepository.URI__c)) {
                    hasValidatedGitRepository = isGitRepositoryValidated(deploymentFlowList[0].Git_Repository__c);
                }
            }
    
            currentPipelineStep = hasValidatedGitRepository ? PipelineSettingsOrder.GitBaseUrls : (hasGitRepository ? PipelineSettingsOrder.GitAuthenticationDetails : (!noActiveFlow) ? PipelineSettingsOrder.GitRepositorySelection : PipelineSettingsOrder.PipelineName);   
        } catch (System.QueryException excp) {
            handleException(excp);
        }
        return currentPipelineStep.name();
    }

    /**
     * Call related action for step and sets next step if action is successfull
     * BaseUrls step is not handled here because it is last one and there is no need to set step
     * @return void
     */
    public void setStep() {
        Integer currentOrder = currentPipelineStep.ordinal();
        Boolean stepResult = false;
        if(currentPipelineStep == PipelineSettingsOrder.PipelineName) {
            stepResult = createPipelineRecord();
        } else if(currentPipelineStep == PipelineSettingsOrder.GitRepositorySelection) {
            stepResult = !checkNameAndProviderFieldValues();
            if(!stepResult) {
                return;
            }

            if(gitRepository.Id != null) {
                isGitRepoValid = isGitRepositoryValidated(gitRepository.Id);
                if(isGitRepoValid) {
                    currentPipelineStep = PipelineSettingsOrder.GitBaseUrls;
                    populateURLFields();
                }
            }
            Utilities.Secure_DML(gitRepository, Utilities.DML_Action.UPS, Schema.SObjectType.Git_Repository__c);
            newPipeline.Git_Repository__c = gitRepository.Id;
            Utilities.Secure_DML(newPipeline, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow__c);
            prepareAuthStep();
        } else if(currentPipelineStep == PipelineSettingsOrder.GitAuthenticationDetails) {
            stepResult = !isGitRepoValid ? false : isGitRepositoryValidated(gitRepository.Id);
        } else if(currentPipelineStep == PipelineSettingsOrder.GitAuthenticationSuccess) {
            populateURLFields();
            stepResult = true;
        }
        currentPipelineStep = stepResult ? PipelineSettingsOrder.values()[currentOrder + 1] : PipelineSettingsOrder.values()[currentOrder];
        updateSetupWizardCustomSetting(null, null, gitRepository.Id, newPipeline.Id, null, null, null);
        currentPipelineStepName = currentPipelineStep.name();
    }

    /**
     * It is used to define which steps to open when user click on "Go Back" link
     *
     * @see PipelineSettingsOrder value
     */
    public void goToPreviousStep() {
        Integer currentStepOrder = 0;
        for(PipelineSettingsOrder stepValue : PipelineSettingsOrder.values()) {
            if(String.isNotBlank(currentPipelineStepName) && currentPipelineStepName.containsIgnoreCase(String.valueOf(stepValue))) {
                currentStepOrder = stepValue.ordinal();
                break;
            }
        }

        // Checking the total step size for component to avoid error for last step
        Integer order = currentStepOrder - 1;
        Integer validStepOrder = (order < 0) ? (order + 1) : order;
        currentPipelineStepName = String.valueOf(PipelineSettingsOrder.values()[validStepOrder]);

        for(PipelineSettingsOrder stepValue : PipelineSettingsOrder.values()) {
            if(String.isNotBlank(currentPipelineStepName) && currentPipelineStepName.containsIgnoreCase(String.valueOf(stepValue))) {
                currentPipelineStep = stepValue;
                break;
            }
        }

        if(currentPipelineStepName == PipelineSettingsOrder.GitAuthenticationDetails.name()) {
            prepareAuthStep();
        }
    }

    /**
    * Create deployment flow and proceed to git repo creation/selection
    * @return Boolean
    */
    public Boolean createPipelineRecord() {
        if(String.isBlank(newPipeline.Name)) {
            newPipeline.Name = MAIN_PIPELINE;
        }
        try {
            newPipeline.Main_Branch__c = 'master';
            Utilities.Secure_DML(newPipeline, Utilities.DML_Action.UPS, Schema.SObjectType.Deployment_Flow__c);
            return true;
        } catch(Exception excp) {
            //return to error page
            handleException(excp);
        }
        return false;
    }

    public void saveGitRepository() {
        Boolean isRequiredFieldsFilled = checkGitRepositoryFields();
        if(!isRequiredFieldsFilled) {
            return;
        }

        if(gitAuthTypeValue == HTTPS_STRING) {
            upsertGitRepositoryConfiguration();
            if(String.isNotBlank(gitRepositoryExtraHeaders)){
                Note extraHeaders = new Note(Title = EXTRA_HEADERS, Body = gitRepositoryExtraHeaders, ParentId = gitRepository.Id);
                Utilities.Secure_DML(extraHeaders, Utilities.DML_Action.UPS, Schema.SObjectType.Note);
            }
        }
        Utilities.Secure_DML(gitRepository, Utilities.DML_Action.UPD, Schema.SObjectType.Git_Repository__c);
    }

    public void upsertGitRepositoryConfiguration() {
        Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(gitRepository.Id);
        if(gitRepositoryConfiguration == null) {
            gitRepositoryConfiguration = new Sensitive_Information__c();
            gitRepositoryConfiguration.Name = gitRepository.Id;
        }
        gitRepositoryConfiguration.Username__c = gitRepositoryUsername;
        gitRepositoryConfiguration.Password__c = DeployAPI.encryptAPIKey(gitRepositoryPassword);

        // protected custom setting so not adding FLS or CRUD
        Utilities.Secure_DML(gitRepositoryConfiguration, Utilities.DML_Action.UPS, schema.SObjectType.Sensitive_Information__c);
    }

    /**
    * Updates repo and custom setting to move to the next component
    * GitBaseUrls handled here because rendering problem
    * @return PageReference
    * */
    public PageReference updateRepoAndMoveToNext() {
        try {
            Utilities.Secure_DML(gitRepository, Utilities.DML_Action.UPD, Schema.SObjectType.Git_Repository__c);
            updateSetupWizardCustomSetting(null, null, gitRepository.Id, newPipeline.Id, null, null, null);
        } catch(Exception excp) {
            handleException(excp);
        }

        return goToNextComponent();
    }

    /**
     * Saves current record changes, updates Setup Wizard custom setting and returns to home page
     * @return PageReference
     */
    public PageReference saveAndClose() {
        if(currentPipelineStep != PipelineSettingsOrder.PipelineName && currentPipelineStep != PipelineSettingsOrder.GitRepositorySelection) {
            Utilities.Secure_DML(gitRepository, Utilities.DML_Action.UPD, Schema.SObjectType.Git_Repository__c);
        }
        if(currentPipelineStep != PipelineSettingsOrder.PipelineName) {
            Utilities.Secure_DML(newPipeline, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow__c);
        }

        updateSetupWizardCustomSetting(null, null, gitRepository.Id, newPipeline.Id, null, null, null);

        return goToHomePage();
    }

    /**
     * Saves current record changes, updates Setup Wizard custom setting and returns to home page
     * @return PageReference
     */
    public PageReference skipUrls() {
        updateSetupWizardCustomSetting(WizardHelper.SetupPipelineOrder.PipelineTemplatesWizard.name(), null, gitRepository.Id, newPipeline.Id, null, null, null);
        return goToNextComponent();
    }

    public void updateAndGoToNext() {
        if(String.isBlank(gitRepository.Id)) {
            gitRepository.Id = null;
        } else {
            String provider = gitRepository.Git_Provider__c;
            gitRepository = gitRepositoryMap.get(gitRepository.Id);
            gitRepository.Git_Provider__c = provider;
        }
        setStep();
    }

    public Boolean checkNameAndProviderFieldValues() {
        ApexPages.getMessages().clear();
        Boolean isNameOrProviderEmpty = String.isBlank(gitRepository.Name) || String.isBlank(gitRepository.Git_Provider__c);
        if(String.isBlank(gitRepository.Name)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' a git repository name');
        }

        if(String.isBlank(gitRepository.Git_Provider__c)){
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, 'Please select a git provider');
        }
        return isNameOrProviderEmpty;
    }

    /**
    * Bitbucket SSH: git clone git@bitbucket.org:ztugcesirin/copado-poc.git
    * Bitbucket HTTPS: git clone https://ztugcesirin@bitbucket.org/ztugcesirin/copado-poc.git
    * Gitlab SSH: git@gitlab.com:username/reponame.git
    * Gitlab HTTPS: https://gitlab.copado.com/app-dev/copado_dev.git
    * Github SSH:  git@github.com:tugce/TestPrivateRepo.git
    * Github HTTPS:  https://github.com/tugce/TestPrivateRepo.git
    * VSTS SSH:
    * VSTS HTTPS:
    * */
    public void populateURLFields() {
        if(String.isNotBlank(gitRepository.URI__c)  && gitRepository.Git_Provider__c != null && gitRepository.Git_Provider__c != 'Others') { // Bitbucket, GitLab, Microsoft Team Service, Github
            if(String.isBlank(gitRepository.Commit_Base_URL__c) && String.isBlank(gitRepository.Branch_Base_URL__c) &&
                    String.isBlank(gitRepository.Pull_Request_Base_URL__c) && String.isBlank(gitRepository.Tag_Base_URL__c)) {

                String branchBaseParameter = gitRepository.Git_Provider__c == BITBUCKET_PROVIDER ? 'branch' : 'tree';
                String tagBaseParameter = gitRepository.Git_Provider__c == BITBUCKET_PROVIDER ? 'src' : 'tags';
                String branchBaseURLProvider = gitRepository.Git_Provider__c == MTS_PROVIDER ? VS_BRANCH_BASE_URL : BRANCH_BASE_URL;
                String commitBaseURLProvider = gitRepository.Git_Provider__c == MTS_PROVIDER ? VS_COMMIT_BASE_URL : COMMIT_BASE_URL;
                String prBaseURLProvider = gitRepository.Git_Provider__c == MTS_PROVIDER ? VS_PR_BASE_URL : PR_BASE_URL;
                String tagBaseURLProvider = gitRepository.Git_Provider__c == MTS_PROVIDER ? VS_TAG_BASE_URL : TAG_BASE_URL;
                String selectedProvider = gitRepository.Git_Provider__c == 'Github' ? GITHUB_COM : gitRepository.Git_Provider__c == BITBUCKET_PROVIDER ? BITBUCKET_ORG : gitRepository.Git_Provider__c == 'GitLab' ? GITLAB_COM : gitRepository.Git_Provider__c == MTS_PROVIDER ? VISUALSTUDIO_COM : '';

                // Branch base url
                gitRepository.Branch_Base_URL__c = String.format(branchBaseURLProvider, new List<String>{
                        selectedProvider, branchBaseParameter
                });
                gitRepository.Branch_Base_URL__c = gitRepository.Branch_Base_URL__c.replace('(', '{').replace(')', '}');

                // Commit base url
                gitRepository.Commit_Base_URL__c = String.format(commitBaseURLProvider, new List<String>{
                        selectedProvider
                });
                gitRepository.Commit_Base_URL__c = gitRepository.Commit_Base_URL__c.replace('(', '{').replace(')', '}');

                // Pr base url
                gitRepository.Pull_Request_Base_URL__c = String.format(prBaseURLProvider, new List<String>{
                        selectedProvider
                });
                gitRepository.Pull_Request_Base_URL__c = gitRepository.Pull_Request_Base_URL__c.replace('(', '{').replace(')', '}');

                // Tag base url
                gitRepository.Tag_Base_URL__c = String.format(tagBaseURLProvider, new List<String>{
                        selectedProvider, tagBaseParameter
                });
                gitRepository.Tag_Base_URL__c = gitRepository.Tag_Base_URL__c.replace('(', '{').replace(')', '}');

                providerBranchBaseUrl = gitRepository.Branch_Base_URL__c;
                providerCommitBaseUrl = gitRepository.Commit_Base_URL__c;
                providerPullBaseUrl = gitRepository.Pull_Request_Base_URL__c;
                providerTagBaseUrl = gitRepository.Tag_Base_URL__c;
                isUrlsPopulatedByMethod = true;
            }
        } else {
            gitRepository.Branch_Base_URL__c = null;
            gitRepository.Commit_Base_URL__c = null;
            gitRepository.Pull_Request_Base_URL__c = null;
            gitRepository.Tag_Base_URL__c = null;
        }
    }

    /**
    * Update base urls' merge fields based on input from user
    * We have different variables for provider urls because if we dont keep url with merge fields
    * if user enters wrong and merges wrong thing we need to parse the url to remo wrong username or repo name
    * @return void
    * */
    public void updateBaseUrlsMergeFields(){
        Boolean mergedUsername = false;

        if((String.isNotBlank(gitRepositoryUsername) && gitRepositoryUsername.containsWhitespace()) || (String.isNotBlank(gitRepositoryRepoName) && gitRepositoryRepoName.containsWhitespace())){
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Pipeline_Username_Repo_Name_Empty_Space_Warning);
            return;
        }

        if(String.isNotBlank(gitRepositoryUsername)){
            gitRepository.Branch_Base_URL__c = providerBranchBaseUrl.replace(USERNAME, gitRepositoryUsername);
            gitRepository.Commit_Base_URL__c = providerCommitBaseUrl.replace(USERNAME, gitRepositoryUsername);
            gitRepository.Pull_Request_Base_URL__c = providerPullBaseUrl.replace(USERNAME, gitRepositoryUsername);
            gitRepository.Tag_Base_URL__c = providerTagBaseUrl.replace(USERNAME, gitRepositoryUsername);
            mergedUsername = true;
        }

        if(String.isNotBlank(gitRepositoryRepoName)){
            //temps for if user wants to change entered value we need to keep url with merge fields
            String tempProviderBranchBaseUrl = providerBranchBaseUrl;
            String tempProviderCommitBaseUrl = providerCommitBaseUrl;
            String tempProviderPullBaseUrl = providerPullBaseUrl;
            String tempProviderTagBaseUrl = providerTagBaseUrl;
            if(mergedUsername){
                providerBranchBaseUrl = gitRepository.Branch_Base_URL__c;
                providerCommitBaseUrl = gitRepository.Commit_Base_URL__c;
                providerPullBaseUrl = gitRepository.Pull_Request_Base_URL__c;
                providerTagBaseUrl = gitRepository.Tag_Base_URL__c;
            }
            gitRepository.Branch_Base_URL__c = providerBranchBaseUrl.replace(REPOSITORY_NAME, gitRepositoryRepoName);
            gitRepository.Commit_Base_URL__c = providerCommitBaseUrl.replace(REPOSITORY_NAME, gitRepositoryRepoName);
            gitRepository.Pull_Request_Base_URL__c = providerPullBaseUrl.replace(REPOSITORY_NAME, gitRepositoryRepoName);
            gitRepository.Tag_Base_URL__c = providerTagBaseUrl.replace(REPOSITORY_NAME, gitRepositoryRepoName);

            providerBranchBaseUrl = tempProviderBranchBaseUrl;
            providerCommitBaseUrl = tempProviderCommitBaseUrl;
            providerPullBaseUrl = tempProviderPullBaseUrl;
            providerTagBaseUrl = tempProviderTagBaseUrl;
        }
    }

    /**
    * Assigns gitAuthTypeValue if uri exists
    * Assings extra headers if gitAuthTypeValue https and extra headers note exists
    * Calls checkIfSSHKeyExist methos if gitAuthTypeValue is SSH
    * @return void
    * */
    @TestVisible
    private void prepareAuthStep() {
        gitAuthTypeValue = HTTPS_STRING;
        //if URI is null or blank it will be checked in the next step. this is only for preparing authentication details page
        if(String.isBlank(gitRepository.URI__c)) {
            return;
        }
        if(gitRepository.URI__c.startsWithIgnoreCase(HTTPS_STRING)) {
            gitAuthTypeValue = HTTPS_STRING;
            try {
                List<Note> headersList = [SELECT Id, Title, Body FROM Note WHERE ParentId = :gitRepository.Id AND Title = :EXTRA_HEADERS WITH SECURITY_ENFORCED];
                if(!headersList.isEmpty()) {
                    gitRepositoryExtraHeaders = headersList[0].Body;
                }
            } catch (System.QueryException excp) {
                handleException(excp);
            }
        } else {
            gitAuthTypeValue = SSH_STRING;
            checkIfSSHKeyExist();
        }
    }

    /**
    * Check if SSH key of the git repository exists
    * If it does assigns value to the gitRepositorySshKey variable
    * @return void
    * */
    public void checkIfSSHKeyExist() {
        try {
            List<Attachment> sshKeys = [SELECT Id, Body FROM Attachment WHERE ParentId = :gitRepository.Id AND Name = 'id_rsa.pub' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            if(!sshKeys.isEmpty()) {
                gitRepositorySshKey = sshKeys[0].Body.toString();
                gitRepositorySshKey = gitRepositorySshKey.trim();
            }
        } catch (System.QueryException excp) {
            handleException(excp);
        }
    }

    /**
    * Creates ssh key
    * @return PageReference
    * */
    public PageReference createSshKey() {
        if(String.isBlank(gitRepository.URI__c)){
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' URI ');
            return null;
        } else if(gitRepository.URI__c.startsWithIgnoreCase(HTTPS_STRING)){
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.SSH_URI_validation);
            return null;
        }
        try {
            String result = DeployAPI.createSSHKey(gitRepository.Id);
            if(String.isBlank(result)) {
                //render error
                handleError(ApexPages.getMessages()[0].getDetail(), new List<String>{
                        'An error occurred when creating SSH Key. Please contact your System Administrator'
                }, '');
                return null;
            }
            checkIfSSHKeyExist();
        } catch(Exception ex) {
            handleException(ex);
        }
        return null;
    }

    /**
    * Check for missing fields and field validations
    * @return Boolean false for error
    * */
    public Boolean checkGitRepositoryFields() {
        isGitRepoValid = false;
        Boolean isMissingFields = false;
        if(String.isBlank(gitRepository.URI__c)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + Schema.SObjectType.Git_Repository__c.fields.URI__c.getLabel());
            isMissingFields = true;
        }
        if(gitAuthTypeValue == HTTPS_STRING && String.isBlank(gitRepositoryUsername)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' username');
            isMissingFields = true;
        }
        if(gitAuthTypeValue == HTTPS_STRING && String.isBlank(gitRepositoryPassword)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' password');
            isMissingFields = true;
        }
        if(gitAuthTypeValue == SSH_STRING && gitRepositorySshKey == null) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + 'SSH Key');
            isMissingFields = true;
        }
        if(isMissingFields) {
            return false;
        }

        if((gitAuthTypeValue == SSH_STRING && gitRepository.URI__c.startsWith(HTTPS_STRING)) || (gitAuthTypeValue == HTTPS_STRING && !gitRepository.URI__c.startsWith(HTTPS_STRING))) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.SSH_URI_validation);
            return false;
        }
        isGitRepoValid = true;
        return true;
    }

    public List<Git_Repository__c> getGitRepositories() {
        List<Git_Repository__c> repositories = new List<Git_Repository__c>();
        try {
            repositories = [SELECT Id, Name, Git_Provider__c, URI__c, Branch_Base_URL__c, Commit_Base_URL__c, Pull_Request_Base_URL__c, Tag_Base_URL__c FROM Git_Repository__c WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000];
            gitRepositoryMap = new Map<Id, Git_Repository__c>(repositories);
        } catch (System.QueryException excp) {
            handleException(excp);
        }
        return repositories;
    }
}