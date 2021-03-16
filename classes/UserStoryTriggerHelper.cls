public without sharing class UserStoryTriggerHelper {
    private static Map<Id, Sprint__c> mapSprint;
    private static Map<Id, Org__c> orgMap;
    private static Map<Id, User_Story__c> usUpdateMap = new Map<Id, User_Story__c>();
    private static Boolean usFlagToStopRecursiveUpdate = false;
    private static Map<Id, Decimal> maxUserStoriesOrderBySprint = new Map<Id, Decimal>();
    private static Map<Id, Project__c> projectsById;
    private static Map<Id, Deployment_Flow__c> deploymentFlowsById;
    private static Map<Id, List<Promoted_User_Story__c>> promotedUserStoriesByUserStoryId = new Map<Id, List<Promoted_User_Story__c>>();
    private static Set<Id> metadataIdsToEnable = new Set<Id>();
    private static Set<Id> metadataIdsToDisable = new Set<Id>();
    private static Set<Promotion__c> promotions = new Set<Promotion__c>();
    private static Map<Id, Decimal> lastOrderNumberMap = new Map<Id, Decimal>();
    private static Map<String, List<User_Story__c>> storiesByPromotion = new Map<String, List<User_Story__c>>();
    public static List<User_Story__c> promoteAndDeployedStories = new List<User_Story__c>();
    public static Map<Id, Environment__c> environmentMap;
    public static Map<Id, Release__c> releaseMap;
    public static Set<Promoted_User_Story__c> promotedUserStoriesToUpdateAsOutdated = new Set<Promoted_User_Story__c>();

    public static void prepareMaps() {
        if (Trigger.isDelete)
            return;

        Set<Id> setSprintIds = new Set<Id>();
        Set<Id> oids = new Set<Id>();
        Set<Id> envids = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> releaseIds = new Set<Id>();
        for (SObject so : Trigger.new) {
            User_Story__c us = (User_Story__c) so;
            setSprintIds.add(us.Sprint__c);
            oids.add(us.org_credential__c);
            if (us.Environment__c != null) {
                envIds.add(us.Environment__c);
            }
            if (us.Project__c != null) {
                projectIds.add(us.Project__c);
            }
            if (us.Release__c != null) {
                releaseIds.add(us.Release__c);
            }
        }

        orgMap = new Map<Id, Org__c>([SELECT Id, OwnerId, Environment__c FROM Org__c WHERE Id IN :oids]);
        for (Org__c org : orgMap.values()) {
            envIds.add(org.Environment__c);
        }
        if (!envIds.isEmpty()) {
            environmentMap = new Map<Id, Environment__c>([SELECT Id, Minimum_Apex_Test_Coverage__c FROM Environment__c WHERE Id IN :envIds]);
        }
        if (!releaseIds.isEmpty()) {
            releaseMap = new Map<Id, Release__c>(
                [SELECT Id, Base_Branch__c, Project__c, Project__r.Deployment_Flow__c FROM Release__c WHERE Id IN :releaseIds]
            );
        }
        if (!setSprintIds.isEmpty()) {
            mapSprint = new Map<Id, Sprint__c>([SELECT Id, Project__c FROM Sprint__c WHERE Id IN :setSprintIds]);
        }
        for (AggregateResult maxUserStoryOrderGroupBySprint : [
            SELECT MAX(Order__c) order, Sprint__c sprint
            FROM User_Story__c
            WHERE Sprint__c IN :setSprintIds
            GROUP BY Sprint__c
        ]) {
            maxUserStoriesOrderBySprint.put((Id) maxUserStoryOrderGroupBySprint.get('sprint'), (Decimal) maxUserStoryOrderGroupBySprint.get('order'));
        }
        if (Trigger.isUpdate) {
            if (!projectIds.isEmpty()) {
                projectsById = new Map<Id, Project__c>([SELECT Deployment_Flow__c FROM Project__c WHERE Id IN :projectIds]);
            }
            Set<Id> deploymentFlowIds = new Set<Id>();
            if (releaseMap != null) {
                for (Release__c release : releaseMap.values()) {
                    if (release.Project__c != null && release.Project__r.Deployment_Flow__c != null) {
                        deploymentFlowIds.add(release.Project__r.Deployment_Flow__c);
                    }
                }
            }

            if (projectsById != null) {
                for (Project__c project : projectsById.values()) {
                    if (project.Deployment_Flow__c != null) {
                        deploymentFlowIds.add(project.Deployment_Flow__c);
                    }
                }
            }

            deploymentFlowsById = new Map<Id, Deployment_Flow__c>(
                [
                    SELECT (SELECT Source_Environment__c, Destination_Environment__c FROM Deployment_Flow_Steps__r)
                    FROM Deployment_Flow__c
                    WHERE Id IN :deploymentFlowIds
                ]
            );

            for (Promoted_User_Story__c promotedUserStory : [
                SELECT User_Story__c
                FROM Promoted_User_Story__c
                WHERE Status__c != 'Outdated' AND User_Story__c IN :Trigger.newMap.keySet()
            ]) {
                if (!promotedUserStoriesByUserStoryId.containsKey(promotedUserStory.User_Story__c)) {
                    promotedUserStoriesByUserStoryId.put(promotedUserStory.User_Story__c, new List<Promoted_User_Story__c>());
                }
                promotedUserStoriesByUserStoryId.get(promotedUserStory.User_Story__c).add(promotedUserStory);
            }

            for (SObject so : Trigger.old) {
                User_Story__c old = (User_Story__c) so;
                User_Story__c usNew = (User_Story__c) Trigger.newMap.get(so.Id);
                if (old.Sprint__c == null) {
                    if (usNew.Sprint__c != null && usNew.Project__c == null) {
                        usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
                    }
                }
            }
        }
    }

    public static void checkSprints(User_Story__c oldUs, User_Story__c us) {
        if (
            oldUs != null &&
            (oldUs.Status__c == 'Backlog' ||
            oldUs.Status__c == 'Backburner') &&
            us.Status__c == oldUs.Status__c &&
            oldUs.Sprint__c == null &&
            us.Sprint__c != null
        ) {
            us.Status__c = 'Approved';
        } else if ((us.Status__c == 'Backlog' || us.Status__c == 'Backburner') && us.Sprint__c != null) {
            us.Sprint__c = null;
        }
    }

    public static void setOrderBeforeUpdate(User_Story__c oldUs, User_Story__c us) {
        if (
            us.Sprint__c != null &&
            (null == oldUs ||
            (us.Sprint__c != oldUs.Sprint__c) ||
            (us.Sprint__c == oldUs.Sprint__c &&
            null == us.Order__c &&
            null != oldUs.Order__c))
        ) {
            // Order will be updated based on sprint on user story create and update action
            // OR
            // Sprint is changed so we need to update order based on new sprint. We will assign the last order number.
            if (!lastOrderNumberMap.containsKey(us.Sprint__c) && maxUserStoriesOrderBySprint.containsKey(us.Sprint__c)) {
                Decimal maxNumber = maxUserStoriesOrderBySprint.get(us.Sprint__c) != null
                    ? maxUserStoriesOrderBySprint.get(us.Sprint__c) +
                      ((oldUs == null || (oldUs.Order__c != maxUserStoriesOrderBySprint.get(us.Sprint__c))) ? 1 : 0)
                    : 1;
                lastOrderNumberMap.put(us.Sprint__c, maxNumber);
            }
            us.Order__c = lastOrderNumberMap.containsKey(us.Sprint__c) ? lastOrderNumberMap.get(us.Sprint__c) : 1;
            Decimal currentOrderNumber = lastOrderNumberMap.containsKey(us.Sprint__c) ? lastOrderNumberMap.get(us.Sprint__c) + 1 : 1;
            lastOrderNumberMap.put(us.Sprint__c, currentOrderNumber);
        } else if (null == us.Sprint__c) {
            // Sprint lookup is removed so Order is going to be null to be updated later.
            us.Order__c = null;
        }
    }

    public static void validateOrgEnvironmentRelationship(User_Story__c us) {
        Org__c org = orgMap.get(us.Org_Credential__c);
        if (us.Org_Credential__c != null && us.Environment__c != null && org.Environment__c != us.Environment__c) {
            us.addError('The org credential must belong to the environment');
        }
    }

    public static void setEnvironment(User_Story__c us) {
        if (us.Environment__c == null && us.Org_Credential__c != null) {
            us.Environment__c = orgMap.get(us.Org_Credential__c).Environment__c;
        }
        if (us.Environment__c != null && environmentMap.get(us.Environment__c) != null) {
            Environment__c env = environmentMap.get(us.Environment__c);
            if (us.Minimum_Apex_Code_Coverage__c < env.Minimum_Apex_Test_Coverage__c) {
                us.Minimum_Apex_Code_Coverage__c = env.Minimum_Apex_Test_Coverage__c;
            }
        }
    }

    public static void setProject(User_Story__c usNew) {
        if (usNew.Sprint__c != null && usNew.Project__c == null) {
            usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
        }
    }

    public static void addUserStoryToPromoteDeployQueue(User_Story__c ous, User_Story__c nus) {
        if (ous.Promote_and_Deploy__c == false && nus.Promote_and_Deploy__c == true) {
            promoteAndDeployedStories.add(nus);
        }
    }

    public static void promoteAndDeployUserStories() {
        for (User_Story__c us : promoteAndDeployedStories) {
            createPromotion(us);
        }
    }

    public static void stopIndexingMetadata(User_Story__c ous, User_Story__c nus) {
        if (!ous.Stop_Indexing_Metadata__c && nus.Stop_Indexing_Metadata__c) {
            metadataIdsToDisable.add(nus.Id);
        } else if (ous.Stop_Indexing_Metadata__c && !nus.Stop_Indexing_Metadata__c) {
            metadataIdsToEnable.add(nus.Id);
        }
    }

    //changed the logic after getting rid of setOrderAfterUpdate method to prevent infinite loop
    //it doesnt update US, creates promotion and uspromotion records instead
    public static void updateUserStories() {
        if (promotions.size() > 0 && !usFlagToStopRecursiveUpdate) {
            List<Promoted_User_Story__c> pus2Insert = new List<Promoted_User_Story__c>();
            usFlagToStopRecursiveUpdate = true;
            Utilities.Secure_DML(new List<Promotion__c>(promotions), Utilities.DML_Action.INS, Schema.SObjectType.Promotion__c);
            for (Promotion__c pItem : promotions) {
                if (storiesByPromotion.containsKey(pItem.Project__c + '_' + pItem.Source_Environment__c)) {
                    List<User_Story__c> tempUserStories = new List<User_Story__c>();
                    for (User_Story__c usItem : storiesByPromotion.get(pItem.Project__c + '_' + pItem.Source_Environment__c)) {
                        pus2Insert.add(addUserStoryToPromotion(usItem, pItem));
                    }
                }
            }
            Utilities.Secure_DML(pus2Insert, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);

            for (Promotion__c pItem : promotions) {
                if (storiesByPromotion.containsKey(pItem.Project__c + '_' + pItem.Source_Environment__c)) {
                    for (User_Story__c usItem : storiesByPromotion.get(pItem.Project__c + '_' + pItem.Source_Environment__c)) {
                        DeployAPI.deployPromotionAsync(
                            pItem.Id,
                            usItem.Name,
                            usItem.Validate_Only__c,
                            usItem.Promote_as_Single_Step__c,
                            usItem.Promotion_Test_Level__c
                        );
                    }
                }
            }
        }
    }

    public static void setChildPromotedUserStoriesAsOutdated(User_Story__c oldUserStory, User_Story__c newUserStory) {
        if (oldUserStory.Environment__c == newUserStory.Environment__c) {
            return;
        }
        Id parentDeploymentFlowId;
        if (newUserStory.Project__c != null) {
            parentDeploymentFlowId = projectsById.get(newUserStory.Project__c).Deployment_Flow__c;
        } else if (newUserStory.Release__c != null) {
            Release__c release = releaseMap.get(newUserStory.Release__c);
            if (release.Project__c != null) {
                parentDeploymentFlowId = release.Project__r.Deployment_Flow__c;
            }
        }
        if (parentDeploymentFlowId != null) {
            Deployment_Flow__c pipeline = deploymentFlowsById.get(parentDeploymentFlowId);
            List<Deployment_Flow_Step__c> pipelineConnections = pipeline.Deployment_Flow_Steps__r;
            Boolean shouldSetChildPromotedUserStoriesAsOutdated = isNewEnvironmentLowerInPipeline(
                pipelineConnections,
                oldUserStory.Environment__c,
                newUserStory.Environment__c
            );
            if (shouldSetChildPromotedUserStoriesAsOutdated && !promotedUserStoriesByUserStoryId.isEmpty()) {
                for (Promoted_User_Story__c promotedUserStory : promotedUserStoriesByUserStoryId.get(newUserStory.Id)) {
                    promotedUserStory.Status__c = 'Outdated';
                    promotedUserStoriesToUpdateAsOutdated.add(promotedUserStory);
                }
            }
        }
    }

    public static void executeIndexMetadataJob() {
        if (!metadataIdsToDisable.isEmpty()) {
            indexMetadataJob(metadataIdsToDisable, false);
        }
        if (!metadataIdsToEnable.isEmpty()) {
            indexMetadataJob(metadataIdsToEnable, true);
        }
    }

    private static Promotion__c createPromotionRecord(User_Story__c us) {
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = us.Project__c;
        promotion.Release__c = us.Release__c;
        promotion.Source_Org_Credential__c = us.Org_Credential__c;
        promotion.Source_Environment__c = us.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;
        return promotion;
    }

    private static void createPromotion(User_Story__c us) {
        Promotion__c promotion = createPromotionRecord(us);
        String key = us.Project__c + '_' + promotion.Source_Environment__c;
        try {
            promotions.add(promotion);
            List<User_Story__c> tempUserStories = new List<User_Story__c>();
            if (storiesByPromotion.containsKey(key)) {
                tempUserStories = storiesByPromotion.get(key);
            }
            tempUserStories.add(us);
            storiesByPromotion.put(key, tempUserStories);
        } catch (Exception e) {
            us.addError(returnValidationError(e.getMessage()));
        }
    }

    private static Promoted_User_Story__c addUserStoryToPromotion(User_Story__c us, Promotion__c p) {
        return new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = p.Id, Name = 'Promoted User Story: ' + us.Name);
    }

    private static String returnValidationError(String message) {
        Set<String> labels = new Set<String>{
            Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED,
            Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED,
            Label.PROMOTION_FLOW_INACTIVE,
            Label.CCM_DESTINATION_ORG_INVALID,
            Label.CBM_FLOW_INVALID,
            Label.CCM_DESTINATION_ORG_INVALID +
            ' ' +
            Label.CBM_FLOW_INVALID
        };

        for (String messageLabel : labels) {
            if (message.contains(messageLabel)) {
                return messageLabel;
            }
        }
        return message;
    }

    private static Boolean isNewEnvironmentLowerInPipeline(
        List<Deployment_Flow_Step__c> pipelineConnections,
        Id previousEnvironmentId,
        Id newEnvironmentId
    ) {
        Boolean shouldSetChildPromotedUserStoriesAsOutdated = false;
        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            if (pipelineConnection.Source_Environment__c == newEnvironmentId) {
                if (pipelineConnection.Destination_Environment__c == previousEnvironmentId) {
                    shouldSetChildPromotedUserStoriesAsOutdated = true;
                } else {
                    shouldSetChildPromotedUserStoriesAsOutdated = isNewEnvironmentLowerInPipeline(
                        pipelineConnections,
                        previousEnvironmentId,
                        pipelineConnection.Destination_Environment__c
                    );
                }
            }
        }
        return shouldSetChildPromotedUserStoriesAsOutdated;
    }

    private static void indexMetadataJob(Set<Id> ids, Boolean checkConflicts) {
        IndexMetadataJob imJob = new IndexMetadataJob();
        imJob.zeroizePotentialConflicts = true;
        imJob.checkPotentialConflict = checkConflicts;
        imJob.storyIds = ids;
        Database.executeBatch(imJob);
    }
}