public with sharing class GitCommit_IntermediaryController extends GitCommit_ComponentBase {
    // Non Constant
    public Boolean dxBranchJobStarted {
        get {
            if (null == dxBranchJobStarted) {
                dxBranchJobStarted = false;
            }
            return dxBranchJobStarted;
        }
        set;
    }
    public Map<String, Set<Object>> componentMessagesMap {
        get {
            if (null == componentMessagesMap) {
                componentMessagesMap = new Map<String, Set<Object>>();
            }
            return componentMessagesMap;
        }
        set;
    }
    @TestVisible
    private String copadoNotificationId;
    @TestVisible
    private List<Copado_Notification__c> copadoNotificationList;

    // Constants
    private final String SNAPSHOT_ID = 'gitSnapshotId';
    private final String USER_STORY_ID = 'userStoryId';
    private final String VARIANT = 'variant';
    private final String PRESELECTION_ID = 'MetadataPreselectionId';

    /**
     * It is used to populate pageController.snapshot record
     * It will add another parameter to URL to get snapshotId from URL
     */
    public PageReference populateSnapshotRecord() {
        String snapshotId = ApexPages.currentPage().getParameters().get(SNAPSHOT_ID);
        String attachmentId = ApexPages.currentPage().getParameters().get(PRESELECTION_ID);
        PageReference pReference = Page.GitCommitMain;
        if (pageController != null && String.isNotBlank(pageController.userStory.Id)) {
            pReference.getParameters().put(USER_STORY_ID, pageController.userStory.Id);
        }
        if (String.isNotBlank(snapshotId)) {
            pReference.getParameters().put(SNAPSHOT_ID, snapshotId);
        }
        if (String.isNotBlank(pageController.variant)) {
            pReference.getParameters().put(VARIANT, pageController.variant);
        }
        if (String.isNotBlank(attachmentId)) {
            pReference.getParameters().put(PRESELECTION_ID, attachmentId);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to make a call out to backend for creating dx branch for user story
     * dxBranchJobStarted is set true to make action poller start at component
     *
     * @see SfdxAPI.createProjectBranch
     */
    public void createDXBranch() {
        try {
            String projectGitRepo = pageController.userStory.Project__r.Deployment_Flow__r.Git_Repository__c;
            String releaseProjectGitRepo = pageController.userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
            String depFlowGitRepoId = String.isNotBlank(projectGitRepo)
                ? projectGitRepo
                : String.isNotBlank(releaseProjectGitRepo) ? releaseProjectGitRepo : '';

            SfdxAPI.createProjectBranch(pageController.userStory.Org_Credential__c, depFlowGitRepoId);
            dxBranchJobStarted = true;
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_INFO,
                new List<String>{ Label.Initializing },
                componentMessagesMap
            );
        } catch (Exception excp) {
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_ERROR,
                new List<String>{ excp.getMessage() },
                componentMessagesMap
            );
        }
    }

    /**
     * It is used to check notification
     *
     * @return
     */
    public PageReference pollerHandler() {
        String notificationType = CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH;
        String copadoNotificationName = CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH + ' null';
        try {
            if (Schema.SObjectType.Copado_Notification__c.isAccessible() && Schema.SObjectType.Copado_Notification__c.isQueryable()) {
                if (copadoNotificationList == null || copadoNotificationList.isEmpty()) {
                    copadoNotificationList = [
                        SELECT Id, status__c, isSuccess__c, isFinished__c, Message__c
                        FROM Copado_Notification__c
                        WHERE
                            Type__c = :notificationType
                            AND isSuccess__c = FALSE
                            AND isFinished__c = FALSE
                            AND Name = :copadoNotificationName
                            AND CreatedById = :UserInfo.getUserId()
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (!copadoNotificationList.isEmpty()) {
                        copadoNotificationId = copadoNotificationList[0].Id;
                    }
                } else {
                    if (String.isNotBlank(copadoNotificationId)) {
                        copadoNotificationList = [
                            SELECT status__c, isSuccess__c, isFinished__c, Message__c
                            FROM Copado_Notification__c
                            WHERE Id = :copadoNotificationId
                            LIMIT 1
                        ];
                    }
                }
                if (!copadoNotificationList.isEmpty() && !copadoNotificationList[0].isFinished__c) {
                    componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                        C_INFO,
                        new List<String>{ copadoNotificationList[0].status__c },
                        componentMessagesMap
                    );
                    return null;
                }
            } else {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Copado_Notification__c.getLabel()
                    },
                    componentMessagesMap
                );
                return null;
            }
        } catch (Exception ex) {
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_ERROR,
                new List<String>{ ex.getMessage() },
                componentMessagesMap
            );
            return null;
        }

        if (!copadoNotificationList.isEmpty() && copadoNotificationList[0].status__c != null && copadoNotificationList[0].isFinished__c) {
            if (copadoNotificationList[0].isSuccess__c) {
                PageReference pReference = Page.GitCommitMain;
                pReference.getParameters().put(USER_STORY_ID, pageController.userStory.Id);
                pReference.getParameters().put(VARIANT, pageController.variant);
                pReference.setRedirect(true);
                return pReference;
            } else {
                if (copadoNotificationList[0].Message__c != null) {
                    componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                        C_WARNING,
                        new List<String>{ copadoNotificationList[0].Message__c },
                        componentMessagesMap
                    );
                }
                dxBranchJobStarted = false;
                return null;
            }
        } else {
            String message = Label.Initializing;
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
            return null;
        }
    }

    /**
     * It is used to return message count to the intermediary component based on dx project branch creation job
     *
     * @return
     */
    public Integer getComponentMessageSize() {
        Integer listsize = 0;
        for (String severity : componentMessagesMap.keySet()) {
            listsize += componentMessagesMap.get(severity).size();
        }
        return listsize;
    }

    /**
     * It is used to return to the user story when the dx project branch creation job fails
     *
     * @return
     */
    public PageReference goBackToUserStory() {
        PageReference pReference = new ApexPages.StandardController(pageController.userStory).view();
        pReference.setRedirect(true);
        return pReference;
    }
}