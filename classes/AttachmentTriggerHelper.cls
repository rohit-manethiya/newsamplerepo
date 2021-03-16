public without sharing class AttachmentTriggerHelper {
    //START OF ccd related contant variables
    public static final String PROCESSED = 'Processed';
    //current User api key
    private static final String apiKey = DeployAPI.getUserAPIKey();
    //ccd vars start
    private static final List<String> manualTaskList = new List<String>{ 'Pull Request', 'Manual Approval', 'Manual Test' };
    //END OF ccd related contant variables

    //uniqueIdentifier of each already existing quality gate step to prevent duplicate creation
    @TestVisible
    private static Set<String> duplicateControlSet = new Set<String>();
    private static Set<String> parentQualityGateIds = new Set<String>();
    //list for quality gate steps to be inserted and actual promotion step to be updated
    private static List<Step__c> stepsToUpsert = new List<Step__c>();
    //in use on prepareDataBulkAfter method as an operational flag
    @TestVisible
    private static Boolean stepFlag = false;
    //step Ids to use for attachment wrapper population
    private static Set<Id> sIds = new Set<Id>();
    //deployment Ids to use order calculation
    private static Set<Id> depIds = new Set<Id>();
    //deployment Ids to use for deploy call for the defined Deployments
    private static Set<Id> deploymentIds = new Set<Id>();
    //to skip quality gate creation for same deployment or quality gate
    @TestVisible
    private static Id previousDeploymentId,
        previousQualityGateId;
    //owner Id to be able to start deployment on backend call
    private static Id ownerId;
    //to skip duplicate quality gate creation on metadataGroupItem iteration
    private static Boolean previousStepCreationDecision;

    private static Set<Id> destEnvIds = new Set<Id>();
    @TestVisible
    private static Set<Id> stepIds = new Set<Id>();
    @TestVisible
    private static Set<Id> stepIdsForManual = new Set<Id>();
    //step order with deployment record Id to Actual Promotion Step Id Map
    private static Map<String, Id> orderPlusDeploymentIdOriginalStepIdMap = new Map<String, Id>();
    //deployment Id to related Connection Behavior Map
    private static Map<Id, Id> deploymentIdConnectoinBehaviorIdMap = new Map<Id, Id>();
    //Metadata Group to Metadata Group Item Map
    private static Map<Id, List<Metadata_Group_Item__c>> mgIdMgiListMap = new Map<Id, List<Metadata_Group_Item__c>>();
    //Step Id to Deployment Job record Map
    private static Map<Id, Deployment_Job__c> stepIdDeploymentJobMap = new Map<Id, Deployment_Job__c>();
    private static Map<Id, Connection_Behavior__c> connectionBehaviorMap = new Map<Id, Connection_Behavior__c>();
    //Connection Behavior Id to related Quality Gate List Map
    @TestVisible
    private static Map<Id, List<Quality_Gate__c>> connectoinBehaviorIdQualityGatesMap = new Map<Id, List<Quality_Gate__c>>();
    //selenium webhook url to use on quality gate step
    private static String runSeleniumWebhook = Settings.server_url + '/json/v1/webhook/selenium/TestGroupRun/selenium_group_id?api_key=user_api_key';
    //CCH webhook url to use on quality gate step
    private static String scanCompliancemWebhook =
        Settings.server_url + '/json/v1/webhook/deployment/{deploymentId}/step/{stepOrder}/cch?api_key={user_api_key}';
    //SCA webhook url to use on quality gate step
    private static String staticCodeAnalysisWebhook =
        Settings.server_url + '/json/v1/webhook/deployment/{deploymentId}/step/{stepOrder}/sca?api_key={user_api_key}';
    //END OF - ccs related non contant variables

    public static Set<String> supportedPrefixes = new Set<String>();
    public static Set<String> supportedNames = new Set<String>();
    public static Set<String> supportedMetadataNames = new Set<String>();

    public static List<Copado_Notification__c> upserts = new List<Copado_Notification__c>();
    public static List<User_Story__c> userStoryList = new List<User_Story__c>();
    public static Map<String, Selenium_Locator_Reference__c> locatorReferences = new Map<String, Selenium_Locator_Reference__c>();
    public static Map<String, Selenium_Locator__c> locators = new Map<String, Selenium_Locator__c>();
    public static Set<String> delete_locatorReferences = new Set<String>();

    public static List<Selenium_Locator_Reference__c> slrList {
        get {
            if (null == slrList && !delete_locatorReferences.isEmpty()) {
                slrList = [SELECT Id FROM Selenium_Locator_Reference__c WHERE External_ID__c IN :delete_locatorReferences];
            }
            return slrList;
        }
        set;
    }

    public static Set<Id> userstoryIds = new Set<Id>();
    public static Map<Id, Attachment> scaIdWithAtt = new Map<Id, Attachment>();
    public static Map<Id, Id> deploymentFlowMap = new Map<Id, Id>(); // Deployment_Flow__c.Id, Deployment_Flow_Step__c.Id
    public static Map<Id, Deployment_Flow_Step__c> deploymentFlowStepMap = new Map<Id, Deployment_Flow_Step__c>();
    public static Map<String, List<Step__c>> stepsByExecutionSequence = new Map<String, List<Step__c>>();
    public static Map<String, Integer> stepOrderByExecutionSequence = new Map<String, Integer>();
    public static final String QUALITY_GATE_BEFORE = 'Before';
    public static final String QUALITY_GATE_AFTER = 'After';
    public static String DFS_INSYNC = 'In sync';

    public static Boolean skipCopadoTrigger() {
        try {
            //this is to check if customer running user has access to Copado package
            return !UserInfo.isCurrentUserLicensed('copado');
        } catch (Exception e) {
            System.debug('exception * ' + e);
            //this is BP or Patch org, with namespace but not package installed
            if (e.getMessage().contains('prefix not found')) {
                return false;
            }
        }
        return false;
    }
    public static void prepareData() {
        //prevent non copado users for failing the trigger without access to Copado entities
        if (skipCopadoTrigger()) {
            return;
        }

        supportedPrefixes.add(Deployment_Job__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Snapshot_Difference__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Apex_Test_Result__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Org__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Build_Task__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Git_Backup__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(User_Story__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Git_Repository__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Promotion__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix());

        supportedNames.add('DEPLOYMENT_STATUS_COPADO');
        supportedNames.add('PROGRESS_STATUS_COPADO');
        supportedNames.add('TEST_PROGRESS_STATUS_COPADO');

        supportedMetadataNames.add('MetaData');
        supportedMetadataNames.add('Git MetaData');
        supportedMetadataNames.add('Delete MetaData');
        supportedMetadataNames.add('result.json');

        List<SObject> records = new List<SObject>();
        if (Trigger.isInsert || Trigger.isUpdate) {
            records = Trigger.new;
        }
        if (Trigger.isDelete) {
            records = Trigger.old;
        }

        List<Attachment> castedRecords = (List<Attachment>) records;
        Integer castedRecordsSize = castedRecords.size();
        for (Integer i = 0; i < castedRecordsSize; i++) {
            Attachment att = castedRecords[i];
            if (att.ParentId != null) {
                String parentId = att.ParentId;
                if (
                    (parentId.substring(0, 3) == User_Story__c.SObjectType.getDescribe().getKeyPrefix()) && supportedMetadataNames.contains(att.Name)
                ) {
                    userstoryIds.add(parentId);
                } else if (
                    (parentId.substring(0, 3) == Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix()) &&
                    supportedMetadataNames.contains(att.Name)
                ) {
                    deploymentFlowMap.put(parentId, null);
                } else if (
                    (parentId.substring(0, 3) == Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix()) &&
                    supportedMetadataNames.contains(att.Name)
                ) {
                    deploymentFlowStepMap.put(parentId, new Deployment_Flow_Step__c());
                } else if (parentId.substring(0, 3) == Step__c.SObjectType.getDescribe().getKeyPrefix() && att.Name == 'RetrieveOnly.json') {
                    // condition for automated/scheduled ccd behavior, RetrieveOnly.json is the last attachment created by backend on the step
                    stepIds.add(parentId);
                } else if (parentId.substring(0, 3) == Step__c.SObjectType.getDescribe().getKeyPrefix() && att.Name == 'MetaData') {
                    // condition for manual ccd behaviour and US with basic metadata. Git promotions steps will not pass djList4ManualDeployments
                    if (
                        Trigger.isInsert || (Trigger.isUpdate && ((Attachment) Trigger.new[i]).BodyLength != ((Attachment) Trigger.old[i]).BodyLength)
                    ) {
                        stepIdsForManual.add(parentId);
                    }
                }
            }
        }

        if (!deploymentFlowStepMap.isEmpty() || !deploymentFlowMap.isEmpty()) {
            for (Deployment_Flow_Step__c flowStep : [
                SELECT
                    Id,
                    Name,
                    Commits_Ahead__c,
                    Commits_Behind__c,
                    Deployment_Flow__c,
                    Destination_Branch__c,
                    Merge_Auto_Resolved_Files__c,
                    Pull_Auto_Resolved_Files__c,
                    Sync_Merge_State__c,
                    Sync_Pull_State__c
                FROM Deployment_Flow_Step__c
                WHERE Id IN :deploymentFlowStepMap.keySet() OR Deployment_Flow__c IN :deploymentFlowMap.keySet()
            ]) {
                deploymentFlowMap.put(flowStep.Deployment_Flow__c, flowStep.Id);
                deploymentFlowStepMap.put(flowStep.Id, flowStep);
            }
        }
    }
    public static void prepareAfterData() {
        //prevent non copado users for failing the trigger without access to Copado entities
        if (skipCopadoTrigger()) {
            return;
        }
        //Get SCARecordIds when they are inserted
        if (Trigger.isInsert) {
            scaIdWithAtt = new Map<Id, Attachment>();
            for (SObject o : Trigger.new) {
                Attachment a = (Attachment) o;
                if (a.Name == 'SCAreport.xml') {
                    scaIdWithAtt.put(a.ParentId, a);
                }
            }
        }
    }

    public static void createOrFinishCopadoNotification(Attachment a, Boolean doFinish) {
        String aId = a.ParentId;
        if (supportedPrefixes.contains(aId.substring(0, 3)) && supportedNames.contains(a.Name)) {
            Map<String, Object> fullMap;
            String body;
            try {
                body = a.Body.toString();
                fullMap = (Map<String, Object>) JSON.deserializeUntyped(body);
            } catch (Exception e) {
                System.debug('###ERROR TRYING TO PARSE ATTACHMENT BODY: ' + (a.Body != null ? a.Body.toString() : null));
            }
            Copado_Notification__c cn = new Copado_Notification__c();
            cn.Name = a.Name;
            cn.ParentId__c = a.ParentId;
            cn.AttachmentId__c = a.Id;
            if (fullMap != null) {
                cn.Parent2Id__c = (fullMap.get('parent2id') != null ? (String) fullMap.get('parent2id') : (String) fullMap.get('copadoJobId'));
                cn.Message__c = (body.length() <= 255) ? body : null;
                if (String.isNotBlank((String) fullMap.get('type'))) {
                    cn.Type__c = (String) fullMap.get('type');
                }
            }
            if (doFinish) {
                cn.isFinished__c = true;
                // try to delete the attachment (?)
            }
            upserts.add(cn);
        }
    }

    public static void upsertCopadoNotifications() {
        try {
            Database.upsert(AttachmentTriggerHelper.upserts, Copado_Notification__c.AttachmentId__c, false);
        } catch (Exception e) {
            System.debug('AttachmentTriggerHelper.upserts==> ' + AttachmentTriggerHelper.upserts);
            System.debug(e);
        }
    }

    public static void processSeleniumLocators(Attachment a, Boolean isDelete) {
        if (a.Name.startsWith('Copado.SeleniumTestCase')) {
            Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(a.Body.toString());
            List<Object> commands = (List<Object>) fullMap.get('commands');
            if (commands == null || commands.size() == 0) {
                return;
            }
            Set<String> locator_ids = new Set<String>();
            for (Object o : commands) {
                Map<String, Object> cmd = (Map<String, Object>) o;
                String locator = (String) cmd.get('target');
                if (locator == null || locator == 'null') {
                    continue;
                }
                String page = '';
                Map<String, Object> context = (Map<String, Object>) cmd.get('context');
                if (context != null) {
                    page = (String) context.get('pageref');
                }

                // user-defined locators ( with locator_id ) are treated separatedly.
                if (locator.toLowerCase().startsWith('{!locator.') && locator.endsWith('}')) {
                    locator_ids.add(locator.substring(10, locator.length() - 1));
                } else {
                    String locatorExtId = getLocatorExternalID(page, locator);
                    String referenceExtId = locatorExtId + a.ParentId;
                    if (!isDelete) {
                        locators.put(locatorExtId, new Selenium_Locator__c(Page__c = page, Locator__c = locator, External_ID__c = locatorExtId));
                        locatorReferences.put(
                            referenceExtId,
                            new Selenium_Locator_Reference__c(
                                Selenium_Locator__r = new Selenium_Locator__c(External_ID__c = locatorExtId),
                                Selenium_Test_Case__c = a.ParentId,
                                External_ID__c = referenceExtId
                            )
                        );
                    } else {
                        delete_locatorReferences.add(referenceExtId);
                    }
                }
            }

            // lookup the named locators, and create the corresponding references
            List<Selenium_Locator__c> named_locators = [
                SELECT Id, Locator_ID__c, External_ID__c, Locator__c
                FROM Selenium_Locator__c
                WHERE Locator_ID__c IN :locator_ids
            ];
            for (Selenium_Locator__c named_locator : named_locators) {
                String referenceExtId = named_locator.External_ID__c + a.ParentId;
                if (!isDelete) {
                    locatorReferences.put(
                        referenceExtId,
                        new Selenium_Locator_Reference__c(
                            Selenium_Locator__c = named_locator.Id,
                            Selenium_Test_Case__c = a.ParentId,
                            External_ID__c = referenceExtId
                        )
                    );
                } else {
                    delete_locatorReferences.add(referenceExtId);
                }
            }
        } else {
            System.debug('**** attachment ignored ' + a.Name);
        }
    }

    public static void persistSeleniumLocators() {
        try {
            Database.UpsertResult[] resLocs = Database.upsert(AttachmentTriggerHelper.locators.values(), Selenium_Locator__c.External_ID__c, false);
            Database.UpsertResult[] resRefs = Database.upsert(
                AttachmentTriggerHelper.locatorReferences.values(),
                Selenium_Locator_Reference__c.External_ID__c,
                false
            );
            if (!delete_locatorReferences.isEmpty()) {
                Utilities.Secure_DML(slrList, Utilities.DML_Action.DEL, schema.SObjectType.Selenium_Locator_Reference__c);
            }
        } catch (Exception e) {
            System.debug('**** persistSeleniumLocators error: ' + e);
        }
    }
    public static String getLocatorExternalID(String page, String target) {
        String extId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(page + target)));
        System.debug('**** DEBUG - input ' + page + ' + ' + target + ' = ' + extId);
        return extId;
    }
    public static void processExternalCIDeploymentJobs() {
        Map<String, String> djStats = new Map<String, String>();
        if (Trigger.new == null) {
            return;
        }
        for (Attachment att : (List<Attachment>) Trigger.new) {
            if (
                att.Name.contains('.json') &&
                att.Name.contains(Deployment_Job__c.SObjectType.getDescribe().getKeyPrefix()) &&
                String.valueOf(att.ParentId).contains(Deployment__c.SObjectType.getDescribe().getKeyPrefix())
            ) {
                try {
                    System.debug(LoggingLevel.ERROR, '*** att.Body: ' + att.Body);
                    List<Object> resultsObjectList = (List<Object>) JSON.deserializeUntyped(att.Body.toString());
                    for (Object obj : resultsObjectList) {
                        Map<String, Object> resultItems = (Map<String, Object>) obj;
                        Map<String, Object> stats = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(resultItems.get('m')));
                        djStats.put(att.Name.replace('.json', ''), String.valueOf(stats.get('status')));
                    }
                } catch (Exception e) {
                    System.debug('processExternalCIDeploymentJobs Exception Message >>> ' + e.getMessage());
                }
            }
        }
        List<Deployment_Job__c> deploymentJobsToUpdate = new List<Deployment_Job__c>();
        for (String djId : djStats.keySet()) {
            Deployment_Job__c dj = new Deployment_Job__c(Id = djId, External_Status__c = djStats.get(djId));
            deploymentJobsToUpdate.add(dj);
        }
        if (!deploymentJobsToUpdate.isEmpty()) {
            Utilities.Secure_DML(deploymentJobsToUpdate, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
        }
    }
    public static void processUserStoryMetadata(Attachment a) {
        if (userstoryIds.contains(a.ParentId)) {
            System.debug('##### Start MetadataIndexJob');
            IndexMetadataJob imJob = new IndexMetadataJob();
            imJob.storyIds = new Set<Id>{ a.ParentId };
            Id batchJobId = Database.executeBatch(imJob);
        }
    }
    public static void processDeploymentFlow(Attachment att) {
        try {
            if (att.ParentId != null) {
                String parentId = att.ParentId;
                if (
                    att.Name == 'result.json' &&
                    parentId.substring(0, 3) == Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix() &&
                    deploymentFlowMap.get(att.ParentId) != null
                ) {
                    System.debug('### ProcessDeploymentFlow');
                    String body = att.Body.toString();
                    List<Object> attachmentSteps = (List<Object>) JSON.deserializeUntyped(body);

                    for (Object attachmentStep : attachmentSteps) {
                        // Determine which deployment flow step this is
                        Map<String, Object> attachmentStepAttributes = (Map<String, Object>) attachmentStep;
                        if (deploymentFlowStepMap.get((String) attachmentStepAttributes.get('id')) != null) {
                            Deployment_Flow_Step__c step = deploymentFlowStepMap.get((String) attachmentStepAttributes.get('id'));

                            // Last Merge Base
                            if ((attachmentStepAttributes.get('mergeTimestamp') != null)) {
                                try {
                                    String unixMergeTimestamp = (String) attachmentStepAttributes.get('mergeTimestamp');
                                    if (unixMergeTimestamp != null || unixMergeTimestamp != '')
                                        step.Last_Merge_Base__c = Datetime.newInstance(Long.valueOf(unixMergeTimestamp));
                                } catch (Exception e) {
                                    System.debug('attachmentStepAttributes===> ' + attachmentStepAttributes);
                                    System.debug(e);
                                }
                            }

                            // Destination Branch
                            try {
                                step.Destination_Branch__c = (String) attachmentStepAttributes.get('destinationBranch');
                            } catch (Exception e) {
                                System.debug('step==> ' + step);
                                System.debug(e);
                            }

                            // Commits Ahead and Behind
                            Integer newCommitsAhead = 0;
                            Integer newCommitsBehind = 0;

                            try {
                                if (attachmentStepAttributes.get('commitsAhead') != null)
                                    newCommitsAhead = Integer.valueOf((Decimal) attachmentStepAttributes.get('commitsAhead'));
                                if (attachmentStepAttributes.get('commitsBehind') != null)
                                    newCommitsBehind = Integer.valueOf((Decimal) attachmentStepAttributes.get('commitsBehind'));
                            } catch (Exception e) {
                                System.debug('attachmentStepAttributes===> ' + attachmentStepAttributes);
                                System.debug(e);
                            }

                            if (step.Commits_Ahead__c > 0 && newCommitsAhead == 0) {
                                step.Last_Merge_CBM_Sync__c = Datetime.now();
                            }
                            if (step.Commits_Behind__c > 0 && newCommitsBehind == 0) {
                                step.Last_Pull_CBM_Sync__c = Datetime.now();
                            }

                            step.Commits_Ahead__c = 0;
                            step.Commits_Behind__c = 0;
                            if (newCommitsAhead != null)
                                step.Commits_Ahead__c = newCommitsAhead;
                            if (newCommitsBehind != null)
                                step.Commits_Behind__c = newCommitsBehind;

                            // Merge and Pull Validation Success
                            if (step.Commits_Ahead__c == 0)
                                step.Sync_Merge_State__c = DFS_INSYNC;
                            if (step.Commits_Behind__c == 0)
                                step.Sync_Pull_State__c = DFS_INSYNC;

                            // Merge and Pull Auto Resolved Files
                            if (attachmentStepAttributes.get('filesMergedConflictAhead') != null) {
                                List<Object> filesMergedConflictAhead = (List<Object>) attachmentStepAttributes.get('filesMergedConflictAhead');
                                try {
                                    step.Merge_Auto_Resolved_Files__c = String.join(filesMergedConflictAhead, ',');
                                } catch (Exception e) {
                                    step.Merge_Auto_Resolved_Files__c = '';
                                    System.debug('step==+==> ' + step);
                                    System.debug(e);
                                }
                            } else {
                                step.Merge_Auto_Resolved_Files__c = '';
                            }
                            if (attachmentStepAttributes.get('filesMergedConflictBehind') != null) {
                                List<Object> filesMergedConflictBehind = (List<Object>) attachmentStepAttributes.get('filesMergedConflictBehind');
                                try {
                                    step.Pull_Auto_Resolved_Files__c = String.join(filesMergedConflictBehind, ',');
                                } catch (Exception e) {
                                    step.Pull_Auto_Resolved_Files__c = '';
                                    System.debug('step==*==> ' + step);
                                    System.debug(e);
                                }
                            } else {
                                step.Pull_Auto_Resolved_Files__c = '';
                            }

                            if (step.Commits_Ahead__c == 0 && step.Commits_Behind__c == 0) {
                                step.Pull_Auto_Resolved_Files__c = '';
                                step.Merge_Auto_Resolved_Files__c = '';
                            }

                            System.debug('### stepAfterBeingUpdatedByAttachment: ' + step);
                            Utilities.Secure_DML(step, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow_Step__c);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('att===> ' + att);
            System.debug(e);
        }
    }

    public static void processDeploymentFlowStep(Attachment att) {
        String parentId = att.ParentId;
        if (parentId == null) {
            return;
        } // it might be badly created by java, and this is a before trigger.
        if (att.Body == null) {
            return;
        } // meaning the body was unchanged.

        if (att.Name == 'result.json' && parentId.substring(0, 3) == Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix()) {
            String body = att.Body.toString();
            Map<String, Object> attachmentStepAttributes = (Map<String, Object>) JSON.deserializeUntyped(body);
            Deployment_Flow_Step__c step = deploymentFlowStepMap.get(att.ParentId);
            if (step != null) {
                if (attachmentStepAttributes.containsKey('mergeValidationSuccess')) {
                    step.Sync_Merge_State__c = (Boolean) attachmentStepAttributes.get('mergeValidationSuccess') ? 'Validated' : 'Validation errors';
                }
                if (step.Commits_Ahead__c == 0) {
                    step.Sync_Merge_State__c = DFS_INSYNC;
                }
                if (attachmentStepAttributes.containsKey('pullValidationSuccess')) {
                    step.Sync_Pull_State__c = (Boolean) attachmentStepAttributes.get('pullValidationSuccess') ? 'Validated' : 'Validation errors';
                }
                if (step.Commits_Behind__c == 0) {
                    step.Sync_Pull_State__c = DFS_INSYNC;
                }

                Utilities.Secure_DML(step, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow_Step__c);
            }
        }
    }

    /**
     * It is used to populate apex code coverage fields
     * It is used to populate selected metadata fields and has apex code checkbox
     * It will be working after insert and after update
     * @param att
     */
    public static void populateUserStoryFields(Attachment att) {
        String parentId = att.ParentId;
        Boolean isUserStoryAttachment = false;
        Boolean isUserStoryUpdated = false;

        if (String.isNotBlank(parentId)) {
            isUserStoryAttachment = parentId.substring(0, 3) == User_Story__c.SObjectType.getDescribe().getKeyPrefix() ? true : false;

            if (isUserStoryAttachment) {
                userStoryList = new List<User_Story__c>();
                userStoryList = [
                    SELECT
                        Id,
                        Failing_Methods__c,
                        Apex_Code_Coverage__c,
                        Classes_Without_Coverage__c,
                        Triggers_Without_Coverage__c,
                        Metadata_Types_in_Selection__c,
                        Has_Apex_Code__c
                    FROM User_Story__c
                    WHERE Id = :parentId
                    LIMIT 1
                ];
            }
        }

        if (String.isNotBlank(att.Name) && att.Name == 'ApexTestResult' && !userStoryList.isEmpty()) {
            if (att.Body != null) {
                String body = att.Body.toString();

                Map<String, Object> attachmentAttributes = (Map<String, Object>) JSON.deserializeUntyped(body);

                Decimal failingMethods = attachmentAttributes.containsKey('failingMethods')
                    ? (Decimal) attachmentAttributes.get('failingMethods')
                    : 0;
                Decimal userStoryCoverage = attachmentAttributes.containsKey('userStoryCoverage')
                    ? (Decimal) attachmentAttributes.get('userStoryCoverage')
                    : 0;
                Decimal classesWithoutCoverage = attachmentAttributes.containsKey('classesWithoutCoverage')
                    ? (Decimal) attachmentAttributes.get('classesWithoutCoverage')
                    : 0;
                Decimal triggersWithoutCoverage = attachmentAttributes.containsKey('triggersWithoutCoverage')
                    ? (Decimal) attachmentAttributes.get('triggersWithoutCoverage')
                    : 0;

                userStoryList[0].Failing_Methods__c = failingMethods;
                userStoryList[0].Apex_Code_Coverage__c = userStoryCoverage;
                userStoryList[0].Classes_Without_Coverage__c = classesWithoutCoverage;
                userStoryList[0].Triggers_Without_Coverage__c = triggersWithoutCoverage;

                isUserStoryUpdated = true;
            }
        } else if (String.isNotBlank(att.Name) && (att.Name == 'Git MetaData' || att.Name == 'MetaData') && !userStoryList.isEmpty()) {
            if (att.Body != null) {
                String body = att.Body.toString();

                // to check the existing record to update fields correctly get the other type of the attachment
                String attachmentName = att.Name == 'Git MetaData' ? 'MetaData' : 'Git MetaData';
                List<Attachment> existingAttachment = new List<Attachment>(
                    [SELECT Id, Body FROM Attachment WHERE Name = :attachmentName AND ParentId = :parentId LIMIT 1]
                );

                List<Object> attachmentAttributes = (List<Object>) JSON.deserializeUntyped(body);

                if (!existingAttachment.isEmpty()) {
                    attachmentAttributes.addAll((List<Object>) JSON.deserializeUntyped(existingAttachment[0].Body.toString()));
                }

                Set<String> typeSet = new Set<String>();
                for (Object obj : attachmentAttributes) {
                    Map<String, Object> innerObj = (Map<String, Object>) obj;
                    typeSet.add((String) innerObj.get('t'));
                }

                if (!typeSet.isEmpty()) {
                    List<String> typeList = new List<String>();
                    typeList.addAll(typeSet);
                    userStoryList[0].Metadata_Types_in_Selection__c = String.join(typeList, ';');
                    Boolean hasApexCode = typeSet.contains('ApexClass') || typeSet.contains('ApexTrigger') ? true : false;
                    userStoryList[0].Has_Apex_Code__c = hasApexCode;

                    isUserStoryUpdated = true;
                }
            }
        }

        // to avoid the dummy update clear the list, because there is no change in the user story list
        if (!isUserStoryUpdated && !userStoryList.isEmpty()) {
            userStoryList.clear();
        }
    }

    /**
     * It is used to update us after fields are populated by reading the attachment body
     * Called at AttachmentTriggerHandler andFinally method
     */
    public static void updateUS() {
        if (!userStoryList.isEmpty()) {
            Utilities.Secure_DML(userStoryList, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        }
    }

    /**
     * prepares iteration data and needed maps for CCD calculation & preparation
     * Being called directly from handler
     */
    public static void prepareDataBulkAfter() {
        List<Step__c> qualityGateStepList = new List<Step__c>();
        if (stepFlag) {
            return;
        }
        Boolean manualFlag = false;
        //clause for "Manual" Connection Behavior
        if (!stepIdsForManual.isEmpty()) {
            qualityGateStepList = populateManualCCDVariables(qualityGateStepList);
            if (!qualityGateStepList.isEmpty()) {
                manualFlag = true;
            }
        }
        if (!stepIds.isEmpty() || manualFlag) {
            //clause for "Scheduled/Automated" Connection Behavior
            if (!manualFlag) {
                qualityGateStepList = populateAutomatesScheduledCCDVariables(qualityGateStepList);
            }
            if (deploymentIdConnectoinBehaviorIdMap.size() > 0) {
                populateConnectionBehaviorRelatedMaps();
            }
            processCCDSteps(qualityGateStepList);
        }
    }

    /**
     * Populates needed variables to successfully create Quality Gates steps for Automated and Scheduled CCD logic
     *
     * @return qualityGateStepList to calculate enforced to be Quality Gate steps
     */
    private static List<Step__c> populateAutomatesScheduledCCDVariables(List<Step__c> qualityGateStepList) {
        List<Step__c> allSteps = [
            SELECT
                Id,
                Branch__c,
                Commit_Name__c,
                Commit_Id__c,
                Git_Repository__c,
                Git_Repository__r.Name,
                Order__c,
                CheckOnly__c,
                Status__c,
                Deployment__c,
                Deployment__r.Promotion__r.Back_Promotion__c,
                Deployment__r.Promotion__r.OwnerId,
                Deployment__r.Promotion__r.Destination_Org_Credential__c,
                Deployment__r.Promotion__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                Deployment__r.Promotion__r.Destination_Environment__c,
                Deployment__r.Promotion__r.Destination_Environment__r.Compliance_Rule_Group__c,
                Deployment__r.Promotion__c,
                Deployment__r.Promotion__r.Connection_Behavior__c,
                Name,
                Type__c,
                dataJson__c,
                Manual_Task_Notified__c
            FROM Step__c
            WHERE Id IN :stepIds
            ORDER BY Deployment__c
        ];
        Integer allStepSize = allSteps.size();
        for (Integer i = 0; i < allStepSize; i++) {
            if (
                String.isNotEmpty(allSteps[i].Deployment__r.Promotion__r.Connection_Behavior__c) &&
                !allSteps[i].CheckOnly__c &&
                allSteps[i].Type__c == 'Git Promotion'
            ) {
                deploymentIdConnectoinBehaviorIdMap.put(allSteps[i].Deployment__c, allSteps[i].Deployment__r.Promotion__r.Connection_Behavior__c);
                destEnvIds.add(allSteps[i].Deployment__r.Promotion__r.Destination_Environment__c);
                qualityGateStepList.add(allSteps[i]);
            }
        }
        return qualityGateStepList;
    }

    /**
     * Populates needed variables to successfully create Quality Gates steps for manual CCD logic
     *
     * @return qualityGateStepList to calculate enforced to be Quality Gate steps
     */
    private static List<Step__c> populateManualCCDVariables(List<Step__c> qualityGateStepList) {
        String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
            .get('Metadata Deployment')
            .getRecordTypeId();
        List<Deployment_Job__c> djList4ManualDeployments = [
            SELECT
                Id,
                Destination_Org__c,
                Destination_Org__r.To_Org__c,
                Destination_Org__r.To_Org__r.Environment__c,
                Destination_Org__r.To_Org__r.Environment__r.Connection_Behavior__c,
                Step__r.Branch__c,
                Step__r.Commit_Name__c,
                Step__r.Commit_Id__c,
                Step__r.Git_Repository__c,
                Step__r.Git_Repository__r.Name,
                Step__r.Order__c,
                Step__r.CheckOnly__c,
                Status__c,
                Step__r.Deployment__c,
                Step__r.Deployment__r.Promotion__r.Back_Promotion__c,
                Step__r.Deployment__r.Promotion__r.OwnerId,
                Step__r.Deployment__r.Promotion__r.Destination_Org_Credential__c,
                Step__r.Deployment__r.Promotion__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                Step__r.Deployment__r.Promotion__r.Destination_Environment__c,
                Step__r.Deployment__r.Promotion__r.Destination_Environment__r.Compliance_Rule_Group__c,
                Destination_Org__r.To_Org__r.Environment__r.Compliance_Rule_Group__c,
                Step__r.Deployment__r.Promotion__c,
                Step__r.Deployment__r.Promotion__r.Connection_Behavior__c,
                Name,
                Step__r.Type__c,
                Step__r.dataJson__c,
                Step__r.Manual_Task_Notified__c
            FROM Deployment_Job__c
            WHERE
                Step__c IN :stepIdsForManual
                AND Destination_Org__r.To_Org__r.Environment__r.Connection_Behavior__c != NULL
                AND Step__r.CheckOnly__c = FALSE
                AND Step__r.Deployment__r.RecordTypeId != :metadataDeploymentRecordTypeId
                AND (Step__r.Type__c = 'MetaData'
                OR Step__r.Type__c = 'Git MetaData')
        ];
        for (Deployment_Job__c djItem : djList4ManualDeployments) {
            deploymentIdConnectoinBehaviorIdMap.put(
                djItem.Step__r.Deployment__c,
                djItem.Destination_Org__r.To_Org__r.Environment__r.Connection_Behavior__c
            );
            stepIdDeploymentJobMap.put(djItem.Step__c, djItem);
            destEnvIds.add(djItem.Destination_Org__r.To_Org__r.Environment__c);
            qualityGateStepList.add(djItem.Step__r);
        }
        return qualityGateStepList;
    }
    /**
     * populates connection behavior related Quality Gate Steps' creation decision helper maps
     */
    private static void populateConnectionBehaviorRelatedMaps() {
        Set<Id> mgIds = new Set<Id>();
        connectionBehaviorMap = new Map<Id, Connection_Behavior__c>(
            [
                SELECT Id, Back_Promotion_Behavior__c, Promotion_Behavior__c
                FROM Connection_Behavior__c
                WHERE Id IN :deploymentIdConnectoinBehaviorIdMap.values()
            ]
        );
        for (Quality_Gate__c qg : [
            SELECT
                Id,
                Name,
                Connection_Behavior__c,
                DataJSON__c,
                Static_Code_Analysis_Settings__c,
                Selenium_Test_Group__c,
                Score_Threshold__c,
                Compliance_Rule_Group__c,
                Test_Level__c,
                Metadata_Group__c,
                Manual_Task_Owner__c,
                Type__c,
                Execution_Sequence__c,
                Automation_Template__c
            FROM Quality_Gate__c
            WHERE Connection_Behavior__c IN :connectionBehaviorMap.keySet()
            ORDER BY Type__c ASC
        ]) {
            List<Quality_Gate__c> qgTempList = new List<Quality_Gate__c>();
            if (connectoinBehaviorIdQualityGatesMap.containsKey(qg.Connection_Behavior__c)) {
                qgTempList = connectoinBehaviorIdQualityGatesMap.get(qg.Connection_Behavior__c);
            }
            qgTempList.add(qg);
            connectoinBehaviorIdQualityGatesMap.put(qg.Connection_Behavior__c, qgTempList);

            mgIds.add(qg.Metadata_Group__c);
        }

        for (Metadata_Group_Item__c mgi : [
            SELECT Metadata_Group__c, Type__c, Operator__c, Value__c
            FROM Metadata_Group_Item__c
            WHERE Metadata_Group__c IN :mgIds
            ORDER BY Metadata_Group__c
        ]) {
            List<Metadata_Group_Item__c> tempList = new List<Metadata_Group_Item__c>();
            if (mgIdMgiListMap.containsKey(mgi.Metadata_Group__c)) {
                tempList = mgIdMgiListMap.get(mgi.Metadata_Group__c);
            }
            tempList.add(mgi);
            mgIdMgiListMap.put(mgi.Metadata_Group__c, tempList);
        }
    }

    /**
     * Decision point for creating the step or not
     * @param dataList committed data List under promotion step
     * @param mgiItem Metadata Group Item list under current Quality gate of the defined Connection Behavior
     *
     * @return createStep decision of the quality gate step creation
     */
    public static Boolean createStep(List<jsonMetaDataWrapper> dataList, Metadata_Group_Item__c mgiItem) {
        String mgiType = mgiItem.Type__c,
            mgiOperator = mgiItem.Operator__c,
            mgiValue = (null != mgiItem.Value__c ? mgiItem.Value__c.toLowerCase() : '');
        Boolean stepCreationFlag = false;
        for (jsonMetaDataWrapper jmdw : dataList) {
            String jmdwn = jmdw.n.toLowerCase();
            if (
                jmdw.t == mgiType &&
                ((mgiOperator == 'Ends with' && jmdwn.endsWith(mgiValue)) ||
                (mgiOperator == 'Starts with' && jmdwn.startsWith(mgiValue)) ||
                (mgiOperator == 'Contains' && jmdwn.contains(mgiValue)) ||
                (mgiOperator == 'Equals' &&
                jmdwn == mgiValue) ||
                mgiOperator == 'All')
            ) {
                stepCreationFlag = true;
                break;
            }
        }
        return stepCreationFlag;
    }

    /**
     * Populates attachmentWrapper maps for Validation/Apex test with Validation attachments creation
     *
     * @param sIds Ids of the step records to fetch current Attachments
     *
     * @return populated attachments from actual promotion step
     */
    public static CCDAttachmentWrapper populateAttachmentWrapper(Set<Id> sIds) {
        CCDAttachmentWrapper attachmentWrapperItem = new CCDAttachmentWrapper();
        for (Attachment attItem : [SELECT Name, Body, ParentId FROM Attachment WHERE ParentId IN :sIds]) {
            stepFlag = true;
            if (attItem.Name == 'MetaData') {
                List<jsonMetaDataWrapper> dataList = (List<jsonMetaDataWrapper>) JSON.deserialize(
                    attItem.Body.toString(),
                    List<jsonMetaDataWrapper>.class
                );
                attachmentWrapperItem.stepId_dataListMap.put(attItem.ParentId, dataList);
            } else if (attItem.Name == 'Git-Promotion.json') {
                attachmentWrapperItem.stepId_gitPromotionMap.put(attItem.ParentId, attItem.Body);
            } else if (attItem.Name == 'RetrieveOnly.json') {
                attachmentWrapperItem.stepId_retrieveOnlyMap.put(attItem.ParentId, attItem.Body);
            }
        }
        return attachmentWrapperItem;
    }

    /**
     * Iterates on steps and related metadata group items to decide on Quality gate creation via createStep method
     *
     * @param qualityGateStepList Step records for Quality gate check
     */
    public static void processCCDSteps(List<Step__c> qualityGateStepList) {
        for (Step__c sItem : qualityGateStepList) {
            sIds.add(sItem.Id);
            depIds.add(sItem.Deployment__c);
        }
        //to be able set correct order to deployment steps which comes from user story deployment tasks(created by backend)
        Map<Id, Integer> deploymentIdStepSizeMap = returnDeploymentIdStepSizeMap(depIds);
        //Populates attachmentWrapper maps for "Validation/Apex test with Validation" attachments creation
        CCDAttachmentWrapper attachmentWrapperItem = populateAttachmentWrapper(sIds);
        defineQualityGateSteps(qualityGateStepList, deploymentIdStepSizeMap, attachmentWrapperItem);

        //insert of quality gate step and update of actual promotion step
        Utilities.Secure_DML(stepsToUpsert, Utilities.DML_Action.UPS, Schema.SObjectType.Step__c);
        //attachment insert(copy of actual promotion step) to "validation/apex test with validation" step
        Utilities.Secure_DML(
            defineAttachmentsToInsert(attachmentWrapperItem, stepsToUpsert),
            Utilities.DML_Action.INS,
            Schema.SObjectType.Attachment
        );

        //start deployment for "deploymentIds" set
        //DeployAPI.deploy(new List<Id>(deploymentIds), ownerId);
    }

    /**
     * defines Quality gate steps
     *
     * @param qualityGateStepList Step records for Quality gate check
     * @param deploymentIdStepSizeMap deployment Id to current step size Map
     * @param attachmentWrapperItem which has MetaData/RetrieveOnly.json/Git-Promotion.json values from the actual Promotion step
     */
    private static void defineQualityGateSteps(
        List<Step__c> qualityGateStepList,
        Map<Id, Integer> deploymentIdStepSizeMap,
        CCDAttachmentWrapper attachmentWrapperItem
    ) {
        for (Step__c sItem : qualityGateStepList) {
            //set owner Id to be able to start deployment
            if (null == ownerId) {
                ownerId = sItem.Deployment__r.Promotion__r.OwnerId;
            }
            //skip already processed deployment
            if (previousDeploymentId == sItem.Deployment__c) {
                continue;
            }
            //sets the highest step order + 1 for next step
            Integer orderCounter = deploymentIdStepSizeMap.get(sItem.Deployment__c);

            Id connectionBehaviorId = returnConnectionBehaviorId(sItem);
            //if connection behavior has any quality gate records for step creation check
            if (connectoinBehaviorIdQualityGatesMap.containsKey(connectionBehaviorId)) {
                //check for manual deployments to not to start them automatically!
                if (
                    null != sItem.Deployment__r.Promotion__c &&
                    ((sItem.Deployment__r.Promotion__r.Back_Promotion__c &&
                    connectionBehaviorMap.get(connectionBehaviorId).Back_Promotion_Behavior__c != 'Manual') ||
                    (!sItem.Deployment__r.Promotion__r.Back_Promotion__c &&
                    connectionBehaviorMap.get(connectionBehaviorId).Promotion_Behavior__c != 'Manual'))
                ) {
                    deploymentIds.add(sItem.Deployment__c);
                }
                orderCounter = enforceQualityGates(connectionBehaviorId, sItem, orderCounter, attachmentWrapperItem);
            } else if (
                null != connectionBehaviorId &&
                connectionBehaviorMap.containsKey(connectionBehaviorId) &&
                !connectoinBehaviorIdQualityGatesMap.containsKey(connectionBehaviorId)
            ) {
                System.debug(
                    'No quality gates has been specified for this connection behavior \n ' + connectionBehaviorMap.get(connectionBehaviorId)
                );
                deploymentIds.add(sItem.Deployment__c);
            }

            Integer numberOfStepBeforeGitPromotion = stepsByExecutionSequence.containsKey(QUALITY_GATE_BEFORE)
                ? stepsByExecutionSequence.get(QUALITY_GATE_BEFORE).size()
                : 0;
            if (numberOfStepBeforeGitPromotion > 0) {
                numberOfStepBeforeGitPromotion = numberOfStepBeforeGitPromotion + 1;
                sItem.Order__c = numberOfStepBeforeGitPromotion;
                stepsToUpsert.add(sItem);
            }

            for (String sequence : stepsByExecutionSequence.keySet()) {
                if (sequence == QUALITY_GATE_AFTER) {
                    for (Step__c qualityGateStepsExecutionSequenceAfter : stepsByExecutionSequence.get(sequence)) {
                        numberOfStepBeforeGitPromotion = numberOfStepBeforeGitPromotion + 1;
                        qualityGateStepsExecutionSequenceAfter.Order__c = numberOfStepBeforeGitPromotion;
                    }
                }
            }
            previousDeploymentId = sItem.Deployment__c;
        }
    }

    /**
     * iterates through related Quality Gates and Metadata Items to compare/match with committed items on actual promotion step
     *
     * @param connectionBehaviorId
     * @param sItem step__c record
     * @param OrderCounter current order to user on to be created step record's order__c field
     * @param attachmentWrapperItem committed items on actual promotion step
     *
     * @return orderCounter to be able to update the order of the actual promotion step as a last step
     */
    public static Integer enforceQualityGates(
        Id connectionBehaviorId,
        Step__c sItem,
        Integer OrderCounter,
        CCDAttachmentWrapper attachmentWrapperItem
    ) {
        for (Quality_Gate__c qgItem : connectoinBehaviorIdQualityGatesMap.get(connectionBehaviorId)) {
            if (null != qgItem.Metadata_Group__c && mgIdMgiListMap.containsKey(qgItem.Metadata_Group__c)) {
                for (Metadata_Group_Item__c mgiItem : mgIdMgiListMap.get(qgItem.Metadata_Group__c)) {
                    //UCU - to prevent duplicate quality gate step creation!!!
                    if (previousQualityGateId == qgItem.Id && previousStepCreationDecision) {
                        continue;
                    }
                    Boolean createStep = createStep(attachmentWrapperItem.stepId_dataListMap.get(sItem.Id), mgiItem);
                    if (createStep && !sItem.Deployment__r.Promotion__r.Back_Promotion__c) {
                        Integer orderByExecutionSequence = stepOrderByExecutionSequence.containsKey(qgItem.Execution_Sequence__c)
                            ? stepOrderByExecutionSequence.get(qgItem.Execution_Sequence__c)
                            : 0;
                        orderByExecutionSequence++;
                        stepOrderByExecutionSequence.put(qgItem.Execution_Sequence__c, orderByExecutionSequence);
                        Step__c qualityGateStep = addStep(qgItem, sItem, orderByExecutionSequence);
                        if (stepsByExecutionSequence.containsKey(qgItem.Execution_Sequence__c)) {
                            stepsByExecutionSequence.get(qgItem.Execution_Sequence__c).add(qualityGateStep);
                        } else {
                            List<Step__c> steps = new List<Step__c>();
                            steps.add(qualityGateStep);
                            stepsByExecutionSequence.put(qgItem.Execution_Sequence__c, steps);
                        }

                        //skip the quality gate and DO NOT process if there is a data issue on quality gate
                        if (null != qualityGateStep) {
                            qualityGateStep.dataJson__c = (null != qualityGateStep.dataJson__c ? qualityGateStep.dataJson__c : '');
                            //if new step's unique Identifier is unique then create the step, if not then don't.
                            if (
                                !duplicateControlSet.contains(
                                    qualityGateStep.Name +
                                    qualityGateStep.Type__c +
                                    qualityGateStep.Deployment__c +
                                    qualityGateStep.dataJson__c.replace('step/' + sItem.Order__c + '/', +'Current/')
                                        .replace('step/' + qualityGateStep.Order__c + '/', 'Current/')
                                )
                            ) {
                                duplicateControlSet.add(
                                    qualityGateStep.Name +
                                    qualityGateStep.Type__c +
                                    qualityGateStep.Deployment__c +
                                    qualityGateStep.dataJson__c.replace('step/' + sItem.Order__c + '/', +'Current/')
                                        .replace('step/' + qualityGateStep.Order__c + '/', 'Current/')
                                );
                                if (!parentQualityGateIds.contains(qualityGateStep.Automated_Behaviour__c)) {
                                    parentQualityGateIds.add(qualityGateStep.Automated_Behaviour__c);
                                    stepsToUpsert.add(qualityGateStep);
                                    orderCounter++;
                                }
                            }
                        }
                    }
                    previousQualityGateId = qgItem.Id;
                    previousStepCreationDecision = createStep;
                }
            }
        }
        return orderCounter;
    }

    /**
     * defines current connection behavior Id based on current deployment(automated, scheduled) or deployment job(manual behavior) record
     *
     * @param sItem Step record
     *
     * @return connection behavior Id
     */
    public static Id returnConnectionBehaviorId(Step__c sItem) {
        return (null != sItem.Deployment__r.Promotion__c
            ? sItem.Deployment__r.Promotion__r.Connection_Behavior__c
            : stepIdDeploymentJobMap.get(sItem.Id).Destination_Org__r.To_Org__r.Environment__r.Connection_Behavior__c);
    }

    /**
     * to be able set correct order to deployment steps which comes from user story deployment tasks(created by backend)
     *
     * @param depIds deployment__c record Ids
     *
     * @return populated deployment Id to step size map after iteration
     */
    public static Map<Id, Integer> returnDeploymentIdStepSizeMap(Set<Id> depIds) {
        Map<Id, Integer> deploymentIdStepSizeMap = new Map<Id, Integer>();
        for (Step__c sItem : [
            SELECT Id, Name, Type__c, Order__c, dataJson__c, Deployment__c, Automated_Behaviour__c
            FROM Step__c
            WHERE Deployment__c IN :depIds
        ]) {
            Integer tempInt = 1;
            sItem.dataJson__c = (null != sItem.dataJson__c ? sItem.dataJson__c : '');
            duplicateControlSet.add(
                sItem.Name +
                sItem.Type__c +
                sItem.Deployment__c +
                sItem.dataJson__c.replace('step/' + sItem.Order__c + '/', 'Current/')
            );
            if (String.isNotBlank(sItem.Automated_Behaviour__c)) {
                parentQualityGateIds.add(sItem.Automated_Behaviour__c);
            }
            if (deploymentIdStepSizeMap.containsKey(sItem.Deployment__c)) {
                tempInt = deploymentIdStepSizeMap.get(sItem.Deployment__c) + 1;
            }
            deploymentIdStepSizeMap.put(sItem.Deployment__c, tempInt);
        }
        return deploymentIdStepSizeMap;
    }

    /**
     * add quality gate step to current step's deployment based on the quality gate type and metadata Item check
     *
     * @param qgItem Quality Gate Record
     * @param sItem actual Promotion Step record
     * @param orderCounter current iteration order to be able to set order__c field on Step__c object
     *
     * @return step to be added to current deployment record
     */
    public static Step__c addStep(Quality_Gate__c qgItem, Step__c sItem, Integer orderCounter) {
        urlCalloutWrapper urlCalloutItem;
        Step__c qualityGateStepToPopulate;
        if (qgItem.Type__c == 'Apex Test with Validation' || qgItem.Type__c == 'Validation') {
            qualityGateStepToPopulate = sItem.clone(false, false, false, false);
            qualityGateStepToPopulate.Name = qgItem.Type__c;
            qualityGateStepToPopulate.CheckOnly__c = true;
            qualityGateStepToPopulate.Order__c = orderCounter;
            qualityGateStepToPopulate.Read_Only__c = true;

            orderPlusDeploymentIdOriginalStepIdMap.put(String.valueOf(orderCounter) + sItem.Deployment__c, sItem.Id);
            dataJsonWrapper djItem = (dataJsonWrapper) JSON.deserialize(qualityGateStepToPopulate.dataJson__c, dataJsonWrapper.class);
            if (String.isBlank(qgItem.Test_Level__c)) {
                qgItem.Test_Level__c = 'No Test Run';
            }
            djItem.testLevel = (qgItem.Type__c == 'Apex Test with Validation' ? qgItem.Test_Level__c.replaceAll(' ', '') : 'NoTestRun');
            qualityGateStepToPopulate.dataJson__c = JSON.serializePretty(djItem, true);
        } else if (qgItem.Type__c == 'Compliance Check') {
            urlCalloutItem = new urlCalloutWrapper(
                scanCompliancemWebhook.replace('{user_api_key}', apiKey)
                    .replace('{deploymentId}', sItem.Deployment__c)
                    .replace('{stepOrder}', String.valueOf(orderCounter)),
                JSON.serializePretty(new cchBodyWrapper(sItem.Id, qgItem.Compliance_Rule_Group__c), true)
            );
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, JSON.serialize(urlCalloutItem), 'URL Callout');
        } else if (qgItem.Type__c == 'Static Code Analysis') {
            String staticCodeAnalysisId = sItem.Deployment__r.Promotion__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c;
            if (null != qgItem.Static_Code_Analysis_Settings__c) {
                staticCodeAnalysisId = qgItem.Static_Code_Analysis_Settings__c;
            }
            urlCalloutItem = new urlCalloutWrapper(
                staticCodeAnalysisWebhook.replace('{user_api_key}', apiKey)
                    .replace('{deploymentId}', sItem.Deployment__c)
                    .replace('{stepOrder}', String.valueOf(orderCounter)),
                JSON.serializePretty(
                    new scaBodyWrapper(
                        sItem.Id,
                        staticCodeAnalysisId,
                        (null != qgItem.Score_Threshold__c ? Integer.valueOf(qgItem.Score_Threshold__c) : null)
                    ),
                    true
                )
            );
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, JSON.serialize(urlCalloutItem), 'URL Callout');
        } else if (qgItem.Type__c == 'Selenium Test' && null != qgItem.Selenium_Test_Group__c) {
            urlCalloutItem = new urlCalloutWrapper(
                runSeleniumWebhook.replace('user_api_key', apiKey).replace('selenium_group_id', qgItem.Selenium_Test_Group__c)
            );
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, JSON.serialize(urlCalloutItem), 'URL Callout');
        } else if (manualTaskList.contains(qgItem.Type__c)) {
            String description = qgItem.Type__c == 'Manual Approval' || qgItem.Type__c == 'Manual Test' ? qgItem.Name : qgItem.Type__c;
            manualTaskWrapper manualTaskItem = new manualTaskWrapper(description, qgItem.Manual_Task_Owner__c);
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, JSON.serialize(manualTaskItem), 'Manual Task');
        } else if (qgItem.Type__c == 'URL Callout') {
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, qgItem.DataJSON__c, 'URL Callout');
        } else if (qgItem.Type__c == 'Automation') {
            AutomationWrapper automationItem = new AutomationWrapper(qgItem.Automation_Template__c);
            qualityGateStepToPopulate = prepareStep(qgItem.Type__c, orderCounter, sItem.Deployment__c, JSON.serialize(automationItem), 'Automation');
        }
        qualityGateStepToPopulate.Automated_Behaviour__c = qgItem.Id;
        return qualityGateStepToPopulate;
    }

    /**
     * Creates needed attachment for the Validation/Apex test and Validation Quality Gate steps
     *
     * @param attachmentWrapperItem AttachmentWrapper which has MetaData/RetrieveOnly.json/Git-Promotion.json values from the actual Promotion step
     * @param stepsToUpsert actual Promotion step to iterate through
     *
     * @return will be inserted Attachments under "Validation/Apex test with validation" step
     */
    private static List<Attachment> defineAttachmentsToInsert(CCDAttachmentWrapper attachmentWrapperItem, List<Step__c> stepsToUpsert) {
        List<Attachment> attListToInsert = new List<Attachment>();
        for (Step__c sItem : stepsToUpsert) {
            if (orderPlusDeploymentIdOriginalStepIdMap.containsKey(String.valueOf(sItem.Order__c) + sItem.Deployment__c)) {
                Id previousStepId = orderPlusDeploymentIdOriginalStepIdMap.get(String.valueOf(sItem.Order__c) + sItem.Deployment__c);
                if (attachmentWrapperItem.stepId_dataListMap.containsKey(previousStepId)) {
                    attListToInsert.add(
                        new Attachment(
                            Name = 'MetaData',
                            Body = Blob.valueOf(JSON.serialize(attachmentWrapperItem.stepId_dataListMap.get(previousStepId))),
                            ParentId = sItem.Id
                        )
                    );
                }
                if (attachmentWrapperItem.stepId_retrieveOnlyMap.containsKey(previousStepId)) {
                    attListToInsert.add(
                        new Attachment(
                            Name = 'RetrieveOnly.json',
                            Body = attachmentWrapperItem.stepId_retrieveOnlyMap.get(previousStepId),
                            ParentId = sItem.Id
                        )
                    );
                }
                if (attachmentWrapperItem.stepId_gitPromotionMap.containsKey(previousStepId)) {
                    attListToInsert.add(
                        new Attachment(
                            Name = 'Git-Promotion.json',
                            Body = attachmentWrapperItem.stepId_gitPromotionMap.get(previousStepId),
                            ParentId = sItem.Id
                        )
                    );
                }
            }
        }
        return attListToInsert;
    }

    /**
     * prepares the default step to modify later on
     *
     * @param name
     * @param orderCounter
     * @param depId
     * @param dataJson
     *
     * @return ready to insert Quality Gate step after population
     */
    public static Step__c prepareStep(String name, Integer orderCounter, Id depId, String dataJson, String stepType) {
        Step__c qualityGate = new Step__c(
            Name = name,
            Order__c = orderCounter,
            Type__c = stepType,
            Status__c = 'Not started',
            Deployment__c = depId,
            dataJson__c = dataJson,
            Read_Only__c = true
        );
        return qualityGate;
    }

    private class manualTaskWrapper {
        public Boolean Perform_in_Destination_Orgs;
        public Boolean Perform_in_Source_Org;
        public String Task_Description;
        public String Task_Owner;
        public String Notify_Task_Owner;
        public manualTaskWrapper(String description, String taskOwnerId) {
            this.Perform_in_Destination_Orgs = false;
            this.Perform_in_Source_Org = true;
            this.Task_Description = description;
            this.Task_Owner = taskOwnerId;
            this.Notify_Task_Owner = 'Chatter and Email';
        }
    }

    private class AutomationWrapper {
        public String automationId;
        public AutomationWrapper(String automationId) {
            this.automationId = automationId;
        }
    }

    public class urlCalloutWrapper {
        public String type;
        public String method;
        public String url;
        public String body;
        public List<List<String>> queryParameters;
        public List<List<String>> headers;
        public urlCalloutWrapper(String url, Boolean executePromotionsInParallel) {
            this.type = executePromotionsInParallel ? 'continue' : 'wait';
            this.method = 'POST';
            this.url = url;
            this.body = '{}';
            this.queryParameters = new List<List<String>>{ new List<String>{ 'api_key', apiKey } };
            this.headers = new List<List<String>>();
        }
        public urlCalloutWrapper(String url) {
            this.type = 'wait';
            this.method = 'POST';
            this.url = url;
            this.body = '{}';
            this.queryParameters = new List<List<String>>{ new List<String>{ 'api_key', apiKey } };
            this.headers = new List<List<String>>();
        }
        public urlCalloutWrapper(String url, String body) {
            this.type = 'wait';
            this.method = 'POST';
            this.url = url;
            this.body = body;
            this.queryParameters = new List<List<String>>{ new List<String>{ 'api_key', apiKey } };
            this.headers = new List<List<String>>{ new List<String>{ 'Content-Type', 'application/json' } };
        }
    }

    public class jsonMetaDataWrapper {
        public String t;
        public String n;
    }

    private class dataJsonWrapper {
        public String testLevel;
        public List<List<String>> replacements;
    }

    private class scaBodyWrapper {
        public String metadataStepId;
        public String settingId;
        public Integer scoreThreshold;
        public scaBodyWrapper(String metadataStepId, String settingId, Integer scoreThreshold) {
            this.metadataStepId = metadataStepId;
            this.settingId = settingId;
            this.scoreThreshold = scoreThreshold;
        }
    }

    private class cchBodyWrapper {
        public String metadataStepId;
        public String complianceRuleGroupId;
        public cchBodyWrapper(String metadataStepId, String complianceRuleGroupId) {
            this.metadataStepId = metadataStepId;
            this.complianceRuleGroupId = complianceRuleGroupId;
        }
    }

    private class CCDAttachmentWrapper {
        public Map<Id, List<jsonMetaDataWrapper>> stepId_dataListMap {
            get {
                if (null == stepId_dataListMap) {
                    stepId_dataListMap = new Map<Id, List<jsonMetaDataWrapper>>();
                }
                return stepId_dataListMap;
            }
            set;
        }
        public Map<Id, Blob> stepId_retrieveOnlyMap {
            get {
                if (null == stepId_retrieveOnlyMap) {
                    stepId_retrieveOnlyMap = new Map<Id, Blob>();
                }
                return stepId_retrieveOnlyMap;
            }
            set;
        }
        public Map<Id, Blob> stepId_gitPromotionMap {
            get {
                if (null == stepId_gitPromotionMap) {
                    stepId_gitPromotionMap = new Map<Id, Blob>();
                }
                return stepId_gitPromotionMap;
            }
            set;
        }
    }
}