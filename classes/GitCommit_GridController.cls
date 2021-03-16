public with sharing class GitCommit_GridController extends GitCommit_ComponentBase {
    // Non Constant
    public String orgMetadataTypeFilter {
        get {
            if (String.isNotBlank(pageController.userStory.Org_Credential__r.Metadata_Types__c)) {
                orgMetadataTypeFilter = '&filter=' + EncodingUtil.urlEncode(pageController.userStory.Org_Credential__r.Metadata_Types__c, 'UTF-8');
            }
            return orgMetadataTypeFilter;
        }
        set;
    }
    public String artifactsParentOrgId {
        get {
            if (
                String.isBlank(artifactsParentOrgId) &&
                null != pageController &&
                null != pageController.snapshot &&
                null != pageController.snapshot.Org__c
            ) {
                artifactsParentOrgId = SfdxAPIHelper.getSOartifactParentId(pageController.snapshot.Org__c);
            }
            return artifactsParentOrgId;
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
    public Boolean isVlocitySucceeded {
        get {
            if (null == isVlocitySucceeded) {
                isVlocitySucceeded = false;
            }
            return isVlocitySucceeded;
        }
        set;
    }
    public Boolean isRefreshCacheSucceeded {
        get {
            if (null == isRefreshCacheSucceeded) {
                isRefreshCacheSucceeded = false;
            }
            return isRefreshCacheSucceeded;
        }
        set;
    }
    public Boolean showCloseVlocityPromtButton {
        get {
            if (null == showCloseVlocityPromtButton) {
                showCloseVlocityPromtButton = false;
            }
            return showCloseVlocityPromtButton;
        }
        set;
    }
    public Boolean showRefreshCachePromtButton {
        get {
            if (null == showRefreshCachePromtButton) {
                showRefreshCachePromtButton = false;
            }
            return showRefreshCachePromtButton;
        }
        set;
    }
    public Boolean startActionPoller {
        get {
            if (null == startActionPoller) {
                startActionPoller = false;
            }
            return startActionPoller;
        }
        set;
    }
    @TestVisible
    private String operationName {
        get {
            if (null == operationName) {
                operationName = '';
            }
            return operationName;
        }
        set;
    }

    private Boolean hasMetadataAttachment {
        get {
            if (hasMetadataAttachment == null) {
                List<Attachment> atts = [SELECT Id FROM Attachment WHERE ParentId = :pageController.snapshot.Org__c AND Name = 'MetaData' LIMIT 1];
                hasMetadataAttachment = !atts.isEmpty();
            }
            return hasMetadataAttachment;
        }
        set;
    }

    private Boolean isSourceMemberAvailable {
        get {
            if (isSourceMemberAvailable == null) {
                isSourceMemberAvailable = true;
                try {
                    new RefreshRecentChanges(pageController.snapshot.Org__c).execute();
                } catch (Exception e) {
                    if (e.getMessage() != null && e.getMessage().contains('sObject type \'SourceMember\' is not supported')) {
                        isSourceMemberAvailable = false;
                    } else {
                        // No section is rerendered for this now, but it is handled in retrieveRecentChanges()
                        pageController.pageMessagesMap.put(C_ERROR, new Set<Object>{ e.getMessage() });
                    }
                }
            }
            return isSourceMemberAvailable;
        }
        set;
    }

    public Boolean isRecentChangesEnabled {
        get {
            return hasMetadataAttachment && isSourceMemberAvailable;
        }
        set;
    }

    public String refreshHelpTooltipMessage {
        get {
            String result = Label.REFRESH_SINCE_LAST_DATE;
            if (!hasMetadataAttachment) {
                result = Label.NO_METADATA_ATTACHMENT;
            } else if (!isSourceMemberAvailable) {
                result = Label.SOURCE_MEMBER_NOT_SUPPORTED;
            }
            return result;
        }
        set;
    }

    // Constants
    private final String METADATA_DEPENDENCIES_JOB = 'MetadataDependenciesJob';
    private final String VLOCITY = 'vlocity';
    private final String REFRESH_CACHE = 'refreshCache';

    public void initPoller() {
        operationName = ApexPages.currentPage().getParameters().get('operation');
        startActionPoller = true;
        if (String.isNotBlank(operationName) && operationName == VLOCITY) {
            isVlocitySucceeded = false;
        }
        if (String.isNotBlank(operationName) && operationName == REFRESH_CACHE) {
            isRefreshCacheSucceeded = false;
        }
        String message = Label.Initializing;
        componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
    }

    public PageReference pollerHandler() {
        if (String.isNotBlank(operationName) && operationName == VLOCITY) {
            isVlocitySucceeded = copadoNotificationProcesses();
        }
        if (String.isNotBlank(operationName) && operationName == REFRESH_CACHE) {
            isRefreshCacheSucceeded = copadoNotificationProcesses();
        }
        return null;
    }

    /**
     * This is used to find latest copado notification record to populate necessary information to the user.
     * @return
     */
    public Boolean copadoNotificationProcesses() {
        Boolean vlocityOperation = String.isNotBlank(operationName) && operationName == VLOCITY;
        String parentId = vlocityOperation ? pageController.userStory.Id : pageController.snapshot.Org__c;
        String failMessageLabel = vlocityOperation ? Label.Vlocity_Dependency_Retrieve_Job_Fail : Label.Refresh_Metadata_Job_Fail;
        String notificationType = vlocityOperation ? METADATA_DEPENDENCIES_JOB : 'MetadataRetriever';
        String copadoNotificationName = vlocityOperation
            ? METADATA_DEPENDENCIES_JOB + ' ' + parentId
            : CopadoNotificationHelper.PROGRESS_STATUS_COPADO;

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
                    if (String.isNotBlank(copadoNotificationId)) {
                        copadoNotificationList = [
                            SELECT status__c, isSuccess__c, isFinished__c
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
                    return false;
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
                return false;
            }
        } catch (Exception ex) {
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_ERROR,
                new List<String>{ ex.getMessage() },
                componentMessagesMap
            );
            return false;
        }
        if (
            !copadoNotificationList.isEmpty() &&
            copadoNotificationList[0].status__c != null &&
            copadoNotificationList[0].status__c.contains(C_DONE) &&
            copadoNotificationList[0].isFinished__c
        ) {
            if (copadoNotificationList[0].isSuccess__c) {
                return true;
            } else {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_WARNING,
                    new List<String>{ failMessageLabel },
                    componentMessagesMap
                );
                showCloseVlocityPromtButton = pageController.showVlocity ? true : false;
                showRefreshCachePromtButton = true;
                return false;
            }
        } else {
            String message = Label.Initializing;
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
            return false;
        }
    }

    /**
     * It is used to count messages size in the list, so at the component it will be used to render icons and spninner
     *
     * @return
     */
    public Integer getComponentMessageSize() {
        Integer listSize = 0;
        for (String severity : componentMessagesMap.keySet()) {
            listSize += componentMessagesMap.get(severity).size();
        }
        return listSize;
    }

    /**
     * It is used to clear componentMessagesMap to use again in other action
     */
    public void clearMessagesMap() {
        componentMessagesMap = new Map<String, Set<Object>>();
        copadoNotificationList = new List<Copado_Notification__c>();
        copadoNotificationId = '';
        showCloseVlocityPromtButton = false;
        showRefreshCachePromtButton = false;
        isVlocitySucceeded = false;
        startActionPoller = false;
    }

    @RemoteAction
    public static List<Object> retrieveRecentChanges(String orgId) {
        try {
            return new RefreshRecentChanges(orgId).execute();
        } catch (Exception e) {
            // Possible exceptions would have already been raised in isSourceMemberAvailable property
            // and added to the map. They will be displayed after this method call rerenders the proper section
            return null;
        }
    }
}