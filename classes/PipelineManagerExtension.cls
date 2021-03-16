public with sharing class PipelineManagerExtension {
    private static final String LEVEL_NO_TEST_RUN = 'NoTestRun';
    private static final String LEVEL_RUN_SPECIFIED_TESTS = 'RunSpecifiedTests';

    //TODO: improve whole class
    // Constants
    public final String MANAGER {
        get {
            return 'manager';
        }
    }
    public final String DIAGRAM {
        get {
            return 'diagram';
        }
    }
    public final String namespace {
        get {
            if (namespace == null) {
                namespace = Settings.ns;
            }
            return namespace;
        }
        private set;
    }
    private final String USER_STORY = 'User_Story__c';
    private final String ERROR = 'error';
    private final String STAGE = 'Stage ';
    private final String C_PULL = 'pull';
    private final String COMPLETED = 'Completed';
    private final String WARNING = 'warning';
    private final String INFO = 'info';
    private final String IS_DELETED = SObjectType.User_Story__c.fields.IsDeleted.name;

    //common variables
    public Deployment_Flow__c currentPipeline { get; set; }
    public String pipelineMode { get; set; }
    public String allEnvironmentsByStageGroupMapJson { get; set; }
    public Map<String, Map<String, Set<EnvironmentWrapper>>> allEnvironmentsByStageGroupMap { get; set; }
    public Map<String, List<Object>> pageMessagesMap { get; set; }

    //promotion related variables
    public BranchManagementExtension.OverlayWrapper newOverlay { get; set; }
    public Boolean showComplianceResults { get; set; }
    public Boolean showSeleniumResults { get; set; }
    public Boolean showUserStories { get; set; }
    public Boolean promotionListOnly { get; set; }
    public Boolean enabledPromotionBackPromotionPoller { get; set; }
    private Boolean isDeploy = false;
    private Boolean isCheckOnly = false;
    public String testLevel { get; set; }
    public Id currentProId4Dependency { get; set; }
    public Promotion__c promotion { get; set; }
    public List<PromotionWrapper> promotionListWrapper { get; set; }
    public Map<String, String> promIdsSelectedMap { get; set; }
    @TestVisible
    private Map<Promotion__c, Set<Id>> pro2promotedIdsMap {
        get {
            if (null == pro2promotedIdsMap) {
                pro2promotedIdsMap = new Map<Promotion__c, Set<Id>>();
            }
            return pro2promotedIdsMap;
        }
        set;
    }

    //internal calculation variables
    public String selectedEnvironmentString { get; set; }
    private Set<String> nextEnvIdsSet;
    @TestVisible
    private Set<String> allSourceIdsSet { get; set; }
    public String allSourceIdsJSON {
        get {
            return JSON.serialize(allSourceIdsSet);
        }
        set;
    }
    @TestVisible
    private Set<String> allDestinationIdsSet { get; set; } //this could be flowStepEnvMap.keyset() this map's key is always DestinationEnvironment.
    public String allDestinationIdsJSON {
        get {
            return JSON.serialize(allDestinationIdsSet);
        }
        set;
    }
    public Map<String, Integer> flowStepEnvSizeMap { get; set; }
    public Map<Id, List<User_Story__c>> dependenciesMap {
        get {
            if (null == dependenciesMap) {
                dependenciesMap = new Map<Id, List<User_Story__c>>();
            }
            return dependenciesMap;
        }
        set;
    }
    public Map<String, Environment__c> allEnvironmentsMap { get; set; }
    private Map<String, Set<String>> flowStepEnvMap;
    public Map<String, String> flowStepToEnvMap { get; set; }
    public String errorMessage { get; private set; }

    //filters
    public String selectedFilterId { get; set; }
    public Boolean renderInApproval { get; set; }

    public PipelineManagerExtension(ApexPages.StandardController pipelineController) {
        if (!Test.isRunningTest()) {
            pipelineController.addFields(new List<String>(Schema.SObjectType.Deployment_Flow__c.fields.getMap().keySet()));
        }

        pipelineMode = ApexPages.currentPage().getParameters().get('mode');
        pageMessagesMap = new Map<String, List<Object>>();
        if (String.isBlank(pipelineMode) || (pipelineMode != DIAGRAM && pipelineMode != MANAGER)) {
            pipelineMode = DIAGRAM;
        }

        pageMessagesMap = new Map<String, List<Object>>();
        if (!FeatureHelper.isFeatureEnabled('Branch Management')) {
            pageMessagesMap.put('INFO', new List<Object>{ Label.Branch_Management_Not_Enabled });
        }

        currentPipeline = (Deployment_Flow__c) pipelineController.getRecord();
        if (currentPipeline.Id == null) {
            if (Schema.SObjectType.Deployment_Flow__c.isAccessible() && Schema.SObjectType.Deployment_Flow__c.isQueryable()) {
                try {
                    if (!Test.isRunningTest()) {
                        currentPipeline = (Deployment_Flow__c) Database.query(
                            'SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Active__c = TRUE ORDER BY LastViewedDate DESC LIMIT 1'
                        );
                    } else {
                        currentPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Active__c = true];
                    }
                } catch (Exception excp) {
                    currentPipeline = new Deployment_Flow__c();
                    pageMessagesMap = UIDesignHelper.genericWarningMessage(WARNING, new List<String>{ Label.Pipeline_Not_Active_Error });
                }
            } else {
                currentPipeline = new Deployment_Flow__c();
                pageMessagesMap = UIDesignHelper.genericWarningMessage(
                    WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Deployment_Flow__c.getLabel()
                    }
                );
            }
        }

        promotionListOnly = false;
        allEnvironmentsByStageGroupMap = new Map<String, Map<String, Set<EnvironmentWrapper>>>();
        allEnvironmentsMap = new Map<String, Environment__c>();
        renderInApproval = false;

        if (pipelineMode == DIAGRAM) {
            addWarnings();
        }

        initFilter();
    }

    public String getSelectedFilterJSON() {
        UserStoryFilterWrapper tempFilter = selectedFilter;
        tempFilter.thisFilter.Parameters__c = '';
        return JSON.serialize(tempFilter, true);
    }

    public String getAllEnvironmentsKeysetJSON() {
        return JSON.serialize(allEnvironmentsMap.keySet(), true);
    }

    public String getAllEnvironmentsToStageGroupKeysetJSON() {
        return JSON.serialize(allEnvironmentsByStageGroupMap, true);
    }

    public String getFlowStepToEnvironmentJSON() {
        if (flowStepToEnvMap == null) {
            return '';
        }
        return JSON.serialize(flowStepToEnvMap, true);
    }

    public void recalculate() {
        getPromotableUserStoriesCount();
        getBackPromotableUserStoriesCount();
        if (renderInApproval != null && renderInApproval) {
            calculateApprovalPendingUserStories();
        }
    }

    /**
     * It is used to fill EnvironmentWrapper user story list based on parameter which can be in progress or approval
     *
     * @param filterType
     */
    private void populateEnvironmentWraperUserStories(List<AggregateResult> aggrList, String filterType) {
        Map<String, Integer> envToCountMap = new Map<String, Integer>();
        for (AggregateResult uStory : aggrList) {
            envToCountMap.put((String) uStory.get('env'), (Integer) uStory.get('inApprovalCount'));
        }

        Map<String, Set<EnvironmentWrapper>> envMap = new Map<String, Set<EnvironmentWrapper>>();
        for (Map<String, Set<EnvironmentWrapper>> keyValue : allEnvironmentsByStageGroupMap.values()) {
            for (String key : keyValue.keySet()) {
                envMap.put(key, keyValue.get(key));
            }
        }

        for (String key : envMap.keySet()) {
            for (EnvironmentWrapper ew : envMap.get(key)) {
                if (envToCountMap.get(ew.currentEnvironment.Id) != null) {
                    if (filterType == 'approval') {
                        ew.userStoriesInApproval = envToCountMap.get(ew.currentEnvironment.Id);
                    }
                }
            }
        }
    }

    /**
     * It is used to get all environment in the deployment flow step and group them for stages
     * At the end populating currentEnvironment variable of EnvironmentWrapper
     *
     * @see EnvironmentWrapper
     */
    public void populateFlowGridMap() {
        allEnvironmentsByStageGroupMap.clear();
        allSourceIdsSet = new Set<String>();
        allDestinationIdsSet = new Set<String>();
        nextEnvIdsSet = new Set<String>();
        flowStepEnvMap = new Map<String, Set<String>>();
        flowStepToEnvMap = new Map<String, String>();
        flowStepEnvSizeMap = new Map<String, Integer>();
        if (!(Schema.SObjectType.Deployment_Flow_Step__c.isAccessible() && Schema.SObjectType.Deployment_Flow_Step__c.isQueryable())) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Deployment_Flow_Step__c.getLabel()
                }
            );
            allEnvironmentsByStageGroupMapJson = JSON.serialize(allEnvironmentsByStageGroupMap);
            return;
        }
        List<Deployment_Flow_Step__c> allSteps = recalculatePipelineStructureAndGetConnections(currentPipeline.Id);
        if (ApexPages.hasMessages()) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ ApexPages.getMessages()[0].getDetail() });
            allEnvironmentsByStageGroupMapJson = JSON.serialize(allEnvironmentsByStageGroupMap);
            return;
        }
        List<Deployment_Flow_Step__c> filteredSteps = getFilteredFlowSteps(hiddenEnvironmentIds, allSteps);

        Set<String> environmentIdsSet = new Set<String>();
        for (Deployment_Flow_Step__c dfs : filteredSteps) {
            if (dfs.Source_Environment__c == null || dfs.Destination_Environment__c == null) {
                pipelineMode = 'diagram';
                pageMessagesMap = UIDesignHelper.genericWarningMessage(WARNING, new List<String>{ Label.Source_and_Destination_Environment_Null });
            }
            String sourceEnv = (dfs.Source_Environment__c == null) ? dfs.Branch__c : dfs.Source_Environment__c;
            String destinationEnv = (dfs.Destination_Environment__c == null) ? dfs.Destination_Branch__c : dfs.Destination_Environment__c;
            environmentIdsSet.add(sourceEnv);
            environmentIdsSet.add(destinationEnv);
            allDestinationIdsSet.add(destinationEnv); // flowStepEnvMap.keyset() ??
            allSourceIdsSet.add(sourceEnv); // flowStepToEnvMap.keyset() ???

            if (!flowStepToEnvMap.containsKey(sourceEnv)) {
                flowStepToEnvMap.put(sourceEnv, destinationEnv);
            }

            if (flowStepEnvMap.containsKey(destinationEnv)) {
                flowStepEnvMap.get(destinationEnv).add(sourceEnv);
            } else {
                flowStepEnvMap.put(destinationEnv, new Set<String>{ sourceEnv });
            }
        }

        for (String env : flowStepEnvMap.keySet()) {
            flowStepEnvSizeMap.put(env, flowStepEnvMap.get(env).size());
        }

        if (Schema.SObjectType.Environment__c.isAccessible() && Schema.SObjectType.Environment__c.isQueryable()) {
            allEnvironmentsMap = new Map<String, Environment__c>(
                [
                    SELECT
                        Id,
                        Name,
                        Run_all_tests__c,
                        Type__c,
                        Connection_Behavior__c,
                        Connection_Behavior__r.Promotion_Behavior__c,
                        Connection_Behavior__r.Back_Promotion_Behavior__c,
                        Latest_Deployment__r.Status__c,
                        Latest_Deployment__r.Paused__c,
                        Latest_Deployment_Status__c,
                        (SELECT Id FROM Org_Credentials__r WHERE Default_Credential__c = true OR CreatedById = :UserInfo.getUserId())
                    FROM Environment__c
                    WHERE Id IN :environmentIdsSet
                ]
            );
        } else {
            allEnvironmentsMap = new Map<String, Environment__c>();
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Environment__c.getLabel() }
            );
        }

        Integer stageNumber = 1;

        for (Deployment_Flow_Step__c dfs : filteredSteps) {
            String destinationEnv = (dfs.Destination_Environment__c == null) ? dfs.Destination_Branch__c : dfs.Destination_Environment__c;
            if (!allSourceIdsSet.contains(destinationEnv)) {
                String currentStage = STAGE + stageNumber;
                Environment__c env = allEnvironmentsMap.get(destinationEnv);
                if (env == null) {
                    env = new Environment__c(Name = destinationEnv);
                }
                if (!allEnvironmentsByStageGroupMap.containsKey(currentStage)) {
                    Set<EnvironmentWrapper> envWrapperList = new Set<EnvironmentWrapper>();
                    Boolean isDestinationEnvironment = (env.Id != null && allDestinationIdsSet.contains(env.Id));
                    envWrapperList.add(new EnvironmentWrapper(env, dfs, isDestinationEnvironment));
                    Map<String, Set<EnvironmentWrapper>> innerMap = new Map<String, Set<EnvironmentWrapper>>();
                    innerMap.put('Final', envWrapperList);
                    allEnvironmentsByStageGroupMap.put(currentStage, innerMap);
                    nextEnvIdsSet.add(destinationEnv);
                }
            }
        }

        Boolean isItLastStage = false;
        while (!isItLastStage) {
            isItLastStage = fillAllEnvironmentsByStageMap(filteredSteps, stageNumber + 1, allEnvironmentsMap);
            stageNumber++;
        }

        Integer mewStageNumber = allEnvironmentsByStageGroupMap.size();
        for (String row : allEnvironmentsByStageGroupMap.keySet()) {
            String oldKey = row;
            row = row + '#' + STAGE + mewStageNumber;
            mewStageNumber--;
            allEnvironmentsByStageGroupMap.put(row, allEnvironmentsByStageGroupMap.get(oldKey));
            allEnvironmentsByStageGroupMap.remove(oldKey);
        }

        for (String row : allEnvironmentsByStageGroupMap.keySet()) {
            String oldKey = row;
            row = row.split('#')[1];
            allEnvironmentsByStageGroupMap.put(row, allEnvironmentsByStageGroupMap.get(oldKey));
            allEnvironmentsByStageGroupMap.remove(oldKey);
        }
        allEnvironmentsByStageGroupMapJson = JSON.serialize(allEnvironmentsByStageGroupMap, true);
    }

    /**
     * This method gets a list of filtered pipeline connections based on the current filter settings for hidding
     * Environments.
     *
     * @param environmentsToHide is a set of Environment ids to be hidden from the pipeline diagram.
     * @param flowStepList is a list of all pipeline connections belonging to the current pipeline.
     *
     * @return a list of pipeline connections to show on the pipeline diagram.
     */
    private List<Deployment_Flow_Step__c> getFilteredFlowSteps(Set<Id> environmentsToHide, List<Deployment_Flow_Step__c> flowStepList) {
        if (environmentsToHide.isEmpty()) {
            return flowStepList;
        }

        Map<Id, Deployment_Flow_Step__c> flowStepsBySource = new Map<Id, Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c thisStep : flowStepList) {
            flowStepsBySource.put(thisStep.Source_Environment__c, thisStep);
        }
        Map<Id, Map<Id, Deployment_Flow_Step__c>> sourcesByDestination = new Map<Id, Map<Id, Deployment_Flow_Step__c>>();
        List<Deployment_Flow_Step__c> flowStepsToHide = new List<Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c thisStep : flowStepList) {
            Id source = thisStep.Source_Environment__c;
            Id destination = thisStep.Destination_Environment__c;
            if (!sourcesByDestination.containsKey(destination)) {
                sourcesByDestination.put(destination, new Map<Id, Deployment_Flow_Step__c>());
            }
            sourcesByDestination.get(destination).put(source, thisStep);
            if (environmentsToHide.contains(source)) {
                flowStepsToHide.add(thisStep);
            }
        }

        for (Deployment_Flow_Step__c thisStep : flowStepsToHide) {
            environmentsToHide.addAll(getEnvironmentsToHide(sourcesByDestination, flowStepsBySource, environmentsToHide, thisStep));
        }

        List<Deployment_Flow_Step__c> filteredSteps = new List<Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c thisStep : flowStepList) {
            if (!environmentsToHide.contains(thisStep.Source_Environment__c) && !environmentsToHide.contains(thisStep.Destination_Environment__c)) {
                filteredSteps.add(thisStep);
            }
        }

        return filteredSteps;
    }

    /**
     * This method runs recursively through all the pipeline connection branches were at least one Environment has been
     * hidden.
     *
     * @param sourcesByDestination is a map of all source pipeline connections ordered by their destination Environment.
     * @param flowStepsBySource is a map of all pipeline connections ordered by their source Environment.
     * @param environmentsToHide is a set of Environment ids to be hidden from the pipeline diagram.
     * @param thisStep is the current pipeline connection being evaluated as a candidate to be hidden.
     *
     * @return a set of Environment ids to be hidden, including upper environments if applicable.
     */
    private Set<Id> getEnvironmentsToHide(
        Map<Id, Map<Id, Deployment_Flow_Step__c>> sourcesByDestination,
        Map<Id, Deployment_Flow_Step__c> flowStepsBySource,
        Set<Id> environmentsToHide,
        Deployment_Flow_Step__c thisStep
    ) {
        Map<Id, Deployment_Flow_Step__c> sourceMap = sourcesByDestination.get(thisStep.Destination_Environment__c);
        if (sourceMap == null) {
            return environmentsToHide;
        }
        for (Id source : environmentsToHide) {
            if (environmentsToHide.contains(source) && sourceMap.containsKey(source)) {
                sourceMap.remove(source);
            }
        }

        if (!sourceMap.isEmpty()) {
            return environmentsToHide;
        }

        environmentsToHide.add(thisStep.Destination_Environment__c);
        Deployment_Flow_Step__c parentStep = flowStepsBySource.get(thisStep.Destination_Environment__c);
        if (parentStep == null) {
            return environmentsToHide;
        }
        return getEnvironmentsToHide(sourcesByDestination, flowStepsBySource, environmentsToHide, parentStep);
    }

    /**
     * It is used to populate allEnvironmentsByStage map with correct stage and environment
     * IT is called at populateFlowGridMap method with while loop, so do not query in this method
     *
     * @see populateFlowGridMap
     */
    private Boolean fillAllEnvironmentsByStageMap(
        List<Deployment_Flow_Step__c> dfsList,
        Integer nextStageNumber,
        Map<String, Environment__c> allEnvironmentsMap
    ) {
        Boolean lastStep = false;
        String nextStage = STAGE + nextStageNumber;
        Set<String> tempNextEnvIdsSet = new Set<String>();
        for (String nextEnv : nextEnvIdsSet) {
            for (Deployment_Flow_Step__c dfs : dfsList) {
                String destinationEnv = dfs.Destination_Environment__c == null ? dfs.Destination_Branch__c : dfs.Destination_Environment__c;
                if (nextEnv != destinationEnv) {
                    continue;
                }
                String sourceEnv = dfs.Source_Environment__c == null ? dfs.Branch__c : dfs.Source_Environment__c;
                Environment__c env = allEnvironmentsMap.get(sourceEnv);
                if (env == null) {
                    env = new Environment__c(Name = sourceEnv);
                }
                Boolean isDestinationEnvironment = (env.Id != null && allDestinationIdsSet.contains(env.Id));
                if (!allEnvironmentsByStageGroupMap.containsKey(nextStage)) {
                    Set<EnvironmentWrapper> envWrapperList = new Set<EnvironmentWrapper>();
                    envWrapperList.add(new EnvironmentWrapper(env, dfs, isDestinationEnvironment));
                    Map<String, Set<EnvironmentWrapper>> innerMap = new Map<String, Set<EnvironmentWrapper>>();
                    innerMap.put(destinationEnv, envWrapperList);
                    allEnvironmentsByStageGroupMap.put(nextStage, innerMap);
                    tempNextEnvIdsSet.add(sourceEnv);
                } else {
                    Map<String, Set<EnvironmentWrapper>> innerMap = allEnvironmentsByStageGroupMap.get(nextStage);
                    if (!innerMap.containsKey(destinationEnv)) {
                        innerMap.put(destinationEnv, new Set<EnvironmentWrapper>{ new EnvironmentWrapper(env, dfs, isDestinationEnvironment) });
                    } else {
                        innerMap.get(destinationEnv).add(new EnvironmentWrapper(env, dfs, isDestinationEnvironment));
                    }
                    allEnvironmentsByStageGroupMap.put(nextStage, innerMap);
                    tempNextEnvIdsSet.add(sourceEnv);
                }
            }
        }

        if (!tempNextEnvIdsSet.isEmpty() && !lastStep) {
            nextEnvIdsSet = tempNextEnvIdsSet;
        }

        if (tempNextEnvIdsSet.isEmpty()) {
            lastStep = true;
        }
        return lastStep;
    }

    private static List<Object> preparePromotableUserStoriesQuery(
        String currentPipelineId,
        Set<String> sourceIdsSet,
        UserStoryFilterWrapper selectedFilterWrapper,
        Boolean shouldRunModalQuery,
        String selectedEnvironment
    ) {
        String whereString = 'Promote_Change__c = TRUE AND Status__c != \'Cancelled\' AND Exclude_From_CBM__c = FALSE';
        whereString += ' AND Environment__c IN :sourceIdsSet';
        whereString += ' AND (Project__r.Deployment_Flow__c = :currentPipelineId OR Release__r.Project__r.Deployment_Flow__c = :currentPipelineId)';
        whereString += populateWhereConditionFields(selectedFilterWrapper);

        String selectString = 'COUNT(ID) aheadUserStoryCount, ' + Schema.SObjectType.User_Story__c.fields.Environment__c.name + ' env';

        if (shouldRunModalQuery) {
            whereString += ' AND Environment__c = :selectedEnvironment LIMIT 50000';
            selectString = 'Id, Name, User_Story_Title__c, Environment__c, Has_Apex_Code__c, Org_Credential__c,Status__c, Sprint__c, Release__c, Last_Validation_Deployment_Status__c,Project__c,Release__r.Project__c';
            selectString = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.User_Story__c.fieldSets.CBM_Fields, selectString);
        } else {
            whereString += ' GROUP BY Environment__c';
        }

        String fromString = Schema.SObjectType.User_Story__c.name;
        String mainQuery = String.format('SELECT {0} FROM {1} WHERE {2}', new List<String>{ selectString, fromString, whereString });

        List<Object> promotableUserStoriesResult = new List<Object>();
        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            promotableUserStoriesResult = Database.query(mainQuery);
        }

        return promotableUserStoriesResult;
    }

    private static List<User_Story__c> prepareBackpromotableUserStoriesQuery(
        String currentPipelineId,
        Set<String> destinationIdsSet,
        UserStoryFilterWrapper selectedFilterWrapper
    ) {
        String localPipelineId = currentPipelineId;

        String selectString = 'Id, Name, User_Story_Title__c, Environment__c, Has_Apex_Code__c, Org_Credential__c,Status__c, Sprint__c, Release__c, Last_Validation_Deployment_Status__c,Project__c,Release__r.Project__c';
        String selectInnerString = 'Id, Promotion__r.Source_Environment__c, Promotion__r.Destination_Environment__c, User_Story__r.Environment__c, Promotion__r.Back_Promotion__c, Promotion__r.Status__c';
        String fromInnerString = 'Promoted_User_Stories__r';
        String whereInnerString = 'Status__c != \'Outdated\' AND Promotion__r.Status__c = \'Completed\' AND (Promotion__r.Source_Environment__c IN :destinationIdsSet';
        whereInnerString += ' OR Promotion__r.Destination_Environment__c IN :destinationIdsSet';
        whereInnerString += ' OR User_Story__r.Environment__c IN  :destinationIdsSet)';
        String selectInnerQuery = String.format(
            'SELECT {0} FROM {1} WHERE {2}',
            new List<String>{ selectInnerString, fromInnerString, whereInnerString }
        );
        selectString = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.User_Story__c.fieldSets.CBM_Fields, selectString);
        selectString += ',(' + selectInnerQuery + ')';
        String fromString = Schema.SObjectType.User_Story__c.name;
        String whereString = 'Status__c != \'Cancelled\' AND Exclude_From_CBM__c = FALSE AND Environment__c != NULL';
        whereString += populateWhereConditionFields(selectedFilterWrapper);
        whereString += ' AND (Project__r.Deployment_Flow__c = :localPipelineId OR Release__r.Project__r.Deployment_Flow__c = :localPipelineId)';
        whereString += ' AND Id IN (';

        String selectInnerWhereString = 'User_Story__c';
        String fromInnerwhereString = 'Promoted_User_Story__c';
        String whereInnerWhereString = 'Promotion__r.Status__c = \'Completed\'';
        whereInnerWhereString += ' AND (Promotion__r.Source_Environment__c IN :destinationIdsSet';
        whereInnerWhereString += ' OR Promotion__r.Destination_Environment__c IN :destinationIdsSet';
        whereInnerWhereString += ' OR User_Story__r.Environment__c IN :destinationIdsSet)';
        String selectInnerWhereQuery = String.format(
            'SELECT {0} FROM {1} WHERE {2}',
            new List<String>{ selectInnerWhereString, fromInnerwhereString, whereInnerWhereString }
        );
        whereString += selectInnerWhereQuery + ')';
        whereString += ' ORDER BY Environment__c LIMIT 50000';

        String mainQuery = String.format('SELECT {0} FROM {1} WHERE {2}', new List<String>{ selectString, fromString, whereString });
        List<User_Story__c> behindUserStoryList = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            behindUserStoryList = (List<User_Story__c>) Database.query(mainQuery);
        }
        return behindUserStoryList;
    }

    /**
     * This method is to show a list of promotable / backpromotable user stories in PipelineManagerDialog page when you click in the arrows "-->"(promote), "<--"(backpromote) in PipelineManager page.
     * @param fromId Environment Id from  user stories are promoted
     * @param toId Environment Id to user stories are promoted
     * @param pathType this parameter indicates 'merge' for promote and 'pull' for back promote.
     * @see preparePromotableUserStoriesQuery this method returns a list of promotable user stories. It is used when 'pathType' == 'merge'
     * @see prepareBackpromotableUserStoriesQuery this method returns a list of backpromotable user stories. It is used when 'pathType' == 'pull'
     * @see BranchManagementExtension.OverlayWrapper  this is used to render in PipelineManagerDialog all promotable user stories. This is an overloaded method.
     */
    public void getPromotableBackPromotableUserStoriesList() {
        Map<String, String> paramMap = new Map<String, String>(ApexPages.currentPage().getParameters());
        String fromEnvId = paramMap.get('fromId');
        String toEnvId = paramMap.get('toId');
        String pathType = paramMap.get('pathType');
        selectedEnvironmentString = fromEnvId;
        promotionListWrapper = new List<PromotionWrapper>();

        newOverlay = new BranchManagementExtension.OverlayWrapper(
            fromEnvId,
            toEnvId,
            allEnvironmentsMap.get(fromEnvId).Name,
            allEnvironmentsMap.get(toEnvId).Name,
            allEnvironmentsMap.get(toEnvId).Run_all_tests__c,
            pathType
        );
        List<User_Story__c> userStoriesList = new List<User_Story__c>();
        if (pathType == 'merge') {
            userStoriesList = (List<User_Story__c>) PipelineManagerExtension.preparePromotableUserStoriesQuery(
                currentPipeline.Id,
                allSourceIdsSet,
                selectedFilter,
                true,
                selectedEnvironmentString
            );
        } else {
            List<User_Story__c> backPromotableUserStoriesList = (List<User_Story__c>) PipelineManagerExtension.prepareBackpromotableUserStoriesQuery(
                currentPipeline.Id,
                allDestinationIdsSet,
                selectedFilter
            );
            Map<Id, Set<Id>> usToEnvMap = new Map<Id, Set<Id>>();
            for (User_Story__c us : backPromotableUserStoriesList) {
                usToEnvMap.put(us.Id, new Set<Id>());
                Set<Id> envIds = usToEnvMap.get(us.Id);
                for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                    envIds.addAll(
                        new Set<Id>{
                            pus.Promotion__r.Source_Environment__c,
                            pus.Promotion__r.Destination_Environment__c,
                            pus.User_Story__r.Environment__c
                        }
                    );
                }
                usToEnvMap.put(us.Id, envIds);
            }

            for (User_Story__c us : backPromotableUserStoriesList) {
                Set<Id> envIds = usToEnvMap.get(us.Id);
                String destinationEnvOfGivenEnv = flowStepToEnvMap.containsKey(toEnvId) ? flowStepToEnvMap.get(toEnvId) : '';
                if (!envIds.contains(toEnvId) && String.isNotBlank(destinationEnvOfGivenEnv) && envIds.contains(destinationEnvOfGivenEnv)) {
                    userStoriesList.add(us);
                }
            }
        }
        if (!userStoriesList.isEmpty()) {
            List<BranchManagementExtension.UserStoryWrapper> usList = new List<BranchManagementExtension.UserStoryWrapper>();
            Integer counter = 0;
            for (User_Story__c us : userStoriesList) {
                if (counter == 500) {
                    pageMessagesMap = UIDesignHelper.genericWarningMessage(INFO, new List<String>{ Label.Pipeline_Environment_500_US_Limit_Message });
                    break;
                }
                us.Promoted_User_Stories__r.clear();
                usList.add(new BranchManagementExtension.UserStoryWrapper(us));
                counter++;
            }
            newOverlay.userStories.addAll(usList);
        }
        promotionInfo();
    }

    /**
     * It is used to retrieve all Compliance scan result for selected environment
     *
     * @return
     */
    public List<Compliance_Scan_Result__c> getComplianceScanResults() {
        List<Compliance_Scan_Result__c> compliencaResultsList = new List<Compliance_Scan_Result__c>();
        if (Schema.SObjectType.Compliance_Scan_Result__c.isQueryable() && Schema.SObjectType.Compliance_Scan_Result__c.isAccessible()) {
            String complianceFields = 'SELECT Id';
            complianceFields = PipelineManagerExtension.prepareFieldsetQuery(
                Schema.SObjectType.Compliance_Scan_Result__c.fieldSets.Compliance_Result_Tab,
                complianceFields
            );
            String complianceQuery = complianceFields + ' FROM Compliance_Scan_Result__c WHERE Environment__c = :selectedEnvironmentString';
            compliencaResultsList = Database.query(complianceQuery);
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Compliance_Scan_Result__c.getLabel()
                }
            );
        }
        return compliencaResultsList;
    }

    /**
     * It is used to retrieve all Selenium test group for selected environment
     *
     * @return
     */
    public List<Selenium_Test_Group__c> getSeleniumTestGroups() {
        List<Selenium_Test_Group__c> seleniumResultsList = new List<Selenium_Test_Group__c>();
        if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
            String seleniumFields = 'SELECT Id';
            seleniumFields = PipelineManagerExtension.prepareFieldsetQuery(
                Schema.SObjectType.Selenium_Test_Group__c.fieldSets.Selenium_Results_Tab,
                seleniumFields
            );
            String seleniumQuery = seleniumFields + ' FROM Selenium_Test_Group__c WHERE Environment__c = :selectedEnvironmentString';
            seleniumResultsList = Database.query(seleniumQuery);
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Selenium_Test_Group__c.getLabel()
                }
            );
        }
        return seleniumResultsList;
    }

    /**
     * It is used to get total size of the selenium test grup to show on tab
     *
     * @return
     */
    public Integer getSTGSize() {
        List<Selenium_Test_Group__c> seleniumResultsList = getSeleniumTestGroups();
        return seleniumResultsList.size();
    }

    /**
     * It is used to get total size of the compliance result to show on tab
     *
     * @return
     */
    public Integer getCRSize() {
        List<Compliance_Scan_Result__c> compliencaResultsList = getComplianceScanResults();
        return compliencaResultsList.size();
    }

    @RemoteAction
    public static Map<String, Integer> promotableStoriesForRemoteAction(
        String currentPipelineId,
        String sourceIdsSet,
        String selectedFilterJsonString
    ) {
        Map<String, Integer> envToCountMap = new Map<String, Integer>();
        Set<String> sources = new Set<String>();
        sources.addAll(sourceIdsSet.remove('[').remove(']').remove(' ').split(','));
        for (String envId : sources) {
            envToCountMap.put(envId, 0);
        }

        UserStoryFilterWrapper remoteFilter = (UserStoryFilterWrapper) System.JSON.deserialize(
            selectedFilterJsonString,
            UserStoryFilterWrapper.class
        );
        List<AggregateResult> aheadUserStoryList = (List<AggregateResult>) PipelineManagerExtension.preparePromotableUserStoriesQuery(
            currentPipelineId,
            sources,
            remoteFilter,
            false,
            ''
        );

        for (AggregateResult uStory : aheadUserStoryList) {
            envToCountMap.put((String) uStory.get('env'), (Integer) uStory.get('aheadUserStoryCount'));
        }

        return envToCountMap;
    }

    @RemoteAction
    public static Map<String, Integer> backPromotableStoriesForRemoteAction(
        String currentPipelineId,
        String destinationIdsSet,
        String selectedFilterJsonString,
        String flowStepToEnvMapString,
        String allEnvironmentsToStageString,
        String allEnvironmentsMapString
    ) {
        Map<String, Integer> envToCountMap = new Map<String, Integer>();
        Set<String> destinations = new Set<String>();
        destinations.addAll(destinationIdsSet.remove('[').remove(']').remove(' ').split(','));
        for (String envId : destinations) {
            envToCountMap.put(envId, 0);
        }
        Set<String> allEnvironmentsIds = (Set<String>) JSON.deserialize(allEnvironmentsMapString, Set<String>.class);
        Map<String, String> flowStepToEnvMapRemote = (Map<String, String>) JSON.deserialize(flowStepToEnvMapString, Map<String, String>.class);
        Map<String, Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>>> allEnvironmentsToStageGroupRemote = (Map<String, Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>>>) System.JSON.deserialize(
            allEnvironmentsToStageString,
            Map<String, Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>>>.class
        );
        UserStoryFilterWrapper remoteFilter = (UserStoryFilterWrapper) System.JSON.deserialize(
            selectedFilterJsonString,
            UserStoryFilterWrapper.class
        );
        List<User_Story__c> behindUserStoryList = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            behindUserStoryList = (List<User_Story__c>) PipelineManagerExtension.prepareBackpromotableUserStoriesQuery(
                currentPipelineId,
                destinations,
                remoteFilter
            );
        }
        List<User_Story__c> userStoryList = behindUserStoryList;
        Map<Id, Set<Id>> usToEnvMap = new Map<Id, Set<Id>>();

        for (User_Story__c us : userStoryList) {
            usToEnvMap.put(us.Id, new Set<Id>());
            Set<Id> envIds = usToEnvMap.get(us.Id);
            for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                envIds.addAll(
                    new Set<Id>{
                        pus.Promotion__r.Source_Environment__c,
                        pus.Promotion__r.Destination_Environment__c,
                        pus.User_Story__r.Environment__c
                    }
                );
            }
            usToEnvMap.put(us.Id, envIds);
        }

        for (String enId : allEnvironmentsIds) {
            Set<String> userStoryIds = new Set<String>();
            for (User_Story__c us : userStoryList) {
                Set<Id> envIds = usToEnvMap.get(us.Id);
                String destinationEnvOfGivenEnv = flowStepToEnvMapRemote.containsKey(enId) ? flowStepToEnvMapRemote.get(enId) : '';
                if (!envIds.contains(enId) && String.isNotBlank(destinationEnvOfGivenEnv) && envIds.contains(destinationEnvOfGivenEnv)) {
                    userStoryIds.add(us.Id);
                }
            }
            envToCountMap.put(enId, userStoryIds.size());
        }

        Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>> envMap = new Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>>();
        for (Map<String, Set<PipelineManagerExtension.EnvironmentWrapper>> keyValue : allEnvironmentsToStageGroupRemote.values()) {
            for (String key : keyValue.keySet()) {
                envMap.put(key, keyValue.get(key));
            }
        }

        for (String key : envMap.keySet()) {
            for (PipelineManagerExtension.EnvironmentWrapper ew : envMap.get(key)) {
                Boolean isThereAnyUSBehind = ew.currentEnvironment != null && envToCountMap.get(ew.currentEnvironment.Id) != null;
                ew.userStoriesBehind = isThereAnyUSBehind ? envToCountMap.get(ew.currentEnvironment.Id) : 0;
            }
        }
        return envToCountMap;
    }

    /**
     * It is used to get count of the user stories which are promotable
     * At the end populating userStoriesAhead variable of EnvironmentWrapper
     *
     * @see EnvironmentWrapper
     * @see PipelineComponentHelper
     */
    public void getPromotableUserStoriesCount() {
        List<AggregateResult> aheadUserStoryList = (List<AggregateResult>) PipelineManagerExtension.preparePromotableUserStoriesQuery(
            currentPipeline.Id,
            allSourceIdsSet,
            selectedFilter,
            false,
            ''
        );

        Map<String, Integer> envToCountMap = new Map<String, Integer>();
        for (AggregateResult uStory : aheadUserStoryList) {
            envToCountMap.put((String) uStory.get('env'), (Integer) uStory.get('aheadUserStoryCount'));
        }

        Map<String, Set<EnvironmentWrapper>> envMap = new Map<String, Set<EnvironmentWrapper>>();
        for (Map<String, Set<EnvironmentWrapper>> keyValue : allEnvironmentsByStageGroupMap.values()) {
            for (String key : keyValue.keySet()) {
                envMap.put(key, keyValue.get(key));
            }
        }

        for (String key : envMap.keySet()) {
            for (EnvironmentWrapper ew : envMap.get(key)) {
                Boolean isThereAnyUSAhead = ew.currentEnvironment != null && envToCountMap.get(ew.currentEnvironment.Id) != null;
                ew.userStoriesAhead = isThereAnyUSAhead ? envToCountMap.get(ew.currentEnvironment.Id) : 0;
            }
        }
    }

    /**
     * It is used to get count of the user stories which are back promotable
     * At the end populating userStoriesBehind variable of EnvironmentWrapper
     *
     * @see EnvironmentWrapper
     * @see PipelineComponentHelper
     */
    public void getBackPromotableUserStoriesCount() {
        List<User_Story__c> userStoryList = PipelineManagerExtension.prepareBackpromotableUserStoriesQuery(
            currentPipeline.Id,
            allDestinationIdsSet,
            selectedFilter
        );
        Map<String, Integer> envToCountMap = new Map<String, Integer>();
        Map<Id, Set<Id>> usToEnvMap = new Map<Id, Set<Id>>();

        for (User_Story__c us : userStoryList) {
            usToEnvMap.put(us.Id, new Set<Id>());
            Set<Id> envIds = usToEnvMap.get(us.Id);
            for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                envIds.addAll(
                    new Set<Id>{
                        pus.Promotion__r.Source_Environment__c,
                        pus.Promotion__r.Destination_Environment__c,
                        pus.User_Story__r.Environment__c
                    }
                );
            }
            usToEnvMap.put(us.Id, envIds);
        }

        for (String enId : allEnvironmentsMap.keySet()) {
            Set<String> userStoryIds = new Set<String>();
            for (User_Story__c us : userStoryList) {
                Set<Id> envIds = usToEnvMap.get(us.Id);
                String destinationEnvOfGivenEnv = flowStepToEnvMap.containsKey(enId) ? flowStepToEnvMap.get(enId) : '';
                if (!envIds.contains(enId) && String.isNotBlank(destinationEnvOfGivenEnv) && envIds.contains(destinationEnvOfGivenEnv)) {
                    userStoryIds.add(us.Id);
                }
            }
            envToCountMap.put(enId, userStoryIds.size());
        }

        Map<String, Set<EnvironmentWrapper>> envMap = new Map<String, Set<EnvironmentWrapper>>();
        for (Map<String, Set<EnvironmentWrapper>> keyValue : allEnvironmentsByStageGroupMap.values()) {
            for (String key : keyValue.keySet()) {
                envMap.put(key, keyValue.get(key));
            }
        }

        for (String key : envMap.keySet()) {
            for (EnvironmentWrapper ew : envMap.get(key)) {
                Boolean isThereAnyUSBehind = ew.currentEnvironment != null && envToCountMap.get(ew.currentEnvironment.Id) != null;
                ew.userStoriesBehind = isThereAnyUSBehind ? envToCountMap.get(ew.currentEnvironment.Id) : 0;
            }
        }
    }

    /**
     * This method render Selenium results tab in PipelineManagerDialog page.
     * It is fired through "switchToSelenium" apex:actionFunction.
     * "switchToSelenium" apex:actionFunction belongs to "switchTab(type)" javascript function to switch between tabs in PipelineManagerDialog modal.
     */
    public void showSeleniumResultsTab() {
        showComplianceResults = false;
        showSeleniumResults = true;
        showUserStories = false;
    }

    /**
     * This method render Compliance results tab in PipelineManagerDialog page.
     * It is fired through "switchToCompliance" apex:actionFunction.
     * "switchToCompliance" apex:actionFunction belongs to "switchTab(type)" javascript function to switch between tabs in PipelineManagerDialog modal.
     */
    public void showComplianceResultsTab() {
        showComplianceResults = true;
        showSeleniumResults = false;
        showUserStories = false;
    }

    /**
     * This method render User Stories results tab in PipelineManagerDialog page.
     * It is fired through "switchToUserStory" apex:actionFunction.
     * "switchToUserStory" apex:actionFunction belongs to "switchTab(type)" javascript function to switch between tabs in PipelineManagerDialog modal.
     */
    public void showUserStoriesTab() {
        showComplianceResults = false;
        showSeleniumResults = false;
        showUserStories = true;
    }

    private Boolean startDeployment = false;

    /**
     * This method is fired when you click on "Validate Selections" button in PipelineManagerDialog page.
     * This method creates a promotion and executes "Validation Only" deploy.
     * @see addUserStoriesToPromotion this method adds user stories to Promoted_User_Story__c sobject
     * @see getPendingPromotions this method queries pending promotions created.
     * @see deployPromotionList  this method deploy promotions with checkOnly
     * @return null Page Ref
     */
    public PageReference createPromotionforValidation() {
        UIDesignHelper.clearPageMessages();
        isCheckOnly = true;
        Boolean isChecked = false, hasApexCode = false;
        List<Promotion__c> promoList = new List<Promotion__c>();
        // This map is made by: Key = Release of the US, if there's no Release will be BLANK. In a Map, BLANK as key is accepted.
        // When Blank as key, it means ONE promotion will be created for all selected US without release.
        Map<String, Promotion__c> releasePromoMap = new Map<String, Promotion__c>();
        List<User_Story__c> usList = new List<User_Story__c>();
        for (BranchManagementExtension.UserStoryWrapper usw : newOverlay.userStories) {
            if (usw.isSelected) {
                usList.add(usw.userStory);
                if (!releasePromoMap.containsKey(usw.userStory.Release__c)) {
                    Promotion__c promo = new Promotion__c();
                    promo = newPromo(usw.userStory);
                    releasePromoMap.put(usw.userStory.Release__c, promo);
                }
                if (!isChecked) {
                    isChecked = true;
                }
                if (!hasApexCode && usw.userStory.Has_Apex_Code__c) {
                    hasApexCode = true;
                }
            }
        }

        if (isChecked) {
            try {
                Set<Id> promotionIds = new Set<Id>();
                promoList = releasePromoMap.values();
                Utilities.Secure_DML(promoList, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
                for (Promotion__c prm : promoList) {
                    releasePromoMap.put(prm.Release__c, prm);
                    promotionIds.add(prm.Id);
                }

                for (User_Story__c us : usList) {
                    if (Schema.SObjectType.User_Story__c.fields.Last_Validation_Promotion__c.isUpdateable()) {
                        us.Last_Validation_Promotion__c = releasePromoMap.get(us.Release__c).Id;
                    }
                }
                addUserStoriesToPromotion(usList, releasePromoMap);
                // do not override selected test level, but do not allow NoTestRun when there is Apex code or RunSpecifiedTests when there's no Apex code
                if(hasApexCode && testLevel == LEVEL_NO_TEST_RUN){
                    testLevel = LEVEL_RUN_SPECIFIED_TESTS;
                }
                else if(!hasApexCode && testLevel == LEVEL_RUN_SPECIFIED_TESTS){
                    testLevel = LEVEL_NO_TEST_RUN;
                }
                Utilities.Secure_DML(usList, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                getPendingPromotions(promotionIds);
                startDeployment = true;
                deployPromotionList();
                return null;
            } catch (Exception ex) {
                pageMessagesMap = UIDesignHelper.genericWarningMessage('error', new List<String>{ ex.getMessage() });
                return null;
            }
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(WARNING, new List<String>{ Label.You_Need_to_Select_One });
            return null;
        }
    }

    /**
     * This method creates new promotion object.
     * @param usItem user story to create new promotion
     * @return new Promotion item
     */
    private Promotion__c newPromo(User_Story__c usItem) {
        if (
            !Schema.SObjectType.Promotion__c.fields.Back_Promotion__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Project__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Release__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Source_Org_Credential__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Destination_Environment__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Source_Environment__c.isCreateable() ||
            !Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.isCreateable()
        ) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Promotion__c.getLabel() }
            );
            return null;
        }
        Promotion__c promotion = new Promotion__c();
        promotion.Back_Promotion__c = newOverlay.pathType.toLowerCase() == C_PULL ? true : false;
        promotion.Project__c = usItem.Project__c;
        promotion.Release__c = usItem.Release__c;
        promotion.Destination_Environment__c = newOverlay.toEnvId;
        promotion.Source_Environment__c = usItem.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;

        return promotion;
    }

    /**
     * This method queries Promotion sobject to get pending promontions based on, new promotions created.
     * This method fills "promotionListWrapper" which is the wrapper class shown in PipelineManagerDialog.page
     * @see promotionListWrapper  wrapper used in PipelineManagerDialog.page to show Promotions
     */
    public void getPendingPromotions(Set<Id> promotionIds) {
        if (!Schema.SObjectType.Promotion__c.isQueryable() && !Schema.SObjectType.Promotion__c.isAccessible()) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Promotion__c.getLabel() }
            );
            return;
        }
        if (newOverlay.toEnvRunAllTests) {
            testLevel = 'RunLocalTests';
        }

        Boolean isBackPromotion = newOverlay.pathType.toLowerCase() == C_PULL ? true : false;
        String selectString = 'SELECT Id, Back_Promotion__c, Source_Environment__c, Destination_Environment__c, Connection_Behavior__c';
        selectString = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.Promotion__c.fieldSets.Pipeline_Manager, selectString);
        selectString += ', (SELECT Id, User_Story__c FROM Promoted_User_Stories__r)';
        String promotionQuery = selectString + ' FROM Promotion__c WHERE Id = :promotionIds AND Back_Promotion__c = :isBackPromotion LIMIT 1000';
        List<Promotion__c> promotionList = (List<Promotion__c>) Database.query(promotionQuery);
        for (Promotion__c promo : promotionList) {
            Set<Id> tempUsIds = new Set<Id>();
            for (Promoted_User_Story__c pus : promo.Promoted_User_Stories__r) {
                if (pro2promotedIdsMap.containsKey(promo)) {
                    tempUsIds = pro2promotedIdsMap.get(promo);
                }
                tempUsIds.add(pus.User_Story__c);
            }
            if (!tempUsIds.isEmpty()) {
                pro2promotedIdsMap.put(promo, tempUsIds);
            }
        }
        if (!pro2promotedIdsMap.isEmpty()) {
            Map<Promotion__c, List<User_Story__c>> promotionToUserStoryListMap = GlobalUtilities.getUserStoriesDependencies(pro2promotedIdsMap);
            for (Promotion__c promo : promotionList) {
                if (pro2promotedIdsMap.containsKey(promo) && !promo.Back_Promotion__c) {
                    if (promotionToUserStoryListMap.containsKey(promo) && !promotionToUserStoryListMap.get(promo).isEmpty()) {
                        promotionListWrapper.add(new PromotionWrapper(promo, testLevel, true));
                        dependenciesMap.put(promo.Id, promotionToUserStoryListMap.get(promo));
                    } else {
                        promotionListWrapper.add(new PromotionWrapper(promo, testLevel));
                    }
                } else {
                    promotionListWrapper.add(new PromotionWrapper(promo, testLevel));
                }
            }
        }
    }

    public void assignCurrentPro() {
        currentProId4Dependency = ApexPages.currentPage().getParameters().get('currentProId');
    }

    /**
     * This method is fired when you click on "Promote and Deploy" button from PipelineManagerDialog page.
     * This method only switch "
     * " boolean variable to TRUE and calls "createPromotion()" method. So, this method creates a promotion and deploy the code.
     *
     * @return a call to "createPromotion" method which returns the view page of the created promotion.
     */
    public PageReference createPromotionListAndDeploy() {
        isDeploy = true;
        return createPromotion();
    }

    /**
     * This method is fired when you click on "Promote" button from PipelineManagerDialog page.
     * If isDeploy is not changed in createPromotionAndDeploy() method, only creates the promotion and redirects the user to the record.
     * If isDeploy is switched to TRUE, the method launch a deploy and redirects the user to the record.
     * @see getPendingPromotions
     * @see addUserStoriesToPromotion
     * @return Pageref with the view page of the created promotion.
     */
    public PageReference createPromotion() {
        closeToastMessage();
        promotion = new Promotion__c();
        Set<Id> promotionIds = new Set<Id>();

        // This map is made by: Key = Release of the US, if there's no Release will be BLANK. In a Map, BLANK as key is accepted.
        // When Blank as key, it means ONE promotion will be created for all selected US without release.
        Map<String, Promotion__c> releasePromoMap = new Map<String, Promotion__c>();
        List<Promotion__c> promoList = new List<Promotion__c>();
        List<User_Story__c> selectedUserStories = new List<User_Story__c>();
        for (BranchManagementExtension.UserStoryWrapper usw : newOverlay.userStories) {
            if (usw.isSelected) {
                selectedUserStories.add(usw.userStory);
                // Check if promo related to Release exists. If not, a new promo it's created.
                // ReleasePromoMap has to join user story or release with its promotion.
                if (!releasePromoMap.containsKey(usw.userStory.Release__c)) {
                    Promotion__c promo = new Promotion__c();
                    promo = newPromo(usw.userStory);
                    releasePromoMap.put(usw.userStory.Release__c, promo);
                }
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
                pageMessagesMap = UIDesignHelper.genericWarningMessage(
                    WARNING,
                    new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Promotion__c.getLabel() }
                );
                return null;
            }
            try {
                promoList = releasePromoMap.values();
                Utilities.Secure_DML(promoList, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);

                for (Promotion__c prm : promoList) {
                    releasePromoMap.put(prm.Release__c, prm);
                    promotionIds.add(prm.Id);
                }
                addUserStoriesToPromotion(selectedUserStories, releasePromoMap);
                getPendingPromotions(promotionIds);
                if (isDeploy) {
                    startDeployment = false;
                    deployPromotionList();
                } else {
                    promotionListOnly = true;
                }
            } catch (DmlException dmlEx) {
                pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ dmlEx.getDmlMessage(0) });
            } catch (Exception ex) {
                pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ ex.getMessage() });
            }
            return null;
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(WARNING, new List<String>{ Label.CBM2_at_least1_us });
            return null;
        }
    }

    /**
     * This method adds user stories and promotion to a Promoted User Story List in createPromotion() method.
     * @param usl User Story List to add in Promoted User Story
     * @param p Promotion to be added in Promoted User Story
     */
    private void addUserStoriesToPromotion(List<User_Story__c> usl, Map<String, Promotion__c> releasePromoMap) {
        try {
            List<Promoted_User_Story__c> uspl = new List<Promoted_User_Story__c>();
            if (
                !Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.isCreateable() ||
                !Schema.SObjectType.Promoted_User_Story__c.fields.Name.isCreateable()
            ) {
                UIDesignHelper.genericWarningMessage(
                    WARNING,
                    new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Promotion__c.getLabel() }
                );
                return;
            }
            for (User_Story__c us : usl) {
                Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = releasePromoMap.get(us.Release__c).Id);
                pus.Name = 'Promoted User Story: ' + us.Name;
                uspl.add(pus);
            }
            Utilities.Secure_DML(uspl, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);
        } catch (DmlException dmlEx) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ dmlEx.getDmlMessage(0) });
        } catch (Exception ex) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ ex.getMessage() });
        }
    }

    /**
     * This method it's called to deploy promotions created by: createPromotionforValidation() and createPromotion()
     * @see createPromotion
     * @see createPromotionforValidation
     * @return null Page Reference
     */
    public PageReference deployPromotionList() {
        try {
            if (!Schema.SObjectType.Promotion__c.fields.Status__c.isUpdateable()) {
                pageMessagesMap = UIDesignHelper.genericWarningMessage(
                    WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Promotion__c.fields.Status__c.getLabel()
                    }
                );
                return null;
            }

            if (promIdsSelectedMap == null) {
                promIdsSelectedMap = new Map<String, String>();
            }
            List<Promotion__c> promotionList = new List<Promotion__c>();
            for (PromotionWrapper prom : promotionListWrapper) {
                if (prom.isSelected && prom.promotion.Status__c != COMPLETED) {
                    prom.promotion.Status__c = 'Scheduled';
                    promotionList.add(prom.promotion);
                }
                promIdsSelectedMap.put(prom.promotion.Id, testLevel);
            }
            Utilities.Secure_DML(promotionList, Utilities.DML_Action.UPD, schema.SObjectType.Promotion__c);
            enabledPromotionBackPromotionPoller = true;
            for (Promotion__c promo : promotionList) {
                if (!Test.isRunningTest()) {
                    //Boolean tempStartDeployment = startDeployment || String.isBlank(promo.Connection_Behavior__c);
                    DeployAPI.deployPromotionAsync(
                        promo.Id,
                        'CBM Promotion ' + promo.Name,
                        isCheckOnly,
                        false,
                        testLevel,
                        true,
                        UserInfo.getUserId()
                    );
                }
            }
            startDeployment = false;
            isDeploy = false;
            isCheckOnly = false;
            checkPromotionsStatuses();
        } catch (Exception ex) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ ex.getMessage() });
        }
        return null;
    }

    /**
     * This method checks the status of the promotions once they are send to backend. It is executed every 10 secs by "rebasePromotionPoller"
     * @see rebasePromotionPoller
     * @return null Page Reference
     */
    public PageReference checkPromotionsStatuses() {
        if (!Schema.SObjectType.Promotion__c.isQueryable() || !Schema.SObjectType.Promotion__c.isAccessible()) {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Promotion__c.getLabel() }
            );
            return null;
        }

        Integer completedPromotionCount = 0;
        promotionListWrapper = new List<PromotionWrapper>();
        String promotionSelect = 'SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, Connection_Behavior__c ';
        promotionSelect = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.Promotion__c.fieldSets.Pipeline_Manager, promotionSelect);
        Set<String> promotionIdSet = promIdsSelectedMap.keySet();
        String promotionQuery = promotionSelect + ' FROM Promotion__c WHERE Id IN :promotionIdSet AND Status__c != \'Cancelled\' LIMIT 1000';
        List<Promotion__c> checkPromotionsList = (List<Promotion__c>) Database.query(promotionQuery);
        for (Promotion__c promLst : checkPromotionsList) {
            promotionListWrapper.add(new PromotionWrapper(promLst, promIdsSelectedMap.get(promLst.Id)));
            if (promLst.Status__c != 'Draft' && promLst.Status__c != 'Scheduled' && promLst.Status__c != 'In Progress') {
                completedPromotionCount++;
            }
        }
        if (checkPromotionsList.size() == completedPromotionCount) {
            enabledPromotionBackPromotionPoller = false;
        }
        return null;
    }

    /**
     * This method is fired once you close Promotion list modal or click on "Create new promotion".
     * This method removes from user story list (BranchManagementExtension.UserStoryWrapper) user stories in promotions recently created.
     * This method removes from promotion list (PromotionWrapper) promotions that are being deployed
     */
    public void resetPromotionList() {
        List<BranchManagementExtension.UserStoryWrapper> usRemoveFromList = new List<BranchManagementExtension.UserStoryWrapper>();
        for (BranchManagementExtension.UserStoryWrapper usw : newOverlay.userStories) {
            if (usw.isSelected) {
                usRemoveFromList.add(usw);
            } else {
                usw.isSelected = true;
            }
        }
        if (!usRemoveFromList.isEmpty()) {
            for (BranchManagementExtension.UserStoryWrapper usRemove : usRemoveFromList) {
                Integer i = newOverlay.userStories.indexOf(usRemove);
                newOverlay.userStories.remove(i);
            }
        }

        List<PromotionWrapper> promRemoveFromWrapper = new List<PromotionWrapper>();
        for (PromotionWrapper rmInprogress : promotionListWrapper) {
            if (rmInprogress.promotion.Status__c != 'Draft') {
                promRemoveFromWrapper.add(rmInprogress);
            }
        }
        if (!promRemoveFromWrapper.isEmpty()) {
            for (PromotionWrapper promRemove : promRemoveFromWrapper) {
                Integer i = promotionListWrapper.indexOf(promRemove);
                promotionListWrapper.remove(i);
            }
        }
        enabledPromotionBackPromotionPoller = false;
    }

    /**
     * This methods is an information toast of promotion creation process.
     * Messages notice user that Copado will create one promotion per release and one promotion grouping all user stories without release no matter the project, because origin and destination is same.
     */
    public void promotionInfo() {
        if (newOverlay.userStories.isEmpty()) {
            return;
        }
        String previousRelease;
        List<String> messageList = new List<String>();
        // 500 limit only shows once when page loads.
        Boolean isLimit500 = newOverlay.userStories.size() >= 500 ? true : false;
        if (isLimit500 && pageMessagesMap != null && pageMessagesMap.containsKey(INFO)) {
            messageList.addAll((List<String>) pageMessagesMap.get(INFO));
        }
        for (BranchManagementExtension.UserStoryWrapper usw : newOverlay.userStories) {
            // "previousRelease != null" is used instead of String.isNotBlank because "previousRelease" could be BLANK in case Release is empty.
            if (usw.isSelected && previousRelease != null && previousRelease != usw.userStory.Release__c) {
                messageList.add(Label.Pipeline_One_promotion_per_release);
                pageMessagesMap.putAll(UIDesignHelper.genericWarningMessage(INFO, messageList));
                return;
            }
            previousRelease = usw.isSelected ? usw.userStory.Release__c : previousRelease;
        }
        closeToastMessage();
    }

    /**
     * This method delete pageMessagesMap when user closes Toast.
     */
    public void closeToastMessage() {
        pageMessagesMap = new Map<String, List<Object>>();
    }

    /**
     * This method prepares select string for given object's given fieldset
     * Also this method takes namespace into consideration. This method handles select strings
     * that both have preselected fields or empty. Sample usage;
     * PipelineManagerExtension.prepareFieldsetQuery('User_Story__c', 'CBM_Fields', 'SELECT Id, Name,
     * @param String objectName
     * @param String fieldsetName
     * @param String selectString
     * @return String
     * */
    public static String prepareFieldsetQuery(FieldSet currentFieldSet, String selectString) {
        String fsNamespace = currentFieldSet.getNameSpace();
        fsNamespace = fsNamespace == null ? '' : fsNamespace + '__';
        for (Schema.FieldSetMember fsm : currentFieldSet.getFields()) {
            Boolean alreadyAdded = selectString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(fsNamespace)) ? true : false;
            selectString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(fsNamespace);
        }
        return selectString;
    }

    /**
     * This method recalculates source and destination branches for the current pipeline flow steps
     *
     * @param pipelineId the current pipeline Id
     *
     * @return a list of the current pipeline connections (flow steps)
     */
    public static List<Deployment_Flow_Step__c> recalculatePipelineStructureAndGetConnections(Id pipelineId) {
        List<Deployment_Flow_Step__c> steps = new List<Deployment_Flow_Step__c>();
        if (Schema.SObjectType.Deployment_Flow_Step__c.isAccessible() && Schema.SObjectType.Deployment_Flow_Step__c.isQueryable()) {
            steps = [
                SELECT
                    Id,
                    Name,
                    Deployment_Flow__r.Main_Branch__c,
                    Branch__c,
                    Destination_Branch__c,
                    Source_Environment__c,
                    Source_Environment__r.Name,
                    Destination_Environment__c,
                    Destination_Environment__r.Name,
                    Connection_Behavior__c,
                    Connection_Behavior_Override__c,
                    Connection_Behavior_Override__r.Promotion_Behavior__c,
                    Connection_Behavior_Override__r.Back_Promotion_Behavior__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :pipelineId
                ORDER BY Destination_Environment__c, Source_Environment__c
            ];
        }

        if (steps.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DF_NO_STEP));
            return steps;
        }

        Map<Id, Deployment_Flow_Step__c> connectionBySourceEnvironment = new Map<Id, Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c thisStep : steps) {
            if (thisStep.Source_Environment__c != null) {
                connectionBySourceEnvironment.put(thisStep.Source_Environment__c, thisStep);
            }
        }

        List<Deployment_Flow_Step__c> updateDFS = new List<Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c thisStep : steps) {
            if (
                (String.isBlank(thisStep.Branch__c) && thisStep.Source_Environment__c == null) ||
                (String.isBlank(thisStep.Destination_Branch__c) && thisStep.Destination_Environment__c == null)
            ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Pipeline_Missing_Destination_Environment));
            }

            if (thisStep.Destination_Environment__c != null) {
                String calculatedBranch = connectionBySourceEnvironment.containsKey(thisStep.Destination_Environment__c)
                    ? connectionBySourceEnvironment.get(thisStep.Destination_Environment__c).Branch__c
                    : steps.get(0).Deployment_Flow__r.Main_Branch__c;

                if (thisStep.Destination_Branch__c != calculatedBranch) {
                    thisStep.Destination_Branch__c = calculatedBranch;
                    updateDFS.add(new Deployment_Flow_Step__c(Id = thisStep.Id, Destination_Branch__c = calculatedBranch));
                }
            } else {
                System.debug('recalculatePipelineStructure() connection source is not part of any dests? it is a data error ' + thisStep);
            }
        }

        if (!updateDFS.isEmpty()) {
            try {
                Utilities.Secure_DML(updateDFS, Utilities.DML_Action.UPD, SObjectType.Deployment_Flow_Step__c);
            } catch (DmlException dmlEx) {
                System.debug(dmlEx.getDmlMessage(0));
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        }

        return steps;
    }

    /**
     * This method activates current pipeline when you change from Pipeline Setup (Diagram)
     * to Pipeline Manager and current current pipeline is not active.
     * @return PageReference redirect to PipelineManager
     */
    public PageReference activatePipeline() {
        if (
            Schema.SObjectType.Deployment_Flow__c.fields.Active__c.isAccessible() &&
            Schema.SObjectType.Deployment_Flow__c.fields.Active__c.isUpdateable()
        ) {
            errorMessage = null;
            try {
                Boolean checkAllConnectionsAuthenticated = getCheckPipelineStepsAuthenticated();
                if (checkAllConnectionsAuthenticated) {
                    Deployment_Flow__c dpFlow = new Deployment_Flow__c();
                    dpFlow.Id = currentPipeline.Id;
                    dpFlow.Active__c = true;
                    Utilities.Secure_DML(dpFlow, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
                    PageReference pr = Page.PipelineManager;
                    pr.getParameters().put('id', currentPipeline.Id);
                    pr.getParameters().put('mode', MANAGER);
                    pr.setRedirect(true);
                    return pr;
                } else {
                    errorMessage = Label.Pipeline_Activate_Pipeline_Prompt;
                }
            } catch (Exception ex) {
                errorMessage = UIDesignHelper.catchExceptionMessage(ex);
                pageMessagesMap = UIDesignHelper.genericWarningMessage(ERROR, new List<String>{ ex.getMessage() });
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow__c.label);
            List<ApexPages.Message> msgList = ApexPages.getMessages();
            for (ApexPages.Message am : msgList) {
                errorMessage += am;
            }
        }
        return null;
    }

    /**
     * Clears Error Message in Modal Form
     */
    public void clearErrorMessage() {
        errorMessage = null;
    }

    //PIPELINE DEPLOYMENT MODAL METHODS START ///////////////////////////////////////

    public PageReference openResolveConflictsPage() {
        String promotionId = ApexPages.currentPage().getParameters().get('promId');
        if (String.isBlank(promotionId)) {
            return null;
        }
        PageReference ref = Page.ResolveConflicts;
        ref.getParameters().put('promotionId', promotionId);
        ref.setRedirect(true);
        return ref;
    }
    //PIPELINE DEPLOYMENT MODAL METHODS START ///////////////////////////////////////

    //PIPELINE FILTERS METHODS START ///////////////////////////////////////

    /**
     * It is used to populate where condition for promotable and backpromotable user stories
     *
     * @return String where clause of select query
     */
    private static String populateWhereConditionFields(UserStoryFilterWrapper selectedWrapper) {
        String whereString = '';
        for (FilterCondition thisCondition : selectedWrapper.filterConditions) {
            if (String.isBlank(thisCondition.fieldApiName)) {
                continue;
            }
            Object thisValue;
            if (thisCondition.isReadOnly) {
                AuxiliaryObject__c thisReadOnlyField = selectedWrapper.readOnlyFields.get(thisCondition.fieldApiName);
                if (thisReadOnlyField != null) {
                    String fieldName = thisCondition.getAuxiliaryField();
                    thisValue = thisReadOnlyField.get(fieldName.toLowerCase());
                    if (thisValue == null) {
                        continue;
                    }
                    whereString += getFormattedQueryCondition(thisCondition, thisValue);
                }
            } else {
                String thisField = thisCondition.fieldApiName.toLowerCase();
                thisValue = selectedWrapper.userStoryFilter.get(thisField);
                if (thisValue == null) {
                    continue;
                }
                if (thisCondition.fieldApiName == 'Project__c') {
                    String selectedProjectId = String.escapeSingleQuotes(String.valueOf(thisValue));
                    String SOQLOperator = String.escapeSingleQuotes(thisCondition.getSOQLOperator());
                    whereString += ' AND (Project__c ' + SOQLOperator + ' \'' + selectedProjectId + '\'';
                    whereString += ' OR (Project__c = null AND Release__r.Project__c ' + SOQLOperator + ' \'' + selectedProjectId + '\'))';
                } else {
                    whereString += getFormattedQueryCondition(thisCondition, thisValue);
                }
            }
        }
        return whereString;
    }

    /**
     * Gets the SOQL condition string based on the current FilterCondition instance.
     * @param thisCondition is the target FilterCondition.
     * @param thisValue is the value of the target field.
     * @return a query condition for the target field with its value.
     */
    private static String getFormattedQueryCondition(FilterCondition thisCondition, Object thisValue) {
        String queryCondition = '';
        String formattedValue = getFormattedQueryValue(thisCondition.fieldType, thisValue);
        if (String.isBlank(formattedValue)) {
            return queryCondition;
        }
        String SOQLOperator = String.escapeSingleQuotes(thisCondition.getSOQLOperator());
        String fieldApiName = String.escapeSingleQuotes(thisCondition.fieldApiName);
        String operator = thisCondition.operator;
        queryCondition = ' AND ';
        if (operator == 's') {
            queryCondition += fieldApiName + ' ' + SOQLOperator + ' \'' + formattedValue + '%\'';
        } else if (operator == 'c') {
            queryCondition += fieldApiName + ' ' + SOQLOperator + ' \'%' + formattedValue + '%\'';
        } else if (operator == 'k') {
            queryCondition += '(NOT ' + fieldApiName + ' ' + SOQLOperator + ' \'%' + formattedValue + '%\')';
        } else if (operator == 'u' || operator == 'x') {
            queryCondition += fieldApiName + ' ' + SOQLOperator + ' (\'' + formattedValue + '\')';
        } else {
            String fieldType = thisCondition.fieldType;
            queryCondition += fieldApiName + ' ' + SOQLOperator + ' ';
            if (
                fieldType != DisplayType.DATE.name() &&
                fieldType != DisplayType.DATETIME.name() &&
                fieldType != DisplayType.BOOLEAN.name() &&
                fieldType != DisplayType.INTEGER.name() &&
                fieldType != DisplayType.DOUBLE.name() &&
                fieldType != DisplayType.LONG.name() &&
                fieldType != DisplayType.PERCENT.name()
            ) {
                queryCondition += '\'' + formattedValue + '\'';
            } else {
                queryCondition += formattedValue;
            }
        }
        return queryCondition;
    }

    /**
     * Gets a formatted value string based on the field type and value provided.
     * @param fieldType is the type of the target field.
     * @param thisValue is the value of the target field.
     * @return the formatted value string in proper format.
     */
    private static String getFormattedQueryValue(String fieldType, Object thisValue) {
        String valueString = '';
        if (fieldType == DisplayType.DATE.name()) {
            Date thisDate = Date.valueOf(thisValue);
            valueString += String.valueOf(thisDate);
        } else if (fieldType == DisplayType.DATETIME.name()) {
            Datetime thisDatetime = Datetime.valueOf(thisValue);
            String dateTimeString = thisDatetime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            valueString += dateTimeString;
        } else if (fieldType == DisplayType.BOOLEAN.name()) {
            valueString += Boolean.valueOf(thisValue);
        } else if (fieldType == DisplayType.INTEGER.name()) {
            valueString += Integer.valueOf(thisValue);
        } else if (fieldType == DisplayType.DOUBLE.name() || fieldType == DisplayType.LONG.name() || fieldType == DisplayType.PERCENT.name()) {
            valueString += Double.valueOf(thisValue);
        } else {
            valueString += String.valueOf(thisValue);
        }
        return String.escapeSingleQuotes(valueString);
    }

    /**
     * This method retrieve the user story ids with pending approvals
     * @return Set<Id>
     */
    private Set<Id> retrievePendingApprovals() {
        Set<Id> pendingApprovalIds = new Set<Id>();
        String userStoryTable = namespace + USER_STORY;
        List<ProcessInstanceWorkitem> pendingApprovals = [
            SELECT ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObject.Type = :userStoryTable
        ];
        for (ProcessInstanceWorkitem pi : pendingApprovals) {
            pendingApprovalIds.add(pi.ProcessInstance.TargetObjectId);
        }
        return pendingApprovalIds;
    }

    /**
     * Calculation of pending user stories in all environments
     */
    public void calculateApprovalPendingUserStories() {
        if (allEnvironmentsByStageGroupMap.isEmpty()) {
            return;
        }
        Set<Id> pendingApprovalIds = retrievePendingApprovals();
        List<AggregateResult> storiesInApproval = new List<AggregateResult>();
        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            storiesInApproval = [
                SELECT COUNT(Id) inApprovalCount, Environment__c env
                FROM User_Story__c
                WHERE
                    Id IN :pendingApprovalIds
                    AND Promote_Change__c = false
                    AND Environment__c != null
                    AND Status__c != 'Rejected'
                    AND Status__c != 'Cancelled'
                GROUP BY Environment__c
            ];
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.User_Story__c.getLabel() }
            );
        }
        populateEnvironmentWraperUserStories(storiesInApproval, 'approval');
    }

    /**
     * Shows user stories with pending approvals of selected environment
     * @return List<User_Story__c>
     */
    public List<User_Story__c> getPendingApprovalsByEnvironment() {
        String envId = ApexPages.currentPage().getParameters().get('approvalEnvId');
        if (envId == null) {
            return null;
        }
        Set<Id> pendingApprovalIds = retrievePendingApprovals();
        if (pendingApprovalIds.isEmpty()) {
            return null;
        }
        String query = 'SELECT Id';
        query = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.User_Story__c.fieldSets.Pipeline_Manager_Pending_Approvals, query);
        query += ' FROM User_Story__c WHERE Id IN :pendingApprovalIds AND Promote_Change__c = FALSE AND Environment__c = :envId AND Status__c != \'Rejected\' AND Status__c != \'Cancelled\'';
        List<User_Story__c> storiesInApproval = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            storiesInApproval.addAll((List<User_Story__c>) Database.query(query));
        } else {
            pageMessagesMap = UIDesignHelper.genericWarningMessage(
                WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.User_Story__c.getLabel() }
            );
        }
        return storiesInApproval;
    }

    /**
     * Shows user stories with pending approvals of selected environment
     * @return List<Deployment__c>
     */
    public List<Deployment__c> getLatestDeploymentsByEnvironment() {
        List<Deployment__c> latestDeployments = new List<Deployment__c>();
        String envId = ApexPages.currentPage().getParameters().get('deploymentEnvId');
        if (envId == null) {
            return new List<Deployment__c>();
        }

        if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
            List<Destination_Org__c> destinationOrgsForEnvironment = [
                SELECT Deployment__c
                FROM Destination_Org__c
                WHERE To_Org__r.Environment__c = :envId
                ORDER BY LastModifiedDate DESC
                LIMIT 1000
            ];
            Set<Id> deploymentsToDestination = new Set<Id>();
            for (Destination_Org__c dest : destinationOrgsForEnvironment) {
                deploymentsToDestination.add(dest.Deployment__c);
            }

            String query = 'SELECT Id, Paused__c, Promotion__c, Status__c, Promotion__r.Status__c';
            query = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.Deployment__c.fieldSets.Pipeline_Deployment_Modal, query);
            query += ' FROM Deployment__c WHERE (Promotion__r.Destination_Environment__c = :envId OR Id IN :deploymentsToDestination) AND Status__c != \'Draft\' AND Status__c != \'Validated\' ORDER BY LastModifiedDate DESC LIMIT 500';

            latestDeployments = (List<Deployment__c>) Database.query(query);
        }

        return latestDeployments;
    }

    //PIPELINE FILTERS METHODS END ///////////////////////////////////////

    //PIPELINE HEADER METHODS START ///////////////////////////////////////

    /**
     * This method is used to populate pipeline select list at header component
     *
     * @return SelectOption values
     */
    public List<SelectOption> getAllPipelines() {
        List<SelectOption> options = new List<SelectOption>();
        for (Deployment_Flow__c df : [SELECT Id, Name FROM Deployment_Flow__c WHERE Calculate_Based_on__c = 'User Story' ORDER BY Name LIMIT 1000]) {
            options.add(new SelectOption(df.Id, df.Name));
        }
        return options;
    }

    /**
     * Change mode variable
     * @return PageReference
     * */
    public PageReference changePipelineMode() {
        pipelineMode = pipelineMode == MANAGER ? DIAGRAM : MANAGER;
        return null;
    }

    /**
     * This method updates current pipeline and trigger by on change method of pipeline picklist in the header
     * @return PageReference
     * */
    public PageReference updatePipeline() {
        PageReference pr = Page.PipelineManager;
        pr.setRedirect(true);
        pr.getParameters().put('id', currentPipeline.Id);
        pr.getParameters().put('mode', pipelineMode);
        return pr;
    }

    //PIPELINE HEADER METHODS START ///////////////////////////////////////

    //PIPELINE SETUP METHODS START ///////////////////////////////////////

    /**
     * This method is to be used to add warnings to help customers avoid mistakes
     * @return Void, Should only add ApexPagesmessage
     */
    private void addWarnings() {
        Integer existingSteps = 0;
        //Deployment Flow Step is master-detail to Deployment Flow. No security check needed
        existingSteps = [
            SELECT COUNT()
            FROM Deployment_Flow_Step__c
            WHERE
                Deployment_Flow__r.Active__c = true
                AND (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') // MY: Added to exclude scratch orgs from used CBM licenses
                AND Deployment_Flow__r.Main_Branch__c != null
                AND Deployment_Flow__r.Git_Repository__c != null
                AND Branch__c != null
                AND Id != :currentPipeline.Id
        ];

        LicenseManagerController lmc = new LicenseManagerController();
        if (lmc.cbmBranchesAvailable != null && existingSteps != null && lmc.cbmBranchesAvailable - existingSteps < 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.BRANCH_MGMT_LICENSE_EXCEEDED));
            pageMessagesMap.put('WARNING', new List<Object>{ Label.BRANCH_MGMT_LICENSE_EXCEEDED });
        }

        if (currentPipeline.Git_Repository__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NoGitRepoLinked));
            pageMessagesMap.put('WARNING', new List<Object>{ Label.NoGitRepoLinked });
            return;
        }
        //Warning: There is another Active Deployment Flow linked to the Same Git Repository + Name
        List<Deployment_Flow__c> dFlows = [
            SELECT Name
            FROM Deployment_Flow__c
            WHERE Git_Repository__c = :currentPipeline.Git_Repository__c AND Active__c = true AND Id != :currentPipeline.Id
            LIMIT 1
        ];
        if (!dFlows.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' "' + dFlows[0].Name + '" ' + Label.DF_Linked_To_Same_Repo));
            pageMessagesMap.put('WARNING', new List<Object>{ ' "' + dFlows[0].Name + '" ' + Label.DF_Linked_To_Same_Repo });
        }
    }

    /**
     * Check if all environments (steps) are authenticated. Checks all environments in Pipeline against Org Credentials with environments in current pipeline whose org credential owner is current user or is default credential.
     *
     * @return checks first if there are steps or environments, if none returns FALSE. Then checks if all environments have org credentials, returns true if all envs have credential, if not returs false.
     */
    public Boolean getCheckPipelineStepsAuthenticated() {
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Org__c.label);
            pageMessagesMap.put(
                WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label }
            );
            return false; // Return false is because in "togglePipelineMode" function, condition is "{!CheckPipelineStepsAuthenticated}" so null or false don't fire the message.
        }
        Set<Id> envIds = new Set<Id>();
        Set<Id> orgSet = new Set<Id>();

        for (Deployment_Flow_Step__c dfs : [
            SELECT Id, Source_Environment__c, Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :currentPipeline.Id
        ]) {
            envIds.add(dfs.Source_Environment__c);
            envIds.add(dfs.Destination_Environment__c);
        }

        envIds.remove(null);

        for (Org__c org : [
            SELECT Id, Environment__c
            FROM Org__c
            WHERE Environment__c = :envIds AND (Default_Credential__c = true OR CreatedById = :UserInfo.getUserId())
        ]) {
            orgSet.add(org.Environment__c);
        }

        orgSet.remove(null);
        return (envIds.isEmpty() || orgSet.isEmpty()) ? false : orgSet.containsAll(envIds);
    }

    public PageReference addMessageToPage() {
        String warningMessage = ApexPages.currentPage().getParameters().get('warningMessage');
        pageMessagesMap.put('WARNING', new List<Object>{ warningMessage });
        return null;
    }

    /**
     * This method is used to create new org credential record after clicking on "+" icon next to environment
     * Adding "newOrgCredential" parameters to url to understand it will create a new org credential as first step at orgauthenticationwizard page
     *
     * @return Redirect to the OrgAuthentication wizard page to authenticate and create necessary records
     */
    public PageReference createOrgCredential() {
        //Clear custom setting last action fields to avoid operational conflicts
        Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        setupWizardSettings.Diagram_Last_Action__c = '';
        setupWizardSettings.Wizard_Last_Action__c = '';
        Utilities.Secure_DML(setupWizardSettings, Utilities.DML_Action.UPS, schema.SObjectType.Setup_Wizard_Steps__c);

        String flowStepId = ApexPages.currentPage().getParameters().get('flowStepId');
        String environmentId = ApexPages.currentPage().getParameters().get('envId');
        String environmentName = ApexPages.currentPage().getParameters().get('envName');
        String createNewOrg = ApexPages.currentPage().getParameters().get('newOrg');
        String branch = ApexPages.currentPage().getParameters().get('branch');
        String useStep = ApexPages.currentPage().getParameters().get('useStep');
        String authStage = ApexPages.currentPage().getParameters().get('authStage');
        String diagramAuth = ApexPages.currentPage().getParameters().get('diagramAuth');
        PageReference pReference = Page.OrgAuthenticationWizard;
        if (String.isNotBlank(createNewOrg) && createNewOrg == 'true') {
            pReference.getParameters().put('newOrgCredential', 'true');
        }
        if (String.isNotBlank(createNewOrg) && createNewOrg == 'false') {
            return authenticateEnvironment();
        }
        pReference.getParameters().put('pipelineId', currentPipeline.Id);
        pReference.getParameters().put('flowStepId', flowStepId);
        pReference.getParameters().put('envId', environmentId);
        pReference.getParameters().put('envName', environmentName);
        pReference.getParameters().put('branch', branch);
        pReference.getParameters().put('useStep', useStep);
        pReference.getParameters().put('authStage', authStage);
        pReference.getParameters().put('diagramAuth', diagramAuth);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * This method is used for authenticating org credentials directly from pipeline diagram instead of redirecting to
     * OrgAuthentication component
     * @return PageReference
     * */
    public PageReference authenticateEnvironment() {
        ApexPages.currentPage().getParameters().put('newOrg', 'true');
        ApexPages.currentPage().getParameters().put('authStage', 'true');
        ApexPages.currentPage().getParameters().put('diagramAuth', 'true');
        return createOrgCredential();
    }

    public PageReference createConnectionBehavior() {
        String stepId = ApexPages.currentPage().getParameters().get('pipelineStepId');
        String environmentId = ApexPages.currentPage().getParameters().get('environmentId');
        String sourceName = ApexPages.currentPage().getParameters().get('sourceName');
        String destinationName = ApexPages.currentPage().getParameters().get('destinationName');
        if (String.isBlank(stepId) && String.isBlank(environmentId)) {
            return null;
        }

        String behaviorName = String.isNotBlank(stepId) ? sourceName + ' to ' + destinationName + ' Behavior' : sourceName + ' Behavior';

        Connection_Behavior__c newBehavior = new Connection_Behavior__c(Name = behaviorName);
        Utilities.Secure_DML(newBehavior, Utilities.DML_Action.INS, SObjectType.Connection_Behavior__c);

        if (String.isNotBlank(stepId)) {
            Deployment_Flow_Step__c currentStep = new Deployment_Flow_Step__c(Id = stepId, Connection_Behavior_Override__c = newBehavior.Id);
            Utilities.Secure_DML(currentStep, Utilities.DML_Action.UPD, SObjectType.Deployment_Flow_Step__c);
        } else if (String.isNotBlank(environmentId)) {
            Environment__c currentEnvironment = new Environment__c(Id = environmentId, Connection_Behavior__c = newBehavior.Id);
            Utilities.Secure_DML(currentEnvironment, Utilities.DML_Action.UPD, SObjectType.Environment__c);
        }

        String retUrl = EncodingUtil.urlEncode('/apex/' + namespace + 'PipelineManager?Id=' + currentPipeline.Id + '&mode=' + pipelineMode, 'UTF-8');

        return new PageReference('/' + newBehavior.Id + '?retURL=' + retUrl + '&cancelURL=' + retUrl);
    }

    //PIPELINE SETUP METHODS END ///////////////////////////////////////

    public class EnvironmentWrapper implements Comparable {
        public Environment__c currentEnvironment { get; set; }
        public Deployment_Flow_Step__c currentStep { get; set; }
        public Integer userStoriesAhead { get; set; }
        public Integer userStoriesBehind { get; set; }
        public Integer userStoriesInProgress { get; set; }
        public Integer userStoriesInApproval { get; set; }
        public String environmentIdentifier { get; set; }
        public Boolean needsOauth { get; set; }
        public Boolean isDestinationEnv { get; set; }

        public EnvironmentWrapper(Environment__c currentEnvironment, Deployment_Flow_Step__c currentStep, Boolean isDestinationEnv) {
            if (null != currentStep) {
                if (null != currentStep.Branch__c) {
                    currentStep.Branch__c = currentStep.Branch__c.replaceAll('"', '').replaceAll('\'', '');
                }
                if (null != currentStep.Destination_Branch__c) {
                    currentStep.Destination_Branch__c = currentStep.Destination_Branch__c.replaceAll('"', '').replaceAll('\'', '');
                }
                if (null != currentStep.Destination_Environment__c) {
                    currentStep.Destination_Environment__r.Name = currentStep.Destination_Environment__r.Name.replaceAll('"', '')
                        .replaceAll('\'', '');
                }
                if (null != currentStep.Source_Environment__c) {
                    currentStep.Source_Environment__r.Name = currentStep.Source_Environment__r.Name.replaceAll('"', '').replaceAll('\'', '');
                }
            }
            if (null != currentEnvironment && null != currentEnvironment.Name) {
                currentEnvironment.Name = currentEnvironment.Name.replaceAll('"', '').replaceAll('\'', '');
            }
            this.currentEnvironment = currentEnvironment;
            this.currentStep = currentStep;
            this.userStoriesAhead = 0;
            this.userStoriesBehind = 0;
            this.userStoriesInProgress = 0;
            this.userStoriesInApproval = 0;
            this.environmentIdentifier = (currentEnvironment.Id == null) ? currentStep.Branch__c : currentEnvironment.Id;
            this.needsOauth = (currentEnvironment.Id != null && currentEnvironment.Org_Credentials__r.size() > 0) ? false : true;
            this.isDestinationEnv = isDestinationEnv;
        }
        public Integer compareTo(Object ObjToCompare) {
            String toCompare = String.isNotBlank(currentStep.Destination_Environment__r.Name)
                ? currentStep.Destination_Environment__r.Name
                : currentStep.Destination_Branch__c;
            toCompare = String.isBlank(toCompare) ? '' : toCompare;
            return toCompare.compareTo(((EnvironmentWrapper) ObjToCompare).currentStep.Destination_Environment__r.Name);
        }
    }

    /**
     * This class is used to shown up Promotion List in PipelineManagerDialog.page
     */
    public class PromotionWrapper {
        public Promotion__c promotion { get; set; }
        public String promotionTestLevel { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean hasDependency { get; set; }

        public PromotionWrapper(Promotion__c promo, String tstLev) {
            this.promotion = promo;
            this.isSelected = true;
            this.hasDependency = false;
            this.promotionTestLevel = tstLev;
        }
        public PromotionWrapper(Promotion__c promo, String tstLev, Boolean hasDependencyParam) {
            this.promotion = promo;
            this.hasDependency = hasDependencyParam;
            this.isSelected = true;
            this.promotionTestLevel = tstLev;
        }
    }

    /** Pipeline Filters **/
    public final Integer CONDITION_ENTRY_LIMIT {
        get {
            return 10;
        }
    }
    public List<SelectOption> environmentOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for (Environment__c thisEnvironment : allEnvironmentsMap.values()) {
                if (!allDestinationIdsSet.contains(thisEnvironment.Id) && !hiddenEnvironmentIds.contains(thisEnvironment.Id)) {
                    options.add(new SelectOption(thisEnvironment.Id, thisEnvironment.Name));
                }
            }
            return options;
        }
    }
    public List<SelectOption> environmentsToHide { get; set; }
    private Set<Id> hiddenEnvironmentIds;
    public String selectedConditionIndex { get; set; }
    public UserStoryFilterWrapper selectedFilter { get; set; }
    private Map<Id, UserStoryFilterWrapper> filterMap { get; set; }
    private static final Map<String, Schema.SObjectField> userStoryFieldMap;
    public List<SelectOption> filterOptions {
        get {
            filterMap = new Map<Id, UserStoryFilterWrapper>();
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', Label.ALL));
            try {
                List<Filter__c> filters = [
                    SELECT Name, Share_With__c, Parameters__c
                    FROM Filter__c
                    WHERE ((Share_With__c = 'Me' AND Owner__c = :UserInfo.getUserId()) OR Share_With__c = 'All') AND Pipeline__c = :currentPipeline.Id
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                ];
                for (Filter__c thisFilter : filters) {
                    options.add(new SelectOption(thisFilter.Id, thisFilter.Name));
                    UserStoryFilterWrapper thisFilterWrapper = new UserStoryFilterWrapper(thisFilter);
                    filterMap.put(thisFilter.Id, thisFilterWrapper);
                }
            } catch (Exception e) {
                pageMessagesMap = UIDesignHelper.genericWarningMessage(
                    WARNING,
                    new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Filter__c.getLabel() }
                );
            }

            return options;
        }
    }
    public List<SelectOption> fieldOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            Map<String, SObjectField> userStoryFields = Schema.getGlobalDescribe().get(namespace + USER_STORY).getDescribe().fields.getMap();
            for (SObjectField thisField : userStoryFields.values()) {
                DescribeFieldResult thisDescribe = thisField.getDescribe();
                if (thisDescribe.isAccessible() && thisDescribe.isFilterable() && !thisDescribe.isCalculated()) {
                    if (
                        (thisDescribe.isCustom() && !thisDescribe.isCreateable() && !thisDescribe.isUpdateable()) ||
                        thisDescribe.getName() == IS_DELETED
                    ) {
                        continue;
                    }
                    options.add(new SelectOption(thisDescribe.getName(), thisDescribe.getLabel()));
                }
            }
            List<SelectOption> sortedOptions = new List<SelectOption>();
            sortedOptions.add(new SelectOption('', Label.NONE_SELECTED));
            sortedOptions.addAll(sortSelectOptionsByLabel(options));
            return sortedOptions;
        }
    }

    public Boolean filterSaveError { get; private set; }
    public Boolean popupHasMessages {
        get {
            return ApexPages.hasMessages();
        }
    }

    static {
        userStoryFieldMap = User_Story__c.SObjectType.getDescribe().fields.getMap();
    }

    /**
     * This method was devised for implementing an alternative way sorting of SelectOption values, where options are sorted
     * by their label instead of their value. The sorting algorithm is quick sort.
     * @param options the unsorted option list.
     * @return a list of sorted options.
     */
    private static List<SelectOption> sortSelectOptionsByLabel(List<SelectOption> options) {
        if (options.isEmpty()) {
            return options;
        }

        Integer pivotIndex = options.size() / 2;
        SelectOption pivotValue = options[pivotIndex];
        options.remove(pivotIndex);

        List<SelectOption> lowerOptions = new List<SelectOption>();
        List<SelectOption> higherOptions = new List<SelectOption>();

        for (SelectOption thisOption : options) {
            if (thisOption.getLabel() <= pivotValue.getLabel()) {
                lowerOptions.add(thisOption);
            } else {
                higherOptions.add(thisOption);
            }
        }
        List<SelectOption> sortedOptions = new List<SelectOption>();
        sortedOptions.addAll(sortSelectOptionsByLabel(lowerOptions));
        sortedOptions.add(pivotValue);
        sortedOptions.addAll(sortSelectOptionsByLabel(higherOptions));
        return sortedOptions;
    }

    /**
     * Validates required fields, serializes filter conditions and saves the current filter configuration to the database.
     */
    public void saveFilter() {
        if (requiredFieldsAreEmpty()) {
            return;
        }

        serializeFilterParameters();
        upsertFilter();
    }

    /**
     * Serializes Environment and User Story filter conditions and saves them to the Filter__c.Parameters__c long text
     * field in JSON format.
     */
    private void serializeFilterParameters() {
        FilterJSONWrapper thisJSONWrapper = new FilterJSONWrapper();
        if (!environmentsToHide.isEmpty()) {
            thisJSONWrapper.serializeEnvironmentFilter(environmentsToHide);
        }
        selectedFilter.setFilterConditionValues();
        thisJSONWrapper.serializeUserStoryFilter(selectedFilter.filterConditions);
        selectedFilter.thisFilter.Parameters__c = JSON.serialize(thisJSONWrapper);
    }

    /**
     * Deletes the current filter from the database. Once deleted, applies the generic "All" filter to the page view.
     */
    public void deleteSelectedFilter() {
        filterSaveError = false;
        try {
            Utilities.Secure_DML(selectedFilter.thisFilter, Utilities.DML_Action.DEL, SObjectType.Filter__c);
            selectedFilterId = null;
            applySelectedFilter();
        } catch (DmlException dmlEx) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlEx.getDmlMessage(0)));
            filterSaveError = true;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            filterSaveError = true;
        }
    }

    /**
     * Performs an upsert operation on the current filter record. Once saved to the database, applies the new filter to
     * the page view.
     */
    private void upsertFilter() {
        filterSaveError = false;
        try {
            Boolean updateSelectedFilterId = false;
            if (selectedFilter.thisFilter.Id == null) {
                updateSelectedFilterId = true;
            }
            Utilities.Secure_DML(selectedFilter.thisFilter, Utilities.DML_Action.UPS, SObjectType.Filter__c);
            if (updateSelectedFilterId) {
                selectedFilterId = selectedFilter.thisFilter.Id;
            }
        } catch (DmlException dmlEx) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlEx.getDmlMessage(0)));
            filterSaveError = true;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            filterSaveError = true;
        }
    }

    /**
     * Clones an existing filter and removes its Id and Name values to create a new, prepopulated record.
     */
    public void createFromExistingFilter() {
        selectedFilter.thisFilter = selectedFilter.thisFilter.clone(true, true, true, true);
        selectedFilter.thisFilter.Id = null;
        selectedFilter.thisFilter.Name = 'Copy of ' + selectedFilter.thisFilter.Name;
        selectedFilter.thisFilter.Pipeline__c = currentPipeline.Id;
        selectedFilter.thisFilter.Owner__c = UserInfo.getUserId();
    }

    /**
     * Clears all page messages, checks if required fields are empty and displays an error message to warn the user accordingly.
     * @return a flag indicating if at least one required field is empty.
     */
    private Boolean requiredFieldsAreEmpty() {
        ApexPages.getMessages().clear();
        filterSaveError = false;

        if (String.isBlank(selectedFilter.thisFilter.Name)) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, SObjectType.Filter__c.fields.Name.Label + ' ' + Label.Required_Field)
            );
            filterSaveError = true;
        }
        if (String.isBlank(selectedFilter.thisFilter.Share_With__c)) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, SObjectType.Filter__c.fields.Share_With__c.Label + ' ' + Label.Required_Field)
            );
            filterSaveError = true;
        }

        return filterSaveError;
    }

    /**
     * A wrapper class used for handling filter serialization/deserialization operations.
     */
    public class FilterJSONWrapper {
        public List<FilterCondition> userStoryFilterConditions { get; private set; }
        public List<EnvironmentFilterWrapper> environmentFilters { get; private set; }

        public FilterJSONWrapper() {
            userStoryFilterConditions = new List<FilterCondition>();
            environmentFilters = new List<EnvironmentFilterWrapper>();
        }

        /**
         * Serializes all environments to be hidden in key-value pairs (name-id), in JSON format.
         *
         * @param thisJSONWrapper a JSON wrapper instance for serializing filter configurations.
         */
        public void serializeEnvironmentFilter(List<SelectOption> environmentsToHide) {
            environmentFilters = new List<EnvironmentFilterWrapper>();
            for (SelectOption thisOption : environmentsToHide) {
                EnvironmentFilterWrapper thisFilterWrapper = new EnvironmentFilterWrapper(thisOption.getValue(), thisOption.getLabel());
                environmentFilters.add(thisFilterWrapper);
            }
        }

        /**
         * Serializes all user story filter conditions in JSON format.
         *
         * @param thisJSONWrapper a JSON wrapper instance for serializing filter configurations.
         */
        public void serializeUserStoryFilter(List<FilterCondition> filterConditions) {
            for (FilterCondition thisCondition : filterConditions) {
                if (String.isNotBlank(thisCondition.fieldApiName) && String.isNotBlank(thisCondition.fieldValue)) {
                    userStoryFilterConditions.add(thisCondition);
                }
            }
        }
    }

    /**
     * A wrapper class used for holding User Story-related filters.
     */
    public class UserStoryFilterWrapper {
        public User_Story__c userStoryFilter { get; set; }
        public Filter__c thisFilter { get; private set; }
        public Map<String, AuxiliaryObject__c> readOnlyFields { get; set; }
        public List<FilterCondition> filterConditions { get; private set; }

        public UserStoryFilterWrapper(Filter__c filter) {
            userStoryFilter = new User_Story__c();
            thisFilter = filter;
            readOnlyFields = new Map<String, AuxiliaryObject__c>();
            filterConditions = new List<FilterCondition>();
        }

        /**
         * Sets the filter conditions of a given instance.
         *
         * @param conditions a list of FilterCondition entries.
         */
        public void setFilterConditions(List<FilterCondition> conditions) {
            filterConditions = conditions;
            setUserStoryFilterValues();
        }

        /**
         * Sets the values of the current FilterCondition entries on the User_Story__c object instance fields.
         */
        private void setUserStoryFilterValues() {
            for (FilterCondition thisCondition : filterConditions) {
                if (thisCondition.isReadOnly) {
                    AuxiliaryObject__c thisReadOnlyField = new AuxiliaryObject__c();
                    setFieldValue(
                        thisReadOnlyField,
                        thisCondition.fieldType,
                        thisCondition.getAuxiliaryField().toLowerCase(),
                        thisCondition.fieldValue
                    );
                    readOnlyFields.put(thisCondition.fieldApiName, thisReadOnlyField);
                } else {
                    SObjectField thisField = PipelineManagerExtension.userStoryFieldMap.get(thisCondition.fieldApiName);
                    if (thisField != null) {
                        setFieldValue(
                            userStoryFilter,
                            thisField.getDescribe().getType().name(),
                            thisCondition.fieldApiName.toLowerCase(),
                            thisCondition.fieldValue
                        );
                    }
                }
            }
        }

        /**
         * Puts the value onto the target object's field.
         * @param thisObject is the target object. It can be an instance of User_Story__c or AuxiliaryObject__c (for read-only fields).
         * @param fieldType the DisplayType of the field.
         * @param fieldApiName the API name of the field.
         * @param fieldValue the new value of the target field.
         */
        private void setFieldValue(SObject thisObject, String fieldType, String fieldApiName, String fieldValue) {
            if (fieldType == DisplayType.BOOLEAN.name()) {
                thisObject.put(fieldApiName, Boolean.valueOf(fieldValue));
            } else if (fieldType == DisplayType.DATE.name()) {
                thisObject.put(fieldApiName, Date.valueOf(fieldValue));
            } else if (fieldType == DisplayType.DATETIME.name()) {
                thisObject.put(fieldApiName, DateTime.valueOf(fieldValue));
            } else if (fieldType == DisplayType.INTEGER.name()) {
                thisObject.put(fieldApiName, Integer.valueOf(fieldValue));
            } else if (fieldType == DisplayType.DOUBLE.name() || fieldType == DisplayType.LONG.name() || fieldType == DisplayType.PERCENT.name()) {
                thisObject.put(fieldApiName, Double.valueOf(fieldValue));
            } else {
                thisObject.put(fieldApiName, fieldValue);
            }
        }

        /**
         * Sets the values of the FilterCondition entries on each entry from the User_Story__c object instance fields.
         */
        public void setFilterConditionValues() {
            for (FilterCondition thisCondition : filterConditions) {
                if (thisCondition.isReadOnly) {
                    AuxiliaryObject__c thisReadOnlyField = readOnlyFields.get(thisCondition.fieldApiName);
                    if (thisReadOnlyField != null) {
                        String fieldName = thisCondition.getAuxiliaryField();
                        SObjectField thisField = PipelineManagerExtension.userStoryFieldMap.get(thisCondition.fieldApiName);
                        if (thisField != null) {
                            DisplayType fieldType = thisField.getDescribe().getType();
                            thisCondition.fieldType = fieldType.name();
                            thisCondition.fieldValue = String.valueOf(thisReadOnlyField.get(fieldName.toLowerCase()));
                        }
                    }
                } else {
                    if (getFieldValue(thisCondition) != null) {
                        SObjectField thisField = PipelineManagerExtension.userStoryFieldMap.get(thisCondition.fieldApiName);
                        if (thisField != null) {
                            DisplayType fieldType = thisField.getDescribe().getType();
                            thisCondition.fieldType = fieldType.name();
                            thisCondition.fieldValue = String.valueOf(getFieldValue(thisCondition));
                        }
                    }
                }
            }
        }

        /**
         * Gets the formatted value of a User_Story__c instance field.
         *
         * @param thisCondition the FilterCondition entry for which the value is being retrieved.
         *
         * @return the field value of the User_Story__c instance.
         */
        public Object getFieldValue(FilterCondition thisCondition) {
            if (String.isBlank(thisCondition.fieldApiName)) {
                return null;
            }
            Object fieldValue = userStoryFilter.get(thisCondition.fieldApiName.toLowerCase());
            if (fieldValue == null) {
                return fieldValue;
            } else if (thisCondition.fieldType == DisplayType.BOOLEAN.Name()) {
                return Boolean.valueOf(fieldValue);
            } else {
                return String.valueOf(fieldValue);
            }
        }

        /**
         * Adds a read-only field to the readOnlyFields map to get an auxiliary field instance.
         * @param thisCondition is the target filter condition for which an auxiliary field is needed.
         */
        private void addReadOnlyField(FilterCondition thisCondition) {
            readOnlyFields.put(thisCondition.fieldApiName, new AuxiliaryObject__c());
        }
    }

    /**
     * A wrapper class used for holding Environment-related filters.
     */
    public class EnvironmentFilterWrapper {
        public String environmentId { get; set; }
        public String name { get; set; }

        public EnvironmentFilterWrapper(String thisId, String thisName) {
            environmentId = thisId;
            name = thisName;
        }
    }

    /**
     * A class representation of a User Story filter condition entry.
     */
    public class FilterCondition {
        public String fieldApiName { get; set; }
        public String operator { get; set; }
        public String fieldValue { get; set; }
        public String fieldType { get; private set; }
        public Boolean isReadOnly { get; private set; }

        public FilterCondition(String fieldName) {
            if (String.isNotBlank(fieldName)) {
                fieldApiName = fieldName;
                setFieldTypeAndAccess();
            } else {
                fieldApiName = '';
                isReadOnly = true;
            }
            operator = 'e';
            fieldValue = null;
        }

        /**
         * Sets the type and access properties for the current field.
         */
        public void setFieldTypeAndAccess() {
            setFieldType();
            setFieldAccess();
        }

        /**
         * Sets the field type of the current condition instance.
         */
        private void setFieldType() {
            SObjectField thisField = PipelineManagerExtension.userStoryFieldMap.get(fieldApiName);
            if (thisField != null) {
                DisplayType thisType = thisField.getDescribe().getType();
                fieldType = thisType.name();
            }
        }

        /**
         * Sets the field access level of the current condition instance.
         */
        private void setFieldAccess() {
            SObjectField thisField = PipelineManagerExtension.userStoryFieldMap.get(fieldApiName);
            if (thisField != null) {
                DescribeFieldResult thisDescribe = thisField.getDescribe();
                isReadOnly = !thisDescribe.isCreateable() || !thisDescribe.isUpdateable();
            }
        }

        /**
         * Gets an auxiliary field name for user_Story__c read-only fields.
         *
         * @return the AuxiliaryObject__c field to store the read-only value.
         */
        public String getAuxiliaryField() {
            if (fieldType == 'REFERENCE') {
                return 'User__c';
            } else if (fieldType == 'DATETIME') {
                return 'Date_Time__c';
            } else if (fieldType == 'DOUBLE' || fieldType == 'LONG') {
                return 'Default_Number__c';
            } else if (fieldType == 'ID') {
                return 'Default_Text__c';
            }
            return 'Default_String__c';
        }

        /**
         * Gets a list of available operator options for the current field type.
         * @return a list of possible SOQL operators.
         */
        public List<SelectOption> getOperatorOptions() {
            List<SelectOption> options = new List<SelectOption>();
            if (String.isNotBlank(fieldType)) {
                List<String> availableOperations = OperatorTypeCodes.getOperatorsByDisplayType().get(fieldType);
                if (availableOperations != null) {
                    Map<String, String> operatorMap = OperatorTypeCodes.getOperatorCodes();
                    for (String operationType : availableOperations) {
                        String operatorName = operatorMap.get(operationType);
                        if (String.isNotBlank(operatorName)) {
                            options.add(new SelectOption(operationType, operatorName));
                        }
                    }
                }
            }
            options.sort();
            return options;
        }

        /**
         * Gets the SOQL operator related to the current operator key.
         * @return the SOQL operator in string format.
         */
        public String getSOQLOperator() {
            return OperatorTypeCodes.getOperatorSembols().get(operator);
        }
    }

    /**
     * Initializes a new instance of Filter__c and wraps it in a filter wrapper instance. By default, adds one empty condition
     * entry.
     */
    private void initFilter() {
        hiddenEnvironmentIds = new Set<Id>();
        environmentsToHide = new List<SelectOption>();
        Filter__c thisFilter = new Filter__c();
        thisFilter.Owner__c = UserInfo.getUserId();
        thisFilter.Share_With__c = 'Me';
        thisFilter.Pipeline__c = currentPipeline.Id;
        selectedFilter = new UserStoryFilterWrapper(thisFilter);
        addFilterConditionEntry();
    }

    /**
     * Adds a new User Story filter condition entry to the filter configuration window.
     */
    public void addFilterConditionEntry() {
        FilterCondition thisCondition = new FilterCondition(fieldOptions[0].getValue());
        selectedFilter.filterConditions.add(thisCondition);
    }

    /**
     * Removes an existing User Story filter condition entry from the filter configuration window.
     */
    public void removeFilterConditionEntry() {
        try {
            Integer index = Integer.valueOf(selectedConditionIndex);
            selectedFilter.filterConditions.remove(index);
            if (selectedFilter.filterConditions.isEmpty()) {
                addFilterConditionEntry();
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    /**
     * When a user selects a different field from the field options picklist on a filter condition entry, this method sets
     * the field data type accordingly in order to correctly handle future rendering and query operations.
     */
    public void updateInputType() {
        try {
            Integer index = Integer.valueOf(selectedConditionIndex);
            FilterCondition thisCondition = selectedFilter.filterConditions.get(index);
            thisCondition.setFieldTypeAndAccess();
            if (thisCondition.isReadOnly) {
                selectedFilter.addReadOnlyField(thisCondition);
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    /**
     * When a user selects a custom filter from the list, this method applies that new filter to the page view. If the filter
     * is no longer present in the database, the "All" filter is applied by default.
     */
    public void applySelectedFilter() {
        if (String.isNotBlank(selectedFilterId)) {
            selectedFilter = filterMap.get(selectedFilterId);
            if (selectedFilter == null) {
                initFilter();
            } else {
                environmentsToHide = new List<SelectOption>();
                hiddenEnvironmentIds = new Set<Id>();
                if (String.isNotBlank(selectedFilter.thisFilter.Parameters__c)) {
                    parseAndSetFilterParameters();
                } else {
                    selectedFilter.filterConditions = new List<FilterCondition>();
                    addFilterConditionEntry();
                }
            }
        } else {
            initFilter();
        }
        populateFlowGridMap();
        recalculate();
    }

    /**
     * When the filter is reset, this method parses the new filter parameters and adds them to the filter modal.
     */
    private void parseAndSetFilterParameters() {
        try {
            FilterJSONWrapper thisJSONWrapper = (FilterJSONWrapper) JSON.deserialize(
                selectedFilter.thisFilter.Parameters__c,
                FilterJSONWrapper.class
            );
            if (!thisJSONWrapper.userStoryFilterConditions.isEmpty()) {
                selectedFilter.setFilterConditions(thisJSONWrapper.userStoryFilterConditions);
            } else if (selectedFilter.filterConditions.isEmpty()) {
                addFilterConditionEntry();
            }
            if (!thisJSONWrapper.environmentFilters.isEmpty()) {
                for (EnvironmentFilterWrapper thisWrapper : thisJSONWrapper.environmentFilters) {
                    environmentsToHide.add(new SelectOption(thisWrapper.environmentId, thisWrapper.name));
                    hiddenEnvironmentIds.add(thisWrapper.environmentId);
                }
            }
        } catch (JSONException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    /**
     * UCU : this method will clone the related connection behavior based on the object type it's related with
     */
    public void deepCloneRelatedConnectionBehavior() {
        Id recordId = ApexPages.currentPage().getParameters().get('recordId');
        String objectName = String.valueOf(recordId.getSobjectType()).toLowerCase();
        SObject record = Database.query(
            'SELECT Name, ' +
            (objectName.endsWith('environment__c')
                ? ''
                : namespace +
                    'Source_Environment__r.Name, ' +
                    namespace +
                    'Destination_Environment__r.Name, ' +
                    namespace +
                    'Connection_Behavior_Override__c, ') +
            namespace +
            'Connection_Behavior__c FROM ' +
            objectName +
            ' WHERE Id = :recordId LIMIT 1'
        );
        Id connectionBehaviorId = (Id) record.get(namespace + 'Connection_Behavior__c');
        Connection_Behavior__c cb2Create;
        if (
            Schema.SObjectType.Connection_Behavior__c.isAccessible() &&
            Schema.SObjectType.Connection_Behavior__c.isQueryable() &&
            Schema.SObjectType.Quality_Gate__c.isAccessible() &&
            Schema.SObjectType.Quality_Gate__c.isQueryable()
        ) {
            Connection_Behavior__c connectionBehaviorWithQualityGatesRecord = [
                SELECT
                    Name,
                    Back_Promotion_Behavior__c,
                    Back_Promotion_Schedule__c,
                    Description__c,
                    Promotion_Behavior__c,
                    Promotion_Schedule__c,
                    Promotion_Scheduled_Job_ID__c,
                    Back_Promotion_Scheduled_Job_ID__c,
                    Schedule_Back_Promotion__c,
                    Story_Status_After_Deployment__c,
                    Max_Scheduled_Back_Promotion_Batch_Size__c,
                    Max_Scheduled_Promotion_Batch_Size__c,
                    Schedule_Promotion__c,
                    (
                        SELECT
                            Id,
                            Name,
                            Type__c,
                            Static_Code_Analysis_Settings__c,
                            Connection_Behavior__c,
                            Test_Level__c,
                            Metadata_Group__c,
                            Manual_Task_Owner__c,
                            Compliance_Rule_Group__c
                        FROM Quality_Gates__r
                    )
                FROM Connection_Behavior__c
                WHERE Id = :connectionBehaviorId
                LIMIT 1
            ];

            cb2Create = connectionBehaviorWithQualityGatesRecord.clone(false, false, false, false);
            cb2Create.Name = (cb2Create.Name + ' Clone').left(80);
            Utilities.Secure_DML(cb2Create, Utilities.DML_Action.INS, Schema.SObjectType.Connection_Behavior__c);

            List<Quality_Gate__c> qgList2Insert = new List<Quality_Gate__c>();
            for (Quality_Gate__c qgItem : connectionBehaviorWithQualityGatesRecord.Quality_Gates__r) {
                Quality_Gate__c qg2Create = qgItem.clone(false, false, false, false);
                qg2Create.Connection_Behavior__c = cb2Create.Id;
                qgList2Insert.add(qg2Create);
            }
            Utilities.Secure_DML(qgList2Insert, Utilities.DML_Action.INS, Schema.SObjectType.Quality_Gate__c);

            if (objectName.endsWith('environment__c')) {
                Environment__c env2update = (Environment__c) record;
                env2update.Connection_Behavior__c = cb2Create.Id;
                Utilities.Secure_DML(env2update, Utilities.DML_Action.UPD, Schema.SObjectType.Environment__c);
                pageMessagesMap.put(
                    'info',
                    new List<Object>{ String.format(Label.Has_been_created_successfully, new List<String>{ env2update.Name, cb2Create.Name }) }
                );
            } else {
                Deployment_Flow_Step__c dfs2update = (Deployment_Flow_Step__c) record;
                dfs2update.Connection_Behavior_Override__c = cb2Create.Id;
                Utilities.Secure_DML(dfs2update, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow_Step__c);
                pageMessagesMap.put(
                    'info',
                    new List<Object>{
                        String.format(
                            Label.Has_been_created_successfully_for_connection,
                            new List<String>{ dfs2update.Source_Environment__r.Name, dfs2update.Destination_Environment__r.Name, cb2Create.Name }
                        )
                    }
                );
            }
        }
        populateFlowGridMap();
        calculateApprovalPendingUserStories();
    }

    /**
     * This variable returns a JSON string of serialized Streaming_Setting__mdt records, ordered by PushTopic name.
     * It is used for enabling streaming services for different push topics on the PipelineManager page.
     */
    public String streamingSettingsJSON {
        get {
            Map<String, Streaming_Setting__mdt> settingsMap = new Map<String, Streaming_Setting__mdt>();
            List<Streaming_Setting__mdt> streamingSettings = [SELECT Channel_Name__c, Enabled__c, Timeout__c FROM Streaming_Setting__mdt];
            for (Streaming_Setting__mdt thisSetting : streamingSettings) {
                settingsMap.put(thisSetting.Channel_Name__c, thisSetting);
            }
            return JSON.serialize(settingsMap);
        }
    }
}