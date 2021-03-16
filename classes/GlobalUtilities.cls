/**
 * GlobalUtilities class with sharing.
 *
 **/
public with sharing class GlobalUtilities {
    private static String validsObjectName { get; set; }
    //public transient static Map<Id, Set<String>> rebasePromotedUserStoryDestinations = new Map<Id, Set<String>>();
    public static Map<Id, List<Promoted_User_Story__c>> getRebaseUserStories(
        List<Deployment_Flow_Step__c> flowSteps,
        Id backPromotionSourceEnv,
        Id flowId
    ) {
        return getPromotedUserStoriesUSBehind(backPromotionSourceEnv, flowId);
    }

    /**
     * Method to retrieve all the possible dependencies for the user stories given
     *
     * @param usIds
     * @param envId
     *
     * @return
     */
    public static List<User_Story__c> getUserStoriesDependencies(Set<Id> usIds, Id envId) {
        //get Custom metadata to ignore Team Dependencies depending of defined Value
        String skipAPI = 'Skip_Dependency__c';
        Copado_Setting__mdt cs = new Copado_Setting__mdt();
        cs = [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Team_Dependency' LIMIT 1];
        if (cs.Text_Field__c != null && cs.Text_Field__c != skipAPI) {
            skipAPI = cs.Text_Field__c;
        }
        //User Story to return
        List<User_Story__c> usToReturn = new List<User_Story__c>();

        String query = '';
        //We get the universe of user stories with their relevant information (Dependencies )
        query =
            'SELECT Id, Environment__c, Name, User_Story_Title__c, Status__c, Environment__r.Name, ' +
            '(SELECT Id, Name, Deliverable__c, Dependency_Status__c, Dependent_Team__c, Dependent_Team__r.Name, Dependent_User_Story__r.Id, Dependent_User_Story__r.Name, Dependent_User_Story__r.User_Story_Title__c, Dependent_User_Story__r.Status__c, Dependent_User_Story__r.Environment__c, Dependent_User_Story__r.Environment__r.Name FROM Team_Dependencies_On_UStory__r WHERE Dependent_User_Story__c IN :usIds), ' +
            '(SELECT Id, Promotion__c, User_Story__c, Promotion__r.Destination_Environment__c, Promotion__r.Source_Environment__c FROM Promoted_User_Stories__r WHERE Promotion__r.Status__c = \'Completed\') ' +
            'FROM User_Story__c ' +
            'WHERE Id NOT IN :usIds ' +
            'AND Id IN (SELECT Provider_User_Story__c FROM Team_Dependency__c WHERE Dependent_User_Story__c IN :usIds AND ' +
            String.escapeSingleQuotes(skipAPI) +
            ' = false)';

        try {
            List<User_Story__c> usUniverse = new List<User_Story__c>();
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                usUniverse = Database.query(query);
            }
            for (User_Story__c us : usUniverse) {
                Boolean skipUS = false;
                if (us.Promoted_User_Stories__r.size() > 0) {
                    //Iterate over all completed promoted user stories to see in which environments it has been if it has been all environments
                    //of all user stories to be promoted then the environments should cotain the dependencies already
                    for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                        if (pus.Promotion__r.Destination_Environment__c == envId || pus.Promotion__r.Source_Environment__c == envId) {
                            skipUS = true;
                            break;
                        }
                    }
                }
                if (!skipUS) {
                    usToReturn.add(us);
                }
            }
        } catch (Exception e) {
            //there was an issue, normally Dependency Skip API Name was set wrong
            System.debug(e.getMessage());
        }
        return usToReturn;
    }

    /**
     * Method to retrieve all the possible dependencies
     *
     * @param promotionToUserStoryIdMap  contains promotion and user story ids set based on promotion
     *
     * @return
     */
    public static Map<Promotion__c, List<User_Story__c>> getUserStoriesDependencies(Map<Promotion__c, Set<Id>> promotionToUserStoryIdMap) {
        Map<Promotion__c, List<User_Story__c>> promotionUserStoriesMap = new Map<Promotion__c, List<User_Story__c>>();

        //get Custom metadata to ignore Team Dependencies depending of defined Value
        String skipAPI = 'Skip_Dependency__c';
        Copado_Setting__mdt cs = new Copado_Setting__mdt();
        cs = [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Team_Dependency' LIMIT 1];
        if (cs.Text_Field__c != null && cs.Text_Field__c != skipAPI) {
            skipAPI = cs.Text_Field__c;
        }
        Set<Id> usIdsSet = new Set<Id>();
        for (Set<Id> usIds : promotionToUserStoryIdMap.values()) {
            usIdsSet.addAll(usIds);
        }

        String query = '';
        //We get the universe of user stories with their relevant information (Dependencies )
        query =
            'SELECT Id, Environment__c, Name, User_Story_Title__c, Status__c, Environment__r.Name, ' +
            '(SELECT Id, Name, Deliverable__c, Dependency_Status__c, Dependent_Team__c, Dependent_Team__r.Name, Dependent_User_Story__r.Id, Dependent_User_Story__r.Name, Dependent_User_Story__r.User_Story_Title__c, Dependent_User_Story__r.Status__c, Dependent_User_Story__r.Environment__c, Dependent_User_Story__r.Environment__r.Name FROM Team_Dependencies_On_UStory__r WHERE Dependent_User_Story__c IN :usIdsSet), ' +
            '(SELECT Id, Promotion__c, User_Story__c, Promotion__r.Destination_Environment__c, Promotion__r.Source_Environment__c, Promotion__r.Status__c FROM Promoted_User_Stories__r )' +
            'FROM User_Story__c ' +
            'WHERE Id IN (SELECT Provider_User_Story__c FROM Team_Dependency__c WHERE Dependent_User_Story__c IN :usIdsSet AND ' +
            String.escapeSingleQuotes(skipAPI) +
            ' = false)';
        try {
            List<User_Story__c> usUniverse = new List<User_Story__c>();
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                usUniverse = Database.query(query);
            }
            Map<Id, Promotion__c> tempPromotionMap = new Map<Id, Promotion__c>();
            for (Promotion__c pro : promotionToUserStoryIdMap.keySet()) {
                tempPromotionMap.put(pro.Id, pro);
            }
            Map<Id, List<Promotion__c>> usToPromotionListMap = new Map<Id, List<Promotion__c>>();
            for (User_Story__c us : usUniverse) {
                for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                    if (usToPromotionListMap.containsKey(us.Id)) {
                        usToPromotionListMap.get(us.Id).add(tempPromotionMap.get(pus.Promotion__c));
                    } else {
                        usToPromotionListMap.put(us.Id, new List<Promotion__c>{ tempPromotionMap.get(pus.Promotion__c) });
                    }
                }
            }
            for (User_Story__c us : usUniverse) {
                Boolean skipUS = false;
                if (!us.Promoted_User_Stories__r.isEmpty()) {
                    //Iterate over all completed promoted user stories to see in which environments it has been if it has been all environments
                    //of all user stories to be promoted then the environments should cotain the dependencies already
                    for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                        if (
                            pus.Promotion__r.Status__c == 'Completed' &&
                            (pus.Promotion__r.Destination_Environment__c == tempPromotionMap.get(pus.Promotion__c).Destination_Environment__c ||
                            pus.Promotion__r.Source_Environment__c == tempPromotionMap.get(pus.Promotion__c).Destination_Environment__c)
                        ) {
                            skipUS = true;
                            break;
                        }
                    }
                }
                if (!skipUS) {
                    if (usToPromotionListMap.containsKey(us.Id)) {
                        for (Promotion__c pr : usToPromotionListMap.get(us.Id)) {
                            if (promotionUserStoriesMap.containsKey(pr)) {
                                promotionUserStoriesMap.get(pr).add(us);
                            } else {
                                promotionUserStoriesMap.put(pr, new List<User_Story__c>{ us });
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            //there was an issue, normally Dependency Skip API Name was set wrong
            System.debug(e.getMessage());
        }
        return promotionUserStoriesMap;
    }

    /**
     * jgaviria@copado.com
     * Get latest Compliance Scan Result and Finding to related record
     *
     * @param pId
     * @param apiRelName
     *
     * @return
     */
    public static Compliance_Scan_Result__c getWOSharingCSR(Id pId, String apiRelName) {
        Compliance_Scan_Result__c csr = new Compliance_Scan_Result__c();
        try {
            if (String.isNotBlank(pId) && String.isNotBlank(apiRelName)) {
                String query =
                    'SELECT Id, Status__c, ' +
                    apiRelName +
                    ', (SELECT Id, Severity__c, Compliance_Rule__r.Action__c FROM Compliance_Findings__r WHERE Compliance_Rule__r.Action__c != \'Document Only\' ORDER BY  Compliance_Rule__r.Action__c, Severity__c LIMIT 1) ' +
                    'FROM  Compliance_Scan_Result__c ' +
                    'WHERE ' +
                    String.escapeSingleQuotes(apiRelName) +
                    ' =: pId ' +
                    'ORDER BY CreatedDate DESC ' +
                    'LIMIT 1';
                List<Compliance_Scan_Result__c> csrL = new List<Compliance_Scan_Result__c>();
                if (Schema.SObjectType.Compliance_Scan_Result__c.isQueryable() && Schema.SObjectType.Compliance_Scan_Result__c.isAccessible()) {
                    csrL = Database.query(query);
                }
                if (!csrL.isEmpty()) {
                    csr = csrL[0];
                }
            }
        } catch (Exception e) {
            //Return empty Object Component will validate
            System.debug('There is no FLS or query is not succesfull ' + e.getMessage());
        }
        return csr;
    }

    private static Set<String> sourceEnvironments;
    public static String userStoriesAheadBehindTitle { get; set; }
    public static String targetBranch { get; set; }
    public static String baseUrl { get; set; }
    public static String provider { get; set; }
    private static Map<String, String> fieldsMap;
    private static List<User_Story__c> usBehindList;
    private static List<User_Story__c> usAheadList;
    private static Map<String, String> resultMap;

    private static Map<Id, List<Promoted_User_Story__c>> getPromotedUserStoriesUSBehind(Id backPromotionSourceEnv, Id flowId) {
        return getPromotedUserStoriesUSBehind(new Set<Id>{ backPromotionSourceEnv }, flowId);
    }
    //changed above method and added below to be able cover multiple backPromotionSourceEnvs
    private static Map<Id, List<Promoted_User_Story__c>> getPromotedUserStoriesUSBehind(Set<Id> backPromotionSourceEnvSet, Id flowId) {
        // Getting all promoted user stories that are modified after the lastTransaction date, not excluded from CBM and part of the current flows requested step.
        // In addition to above explanation
        // Promotion has to be completed in order to consider the user story has ben stream lined to the next environment
        // User story should not be cancelled. Cancelled USs are ignored since they should not be promoteable.
        // Promotions destination env has be equal to flowSteps destination env. This is necessary to consider user stories current environment.

        Set<Id> sourceAndDestination = new Set<Id>();
        Map<Id, List<Promoted_User_Story__c>> userStoryPromotionsMap = new Map<Id, List<Promoted_User_Story__c>>();
        if (Schema.SObjectType.Promoted_User_Story__c.isQueryable() && Schema.SObjectType.Promoted_User_Story__c.isAccessible()) {
            List<Promoted_User_Story__c> pusList = [
                SELECT
                    Id,
                    Name,
                    User_Story__c,
                    User_Story__r.Name,
                    User_Story__r.User_Story_Title__c,
                    Promotion__r.Source_Environment__c,
                    Promotion__r.Destination_Environment__c,
                    Promotion__r.Back_Promotion__c,
                    User_Story__r.Project__r.Name,
                    User_Story__r.Release__r.Name,
                    User_Story__r.Org_Credential__r.Org_Type__c,
                    User_Story__r.Project__c,
                    User_Story__r.Release__c
                FROM Promoted_User_Story__c
                WHERE
                    Status__c != 'Outdated'
                    AND User_Story__r.Exclude_From_CBM__c = false
                    AND (User_Story__r.Project__r.Deployment_Flow__c = :flowId
                    OR User_Story__r.Release__r.Project__r.Deployment_Flow__c = :flowId)
                    AND Promotion__r.Status__c = 'Completed'
                    AND User_Story__r.Status__c != 'Cancelled'
                    AND (Promotion__r.Destination_Environment__c IN :backPromotionSourceEnvSet
                    OR Promotion__r.Source_Environment__c IN :backPromotionSourceEnvSet
                    OR User_Story__r.Environment__c IN :backPromotionSourceEnvSet)
                ORDER BY Promotion__r.Back_Promotion__c DESC
            ];
            Integer pusListSize = pusList.size();
            for (Integer i = 0; i < pusListSize; i++) {
                Promoted_User_Story__c pus = pusList[i];
                if (!userStoryPromotionsMap.containsKey(pus.User_Story__c)) {
                    userStoryPromotionsMap.put(pus.User_Story__c, new List<Promoted_User_Story__c>{ pus });
                } else {
                    List<Promoted_User_Story__c> temp = userStoryPromotionsMap.get(pus.User_Story__c);
                    temp.add(pus);
                    userStoryPromotionsMap.put(pus.User_Story__c, temp);
                }
            }
        }

        return userStoryPromotionsMap;
    }

    public static Map<Id, Map<Id, RebaseSelectionsWrapper>> calculateUserStoriesBehind(
        Map<Id, List<Promoted_User_Story__c>> promotedUserStoriesByUserStoryId,
        List<Deployment_Flow_Step__c> pipelineConnections
    ) {
        Map<Id, Map<Id, RebaseSelectionsWrapper>> rebaseSelectionsWrapperByEnvironmentByUserStory = new Map<Id, Map<Id, RebaseSelectionsWrapper>>();
        Map<Id, Boolean> userStoriesWithShouldBeOmittedCheck = new Map<Id, Boolean>();
        Map<Id, Set<Id>> destinationEnvironmentsByUserStory = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> sourceEnvironmentsByUserStory = new Map<Id, Set<Id>>();
        for (Id userStoryId : promotedUserStoriesByUserStoryId.keySet()) {
            Set<Id> destEnvironments = new Set<Id>();
            Set<Id> sourceEnvironments = new Set<Id>();
            for (Promoted_User_Story__c promotedUserStory : promotedUserStoriesByUserStoryId.get(userStoryId)) {
                if (promotedUserStory.Promotion__c != null) {
                    destEnvironments.add(promotedUserStory.Promotion__r.Destination_Environment__c);
                    if (!promotedUserStory.Promotion__r.Back_Promotion__c)
                        sourceEnvironments.add(promotedUserStory.Promotion__r.Source_Environment__c);
                }
            }
            destinationEnvironmentsByUserStory.put(userStoryId, destEnvironments);
            sourceEnvironmentsByUserStory.put(userStoryId, sourceEnvironments);
        }
        for (Id userStoryId : promotedUserStoriesByUserStoryId.keySet()) {
            Map<Id, RebaseSelectionsWrapper> rebaseSelectionsWrapperByEnvironment = new Map<Id, RebaseSelectionsWrapper>();
            for (Deployment_Flow_Step__c pipelineConntection : pipelineConnections) {
                if (
                    !destinationEnvironmentsByUserStory.get(userStoryId).contains(pipelineConntection.Source_Environment__c) &&
                    !sourceEnvironmentsByUserStory.get(userStoryId).contains(pipelineConntection.Source_Environment__c)
                ) {
                    rebaseSelectionsWrapperByEnvironment.put(
                        pipelineConntection.Source_Environment__c,
                        new rebaseSelectionsWrapper(pipelineConntection.Source_Environment__c, userStoryId, true, true)
                    );
                    userStoriesWithShouldBeOmittedCheck.put(userStoryId, false);
                } else {
                    rebaseSelectionsWrapperByEnvironment.put(
                        pipelineConntection.Source_Environment__c,
                        new rebaseSelectionsWrapper(pipelineConntection.Source_Environment__c, userStoryId, false, false)
                    );
                    if (!userStoriesWithShouldBeOmittedCheck.containsKey(userStoryId)) {
                        userStoriesWithShouldBeOmittedCheck.put(userStoryId, true);
                    }
                }
            }
            if (userStoriesWithShouldBeOmittedCheck.containsKey(userStoryId) && !userStoriesWithShouldBeOmittedCheck.get(userStoryId)) {
                rebaseSelectionsWrapperByEnvironmentByUserStory.put(userStoryId, rebaseSelectionsWrapperByEnvironment);
            }
        }
        return rebaseSelectionsWrapperByEnvironmentByUserStory;
    }

    @TestVisible
    private static Map<Id, List<Promoted_User_Story__c>> getPromotedUserStoriesUSBehind(Deployment_Flow_Step__c flowStep) {
        return getPromotedUserStoriesUSBehind(flowStep.Destination_Environment__c, flowStep.Deployment_Flow__c);
    }

    private static void getUSListBehind(Set<Id> usIds) {
        usBehindList = new List<User_Story__c>();
        String soqlString = 'SELECT ' + fieldsMap.get(Label.FIELDS) + ' FROM ' + fieldsMap.get(Label.OBJECT) + ' WHERE Id IN :usIds LIMIT 1000';
        List<User_Story__c> temp = Database.query(soqlString);
        for (User_Story__c us : temp) {
            usBehindList.add(us);
        }
    }

    private static void getUSListAhead(Deployment_Flow_Step__c flowStep) {
        usAheadList = new List<User_Story__c>();
        String soqlString = '';
        if (
            String.isNotBlank(flowStep.Deployment_Flow__c) &&
            String.isNotBlank(flowStep.Source_Environment__c) &&
            Schema.getGlobalDescribe().get(fieldsMap.get(Label.OBJECT)).getDescribe().isQueryable() &&
            Schema.getGlobalDescribe().get(fieldsMap.get(Label.OBJECT)).getDescribe().isAccessible()
        ) {
            soqlString =
                'SELECT ' +
                fieldsMap.get(Label.FIELDS) +
                ' FROM ' +
                fieldsMap.get(Label.OBJECT) +
                ' WHERE Exclude_From_CBM__c = false AND Status__c != \'Cancelled\' AND (Project__r.Deployment_Flow__c = \'' +
                String.escapeSingleQuotes(flowStep.Deployment_Flow__c) +
                '\' OR Release__r.Project__r.Deployment_Flow__c = \'' +
                String.escapeSingleQuotes(flowStep.Deployment_Flow__c) +
                '\') AND Environment__c = \'' +
                String.escapeSingleQuotes(flowStep.Source_Environment__c) +
                '\' AND Promote_Change__c = true ORDER BY Name DESC LIMIT 1000';
            usAheadList = Database.query(soqlString);
        }
    }

    /**
     * It is used to retrieve all user stories behind with all fields populated
     *
     * @param flowStep
     *
     * @return
     */
    public static List<User_Story__c> getUserStoriesBehind(Deployment_Flow_Step__c flowStep) {
        Map<Id, List<Promoted_User_Story__c>> userStoriesWithPromotions = getPromotedUserStoriesUSBehind(
            flowStep.Destination_Environment__c,
            flowStep.Deployment_Flow__c
        );
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsWithoutSharing('User_Story__c');
        Map<Id, Map<Id, RebaseSelectionsWrapper>> usBehind = calculateUserStoriesBehind(
            userStoriesWithPromotions,
            new List<Deployment_Flow_Step__c>{ flowStep }
        );
        userStoriesWithPromotions = null;
        getUSListBehind(usBehind.keySet());
        usBehind = null;
        return usBehindList;
    }

    /**
     * It is used to retrieve all user stories behind with all fields populated
     *
     * @param flowStepList
     *
     * @return
     */
    public static Map<Id, Map<Id, RebaseSelectionsWrapper>> getUserStoriesBehind(
        List<Deployment_Flow_Step__c> flowStepList,
        Set<Id> destinationEnvs,
        Id deploymentFlowId
    ) {
        Map<Id, List<Promoted_User_Story__c>> userStoriesWithPromotions = getPromotedUserStoriesUSBehind(destinationEnvs, deploymentFlowId);
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsWithoutSharing('User_Story__c');
        Map<Id, Map<Id, RebaseSelectionsWrapper>> usBehind = calculateUserStoriesBehind(userStoriesWithPromotions, flowStepList);
        userStoriesWithPromotions = null;
        return usBehind;
    }

    /**
     * It is used to retrieve all user stories behind with defined fields populated
     *
     * @param fieldNamesSet
     * @param flowStep
     *
     * @return
     */
    public static List<User_Story__c> getUserStoriesFromFieldsetBehind(Set<String> fieldNamesSet, Deployment_Flow_Step__c flowStep) {
        Map<Id, List<Promoted_User_Story__c>> userStoriesWithPromotions = getPromotedUserStoriesUSBehind(
            flowStep.Destination_Environment__c,
            flowStep.Deployment_Flow__c
        );
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsFromFieldsetWithoutSharing(fieldNamesSet, 'User_Story__c');
        Map<Id, Map<Id, RebaseSelectionsWrapper>> usBehind = calculateUserStoriesBehind(
            userStoriesWithPromotions,
            new List<Deployment_Flow_Step__c>{ flowStep }
        );
        getUSListBehind(usBehind.keySet());
        return usBehindList;
    }

    /**
     * It is used to retrieve all user stories ahead with defined fields populated
     *
     * @param fieldNamesSet
     * @param flowStep
     *
     * @return
     */
    public static List<User_Story__c> getUserStoriesFromFieldsetAhead(Set<String> fieldNamesSet, Deployment_Flow_Step__c flowStep) {
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsFromFieldsetWithoutSharing(fieldNamesSet, 'User_Story__c');
        getUSListAhead(flowStep);
        return usAheadList;
    }

    /**
     * It is used to retrieve all user stories ahead with all fields populated
     *
     * @param flowStep
     *
     * @return
     */
    public static List<User_Story__c> getUserStoriesAhead(Deployment_Flow_Step__c flowStep) {
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsWithoutSharing('User_Story__c');
        getUSListAhead(flowStep);
        return usAheadList;
    }

    /**
     *
     *
     * @param userStoryId
     * @param otherFields
     *
     * @return
     */
    public static deploymentFlowDetails getUserStoryDeploymentFlowDetails(String userStoryId, String otherFields) {
        Id deploymentFlowId = null;
        User_Story__c us = new User_Story__c();
        if (String.isNotBlank(userStoryId) && Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            us = [SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE Id = :userStoryId];
        }
        deploymentFlowId = us.Project__r.Deployment_Flow__c != null
            ? us.Project__r.Deployment_Flow__c
            : us.Release__r.Project__r.Deployment_Flow__c != null ? us.Release__r.Project__r.Deployment_Flow__c : null;
        return deploymentFlowId != null ? getDeploymentFlowDetails(deploymentFlowId, otherFields) : new deploymentFlowDetails();
    }

    /**
     *
     *
     * @param recordId
     * @param otherFields
     *
     * @return
     */
    public static deploymentFlowDetails getDeploymentFlowDetails(String recordId, String otherFields) {
        deploymentFlowDetails details = new deploymentFlowDetails();
        details.flow = (Deployment_Flow__c) queryAllfieldsWithoutSharing('Deployment_Flow__c', recordId, otherFields);
        details.isCBMFlow = (details.flow.Git_Repository__c != null && details.flow.Main_Branch__c != null);
        return details;
    }

    public class deploymentFlowDetails {
        public Boolean isCBMFlow { get; set; }
        public Deployment_Flow__c flow { get; set; }
        public deploymentFlowDetails() {
            this.isCBMFlow = false;
            this.flow = null;
        }
    }

    /**
     *
     *
     * @param sObjectName object name in String, namespace is not needed
     * @param recordId
     * @param otherFields
     *
     * @return
     */
    public static SObject queryAllfieldsWithoutSharing(String sObjectName, String recordId, String otherFields) {
        recordId = EncodingUtil.urlEncode(recordId, 'UTF-8');
        fieldsMap = new Map<String, String>();
        fieldsMap = getAllFieldsWithoutSharing(sObjectName);
        String additionalFields = String.isNotBlank(otherFields) ? ', ' + otherFields : '';
        String fieldsString = !fieldsMap.get(Label.FIELDS).containsIgnoreCase(otherFields)
            ? fieldsMap.get(Label.FIELDS) + additionalFields
            : fieldsMap.get(Label.FIELDS);
        String queryString = 'SELECT ' + fieldsString + ' FROM ' + fieldsMap.get(Label.OBJECT) + ' WHERE Id =:recordId';

        List<SObject> sObjectList = Database.query(queryString);
        return !sObjectList.isEmpty() ? sObjectList.get(0) : null;
    }

    /**
     *
     *
     * @param sObjectName object name in String, namespace is not needed
     *
     * @return
     */
    private static Boolean objectNameValidations(String sObjectName) {
        String namespace = Settings.ns;
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME && (String.isBlank(namespace) || !sObjectName.startsWith(namespace))) {
            validsObjectName = namespace + sObjectName;
        }
        return Schema.getGlobalDescribe().containsKey(validsObjectName) ? true : false;
    }

    /**
     * It will fill the fields and object map of a given sobject name
     *
     * @param fieldNamesSet if fieldnameset is defined, it will fill the map fields by using set
     * @param sObjectName object name in String, namespace is not needed
     */
    private static void getResultMap(Set<String> fieldNamesSet, String sObjectName) {
        resultMap = new Map<String, String>();
        String allfields = '';
        Set<String> accessibleFields = new Set<String>();
        if (fieldNamesSet == null) {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe()
                .get(sObjectName)
                .getDescribe()
                .SObjectType.getDescribe()
                .fields.getMap();
            for (Schema.SObjectField field : fields.values()) {
                accessibleFields.add(field.getDescribe().getName().toLowerCase());
            }
        } else {
            accessibleFields.addAll(fieldNamesSet);
        }

        String namespace = Settings.ns;
        if (sObjectName.containsIgnoreCase(namespace + 'user_story__c')) {
            List<String> necessaryFields = new List<String>{
                'Has_Apex_Code__c',
                'Environment__c',
                'Project__r.Name',
                'Release__r.Name',
                'Org_Credential__r.Org_Type__c'
            };
            for (String str : necessaryFields) {
                String fieldWithNs = namespace + str;
                if (!accessibleFields.contains(fieldWithNs.toLowerCase())) {
                    accessibleFields.add(namespace + str);
                }
            }
        }

        List<String> accessibleFieldsList = new List<String>();
        accessibleFieldsList.addAll(accessibleFields);
        allfields = String.join(accessibleFieldsList, ',');
        resultMap.put(Label.OBJECT, sObjectName);
        resultMap.put(Label.FIELDS, allfields);
    }

    /**
     * It will retrieve all fields of a given sobject name
     *
     * @param sObjectName object name in String, namespace is not needed
     *
     * @return returning map of object and fields
     */
    public static Map<String, String> getAllFieldsWithoutSharing(String sObjectName) {
        Boolean valid = objectNameValidations(sObjectName);
        sObjectName = validsObjectName == null ? sObjectName : validsObjectName;
        //System.debug(LoggingLevel.INFO, '***getAllFieldsWithoutSharing:::sObjectName :' + sObjectName);
        getResultMap(null, sObjectName);
        return !valid ? null : resultMap;
    }

    /**
     * It will retrieve all fields of a given sobject name and field name set
     *
     * @param fieldNamesSet field name set in String
     * @param sObjectName object name in String, namespace is not needed
     *
     * @return returning map of object and fields
     */
    public static Map<String, String> getAllFieldsFromFieldsetWithoutSharing(Set<String> fieldNamesSet, String sObjectName) {
        Boolean valid = objectNameValidations(sObjectName);
        sObjectName = validsObjectName == null ? sObjectName : validsObjectName;
        getResultMap(fieldNamesSet, sObjectName);
        return !valid ? null : resultMap;
    }

    /**
     * It will return user story object with all fields by using given record id
     *
     * @param recordId user story Id in String format
     *
     * @return
     */
    public static User_Story__c getUserStoryById(String recordId) {
        SObject so = GlobalUtilities.queryAllfieldsWithoutSharing('User_Story__c', recordId, 'Org_Credential__r.Org_Type__c');
        return so == null ? null : (User_Story__c) so;
    }

    /**
     * Method to update the User Story Base Branch field.
     *
     * @param userStoryId
     * @param baseBranch
     */
    public static void updateUserStoryBaseBranch(Id userStoryId, String baseBranch) {
        if (!String.isBlank(baseBranch)) {
            User_Story__c userStory;
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                for (User_Story__c us : [SELECT Id, Base_Branch__c FROM User_Story__c WHERE Id = :userStoryId LIMIT 1]) {
                    userStory = us;
                }
            }
            if (userStory != null) {
                if (Schema.SObjectType.User_Story__c.fields.Base_Branch__c.isUpdateable()) {
                    userStory.Base_Branch__c = baseBranch;
                    Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, Schema.SObjectType.User_Story__c);
                }
            }
        }
    }

    public class flowStepWrapper {
        public String style { get; set; }
        public String environment { get; set; }

        public flowStepWrapper(String s, String e) {
            this.style = s;
            this.environment = e;
        }
    }

    /**
     *
     *
     * @param projectDeploymentFlow
     * @param releaseDeploymentFlow
     *
     * @return
     */
    public static String getFlowId(String projectDeploymentFlow, String releaseDeploymentFlow) {
        return String.isNotBlank(projectDeploymentFlow)
            ? projectDeploymentFlow
            : String.isNotBlank(releaseDeploymentFlow) ? releaseDeploymentFlow : '';
    }

    /**
     * It is used to get commit counts for given user stories
     *
     * @param userStoryId
     *
     * @return
     */
    public static Integer getCommitCount(Id userStoryId) {
        Integer commitCount = 0;
        if (Schema.SObjectType.User_Story_Commit__c.isQueryable() && Schema.SObjectType.User_Story_Commit__c.isAccessible()) {
            commitCount = [SELECT COUNT() FROM User_Story_Commit__c WHERE User_Story__c = :userStoryId AND Snapshot_Commit__r.Status__c = 'Complete'];
        }
        return commitCount;
    }

    /**
     * It is used to find deployment flow and steps based on given user story environment
     *
     * @param userStory
     *
     * @return
     */
    public static List<flowStepWrapper> getDeploymentFlowSteps(User_Story__c userStory) {
        List<flowStepWrapper> visualFlowSteps = new List<flowStepWrapper>();
        Map<Id, String> envNames = new Map<Id, String>(); // Env.Id, Env.Name
        Map<Id, String> envBranches = new Map<Id, String>(); // Env.Id, Branch Name
        Map<Id, Id> envIds = new Map<Id, Id>(); // SourceEnv.Id, DestinationEnv.Id
        String flowId = '';
        targetBranch = '';

        Deployment_Flow_Step__c flowStep = new Deployment_Flow_Step__c();

        if (String.isNotBlank(userStory.Environment__c) && (String.isNotBlank(userStory.Project__c) || String.isNotBlank(userStory.Release__c))) {
            flowId = getFlowId(userStory.Project__r.Deployment_Flow__c, userStory.Release__r.Project__r.Deployment_Flow__c);
            if (
                String.isNotBlank(userStory.Release__r.Base_Branch__c) &&
                String.isNotBlank(userStory.Base_Branch__c) &&
                userStory.Release__r.Base_Branch__c != userStory.Base_Branch__c
            ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_BASE_BRANCH_CONFLICT));
            }

            if (String.isNotBlank(flowId)) {
                List<String> extraFields = new List<String>();
                String namespace = Settings.ns;
                extraFields.add(namespace + 'Git_Repository__r.Pull_Request_Base_URL__c');
                extraFields.add(namespace + 'Git_Repository__r.Git_Provider__c');
                deploymentFlowDetails flowDetails = getDeploymentFlowDetails(flowId, String.join(extraFields, ', '));

                if (!flowDetails.flow.Active__c) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DF_Inactive));
                }

                baseUrl = flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c != null
                    ? flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c
                    : '';
                provider = flowDetails.flow.Git_Repository__r.Git_Provider__c != null ? flowDetails.flow.Git_Repository__r.Git_Provider__c : '';

                for (Deployment_Flow_Step__c step : [
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
                    WHERE Deployment_Flow__c = :flowDetails.flow.Id
                ]) {
                    if (step.Source_Environment__c != null) {
                        envNames.put(step.Source_Environment__c, step.Source_Environment__r.Name);
                        envBranches.put(step.Source_Environment__c, step.Branch__c);
                        envIds.put(step.Source_Environment__c, step.Destination_Environment__c);
                        if (step.Source_Environment__c == userStory.Environment__c) {
                            flowStep = step;
                        }
                    }
                    if (step.Destination_Environment__c != null) {
                        envNames.put(step.Destination_Environment__c, step.Destination_Environment__r.Name);
                    }
                }

                // Determine the path of environments prior to the current environment
                Map<Id, Promoted_User_Story__c> promotedUserStories = new Map<Id, Promoted_User_Story__c>(); // <Destination Environment Id, Promoted_User_Story__c>
                if (Schema.SObjectType.Promoted_User_Story__c.isQueryable() && Schema.SObjectType.Promoted_User_Story__c.isAccessible()) {
                    for (Promoted_User_Story__c pus : [
                        SELECT
                            Id,
                            Promotion__r.Source_Environment__c,
                            Promotion__r.Source_Environment__r.Name,
                            Promotion__r.Destination_Environment__c
                        FROM Promoted_User_Story__c
                        WHERE
                            User_Story__c = :userStory.Id
                            AND Promotion__r.Back_Promotion__c != true
                            AND Promotion__r.Source_Environment__c != null
                            AND Promotion__r.Destination_Environment__c != null
                            AND Promotion__r.Status__c = 'Completed'
                        ORDER BY CreatedDate
                    ]) {
                        if (!promotedUserStories.containsKey(pus.Promotion__r.Destination_Environment__c)) {
                            promotedUserStories.put(pus.Promotion__r.Destination_Environment__c, pus);
                        }
                    }
                }
                // Add the Environments to the User Story Path
                if (envNames.get(userStory.Environment__c) != null) {
                    Id currentEnvironmentId = userStory.Environment__c;

                    // Iterate through the environments of the Deployment Flow Steps to get the future Environments
                    Integer currentStep = 0;
                    Integer futureEnvironments = 0;
                    if (envIds.get(currentEnvironmentId) != null) {
                        while (currentStep <= envNames.size()) {
                            if (envIds.get(currentEnvironmentId) != null) {
                                Id destinationId = envIds.get(currentEnvironmentId);
                                if (destinationId != null && envBranches.containsKey(destinationId)) {
                                    targetBranch = String.isBlank(targetBranch) ? envBranches.get(destinationId) : targetBranch;
                                } else {
                                    targetBranch = String.isBlank(targetBranch) ? flowDetails.flow.Main_Branch__c : targetBranch;
                                }
                                if (envNames.get(destinationId) != null) {
                                    visualFlowSteps.add(new flowStepWrapper('slds-is-incomplete', envNames.get(destinationId)));
                                    futureEnvironments++;
                                }
                                currentEnvironmentId = destinationId;
                            }
                            currentStep += 1;
                        }
                    }

                    // Add the current environment
                    if (futureEnvironments > 0) {
                        visualFlowSteps.add(0, new flowStepWrapper('slds-is-current', envNames.get(userStory.Environment__c)));
                    } else {
                        visualFlowSteps.add(new flowStepWrapper('slds-is-complete slds-is-won', envNames.get(userStory.Environment__c)));
                    }

                    // Iterate through the promotedUserStories to get the past Environments
                    Id destinationEnvironmentId = userStory.Environment__c;
                    while (promotedUserStories.get(destinationEnvironmentId) != null) {
                        visualFlowSteps.add(
                            0,
                            new flowStepWrapper(
                                'slds-is-complete',
                                promotedUserStories.get(destinationEnvironmentId).Promotion__r.Source_Environment__r.Name
                            )
                        );
                        destinationEnvironmentId = promotedUserStories.get(destinationEnvironmentId).Promotion__r.Source_Environment__c;
                    }
                }

                if (flowDetails.isCBMFlow && flowStep != null) {
                    Set<String> userStoryFieldNameSet = new Set<String>{ 'Id', 'Name', Settings.ns + 'User_Story_Title__c' };

                    List<User_Story__c> userStoriesAhead = GlobalUtilities.getUserStoriesFromFieldsetAhead(userStoryFieldNameSet, flowStep);
                    List<User_Story__c> userStoriesBehind = new List<User_Story__c>();

                    if (
                        userStory.Org_Credential__c != null && String.isNotBlank(userStory.Org_Credential__r.Org_Type__c) &&
                        !userStory.Org_Credential__r.Org_Type__c.contains('Scratch Org')
                    ) {
                        userStoriesBehind = GlobalUtilities.getUserStoriesFromFieldsetBehind(userStoryFieldNameSet, flowStep);
                        userStoriesAheadBehindTitle = ' - ' + userStoriesAhead.size() + ' ahead, ' + userStoriesBehind.size() + ' behind';
                    } else {
                        userStoriesBehind = new List<User_Story__c>();
                        userStoriesAheadBehindTitle = ' - ' + userStoriesAhead.size() + ' ahead';
                    }
                    Boolean isUserStoryAhead = false;
                    Map<Id, User_Story__c> userStoryMap = new Map<Id, User_Story__c>(userStoriesAhead);
                    if (userStoryMap.keySet().contains(userStory.Id)) {
                        isUserStoryAhead = true;
                    }
                }
            }
        }
        return visualFlowSteps;
    }

    public class RebaseSelectionsWrapper {
        public String rebaseEnv { get; set; }
        public String rebaseUs { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean isAvailable { get; set; }
        public rebaseSelectionsWrapper(String rebaseEnv, String rebaseUs, Boolean isSelected, Boolean isAvailable) {
            this.rebaseEnv = rebaseEnv;
            this.rebaseUs = rebaseUs;
            this.isSelected = isSelected;
            this.isAvailable = isAvailable;
        }
    }
}