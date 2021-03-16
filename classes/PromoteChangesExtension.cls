public with sharing class PromoteChangesExtension {
    // Constants
    private final String C_COMPLETED = 'Completed';
    private final String C_FAIL = 'Fail';
    private final String C_ERROR = 'Error';
    private final String REGRESSION_TEST = 'Regression Test';
    private final String USER_STORY_TEST = 'User Story Test';
    private final String C_SELECT = ' SELECT ';
    private final String CREATE_DEPLOYMENT = 'createDeployment';
    private final String C_REFERENCE = 'reference';
    private final String C_ID = 'id';

    // Non Constants
    public Promotion__c promotion { get; set; }
    public String suggestedDeploymentName { get; set; }
    public List<userStoryWrapper> userStories { get; set; }
    public List<promotedStoryWrapper> promotedWrappedStories { get; set; }
    @TestVisible
    private Set<Id> promotedIdsSet { get; set; }
    public Boolean renderStep1 { get; set; }
    public Boolean renderBtnPromote { get; set; }
    public String branch { get; set; }
    public Boolean enableCreateDeploymentButton { get; set; }
    public Boolean enableSTS { get; set; }
    public Boolean enableUserStoryMetadatas { get; set; }
    public String promotedUserStoryIds { get; set; }
    public String excludeds {
        get {
            if (String.isBlank(excludeds) && null != this.promotion.Project__c) {
                if (Schema.SObjectType.Project__c.isQueryable() && Schema.SObjectType.Project__c.isAccessible()) {
                    excludeds = [SELECT Exclude_Tabs_from_Promotion_Page__c FROM Project__c WHERE Id = :this.promotion.Project__c]
                    .Exclude_Tabs_from_Promotion_Page__c;
                    if (null != excludeds) {
                        excludeds = excludeds.replace(' ', '').toLowerCase();
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Project__c.getLabel());
                    return '';
                }
            }
            return excludeds;
        }
        set;
    }
    public Boolean isCSTEnabled { get; set; }
    public Decimal sourceEnvMaxSCAScore { get; set; }
    public GlobalUtilities.deploymentFlowDetails flowDetails { get; set; }
    public Map<String, String> outdatedUSMetadataMap { get; set; }
    public seleniumTestResultWrapper str { get; set; }
    public String notPromotedUs {
        get {
            if (null == notPromotedUs) {
                notPromotedUs = '';
            }
            return notPromotedUs;
        }
        set;
    }
    public transient Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> usEnvironmentAvailabilityMap { get; set; }
    public Decimal worstSCAscore { get; set; }
    public Decimal averageSCAscore { get; set; }
    public Promoted_User_Story__c mockStoryWrapper { get; set; }
    public Boolean scaAccess { get; set; }
    public Boolean openCreateDeployment { get; set; }
    public transient List<User_Story__c> dependenciesList { get; set; }
    public String ns {
        get {
            if (String.isBlank(ns)) {
                ns = Settings.ns.toLowerCase();
            }
            return ns;
        }
        set;
    }
    private Map<Id, Id> source_destionationMap {
        get {
            if (null == source_destionationMap) {
                source_destionationMap = new Map<Id, Id>();
                if (null != depFlowId) {
                    if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                        for (Deployment_Flow_Step__c s : [
                            SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Source_Environment__r.Name
                            FROM Deployment_Flow_Step__c
                            WHERE Deployment_Flow__c = :depFlowId AND Source_Environment__r.Type__c != 'Scratch Org'
                        ]) {
                            source_destionationMap.put(s.Source_Environment__c, s.Destination_Environment__c);
                            if (this.promotion.Destination_Environment__c != s.Destination_Environment__c) {
                                prevSteps.add(s);
                            }
                        }
                    } else {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.getLabel());
                        return source_destionationMap;
                    }
                }
            }
            return source_destionationMap;
        }
        set;
    }
    public transient List<Promoted_User_Story__c> tmp { get; set; }
    public transient List<User_Story__c> usList {
        get {
            if (null == usList) {
                usList = new List<User_Story__c>();
            }
            return usList;
        }
        set;
    }
    public Promotion__c tempPromotion;
    public List<Deployment_Flow_Step__c> prevSteps {
        get {
            if (null == prevSteps) {
                prevSteps = new List<Deployment_Flow_Step__c>();
            }
            return prevSteps;
        }
        set;
    }
    private Id depFlowId {
        get {
            if (null == depFlowId) {
                if (null != this.tempPromotion.Project__c) {
                    depFlowId = this.tempPromotion.Project__r.Deployment_Flow__c;
                } else if (null != this.tempPromotion.Release__c) {
                    if (null != this.tempPromotion.Release__r.Project__c) {
                        depFlowId = this.tempPromotion.Release__r.Project__r.Deployment_Flow__c;
                    }
                }
            }
            return depFlowId;
        }
        set;
    }
    public String deploymentPrefix {
        get {
            if (!String.isBlank(deploymentPrefix)) {
                return deploymentPrefix;
            }
            Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe();
            Schema.SObjectType s = m.get(ns + 'Deployment__c');
            Schema.DescribeSObjectResult r = s.getDescribe();
            return r.getKeyPrefix();
        }
        set;
    }

    public PromoteChangesExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(Utilities.getAllFields('Promotion__c').get(Label.FIELDS).split(','));
            stdController.addFields(
                new List<String>{
                    ns + 'Release__r.Name',
                    ns + 'Source_Environment__r.Name',
                    ns + 'Destination_Environment__r.Name',
                    ns +
                    'project__r.' +
                    ns +
                    'Deployment_flow__c',
                    ns +
                    'release__r.' +
                    ns +
                    'project__r.' +
                    ns +
                    'Deployment_flow__c'
                }
            );
        }

        scaAccess = FeatureAccessHelper.isSCAFeatureAccessible();
        promotedIdsSet = new Set<Id>();
        renderBtnPromote = false;
        renderStep1 = true;
        enableSTS = false;
        enableUserStoryMetadatas = false;
        outdatedUSMetadataMap = new Map<String, String>();
        str = new seleniumTestResultWrapper();
        tempPromotion = (Promotion__c) stdController.getRecord();
        if (Test.isRunningTest()) {
            if (Schema.SObjectType.Promotion__c.isQueryable() && Schema.SObjectType.Promotion__c.isAccessible()) {
                tempPromotion = [
                    SELECT Release__c, Project__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                    FROM Promotion__c
                    WHERE Id = :stdController.getId()
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promotion__c.getLabel());
                return;
            }
        }
        this.promotion = Utilities.getPromotionById(stdController.getId());
        if (this.promotion == null) {
            this.promotion = new Promotion__c();
        }
        Id cId = this.promotion.Id;
        Integer depCount = 0;

        if (Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
            depCount = Database.countQuery('SELECT COUNT() FROM ' + ns + 'Deployment__c WHERE ' + ns + 'Promotion__c = :cId');
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment__c.getLabel());
            return;
        }

        suggestedDeploymentName =
            'Deploy - ' +
            this.promotion.Name +
            ' => ' +
            (!Test.isRunningTest()
                ? (((Promotion__c) stdController.getRecord()).Destination_Environment__c != null
                      ? ((Promotion__c) stdController.getRecord()).Destination_Environment__r.Name
                      : 'NA')
                : '') +
            ' (' +
            (depCount + 1) +
            ')';

        refreshTables();

        isCSTEnabled = false;
        for (Feature__c feature : [SELECT Name, Enabled__c FROM Feature__c]) {
            if (feature.Name == 'Selenium Testing' && feature.Enabled__c == true) {
                isCSTEnabled = true;
            }
        }

        List<Environment__c> sourceEnv = new List<Environment__c>();
        if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            sourceEnv = [SELECT Maximum_SCA_Score__c FROM Environment__c WHERE Id = :promotion.Source_Environment__c];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Environment__c.getLabel());
            return;
        }
        if (sourceEnv.size() > 0 && sourceEnv[0].Maximum_SCA_Score__c != null) {
            sourceEnvMaxSCAScore = sourceEnv[0].Maximum_SCA_Score__c;
        } else {
            sourceEnvMaxSCAScore = 0;
        }

        // Get URL createDeployment parameter
        String createDeployment = ApexPages.currentPage().getParameters().get(CREATE_DEPLOYMENT);
        openCreateDeployment = createDeployment != null && Boolean.valueOf(createDeployment);
        ApexPages.currentPage().getParameters().remove(CREATE_DEPLOYMENT);

        //Warning about Merge Conflicts
        if (this.promotion.Status__c == 'Merge Conflict') {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Merge_Conflict_Found);
        }
    }

    public void refreshTables() {
        promotedIdsSet = new Set<Id>();
        if (LicenseHelper.isLicensesExceeded()) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.LICENSES_EXCEEDED);
            return;
        }
        getPromotedUserStories();
    }

    public PageReference getPromotedUserStories() {
        Map<Id, Decimal> userStoryScore = new Map<Id, Decimal>();
        promotedWrappedStories = new List<promotedStoryWrapper>();
        Set<String> querySet = new Set<String>();
        for (Schema.FieldSetMember fsm : SObjectType.User_Story__c.fieldSets.PromotionRelatedList.getFields()) {
            if (fsm != null) {
                if (String.valueOf(fsm.type) == C_REFERENCE) {
                    querySet.add(ns + 'user_story__r.' + fsm.getFieldPath().toLowerCase());
                    querySet.add(ns + 'user_story__r.' + fsm.getFieldPath().replace('__c', '__r.name').toLowerCase());
                } else {
                    querySet.add(ns + 'user_story__r.' + fsm.getFieldPath().toLowerCase());
                }
            }
        }
        querySet.add(C_ID);
        querySet.add('User_Story__c');

        if (!Schema.SObjectType.Promoted_User_Story__c.isQueryable() && Schema.SObjectType.Promoted_User_Story__c.isAccessible()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promoted_User_Story__c.getLabel());
            return null;
        }

        for (
            Promoted_User_Story__c pus : Database.query(
                C_SELECT +
                String.join(new List<String>(querySet), ',') +
                ' FROM Promoted_User_Story__c WHERE Promotion__c = \'' +
                String.escapeSingleQuotes(promotion.Id) +
                '\''
            )
        ) {
            promotedWrappedStories.add(new promotedStoryWrapper(false, pus));
            promotedIdsSet.add(pus.User_Story__c);
        }

        if (!validateDeployment() && enableCreateDeploymentButton == true) {
            enableCreateDeploymentButton = false;
        }

        enableCreateDeploymentButton = promotedIdsSet.size() > 0;
        updatePromotedIdSetToString();

        if (!promotion.Back_Promotion__c) {
            dependenciesList = GlobalUtilities.getUserStoriesDependencies(promotedIdsSet, promotion.Destination_Environment__c);
        }
        return null;
    }

    public Boolean validateDeployment() {
        Boolean isSandboxDestinations = false;
        Promotion__c prm = new Promotion__c();
        if (Schema.SObjectType.Promotion__c.isQueryable() && Schema.SObjectType.Promotion__c.isAccessible()) {
            prm = [
                SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Release__r.Base_Branch__c
                FROM Promotion__c
                WHERE Id = :promotion.Id
            ];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promotion__c.getLabel());
            return false;
        }
        List<String> extraFields = new List<String>();
        extraFields.add(ns + 'Git_Repository__r.Pull_Request_Base_URL__c');
        extraFields.add(ns + 'Git_Repository__r.Git_Provider__c');
        if (prm.Project__r.Deployment_Flow__c != null) {
            flowDetails = GlobalUtilities.getDeploymentFlowDetails(prm.Project__r.Deployment_Flow__c, String.join(extraFields, ', '));
        } else if (prm.Release__r.Project__r.Deployment_Flow__c != null) {
            flowDetails = GlobalUtilities.getDeploymentFlowDetails(prm.Release__r.Project__r.Deployment_Flow__c, String.join(extraFields, ', '));
        }
        Boolean isCCMFlow =
            flowDetails?.flow != null &&
            flowDetails.flow.Git_Repository__c == null &&
            flowDetails.flow.Main_Branch__c == null;

        if (promotion != null && (LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled())) {
            // Base Branch Validation
            if (prm.Release__r.Base_Branch__c != null) {
                String userStoryList = '';
                if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                    for (User_Story__c us : [
                        SELECT Id, Name, Base_Branch__c
                        FROM User_Story__c
                        WHERE
                            Id IN (SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = :prm.Id)
                            AND Base_Branch__c != NULL
                            AND Base_Branch__c != :prm.Release__r.Base_Branch__c
                        LIMIT 1000
                    ]) {
                        if (!String.isBlank(userStoryList)) {
                            userStoryList += ', ';
                        }
                        userStoryList += us.Name;
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                    return false;
                }
                if (!String.isBlank(userStoryList)) {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStoryList);
                }
            }

            // CCM Only user validation
            if (!LicenseHelper.isCopadoEnabled() && LicenseHelper.isCCMEnabled()) {
                if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
                    for (Environment__c destinationEnv : [SELECT Id, Type__c FROM Environment__c WHERE Id = :promotion.Destination_Environment__c]) {
                        if (destinationEnv.Type__c == 'Sandbox') {
                            isSandboxDestinations = true;
                        } else {
                            isSandboxDestinations = false;
                            break;
                        }
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Environment__c.getLabel());
                    return false;
                }
                if (!isSandboxDestinations) {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.CCM_DESTINATION_ORG_INVALID);
                    return false;
                }
            }

            if (flowDetails?.flow?.Active__c == true) {
                if (LicenseHelper.isCopadoEnabled() && isCCMFlow) {
                    return true;
                } else if (flowDetails.isCBMFlow) {
                    return true;
                } else {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.CBM_FLOW_INVALID);
                }
            } else {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.PROMOTION_FLOW_INACTIVE);
            }
        } else if (LicenseHelper.isCopadoEnabled()) {
            return true;
        } else {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        }
        return false;
    }

    public void updatePromotedIdSetToString() {
        promotedUserStoryIds = '';
        for (String s : promotedIdsSet) {
            promotedUserStoryIds += (promotedUserStoryIds == '' ? '' : ',') + s;
        }
    }

    /**
     * It is used to check if back promotable user stories calculation enabled
     * if Test.isRunningTest(), we are returning hard coded true, because you can not do DML operation on custom metadata types. Since we are checking for the value which will be created by customer, we will make it pass through the code for test class.
     *
     * @return
     */
    private Boolean checkBackPromotableUserStoriesCalculationIsEnabled(String developerName) {
        Boolean isEnabled = false;
        for (Copado_Setting__mdt backPromoteCalculationSetting : [
            SELECT Enabled__c
            FROM Copado_Setting__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ]) {
            isEnabled = backPromoteCalculationSetting.Enabled__c;
        }
        return isEnabled;
    }

    public void checkBackPromotions() {
        usList.clear();
        Boolean isProd = !source_destionationMap.containsKey(this.promotion.Destination_Environment__c);

        // Hide_Promotion_US_Behind_Warning is not in the package, customer will create it on their own.
        Boolean isBackPromotableCalculationEnabled = checkBackPromotableUserStoriesCalculationIsEnabled('Hide_Promotion_US_Behind_Warning');

        if (isProd && !isBackPromotableCalculationEnabled) {
            Set<Id> destinationEvnIds = new Set<Id>();
            List<Id> sourceIdsList = new List<Id>(source_destionationMap.keySet());
            for (Integer dc = 0; dc < source_destionationMap.size(); dc++) {
                if (source_destionationMap.values()[dc] != this.promotion.Destination_Environment__c) {
                    destinationEvnIds.add(sourceIdsList[dc]);
                }
            }
            usEnvironmentAvailabilityMap = GlobalUtilities.getUserStoriesBehind(prevSteps, destinationEvnIds, depFlowId);
            List<Id> usIdListBehind = new List<Id>(usEnvironmentAvailabilityMap.keySet());
            Integer ifCounter = 0;
            if (Schema.SObjectType.Promoted_User_Story__c.isQueryable() && Schema.SObjectType.Promoted_User_Story__c.isAccessible()) {
                tmp = new List<Promoted_User_Story__c>(
                    [
                        SELECT Id, User_Story__c, User_Story__r.Name, User_Story__r.User_Story_Title__c
                        FROM Promoted_User_Story__c
                        WHERE Promotion__c = :promotion.Id
                    ]
                );
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promoted_User_Story__c.getLabel());
                return;
            }

            Map<Id, User_Story__c> tempMap = new Map<Id, User_Story__c>();
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                tempMap = new Map<Id, User_Story__c>([SELECT Id, Name, User_Story_Title__c FROM User_Story__c WHERE Id IN :usIdListBehind]);
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return;
            }
            for (Promoted_User_Story__c pus : tmp) {
                if (usIdListBehind.contains(pus.User_Story__c)) {
                    usList.add(tempMap.get(pus.User_Story__c));
                    ifCounter++;
                }
            }
            if (ifCounter > 0) {
                notPromotedUs = Label.NotPromotedtoAll;
            }
        }
    }

    public List<seleniumTestWrapper> getSeleniumTestGroups() {
        List<seleniumTestWrapper> seleniumTests = new List<seleniumTestWrapper>();
        //str = new seleniumTestResultWrapper();
        List<Selenium_Test_Group__c> stgs = new List<Selenium_Test_Group__c>();
        List<Id> usTestGroupIds = new List<Id>();

        if (Schema.SObjectType.User_Story_Selenium_Test__c.isQueryable() && Schema.SObjectType.User_Story_Selenium_Test__c.isAccessible()) {
            if (!promotion.Back_Promotion__c) {
                for (User_Story_Selenium_Test__c usST : [
                    SELECT Selenium_Test_Group__c
                    FROM User_Story_Selenium_Test__c
                    WHERE
                        User_Story__c IN :promotedIdsSet
                        AND (User_Story__r.Environment__c = :promotion.Source_Environment__c
                        OR User_Story__r.Environment__c = :promotion.Destination_Environment__c)
                ]) {
                    usTestGroupIds.add(usST.Selenium_Test_Group__c);
                }
            } else {
                for (User_Story_Selenium_Test__c usST : [
                    SELECT Selenium_Test_Group__c
                    FROM User_Story_Selenium_Test__c
                    WHERE User_Story__c IN :promotedIdsSet
                ]) {
                    usTestGroupIds.add(usST.Selenium_Test_Group__c);
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Selenium_Test__c.getLabel());
            return null;
        }

        if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
            for (Selenium_Test_Group__c rSTG : [
                SELECT Id, Name, Environment__c, Environment__r.Name, Type__c, Status__c, Status_Icon__c, Status_Date__c
                FROM Selenium_Test_Group__c
                WHERE
                    Id IN :usTestGroupIds
                    OR (Type__c = :REGRESSION_TEST
                    AND (Environment__c = :promotion.Source_Environment__c
                    OR Environment__c = :promotion.Destination_Environment__c))
            ]) {
                stgs.add(rSTG);
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Group__c.getLabel());
            return null;
        }

        for (Selenium_Test_Group__c tg : stgs) {
            if (tg.Environment__c == promotion.Source_Environment__c) {
                if (tg.Type__c == REGRESSION_TEST) {
                    str.countAllSourceRegression += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedSourceRegression += tg.Status__c.startsWith(C_COMPLETED) ? 1 : 0;
                        str.countFinishedSourceRegression += tg.Status__c.startsWith(C_FAIL) ? 1 : 0;
                        str.countErrorsSourceRegression += tg.Status__c.containsIgnoreCase(C_ERROR) || tg.Status__c.contains(C_FAIL) ? 1 : 0;
                    }
                }
                if (tg.Type__c == USER_STORY_TEST) {
                    str.countAllSourceUserStory += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedSourceUserStory += tg.Status__c.startsWith(C_COMPLETED) ? 1 : 0;
                        str.countFinishedSourceUserStory += tg.Status__c.startsWith(C_FAIL) ? 1 : 0;
                        str.countErrorsSourceUserStory += tg.Status__c.containsIgnoreCase(C_ERROR) || tg.Status__c.contains(C_FAIL) ? 1 : 0;
                    }
                }
                seleniumTests.add(new seleniumTestWrapper('Source', tg));
            } else if (tg.Environment__c == promotion.Destination_Environment__c) {
                if (tg.Type__c == REGRESSION_TEST) {
                    str.countAllDestinationRegression += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedDestinationRegression += tg.Status__c.startsWith(C_COMPLETED) ? 1 : 0;
                        str.countFinishedDestinationRegression += tg.Status__c.startsWith(C_FAIL) ? 1 : 0;
                        str.countErrorsDestinationRegression += tg.Status__c.containsIgnoreCase(C_ERROR) || tg.Status__c.contains(C_FAIL) ? 1 : 0;
                    }
                }
                if (tg.Type__c == USER_STORY_TEST) {
                    str.countAllDestinationUserStory += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedDestinationUserStory += tg.Status__c.startsWith(C_COMPLETED) ? 1 : 0;
                        str.countFinishedDestinationUserStory += tg.Status__c.startsWith(C_FAIL) ? 1 : 0;
                        str.countErrorsDestinationUserStory += tg.Status__c.containsIgnoreCase(C_ERROR) || tg.Status__c.contains(C_FAIL) ? 1 : 0;
                    }
                }
                seleniumTests.add(new seleniumTestWrapper('Destination', tg));
            }
        }
        return seleniumTests;
    }

    public void calculateSCAScores() {
        Map<Id, Decimal> userStoryScore = new Map<Id, Decimal>();
        if (Schema.SObjectType.Static_Code_Analysis_Result__c.isQueryable() && Schema.SObjectType.Static_Code_Analysis_Result__c.isAccessible()) {
            for (Static_Code_Analysis_Result__c scar : [
                SELECT Score_v11__c, User_Story__c
                FROM Static_Code_Analysis_Result__c
                WHERE User_Story__c IN :promotedIdsSet
                ORDER BY CreatedDate ASC
            ]) {
                // calculate SCA score
                userStoryScore.put(scar.User_Story__c, scar.Score_v11__c);
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Static_Code_Analysis_Result__c.getLabel());
            return;
        }
        // calculate SCA score
        Integer stories = 0;
        Decimal totalScore = 0;
        for (Id usId : userStoryScore.keySet()) {
            totalScore += userStoryScore.get(usId);
            stories += 1;
            if (worstSCAscore < userStoryScore.get(usId)) {
                worstSCAscore = userStoryScore.get(usId);
                mockStoryWrapper = new Promoted_User_Story__c(User_Story__c = usId);
            }
        }
        if (totalScore > 0 && stories > 0) {
            averageSCAscore = totalScore / stories;
        }
    }

    public PageReference reloadPromotion() {
        PageReference ref = Page.PromoteChanges;
        ref.getParameters().put(C_ID, promotion.Id);
        ref.setRedirect(true);
        return ref;
    }

    public PageReference openResolveConflictsPage() {
        PageReference ref = Page.ResolveConflicts;
        ref.getParameters().put('promotionId', promotion.Id);
        ref.setRedirect(true);
        return ref;
    }

    public PageReference listUserStories() {
        userStories = new List<userStoryWrapper>();
        Set<String> querySet = new Set<String>();
        for (Schema.FieldSetMember f : SObjectType.User_Story__c.fieldSets.PromotionRelatedList.getFields()) {
            if (String.valueOf(f.type) == C_REFERENCE) {
                querySet.add(f.getFieldPath().toLowerCase());
                querySet.add(f.getFieldPath().replace('__c', '__r.name').toLowerCase());
            } else {
                querySet.add(f.getFieldPath().toLowerCase());
            }
        }
        querySet.add(C_ID);

        if (!promotion.Back_Promotion__c) {
            //List<User_Story__c> usList = new List<User_Story__c>();
            String usQuery =
                C_SELECT +
                String.join(new List<String>(querySet), ',') +
                ' FROM User_Story__c WHERE Promote_Change__c = true ' +
                ' AND Environment__c = \'' +
                String.escapeSingleQuotes(promotion.Source_Environment__c) +
                '\'';
            if (promotion.Project__c != null) {
                usQuery += ' AND Project__c = \'' + String.escapeSingleQuotes(promotion.Project__c) + '\' Limit 999';
            } else if (promotion.Release__c != null) {
                usQuery += ' AND Release__c = \'' + String.escapeSingleQuotes(promotion.Release__c) + '\' Limit 999';
            }
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                if (promotion.Project__c != null || promotion.Release__c != null) {
                    //usList = Database.query(usQuery);
                    for (User_Story__c us : Database.query(usQuery)) {
                        if (!promotedIdsSet.contains(us.Id)) {
                            userStories.add(new userStoryWrapper(false, us));
                        }
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return null;
            }
        } else {
            List<Deployment_Flow_Step__c> flowStep = new List<Deployment_Flow_Step__c>();
            if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                flowStep = [
                    SELECT
                        Deployment_Flow__c,
                        Source_Environment__c,
                        Source_Environment__r.Name,
                        Branch__c,
                        Destination_Environment__c,
                        Destination_Environment__r.Name,
                        Last_Merge_Base__c,
                        Last_Merge_CBM_Sync__c,
                        Last_Pull_CBM_Sync__c,
                        Destination_Branch__c
                    FROM Deployment_Flow_Step__c
                    WHERE Deployment_Flow__c = :flowDetails.flow.Id AND Source_Environment__c = :promotion.Destination_Environment__c
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.getLabel());
                return null;
            }

            Set<String> usIdSet = new Set<String>();
            if (!flowStep.isEmpty()) {
                for (User_Story__c userStory : GlobalUtilities.getUserStoriesFromFieldsetBehind(querySet, flowStep.get(0))) {
                    usIdSet.add(userStory.Id);
                }

                querySet.add(SObjectType.User_Story__c.fields.Project__c.getName().toLowerCase());
                querySet.add(SObjectType.User_Story__c.fields.Release__c.getName().toLowerCase());
                if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                    String userStoryQueryString =
                        C_SELECT +
                        String.join(new List<String>(querySet), ',') +
                        '  FROM User_Story__c WHERE Id IN :usIdSet';
                    for (User_Story__c userStory : Database.query(userStoryQueryString)) {
                        if (
                            !promotedIdsSet.contains(userStory.Id) &&
                            userStories.size() < 999 &&
                            (promotion.Project__c != null &&
                            promotion.Project__c == userStory.Project__c ||
                            promotion.Release__c != null &&
                            promotion.Release__c == userStory.Release__c)
                        ) {
                            userStories.add(new userStoryWrapper(false, userStory));
                        }
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                    return null;
                }
            }
        }

        return null;
    }

    public void removeSelectedUserStories() {
        List<Promoted_User_Story__c> removals = new List<Promoted_User_Story__c>();
        for (promotedStoryWrapper pus : promotedWrappedStories) {
            if (pus.selected) {
                removals.add(new Promoted_User_Story__c(Id = pus.promotedUS.Id));
            }
        }
        Utilities.Secure_DML(removals, Utilities.DML_Action.DEL, Schema.SObjectType.Promoted_User_Story__c);
        refreshTables();
        listUserStories();
    }

    public void addStoriesToPromotion() {
        // check if there is any userStories
        if (userStories == null || userStories.isEmpty()) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.INFO, Label.NO_USER_STORIES_TO_PROMOTE);
            return;
        }
        // review the database status so no duplicate records are created
        if (!Schema.SObjectType.Promoted_User_Story__c.isQueryable() && !Schema.SObjectType.Promoted_User_Story__c.isAccessible()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promoted_User_Story__c.getLabel());
            return;
        }

        String pusStringQuery =
            'SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = \'' +
            String.escapeSingleQuotes(promotion.Id) +
            '\'';
        for (Promoted_User_Story__c pus : Database.query(pusStringQuery)) {
            promotedIdsSet.add(pus.User_Story__c);
        }
        //Check promotedWrappedStories and add them to the promotedIdsSet
        for (promotedStoryWrapper pusw : promotedWrappedStories) {
            if (!promotedIdsSet.contains(pusw.promotedUS.User_Story__c)) {
                promotedIdsSet.add(pusw.promotedUS.User_Story__c);
            }
        }

        Integer selcount = 0;
        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        for (userStoryWrapper usw : userStories) {
            if (usw.selected) {
                selcount++;
            }
        }
        if (selcount == 0) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.INFO, Label.NO_USER_STORIES_TO_PROMOTE);
            return;
        }
        for (userStoryWrapper usw : userStories) {
            if (usw.selected) {
                selcount++;
                if (!promotedIdsSet.contains(usw.userStory.Id)) {
                    promotedIdsSet.add(usw.userStory.Id);
                    String userStoryTitle = (!String.isBlank(usw.userStory.User_Story_Title__c)) ? usw.userStory.User_Story_Title__c : '';
                    if (userStoryTitle.length() > 80) {
                        userStoryTitle = userStoryTitle.left(80);
                    }
                    promotedStories.add(
                        new Promoted_User_Story__c(Name = userStoryTitle, User_Story__c = usw.userStory.Id, Promotion__c = promotion.Id)
                    );
                }
            }
        }
        try {
            Utilities.Secure_DML(promotedStories, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }
        refreshTables();
        listUserStories();
    }

    public Boolean getIsSeleniumRunning() {
        List<seleniumTestWrapper> stwList = getSeleniumTestGroups();
        if (stwList != null && !stwList.isEmpty()) {
            for (seleniumTestWrapper stw : stwList) {
                if (stw.testGroup.Status__c == 'Queued' || stw.testGroup.Status__c == 'In Progress') {
                    return true;
                }
            }
        }
        return false;
    }

    public void refreshSeleniumTestGroups() {
        getSeleniumTestGroups();
    }

    private PageReference runTestsSourceRegressionAll(Integer environment, Integer groupoftests) {
        Integer i = RunTestGroupsBatch.runSeleniumTestsOfPromotionId(promotion.Id, environment, groupoftests);
        if (i == 0) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.PROMOTION_RUN_NO_TESTS);
        } else {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.INFO, Label.PROMOTION_RUN_RUNNING);
        }
        return null;
    }

    public PageReference runTestsSourceRegression() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_SOURCE, RunTestGroupsBatch.MODE_REGRESSION_ONLY);
    }

    public PageReference runTestsSourceUserStory() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_SOURCE, RunTestGroupsBatch.MODE_USERSTORY_ONLY);
    }

    public PageReference runTestsDestinationRegression() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_REGRESSION_ONLY);
    }

    public PageReference runTestsDestinationUserStory() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_USERSTORY_ONLY);
    }

    public Datetime lastCommitDate;
    public Datetime lastCommitDateDesc;
    public Integer totalCount {
        get {
            if (null == totalCount) {
                if (Schema.SObjectType.User_Story_Metadata__c.isQueryable() && Schema.SObjectType.User_Story_Metadata__c.isAccessible()) {
                    totalCount = [SELECT COUNT() FROM User_Story_Metadata__c WHERE User_Story__c IN :promotedIdsSet];
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Metadata__c.getLabel());
                    return totalCount;
                }
            }
            return totalCount;
        }
        set;
    }
    public Boolean isFirst {
        get {
            if (null == isFirst) {
                isFirst = false;
            }
            return isFirst;
        }
        set;
    }
    public Boolean isNext {
        get {
            if (null == isNext) {
                isNext = true;
            }
            return isNext;
        }
        set;
    }
    public Integer pageCounter {
        get {
            if (null == pageCounter) {
                pageCounter = 1;
            }
            return pageCounter;
        }
        set;
    }
    public Boolean isNextOk {
        get {
            if (null == isNextOk) {
                isNextOk = false;
            }
            return isNextOk;
        }
        set;
    }

    /**
     * below is UserStoryMetadatas getter instead of a variable based on view state concern and also has a pagination logic inside which is triggered via prevb4M and nextb4M buttons on promoteChanges.page
     *
     * @return
     */
    public List<User_Story_Metadata__c> getUserStoryMetadatas() {
        List<User_Story_Metadata__c> userStoryMetadatas = new List<User_Story_Metadata__c>();
        Integer limitHeapSize = Limits.getLimitHeapSize();
        Integer maxMetadataHeapSize = 0;
        Integer limitCPUTime = Limits.getLimitCpuTime();
        Integer maxCPUTime = 0;
        if (isFirst && !promotedIdsSet.isEmpty()) {
            try {
                Map<String, User_Story_Metadata__c> userStoryMetadataNameMap = new Map<String, User_Story_Metadata__c>();
                String usOrderByFieldName = '';
                String soqlUsOrderByFieldName = '';
                if (String.isNotBlank(promotion.Order_by__c)) {
                    usOrderByFieldName = promotion.Order_by__c.trim().removeStart(ns).substringBefore(' ');
                    // This variable is used for a dynamic SOQL, so Namespace is no needed according to Salesforce Doc.
                    soqlUsOrderByFieldName = ', User_Story__r.' + usOrderByFieldName;
                }
                if (Schema.SObjectType.User_Story_Metadata__c.isQueryable() && Schema.SObjectType.User_Story_Metadata__c.isAccessible()) {
                    String strQuery = 'SELECT Name, Status_Icon__c, Metadata_API_Name__c, Status__c, Last_Commit_Date__c, User_Story__c, User_Story__r.Name, CreatedDate';
                    if (!strQuery.toLowerCase().replaceAll('\\s+', '').contains(soqlUsOrderByFieldName.toLowerCase().replaceAll('\\s+', ''))) {
                        strQuery += soqlUsOrderByFieldName;
                    }
                    strQuery +=
                        ' FROM User_Story_Metadata__c WHERE User_Story__c IN :promotedIdsSet ' +
                        (null == lastCommitDate
                            ? 'ORDER BY Last_Commit_Date__c DESC'
                            : (isNext
                                  ? ' AND Last_Commit_Date__c > :lastCommitDate ORDER BY Last_Commit_Date__c DESC '
                                  : ' AND Last_Commit_Date__c < :lastCommitDateDesc ORDER BY Last_Commit_Date__c ASC ')) +
                        ' LIMIT 1000';
                    for (User_Story_Metadata__c usMetadata : Database.query(strQuery)) {
                        Integer startingHeap = Limits.getHeapSize();
                        Integer startingCpuTime = Limits.getCpuTime();
                        if ((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                            System.debug('### Heap Size limit reached. Exit User Story Metadata for loop.');
                            break;
                        }
                        userStoryMetadatas.add(usMetadata);

                        // Adding all user story metadata name to map to check if it is duplicate. If it is duplicate, we will check the promotion order by field to compare last commit date.
                        if (!userStoryMetadataNameMap.containsKey(usMetadata.Metadata_API_Name__c)) {
                            userStoryMetadataNameMap.put(usMetadata.Metadata_API_Name__c, usMetadata);
                        } else {
                            Datetime datetimeValueInMap = userStoryMetadataNameMap.get(usMetadata.Metadata_API_Name__c).Last_Commit_Date__c;
                            Datetime iteratedDatetimeValue = usMetadata.Last_Commit_Date__c;
                            // Namespace no needed in this case for 'USer_Story__r'
                            String itemValueInMap = String.isNotBlank(promotion.Order_by__c)
                                ? String.valueOf(
                                      userStoryMetadataNameMap.get(usMetadata.Metadata_API_Name__c)
                                          .getSObject('User_Story__r')
                                          .get(usOrderByFieldName)
                                  )
                                : userStoryMetadataNameMap.get(usMetadata.Metadata_API_Name__c).User_Story__r.Name;
                            String iteratedItemValue = String.isNotBlank(promotion.Order_by__c)
                                ? String.valueOf(usMetadata.getSObject('User_Story__r').get(usOrderByFieldName))
                                : usMetadata.User_Story__r.Name;

                            if (datetimeValueInMap > iteratedDatetimeValue && itemValueInMap < iteratedItemValue) {
                                if (outdatedUSMetadataMap.isEmpty()) {
                                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Outdated_Component_In_Promotion);
                                }
                                String warningValue = String.format(
                                    Label.Outdated_User_Story_Metadata,
                                    new List<String>{
                                        usMetadata.Name,
                                        userStoryMetadataNameMap.get(usMetadata.Metadata_API_Name__c).User_Story__r.Name
                                    }
                                );
                                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, warningValue);
                                outdatedUSMetadataMap.put(usMetadata.Metadata_API_Name__c, usMetadata.User_Story__c);
                            }
                        }

                        Integer addedHeap = Limits.getHeapSize() - startingHeap;
                        Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                        if (addedHeap > maxMetadataHeapSize) {
                            maxMetadataHeapSize = addedHeap;
                        }
                        if (addedCpuTime > maxCPUTime) {
                            maxCPUTime = addedCpuTime;
                        }
                    }

                    if (!userStoryMetadatas.isEmpty()) {
                        lastCommitDate = isNext
                            ? userStoryMetadatas[userStoryMetadatas.size() - 1].Last_Commit_Date__c
                            : userStoryMetadatas[0].Last_Commit_Date__c;
                        lastCommitDateDesc = isNext
                            ? userStoryMetadatas[0].Last_Commit_Date__c
                            : userStoryMetadatas[userStoryMetadatas.size() - 1].Last_Commit_Date__c;
                    }
                    isFirst = false;
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Metadata__c.getLabel()); //return empty list rather than null
                }
            } catch (Exception ex) {
                UIDesignHelper.catchExceptionMessage(ex); //return empty list rather than null
            }
        }
        return userStoryMetadatas;
    }

    public void enableSeleniumTab() {
        resetDom();
        enableSTS = true;
    }

    public void enableMetadataTab() {
        resetDom();
        enableUserStoryMetadatas = true;
    }

    public PageReference resetDom() {
        isNext = true;
        isFirst = true;
        enableSTS = false;
        enableUserStoryMetadatas = false;
        worstSCAscore = 0;
        averageSCAscore = 0;
        lastCommitDate = null;
        str = new seleniumTestResultWrapper();
        userStories = new List<userStoryWrapper>();
        promotedWrappedStories = new List<promotedStoryWrapper>();
        usList = new List<User_Story__c>();
        UIDesignHelper.clearPageMessages();
        return null;
    }

    /**
     * This is used to create new user story with outdated user story metadata, user story org will be source org of the promotion.
     *
     * @return It will redirect you to git commit page by auto selected metadata
     */
    public PageReference createNewUs() {
        if (!outdatedUSMetadataMap.isEmpty()) {
            List<User_Story__c> usList = new List<User_Story__c>();
            Map<String, String> userStoryFieldsMap = Utilities.getAllFields('User_Story__c');
            Set<String> usIdSet = new Set<String>();
            usIdSet.addAll(outdatedUSMetadataMap.values());
            String queryString =
                'SELECT ' +
                userStoryFieldsMap.get(Label.FIELDS) +
                ' FROM ' +
                userStoryFieldsMap.get(Label.OBJECT) +
                ' WHERE Id IN :usIdSet LIMIT 1';
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                usList = Database.query(queryString);
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return null;
            }
            List<Attachment> existingAttachmentList = new List<Attachment>();
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                existingAttachmentList = [SELECT Id, Name, Body FROM Attachment WHERE ParentId IN :usIdSet AND Name = 'Git Metadata'];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.getLabel());
                return null;
            }

            if (!usList.isEmpty()) {
                try {
                    String userStoryName = promotion.Name + ' ==> ' + Label.Updated_User_Story_Metadata;
                    List<User_Story__c> clonedUsList = new List<User_Story__c>();
                    if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                        clonedUsList = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :userStoryName LIMIT 1];
                    } else {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                        return null;
                    }

                    String userStoryId = '';
                    if (!clonedUsList.isEmpty()) {
                        userStoryId = clonedUsList[0].Id;
                    } else {
                        User_Story__c us = new User_Story__c();
                        us.User_Story_Title__c = userStoryName;
                        us.Org_Credential__c = promotion.Source_Org_Credential__c;
                        us.Status__c = 'In Progress';
                        us.Promote_Change__c = true;
                        us.Project__c = usList[0].Project__c;
                        us.Release__c = usList[0].Release__c;
                        us.Sprint__c = usList[0].Sprint__c;
                        us.Epic__c = usList[0].Epic__c;
                        us.Story_Points_SFDC__c = 1;
                        us.Developer__c = usList[0].Developer__c;
                        us.Team__c = usList[0].Team__c;
                        Utilities.Secure_DML(us, Utilities.DML_Action.INS, Schema.SObjectType.User_Story__c);

                        userStoryId = us.Id;

                        Promoted_User_Story__c pus = new Promoted_User_Story__c();
                        pus.User_Story__c = us.Id;
                        pus.Promotion__c = promotion.Id;
                        Utilities.Secure_DML(pus, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);
                    }

                    List<MetaDataItem> metadataItemList = new List<MetaDataItem>();
                    for (Attachment att : existingAttachmentList) {
                        metadataItemList.addAll((List<MetaDataItem>) JSON.deserialize(att.Body.toString(), List<MetaDataItem>.class));
                    }

                    Map<String, MetaDataItem> mdiMap = new Map<String, MetaDataItem>();
                    for (String metadataTypeAndName : outdatedUSMetadataMap.keySet()) {
                        for (MetaDataItem existingMdi : metadataItemList) {
                            String typeAndName = existingMdi.t + '.' + existingMdi.n;
                            if (typeAndName == metadataTypeAndName && !mdiMap.containsKey(metadataTypeAndName)) {
                                MetaDataItem mdi = new MetaDataItem();
                                mdi.t = existingMdi.t;
                                mdi.n = existingMdi.n;
                                mdi.r = false;
                                mdi.s = true;
                                mdiMap.put(metadataTypeAndName, mdi);
                            }
                        }
                    }

                    Attachment att = new Attachment(
                        ParentId = userStoryId,
                        Name = 'MetadataPreselection-UsertStoryImport',
                        Body = Blob.valueOf(JSON.serialize(mdiMap.values()))
                    );
                    Utilities.Secure_DML(att, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);

                    PageReference pr = Page.GitCommitMain;
                    pr.getParameters().put('variant', 'userstoryCommit');
                    pr.getParameters().put('userStoryId', userStoryId);
                    pr.getParameters().put('MetadataPreselectionId', att.Id);
                    pr.setRedirect(true);
                    return pr;
                } catch (Exception ex) {
                    UIDesignHelper.catchExceptionMessage(ex);
                    return null;
                }
            }
        } else {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.No_Outdated_User_Story_Metadata);
            return null;
        }
        return null;
    }

    /**
     * wrapper class to create an attachment for auto populate the selected metadata for cloned us fro outdated user story metadata.
     */
    public class MetaDataItem {
        public String t { get; set; } // typetest
        public String n { get; set; } // name
        public Boolean r; // retrieve only
        public Boolean s; // selected
        public String cb; // created by
        public String cd; // created date
    }

    public String jobsManagerMatchingKeys {
        get {
            Map<Id, String> branchesPerEnv = new Map<Id, String>();
            List<Promotion__c> promotionList = new List<Promotion__c>();
            if (Schema.SObjectType.Promotion__c.isQueryable() && Schema.SObjectType.Promotion__c.isAccessible()) {
                promotionList = [
                    SELECT
                        Project__c,
                        Release__c,
                        Project__r.Deployment_Flow__c,
                        Project__r.Deployment_Flow__r.Active__c,
                        Project__r.Deployment_Flow__r.Git_Repository__c,
                        Destination_Org_Credential__r.Environment__c
                    FROM Promotion__c
                    WHERE Id = :promotion.Id
                    LIMIT 1
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Promotion__c.getLabel());
                return '';
            }
            if (!promotionList.isEmpty()) {
                if (promotionList[0].Project__r.Deployment_Flow__c == null || promotionList[0].Destination_Org_Credential__r.Environment__c == null) {
                    return '';
                }
                branchesPerEnv = getEnvsAndBranchesOfDeploymentFlow(promotionList[0].Project__r.Deployment_Flow__c);
                branch = '';
                if (branchesPerEnv.containsKey(promotionList[0].Destination_Org_Credential__r.Environment__c)) {
                    branch = branchesPerEnv.get(promotionList[0].Destination_Org_Credential__r.Environment__c);
                }
                return 'GIT-' + promotionList[0].Project__r.Deployment_Flow__r.Git_Repository__c + '-' + branch;
            } else {
                return '';
            }
        }
        set;
    }

    public static Map<Id, String> getEnvsAndBranchesOfDeploymentFlow(Id dfId) {
        Map<Id, String> envsAndBranches = new Map<Id, String>(); // Env.Id, Branch_name
        Deployment_Flow__c df = new Deployment_Flow__c();
        if (Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            df = [SELECT Id, Name, Git_Repository__c, Main_Branch__c FROM Deployment_Flow__c WHERE Id = :dfId];
            List<Deployment_Flow_Step__c> steps = [
                SELECT Source_Environment__c, Branch__c, Destination_Environment__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :df.Id
            ];
            if (steps.size() > 0) {
                for (Deployment_Flow_Step__c step : steps) {
                    if (step.Source_Environment__c != null) {
                        envsAndBranches.put(step.Source_Environment__c, step.Branch__c);
                    }
                }
                // any dest environment not previously set as a source somewhere, is the main env, and matches the main branch.
                for (Deployment_Flow_Step__c step : steps) {
                    if (step.Destination_Environment__c != null && !envsAndBranches.containsKey(step.Destination_Environment__c)) {
                        envsAndBranches.put(step.Destination_Environment__c, df.Main_Branch__c);
                    }
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow__c.getLabel()); //return empty map instead of null
        }
        return envsAndBranches;
    }

    /**
     * This is used to check if org has chatter enabled so chatter component is hidden and not rendered
     *
     * @return
     */
    public static Boolean getisChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Promotion__c.isFeedEnabled();
    }

    public class promotedStoryWrapper {
        public Boolean selected { get; set; }
        public Promoted_User_Story__c promotedUS { get; set; }
        public promotedStoryWrapper(Boolean b, Promoted_User_Story__c pus) {
            this.selected = b;
            this.promotedUS = pus;
        }
    }
    public class userStoryWrapper {
        public Boolean selected { get; set; }
        public User_Story__c userStory { get; set; }
        public userStoryWrapper(Boolean b, User_Story__c us) {
            this.selected = b;
            this.userStory = us;
        }
    }
    public class seleniumTestWrapper {
        public String location { get; set; }
        public Selenium_Test_Group__c testGroup { get; set; }
        public seleniumTestWrapper(String location, Selenium_Test_Group__c stg) {
            this.location = location;
            this.testGroup = stg;
        }
    }
    public class seleniumTestResultWrapper {
        public Integer countAllSourceRegression { get; set; }
        public Integer countFinishedSourceRegression { get; set; }
        public Integer countErrorsSourceRegression { get; set; }

        public Integer countAllDestinationRegression { get; set; }
        public Integer countFinishedDestinationRegression { get; set; }
        public Integer countErrorsDestinationRegression { get; set; }

        public Integer countAllSourceUserStory { get; set; }
        public Integer countFinishedSourceUserStory { get; set; }
        public Integer countErrorsSourceUserStory { get; set; }

        public Integer countAllDestinationUserStory { get; set; }
        public Integer countFinishedDestinationUserStory { get; set; }
        public Integer countErrorsDestinationUserStory { get; set; }

        public seleniumTestResultWrapper() {
            this.countAllSourceRegression = 0;
            this.countFinishedSourceRegression = 0;
            this.countErrorsSourceRegression = 0;

            this.countAllDestinationRegression = 0;
            this.countFinishedDestinationRegression = 0;
            this.countErrorsDestinationRegression = 0;

            this.countAllSourceUserStory = 0;
            this.countFinishedSourceUserStory = 0;
            this.countErrorsSourceUserStory = 0;

            this.countAllDestinationUserStory = 0;
            this.countFinishedDestinationUserStory = 0;
            this.countErrorsDestinationUserStory = 0;
        }
    }
}