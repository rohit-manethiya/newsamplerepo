/**
 * Handler class to create deployment records for CCD forward promotions(Automated, Scheduled)
 *
 */
public with sharing class UserStoryChangeEventTriggerHandler {
    //CONSTANT variables
    public static final String PROMOTED_USER_STORY = 'Promoted User Story: ';
    public static final String CANCELLED = 'Cancelled';
    public static final String COMPLETED = 'Completed';
    public static final String PROCESSED = 'Processed';
    private static final String PLUS_SIGN = '+';
    public static final String SOQL_WHERE = ' WHERE ';
    public static final String USER_STORY_QUERY = 'SELECT Id FROM User_Story__c';
    private static List<String> STATUSES_NEEDS_TO_REPEAT = new List<String>{ 'Completed with errors', 'Validation failed', 'Cancelled', 'Validated' };
    //current User api key
    public static String apiKey = DeployAPI.getUserAPIKey();

    //NON-CONSTANT variables
    public static Boolean continueFlag = false;
    //related connection behavior type
    public static String connectionBehavior = 'Automated';
    //Manual step required + deployment Flow Id + Org Credential to Promotion record Map
    private static Map<String, Promotion__c> uniqueIdentifierPromotionMap = new Map<String, Promotion__c>();
    //deployment flow Id + environment Map to Connection Behavior Map
    private static Map<String, Id> deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap = new Map<String, Id>();
    //User Story to Promotion Map
    private static Map<User_Story__c, Promotion__c> userStoryPromotionMap = new Map<User_Story__c, Promotion__c>();
    //Promotion record Id to User Story Names map
    private static Map<Id, List<String>> promotionIdUsNamesMap = new Map<Id, List<String>>();
    //User Story Id to Deployment Flow Id Map
    private static Map<Id, Id> usIdDepFlowId = new Map<Id, Id>();
    //environment Id set
    private static Set<Id> envIds = new Set<Id>();
    //promotion Id set
    private static Set<Id> proIds = new Set<Id>();
    //serialized JSON list to pass Queueable Class for deployment record creation via backend call
    private static List<String> queueableClassCalloutJsonList = new List<String>();
    //deploy promotion webhook url to use on Orchestrator(container) deployment
    private static String deployPromotionsUrl =
        Settings.server_url +
        '/json/v1/webhook/promotions/promotionId/process?checkOnly=check_only&testLevel=test_level&api_key=user_api_key&deploymentName=deployment_name';
    private static Map<Id, Connection_Behavior__c> connectionBehaviorsByEnvironmentIds = new Map<Id, Connection_Behavior__c>();
    private static Set<String> filteredUserStoryIds = new Set<String>();

    /**
     * @param usIds UserStory Ids to process for CCD
     * @param commitUserId committer id to send via callout to backend for auth purpose
     */
    public static String ccdCheckConnectionBehaviorAndPromote(
        Set<String> usIds,
        String commitUserId,
        Boolean sentFromOtherTrigger,
        String existingDeploymentId
    ) {
        List<User_Story__c> userStories = populateVariables(usIds);
        if (!envIds.isEmpty()) {
            Map<Id, Connection_Behavior__c> connectionBehaviors = returnConnectionBehaviorMap(envIds);
            queryUserStoriesDefinedAtConnectionBehaviorPromotionCriteria(connectionBehaviors.values());
            Map<String, Promoted_User_Story__c> promotedUserStoriesByUniqueKey = checkDuplication(
                [
                    SELECT
                        Id,
                        User_Story__c,
                        User_Story__r.Release__c,
                        User_Story__r.Project__c,
                        User_Story__r.Org_Credential__c,
                        User_Story__r.Environment__c,
                        Promotion__c,
                        Promotion__r.Status__c,
                        Promotion__r.Project__c,
                        Promotion__r.Release__c,
                        Promotion__r.Source_Org_Credential__c
                    FROM Promoted_User_Story__c
                    WHERE
                        User_Story__c IN :usIds
                        AND Status__c != 'Outdated'
                        AND Promotion__r.Back_Promotion__c = false
                        AND Promotion__r.Status__c NOT IN :STATUSES_NEEDS_TO_REPEAT
                ],
                true
            );
            for (User_Story__c usItem : userStories) {
                Id projectOrReleaseId = null != usItem.Project__c ? usItem.Project__c : usItem.Release__c;

                Boolean connectionBehaviorHasCriteria = connectionBehaviorHasPromotionCriteria(usItem, connectionBehaviors);
                Boolean connectionBehaviorWithCriteria =
                    connectionBehaviorHasCriteria &&
                    !filteredUserStoryIds.isEmpty() &&
                    filteredUserStoryIds.contains(usItem.Id) &&
                    hasConnectionBehavior(usItem, connectionBehaviors) &&
                    !promotedUserStoriesByUniqueKey.containsKey(String.valueOf(usItem.Id) + projectOrReleaseId + usItem.Org_Credential__c);
                Boolean connectionBehaviorWithoutCriteria =
                    !connectionBehaviorHasCriteria &&
                    hasConnectionBehavior(usItem, connectionBehaviors) &&
                    !promotedUserStoriesByUniqueKey.containsKey(String.valueOf(usItem.Id) + projectOrReleaseId + usItem.Org_Credential__c);
                if (connectionBehaviorWithCriteria || connectionBehaviorWithoutCriteria) {
                    preparePromotions(
                        usItem,
                        usIdDepFlowId.get(usItem.Id),
                        commitUserId,
                        deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.get(usIdDepFlowId.get(usItem.Id) + PLUS_SIGN + usItem.Environment__c)
                    );
                }
            }
            if (continueFlag) {
                LicenseHelper.automatedProcessTriggeringUserId = commitUserId;

                insertPromotionAndUserStoryPromotionRecords();
                return createDeploymentRecords(commitUserId, sentFromOtherTrigger, existingDeploymentId);
            } else {
                return existingDeploymentId;
            }
        } else {
            return existingDeploymentId;
        }
    }

    private static void queryUserStoriesDefinedAtConnectionBehaviorPromotionCriteria(List<Connection_Behavior__c> connectionBehaviors) {
        String whereClause = '';
        Integer counter = 1;
        for (Connection_Behavior__c connectionBehavior : connectionBehaviors) {
            if (String.isNotBlank(connectionBehavior.Promotion_Criteria__c)) {
                if (counter == 1) {
                    whereClause += SOQL_WHERE;
                }
                whereClause += counter > 1
                    ? ' OR (' + connectionBehavior.Promotion_Criteria__c + ')'
                    : '(' + connectionBehavior.Promotion_Criteria__c + ')';
                counter++;
            }
        }
        for (User_Story__c userStory : Database.query(USER_STORY_QUERY + whereClause)) {
            filteredUserStoryIds.add(userStory.Id);
        }
    }

    /**
     * @param promotedUserStories
     * @return duplication map for promoted User Stories based on unique id(user story id + project id + org credential id)
     * @see ccdCheckConnectionBehaviorAndPromote method
     */
    public static Map<String, Promoted_User_Story__c> checkDuplication(List<Promoted_User_Story__c> promotedUserStories, Boolean isOrgCredential) {
        Map<String, Promoted_User_Story__c> promotedUserStoriesByUniqueKey = new Map<String, Promoted_User_Story__c>();
        for (Promoted_User_Story__c pusItem : promotedUserStories) {
            Boolean isDuplicatePromotion =
                (isOrgCredential ? pusItem.User_Story__r.Org_Credential__c == pusItem.Promotion__r.Source_Org_Credential__c : true) &&
                ((null != pusItem.Promotion__r.Project__c && pusItem.User_Story__r.Project__c == pusItem.Promotion__r.Project__c) ||
                (null != pusItem.Promotion__r.Release__c &&
                pusItem.User_Story__r.Release__c == pusItem.Promotion__r.Release__c));
            if (isDuplicatePromotion) {
                id projectOrReleaseId = null != pusItem.User_Story__r.Project__c
                    ? pusItem.User_Story__r.Project__c
                    : pusItem.User_Story__r.Release__c;
                promotedUserStoriesByUniqueKey.put(
                    String.valueOf(pusItem.User_Story__c) +
                    projectOrReleaseId +
                    (isOrgCredential ? pusItem.User_Story__r.Org_Credential__c : pusItem.Promotion__r.Destination_Environment__c),
                    pusItem
                );
            }
        }
        return promotedUserStoriesByUniqueKey;
    }

    /**
     * populates needed variables via User story and promoted user story to use later on
     *
     * @param usIds user story ids
     */
    private static List<User_Story__c> populateVariables(Set<String> usIds) {
        List<User_Story__c> userStories = [
            SELECT
                Id,
                Environment__c,
                Project__c,
                Project__r.Deployment_Flow__c,
                Release__c,
                Release__r.Project__c,
                Release__r.Project__r.Deployment_Flow__c,
                Name,
                Manual_Step_Required__c,
                Org_Credential__c,
                (SELECT Id, Promotion__c, Promotion__r.Status__c, Promotion__r.Connection_Behavior__c FROM Promoted_User_Stories__r)
            FROM User_Story__c
            WHERE Id IN :usIds AND Exclude_From_CBM__c = false AND Status__c != :CANCELLED
        ];
        //define each user stories' deployment flow and current Environmentw
        for (User_Story__c us : userStories) {
            envIds.add(us.Environment__c);
            if (null != us.Project__c) {
                usIdDepFlowId.put(us.Id, us.Project__r.Deployment_Flow__c);
            } else if (null != us.Release__c && null != us.Release__r.Project__c) {
                usIdDepFlowId.put(us.Id, us.Release__r.Project__r.Deployment_Flow__c);
            }
            for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                if (pus.Promotion__r.Status__c == COMPLETED && pus.Promotion__r.Connection_Behavior__c != PROCESSED) {
                    proIds.add(pus.Promotion__c);
                }
            }
        }
        return userStories;
    }

    /**
     * already processed promotion List to mark as processed to not to iterate for back promotions on scheduled logic
     *
     * @param proIds
     */
    private static void sendPromotionListToMarkAsProcessed(Set<Id> proIds) {
        if (!proIds.isEmpty()) {
            PromotionChangeEventTriggerHandler.markPromotionsAsProcessed([SELECT Connection_Behavior__c FROM Promotion__c WHERE Id IN :proIds]);
        }
    }

    /**
     * populates connection behavior map for specified environment Id set
     *
     * @param envIds environment Ids
     *
     * @return connectionBehaviorMap
     */
    private static Map<Id, Connection_Behavior__c> returnConnectionBehaviorMap(Set<Id> envIds) {
        Map<Id, Id> environmentIdsByConnectionBehaviorIds = new Map<Id, Id>();
        for (Deployment_Flow_Step__c deploymentFlowStepRecord : [
            SELECT Id, Connection_Behavior__c, Source_Environment__c, Deployment_Flow__c, Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Source_Environment__c IN :envIds AND Deployment_Flow__r.Active__c = true
        ]) {
            deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.put(
                deploymentFlowStepRecord.Deployment_Flow__c +
                PLUS_SIGN +
                deploymentFlowStepRecord.Source_Environment__c,
                deploymentFlowStepRecord.Connection_Behavior__c
            );
            if (deploymentFlowStepRecord.Connection_Behavior__c != null) {
                environmentIdsByConnectionBehaviorIds.put(
                    deploymentFlowStepRecord.Connection_Behavior__c,
                    deploymentFlowStepRecord.Destination_Environment__c
                );
            }
        }
        Map<Id, Connection_Behavior__c> connectionBehaviors = new Map<Id, Connection_Behavior__c>(
            [
                SELECT
                    Id,
                    Name,
                    Back_Promotion_Behavior__c,
                    Promotion_Behavior__c,
                    Promotion_Criteria__c,
                    Execute_promotions_in_parallel__c,
                    Execute_back_promotions_in_parallel__c
                FROM Connection_Behavior__c
                WHERE Id IN :deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.values() AND Promotion_Behavior__c = :connectionBehavior
            ]
        );
        for (Connection_Behavior__c connectionBehavior : connectionBehaviors.values()) {
            Id environmentId = environmentIdsByConnectionBehaviorIds.containsKey(connectionBehavior.Id)
                ? environmentIdsByConnectionBehaviorIds.get(connectionBehavior.Id)
                : null;
            if (environmentId != null) {
                connectionBehaviorsByEnvironmentIds.put(environmentId, connectionBehavior);
            }
        }
        return connectionBehaviors;
    }
    /**
     * checks if there is any connection behavior matches for current User Story
     *
     * @param usItem User Story record
     * @param connectionBehaviorMap
     *
     * @return decision
     */
    private static Boolean hasConnectionBehavior(User_Story__c usItem, Map<Id, Connection_Behavior__c> connectionBehaviors) {
        return usIdDepFlowId.containsKey(usItem.Id) &&
            deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.containsKey(usIdDepFlowId.get(usItem.Id) + PLUS_SIGN + usItem.Environment__c) &&
            connectionBehaviors.containsKey(
                deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.get(usIdDepFlowId.get(usItem.Id) + PLUS_SIGN + usItem.Environment__c)
            );
    }

    private static Boolean connectionBehaviorHasPromotionCriteria(User_Story__c usItem, Map<Id, Connection_Behavior__c> connectionBehaviors) {
        Id connectionBehaviorId = deploymentFlowIdWithEnvironmentToConnectionBehaviorIdMap.get(
            usIdDepFlowId.get(usItem.Id) +
            PLUS_SIGN +
            usItem.Environment__c
        );
        Boolean userStoryEnvironmentHasConnectionBehavior = connectionBehaviors.containsKey(connectionBehaviorId);
        String connectionBehaviorPromotionCriteria = userStoryEnvironmentHasConnectionBehavior
            ? connectionBehaviors.get(connectionBehaviorId).Promotion_Criteria__c
            : '';
        return userStoryEnvironmentHasConnectionBehavior && String.isNotBlank(connectionBehaviorPromotionCriteria);
    }

    /**
     * @param usItem currently Processed UserStory record
     * @param flowId current deployment Flow Id
     * @param ownerIdParam commit user Id
     * @param connectionBehaviorId connection behavior id either tied to related deploymentFlow step or Environment
     */
    public static void preparePromotions(User_Story__c usItem, Id flowId, String ownerIdParam, String connectionBehaviorId) {
        continueFlag = true;
        if (uniqueIdentifierPromotionMap.containsKey(usItem.Manual_Step_Required__c + PLUS_SIGN + flowId + PLUS_SIGN + usItem.Org_Credential__c)) {
            userStoryPromotionMap.put(
                usItem,
                uniqueIdentifierPromotionMap.get(usItem.Manual_Step_Required__c + PLUS_SIGN + flowId + PLUS_SIGN + usItem.Org_Credential__c)
            );
        } else {
            Promotion__c promotion = new Promotion__c();
            promotion.Project__c = usItem.Project__c;
            promotion.Connection_Behavior__c = connectionBehaviorId;
            promotion.Release__c = usItem.Release__c;
            promotion.OwnerId = ownerIdParam;
            promotion.Source_Org_Credential__c = usItem.Org_Credential__c;
            promotion.Source_Environment__c = usItem.Environment__c;
            promotion.Send_Deployment_Complete_email__c = true;
            uniqueIdentifierPromotionMap.put(usItem.Manual_Step_Required__c + PLUS_SIGN + flowId + PLUS_SIGN + usItem.Org_Credential__c, promotion);

            userStoryPromotionMap.put(usItem, promotion);
        }
    }
    /**
     * inserts promotion and  User Story Promotion records for deployment record creation
     */
    private static void insertPromotionAndUserStoryPromotionRecords() {
        Utilities.Secure_DML(uniqueIdentifierPromotionMap.values(), Utilities.DML_Action.INS, Schema.SObjectType.Promotion__c);

        List<Promoted_User_Story__c> pusToInsert = new List<Promoted_User_Story__c>();
        for (User_Story__c us : userStoryPromotionMap.keySet()) {
            String promotionId = userStoryPromotionMap.get(us).Id;
            Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = promotionId);
            pus.Name = PROMOTED_USER_STORY + us.Name;

            List<String> usNames = new List<String>();
            if (promotionIdUsNamesMap.containsKey(promotionId)) {
                usNames = promotionIdUsNamesMap.get(promotionId);
            }
            usNames.add(us.Name);
            promotionIdUsNamesMap.put(promotionId, usNames);

            pusToInsert.add(pus);
        }
        Utilities.Secure_DML(pusToInsert, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);
    }

    /**
     * callout to backend for Deployment records creation
     */
    private static String createDeploymentRecords(String commitUserId, Boolean sentFromOtherTrigger, String existingDeploymentId) {
        if (connectionBehavior == 'Automated') {
            for (Id proId : promotionIdUsNamesMap.keySet()) {
                queueableClassCalloutJsonList.add(
                    JSON.serialize(
                        new CCD_BothPromotionQueueable.calloutWrapper(
                            proId,
                            String.join(promotionIdUsNamesMap.get(proId), ','),
                            false,
                            false,
                            '',
                            true,
                            (String.isBlank(commitUserId) ? null : commitUserId)
                        )
                    )
                );
            }
            ID jobID = System.enqueueJob(new CCD_BothPromotionQueueable(queueableClassCalloutJsonList));
        } else {
            existingDeploymentId = addStepsToDeployment(existingDeploymentId, promotionIdUsNamesMap.keySet(), true);
        }
        return existingDeploymentId;
    }
    /**
     * adds needed steps(steps as promotions) to the orchestrator deployment
     *
     * @param existingDeploymentId not null if a deployment exist
     * @param proIds promotion ids to create steps for
     *
     * @return container deployment id
     */
    public static String addStepsToDeployment(String existingDeploymentId, Set<Id> proIds, Boolean isDeployment) {
        Integer orderCounter = 0;
        List<Step__c> promotionAsStepList = new List<Step__c>();
        List<Promotion__c> proList = [SELECT Id, Name, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id IN :proIds];
        if (String.isBlank(existingDeploymentId)) {
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Advanced (multi-step)')
                .getRecordTypeId();
            Deployment__c containerDeployment = new Deployment__c(
                Name = 'CCD Scheduled ' + (isDeployment ? 'Deployment ' : 'Back-Promotion') + ' Behavior ' + System.now(),
                From_Org__c = proList[0].Source_Org_Credential__c,
                RecordTypeId = advancedDeploymentRecordTypeId
            );
            Utilities.Secure_DML(containerDeployment, Utilities.DML_Action.INS, Schema.SObjectType.Deployment__c);
            Destination_Org__c toOrg = new Destination_Org__c(
                To_Org__c = proList[0].Destination_Org_Credential__c,
                Deployment__c = containerDeployment.Id
            );
            Utilities.Secure_DML(toOrg, Utilities.DML_Action.INS, Schema.SObjectType.Destination_Org__c);
            existingDeploymentId = containerDeployment.Id;
        } else {
            orderCounter = Integer.valueOf(
                [SELECT Order__c FROM Step__c WHERE Deployment__c = :existingDeploymentId ORDER BY Order__c DESC LIMIT 1]
                .Order__c
            );
        }

        List<Destination_Org__c> destinationOrgs = [
            SELECT To_Org__r.Environment__c
            FROM Destination_Org__c
            WHERE Deployment__c = :existingDeploymentId
            LIMIT 1
        ];
        Id destinationEnvironmentId = !destinationOrgs.isEmpty() ? destinationOrgs[0].To_Org__r.Environment__c : null;
        Boolean executePromotionsInParallel = connectionBehaviorsByEnvironmentIds.containsKey(destinationEnvironmentId)
            ? isDeployment
                    ? connectionBehaviorsByEnvironmentIds.get(destinationEnvironmentId).Execute_promotions_in_parallel__c
                    : connectionBehaviorsByEnvironmentIds.get(destinationEnvironmentId).Execute_back_promotions_in_parallel__c
            : false;
        for (Promotion__c proItem : proList) {
            promotionAsStepList.add(
                AttachmentTriggerHelper.prepareStep(
                    proItem.Name,
                    ++orderCounter,
                    existingDeploymentId,
                    JSON.serialize(
                        new AttachmentTriggerHelper.urlCalloutWrapper(
                            deployPromotionsUrl.replace('user_api_key', apiKey)
                                .replace('promotionId', proItem.Id)
                                .replace('deployment_name', proItem.Name)
                                .replace('test_level', '')
                                .replace('check_only', 'false'),
                            executePromotionsInParallel
                        )
                    ),
                    'URL Callout'
                )
            );
        }
        Utilities.Secure_DML(promotionAsStepList, Utilities.DML_Action.INS, Schema.SObjectType.Step__c);
        return existingDeploymentId;
    }
}