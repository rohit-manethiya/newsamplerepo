public without sharing class PromotionTriggerHelper {
    public static Map<Id, List<Deployment_Flow_Step__c>> stepsMap;
    private static Map<Id, List<Org__c>> environmentOrgMap;
    private static Map<Id, Environment__c> environmentMap;

    private static Map<String, Id> sourceIdDestinationIdToConnectionBehaviorIdMap = new Map<String, Id>();
    private static Map<Id, Org__c> orgMap;
    public static final String S_VALIDATION = 'Validation';
    public static final String COMPLETED = 'Completed';
    public static final String MERGE_CONFLICT = 'Merge Conflict';
    public static Set<Id> proIds = new Set<Id>();
    public static final String S_IFUSERHASNOCREDENTIAL = 'Only If User Has No Org Credential';
    public static Map<Id, Id> projectFlowMap;
    public static Map<Id, String> projectFlowOrderMap;
    public static Map<Id, GlobalUtilities.deploymentFlowDetails> promotionFlows;
    public static Map<Id, Id> releaseProjectsMap;
    public static Map<Id, String> destinationEnvironmentTypesMap;
    private static Set<Id> completedPromotionIds = new Set<Id>();
    public static Set<Id> promotionIds = new Set<Id>();
    public static List<Promotion__c> completedPromotions = new List<Promotion__c>();
    public static Map<Id, Set<String>> promotionMetadatasMap;
    public static Map<Id, Set<User_Story_Metadata__c>> environmentsMetadatasMap;
    public static Set<Id> destinationEnvironmentsIds;
    public static List<User_Story_Metadata__c> usMetadataUpd;
    public static Set<Id> environmentIndexBackPromotionSet;
    private static Set<Id> releaseIds;
    public static List<Promoted_User_Story__c> promotedStories;
    public static String ns {
        get {
            if (null == ns) {
                ns = Settings.ns;
            }
            return ns;
        }
        set;
    }

    /**
     * This method checks if a promotion is completed after update
     *
     * @param pNew is the new promotion to check
     */
    public static void isCompleted(Promotion__c pNew, Promotion__c pOld) {
        if (pNew.Status__c == COMPLETED && pOld.Status__c != COMPLETED) {
            completedPromotionIds.add(pNew.Id);
        }
    }

    /**
     * This method updates user stories with promote and promote and deploy as FALSE and it updates current environment to deployed environment if promotion is not a back promotion
     */
    public static void resetUserStories() {
        Map<Id, Connection_Behavior__c> connectionBehaviorMap = new Map<Id, Connection_Behavior__c>(
            [
                SELECT Id, Story_Status_After_Deployment__c
                FROM Connection_Behavior__c
                WHERE Id IN :sourceIdDestinationIdToConnectionBehaviorIdMap.values() AND Story_Status_After_Deployment__c != ''
            ]
        );
        List<User_Story__c> userStories = new List<User_Story__c>();
        for (Promoted_User_Story__c pus : promotedStories) {
            if (!pus.Promotion__r.Back_Promotion__c && completedPromotionIds.contains(pus.Promotion__c)) {
                String mapKey = String.valueOf(pus.Promotion__r.Source_Environment__c) + String.valueOf(pus.Promotion__r.Destination_Environment__c);
                User_Story__c us2Update = new User_Story__c(
                    Id = pus.User_Story__c,
                    Promote_Change__c = false,
                    Promote_and_Deploy__c = false,
                    Environment__c = pus.Promotion__r.Destination_Environment__c,
                    Org_Credential__c = pus.Promotion__r.Destination_Org_Credential__c
                );
                if (
                    sourceIdDestinationIdToConnectionBehaviorIdMap.containsKey(mapKey) &&
                    connectionBehaviorMap.containsKey(sourceIdDestinationIdToConnectionBehaviorIdMap.get(mapKey))
                ) {
                    us2Update.Status__c = connectionBehaviorMap.get(sourceIdDestinationIdToConnectionBehaviorIdMap.get(mapKey))
                        .Story_Status_After_Deployment__c;
                }
                userStories.add(us2Update);
            }
        }

        if (!userStories.isEmpty()) {
            Utilities.Secure_DML(userStories, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        }
    }

    public static void checkValidity(SObject currentItem) {
        String currentFapiName = ((String) currentItem.get('Order_By__c')).toLowerCase().replace('desc', '').replace('asc', '').replace(' ', '');
        SObjectField sObj = Schema.SObjectType.User_Story__c.fields.getMap().get(currentFapiName);
        if (null == sObj) {
            currentItem.addError(Label.PleaseMakeSure);
        } else if (!sObj.getDescribe().isSortable()) {
            currentItem.addError(currentFapiName + ' ' + Label.NOT_SORTABLE);
        }
    }

    /**
     * This method prepare data to process bulkified data
     *
     * @param records list of promotion records
     */
    public static void prepareData(List<SObject> records, List<Promotion__c> oldList) {
        stepsMap = new Map<Id, List<Deployment_Flow_Step__c>>();
        projectFlowMap = new Map<Id, Id>();
        projectFlowOrderMap = new Map<Id, String>();
        promotionFlows = new Map<Id, GlobalUtilities.deploymentFlowDetails>();
        releaseProjectsMap = new Map<Id, Id>();
        releaseIds = new Set<Id>();
        environmentOrgMap = new Map<Id, List<Org__c>>();
        destinationEnvironmentTypesMap = new Map<Id, String>(); // Id, Type__c
        orgMap = new Map<Id, Org__c>();
        Set<Id> flowIds = new Set<Id>();
        Set<Id> environmentSetIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        promotionMetadatasMap = new Map<Id, Set<String>>();
        environmentsMetadatasMap = new Map<Id, Set<User_Story_Metadata__c>>();
        destinationEnvironmentsIds = new Set<Id>();
        usMetadataUpd = new List<User_Story_Metadata__c>();
        environmentIndexBackPromotionSet = new Set<Id>();
        environmentMap = new Map<Id, Environment__c>();
        promotedStories = new List<Promoted_User_Story__c>();

        for (SObject obj : records) {
            Promotion__c prm = (Promotion__c) obj;
            if (String.isNotBlank(prm.Order_by__c)) {
                checkValidity(obj);
            }
            if (prm.Release__c != null) {
                releaseIds.add(prm.Release__c);
            }
            if (prm.Project__c != null) {
                projectIds.add(prm.Project__c);
            }
            if (prm.Source_Environment__c != null) {
                environmentOrgMap.put(prm.Source_Environment__c, new List<Org__c>());
            }
            if (prm.Destination_Environment__c != null) {
                environmentOrgMap.put(prm.Destination_Environment__c, new List<Org__c>());
                destinationEnvironmentsIds.add(prm.Destination_Environment__c);
            }

            promotionIds.add(prm.Id);
        }

        if (!environmentOrgMap.isEmpty()) {
            for (Environment__c env : [
                SELECT Id, Promotion_Default_Credential__c, Validation_Promotion_Default_Credential__c, Index_Back_Promotion_metadata__c
                FROM Environment__c
                WHERE Id IN :environmentOrgMap.keySet()
            ]) {
                if (destinationEnvironmentsIds.contains(env.Id) && env.Index_Back_Promotion_metadata__c) {
                    environmentIndexBackPromotionSet.add(env.Id);
                }
                environmentMap.put(env.Id, env);
            }
        }

        if (!releaseIds.isEmpty()) {
            for (Release__c rel : [SELECT Id, Project__c FROM Release__c WHERE Id IN :releaseIds]) {
                projectIds.add(rel.Project__c);
                releaseProjectsMap.put(rel.Id, rel.Project__c);
            }
        }

        if (!projectIds.isEmpty()) {
            for (Project__c pj : [SELECT Id, Deployment_Flow__c, Deployment_Flow__r.Order_by__c FROM Project__c WHERE Id IN :projectIds]) {
                flowIds.add(pj.Deployment_Flow__c);
                projectFlowMap.put(pj.Id, pj.Deployment_Flow__c);
                projectFlowOrderMap.put(pj.Id, pj.Deployment_Flow__r.Order_by__c);
                stepsMap.put(pj.Deployment_Flow__c, new List<Deployment_Flow_Step__c>());
                if (pj.Deployment_Flow__c != null) {
                    promotionFlows.put(pj.Id, GlobalUtilities.getDeploymentFlowDetails(pj.Deployment_Flow__c, ''));
                }
            }
        }

        for (SObject obj : records) {
            Promotion__c prm = (Promotion__c) obj;
            Boolean nullObjId = (null == obj.get('Id'));
            Boolean projectFieldPopulated = (null != prm.Project__c && String.isNotBlank(projectFlowOrderMap.get(prm.Project__c)));
            Boolean releaseProjectPopulated = (null != prm.Release__c &&
            null != prm.Release__r.Project__c &&
            String.isNotBlank(projectFlowOrderMap.get(prm.Release__r.Project__c)));

            if ((nullObjId && projectFieldPopulated) || releaseProjectPopulated) {
                prm.Order_by__c = (null != prm.Project__c
                    ? projectFlowOrderMap.get(prm.Project__c)
                    : projectFlowOrderMap.get(prm.Release__r.Project__c));
            }
        }

        if (!flowIds.isEmpty()) {
            List<Deployment_Flow_Step__c> steps = [
                SELECT
                    Id,
                    Connection_Behavior__c,
                    Source_Environment__c,
                    Destination_Environment__c,
                    Source_Environment__r.Type__c,
                    Destination_Environment__r.Type__c,
                    Deployment_Flow__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c IN :flowIds
            ];
            for (Deployment_Flow_Step__c stepItem : steps) {
                if (null != stepItem.Source_Environment__c && null != stepItem.Destination_Environment__c) {
                    sourceIdDestinationIdToConnectionBehaviorIdMap.put(
                        String.valueOf(stepItem.Source_Environment__c) + String.valueOf(stepItem.Destination_Environment__c),
                        stepItem.Connection_Behavior__c
                    );
                }
                List<Deployment_Flow_Step__c> tmp = stepsMap.get(stepItem.Deployment_Flow__c);
                environmentSetIds.add(stepItem.Source_Environment__c);
                environmentSetIds.add(stepItem.Destination_Environment__c);
                environmentOrgMap.put(stepItem.Source_Environment__c, new List<Org__c>());
                environmentOrgMap.put(stepItem.Destination_Environment__c, new List<Org__c>());
                tmp.add(stepItem);
                stepsMap.put(stepItem.Deployment_Flow__c, tmp);
            }
        }

        if (!environmentSetIds.isEmpty()) {
            for (Org__c org : [SELECT Id, OwnerId, Environment__c, Default_Credential__c FROM Org__c WHERE Environment__c IN :environmentSetIds]) {
                orgMap.put(org.Id, org);
                List<Org__c> tmp = environmentOrgMap.get(org.Environment__c);
                tmp.add(org);
                environmentOrgMap.put(org.Environment__c, tmp);
            }
        }

        //Load Promotions per User Story
        Map<Id, Id> userStoryPromotionMap = new Map<Id, Id>();
        if (!promotionIds.isEmpty()) {
            for (Promoted_User_Story__c pus : [
                SELECT
                    Id,
                    User_Story__c,
                    Promotion__r.Connection_Behavior__c,
                    Promotion__r.Source_Environment__c,
                    Promotion__c,
                    Promotion__r.Destination_Environment__c,
                    Promotion__r.Destination_Org_Credential__c,
                    Promotion__r.Back_Promotion__c
                FROM Promoted_User_Story__c
                WHERE Promotion__c IN :promotionIds
            ]) {
                userStoryPromotionMap.put(pus.User_Story__c, pus.Promotion__c);
                promotedStories.add(pus);
            }
        }

        //Load Environment per User Story
        Map<Id, Id> userStoryEnvironmentMap = new Map<Id, Id>();
        if (!destinationEnvironmentsIds.isEmpty()) {
            for (User_Story__c us : [
                SELECT Id, Environment__c
                FROM User_Story__c
                WHERE Environment__c IN :destinationEnvironmentsIds AND Exclude_From_CBM__c = false
                LIMIT 50000
            ]) {
                userStoryEnvironmentMap.put(us.Id, us.Environment__c);
            }
        }

        // Load User Story Metadata from Promotion and Environment
        for (User_Story_Metadata__c usMetadata : [
            SELECT Metadata_API_Name__c, User_Story__c, User_Story__r.Environment__c, Status__c
            FROM User_Story_Metadata__c
            WHERE
                User_Story__c IN :userStoryPromotionMap.keySet()
                OR (User_Story__r.Environment__c IN :environmentIndexBackPromotionSet
                AND Status__c != :Label.BACK_PROMOTED)
            LIMIT 50000
        ]) {
            // Promotion part
            if (userStoryPromotionMap.containsKey(usMetadata.User_Story__c)) {
                if (!promotionMetadatasMap.containsKey(userStoryPromotionMap.get(usMetadata.User_Story__c))) {
                    Set<String> metadatas = new Set<String>();
                    metadatas.add(usMetadata.Metadata_API_Name__c);
                    promotionMetadatasMap.put(userStoryPromotionMap.get(usMetadata.User_Story__c), metadatas);
                } else {
                    Set<String> metadatas = promotionMetadatasMap.get(userStoryPromotionMap.get(usMetadata.User_Story__c));
                    metadatas.add(usMetadata.Metadata_API_Name__c);
                    promotionMetadatasMap.put(userStoryPromotionMap.get(usMetadata.User_Story__c), metadatas);
                }
            }

            // Environment part
            if (environmentIndexBackPromotionSet.contains(usMetadata.User_Story__r.Environment__c) && usMetadata.Status__c != Label.BACK_PROMOTED) {
                if (!environmentsMetadatasMap.containsKey(userStoryEnvironmentMap.get(usMetadata.User_Story__c))) {
                    Set<User_Story_Metadata__c> metadatas = new Set<User_Story_Metadata__c>();
                    metadatas.add(usMetadata);
                    environmentsMetadatasMap.put(userStoryEnvironmentMap.get(usMetadata.User_Story__c), metadatas);
                } else {
                    Set<User_Story_Metadata__c> metadatas = environmentsMetadatasMap.get(userStoryEnvironmentMap.get(usMetadata.User_Story__c));
                    metadatas.add(usMetadata);
                    environmentsMetadatasMap.put(userStoryEnvironmentMap.get(usMetadata.User_Story__c), metadatas);
                }
            }
        }
    }

    public static void canPromoteThis(Promotion__c promotion) {
        Boolean isValidCBMFlow = false;

        if (promotion.Project__c != null) {
            if (promotionFlows.containsKey(promotion.Project__c)) {
                isValidCBMFlow = promotionFlows.get(promotion.Project__c).isCBMFlow;
            } else {
                promotion.addError(Label.PROMOTION_PROJECT_DEPLOYMENT_FLOW_MISSING);
            }
        } else if (promotion.Release__c != null) {
            if (releaseProjectsMap.containsKey(promotion.Release__c) && promotionFlows.containsKey(releaseProjectsMap.get(promotion.Release__c))) {
                isValidCBMFlow = promotionFlows.get(releaseProjectsMap.get(promotion.Release__c)).isCBMFlow;
            } else {
                promotion.addError(Label.PROMOTION_RELEASE_DEPLOYMENT_FLOW_MISSING);
            }
        }

        if (promotion.Back_Promotion__c && !isValidCBMFlow) {
            promotion.addError(Label.BACK_PROMOTION_NOT_ENABLED);
        }
        if (LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled()) {
            Boolean isActiveFlow = false;
            Boolean isSandboxDestination = false;
            if (promotion.Project__c != null && promotionFlows.get(promotion.Project__c) != null) {
                if (promotionFlows.get(promotion.Project__c).flow.Active__c) {
                    isActiveFlow = true;
                }
            } else if (promotion.Release__c != null && promotionFlows.get(releaseProjectsMap.get(promotion.Release__c)) != null) {
                if (promotionFlows.get(releaseProjectsMap.get(promotion.Release__c)).flow.Active__c) {
                    isActiveFlow = true;
                }
            }

            if (isActiveFlow && !LicenseHelper.isCopadoEnabled()) {
                if (
                    promotion.Destination_Environment__c != null &&
                    destinationEnvironmentTypesMap.get(promotion.Destination_Environment__c) != null
                ) {
                    if (destinationEnvironmentTypesMap.get(promotion.Destination_Environment__c) == 'Sandbox') {
                        isSandboxDestination = true;
                    }
                }

                if (!isValidCBMFlow) {
                    promotion.addError(Label.CBM_FLOW_INVALID);
                }
                if (!isSandboxDestination) {
                    promotion.addError(Label.CCM_DESTINATION_ORG_INVALID);
                }
            } else if (!isActiveFlow) {
                promotion.addError(Label.PROMOTION_FLOW_INACTIVE);
            }
        } else {
            promotion.addError(Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED);
        }
    }

    public static void validateOrgEnvironmentRelationship(Promotion__c promotion) {
        Org__c sorg = orgMap.get(promotion.Source_Org_Credential__c);
        Org__c dorg = orgMap.get(promotion.Destination_Org_Credential__c);
        Id flowId = projectFlowMap.get(promotion.Project__c);
        if (flowId != null && promotion.Source_Environment__c != null && sorg == null) {
            promotion.addError(Label.FLOW_CREDENTIAL_ERROR);
        }
        if (flowId != null && promotion.Destination_Environment__c != null && dorg == null) {
            promotion.addError(Label.FLOW_CREDENTIAL_ERROR);
        }
        if (sorg != null && promotion.Source_Org_Credential__c != null && sorg.Environment__c != promotion.Source_Environment__c) {
            promotion.Source_Org_Credential__c.addError(Label.ORG_CREDENTIAL_NOT_PART_OF_ENVIRONMENT);
        }
        if (dorg != null && promotion.Destination_Org_Credential__c != null && dorg.Environment__c != promotion.Destination_Environment__c) {
            promotion.Destination_Org_Credential__c.addError(Label.ORG_CREDENTIAL_NOT_PART_OF_ENVIRONMENT);
        }
    }

    public static void setSourceOrgFromEnvironment(Promotion__c promotion) {
        Boolean isValidation = promotion.Status__c == S_VALIDATION;

        if (!promotion.Back_Promotion__c) {
            if (null == promotion.Source_Org_Credential__c && null != promotion.Source_Environment__c) {
                Boolean defaultOrgFlag4Source = ((isValidation &&
                environmentMap.get(promotion.Source_Environment__c).Validation_Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL) ||
                (!isValidation && environmentMap.get(promotion.Source_Environment__c).Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL));
                for (Org__c org : environmentOrgMap.get(promotion.Source_Environment__c)) {
                    if (org.OwnerId == promotion.OwnerId && (null == promotion.Source_Org_Credential__c || defaultOrgFlag4Source)) {
                        promotion.Source_Org_Credential__c = org.Id;
                        if (defaultOrgFlag4Source) {
                            break;
                        }
                    } // If the user has no Org Credential, assign a default credential
                    if (org.Default_Credential__c && (null == promotion.Source_Org_Credential__c || !defaultOrgFlag4Source)) {
                        promotion.Source_Org_Credential__c = org.Id;
                        if (!defaultOrgFlag4Source) {
                            break;
                        }
                    }
                }
            }
        } else {
            if (null == promotion.Destination_Org_Credential__c && null != promotion.Destination_Environment__c) {
                Boolean defaultOrgFlag4Destination = ((isValidation &&
                environmentMap.get(promotion.Destination_Environment__c).Validation_Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL) ||
                (!isValidation &&
                environmentMap.get(promotion.Destination_Environment__c).Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL));
                for (Org__c org : environmentOrgMap.get(promotion.Destination_Environment__c)) {
                    if (org.OwnerId == promotion.OwnerId && (null == promotion.Destination_Org_Credential__c || defaultOrgFlag4Destination)) {
                        promotion.Destination_Org_Credential__c = org.Id;
                        if (defaultOrgFlag4Destination) {
                            break;
                        }
                    } // If the user has no Org Credential, assign a default credential
                    if (org.Default_Credential__c && (null == promotion.Destination_Org_Credential__c || !defaultOrgFlag4Destination)) {
                        promotion.Destination_Org_Credential__c = org.Id;
                        if (!defaultOrgFlag4Destination) {
                            break;
                        }
                    }
                }
            }
            System.debug('fill org cred... promotion====> ' + promotion);
        }

        if (!promotion.Back_Promotion__c && promotion.Source_Org_Credential__c == null && promotion.Source_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_SOURCE_ORG_NOT_FOUND);
        } else if (promotion.Back_Promotion__c && promotion.Destination_Org_Credential__c == null && promotion.Destination_Environment__c != null) {
            System.debug('ERROR mf fill org cred......');
            promotion.addError(Label.ERROR_PROMOTION_SOURCE_ORG_NOT_FOUND);
        }
    }

    public static Boolean hasEqualDeploymentFlows(Promotion__c promotion) {
        Id flowId = projectFlowMap.get(promotion.Project__c);
        if (null != promotion.Release__c) {
            Id projectId = releaseProjectsMap.get(promotion.Release__c);
            Id releaseFlowId = projectFlowMap.get(projectId);
            if (flowId != null && releaseFlowId != null && flowId != releaseFlowId) {
                promotion.addError(Label.Same_Deployment_Flow_Linked_To_Release);
                return false;
            }
        }
        return true;
    }

    public static void setAutoResolveConflictOption(Promotion__c promotion) {
        Deployment_Flow__c flow;
        if (promotion.Project__c != null && promotionFlows.containsKey(promotion.Project__c)) {
            flow = promotionFlows.get(promotion.Project__c).flow;
        } else if (
            promotion.Release__c != null && releaseProjectsMap.containsKey(promotion.Release__c) &&
            promotionFlows.containsKey(releaseProjectsMap.get(promotion.Release__c))
        ) {
            flow = promotionFlows.get(releaseProjectsMap.get(promotion.Release__c)).flow;
        }
        // If the promotion AutoResolve options are null, apply the Deployment Flow AutoResolve options
        if (flow != null && promotion.Exclude_From_Auto_Resolve__c == null) {
            promotion.Exclude_From_Auto_Resolve__c = flow.Exclude_From_Auto_Resolve__c;
        }
    }

    public static void setMergeConflictField(Promotion__c promotion) {
        if (promotion.Status__c == MERGE_CONFLICT) {
            promotion.Merge_Conflict__c = true;
        }
    }

    public static void setDestinationOrgFromFlow(Promotion__c promotion) {
        Boolean isValidation = promotion.Status__c == S_VALIDATION;

        Id flowId = projectFlowMap.get(promotion.Project__c);
        if (promotion.Release__c != null) {
            Id projectId = releaseProjectsMap.get(promotion.Release__c);

            if (projectFlowMap.containsKey(projectId)) {
                flowId = projectFlowMap.get(projectId);
            }
        }

        List<Deployment_Flow_Step__c> tmp = stepsMap.get(flowId);
        if (tmp != null) {
            for (Deployment_Flow_Step__c step : tmp) {
                if (!promotion.Back_Promotion__c && null != promotion.Source_Environment__c) {
                    Boolean defaultOrgFlag4Source = ((isValidation &&
                    environmentMap.get(promotion.Source_Environment__c).Validation_Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL) ||
                    (!isValidation &&
                    environmentMap.get(promotion.Source_Environment__c).Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL));
                    if (step.Source_Environment__c == promotion.Source_Environment__c) {
                        promotion.Destination_Environment__c = step.Destination_Environment__c;
                        if (String.isEmpty(promotion.Connection_Behavior__c)) {
                            promotion.Connection_Behavior__c = step.Connection_Behavior__c;
                        }

                        destinationEnvironmentTypesMap.put(promotion.Destination_Environment__c, step.Destination_Environment__r.Type__c);
                        for (Org__c org : environmentOrgMap.get(promotion.Destination_Environment__c)) {
                            if (org.OwnerId == promotion.OwnerId && (null == promotion.Destination_Org_Credential__c || defaultOrgFlag4Source)) {
                                promotion.Destination_Org_Credential__c = org.Id;
                                if (defaultOrgFlag4Source) {
                                    break;
                                }
                            }
                            if (org.Default_Credential__c && (null == promotion.Destination_Org_Credential__c || !defaultOrgFlag4Source)) {
                                promotion.Destination_Org_Credential__c = org.Id;
                                if (!defaultOrgFlag4Source) {
                                    break;
                                }
                            }
                        }
                    }
                } else if (promotion.Back_Promotion__c && null != promotion.Destination_Environment__c) {
                    Boolean defaultOrgFlag4Destination = ((isValidation &&
                    environmentMap.get(promotion.Destination_Environment__c).Validation_Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL) ||
                    (!isValidation &&
                    environmentMap.get(promotion.Destination_Environment__c).Promotion_Default_Credential__c == S_IFUSERHASNOCREDENTIAL));
                    if (step.Source_Environment__c == promotion.Destination_Environment__c) {
                        promotion.Source_Environment__c = step.Destination_Environment__c;
                        if (String.isEmpty(promotion.Connection_Behavior__c)) {
                            promotion.Connection_Behavior__c = step.Connection_Behavior__c;
                        }

                        destinationEnvironmentTypesMap.put(promotion.Destination_Environment__c, step.Source_Environment__r.Type__c);
                        for (Org__c org : environmentOrgMap.get(promotion.Source_Environment__c)) {
                            if (org.OwnerId == promotion.OwnerId && (null == promotion.Source_Org_Credential__c || defaultOrgFlag4Destination)) {
                                promotion.Source_Org_Credential__c = org.Id;
                                if (defaultOrgFlag4Destination) {
                                    break;
                                }
                            }
                            if (org.Default_Credential__c && (null == promotion.Source_Org_Credential__c || !defaultOrgFlag4Destination)) {
                                promotion.Source_Org_Credential__c = org.Id;
                                if (!defaultOrgFlag4Destination) {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!promotion.Back_Promotion__c && promotion.Destination_Org_Credential__c == null && promotion.Destination_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_DESTINATION_ORG_NOT_FOUND);
        } else if (promotion.Back_Promotion__c && promotion.Source_Org_Credential__c == null && promotion.Source_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_DESTINATION_ORG_NOT_FOUND);
        }
    }

    public static void accumulateIfCompleted(Promotion__c pNew, Promotion__c pOld) {
        if (pOld.Status__c != COMPLETED && pNew.Status__c == COMPLETED) {
            completedPromotions.add(pNew);
            proIds = new Set<Id>();
            if (!pNew.Back_Promotion__c) {
                proIds.add(pNew.Id);
            }
        }
    }

    public static void accumulateCompletedListIfNotEmpty() {
        if (!proIds.isEmpty()) {
            updateUSLastPromotionDate(proIds);
        }
    }

    /**
     * @param pId
     * @description updates related user stories with current time after the promotion successfully completed
     */
    @Future
    public static void updateUSLastPromotionDate(set<Id> pIds) {
        List<Promotion__c> promotionList = [SELECT Id, (SELECT User_Story__c FROM Promoted_User_Stories__r) FROM Promotion__c WHERE Id IN :pIds];
        Set<Id> usIds = new Set<Id>();
        for (Promotion__c proItem : promotionList) {
            for (Promoted_User_Story__c pus : proItem.Promoted_User_Stories__r) {
                usIds.add(pus.User_Story__c);
            }
        }
        if (usIds.size() > 0) {
            List<User_Story__c> usList2Update = [SELECT Id, Last_Promotion_Date__c FROM User_Story__c WHERE Id IN :usIds];
            for (User_Story__c us : usList2Update) {
                us.Last_Promotion_Date__c = System.now();
            }
            Utilities.Secure_DML(usList2Update, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        }
    }

    public static void runSeleniumTestGroups() {
        if (!completedPromotions.isEmpty() && !System.isBatch()) {
            RunTestGroupsBatch.runSeleniumTestsOfPromotions(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_ALL_TESTS, completedPromotions);
        }
    }

    /**
     * If we find a coincidence between the User Story Metadata in a Completed - Back Promotion
     * we mark User Story Metadata of Destination Environment as Back Promoted
     * @param promo to check user stories and mark as back promoted if needed.
     */
    public static void markUserStoryMetadataBackPromoted(Promotion__c promo) {
        if (environmentIndexBackPromotionSet.contains(promo.Destination_Environment__c) && promo.Status__c == COMPLETED && promo.Back_Promotion__c) {
            if (promotionMetadatasMap.containsKey(promo.Id) && environmentsMetadatasMap.containsKey(promo.Destination_Environment__c)) {
                Set<String> promoMetadatas = promotionMetadatasMap.get(promo.Id);
                for (User_Story_Metadata__c usm : environmentsMetadatasMap.get(promo.Destination_Environment__c)) {
                    if (promoMetadatas.contains(usm.Metadata_API_Name__c)) {
                        usm.Status__c = Label.BACK_PROMOTED;
                        usMetadataUpd.add(usm);
                    }
                }
            }
        }
    }

    /**
     * This method updates user story metadata records previously loaded by markUserStoryMetadataBackPromoted
     * @see markUserStoryMetadataBackPromoted()
     */
    public static void updateUserStoryMetadatasBackPromoted() {
        if (usMetadataUpd != null) {
            Utilities.Secure_DML(usMetadataUpd, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
        }
    }
}