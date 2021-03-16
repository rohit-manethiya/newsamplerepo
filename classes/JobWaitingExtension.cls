/**
 * This is a extension class to use for all waiting job page.
 * It is designed as sObject so you can define your object and perform different method
 */
public with sharing class JobWaitingExtension {
    // Non Constants
    public SObject objectname { get; set; }
    public User_Story__c userStory { get; set; } // this is used for user story validation job
    public Git_Backup__c gitSnapshot { get; set; } // this is used for user story validation job
    public Map<String, Set<Object>> pageMessagesMap { get; set; }
    private Boolean enableValidationPoller;
    private Boolean enableCommitChangesPoller;
    private Boolean enableTestRunPoller;
    private String processType;
    private String namespace;
    public String copadoNotificationId { get; set; }
    private String parentPageName;
    private String lastCalloutMessageFromAPI;
    private List<Copado_Notification__c> copadoNotificationList;
    private Map<String, Boolean> notificationStatusMap;
    // Constants
    private final String C_GITHUB = 'Github';
    private final String C_GITLAB = 'GitLab';
    private final String C_BITBUCKET = 'Bitbucket';
    private final String C_MTS = 'Microsoft Team Service';
    private final String PSC = 'PROGRESS_STATUS_COPADO';
    private final String VALIDATION = 'Validation';
    private final String C_COMMIT = 'Commit';
    private final String C_DONE = 'done';
    private final String DESTRUCTIVECHANGES = 'Destructive Changes';
    private final String GITDELETION = 'GitDeletion';
    private final String C_PROMOTION = 'Promotion';
    private final String DEPLOYER = 'Deployer';
    private final String C_ERROR = 'error';
    private final String C_TESTRUN = 'ApexTestRunner';
    private final String C_STD = 'Standard';
    private final String C_SID = 'sId';
    private final String C_CTYPE = 'cType';
    private final String C_WARNING = 'warning';
    private final String C_INFO = 'info';
    private final String C_SUCCESS = 'success';
    private final String DYNAMIC_QUERY = 'SELECT {0} FROM {1} WHERE {2}';
    private final String CO_VALIDATION = 'co_validation';
    private final String CO_COMMIT_CHANGES = 'co_commitChanges';
    private final String CO_APEX_TEST_RUN = 'co_apexTestRun';
    private final String CO_PULL_REQUEST = 'co_pullRequest';

    public JobWaitingExtension(ApexPages.StandardController stdController) {
        this.objectname = (SObject) stdController.getRecord();
        processType = ApexPages.currentPage().getParameters().get('type');
        namespace = Settings.ns;
        pageMessagesMap = new Map<String, Set<Object>>();
        enableValidationPoller = false;
        enableCommitChangesPoller = false;
        enableTestRunPoller = false;
        copadoNotificationId = '';
        parentPageName = C_STD;
        userStory = new User_Story__c();
        gitSnapshot = new Git_Backup__c();
        if (Schema.User_Story__c.SObjectType == objectname.getSObjectType()) {
            fetchUserStory();
        } else if (Schema.Git_Backup__c.SObjectType == objectname.getSObjectType()) {
            fetchGitSnapshot();
        }
    }

    /**
     * It is used to check existing copado notification status when you refresh the page
     */
    public void checkCopadoNotificationStatus() {
        notificationStatusMap = new Map<String, Boolean>();
        if (processType == CO_VALIDATION) {
            enableValidationPoller = true;
            Boolean promotionJobIsDone = false;
            if (Schema.SObjectType.Copado_Notification__c.isAccessible() && Schema.SObjectType.Copado_Notification__c.isQueryable()) {
                String existingJobId = ApexPages.currentPage().getParameters().get('existingJobId');
                if (String.isNotBlank(existingJobId)) {
                    List<Copado_Notification__c> cnList = new List<Copado_Notification__c>();
                    cnList = [SELECT Type__c FROM Copado_Notification__c WHERE Id = :existingJobId LIMIT 1];
                    promotionJobIsDone = !cnList.isEmpty() && String.isNotBlank(cnList[0].Type__c) && cnList[0].Type__c == 'Deployer';
                }
            } else {
                addRecordsToMessageMap(
                    C_WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Copado_Notification__c.getLabel()
                    }
                );
                return;
            }
            notificationStatusMap.put(C_PROMOTION, promotionJobIsDone ? true : false);
            notificationStatusMap.put(DEPLOYER, false);
        } else if (processType == CO_COMMIT_CHANGES) {
            enableCommitChangesPoller = true;
            String commitType = getCommitType();
            notificationStatusMap.put(commitType, false);
        } else if (processType == CO_APEX_TEST_RUN) {
            enableTestRunPoller = true;
            notificationStatusMap.put(C_TESTRUN, false);
        }
    }

    /**
     * this is used to redirect parent page when user click on Go Back button on the page
     * @return
     */
    public PageReference getReturnUrl() {
        return getReturnUrlWithParameter(parentPageName);
    }

    /**
     * this is used to generate returning url to back to parent page
     * @return
     */
    public PageReference getReturnUrlWithParameter(String pageType) {
        PageReference pReference;
        if (pageType == C_STD) {
            pReference = new ApexPages.StandardController(objectname).view();
        } else if (pageType == C_TESTRUN) {
            pReference = Page.UserStoryApexTestResults;
            pReference.getParameters().put('id', userStory.Id);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * this is used to check if there is any commit changes at user story
     * @return
     */
    private Boolean isUSReadyToValidate() {
        List<GlobalUtilities.flowStepWrapper> visualFlowSteps = GlobalUtilities.getDeploymentFlowSteps(userStory);
        return String.isBlank(userStory.Metadata_Types_in_Selection__c) || visualFlowSteps.isEmpty() ? false : true;
    }

    /**
     * This is used to cast sobject to user story record
     */
    public void fetchUserStory() {
        Id usId = objectname.Id;

        String selectUSString = ('Id, Name, Org_Credential__r.Validated_Date__c, Org_Credential__r.Error__c, Promote_as_Single_Step__c, Developer__c, Status__c, Progress__c, Promotion_Test_Level__c, Metadata_Types_in_Selection__c, User_Story_Title__c, Project__c, Environment__c, Org_Credential__c, Base_Branch__c, Org_Credential__r.Org_Type__c, Project__r.Deployment_Flow__c, Project__r.Deployment_Flow__r.Main_Branch__c, Release__r.Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__r.Main_Branch__c, Release__r.Base_Branch__c, Last_Validation_Promotion__c');
        String fsNamespace = SObjectType.User_Story__c.fieldSets.User_Story_Waiting_Page.getNameSpace();
        fsNamespace = fsNamespace == null ? '' : fsNamespace + '__';
        for (Schema.FieldSetMember fsm : SObjectType.User_Story__c.fieldSets.User_Story_Waiting_Page.getFields()) {
            Boolean alreadyAdded = selectUSString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(fsNamespace)) ? true : false;
            selectUSString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(fsNamespace);
        }

        String fromUSString = Schema.SObjectType.User_Story__c.name;
        String whereUSString = 'Id = :usId';
        String mainUSQuery = String.format(DYNAMIC_QUERY, new List<String>{ selectUSString, fromUSString, whereUSString });

        if (Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
            userStory = Database.query(mainUSQuery);

            if (String.isNotBlank(processType)) {
                if (processType == CO_VALIDATION) {
                    Boolean readyToValidate = isUSReadyToValidate();
                    if (!readyToValidate) {
                        addRecordsToMessageMap(C_WARNING, new List<String>{ Label.No_Commit_Changes, Label.Please_Go_Back_To_Record });
                        enableValidationPoller = false;
                    } else {
                        addRecordsToMessageMap(C_INFO, new List<String>{ Label.Validation_In_Progress });
                        enableValidationPoller = true;
                    }
                } else if (processType == CO_PULL_REQUEST) {
                    addRecordsToMessageMap(C_INFO, new List<String>{ Label.Pull_Request_In_Progress });
                } else if (processType == CO_COMMIT_CHANGES) {
                    addRecordsToMessageMap(C_INFO, new List<String>{ Label.Commit_Started });
                    enableCommitChangesPoller = false;
                } else if (processType == CO_APEX_TEST_RUN) {
                    addRecordsToMessageMap(C_INFO, new List<String>{ Label.Apex_Test_Run_Started });
                    enableTestRunPoller = false;
                    parentPageName = C_TESTRUN;
                }
            }
        } else {
            addRecordsToMessageMap(
                C_WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.User_Story__c.getLabel() }
            );
            return;
        }
    }

    /**
     * This is used to cast sobject to git snapshot record
     */
    public void fetchGitSnapshot() {
        Id snapshotId = objectname.Id;
        String selectSnapshotString = ('Id, Name, Org__c, Org__r.Validated_Date__c, Org__r.Error__c');
        String fsNamespace = SObjectType.Git_Backup__c.fieldSets.Snapshot_Waiting_Page.getNameSpace();
        fsNamespace = fsNamespace == null ? '' : fsNamespace + '__';
        for (Schema.FieldSetMember fsm : SObjectType.Git_Backup__c.fieldSets.Snapshot_Waiting_Page.getFields()) {
            Boolean alreadyAdded = selectSnapshotString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(fsNamespace)) ? true : false;
            selectSnapshotString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(fsNamespace);
        }
        String fromSnapshotString = Schema.SObjectType.Git_Backup__c.name;
        String whereSnapshotString = 'Id = :snapshotId';
        String mainSnapshotQuery = String.format(DYNAMIC_QUERY, new List<String>{ selectSnapshotString, fromSnapshotString, whereSnapshotString });

        if (Schema.SObjectType.Git_Backup__c.isAccessible() && Schema.SObjectType.Git_Backup__c.isQueryable()) {
            gitSnapshot = Database.query(mainSnapshotQuery);

            if (String.isNotBlank(processType)) {
                if (processType == CO_COMMIT_CHANGES) {
                    addRecordsToMessageMap(C_INFO, new List<String>{ Label.Commit_Started });
                    enableCommitChangesPoller = false;
                }
            }
        } else {
            addRecordsToMessageMap(
                C_WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.getLabel() }
            );
            return;
        }
    }

    /**
     * This is used to make a callout to the backend to create job for commit changes
     */
    public void commitCallOut() {
        if (
            (userStory.Id != null && userStory.Org_Credential__r.Validated_Date__c == null) ||
            (gitSnapshot.Id != null &&
            gitSnapshot.Org__r.Validated_Date__c == null)
        ) {
            addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Org_Is_Not_Valid, Label.Please_Go_Back_To_Record });
            enableCommitChangesPoller = false;
            return;
        }
        Settings cSetting = new Settings();
        String baseUrl = cSetting.urlBase;
        String urlParameter = Settings.generic_heroku_params;
        String actionName = ApexPages.currentPage().getParameters().get('ep');
        String msg = '';
        String commitId = ApexPages.currentPage().getParameters().get('cId');
        if (String.isNotBlank(commitId)) {
            if (Schema.SObjectType.Git_Org_Commit__c.isAccessible() && Schema.SObjectType.Git_Org_Commit__c.isQueryable()) {
                List<Git_Org_Commit__c> snapshotCommitList = [SELECT Commit_Message__c FROM Git_Org_Commit__c WHERE Id = :commitId LIMIT 1];

                if (!snapshotCommitList.isEmpty()) {
                    msg = snapshotCommitList[0].Commit_Message__c;
                }
            } else {
                addRecordsToMessageMap(
                    C_WARNING,
                    new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Git_Org_Commit__c.getLabel() }
                );
                return;
            }
        }

        String snapshotId = ApexPages.currentPage().getParameters().get(C_SID);
        String snapshotStr = gitSnapshot.Id;
        String newSnapshotId = (String.isEmpty(snapshotId) && String.isNotBlank(snapshotStr)) ? snapshotStr : snapshotId;
        String mBranch = getMainBranch(userStory);

        String commitType = getCommitType();
        String orgId = (userStory != null &&
            userStory.Id != null)
            ? userStory.Org_Credential__c
            : (gitSnapshot != null && gitSnapshot.Id != null) ? gitSnapshot.Org__c : '';
        String userStoryStr = userStory.Id;
        String usId = String.isNotBlank(userStoryStr) ? userStoryStr : '';
        String finalUrl =
            baseUrl +
            EncodingUtil.urlEncode(actionName, 'UTF-8') +
            '/' +
            commitId +
            urlParameter +
            '&orgId=' +
            orgId +
            '&gitBackupId=' +
            newSnapshotId +
            '&message=' +
            EncodingUtil.urlEncode(msg, 'UTF-8') +
            '&userStoryId=' +
            usId +
            '&type=' +
            EncodingUtil.urlEncode(commitType.trim(), 'UTF-8');
        if (String.isNotBlank(mBranch)) {
            finalUrl += '&mainBranch=' + mBranch;
        }
        String recreateFeatureBranch = ApexPages.currentPage().getParameters().get('recreateFeatureBranch');
        if (String.isNotBlank(recreateFeatureBranch)) {
            finalUrl += '&recreateFeatureBranch=' + recreateFeatureBranch;
        }
        doCallOut(finalUrl, C_COMMIT, Label.Unexpected_Error_Commit_Changes);
        notificationStatusMap = new Map<String, Boolean>();
        notificationStatusMap.put(commitType, false);
    }

    /**
     * Returns the main branch for commit changes
     */
    @TestVisible
    private String getMainBranch(User_Story__c userStory) {
        String projectDefaultBranch = String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Main_Branch__c)
            ? userStory.Project__r.Deployment_Flow__r.Main_Branch__c
            : 'master';
        String releaseDefaultBranch = String.isNotBlank(userStory.Release__r.Base_Branch__c) ? userStory.Release__r.Base_Branch__c : '';
        String usStoryDefaultBranch = String.isNotBlank(userStory.Base_Branch__c) ? userStory.Base_Branch__c : '';
        return String.isNotBlank(usStoryDefaultBranch)
            ? usStoryDefaultBranch
            : String.isNotBlank(releaseDefaultBranch) ? releaseDefaultBranch : projectDefaultBranch;
    }

    /**
     * It is used to return commit type by checking the url
     *
     * @return
     */
    private String getCommitType() {
        String commitType = ApexPages.currentPage().getParameters().get(C_CTYPE);
        if (String.isNotBlank(commitType)) {
            if (commitType == DESTRUCTIVECHANGES) {
                commitType = GITDELETION;
            } else if (commitType == 'Full Profiles & Permission Sets') {
                commitType = 'FullProfilePermissionSets';
            }
        }
        return commitType;
    }

    /**
     * This is used to create and update records to validate for user story
     */
    public void prepareValidation() {
        if (enableValidationPoller) {
            if (
                Schema.SObjectType.Promotion__c.fields.Project__c.isCreateable() &&
                Schema.SObjectType.Promotion__c.fields.Release__c.isCreateable() &&
                Schema.SObjectType.Promotion__c.fields.Source_Org_Credential__c.isCreateable() &&
                Schema.SObjectType.Promotion__c.fields.Source_Environment__c.isCreateable() &&
                Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.isCreateable() &&
                Schema.SObjectType.Promotion__c.fields.Status__c.isCreateable()
            ) {
                Promotion__c promotion = new Promotion__c();
                promotion.Project__c = userStory.Project__c;
                promotion.Release__c = userStory.Release__c;
                promotion.Source_Org_Credential__c = userStory.Org_Credential__c;
                promotion.Source_Environment__c = userStory.Environment__c;
                promotion.Send_Deployment_Complete_email__c = true;
                promotion.Status__c = VALIDATION;
                try {
                    Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);
                    if (
                        Schema.SObjectType.Promoted_User_Story__c.fields.User_Story__c.isCreateable() &&
                        Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.isCreateable()
                    ) {
                        Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);
                        pus.Name = 'Promoted User Story: ' + userStory.Name;
                        Utilities.Secure_DML(pus, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);
                    }
                    if (
                        Schema.SObjectType.User_Story__c.fields.Last_Validation_Promotion__c.isUpdateable() &&
                        Schema.SObjectType.User_Story__c.fields.Last_Validation_Deployment__c.isUpdateable()
                    ) {
                        userStory.Last_Validation_Promotion__c = promotion.Id;
                        userStory.Last_Validation_Deployment__c = null;
                        Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                    }
                    enableValidationPoller = true;
                } catch (DmlException dmlEx) {
                    enableValidationPoller = false;
                    pageMessagesMap.clear();
                    addRecordsToMessageMap(C_ERROR, new List<String>{ dmlEx.getDmlMessage(0) });
                    addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Please_Go_Back_To_Record });
                }
                notificationStatusMap = new Map<String, Boolean>();
                notificationStatusMap.put(C_PROMOTION, false);
                notificationStatusMap.put(DEPLOYER, false);
            }
        }
    }

    /**
     * this is used to render action poller for validation
     * @return
     */
    public Boolean getIsValidationPollerEnabled() {
        return enableValidationPoller;
    }

    /**
     * this is used to render action poller for commit changes
     * @return
     */
    public Boolean getIsCommitChangesPollerEnabled() {
        return enableCommitChangesPoller;
    }

    /**
     * this is used to render action poller for apex test run
     * @return
     */
    public Boolean getIsApexTestRunPollerEnabled() {
        return enableTestRunPoller;
    }

    /**
     * This is used to redirect to the parent page after validation completed
     * @return
     */
    public PageReference waitForDeployment() {
        List<Deployment__c> deploymentList;
        try {
            if (Schema.SObjectType.Deployment__c.isAccessible() && Schema.SObjectType.Deployment__c.isQueryable()) {
                deploymentList = [
                    SELECT Id, Status__c, Promotion__r.Status__c
                    FROM Deployment__c
                    WHERE Promotion__c = :userStory.Last_Validation_Promotion__c
                    LIMIT 1
                ];

                if (!deploymentList.isEmpty() && deploymentList.get(0).Promotion__r.Status__c == 'Merge Conflict') {
                    addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Merge_Conflict_On_Validation, Label.Please_Go_Back_To_Record });
                    enableValidationPoller = false;
                    return null;
                }
            } else {
                addRecordsToMessageMap(
                    C_WARNING,
                    new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Deployment__c.getLabel() }
                );
                return null;
            }
        } catch (Exception ex) {
            addRecordsToMessageMap(C_ERROR, new List<String>{ ex.getMessage() });
            return null;
        }

        // first notification is tied to promotion, return parameter is false because there is another job which is deployer
        if (notificationStatusMap.containsKey(C_PROMOTION) && !notificationStatusMap.get(C_PROMOTION)) {
            return copadoNotificationProcesses(
                C_PROMOTION,
                PSC,
                userStory.Last_Validation_Promotion__c,
                Label.Promotion_Validation_Success,
                Label.Unexpected_Error_Promotion_Process,
                VALIDATION,
                false,
                C_STD
            );
        }

        // second job is tied to deployment job, return parameter is true because job will finish after this one
        List<Step__c> stepList = new List<Step__c>();
        if (Schema.SObjectType.Step__c.isAccessible() && Schema.SObjectType.Step__c.isQueryable()) {
            if (deploymentList != null && !deploymentList.isEmpty()) {
                stepList = [SELECT Id FROM Step__c WHERE Deployment__c = :deploymentList[0].Id LIMIT 1];
            }
        } else {
            addRecordsToMessageMap(
                C_WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Step__c.getLabel() }
            );
            return null;
        }

        List<Deployment_Job__c> deploymentJobList = new List<Deployment_Job__c>();
        if (Schema.SObjectType.Deployment_Job__c.isAccessible() && Schema.SObjectType.Deployment_Job__c.isQueryable()) {
            if (!stepList.isEmpty()) {
                deploymentJobList = [SELECT Id FROM Deployment_Job__c WHERE Step__c = :stepList[0].Id LIMIT 1];
            }
        } else {
            addRecordsToMessageMap(
                C_WARNING,
                new List<String>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Job__c.getLabel() }
            );
            return null;
        }

        if (notificationStatusMap.containsKey(DEPLOYER) && !notificationStatusMap.get(DEPLOYER) && !deploymentJobList.isEmpty()) {
            return copadoNotificationProcesses(
                DEPLOYER,
                PSC,
                deploymentJobList[0].Id,
                Label.Validation_Completed,
                Label.Unexpected_Error_Validation,
                VALIDATION,
                true,
                C_STD
            );
        }
        return null;
    }

    /**
     * this is used to run validation for user story
     */
    public void runValidation() {
        if (String.isNotBlank(userStory.Last_Validation_Promotion__c) && enableValidationPoller) {
            DeployAPI.deployPromotion(
                userStory.Last_Validation_Promotion__c,
                userStory.Name,
                true,
                userStory.Promote_as_Single_Step__c,
                userStory.Promotion_Test_Level__c
            );
        }
    }

    /**
     * It is used to prepare necessary values to redirect provider
     * @return
     */
    public PageReference preparationPullRequest() {
        GlobalUtilities.getDeploymentFlowSteps(userStory);
        String targetBranch = GlobalUtilities.targetBranch;
        String compareBranch = 'feature/' + userStory.Name;
        String baseUrl = GlobalUtilities.baseUrl;
        String provider = GlobalUtilities.provider;
        Integer commitCount = GlobalUtilities.getCommitCount(userStory.Id);
        if (String.isBlank(targetBranch)) {
            // Target branch not found. This indicates that user story does not have an environment, project or git repository association
            addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Target_Branch_Not_Found, Label.Please_Go_Back_To_Record });
            return null;
        } else if (String.isBlank(baseUrl) || String.isBlank(provider)) {
            // Pull request base url and git provider field not found.
            // Pull request base url and provider is important in order to setup the pull request creation operation
            addRecordsToMessageMap(C_WARNING, new List<String>{ Label.PULL_REQUEST_VALIDATION, Label.Please_Go_Back_To_Record });
            return null;
        } else if (String.isBlank(compareBranch) || commitCount <= 0) {
            // Feature branch not found. In order to have feature branch user story must have a completed commit.
            addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Feature_Branch_Not_Found, Label.Please_Go_Back_To_Record });
            return null;
        } else {
            // If above validations are passed then we can execute pull request operations.
            String url = initPullRequest(provider, targetBranch, baseUrl, compareBranch);
            PageReference pageRef = new PageReference(url);
            pageRef.setRedirect(true);
            return pageRef;
        }
    }

    /**
     * Initiliazing the url based on selected provider
     * @param provider
     * @param targetBranch
     * @param baseUrl
     * @param compareBranch
     *
     * @return
     */
    private String initPullRequest(String provider, String targetBranch, String baseUrl, String compareBranch) {
        String url = baseUrl;
        String path = '';
        if (provider == C_GITHUB) {
            path = 'compare/' + targetBranch + '...' + compareBranch + '?expand=1';
        } else if (provider == C_GITLAB) {
            path = 'merge_requests/new?merge_request[source_branch]=' + compareBranch + '&merge_request[target_branch]=' + targetBranch;
        } else if (provider == C_BITBUCKET) {
            path = 'pull-requests/new?source=' + compareBranch + '&dest=' + targetBranch + '&event_source=branch_detail';
        } else if (provider == C_MTS) {
            path = 'Pullrequestcreate?targetRef=' + targetBranch + '&sourceRef=' + compareBranch;
        } else if (provider == 'Others') {
            String targetKey = '[TARGET_BRANCH_NAME]';
            String sourceKey = '[SOURCE_BRANCH_NAME]';
            Pattern myRegexp = Pattern.compile('\\[.*?\\]');
            Matcher myMatcher = myRegexp.matcher(url);
            List<String> matches = new List<String>();
            while (myMatcher.find()) {
                matches.add(myMatcher.group(0));
            }

            if (!matches.isEmpty() && matches.size() == 2) {
                url = url.replace(targetKey, targetBranch).replace(sourceKey, compareBranch);
            } else {
                addRecordsToMessageMap(C_WARNING, new List<String>{ Label.Missing_Parameter_Pull_Request, Label.Please_Go_Back_To_Record });
            }
        }

        if (provider == C_GITHUB || provider == C_GITLAB || provider == C_BITBUCKET || provider == C_MTS) {
            url = url.endsWith('/') ? url + path : url + '/' + path;
        }
        return url;
    }

    /**
     * This is used to redirect to the parent page after commit changes are completed
     * It will return to user story page after commit done.
     * @return
     */
    public PageReference waitForCommitChanges() {
        String snapshotId = ApexPages.currentPage().getParameters().get(C_SID);
        String snapshotStr = gitSnapshot.Id;
        String newSnapshotId = (String.isEmpty(snapshotId) && String.isNotBlank(snapshotStr)) ? snapshotStr : snapshotId;
        String commitType = ApexPages.currentPage().getParameters().get(C_CTYPE);
        String notificationType = 'GitCommit';
        if (String.isNotBlank(commitType) && commitType == DESTRUCTIVECHANGES) {
            notificationType = GITDELETION;
        }
        return copadoNotificationProcesses(
            notificationType,
            PSC,
            newSnapshotId,
            Label.Commit_Completed_Successfully,
            Label.Unexpected_Error_Commit_Changes,
            C_COMMIT,
            true,
            C_STD
        );
    }

    /**
     * This is used to find latest copado notification record to populate necessary information to the user.
     * @param notificationType  ==> type of the notification such as; Promotion, Git Commit
     * @param parentId  ==> parent id of the copado notification record
     * @param completedMessageLabel  ==> success message when the job is done and success
     * @param failMessageLabel  ==> fail message when the job is fail
     * @param pollerType  ==> for now only two values 'Commit' or 'Validation'
     * @param returnParentOnSuccess  ==> true or false based on requirement
     * @return
     */
    public PageReference copadoNotificationProcesses(
        String notificationType,
        String copadoNotificationName,
        Id parentId,
        String completedMessageLabel,
        String failMessageLabel,
        String pollerType,
        Boolean returnParentOnSuccess,
        String pageType
    ) {
        try {
            if (Schema.SObjectType.Copado_Notification__c.isAccessible() && Schema.SObjectType.Copado_Notification__c.isQueryable()) {
                if (copadoNotificationList == null || copadoNotificationList.isEmpty()) {
                    copadoNotificationList = [
                        SELECT Id, status__c, isSuccess__c, isFinished__c
                        FROM Copado_Notification__c
                        WHERE
                            Type__c = :notificationType
                            AND isSuccess__c = FALSE
                            AND isFinished__c = FALSE
                            AND Name = :copadoNotificationName
                            AND ParentId__c = :parentId
                            AND CreatedById = :UserInfo.getUserId()
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (!copadoNotificationList.isEmpty()) {
                        copadoNotificationId = copadoNotificationList[0].Id;
                    }
                } else {
                    String existingJobId = ApexPages.currentPage().getParameters().get('existingJobId');
                    String newJobId = String.isNotBlank(existingJobId) ? existingJobId : copadoNotificationId;
                    if (String.isNotBlank(newJobId)) {
                        copadoNotificationList = [
                            SELECT status__c, isSuccess__c, isFinished__c
                            FROM Copado_Notification__c
                            WHERE Id = :newJobId
                            LIMIT 1
                        ];
                    }
                }
                if (!copadoNotificationList.isEmpty() && !copadoNotificationList[0].isFinished__c) {
                    addRecordsToMessageMap(C_INFO, new List<String>{ copadoNotificationList[0].status__c });
                    return null;
                }
            } else {
                addRecordsToMessageMap(
                    C_WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Copado_Notification__c.getLabel()
                    }
                );
                return null;
            }
        } catch (Exception ex) {
            addRecordsToMessageMap(C_ERROR, new List<String>{ ex.getMessage() });
            return null;
        }

        if (
            !copadoNotificationList.isEmpty() &&
            copadoNotificationList[0].status__c != null &&
            copadoNotificationList[0].status__c.contains(C_DONE) &&
            copadoNotificationList[0].isFinished__c
        ) {
            if (copadoNotificationList[0].isSuccess__c) {
                addRecordsToMessageMap(C_SUCCESS, new List<String>{ completedMessageLabel });
                notificationStatusMap.put(notificationType, true);
                copadoNotificationList = new List<Copado_Notification__c>();
                if (returnParentOnSuccess) {
                    return getReturnUrlWithParameter(pageType);
                }
            } else {
                addRecordsToMessageMap(C_WARNING, new List<String>{ failMessageLabel, Label.Please_Go_Back_To_Record });
                enableCommitChangesPoller = false;
                enableValidationPoller = false;
                enableTestRunPoller = false;
                return null;
            }

            if (returnParentOnSuccess) {
                if (pollerType == C_COMMIT) {
                    enableCommitChangesPoller = false;
                } else if (pollerType == VALIDATION) {
                    enableValidationPoller = false;
                } else if (pollerType == C_TESTRUN) {
                    enableTestRunPoller = false;
                }
            }
        } else {
            String message = String.isNotBlank(this.lastCalloutMessageFromAPI) ? this.lastCalloutMessageFromAPI : Label.Initializing;
            addRecordsToMessageMap(C_INFO, new List<String>{ message });
        }
        return null;
    }

    /**
     * This is used to make a callout to the backend to create job for test run
     */
    public void apexTestRunCallOut() {
        Settings cSetting = new Settings();
        String baseUrl = cSetting.urlBase;
        String namespace = Settings.ns;
        String urlParameter = Settings.generic_heroku_params;
        namespace = String.isBlank(namespace) ? 'none' : namespace;
        String testClassList = ApexPages.currentPage().getParameters().get('testClassList');
        String testClassNS = ApexPages.currentPage().getParameters().get('testClassNamespace');
        testClassNS = String.isNotBlank(testClassNS) && testClassNS.endsWith('/') ? testClassNS.removeEnd('/') : testClassNS;
        String finalUrl =
            baseUrl +
            'apexTest/' +
            userStory.Org_Credential__c +
            '/' +
            testClassNS +
            '/' +
            testClassList +
            urlParameter +
            '&parentId=' +
            userStory.Id;
        doCallOut(finalUrl, C_TESTRUN, Label.Unexpected_Error_Apex_Test_Run);
        notificationStatusMap = new Map<String, Boolean>();
        notificationStatusMap.put(C_TESTRUN, false);
    }

    /**
     * This is used to redirect to the parent page after apex test run is completed
     * It will return to apex test run page after test run done
     */
    public PageReference waitForApexTestRun() {
        return copadoNotificationProcesses(
            C_TESTRUN,
            PSC,
            userStory.Id,
            Label.Apex_Test_Run_Completed_Successfully,
            Label.Unexpected_Error_Apex_Test_Run,
            C_TESTRUN,
            true,
            C_TESTRUN
        );
    }

    /**
     * This is used to make all call out to the backend
     * @param finalUrl ==> final url for endpoint
     * @param pollerType ==> poller type  to render poller variables
     * @param errorMessage ==> error message you want to show at page if the response returns nothing
     */
    public Map<String, Object> doCallOut(String finalUrl, String pollerType, String errorMessage) {
        try {
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setEndpoint(finalUrl);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (responseMap.isEmpty()) {
                addRecordsToMessageMap(C_ERROR, new List<String>{ errorMessage, Label.Please_Go_Back_To_Record });
                return null;
            }
            if (responseMap.containsKey(C_ERROR)) {
                if (pollerType == C_TESTRUN) {
                    enableTestRunPoller = false;
                } else if (pollerType == C_COMMIT) {
                    enableCommitChangesPoller = false;
                }
                addRecordsToMessageMap(C_ERROR, new List<String>{ String.valueOf(responseMap.get(C_ERROR)), Label.Please_Go_Back_To_Record });
                return null;
            } else {
                if (pollerType == C_TESTRUN) {
                    enableTestRunPoller = true;
                } else if (pollerType == C_COMMIT) {
                    enableCommitChangesPoller = true;
                }
                this.lastCalloutMessageFromAPI = String.valueOf(responseMap.get('ok'));
                addRecordsToMessageMap(C_INFO, new List<String>{ this.lastCalloutMessageFromAPI });
                return responseMap;
            }
        } catch (Exception ex) {
            if (pollerType == C_TESTRUN) {
                enableTestRunPoller = false;
            } else if (pollerType == C_COMMIT) {
                enableCommitChangesPoller = false;
            }
            addRecordsToMessageMap(C_ERROR, new List<String>{ ex.getMessage() });
        }
        return null;
    }

    /**
     * It is used to add messages to the pageMessagesMap map
     */
    private void addRecordsToMessageMap(String severity, List<String> messageList) {
        pageMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(severity, messageList, pageMessagesMap);
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getPageMessageSize() {
        Integer listsize = 0;
        for (String severity : pageMessagesMap.keySet()) {
            listsize += pageMessagesMap.get(severity).size();
        }
        return listsize;
    }
}