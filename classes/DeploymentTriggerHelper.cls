public with sharing class DeploymentTriggerHelper {
    private static List<Promotion__c> promosToComplete = new List<Promotion__c>();
    private static List<Build_Task__c> buildTasks = new List<Build_Task__c>();
    private static Set<Id> checkOnly = new Set<Id>();
    private static Map<String, Build_Task__c> taskMap = new Map<String, Build_Task__c>();
    private static Set<Id> promotionUSSet = new Set<Id>();
    private static Map<String, Org__c> orgMap = new Map<String, Org__c>();
    private static List<Deployment_History__c> history = new List<Deployment_History__c>();
    public static Map<Id, Id> deploymentIdsByPromotiondIds;
    public static Map<Id, Promotion__c> deploymentPromotionsByDeploymentIds;
    public static Map<Id, Id> deploymentFlowIdsByPromotionIds;
    public static Map<Id, Deployment_Flow__c> deploymentFlowsByDeploymentFlowIds;
    private static Map<Id, Set<Step__c>> stepsPerDeployment = new Map<Id, Set<Step__c>>();
    private static Set<Step__c> stepsToUpdate = new Set<Step__c>();
    private static Boolean promotionsUpdated { get; set; }
    private static Map<Id, User_Story__c> userStoryByIds = new Map<Id, User_Story__c>();
    private static Map<Id, Environment__c> environmentByIds = new Map<Id, Environment__c>();

    public static void prepareData() {
        System.debug('### Deployment prepareData');
        Set<Id> promotionIds = new Set<Id>();
        deploymentIdsByPromotiondIds = new Map<Id, Id>(); // Promotion__c.Id, Deployment__c.Id
        deploymentPromotionsByDeploymentIds = new Map<Id, Promotion__c>(); // Deployment__c.Id, Promotion__c
        deploymentFlowIdsByPromotionIds = new Map<Id, Id>(); // Promotion__c.Id, Deployment_Flow__c.Id
        deploymentFlowsByDeploymentFlowIds = new Map<Id, Deployment_Flow__c>(); // Deployment_Flow__c.Id, Deployment_Flow__c

        if (Trigger.new != null) {
            for (SObject sObjects : Trigger.new) {
                Deployment__c deployment = (Deployment__c) sObjects;
                if (deployment.Promotion__c != null) {
                    promotionIds.add(deployment.Promotion__c);
                    deploymentIdsByPromotiondIds.put(deployment.Promotion__c, deployment.Id);
                }
                if (deployment.Build_Task__c != null) {
                    taskMap.put(deployment.Build_Task__c, null);
                }
                if (deployment.From_Org__c != null) {
                    orgMap.put(deployment.From_Org__c, null);
                }
            }

            for (Promotion__c promotion : [
                SELECT
                    Release__r.Project__r.Deployment_Flow__c,
                    Project__r.Deployment_Flow__c,
                    Status__c,
                    (SELECT User_Story__c FROM Promoted_User_Stories__r)
                FROM Promotion__c
                WHERE Id IN :promotionIds
            ]) {
                if (promotion.Release__r.Project__r.Deployment_Flow__c != null) {
                    deploymentFlowIdsByPromotionIds.put(promotion.Id, promotion.Release__r.Project__r.Deployment_Flow__c);
                }
                if (promotion.Project__r.Deployment_Flow__c != null) {
                    deploymentFlowIdsByPromotionIds.put(promotion.Id, promotion.Project__r.Deployment_Flow__c);
                }
                if (promotion.Project__r.Deployment_Flow__c != null || promotion.Release__r.Project__r.Deployment_Flow__c != null) {
                    deploymentPromotionsByDeploymentIds.put(deploymentIdsByPromotiondIds.get(promotion.Id), promotion);
                }

                for (Promoted_User_Story__c promotedUserStory : promotion.Promoted_User_Stories__r) {
                    promotionUSSet.add(promotedUserStory.User_Story__c);
                }
            }

            for (Deployment_Flow__c deploymentFlow : [
                SELECT Active__c, Git_Repository__c, Main_Branch__c
                FROM Deployment_Flow__c
                WHERE Id IN :deploymentFlowIdsByPromotionIds.values()
            ]) {
                if (deploymentFlow != null) {
                    deploymentFlowsByDeploymentFlowIds.put(deploymentFlow.Id, deploymentFlow);
                }
            }
        }

        if (Trigger.old != null) {
            //For re-run deployments, we need to reset the manual step notifications
            for (Step__c step : [SELECT Id, Manual_Task_Notified__c, Deployment__c FROM Step__c WHERE Deployment__c IN :Trigger.old]) {
                if (stepsPerDeployment.containsKey(step.Deployment__c)) {
                    Set<Step__c> steps = stepsPerDeployment.get(step.Deployment__c);
                    steps.add(step);
                    stepsPerDeployment.put(step.Deployment__c, steps);
                } else {
                    Set<Step__c> steps = new Set<Step__c>();
                    steps.add(step);
                    stepsPerDeployment.put(step.Deployment__c, steps);
                }
            }

            for (SObject so : Trigger.old) {
                Deployment__c d = (Deployment__c) so;
                if (d.From_Org__c != null) {
                    orgMap.put(d.From_Org__c, null);
                }
            }
        }

        if (!taskMap.isEmpty()) {
            for (Build_Task__c bt : [
                SELECT Id, Continuous_Integration__r.Post_Success_Deployment_Jobs__c, Continuous_Integration__r.Post_Failed_Deployment_Jobs__c
                FROM Build_Task__c
                WHERE Id IN :taskMap.keySet()
            ]) {
                taskMap.put(bt.id, bt);
            }
        }

        if (!orgMap.isEmpty()) {
            for (Org__c org : [SELECT Id, Name, Environment__r.Org_ID__c FROM Org__c WHERE Id IN :orgMap.keySet()]) {
                orgMap.put(org.id, org);
            }
        }
    }

    public static void canDeployThis(Deployment__c d) {
        if (LicenseHelper.isLicensesExceeded()) {
            d.addError(Label.LICENSES_EXCEEDED);
        }
        if (d.Promotion__c != null && (LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled())) {
            Boolean isActiveFlow = false;
            Boolean isCCMFlow = false;
            Boolean isValidCBMFlow = false;
            if (
                deploymentFlowIdsByPromotionIds.containsKey(d.Promotion__c) &&
                deploymentFlowsByDeploymentFlowIds.containsKey(deploymentFlowIdsByPromotionIds.get(d.Promotion__c)) &&
                deploymentFlowsByDeploymentFlowIds.get(deploymentFlowIdsByPromotionIds.get(d.Promotion__c)) != null &&
                deploymentFlowsByDeploymentFlowIds.get(deploymentFlowIdsByPromotionIds.get(d.Promotion__c)).Active__c
            ) {
                isActiveFlow = true;
            }

            if (isActiveFlow) {
                Deployment_Flow__c df = deploymentFlowsByDeploymentFlowIds.get(deploymentFlowIdsByPromotionIds.get(d.Promotion__c));
                if (df.Git_Repository__c == null && df.Main_Branch__c == null) {
                    isCCMFlow = true;
                } else if (df.Git_Repository__c != null && df.Main_Branch__c != null) {
                    isValidCBMFlow = true;
                }

                if (LicenseHelper.isCopadoEnabled() && !isCCMFlow && !isValidCBMFLow) {
                    d.addError(Label.CBM_FLOW_INVALID);
                }
                if (!LicenseHelper.isCopadoEnabled() && isCCMFlow) {
                    d.addError(Label.CBM_FLOW_INVALID);
                }
            } else {
                d.addError(Label.PROMOTION_FLOW_INACTIVE);
            }
        } else if (!LicenseHelper.isCopadoEnabled()) {
            d.addError(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        }
    }

    public static void getValidateOnlyDeployments(Set<Id> ids) {
        for (Step__c sItem : [SELECT Deployment__c FROM Step__c WHERE Deployment__c IN :ids AND CheckOnly__c = TRUE]) {
            // add deployment ids with check only steps, to prevent the promotion of all users stories upon vaildations
            checkOnly.add(sItem.Deployment__c);
        }
    }

    public static void checkPromotionCompleteness(Deployment__c oldd, Deployment__c newd) {
        System.debug('### checkPromotionCompleteness');
        Promotion__c promotion = deploymentPromotionsByDeploymentIds.get(newd.Id);
        if (promotion != null) {
            String promotionStatus = promotion.Status__c;
            //below condition is added to seperate ccd deployments from user story validations
            Boolean isRegularDeployment = (checkOnly.isEmpty() || !checkOnly.contains(newd.Id));

            if (
                isRegularDeployment &&
                !String.isBlank(newd.Promotion__c) &&
                oldd.Status__c != 'Completed Successfully' &&
                newd.Status__c == 'Completed Successfully'
            ) {
                promotion.Status__c = 'Completed';
            } else if (
                isRegularDeployment &&
                !String.isBlank(newd.Promotion__c) &&
                oldd.Status__c != 'Completed with Errors' &&
                newd.Status__c == 'Completed with Errors'
            ) {
                promotion.Status__c = 'Completed with errors';
            } else if (
                !isRegularDeployment &&
                !String.isBlank(newd.Promotion__c) &&
                oldd.Status__c != 'Completed Successfully' &&
                newd.Status__c == 'Completed Successfully'
            ) {
                promotion.Status__c = 'Validated';
            } else if (
                !isRegularDeployment &&
                !String.isBlank(newd.Promotion__c) &&
                oldd.Status__c != 'Completed with Errors' &&
                newd.Status__c == 'Completed with Errors'
            ) {
                promotion.Status__c = 'Validation failed';
            } else if (!String.isBlank(newd.Promotion__c) && oldd.Status__c != 'In progress' && newd.Status__c == 'In progress') {
                promotion.Status__c = 'In Progress';
            }
            System.debug('### promotionStatus: ' + promotion.Status__c);
            if (promotionStatus != promotion.Status__c) {
                promosToComplete.add(promotion);
            }
        }
    }

    public static void checkBuildTaskCompleteness(Deployment__c oldd, Deployment__c newd) {
        system.debug('### THIS DEPLOYMENT: ' + newd);
        if (!String.isBlank(newd.Build_Task__c)) {
            system.debug('### THIS DEPLOYMENT HAS BUILD TASK: ' + newd.Build_Task__c);
            if (
                oldd.Status__c != 'Completed Successfully' &&
                newd.Status__c == 'Completed Successfully' &&
                taskMap.containsKey(newd.Build_Task__c) &&
                taskMap.get(newd.Build_Task__c).Continuous_Integration__r.Post_Success_Deployment_Jobs__c == null
            ) {
                system.debug('### CREATING BUILD TASK FOR SUCCESS: ' + newd.Build_Task__c);
                Build_Task__c ci = new Build_Task__c();
                ci.Id = newd.Build_Task__c;
                ci.Status__c = 'Success';
                buildTasks.add(ci);
            }
            if (
                oldd.Status__c != 'Completed with Errors' &&
                newd.Status__c == 'Completed with Errors' &&
                taskMap.containsKey(newd.Build_Task__c) &&
                taskMap.get(newd.Build_Task__c).Continuous_Integration__r.Post_Failed_Deployment_Jobs__c == null
            ) {
                system.debug('### CREATING BUILD TASK FOR FAILED: ' + newd.Build_Task__c);
                Build_Task__c ci = new Build_Task__c();
                ci.Id = newd.Build_Task__c;
                ci.Status__c = 'Failed';
                buildTasks.add(ci);
            }
        }
    }

    public static void updateEnvironmentStatus(List<Deployment__c> newList, Map<Id, Deployment__c> oldMap) {
        if (oldMap == null) {
            return;
        }
        //merge conflict added for showing it on the deployment activity screen
        List<String> desiredStatuses = new List<String>{ 'Merge Conflict', 'In progress', 'Completed with Errors', 'Completed Successfully' };
        Set<Id> depIds = new Set<Id>();
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>();
        Map<Id, Deployment__c> envWithDeployment = new Map<Id, Deployment__c>();
        for (Deployment__c thisDeployment : newList) {
            deploymentMap.put(thisDeployment.Id, thisDeployment);
            Deployment__c oldDeployment = oldMap.get(thisDeployment.Id);
            if (
                desiredStatuses.contains(thisDeployment.Status__c) &&
                (thisDeployment.Status__c != oldDeployment.Status__c ||
                thisDeployment.Paused__c != oldDeployment.Paused__c)
            ) {
                depIds.add(thisDeployment.Id);
            }
        }

        if (depIds.isEmpty()) {
            return;
        }

        List<Destination_Org__c> destinationOrgs = [
            SELECT Deployment__r.Status__c, To_Org__r.Environment__c
            FROM Destination_Org__c
            WHERE Deployment__c IN :depIds AND To_Org__r.Environment__c != null
        ];
        for (Destination_Org__c doItem : destinationOrgs) {
            envWithDeployment.put(doItem.To_Org__r.Environment__c, deploymentMap.get(doItem.Deployment__c));
        }

        Boolean isPausedValueExist = false;
        Schema.DescribeFieldResult fieldResult = Environment__c.Latest_Deployment_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry key : ple) {
            if (key.getValue() == 'Paused') {
                isPausedValueExist = true;
                break;
            }
        }

        List<Environment__c> envList = [
            SELECT Latest_Deployment__c, Latest_Deployment_Status__c
            FROM Environment__c
            WHERE Id IN :envWithDeployment.keySet()
        ];
        for (Environment__c env : envList) {
            Deployment__c thisDeployment = envWithDeployment.get(env.Id);
            if (thisDeployment != null) {
                env.Latest_Deployment__c = thisDeployment.Id;
                env.Latest_Deployment_Status__c = thisDeployment.Paused__c && isPausedValueExist ? 'Paused' : thisDeployment.Status__c;
                environmentByIds.put(env.Id, env);
            }
        }

        /*if (!envList.isEmpty()) {
            Utilities.Secure_DML(envList, Utilities.DML_Action.UPD, Schema.SObjectType.Environment__c);
        }*/
    }

    public static void updateBuildTasks() {
        system.debug('### Updating build tasks for Deployment Trigger: ' + buildTasks);
        if (!buildTasks.isEmpty()) {
            Utilities.Secure_DML(buildTasks, Utilities.DML_Action.UPD, schema.Sobjecttype.Build_Task__c);
        }
    }

    public static void completePromotions() {
        System.debug('### completePromotions');
        if (promotionsUpdated == null) {
            promotionsUpdated = false;
        }
        if (!promotionsUpdated && promosToComplete.size() > 0) {
            System.debug('### promotionsUpdated');
            promotionsUpdated = true;
            Utilities.Secure_DML(promosToComplete, Utilities.DML_Action.UPD, schema.Sobjecttype.Promotion__c);
        }
    }

    public static void addHistory(Deployment__c d, String event) {
        history.add(
            new Deployment_History__c(
                Deployment_Id__c = d.Id,
                Deployment__c = (event == 'Deleted' ? null : d.Id),
                Date__c = System.now(),
                Event__c = event,
                Object__c = 'Deployment',
                User__c = UserInfo.getUserId()
            )
        );
    }

    public static void addHistory(Deployment__c oldd, Deployment__c newd) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Deployment__c.fields.getMap();
        for (String field : fieldMap.keyset()) {
            DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
            if (dfr.isUpdateable()) {
                if (oldd.get(field) != newd.get(field)) {
                    Deployment_History__c h = new Deployment_History__c(
                        Deployment__c = oldd.Id,
                        Deployment_Id__c = oldd.Id,
                        Date__c = System.now(),
                        Event__c = 'Updated',
                        Object__c = 'Deployment',
                        Field__c = dfr.getLabel(),
                        User__c = UserInfo.getUserId(),
                        New_Value__c = (newd.get(field) != null ? String.valueOf(newd.get(field)) : null),
                        Old_Value__c = (oldd.get(field) != null ? String.valueOf(oldd.get(field)) : null)
                    );
                    if (String.isNotBlank(h.New_Value__c) && orgMap.containsKey(h.New_Value__c)) {
                        h.New_Value__c = orgMap.get(h.New_Value__c).Name + ' (' + orgMap.get(h.New_Value__c).Environment__r.Org_ID__c + ')';
                    }
                    if (String.isNotBlank(h.Old_Value__c) && orgMap.containsKey(h.Old_Value__c)) {
                        h.Old_Value__c = orgMap.get(h.Old_Value__c).Name + ' (' + orgMap.get(h.Old_Value__c).Environment__r.Org_ID__c + ')';
                    }
                    history.add(h);
                }
            }
        }
    }

    public static void insertHistory() {
        if (!history.isEmpty()) {
            Utilities.Secure_DML(history, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_History__c);
            history.clear();
        }
    }

    public static void cleanManualTaskNotifications(Deployment__c oldDeployment, Deployment__c newDeployment) {
        //When a deployment starts...
        if (oldDeployment.Status__c != 'In Progress' && newDeployment.Status__c == 'In Progress') {
            if (stepsPerDeployment.containsKey(oldDeployment.Id)) {
                stepsToUpdate.addAll(stepsPerDeployment.get(oldDeployment.Id));
            }
        }
    }

    public static void updateSteps() {
        if (!stepsToUpdate.isEmpty()) {
            for (Step__c step : stepsToUpdate) {
                step.Manual_Task_Notified__c = false;
            }
            Utilities.Secure_DML(new List<Step__c>(stepsToUpdate), Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        }
    }

    public static void updateDeploymentLookupOnUS(Deployment__c deployment) {
        // all user stories in promotion will be updated
        // it will only update user story last validation deployment lookup if deployment have checkonly checked in the steps.
        for (Id usId : promotionUSSet) {
            if (checkOnly.contains(deployment.Id)) {
                User_Story__c us = new User_Story__c(
                    Id = usId,
                    Last_Validation_Deployment__c = deployment.Id,
                    Last_Validation_Promotion__c = deployment.Promotion__c
                );
                userStoryByIds.put(us.Id, us);
            }
        }
    }

    public static void updateUSs() {
        if (!userStoryByIds.isEmpty()) {
            Utilities.Secure_DML(userStoryByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        }
    }

    public static void updateDeploymentPausedStatus(List<Deployment__c> newList) {
        for (Deployment__c thisDeployment : newList) {
            if (thisDeployment.Paused__c && thisDeployment.Status__c != 'In progress') {
                thisDeployment.Paused__c = false;
            }
        }
    }

    public static void updateEnvironment() {
        if (!environmentByIds.isEmpty()) {
            Utilities.Secure_DML(environmentByIds.values(), Utilities.DML_Action.UPD, Schema.SObjectType.Environment__c);
        }
    }
}