/**
 * This is main controller of GitCommitMain page which extends GitCommit_PageBase to keep communication between components
 */
public with sharing class GitCommit_MainPageController extends GitCommit_PageBase {
    // Non Constants
    public GitCommit_ComponentBase myComponentController { get; set; }
    private CommitService commitInterface;

    public GitCommit_MainPageController() {
        checkLicenseAndPermission();

        if (pageMessagesMap.isEmpty()) {
            Map<String, String> params = ApexPages.currentPage().getParameters();
            userStory.Id = params.get('userStoryId');
            snapshot.Id = params.get('snapshotId');
            variant = params.get('variant');
            initializeServiceClasses();
        }
        if (pageMessagesMap.isEmpty()) {
            loadAndValidateParameters();
        }
        if (pageMessagesMap.isEmpty()) {
            requestGitOperationsFile();
            showVlocity = (null != Feature__c.getValues(VLOCITY) ? Feature__c.getValues(VLOCITY).Enabled__c : false);
        }
    }

    public override void setComponentController(GitCommit_ComponentBase compController) {
        myComponentController = (GitCommit_ComponentBase) compController;
    }

    /*public override GitCommit_ComponentBase getMyComponentController() {
        return myComponentController;
    }*/

    /**
     * Strategy pattern
     * Based on the page content, different services will be initialised by using CommitService interface
     * User Story Commit will initialize UserStoryCommitService()
     * Snapshot Commit will initialize SnapshotCommitService()
     *
     * @see CommitService
     */
    private void initializeServiceClasses() {
        if (String.isNotBlank(variant)) {
            if (variant.toLowerCase() == 'userstorycommit') {
                commitInterface = new UserStoryCommitService();
            } else if (variant.toLowerCase() == 'gitsnapshotcommit') {
                commitInterface = new SnapshotCommitService();
            } else if (variant.toLowerCase() == 'dxcommit') {
                commitInterface = new DxCommitService();
            } else {
                pageMessagesMap.put(C_ERROR, new Set<Object>{ Label.Unsupported_Service });
            }
        } else {
            pageMessagesMap.put(C_ERROR, new Set<Object>{ Label.Variant_Is_Not_Defined });
        }
    }

    /**
     * It is used to check all license and permission check before loading page content
     */
    private void checkLicenseAndPermission() {
        if (LicenseHelper.isLicensesExceeded()) {
            pageMessagesMap.put(C_WARNING, new Set<Object>{ Label.LICENSES_EXCEEDED });
        }
        if (!LicenseHelper.actionIsLicenseEnabled('commitFiles')) {
            pageMessagesMap.put(C_WARNING, new Set<Object>{ Label.CCM_License_Restriction });
        }
        if (!FeatureHelper.isChangeChangeManagementEnabled()) {
            pageMessagesMap.put(C_WARNING, new Set<Object>{ Label.FEATURE_NOT_SUPPORTED });
        }
        if (!Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            pageMessagesMap.put(C_WARNING, new Set<Object>{ Label.MISSING_PERMISSIONS_CBM_FLOW });
        }
    }

    /**
     * It is used to retrieve necessary records for component
     * Check that the snapshot is commitable, that the snapshot/org matches, etc.
     * Main branch population deployment flow > user story > release
     *
     * @see GitCommit_PageBase
     * @see CommitService
     * @see initializeServiceClasses
     */
    private void loadAndValidateParameters() {
        String namespace = Settings.ns;
        try {
            pageHeaderText = commitInterface.getPageHeader();
            GitCommit_PageBase serviceBase = commitInterface.loadAndValidateBaseRecords(namespace, userStory.Id, snapshot.Id);

            this.userStory = serviceBase.userStory;
            this.snapshot = serviceBase.snapshot;
            this.snapshotList = serviceBase.snapshotList;
            this.userStoryBaseBranch = serviceBase.userStoryBaseBranch;
            this.userStoryRecordJson = serviceBase.userStoryRecordJson;
            this.snapshotRecordJson = serviceBase.snapshotRecordJson;
            this.showCreateDXBranchPrompt = serviceBase.showCreateDXBranchPrompt;

            if (String.isNotBlank(userStory.Org_Credential__c)) {
                List<UserRecordAccess> usersRecordAccess = [
                    SELECT RecordId, HasEditAccess
                    FROM UserRecordAccess
                    WHERE UserId = :UserInfo.getUserId() AND RecordId = :userStory.Org_Credential__c
                ];

                if (!usersRecordAccess.isEmpty() && !usersRecordAccess[0].HasEditAccess) {
                    pageMessagesMap.put(C_WARNING, new Set<Object>{ Label.Read_Write_Access_Missing });
                    userHasAccess = false;
                    snapshotList.clear();
                }
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new Set<Object>{ excp.getMessage() });
            return;
        }
    }

    /**
     * It calls backend for Git Operations file which contains options JSON file
     * Endpoint is: '/json/v1/gitOperations'
     * @see parseGitOperationsFile method to see response parse
     */
    public void requestGitOperationsFile() {
        try {
            String callUrul = Settings.server_url + '/json/v1/gitOperations';
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String body = res.getBody();
            parseGitOperationsFile(body);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new Set<Object>{ Label.Connection_Problem });
        }
    }

    /**
     * It is parser method for Git Operations file retrieved from backend
     * @param jsonStr Backend call Http response body
     * @see GitCommit_PageBase for Operation wrapper
     */
    @TestVisible
    private void parseGitOperationsFile(String jsonStr) {
        List<Object> jsonObject = new List<Object>();
        try {
            jsonObject = (List<Object>) JSON.deserializeUntyped(jsonStr);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new Set<Object>{ Label.Error_Parsing_Git_File });
            return;
        }

        //This is for showing a git operation if a related Git Operation Permission found in custom setting
        //Ordering By SetupOwner.Type is for if 2 custom setting found for user choose User setting over Profile setting
        Set<String> allowedGitOperationLabels = new Set<String>();
        List<Git_Operation_Restriction__c> allowedGitOperations = new List<Git_Operation_Restriction__c>();
        allowedGitOperations = [
            SELECT Id, SetupOwner.Name, SetupOwner.Type, SetupOwnerId, Git_Operation_Name__c, Active__c
            FROM Git_Operation_Restriction__c
            WHERE (SetupOwnerId = :UserInfo.getUserId() OR SetupOwnerId = :UserInfo.getProfileId()) AND Active__c = true
            ORDER BY SetupOwnerId
        ];

        Git_Operation_Restriction__c orgDefaultRestriction = Git_Operation_Restriction__c.getOrgDefaults();
        if (null != orgDefaultRestriction && orgDefaultRestriction.Active__c == true) {
            allowedGitOperations.add(orgDefaultRestriction);
        }

        if (!allowedGitOperations.isEmpty()) {
            List<String> allowedGitOperationsLabelsList = new List<String>();
            allowedGitOperationsLabelsList.addAll(allowedGitOperations[0].Git_Operation_Name__c.trim().toLowerCase().split(';'));
            if (!allowedGitOperationsLabelsList.isEmpty()) {
                for (Integer i = 0; i < allowedGitOperationsLabelsList.size(); i++) {
                    allowedGitOperationsLabelsList[i] = allowedGitOperationsLabelsList[i].trim();
                }
                allowedGitOperationLabels.addAll(allowedGitOperationsLabelsList);
            }
        }

        for (Object jsonObj : jsonObject) {
            Operation op = new Operation();
            try {
                op = (Operation) JSON.deserialize(JSON.serialize(jsonObj), Operation.class);
            } catch (Exception excp) {
                pageMessagesMap.put(C_ERROR, new Set<Object>{ excp.getMessage() });
                continue;
            }

            // If operation label exist in custom setting OR if there is no active custom setting then add it to picklist
            // TODO until US-0006586 completed Dx and vlocity operations will be hard coded
            if (
                (String.isNotBlank(op.operationLabel) &&
                String.isNotBlank(variant) &&
                variant.toLowerCase() == 'gitsnapshotcommit' &&
                String.isNotBlank(op.pages) &&
                op.pages.toLowerCase().contains(variant.toLowerCase()) &&
                ((allowedGitOperationLabels.contains(op.operationLabel.toLowerCase())) || allowedGitOperations.isEmpty())) ||
                (String.isNotBlank(op.operationLabel) &&
                String.isNotBlank(variant) &&
                variant.toLowerCase() != 'gitsnapshotcommit' &&
                String.isNotBlank(op.pages) &&
                ((allowedGitOperationLabels.contains(op.operationLabel.toLowerCase())) || allowedGitOperations.isEmpty()))
            ) {
                operationsMap.put(op.operationLabel, op);
            }
        }
        jsonObject.clear();
    }

    /**
     * It is used to return main record by using CommitService Interface
     *
     * @see GitCommit_PageBase
     * @see CommitService
     * @see initializeServiceClasses
     * @return
     */
    public PageReference returnToRecord() {
        return commitInterface.returnParentRecord();
    }
}