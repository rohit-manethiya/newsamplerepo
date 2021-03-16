/**
 * Created by COPADO\ucan on 9/16/19.
 */

public with sharing class PromotionChangeEventTriggerHandler {
    //CONSTANT variables
    private static final String BACK_PROMOTED_USER_STORY = 'Back Promoted User Story: ';
    //in use for Promotion query for Status field
    private static final String COMPLETED = 'Completed';
    private static final String SOQL_WHERE = ' WHERE ';
    private static final String USER_STORY_QUERY = 'SELECT Id FROM User_Story__c';

    //NON-CONSTANT variables
    public static Boolean alreadyProcesses = false;
    //connection Behavior type to be process by the code
    public static String connectionBehavior = 'Automated';
    //User Id to be used on backend call
    public static String commitUserId;
    //Successfully completed promotion Ids
    private static Set<Id> completedProIds = new Set<Id>();
    //promotion destionation environment Ids of Successfully Completed Promotions
    private static Set<Id> destinationsEnvIds = new Set<Id>();
    //rebaseMap for behind User Story calculation
    private static Map<Id, List<Promoted_User_Story__c>> rebaseMap = new Map<Id, List<Promoted_User_Story__c>>();
    //User Story Id to promotion record Map
    private static Map<Id, Promotion__c> usIdOriginalPromotionMap = new Map<Id, Promotion__c>();
    //Environment Id to Promotion record Map
    private static Map<Id, Promotion__c> envIdPromotionMap = new Map<Id, Promotion__c>();
    //Environment Id + Project Id / Release Id to Promotion record Map
    private static Map<String, Promotion__c> envIdPlusProjectOrReleaseToPromotionMap = new Map<String, Promotion__c>();
    //User Story Ids to send to related handler for Forward Promotion calculation
    private static Set<String> userStoryIdsForForwardPromotionSet = new Set<String>();
    //deployment flow Ids set
    private static Set<Id> deploymentFlowIds = new Set<Id>();
    //connection Behavior Ids set
    private static Set<String> connectionBehaviorIds = new Set<String>();
    //Environment Id to Connection Behavior Id Map
    private static Map<Id, Id> envIdConnectionBehaviorMap = new Map<Id, Id>();
    //User Story Id to User Story Name Map
    private static Map<Id, String> usIdUsNameMap = new Map<Id, String>();
    //Promotion Id to all related User Story names Map
    private static Map<Id, List<String>> promotionIdUsNamesMap = new Map<Id, List<String>>();
    //serialized JSON list to pass Queueable Class for deployment record creation via backend call
    public static List<String> queueableClassCalloutJsonList = new List<String>();
    //to be inserted promotion records
    private static Set<Promotion__c> promotionsToInsert = new Set<Promotion__c>();
    //to be inserted user story promotion records
    private static Set<Promoted_User_Story__c> promotedUserStoriesToInsert = new Set<Promoted_User_Story__c>();
    //to prevent duplicate pus creation for back promotion
    private static Map<String, Promoted_User_Story__c> promotedUserStoriesByUniqueKey;
    //statuses that will not be populated on promotedUserStoriesByUniqueKey map
    private static List<String> STATUSES_NEEDS_TO_REPEAT = new List<String>{ 'Completed with errors', 'Validation failed', 'Cancelled', 'Validated' };
    private static Map<Id, Connection_Behavior__c> connectionBehaviorByIds;
    private static Set<String> filteredUserStoryIds = new Set<String>();

    /**
     * checks for potential CCD back-promotions via iterating completedPromotions list
     *
     * @param completedPromotions Successfully completed Promotion records
     */
    public static String ccdCheckForAutomatedBackPromotions(List<Promotion__c> completedPromotions, String existingDeploymentId) {
        if (alreadyProcesses) {
            return null;
        }
        for (Promotion__c proItem : completedPromotions) {
            completedProIds.add(proItem.Id);
            destinationsEnvIds.add(proItem.Destination_Environment__c);
        }
        if (!completedProIds.isEmpty()) {
            alreadyProcesses = true;
            queryAllConnectionBehavior();
            queryUserStoriesDefinedAtConnectionBehaviorBackPromotionCriteria(connectionBehaviorByIds.values());
            List<Promoted_User_Story__c> rebaseUserStories = returnPusList(getUsIds(completedProIds));
            if (!rebaseUserStories.isEmpty()) {
                List<Deployment_Flow_Step__c> deploymentFlowStepRecordList = populateVariables(rebaseUserStories);
                existingDeploymentId = sendForForwardPromotion(existingDeploymentId);
                if (!connectionBehaviorIds.isEmpty()) {
                    Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> rebaseCalculationMap = prepareBackPromotionRecords(
                        deploymentFlowStepRecordList
                    );
                    Savepoint spItem = insertBackPromotionRecords();
                    //roll back is inside this method
                    createUserStoryPromotionRecords(rebaseCalculationMap, spItem);
                    existingDeploymentId = createDeploymentRecords(existingDeploymentId);
                }
            }
            return existingDeploymentId;
        } else {
            return null;
        }
    }

    private static void queryAllConnectionBehavior() {
        connectionBehaviorByIds = new Map<Id, Connection_Behavior__c>(
            [SELECT Id, Back_Promotion_Behavior__c, Back_Promotion_Criteria__c FROM Connection_Behavior__c LIMIT 1000]
        );
    }

    private static void queryUserStoriesDefinedAtConnectionBehaviorBackPromotionCriteria(List<Connection_Behavior__c> connectionBehaviors) {
        String whereClause = '';
        Integer counter = 1;
        for (Connection_Behavior__c connectionBehavior : connectionBehaviors) {
            if (String.isNotBlank(connectionBehavior.Back_Promotion_Criteria__c)) {
                if (counter == 1) {
                    whereClause += SOQL_WHERE;
                }
                whereClause += counter > 1
                    ? ' OR (' + connectionBehavior.Back_Promotion_Criteria__c + ')'
                    : '(' + connectionBehavior.Back_Promotion_Criteria__c + ')';
                counter++;
            }
        }
        for (User_Story__c userStory : Database.query(USER_STORY_QUERY + whereClause)) {
            filteredUserStoryIds.add(userStory.Id);
        }
    }

    private static Set<Id> getUsIds(Set<Id> proIds) {
        for (Promoted_User_Story__c promotedUserStoryRecord : [
            SELECT Id, User_Story__c
            FROM Promoted_User_Story__c
            WHERE User_Story__r.Exclude_From_Cbm__c = false AND Promotion__c IN :proIds
        ]) {
            proIds.add(promotedUserStoryRecord.User_Story__c);
        }
        return proIds;
    }

    /**
     * gets User Stories which needs back promotion calculation via Promotion Ids
     * then returns all the Promoted User Stories belongs to them
     *
     * @return
     */
    public static List<Promoted_User_Story__c> returnPusList(Set<Id> usIds) {
        promotedUserStoriesByUniqueKey = UserStoryChangeEventTriggerHandler.checkDuplication(
            [
                SELECT
                    Id,
                    User_Story__c,
                    User_Story__r.Project__c,
                    User_Story__r.Release__c,
                    User_Story__r.Environment__c,
                    User_Story__r.Org_Credential__c,
                    Promotion__c,
                    Promotion__r.Status__c,
                    Promotion__r.Project__c,
                    Promotion__r.Release__c,
                    Promotion__r.Destination_Environment__c,
                    Promotion__r.Source_Org_Credential__c
                FROM Promoted_User_Story__c
                WHERE
                    User_Story__c IN :usIds
                    AND Status__c != 'Outdated'
                    AND Promotion__r.Back_Promotion__c = true
                    AND Promotion__r.Status__c NOT IN :STATUSES_NEEDS_TO_REPEAT
            ],
            false
        );
        return [
            SELECT
                Id,
                User_Story__c,
                User_Story__r.Name,
                Promotion__c,
                Promotion__r.Back_Promotion__c,
                Promotion__r.Destination_Environment__c,
                Promotion__r.Source_Environment__c,
                Promotion__r.Release__c,
                Promotion__r.Release__r.Project__r.Deployment_Flow__c,
                Promotion__r.Project__c,
                Promotion__r.Project__r.Deployment_Flow__c
            FROM Promoted_User_Story__c
            WHERE
                User_Story__c IN :usIds
                AND Status__c != 'Outdated'
                AND (Promotion__r.Destination_Environment__c IN :destinationsEnvIds
                OR (Promotion__r.Source_Environment__c IN :destinationsEnvIds
                AND Promotion__r.Back_Promotion__c = true))
                AND Promotion__r.Status__c = :COMPLETED
            ORDER BY User_Story__c
        ];
    }

    /**
     * populate needed Maps and Lists for to be created promotion records calculation
     *
     * @param rebaseUserStories already completed User Story Promotions List
     *
     * @return Deployment Flow Steps for rebaseCalculationList
     */
    private static List<Deployment_Flow_Step__c> populateVariables(List<Promoted_User_Story__c> rebaseUserStories) {
        Id promotionProjectDFId = null;
        Id releasePromotionProjectDFId = null;
        for (Promoted_User_Story__c promotedUserStoriesRecord : rebaseUserStories) {
            if (!promotedUserStoriesRecord.Promotion__r.Back_Promotion__c) {
                userStoryIdsForForwardPromotionSet.add(promotedUserStoriesRecord.User_Story__c);
            }
            usIdOriginalPromotionMap.put(promotedUserStoriesRecord.User_Story__c, promotedUserStoriesRecord.Promotion__r);
            usIdUsNameMap.put(promotedUserStoriesRecord.User_Story__c, promotedUserStoriesRecord.User_Story__r.Name);
            promotionProjectDFId = promotedUserStoriesRecord.Promotion__r.Project__c != null &&
                promotedUserStoriesRecord.Promotion__r.Project__r.Deployment_Flow__c != null
                ? promotedUserStoriesRecord.Promotion__r.Project__r.Deployment_Flow__c
                : null;
            releasePromotionProjectDFId = promotedUserStoriesRecord.Promotion__r.Release__c != null &&
                promotedUserStoriesRecord.Promotion__r.Release__r.Project__c != null &&
                promotedUserStoriesRecord.Promotion__r.Release__r.Project__r.Deployment_Flow__c != null
                ? promotedUserStoriesRecord.Promotion__r.Release__r.Project__r.Deployment_Flow__c
                : null;
            if (promotionProjectDFId != null) {
                deploymentFlowIds.add(promotionProjectDFId);
            } else if (releasePromotionProjectDFId != null) {
                deploymentFlowIds.add(releasePromotionProjectDFId);
            }

            List<Promoted_User_Story__c> tempPromotedUserStories = new List<Promoted_User_Story__c>();
            if (rebaseMap.containsKey(promotedUserStoriesRecord.User_Story__c)) {
                tempPromotedUserStories = rebaseMap.get(promotedUserStoriesRecord.User_Story__c);
            }
            tempPromotedUserStories.add(promotedUserStoriesRecord);
            rebaseMap.put(promotedUserStoriesRecord.User_Story__c, tempPromotedUserStories);
        }
        for (Deployment_Flow_Step__c dfs : [
            SELECT Id, Name, Connection_Behavior__c, Source_Environment__c, Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c IN :deploymentFlowIds AND Destination_Environment__c IN :destinationsEnvIds AND Connection_Behavior__c != ''
        ]) {
            connectionBehaviorIds.add(dfs.Connection_Behavior__c);
        }
        List<Connection_Behavior__c> connectionBehaviorList = new List<Connection_Behavior__c>(
            [
                SELECT Id, Back_Promotion_Behavior__c
                FROM Connection_Behavior__c
                WHERE Id IN :connectionBehaviorIds AND Back_Promotion_Behavior__c = :connectionBehavior
            ]
        );
        connectionBehaviorIds.clear();
        for (Connection_Behavior__c cbItem : connectionBehaviorList) {
            connectionBehaviorIds.add(((String) cbItem.Id).substring(0, 15));
        }
        List<Deployment_Flow_Step__c> deploymentFlowLists = [
            SELECT Id, Name, Connection_Behavior__c, Source_Environment__c, Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE
                Deployment_Flow__c IN :deploymentFlowIds
                AND Destination_Environment__c IN :destinationsEnvIds
                AND Connection_Behavior__c IN :connectionBehaviorIds
        ];
        for (Deployment_Flow_Step__c dfs : deploymentFlowLists) {
            envIdConnectionBehaviorMap.put(dfs.Source_Environment__c, dfs.Connection_Behavior__c);
        }

        return deploymentFlowLists;
    }
    /**
     * User Story Ids to be controlled for any possible forward promotion
     *
     * @return String deploymentId
     */
    public static String sendForForwardPromotion(String existingDeploymentId) {
        if (!userStoryIdsForForwardPromotionSet.isEmpty()) {
            return UserStoryChangeEventTriggerHandler.ccdCheckConnectionBehaviorAndPromote(
                userStoryIdsForForwardPromotionSet,
                commitUserId,
                true,
                existingDeploymentId
            );
        }
        return existingDeploymentId;
    }
    /**
     * creation of Back promotion records after User Story Promotions calculation via GlobalUtilities class
     *
     * @return rebaseCalculationMap for createUserStoryPromotionRecords method
     */
    private static Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> prepareBackPromotionRecords(
        List<Deployment_Flow_Step__c> deploymentFlowStepRecordList
    ) {
        LicenseHelper.automatedProcessTriggeringUserId = commitUserId;
        //rebaseCalculationList - User Stories to back promote calculation
        Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> rebaseCalculationMap = GlobalUtilities.calculateUserStoriesBehind(
            rebaseMap,
            deploymentFlowStepRecordList
        );
        for (Id rid : rebaseCalculationMap.keySet()) {
            for (GlobalUtilities.RebaseSelectionsWrapper rsw : rebaseCalculationMap.get(rid).values()) {
                Id projectId = usIdOriginalPromotionMap.get(rsw.rebaseUs).Project__c;
                Id releaseId = usIdOriginalPromotionMap.get(rsw.rebaseUs).Release__c;
                Id projectOrReleaseId = String.valueOf(null != projectId ? projectId : releaseId);
                String uniqueKey = rsw.rebaseEnv;
                Boolean connectionBehaviorHasBackPromotionCriteria = environmentHasConnectionBehaviorCriteria(
                    envIdConnectionBehaviorMap.get(rsw.rebaseEnv)
                );
                Boolean userStoryMatchBackPromotoionCriteria =
                    connectionBehaviorHasBackPromotionCriteria && filteredUserStoryIds.contains(rsw.rebaseUs);
                if (userStoryMatchBackPromotoionCriteria || !connectionBehaviorHasBackPromotionCriteria) {
                    if (
                        rsw.isAvailable &&
                        !envIdPlusProjectOrReleaseToPromotionMap.containsKey(uniqueKey) &&
                        !promotedUserStoriesByUniqueKey.containsKey(String.valueOf(rsw.rebaseUs) + projectOrReleaseId + rsw.rebaseEnv)
                    ) {
                        Promotion__c promotion = new Promotion__c();
                        promotion.Project__c = projectId;
                        promotion.Back_Promotion__c = true;
                        promotion.OwnerId = commitUserId;
                        promotion.Connection_Behavior__c = envIdConnectionBehaviorMap.get(rsw.rebaseEnv);
                        promotion.Release__c = releaseId;
                        promotion.Destination_Environment__c = rsw.rebaseEnv;
                        promotion.Send_Deployment_Complete_email__c = true;
                        promotionsToInsert.add(promotion);
                        envIdPlusProjectOrReleaseToPromotionMap.put(rsw.rebaseEnv, null);
                    }
                }
            }
        }
        return rebaseCalculationMap;
    }

    private static Boolean environmentHasConnectionBehaviorCriteria(String connectionBehaviorId) {
        return connectionBehaviorByIds.containsKey(connectionBehaviorId) &&
            connectionBehaviorByIds.get(connectionBehaviorId).Back_Promotion_Criteria__c != null;
    }

    /**
     * inserts promotion records and populates promotion related maps via successfully created rows
     * to create "User Story Promotion" records
     *
     * @return Savepoint for possible rollback
     */
    private static Savepoint insertBackPromotionRecords() {
        Savepoint spItem = Database.setSavepoint();
        Database.saveResult[] saveResultList;
        try {
            //!IMPORTANT: removed secureDML to not to block User stories w/o exception because of the ones with exception
            saveResultList = Database.insert(new List<Promotion__c>(promotionsToInsert), false);
        } catch (Exception ex) {
            System.debug('ex==> ' + ex.getMessage());
        }

        for (Database.SaveResult sr : saveResultList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted Promotion. Promotion ID: ' + sr.getId());
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(
                        'The following error has occurred.\n\n' +
                        err.getStatusCode() +
                        ': ' +
                        err.getMessage() +
                        '\n\nPromotion fields that affected by this error : ' +
                        err.getFields()
                    );
                }
            }
        }
        // Reset values in map, previously used only for keyset duplication check having null values
        envIdPlusProjectOrReleaseToPromotionMap.clear();
        for (Promotion__c pro : new List<Promotion__c>(promotionsToInsert)) {
            //continue for successful promotions only
            if (null != pro.Id) {
                envIdPromotionMap.put(pro.Destination_Environment__c, pro);
                envIdPlusProjectOrReleaseToPromotionMap.put(pro.Destination_Environment__c, pro);
            } else {
                // Skip silently, this should never happen and
                // it is actually not expected, but we log it just in case
                System.debug('### Promotion was not inserted successfully, please review Databse.Error logs above.');
            }
        }
        return spItem;
    }
    /**
     * creates User Story Promotions via Successfully created promotion records
     *
     * @param rebaseCalculationList available lower environments to back deploy
     * @param spItem SavePoint for possible DML fail
     */
    private static void createUserStoryPromotionRecords(
        Map<Id, Map<Id, GlobalUtilities.RebaseSelectionsWrapper>> rebaseCalculationList,
        Savepoint spItem
    ) {
        for (Id rid : rebaseCalculationList.keySet()) {
            for (GlobalUtilities.RebaseSelectionsWrapper rsw : rebaseCalculationList.get(rid).values()) {
                Boolean connectionBehaviorHasBackPromotionCriteria = environmentHasConnectionBehaviorCriteria(
                    envIdConnectionBehaviorMap.get(rsw.rebaseEnv)
                );
                Boolean userStoryMatchBackPromotionCriteria =
                    connectionBehaviorHasBackPromotionCriteria && filteredUserStoryIds.contains(rsw.rebaseUs);
                if (userStoryMatchBackPromotionCriteria || !connectionBehaviorHasBackPromotionCriteria) {
                    if (rsw.isAvailable && envIdPlusProjectOrReleaseToPromotionMap.containsKey(rsw.rebaseEnv)) {
                        String promotionId = envIdPlusProjectOrReleaseToPromotionMap.get(rsw.rebaseEnv).Id;
                        Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = rsw.rebaseUs, Promotion__c = promotionId);
                        pus.Name = BACK_PROMOTED_USER_STORY + usIdUsNameMap.get(rsw.rebaseUs);
                        promotedUserStoriesToInsert.add(pus);

                        List<String> usNames = new List<String>();
                        if (promotionIdUsNamesMap.containsKey(promotionId)) {
                            usNames = promotionIdUsNamesMap.get(promotionId);
                        }
                        usNames.add(usIdUsNameMap.get(rsw.rebaseUs));
                        promotionIdUsNamesMap.put(promotionId, usNames);
                    }
                }
            }
        }
        try {
            Utilities.Secure_DML(
                new List<Promoted_User_Story__c>(promotedUserStoriesToInsert),
                Utilities.DML_Action.INS,
                Schema.SObjectType.Promoted_User_Story__c
            );
        } catch (Exception ex) {
            System.debug('ex==> ' + ex.getMessage());
            Database.rollback(spItem);
        }
    }
    /**
     * callout to backend for Deployment records creation
     */
    public static String createDeploymentRecords(String existingDeploymentId) {
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
            if (!promotionIdUsNamesMap.isEmpty()) {
                existingDeploymentId = UserStoryChangeEventTriggerHandler.addStepsToDeployment(
                    existingDeploymentId,
                    promotionIdUsNamesMap.keySet(),
                    false
                );
            }
        }
        return existingDeploymentId;
    }
    /**
     * Mark promotions as processed to prevent duplication in the future
     *
     * @param completedPromotions
     */
    public static void markPromotionsAsProcessed(List<Promotion__c> completedPromotions) {
        for (Promotion__c proItem : completedPromotions) {
            proItem.Connection_Behavior__c = 'Processed';
        }
        LicenseHelper.automatedProcessTriggeringUserId = commitUserId;
        Utilities.Secure_DML(completedPromotions, Utilities.DML_Action.UPD, Schema.SObjectType.Promotion__c);
    }
}