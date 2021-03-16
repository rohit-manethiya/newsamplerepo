/**
 * Branch management VF page controller extension
 * @author Mert YALTI
 * @version 2.0
 */
public with sharing class BranchManagementExtension {
    private final String C_NONE = '--None--';
    private final String C_SCRATCHORG = 'Scratch Org';
    private final String C_MERGE = 'merge';
    private final String C_STEPID = 'stepId';
    private final String C_PULL = 'pull';
    private final static String C_FALSE = 'false';
    private final static String C_TRUE = 'true';
    private final String WARNING = 'warning';
    private final Deployment_Flow__c deploymentflow;
    public Map<String, List<Object>> pageMessagesMap { get; set; }
    public final String calculationBase {
        get {
            if (String.isBlank(calculationBase) && String.isNotBlank(deploymentflow.Calculate_Based_on__c)) {
                calculationBase = deploymentflow.Calculate_Based_on__c;
            }
            return calculationBase;
        }
        set;
    }
    public final String disabledTabs {
        get {
            if (String.isBlank(disabledTabs) && String.isNotBlank(deploymentflow.Hide_Tabs__c)) {
                disabledTabs = deploymentflow.Hide_Tabs__c.replace(' ', '').toLowerCase();
            }
            return disabledTabs;
        }
        set;
    }
    public Boolean hideCalcBackPromotionButtons { get; set; }
    public Boolean rebaselistView { get; set; }
    public Boolean showUserStories {
        get {
            if (null == showUserStories) {
                showUserStories = true;
            }
            return showUserStories;
        }
        set;
    }
    public Boolean promotionOnly { get; set; }
    public Boolean showCommits { get; set; }
    public Boolean hideCommitTab { get; set; }
    public Boolean showErrors { get; set; }
    public Integer csrSize {
        get {
            if (null == csrSize) {
                csrSize = 0;
            }
            return csrSize;
        }
        set;
    }
    public Integer strSize {
        get {
            if (null == strSize) {
                strSize = 0;
            }
            return strSize;
        }
        set;
    }
    public List<Selenium_Test_Group__c> seleniumResultsList {
        get {
            if (null == seleniumResultsList) {
                new List<Selenium_Test_Group__c>();
            }
            return seleniumResultsList;
        }
        set;
    }
    public Boolean showSeleniumResults {
        get {
            if (null == showSeleniumResults) {
                showSeleniumResults = false;
            }
            return showSeleniumResults;
        }
        set;
    }
    public List<Compliance_Scan_Result__c> compliencaResultsList {
        get {
            if (null == compliencaResultsList) {
                compliencaResultsList = new List<Compliance_Scan_Result__c>();
            }
            return compliencaResultsList;
        }
        set;
    }
    public Boolean showComplianceResults {
        get {
            if (null == showComplianceResults) {
                showComplianceResults = false;
            }
            return showComplianceResults;
        }
        set;
    }
    public Boolean showFileDifferences { get; set; }
    public Boolean showAutoResolves { get; set; }
    public Boolean showMergeDifferences { get; set; }
    public Boolean showHiddenCheckboxes { get; set; }
    public Boolean enabledRebasePromotionPoller { get; set; }
    public Boolean rebaseDeploymentsCompleted { get; set; }
    public OverlayWrapper latestOverlay { get; set; }
    public Deployment_Flow_Step__c requestedStep { get; set; }
    public static String stepMapJSON { get; set; }
    @TestVisible
    private List<UserStoryWrapper> usPlaceHolder { get; set; }
    private List<ErrorWrapper> tempErrors;
    public Integer errorSize { get; set; }
    public List<SelectOption> projects { get; set; }
    public List<SelectOption> releases { get; set; }
    public Integer allStorySize { get; set; }
    public Promotion__c promotion { get; set; }
    public String promotionBtnLabel { get; set; }
    public List<SelectOption> rebaseSourceEnvironments { get; set; }
    public String rebaseSource { get; set; }
    public String rebaseProject { get; set; }
    public String rebaseRelease { get; set; }
    public List<User_Story__c> dependenciesList { get; set; }
    public List<UserStoryWrapper> rebaseUserStoriesWrapper { get; set; }
    public List<RebaseEnvironmentWrapper> rebaseSources { get; set; }
    public Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> usEnvironmentAvailabilityMap { get; set; }
    public Map<Id, Promotion__c> rebasePromotionsMap { get; set; }
    public Boolean rebasePromotionsCreated { get; set; }
    private List<Promotion__c> rebasePromotions { get; set; }
    private Set<Id> rebasePromotionIds { get; set; }
    private Map<Id, List<Deployment_Flow_Step__c>> destinationToSources { get; set; }
    public Map<Id, List<Environmental_Variable__c>> envId_envVarsMap {
        get {
            if (null == envId_envVarsMap) {
                envId_envVarsMap = new Map<Id, List<Environmental_Variable__c>>();
            }
            return envId_envVarsMap;
        }
        set;
    }
    public Set<Id> envIdsset {
        get {
            if (null == envIdsset) {
                envIdsset = new Set<Id>();
                if (dfSteps != null) {
                    for (Deployment_Flow_Step__c df : dfSteps) {
                        envIdsset.add(df.Source_Environment__c);
                        envIdsset.add(df.Destination_Environment__c);
                    }
                }
            }
            return envIdsset;
        }
        private set;
    }
    private List<Deployment_Flow_Step__c> dfSteps {
        get {
            if (null == dfSteps) {
                dfSteps = Utilities.getStepDetailsOfDeploymentFlow(deploymentflow.Id);
            }
            return dfSteps;
        }
        private set;
    }
    public List<Environmental_Variable__c> envVarList {
        get {
            if (
                null == envVarList &&
                envIdsset != null &&
                Schema.SObjectType.Environmental_Variable__c.isQueryable() &&
                Schema.SObjectType.Environmental_Variable__c.isAccessible()
            ) {
                envVarList = new List<Environmental_Variable__c>(
                    [
                        SELECT Id, Name, Value__c, Environment__c, Environment__r.Name
                        FROM Environmental_Variable__c
                        WHERE Environment__c IN :envIdsset
                        ORDER BY Name
                    ]
                );
                List<Environmental_Variable__c> tempList;
                for (Environmental_Variable__c evItem : envVarList) {
                    tempList = new List<Environmental_Variable__c>();
                    if (envId_envVarsMap.containsKey(evItem.Environment__c)) {
                        tempList = envId_envVarsMap.get(evItem.Environment__c);
                    }
                    tempList.add(evItem);
                    envId_envVarsMap.put(evItem.Environment__c, tempList);
                }
            }
            return envVarList;
        }
        private set;
    }
    private String pathType { get; set; }
    private String stepResult { get; set; }
    public Integer commAhead { get; set; }
    public Integer commBehind { get; set; }
    // Added by Nahuel
    // return multiple keys.
    public String jobsManagerMatchingKeys {
        get {
            Deployment_Flow__c flow = new Deployment_Flow__c();
            if (Schema.SObjectType.Deployment_Flow__c.isQueryable() || Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                flow = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c WHERE Id = :deploymentflow.Id];
                Map<Id, String> branchesPerEnv = Utilities.getEnvsAndBranchesOfDeploymentFlow(flow.Id);
                String matchingKey = '';
                for (String branch : branchesPerEnv.values()) {
                    matchingKey += ';GIT-' + flow.Git_Repository__c + '-' + branch;
                }
                return matchingKey.replaceFirst(';', '');
            }
            return '';
        }
        set;
    }
    /**
     * Constructor method
     * @param  stdController Deployment_Flow__c Std controller
     * @see BranchManagementExtension.getAllStepDetails
     * @see resetPanels
     */
    public BranchManagementExtension(ApexPages.StandardController stdController) {
        hideCalcBackPromotionButtons = false;
        // Checking if branch management feature is enabled
        Boolean isFeatureEnabled = FeatureHelper.isFeatureEnabled('Branch Management');
        if (!isFeatureEnabled) {
            hideCalcBackPromotionButtons = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Branch_Management_Not_Enabled));
        }
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest() && !ApexPages.currentPage().getUrl().toLowerCase().contains('pipelinemanager')) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment_Flow__c.fields.getMap().keySet()));
        }

        rebaselistView = false; //has to be true change this before promote.
        showHiddenCheckboxes = false;
        rebasePromotionsCreated = false;
        rebaseDeploymentsCompleted = false;
        enabledRebasePromotionPoller = false;
        promotionOnly = true;
        if (rebasePromotionsMap == null) {
            rebasePromotionsMap = new Map<Id, Promotion__c>();
        } else if (rebasePromotionsMap.keySet().size() > 0) {
            rebasePromotionsCreated = true;
        }
        dependenciesList = new List<User_Story__c>();
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
        this.deploymentflow = (Deployment_Flow__c) stdController.getRecord();
        Integer existingSteps = 0;
        if (String.isNotBlank(deploymentflow.Id)) {
            if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                existingSteps = [
                    SELECT COUNT()
                    FROM Deployment_Flow_Step__c
                    WHERE
                        Deployment_Flow__r.Active__c = true
                        AND (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') // MY: Added to exclude scratch orgs from used CBM licenses
                        AND Deployment_Flow__r.Main_Branch__c != null
                        AND Deployment_Flow__r.Git_Repository__c != null
                        AND Branch__c != null
                        AND Id != :deploymentflow.Id
                ];
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Deployment_Flow_Step__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return;
            }
        }

        LicenseManagerController lmc = new LicenseManagerController();
        if (lmc.cbmBranchesAvailable != null && existingSteps != null && lmc.cbmBranchesAvailable - existingSteps < 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.BRANCH_MGMT_LICENSE_EXCEEDED));
        }

        // Checking if the deployment flow is active or not
        if (!deploymentflow.Active__c) {
            hideCalcBackPromotionButtons = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DF_Inactive));
        }
        addWarnings(deploymentflow);
        promotion = new Promotion__c();
        BranchManagementExtension.getAllStepDetails(this.deploymentflow.Id);
        allStorySize = 0;
        pageMessagesMap = new Map<String, List<Object>>();
        resetPanels();
    }

    /**
     * This method is to be used to add warnings to help customers avoid mistakes
     * @param  Deployment flow record
     * @return Void, Should only add ApexPagesmessage
     */
    private void addWarnings(Deployment_Flow__c df) {
        if (!Schema.SObjectType.Deployment_Flow__c.isAccessible() && !Schema.SObjectType.Deployment_Flow__c.isQueryable()) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.Deployment_Flow__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return;
        }
        if (null != df.Git_Repository__c) {
            //Warning: There is another Active Deployment Flow linked to the Same Git Repository + Name
            List<Deployment_Flow__c> dFlows = [
                SELECT Name
                FROM Deployment_Flow__c
                WHERE Git_Repository__c = :df.Git_Repository__c AND Active__c = true AND Id != :df.Id
                LIMIT 1
            ];
            if (!dFlows.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, dFlows[0].Name + Label.DF_Linked_To_Same_Repo));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NoGitRepoLinked));
        }
    }
    /**
     * Queries all deployment flow steps with their details
     * Marked as remote action since this particular function is in use at backDeploy JS resource
     * @param  flowId Deployment flow Id
     * @return        Map of steps
     */
    @RemoteAction
    public static Map<Id, Deployment_Flow_Step__c> getAllStepDetails(String flowId) {
        Map<Id, Deployment_Flow_Step__c> stepsMap = new Map<Id, Deployment_Flow_Step__c>();
        List<Deployment_Flow_Step__c> steps = Utilities.getStepDetailsOfDeploymentFlow(flowId);
        if (steps != null) {
            for (Deployment_Flow_Step__c dfs : steps) {
                stepsMap.put(dfs.Id, dfs);
            }
            steps.clear();
            stepMapJSON = JSON.serialize(stepsMap);
            return stepsMap;
        } else {
            stepMapJSON = BranchManagementExtension.C_FALSE;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DF_NO_STEP));
            return stepsMap;
        }
    }
    /**
     * Resets all modal panel display states
     * @return [description]
     */
    public PageReference resetPanels() {
        if (latestOverlay != null) {
            promotion.Project__c = null;
            latestOverlay.userStories = new List<UserStoryWrapper>();
            latestOverlay.errors = new List<ErrorWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        showUserStories = false;
        showCommits = false;
        showErrors = false;
        showFileDifferences = false;
        showAutoResolves = false;
        showMergeDifferences = false;
        showComplianceResults = false;
        showSeleniumResults = false;
        pageMessagesMap = new Map<String, List<Object>>();
        return null;
    }
    /**
     * When the environment modal is closed all related variables needs to be reseted. This method handled that job.
     * @return null Pagereference
     */
    public PageReference resetModalsDOM() {
        latestOverlay = null;
        promotion = new Promotion__c();
        dependenciesList = new List<User_Story__c>();
        resetPanels();
        return null;
    }
    /**
     * To render user stories panel
     * @return null Pagereference
     */
    public PageReference showUserStories() {
        resetPanels();
        getUserStories();
        tempErrors = new List<ErrorWrapper>();
        showUserStories = true;
        return null;
    }
    /**
     * To render commits panel
     * @return null Pagereference
     */
    public PageReference showCommits() {
        resetPanels();
        if (latestOverlay != null) {
            latestOverlay.commitsAhead = commAhead;
            latestOverlay.commitsBehind = commBehind;
        }
        showCommits = true;
        return null;
    }
    /**
     * To render errors panel
     * @return null Pagereference
     */
    public PageReference showErrors() {
        resetPanels();
        if (latestOverlay != null) {
            retrieveErrors();
            latestOverlay.errors.addAll(tempErrors);
            tempErrors.clear();
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        showErrors = true;
        return null;
    }
    /**
     * To render errors panel
     * @return null Pagereference
     */
    public PageReference showSeleniumResults() {
        resetPanels();
        if (latestOverlay != null) {
            retrieveSeleniumResults();
            tempErrors.clear();
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
        }
        showSeleniumResults = true;
        System.debug('it is executes: ' + showSeleniumResults);
        return null;
    }
    /**
     * To render errors panel
     * @return null Pagereference
     */
    public PageReference showComplianceResults() {
        resetPanels();
        if (latestOverlay != null) {
            retrieveComplianceResults();
            tempErrors.clear();
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        showComplianceResults = true;
        return null;
    }
    /**
     * To render file differences panel
     * @return null Pagereference
     */
    public PageReference showFileDifferences() {
        resetPanels();
        if (latestOverlay != null) {
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        showFileDifferences = true;
        return null;
    }
    /**
     * To render auto resolved files panel
     * @return null Pagereference
     */
    public PageReference showAutoResolves() {
        resetPanels();
        if (latestOverlay != null) {
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        showAutoResolves = true;
        return null;
    }
    public PageReference showMergeDifferences() {
        resetPanels();
        showMergeDifferences = true;
        if (latestOverlay != null) {
            if (projects != null && !projects.isEmpty()) {
                projects.clear();
            }
            if (releases != null && !releases.isEmpty()) {
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
            compliencaResultsList = new List<Compliance_Scan_Result__c>();
            seleniumResultsList = new List<Selenium_Test_Group__c>();
        }
        return null;
    }
    public PageReference toggleRebaseListView() {
        showHiddenCheckboxes = showHiddenCheckboxes != true;
        return null;
    }
    public void resetRebaseModal() {
        rebaseSource = '';
        rebaseProject = '';
        rebaseRelease = '';
        projects = new List<SelectOption>();
        releases = new List<SelectOption>();
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
    }

    private String getPageParameter(String paramName) {
        return String.isNotBlank(ApexPages.currentPage().getParameters().get(paramName))
            ? ApexPages.currentPage().getParameters().get(paramName)
            : '';
    }
    @TestVisible
    private void calculateUserStoryEnvironmentAvailability(List<User_Story__c> usList) {
        Set<Id> usIds = new Set<Id>();
        for (User_Story__c us : usList) {
            usIds.add(us.Id);
        }
    }

    public PageReference getRebaseUserStories() {
        System.debug('*** getrebaseuserstories: ');
        projects.clear();
        releases.clear();
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
        List<Deployment_Flow_Step__c> rebaseSteps = new List<Deployment_Flow_Step__c>();
        Map<Id, String> uniqProjects = new Map<Id, String>();
        Map<Id, String> uniqReleases = new Map<Id, String>();
        usEnvironmentAvailabilityMap = new Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>>();

        projects = new List<SelectOption>();
        projects.add(new SelectOption(C_NONE, C_NONE));
        releases = new List<SelectOption>();
        releases.add(new SelectOption(C_NONE, C_NONE));
        if (rebaseSource == C_NONE || rebaseSource == null) {
            rebaseProject = null;
            rebaseRelease = null;
            return null;
        }

        for (Deployment_Flow_Step__c dfs : destinationToSources.get(rebaseSource)) {
            if ((rebaseProject != null && rebaseProject != C_NONE) || (rebaseRelease != null && rebaseRelease != C_NONE)) {
                rebaseSources.add(new rebaseEnvironmentWrapper(dfs));
            }
            rebaseSteps.add(dfs);
        }

        Map<Id, List<Promoted_User_Story__c>> userStoriesWithPromotions = GlobalUtilities.getRebaseUserStories(
            rebaseSteps,
            rebaseSource,
            deploymentflow.Id
        );

        System.debug('userStoriesWithPromotions: ' + userStoriesWithPromotions);

        for (Id usId : userStoriesWithPromotions.keySet()) {
            for (Promoted_User_Story__c pus : userStoriesWithPromotions.get(usId)) {
                if (pus.User_Story__r.Project__c != null && !uniqProjects.containsKey(pus.User_Story__r.Project__c)) {
                    // Project & Release picklist values
                    projects.add(new SelectOption(pus.User_Story__r.Project__c, pus.User_Story__r.Project__r.Name));
                    uniqProjects.put(pus.User_Story__r.Project__c, pus.User_Story__r.Project__r.Name);
                }
                if (pus.User_Story__r.Release__c != null && !uniqReleases.containsKey(pus.User_Story__r.Release__c)) {
                    // Project & Release picklist values
                    releases.add(new SelectOption(pus.User_Story__r.Release__c, pus.User_Story__r.Release__r.Name));
                    uniqReleases.put(pus.User_Story__r.Release__c, pus.User_Story__r.Release__r.Name);
                }
            }
        }
        if ((String.isBlank(rebaseProject) && String.isBlank(rebaseRelease)) || (rebaseProject == C_NONE && rebaseRelease == C_NONE)) {
            return null;
        }
        usEnvironmentAvailabilityMap = GlobalUtilities.calculateUserStoriesBehind(userStoriesWithPromotions, rebaseSteps);
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            String userStoryQuery = 'SELECT Id, User_Story_Title__c,Name,Release__c,Project__c';
            userStoryQuery = PipelineManagerExtension.prepareFieldsetQuery(
                Schema.SObjectType.User_Story__c.fieldSets.Mass_Back_Promote,
                userStoryQuery
            );
            Set<Id> availableUserStoryIds = usEnvironmentAvailabilityMap.keySet();
            userStoryQuery = userStoryQuery + ' FROM User_Story__c WHERE Id IN :availableUserStoryIds LIMIT 1000';
            List<User_Story__c> usList = (List<User_Story__c>) Database.query(userStoryQuery);
            for (User_Story__c us : usList) {
                if (
                    (rebaseProject != null &&
                    rebaseProject != C_NONE &&
                    rebaseRelease != null &&
                    rebaseRelease == C_NONE &&
                    rebaseProject == us.Project__c) ||
                    (rebaseProject != null &&
                    rebaseProject == C_NONE &&
                    rebaseRelease != null &&
                    rebaseRelease != C_NONE &&
                    rebaseRelease == us.Release__c) ||
                    (rebaseProject != null &&
                    rebaseProject != C_NONE &&
                    rebaseRelease != null &&
                    rebaseRelease != C_NONE &&
                    rebaseRelease == us.Release__c &&
                    rebaseProject == us.Project__c)
                ) {
                    UserStoryWrapper usMassBp = new UserStoryWrapper(us);
                    rebaseUserStoriesWrapper.add(usMassBp);
                }
            }
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.User_Story__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return null;
        }
        return null;
    }
    public PageReference createRebasePromotionsAndDeploy() {
        isDeploy = true;
        return createRebasePromotions();
    }
    public Boolean getIsRebasePromotionsCreated() {
        return rebasePromotionsCreated;
    }
    public Boolean getEnabledRebasePromotionPoller() {
        return enabledRebasePromotionPoller;
    }
    public PageReference createRebasePromotions() {
        Savepoint sp = Database.setSavepoint();
        Map<Id, User_Story__c> allUsMap = new Map<Id, User_Story__c>();
        for (UserStoryWrapper usw : rebaseUserStoriesWrapper) {
            allUsMap.put(usw.userStory.Id, usw.userStory);
        }
        if (rebasePromotionIds == null) {
            rebasePromotionIds = new Set<Id>();
        }
        if (rebasePromotions == null) {
            rebasePromotions = new List<Promotion__c>();
        }
        List<Promotion__c> newRebasePromotions = new List<Promotion__c>();
        Boolean hasSelection = false;
        Boolean promotionOnly = true;
        Set<Id> processedEnvIds = new Set<Id>();
        Map<Id, List<User_Story__c>> envStories = new Map<Id, List<User_Story__c>>();

        for (Id usId : usEnvironmentAvailabilityMap.keySet()) {
            Map<Id, GlobalUtilities.RebaseSelectionsWrapper> pTemp = usEnvironmentAvailabilityMap.get(usId);
            for (Id envId : pTemp.keySet()) {
                if (allUsMap.containsKey(usId) && allUsMap.get(usId) != null && pTemp.get(envId).isSelected) {
                    hasSelection = true;
                    if (envStories.containsKey(envId)) {
                        List<User_Story__c> usTemp = envStories.get(envId);
                        if (!usTemp.contains(allUsMap.get(usId))) {
                            usTemp.add(allUsMap.get(usId));
                            envStories.put(envId, usTemp);
                        }
                    } else {
                        List<User_Story__c> usTemp = new List<User_Story__c>();
                        usTemp.add(allUsMap.get(usId));
                        envStories.put(envId, usTemp);
                    }

                    if (!processedEnvIds.contains(envId)) {
                        Promotion__c rebasePromotion = new Promotion__c();
                        rebasePromotion.Back_Promotion__c = true;
                        rebasePromotion.Source_Environment__c = null;
                        rebasePromotion.Destination_Environment__c = envId;
                        rebasePromotion.Project__c = rebaseProject != C_NONE ? rebaseProject : null;
                        rebasePromotion.Release__c = rebaseRelease != C_NONE ? rebaseRelease : null;
                        if (isDeploy) {
                            rebasePromotion.Status__c = 'Scheduled';
                        }
                        newRebasePromotions.add(rebasePromotion);
                    }
                    processedEnvIds.add(envId);
                }
            }
        }
        if (newRebasePromotions.isEmpty() || !hasSelection) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(WARNING, new List<String>{ Label.CBM2_at_least1_us });
            return null;
        }
        try {
            Utilities.Secure_DML(newRebasePromotions, Utilities.DML_Action.UPS, schema.SObjectType.Promotion__c);
            List<Promoted_User_Story__c> pusList = new List<Promoted_User_Story__c>();
            for (Promotion__c pro : newRebasePromotions) {
                if (envStories.containsKey(pro.Destination_Environment__c) && envStories.containsKey(pro.Destination_Environment__c)) {
                    pusList.addAll(addUserStoriesToPromotion(envStories.get(pro.Destination_Environment__c), pro));
                }
                rebasePromotionIds.add(pro.Id);
            }
            if (!pusList.isEmpty()) {
                Utilities.Secure_DML(pusList, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);
            }
            rebasePromotions.addAll(newRebasePromotions);
            rebasePromotionsMap = new Map<Id, Promotion__c>();
            rebasePromotionsMap.putAll((List<Promotion__c>) Database.query(generatePromotionsSoql(rebasePromotionIds)));
            if (!rebasePromotionsMap.isEmpty()) {
                rebasePromotionsCreated = true;
                if (isDeploy) {
                    enabledRebasePromotionPoller = true;
                    promotionOnly = false;
                }
            }
            if (isDeploy) {
                promotionOnly = false;
                deployPromotions();
                rebasePromotionIds.clear();
                rebasePromotions.clear();
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            rebasePromotionIds.clear();
            rebasePromotions.clear();
            allUsMap.clear();
            pageMessagesMap = UIDesignHelper.genericWarningMessage('error', new List<String>{ ex.getMessage() });
            System.debug('error: ' + pageMessagesMap);
        }
        return null;
    }
    private String generatePromotionsSoql(Set<Id> rebasePromotionIds) {
        //TODO : Below code will be enabled with v11 we need to include ManageBranchesDialog fieldset into package
        /*String promotionsSoql = 'SELECT ';
        for (Schema.FieldSetMember pf : SObjectType.Promotion__c.FieldSets.ManageBranchesDialog.getFields()) {
            promotionsSoql += pf.getFieldPath() + ', ';
        }*/
        String promotionsSoql = 'SELECT Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, Connection_Behavior__c, ';
        promotionsSoql += 'Id FROM Promotion__c WHERE Id=:rebasePromotionIds LIMIT 1000';
        return promotionsSoql;
    }
    public PageReference deployPromotions() {
        if (!rebasePromotions.isEmpty()) {
            promotionOnly = false;
            Set<Id> rebasePromotionIds = new Set<Id>();
            rebasePromotionsMap = new Map<Id, Promotion__c>();
            if (!Schema.SObjectType.Promotion__c.fields.Status__c.isUpdateable()) {
                return null;
            }
            for (Promotion__c p : rebasePromotions) {
                p.Status__c = 'Scheduled';
                rebasePromotionIds.add(p.Id);
            }
            Utilities.Secure_DML(rebasePromotions, Utilities.DML_Action.UPD, schema.SObjectType.Promotion__c);
            if (Schema.SObjectType.Promotion__c.isQueryable() || Schema.SObjectType.Promotion__c.isAccessible()) {
                rebasePromotionsMap.putAll((List<Promotion__c>) Database.query(generatePromotionsSoql(rebasePromotionIds)));
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Promotion__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return null;
            }
            rebasePromotionsCreated = true;
            enabledRebasePromotionPoller = true;
            for (Promotion__c pro : rebasePromotions) {
                if (!Test.isRunningTest()) {
                    //Boolean startDeployment = String.isBlank(pro.Connection_Behavior__c);
                    DeployAPI.deployPromotionAsync(
                        pro.Id,
                        'CBM Promotion ' + rebasePromotionsMap.get(pro.Id).Name,
                        false,
                        false,
                        '',
                        true,
                        UserInfo.getUserId()
                    );
                }
            }
            isDeploy = false;
            rebasePromotions.clear();
        }
        return null;
    }
    public Integer rebasePromotionKeySize {
        get {
            Integer keys = 0;
            if (rebasePromotionsMap != null && rebasePromotionsMap.keySet().size() > 0) {
                keys = rebasePromotionsMap.keySet().size();
            }
            return keys;
        }
    }
    public PageReference goToPromotions() {
        rebasePromotionsCreated = true;
        showHiddenCheckboxes = false;
        return null;
    }
    public PageReference resetPromotions() {
        ApexPages.getMessages().clear();
        rebasePromotionsCreated = false;
        rebaseDeploymentsCompleted = false;
        enabledRebasePromotionPoller = false;
        showHiddenCheckboxes = false;
        resetRebaseModal();
        return null;
    }
    public PageReference checkRebasePromotionsStatuses() {
        //TODO : Below code will be enabled with v11 we need to include ManageBranchesDialog fieldset into package
        /*String promotionsSoql = 'SELECT ';
        for (Schema.FieldSetMember pf : SObjectType.Promotion__c.FieldSets.ManageBranchesDialog.getFields()) {
            promotionsSoql += pf.getFieldPath() + ', ';
        }*/
        Set<Id> promIds = rebasePromotionsMap.keySet();
        String promotionsSoql = 'SELECT Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, ';
        promotionsSoql += 'Id FROM Promotion__c WHERE Id=:promIds AND Status__c != \'Cancelled\' LIMIT 1000';
        rebasePromotionsMap = new Map<Id, Promotion__c>();
        List<Promotion__c> proList = new List<Promotion__c>();
        if (Schema.SObjectType.Promotion__c.isQueryable() || Schema.SObjectType.Promotion__c.isAccessible()) {
            proList.addAll((List<Promotion__c>) Database.query(promotionsSoql));
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Promotion__c.getName() + ': ' + Label.Insufficient_Access_Rights)
            );
            return null;
        }
        Integer completedPromotionCount = 0;
        for (Promotion__c pro : proList) {
            rebasePromotionsMap.put(pro.Id, pro);
            if (pro.Status__c.contains('Completed')) {
                completedPromotionCount++;
            }
        }
        if (proList.size() == completedPromotionCount) {
            resetPromotions();
            rebaseDeploymentsCompleted = true;
        }
        proList.clear();
        return null;
    }
    /**
     * ONGOING DEVELOPMENT
     * @return [description]
     */
    public PageReference prepareRebase() {
        resetRebaseModal();
        promotionBtnLabel = 'Back Promotion';
        Map<Id, Integer> stepAsDestinationCount = new Map<Id, Integer>();
        Map<Id, String> stepAsDestination = new Map<Id, String>();
        destinationToSources = new Map<Id, List<Deployment_Flow_Step__c>>();
        Map<Id, Deployment_Flow_Step__c> tempStepsMap = BranchManagementExtension.getAllStepDetails(deploymentflow.Id);
        Map<Id, Deployment_Flow_Step__c> rebaseSourceSteps = getMultipleStepDetails(tempStepsMap.keySet());
        for (Deployment_Flow_Step__c dfs : rebaseSourceSteps.values()) {
            if (dfs.Source_Environment__r.Type__c != null && !dfs.Source_Environment__r.Type__c.startsWithIgnoreCase(C_SCRATCHORG)) {
                if (stepAsDestinationCount.containsKey(dfs.Destination_Environment__c)) {
                    Integer count = stepAsDestinationCount.get(dfs.Destination_Environment__c);
                    stepAsDestinationCount.put(dfs.Destination_Environment__c, count + 1);
                } else if (dfs.Destination_Environment__c != null) {
                    stepAsDestinationCount.put(dfs.Destination_Environment__c, 1);
                }
            }
            stepAsDestination.put(dfs.Destination_Environment__c, dfs.Id);
            List<Deployment_Flow_Step__c> temp;
            if (destinationToSources.containsKey(dfs.Destination_Environment__c)) {
                temp = destinationToSources.get(dfs.Destination_Environment__c);
            } else if (dfs.Destination_Environment__c != null) {
                temp = new List<Deployment_Flow_Step__c>();
            }
            if (dfs.Source_Environment__r.Type__c != null && !dfs.Source_Environment__r.Type__c.startsWithIgnoreCase(C_SCRATCHORG)) {
                temp.add(dfs);
            }
            destinationToSources.put(dfs.Destination_Environment__c, temp);
        }
        rebaseSourceEnvironments = new List<SelectOption>();
        rebaseSourceEnvironments.add(new SelectOption(C_NONE, C_NONE));
        for (Id destId : stepAsDestinationCount.keySet()) {
            if (stepAsDestinationCount.get(destId) >= 1) {
                rebaseSourceEnvironments.add(
                    new SelectOption(destId, rebaseSourceSteps.get(stepAsDestination.get(destId)).Destination_Environment__r.Name)
                );
            }
        }
        return null;
    }

    /**
     * Prepares the modal with the deployment flow results.json
     * @see getStepDetails
     * @return null Pagereference
     */
    public PageReference prepareOverlay() {
        promotionBtnLabel = 'Promotion';
        if (promotion != null) {
            promotion.Project__c = null;
            promotion.Release__c = null;
        }
        pathType = '';
        stepResult = '';

        // following variables are passed from the VF page
        String fromEnvId = getPageParameter('fromEnvId');
        if (!Schema.SObjectType.Environment__c.isAccessible() && !Schema.SObjectType.Environment__c.isQueryable()) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.Environment__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return null;
        }

        List<Environment__c> environmentList = [SELECT Type__c FROM Environment__c WHERE Id = :String.escapeSingleQuotes(fromEnvId) LIMIT 1];
        if (!environmentList.isEmpty()) {
            hideCommitTab = environmentList.get(0).Type__c != null && environmentList.get(0).Type__c.contains(C_SCRATCHORG) ? false : true;
            environmentList.clear();
        }
        String toEnvId = getPageParameter('toEnvId');
        String stepId = getPageParameter(C_STEPID);
        pathType = getPageParameter('type');
        stepResult = getPageParameter('stepResult');
        requestedStep = getStepDetails(stepId);
        if (requestedStep != null) {
            latestOverlay = null;
            String envId = fromEnvId;
            Datetime lastSync = requestedStep.Last_Merge_CBM_Sync__c;
            if (pathType == C_PULL) {
                envId = toEnvId;
                promotionBtnLabel = 'Back Promotion';
                lastSync = requestedStep.Last_Pull_CBM_Sync__c;
            }
            latestOverlay = new OverlayWrapper(
                fromEnvId,
                toEnvId,
                requestedStep.Source_Environment__r.Name,
                requestedStep.Destination_Environment__r.Name,
                pathType,
                null,
                new List<ErrorWrapper>(),
                ApexPages.currentPage().getParameters().get(C_STEPID)
            );
            envId = ((pathType == C_MERGE) ? requestedStep.Source_Environment__c : requestedStep.Destination_Environment__c);

            if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
                strSize = [SELECT COUNT() FROM Selenium_Test_Group__c WHERE Environment__c = :envId];
                strSize = strSize > 1000 ? 1000 : strSize;
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Selenium_Test_Group__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return null;
            }
            if (Schema.SObjectType.Compliance_Scan_Result__c.isQueryable() && Schema.SObjectType.Compliance_Scan_Result__c.isAccessible()) {
                csrSize = [SELECT COUNT() FROM Compliance_Scan_Result__c WHERE Environment__c = :envId];
                csrSize = csrSize > 1000 ? 1000 : csrSize;
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Compliance_Scan_Result__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return null;
            }
        }
        return null;
    }
    /**
     * Process the modal with the deployment flow step results.json
     * @return null Pagereference
     */
    public PageReference errorsOverlay() {
        retrieveErrors();
        errorSize = tempErrors.size();
        tempErrors.clear();
        return null;
    }
    public PageReference retrieveSeleniumResults() {
        Id envId = ((pathType == C_MERGE) ? requestedStep.Source_Environment__c : requestedStep.Destination_Environment__c);
        if (
            requestedStep != null && Schema.SObjectType.Selenium_Test_Group__c.isQueryable() &&
            Schema.SObjectType.Selenium_Test_Group__c.isAccessible()
        ) {
            seleniumResultsList = [
                SELECT Id, Name, Status_Date__c, Type__c, Status_Icon__c, Status__c
                FROM Selenium_Test_Group__c
                WHERE Environment__c = :envId
                ORDER BY LastModifiedDate DESC
                LIMIT 1000
            ];
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.Compliance_Scan_Result__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return null;
        }
        return null;
    }
    public PageReference retrieveComplianceResults() {
        Id envId = ((pathType == C_MERGE) ? requestedStep.Source_Environment__c : requestedStep.Destination_Environment__c);
        if (
            requestedStep != null && Schema.SObjectType.Compliance_Scan_Result__c.isQueryable() &&
            Schema.SObjectType.Compliance_Scan_Result__c.isAccessible()
        ) {
            compliencaResultsList = [
                SELECT
                    Id,
                    Name,
                    Resolution_Details__c,
                    Highest_Rule_Action__c,
                    Highest_Severity__c,
                    Status__c,
                    User_Story__c,
                    User_Story__r.Name,
                    Findings__c,
                    LastModifiedBy.Name,
                    LastModifiedDate
                FROM Compliance_Scan_Result__c
                WHERE Environment__c = :envId
            ];
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.Compliance_Scan_Result__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return null;
        }
        return null;
    }
    public PageReference retrieveErrors() {
        if (requestedStep != null) {
            tempErrors = new List<ErrorWrapper>();
            // Processing step details
            // stepResults comes from the result.json attachment stored on the deployment flow step
            if (!String.isBlank(stepResult)) {
                Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(stepResult);
                if (pathType == C_MERGE) {
                    // Merge errors
                    List<Object> mergeValidationErrors = (List<Object>) jsonObject.get('mergeValidationErrors');
                    tempErrors = processErrorJSON(pathType, mergeValidationErrors);
                } else {
                    // Pull errors
                    List<Object> pullValidationErrors = (List<Object>) jsonObject.get('pullValidationErrors');
                    tempErrors = processErrorJSON(pathType, pullValidationErrors);
                }
            }
        }
        return null;
    }
    /**
     * Finishes the modal with user stories ahead or behind
     * @return null Pagereference
     */
    public PageReference userStoriesOverlay() {
        try {
            getOnlyUserStoriesNumber();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '*** ERROR userStoriesOverlay: ' + e.getMessage());
        }
        return null;
    }
    /**
     * Retrieves user stories that are ready to be promoted
     * @return [description]
     */
    public PageReference getPromotableUserStories() {
        if (usPlaceHolder.isEmpty()) {
            getUserStories();
        }
        if (!usPlaceHolder.isEmpty() && latestOverlay != null) {
            latestOverlay.userStories = new List<UserStoryWrapper>();
            for (UserStoryWrapper usw : usPlaceHolder) {
                if (
                    (usw.userStory.Project__c != null && usw.userStory.Project__c == promotion.Project__c) ||
                    (usw.userStory.Release__c != null &&
                    usw.userStory.Release__c == promotion.Release__c)
                ) {
                    latestOverlay.userStories.add(usw);
                }
            }
            usPlaceHolder.clear();
            return null;
        }
        return null;
    }
    /**
     * Gets all user stories depending on the operation type
     * if merge retrieves user stories ahead,
     * if pull retrieve user stories behind
     */
    @TestVisible
    private void getOnlyUserStoriesNumber() {
        if (latestOverlay != null) {
            usPlaceHolder = new List<UserStoryWrapper>();
            if (latestOverlay.pathType == C_MERGE) {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesAhead(requestedStep)) {
                    usPlaceHolder.add(new UserStoryWrapper(ustry));
                }
            } else {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesBehind(requestedStep)) {
                    usPlaceHolder.add(new UserStoryWrapper(ustry));
                }
            }
            allStorySize = usPlaceHolder.size();
            usPlaceHolder.clear();
        }
    }
    /**
     * Gets all user stories depending on the operation type
     * if merge retrieves user stories ahead,
     * if pull retrieve user stories behind
     */
    @TestVisible
    private void getUserStories() {
        projects = new List<SelectOption>();
        Map<Id, String> uniqProjects = new Map<Id, String>();
        releases = new List<SelectOption>();
        Map<Id, String> uniqReleases = new Map<Id, String>();
        if (latestOverlay != null) {
            usPlaceHolder = new List<UserStoryWrapper>();
            projects.add(new SelectOption('', C_NONE));
            releases.add(new SelectOption('', C_NONE));
            Schema.DescribeSObjectResult dsr = Schema.SObjectType.User_Story__c;
            Schema.FieldSet fieldSetObj = dsr.fieldSets.getMap().get(Settings.ns + 'CBM_Fields');
            Set<String> availableFieldsSet = new Set<String>();
            for (Schema.FieldSetMember field : fieldSetObj.getFields()) {
                availableFieldsSet.add(field.getFieldPath());
            }
            if (latestOverlay.pathType == C_MERGE) {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesFromFieldsetAhead(availableFieldsSet, requestedStep)) {
                    usPlaceHolder.add(new UserStoryWrapper(ustry));
                    if (ustry.Project__c != null && !uniqProjects.containsKey(ustry.Project__c)) {
                        // Project & Release picklist values
                        projects.add(new SelectOption(ustry.Project__c, ustry.Project__r.Name));
                        uniqProjects.put(ustry.Project__c, ustry.Project__r.Name);
                    }
                    if (ustry.Release__c != null && !uniqReleases.containsKey(ustry.Release__c)) {
                        // Project & Release picklist values
                        releases.add(new SelectOption(ustry.Release__c, ustry.Release__r.Name));
                        uniqReleases.put(ustry.Release__c, ustry.Release__r.Name);
                    }
                }
            } else {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesFromFieldsetBehind(availableFieldsSet, requestedStep)) {
                    usPlaceHolder.add(new UserStoryWrapper(ustry));
                    if (ustry.Project__c != null && !uniqProjects.containsKey(ustry.Project__c)) {
                        // Project & Release picklist values
                        projects.add(new SelectOption(ustry.Project__c, ustry.Project__r.Name));
                        uniqProjects.put(ustry.Project__c, ustry.Project__r.Name);
                    }
                    if (ustry.Release__c != null && !uniqReleases.containsKey(ustry.Release__c)) {
                        // Project & Release picklist values
                        releases.add(new SelectOption(ustry.Release__c, ustry.Release__r.Name));
                        uniqReleases.put(ustry.Release__c, ustry.Release__r.Name);
                    }
                }
            }
            allStorySize = usPlaceHolder.size();
            uniqProjects.clear();
            uniqReleases.clear();
        }
    }
    private List<ErrorWrapper> processErrorJSON(String pathType, List<Object> errorObject) {
        if (errorObject != null) {
            List<ErrorWrapper> tempList = new List<ErrorWrapper>();
            for (Object errorObj : errorObject) {
                Map<String, Object> file = (Map<String, Object>) errorObj;
                tempList.add(new ErrorWrapper(pathType, (String) file.get('l'), (String) file.get('m'), (String) file.get('t')));
                if (tempList.size() >= 1000) {
                    break;
                }
            }
            return tempList;
        }
        return new List<ErrorWrapper>();
    }
    private Deployment_Flow_Step__c getStepDetails(String stepId) {
        try {
            if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                Map<String, String> d = GlobalUtilities.getAllFieldsWithoutSharing('Deployment_Flow_Step__c');
                //Typecasting and escaping single quotes needs to resolve SOQL Injection issue since both of them are actual sanity check methods for dynamic queries.
                String injectionSecureId = String.escapeSingleQuotes(String.valueOf(stepId));
                String soqlString =
                    'SELECT ' +
                    String.escapeSingleQuotes(d.get(Label.FIELDS)) +
                    ',Source_Environment__r.Name, Destination_Environment__r.Name FROM ' +
                    String.escapeSingleQuotes(d.get(Label.OBJECT)) +
                    ' WHERE Id =:injectionSecureId';
                return Database.query(soqlString);
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Deployment_Flow_Step__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '*** getStepDetails Exception : ' + e.getMessage());
            return null;
        }
    }
    private Map<Id, Deployment_Flow_Step__c> getMultipleStepDetails(Set<Id> stepIds) {
        Map<Id, Deployment_Flow_Step__c> dfsMap = new Map<Id, Deployment_Flow_Step__c>();
        try {
            if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                Map<String, String> d = GlobalUtilities.getAllFieldsWithoutSharing('Deployment_Flow_Step__c');
                String soqlString =
                    'SELECT ' +
                    String.escapeSingleQuotes(d.get(Label.FIELDS)) +
                    ',Source_Environment__r.Name, Destination_Environment__r.Name, Source_Environment__r.Type__c FROM ' +
                    String.escapeSingleQuotes(d.get(Label.OBJECT)) +
                    ' WHERE Id IN: stepIds';
                for (Deployment_Flow_Step__c dfs : Database.query(soqlString)) {
                    dfsMap.put(dfs.Id, dfs);
                }
                return dfsMap;
            } else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Schema.SObjectType.Deployment_Flow_Step__c.getName() +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '*** getMultipleStepDetails Exception : ' + e.getMessage());
            return dfsMap;
        }
    }
    private Boolean isDeploy = false;
    public PageReference createPromotionAndDeploy() {
        isDeploy = true;
        return createPromotion();
    }
    public PageReference createPromotion() {
        String fromEnvId = latestOverlay.fromEnvId;
        String toEnvId = latestOverlay.toEnvId;
        List<User_Story__c> selectedUserStories = new List<User_Story__c>();
        for (UserStoryWrapper usw : latestOverlay.userStories) {
            if (usw.isSelected) {
                selectedUserStories.add(usw.userStory);
            }
        }
        if (!selectedUserStories.isEmpty()) {
            if (
                !Schema.SObjectType.Promotion__c.fields.Source_Environment__c.isCreateable() ||
                !Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.isCreateable() ||
                !Schema.SObjectType.Promotion__c.fields.Back_Promotion__c.isCreateable() ||
                !Schema.SObjectType.Promotion__c.fields.Source_Environment__c.isCreateable() ||
                !Schema.SObjectType.Promotion__c.fields.Destination_Environment__c.isCreateable()
            ) {
                return null;
            }
            promotion.Source_Environment__c = fromEnvId;
            promotion.Send_Deployment_Complete_email__c = true;
            if (latestOverlay.pathType == C_PULL) {
                promotion.Back_Promotion__c = true;
                promotion.Source_Environment__c = null;
                promotion.Destination_Environment__c = toEnvId;
            }
            try {
                Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
                List<Promoted_User_Story__c> pusList = addUserStoriesToPromotion(selectedUserStories, promotion);
                if (!pusList.isEmpty()) {
                    Utilities.Secure_DML(pusList, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);
                }
                if (isDeploy) {
                    if (!Test.isRunningTest()) {
                        String promotionName = '';
                        if (Schema.SObjectType.Promotion__c.isQueryable() && Schema.SObjectType.Promotion__c.isAccessible()) {
                            promotionName = [SELECT Name FROM Promotion__c WHERE Id = :promotion.Id LIMIT 1].Name;
                        } else {
                            ApexPages.addMessage(
                                new ApexPages.Message(
                                    ApexPages.Severity.WARNING,
                                    Schema.SObjectType.Promotion__c.getName() +
                                    ': ' +
                                    Label.Insufficient_Access_Rights
                                )
                            );
                            return null;
                        }
                        DeployAPI.deployPromotionAsync(promotion.Id, 'CBM Promotion ' + promotionName, false, false, '');
                    }
                    isDeploy = false;
                }
                PageReference promotionRef = new PageReference('/' + promotion.Id);
                promotion = new Promotion__c();
                return promotionRef;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
            return null;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CBM2_at_least1_us));
            return null;
        }
    }
    /**
     * Calculates on the fly the dependencies
     */
    public PageReference calculateUSDependencies() {
        dependenciesList = new List<User_Story__c>();
        if (latestOverlay.pathType != C_PULL) {
            Set<Id> usIds = new Set<Id>();
            for (UserStoryWrapper usw : latestOverlay.userStories) {
                if (usw.isSelected) {
                    usIds.add(usw.userStory.Id);
                }
            }
            if (!usIds.isEmpty()) {
                dependenciesList = GlobalUtilities.getUserStoriesDependencies(usIds, latestOverlay.toEnvId);
            }
        }
        return null;
    }
    private static List<Promoted_User_Story__c> addUserStoriesToPromotion(List<User_Story__c> usl, Promotion__c p) {
        List<Promoted_User_Story__c> promotedUSerStories = new List<Promoted_User_Story__c>();
        if (
            !Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.isCreateable() ||
            !Schema.SObjectType.Promoted_User_Story__c.fields.Name.isCreateable()
        ) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Promotion__c.getName() + ': ' + Label.Insufficient_Access_Rights)
            );
            return promotedUSerStories;
        }

        for (User_Story__c us : usl) {
            Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = p.Id);
            pus.Name = 'Promoted User Story: ' + us.Name;
            promotedUSerStories.add(pus);
        }
        return promotedUSerStories;
    }
    public PageReference addPageMessages() {
        String message = ApexPages.currentPage().getParameters().get('message');
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
        return null;
    }

    @RemoteAction
    public static Object returnOrgColors(Id flowStepId) {
        System.debug('flowStepId====> ' + flowStepId);
        Map<String, StepColorWrapper> stepColorMap = new Map<String, StepColorWrapper>();
        Boolean isDfsQueryable = Schema.SObjectType.Deployment_Flow_Step__c.isQueryable();
        Boolean isDfsAccessible = Schema.SObjectType.Deployment_Flow_Step__c.isAccessible();
        if (isDfsQueryable && isDfsAccessible) {
            Deployment_Flow_Step__c dfs = [
                SELECT
                    id,
                    name,
                    Deployment_Flow__c,
                    Destination_Environment__c,
                    Destination_Environment__r.Name,
                    Source_Environment__c,
                    Source_Environment__r.Name
                FROM Deployment_Flow_Step__c
                WHERE Id = :flowStepId
            ];
            Integer readyCount;

            readyCount = returnCountsAfterIteration(GlobalUtilities.getUserStoriesAhead(dfs), dfs.Source_Environment__c);
            stepColorMap.put(
                dfs.Source_Environment__c + C_TRUE,
                new StepColorWrapper(true, (readyCount > 0 ? '#00A3E0' : 'transparent'), dfs.Source_Environment__c, dfs.Destination_Environment__c)
            );

            readyCount = returnCountsAfterIteration(
                GlobalUtilities.getUserStoriesBehind(dfs),
                dfs.Source_Environment__c +
                '' +
                dfs.Destination_Environment__c
            );

            //below additional map key is in plave to prevent showing US's available for back promotion to same org
            stepColorMap.put(
                dfs.Source_Environment__c +
                '' +
                dfs.Destination_Environment__c +
                C_FALSE,
                new StepColorWrapper(false, (readyCount > 0 ? '#00A3E0' : 'transparent'), dfs.Destination_Environment__c, dfs.Source_Environment__c)
            );

            stepColorMap.put('cpuTime', new StepColorWrapper(null, String.valueOf(Limits.getLimitCpuTime() - Limits.getCpuTime()), null, null));
            return stepColorMap;
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Schema.SObjectType.Deployment_Flow_Step__c.getName() +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return null;
        }
    }

    public static Integer returnCountsAfterIteration(List<User_Story__c> currentListParam, String envId) {
        Integer readyCount = 0;
        //below control logic is implemented to prevent showing US's available for back promotion to same org
        set<Id> usIds = new Set<Id>();
        List<User_Story__c> currentList = new List<User_Story__c>(currentListParam);
        Integer currentListSize = currentList.size();
        for (Integer j = 0; j < currentListSize; j++) {
            usIds.add(currentList[j].Id);
        }
        Map<Id, List<String>> us_SourceEnvMap = new Map<Id, List<String>>();
        List<Promoted_User_Story__c> pusList = [
            SELECT
                Id,
                Name,
                User_Story__c,
                Promotion__r.Source_Environment__c,
                Promotion__r.Destination_Environment__c,
                Promotion__r.Back_Promotion__c
            FROM Promoted_User_Story__c
            WHERE Promotion__r.Status__c = 'Completed' AND User_Story__c IN :usIds
            ORDER BY CreatedDate DESC
            LIMIT 10000
        ];
        Integer pusListSize = pusList.size();
        for (Integer j = 0; j < pusListSize; j++) {
            Promoted_User_Story__c pus = pusList[j];

            if (!us_SourceEnvMap.containsKey(pus.User_Story__c)) {
                us_SourceEnvMap.put(pus.User_Story__c, new List<String>());
            }

            List<String> tempList = us_SourceEnvMap.get(pus.User_Story__c);
            tempList.add(pus.Promotion__r.Source_Environment__c + '' + pus.Promotion__r.Destination_Environment__c);
            us_SourceEnvMap.put(pus.User_Story__c, tempList);
        }
        for (Integer j = 0; j < currentListSize; j++) {
            User_Story__c us = currentList[j];

            if (
                (us.promote_change__c || envId.length() > 18) &&
                (!us_SourceEnvMap.containsKey(us.Id) || (us_SourceEnvMap.containsKey(us.Id) && !us_SourceEnvMap.get(us.Id).contains(envId)))
            ) {
                readyCount++;
            }
        }
        return readyCount;
    }

    public Id proId;
    public String userStoryName;
    public String testLevel;
    public PageReference createPromotionforValidation() {
        ApexPages.getMessages().clear();
        Boolean isChecked = false, hasApexCode = false;
        List<User_Story__c> usList = new List<User_Story__c>();
        User_Story__c usItem;
        for (UserStoryWrapper usw : latestOverlay.userStories) {
            if (usw.isSelected) {
                usList.add(usw.userStory);
                if (!isChecked) {
                    isChecked = true;
                    usItem = usw.userStory;
                }
                if (!hasApexCode && usw.userStory.Has_Apex_Code__c) {
                    hasApexCode = true;
                }
            }
        }
        if (isChecked) {
            Promotion__c promotion = new Promotion__c();
            if (Schema.SObjectType.Promotion__c.fields.Back_Promotion__c.isCreateable()) {
                promotion.Back_Promotion__c = latestOverlay.pathType.toLowerCase() == C_PULL ? true : false;
            }
            if (Schema.SObjectType.Promotion__c.fields.Project__c.isCreateable()) {
                promotion.Project__c = usItem.Project__c;
            }
            if (Schema.SObjectType.Promotion__c.fields.Release__c.isCreateable()) {
                promotion.Release__c = usItem.Release__c;
            }
            if (Schema.SObjectType.Promotion__c.fields.Source_Org_Credential__c.isCreateable()) {
                promotion.Source_Org_Credential__c = usItem.Org_Credential__c;
            }
            if (Schema.SObjectType.Promotion__c.fields.Destination_Environment__c.isCreateable()) {
                promotion.Destination_Environment__c = latestOverlay.toEnvId;
            }
            if (Schema.SObjectType.Promotion__c.fields.Source_Environment__c.isCreateable()) {
                promotion.Source_Environment__c = usItem.Environment__c;
            }
            if (Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.isCreateable()) {
                promotion.Send_Deployment_Complete_email__c = true;
            }
            try {
                List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();
                Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
                for (User_Story__c us : usList) {
                    promotedUserStories.add(addUserStoryToPromotion(us, promotion));
                    if (Schema.SObjectType.User_Story__c.fields.Last_Validation_Promotion__c.isUpdateable()) {
                        us.Last_Validation_Promotion__c = promotion.Id;
                    }
                }
                if (!promotedUserStories.isEmpty()) {
                    Utilities.Secure_DML(promotedUserStories, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);
                }
                testLevel = (hasApexCode ? 'RunSpecifiedTests' : 'NoTestRun');
                userStoryName = usList[0].Name;
                proId = promotion.Id;
                Utilities.Secure_DML(usList, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                return null;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.You_Need_to_Select_One));
            return null;
        }
    }
    public Promoted_User_Story__c addUserStoryToPromotion(User_Story__c us, Promotion__c p) {
        Promoted_User_Story__c pus = new Promoted_User_Story__c();
        if (Schema.SObjectType.Promoted_User_Story__c.fields.User_Story__c.isCreateable()) {
            pus.User_Story__c = us.Id;
        }
        if (Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.isCreateable()) {
            pus.Promotion__c = p.Id;
        }
        if (Schema.SObjectType.Promoted_User_Story__c.fields.Name.isCreateable()) {
            pus.Name = 'Promoted User Story: ' + us.Name;
        }
        return pus;
    }

    public PageReference redirectToPromotion() {
        if (null != proId) {
            if (!Test.isRunningTest()) {
                DeployAPI.deployPromotion(proId, userStoryName, true, false, testLevel);
            }
            PageReference pageRef = new PageReference('/' + proId);
            pageRef.setRedirect(true);
            return pageRef;
        } else {
            return null;
        }
    }

    /**
     * This method delete pageMessagesMap when user closes Toast.
     */
    public void closeToastMessage() {
        pageMessagesMap = new Map<String, List<Object>>();
    }

    public class StepColorWrapper {
        public Boolean isMerge { get; set; }
        public String color { get; set; }
        public Id envId { get; set; }
        public Id fromEnvId { get; set; }
        public StepColorWrapper(Boolean isMerge, String color, Id envId, Id fromEnvId) {
            this.isMerge = isMerge;
            this.color = color;
            this.envId = envId;
            this.fromEnvId = fromEnvId;
        }
    }

    public class OverlayWrapper {
        public String fromEnvId { get; set; }
        public String fromEnvName { get; set; }
        public String toEnvId { get; set; }
        public String toEnvName { get; set; }
        public Boolean toEnvRunAllTests { get; set; }
        public String pathType { get; set; }
        public List<UserStoryWrapper> userStories { get; set; }
        public Integer commitsAhead { get; set; }
        public Integer commitsBehind { get; set; }
        public List<ErrorWrapper> errors { get; set; }
        public String stepId { get; set; }
        public OverlayWrapper(
            String fromEnvId,
            String toEnvId,
            String fromEnvName,
            String toEnvName,
            String pathType,
            List<Git_Org_Commit__c> commits,
            List<ErrorWrapper> errors,
            String stepId
        ) {
            this.fromEnvId = fromEnvId;
            this.toEnvId = toEnvId;
            this.fromEnvName = fromEnvName;
            this.toEnvName = toEnvName;
            this.pathType = pathType;
            this.userStories = new List<UserStoryWrapper>();
            this.errors = errors;
            this.stepId = stepId;
            this.commitsAhead = 0;
            this.commitsBehind = 0;
        }
        public OverlayWrapper(String fromEnvId, String toEnvId, String fromEnvName, String toEnvName, Boolean toEnvRunAllTests, String pathType) {
            this.fromEnvId = fromEnvId;
            this.toEnvId = toEnvId;
            this.fromEnvName = fromEnvName;
            this.toEnvName = toEnvName;
            this.toEnvRunAllTests = toEnvRunAllTests;
            this.pathType = pathType;
            this.userStories = new List<UserStoryWrapper>();
            this.commitsAhead = 0;
            this.commitsBehind = 0;
        }
    }
    public class RebaseEnvironmentWrapper {
        public Boolean isSelected { get; set; }
        public Deployment_Flow_Step__c step { get; set; }
        public rebaseEnvironmentWrapper(Deployment_Flow_Step__c step) {
            this.isSelected = true;
            this.step = step;
        }
    }
    public class UserStoryWrapper {
        public Boolean isSelected { get; set; }
        public User_Story__c userStory { get; set; }
        public UserStoryWrapper(User_Story__c userStory) {
            this.isSelected = true;
            this.userStory = userStory;
        }
    }

    public class FilesWrapper implements Comparable {
        public String pathType { get; set; }
        public String dmlType { get; set; }
        public String metadataName { get; set; }
        public FilesWrapper(String pathType, String dmlType, String metadataName) {
            this.pathType = pathType;
            this.dmlType = dmlType;
            this.metadataName = metadataName;
        }
        public Integer compareTo(Object compareTo) {
            FilesWrapper t = (FilesWrapper) compareTo;
            if (t.dmlType + t.metadataName == this.dmlType + this.metadataName) {
                return 0;
            }
            if (t.dmlType + t.metadataName > this.dmlType + this.metadataName) {
                return -1;
            }
            return 1;
        }
    }
    public class ErrorWrapper {
        public String pathType { get; set; }
        public String level { get; set; }
        public String errorMessage { get; set; }
        public String copadoTip { get; set; }
        public ErrorWrapper(String pathType, String level, String errorMessage, String copadoTip) {
            this.pathType = pathType;
            this.level = level;
            this.errorMessage = errorMessage;
            this.copadoTip = copadoTip;
        }
    }
    public class CountWrapper {
        public Integer totalCount;
        public Integer nullCount;
        public Integer successCount;
        public Integer readyCount;
        public CountWrapper(Integer totalC, Integer nullC, Integer successC, Integer readyC) {
            this.totalCount = totalC;
            this.nullCount = nullC;
            this.successCount = successC;
            this.readyCount = readyC;
        }
    }
}