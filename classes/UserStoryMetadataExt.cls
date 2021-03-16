/**
 * @description Extension controller for UserStoryMetadata.page
 *
 */
public with sharing class UserStoryMetadataExt {
    // Non Constant
    public User_Story_Metadata__c usMetadata { get; set; }
    public List<User_Story_Metadata__c> usMetadataList {
        get {
            if (usMetadataList == null) {
                usMetadataList = getUserStoryMetadatas();
            }
            return usMetadataList;
        }
        set;
    }
    private ApexPages.StandardController controller { get; set; }
    public Map<String, User_Story_Metadata__c> usmMap { get; set; }
    public Map<String, PullConfig> usConfigMap { get; set; }
    public PullConfig latestPull { get; set; }
    private String usMetadataColumnNames;

    public Integer offset {
        get {
            if (offset == null) {
                offset = 0;
            }
            return offset;
        }
        set;
    }
    public Boolean disableNext { get; set; }
    public Boolean disablePrevious { get; set; }
    private String Status = '';
    public String metadataId = '';

    // Constants
    public static final Integer OFFSET_INTERVAL = 100;
    private static final String FEATURE = 'feature/';

    /**
     * @description Contructor
     */
    public UserStoryMetadataExt(ApexPages.StandardController stdController) {
        controller = stdController;
        usMetadataColumnNames = '';
        List<Schema.FieldSetMember> fieldSetMemberList = SObjectType.User_Story_Metadata__c.fieldSets.Copado_User_Story_Metadata_Columns.getFields();
        for (Schema.FieldSetMember fsm : fieldSetMemberList) {
            usMetadataColumnNames += fsm.getFieldPath() + ',';
        }

        usMetadataColumnNames = usMetadataColumnNames.removeEnd(',');
        retrieveMetadata();
    }
    /**
     * @description This method retrieves "User Story Metadata" record data related to metadata selected in user story.
     * @throws warning in case user story is marked to stop indexing metadata.
     */
    public void retrieveMetadata() {
        usmMap = new Map<String, User_Story_Metadata__c>();
        if (Schema.SObjectType.User_Story_Metadata__c.isQueryable() && Schema.SObjectType.User_Story_Metadata__c.isAccessible()) {
            usMetadata = [
                SELECT
                    Id,
                    Name,
                    Last_Commit_Date__c,
                    User_Story__r.Name,
                    User_Story__r.Project__r.Deployment_Flow__c,
                    User_Story__r.Release__r.Project__r.Deployment_Flow__c,
                    Status__c,
                    Status_Icon__c,
                    Metadata_API_Name__c,
                    User_Story__c,
                    User_Story__r.Environment__c,
                    User_Story__r.User_Story_Title__c,
                    LastModifiedDate,
                    User_Story__r.Stop_Indexing_Metadata__c
                FROM User_Story_Metadata__c
                WHERE Id = :controller.getId()
                LIMIT 1
            ];
            if (usMetadata.User_Story__r.Stop_Indexing_Metadata__c) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.USER_STORY_MARKED_STOP_INDEXING_METADATA);
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Metadata__c.getLabel());
            return;
        }

        if (usMetadata == null) {
            usMetadata = new User_Story_Metadata__c();
        }
    }
    /**
     * @description Set up pull request for the US
     * @param compareUS comes from URL.
     * @return Pagereference
     */
    public PageReference preparePullRequest() {
        if (usConfigMap == null) {
            usConfigMap = new Map<String, PullConfig>();
        }
        String compareUS = ApexPages.currentPage().getParameters().get('compareUS');
        if (String.isBlank(compareUS) || !usmMap.containsKey(compareUS)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Nothing_To_Compare);
            return null;
        } else {
            if (usConfigMap.containsKey(compareUS)) {
                latestPull = usConfigMap.get(compareUS);
                return null;
            }

            String baseDF, compareDF;
            if (String.isBlank(usMetadata.User_Story__r.Project__c) && String.isBlank(usMetadata.User_Story__r.Release__c)) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.BASE_US_PROJECT_OR_RELEASE);
                return null;
            } else if (
                String.isBlank(usMetadata.User_Story__r.Project__r.Deployment_Flow__c) &&
                String.isBlank(usMetadata.User_Story__r.Release__r.Project__r.Deployment_Flow__c)
            ) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.BASE_US_DEPLOYMENT_FLOW);
                return null;
            } else {
                baseDF = !String.isBlank(usMetadata.User_Story__r.Project__r.Deployment_Flow__c)
                    ? usMetadata.User_Story__r.Project__r.Deployment_Flow__c
                    : usMetadata.User_Story__r.Release__r.Project__r.Deployment_Flow__c;
            }
            User_Story_Metadata__c tempUS = usmMap.get(compareUS);
            if (String.isBlank(tempUS.User_Story__r.Project__c) && String.isBlank(tempUS.User_Story__r.Release__c)) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.COMPAIRING_US_PROJECT_OR_RELEASE);
                return null;
            } else if (
                String.isBlank(tempUS.User_Story__r.Project__r.Deployment_Flow__c) &&
                String.isBlank(tempUS.User_Story__r.Release__r.Project__r.Deployment_Flow__c)
            ) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.COMPAIRING_US_DEPLOYMENT_FLOW);
                return null;
            } else {
                compareDF = !String.isBlank(tempUS.User_Story__r.Project__r.Deployment_Flow__c)
                    ? tempUS.User_Story__r.Project__r.Deployment_Flow__c
                    : tempUS.User_Story__r.Release__r.Project__r.Deployment_Flow__c;
            }

            if (baseDF != compareDF) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.BASE_COMPARING_US_FLOW);
            } else {
                List<String> extraFieldsList = new List<String>();
                String namespace = Settings.ns;
                extraFieldsList.add(namespace + 'Git_Repository__r.Pull_Request_Base_URL__c');
                extraFieldsList.add(namespace + 'Git_Repository__r.Git_Provider__c');
                GlobalUtilities.deploymentFlowDetails flowDetails = GlobalUtilities.getDeploymentFlowDetails(
                    baseDF,
                    String.join(extraFieldsList, ', ')
                );
                if (flowDetails.flow.Active__c) {
                    if (
                        String.isBlank(flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c) ||
                        String.isBlank(flowDetails.flow.Git_Repository__r.Git_Provider__c)
                    ) {
                        UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.PULLREQUEST_BASE_URL_AND_TYPE);
                    } else {
                        latestPull = new pullConfig(
                            flowDetails.flow.Git_Repository__r.Git_Provider__c,
                            flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c,
                            FEATURE + usMetadata.User_Story__r.Name,
                            FEATURE + tempUS.User_Story__r.Name
                        );
                        usConfigMap.put(compareUS, latestPull);
                    }
                } else {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.FLOW_NEEDS_TO_BE_ACTVE);
                }
            }
            return null;
        }
    }
    /**
     * @description wrapper class to store pull request config information related to user story
     */
    public class PullConfig {
        public String gitType { get; set; }
        public String pullURL { get; set; }
        public String base { get; set; }
        public String compare { get; set; }

        public pullConfig(String gitType, String pullURL, String base, String compare) {
            this.gitType = gitType;
            this.pullURL = pullURL;
            this.base = base;
            this.compare = compare;
        }
    }
    /**
     * @description It get User Story metadata statuses shown in USerStoryMetadata.page
     * @return Selectoption list of User Story metadata statuses picklist values.
     */
    public List<SelectOption> getStatuses() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult statusDescribe = User_Story_Metadata__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> statusesList = statusDescribe.getPicklistValues();

        for (Schema.PicklistEntry pe : statusesList) {
            options.add(new SelectOption(pe.getLabel(), pe.getValue()));
        }
        return options;
    }
    /**
     * @description It update all status selected in VF page
     */
    public void updateStatuses() {
        metadataId = usMetadata.Id;
        updateStatus();
        for (User_Story_Metadata__c usm : usMetadataList) {
            metadataId = usm.Id;
            updateStatus();
        }
        // Saved for Copado v9.0 retrieveMetadata();
    }
    /**
     * @description It updates status for selected metadata record.
     * @param Status comes from the URL. It is new status to be updated.
     * @param metadataId comes from the URL. It is record to be updated.
     * @return Page Reference
     * @throws exception through UIDesignHelper
     */
    public PageReference updateStatus() {
        try {
            Status = ApexPages.currentPage().getParameters().get('Status');
            Boolean isSingleUpdate = false;
            if (String.isBlank(metadataId)) {
                metadataId = ApexPages.currentPage().getParameters().get('metadataId');
                isSingleUpdate = true;
            }

            if (usmMap.containsKey(metadataId)) {
                usmMap.get(metadataId).Status__c = Status;
                Utilities.Secure_DML(usmMap.get(metadataId), Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
            } else if (usMetadata != null && String.valueOf(usMetadata.Id) == metadataId) {
                usMetadata.Status__c = Status;
                Utilities.Secure_DML(usMetadata, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
            }

            // Saved for Copado v9.0 if(isSingleUpdate)retrieveMetadata();
            metadataId = '';
        } catch (Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
        }
        return null;
    }
    /**
     * @description  Overrides standard delete function
     * @return Pagereference
     * @throws exception through UIDesignHelper
     * @see Utilities
     * @see UIDesignHelper
     */
    public PageReference deleteJob() {
        if (usMetadata.Id != null) {
            PageReference retPage;
            if (usMetadata.User_Story__c != null) {
                User_Story__c uSc = new User_Story__c(Id = usMetadata.User_Story__c);
                retPage = new ApexPages.StandardController(uSc).view();
            } else {
                retPage = new PageReference('/home/home.jsp');
            }
            retPage.setRedirect(true);
            try {
                Utilities.Secure_DML(usMetadata, Utilities.DML_Action.DEL, schema.SObjectType.User_Story_Metadata__c);
                return retPage;
            } catch (Exception ex) {
                UIDesignHelper.catchExceptionMessage(ex);
            }
        }
        return null;
    }
    /**
     * @description In case of pagination it takes the user to the previous page.
     * @return Pagereference
     */
    public PageReference previousUserStoryMetadatas() {
        offset = offset - OFFSET_INTERVAL;
        usMetadataList = getUserStoryMetadatas();
        disableNext = false;
        return null;
    }
    /**
     * @description In case of pagination it takes the user to the next page.
     * @return Pagereference
     */
    public PageReference nextUserStoryMetadatas() {
        offset = offset + OFFSET_INTERVAL;
        usMetadataList = getUserStoryMetadatas();
        disablePrevious = false;
        return null;
    }
    /**
     * @description  Get the list of User Story Metadata related
     * @return a List of User Story Metadata in other User Stories.
     * @throws exception through UIDesignHelper
     * @see UIDesignHelper
     */
    public List<User_Story_Metadata__c> getUserStoryMetadatas() {
        List<User_Story_Metadata__c> usMetadataList = new List<User_Story_Metadata__c>();
        if (String.isBlank(usMetadata.Id) || usMetadata.User_Story__r.Stop_Indexing_Metadata__c) {
            return usMetadataList;
        }
        if (Schema.SObjectType.User_Story_Metadata__c.isQueryable() && Schema.SObjectType.User_Story_Metadata__c.isAccessible()) {
            String query =
                ' SELECT Id, User_Story__r.Name, User_Story__r.Project__c, User_Story__r.Project__r.Deployment_Flow__c, User_Story__r.Release__c, User_Story__r.Release__r.Project__r.Deployment_Flow__c, ' +
                usMetadataColumnNames +
                ' FROM User_Story_Metadata__c WHERE Id != \'' +
                String.escapeSingleQuotes(usMetadata.Id) +
                '\' AND Metadata_API_Name__c = \'' +
                String.escapeSingleQuotes(usMetadata.Metadata_API_Name__c) +
                '\' AND User_Story__r.Stop_Indexing_Metadata__c != TRUE LIMIT ' +
                OFFSET_INTERVAL +
                ' OFFSET ' +
                offset;
            usMetadataList = Database.query(query);
            for (User_Story_Metadata__c usm : usMetadataList) {
                usmMap.put(usm.Id, usm);
            }

            if (offset == 0) {
                disablePrevious = true;
            }

            if (offset == 2000 || usMetadataList.size() < OFFSET_INTERVAL) {
                disableNext = true;
            }

            return usMetadataList;
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Metadata__c.getLabel());
            return usMetadataList;
        }
    }
}