/**
 * This is main controller for GitCommit_Header component which extends GitCommit_ComponentBase to get values from GitCommit_PageBase
 * @see GitCommit_PageBase
 */
public with sharing class GitCommit_HeaderController extends GitCommit_ComponentBase {
    // Non Constant
    public String commitMessage {
        set;
        get {
            if(commitMessage == null) {
                commitMessage = preCommitMessage();
            }
            return commitMessage;
        }
    }

    public List<SelectOption> availableOperationList {
        set;
        get {
            if(availableOperationList == null) {
                availableOperationList = populateOperationList();
            }
            return availableOperationList;
        }
    }

    // Constant
    private final String RECREATE_FEATURE_BRANCH = 'recreateFeatureBranch';

    public GitCommit_HeaderController() {
    }

    /**
     * It is used to populate commit message by using user story record
     * @see GitCommit_MainPageController.parseGitOperationsFile  to find how pageController.userStory is populated
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     *
     * @return String value of (user story name + user story title)
     */
    public String preCommitMessage() {
        if(pageController != null && pageController.userStory != null && pageController.userStory.Id != null) {
            return commitMessage = (pageController.userStory.Name + ': ' + (String.isEmpty(pageController.userStory.User_Story_Title__c) ? '' : pageController.userStory.User_Story_Title__c)).left(254);
        }
        return '';
    }

    /**
     * It is used to populate available git operation type
     * @see GitCommit_MainPageController.parseGitOperationsFile  to find how pageController.operationsMap is populated
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     *
     * @return
     */
    public List<SelectOption> populateOperationList() {
        List<SelectOption> options = new List<SelectOption>();
        if(pageController != null && pageController.operationsMap != null) {
            for(String operationLabel : pageController.operationsMap.keySet()) {
                options.add(new SelectOption(operationLabel, operationLabel));
            }
        }
        return options;
    }

    /**
     * It is used to update operationItem when changing the existing operation,
     * @see pageController.operationItem is used to render GitCommit_Operation component
     * @see GitCommit_MainPageController.parseGitOperationsFile  to find how pageController.operationsMap is populated
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     */
    public void updateOperationItem() {
        if(pageController != null && pageController.operationsMap != null && pageController.operationsMap.containsKey(pageController.selectedGitOperation)) {
            pageController.operationItem = pageController.operationsMap.get(pageController.selectedGitOperation);
        }
    }

    /**
     * When user click on Commit Changes, first this methods is called.
     * It is used to delete existing user story metadata record if git operation is recommit and recreate feature branch is checked
     * @see GitCommit_MainPageController.parseGitOperationsFile  to find how pageController.operationItem is populated
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     */
    public void deleteMetadataIndex() {
        if(null != pageController && null != pageController.operationItem && null != pageController.operationItem.operationFormElements) {
            for(GitCommit_PageBase.OperationFormElement ofe : pageController.operationItem.operationFormElements) {
                if(ofe.name == RECREATE_FEATURE_BRANCH && ofe.boolValue) {
                    List<User_Story_Metadata__c> usmList = new List<User_Story_Metadata__c>();
                    if(Schema.SObjectType.User_Story_Metadata__c.isAccessible() && Schema.SObjectType.User_Story_Metadata__c.isQueryable()) {
                        usmList = [SELECT Id, Name FROM User_Story_Metadata__c WHERE User_Story__c = :pageController.userStory.Id];
                    } else {
                        pageController.pageMessagesMap.put(C_ERROR, new Set<Object>{
                                Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.User_Story_Metadata__c.getLabel()
                        });
                        return;
                    }
                    if(!usmList.isEmpty()) {
                        Utilities.Secure_DML(usmList, Utilities.DML_Action.DEL, Schema.SObjectType.User_Story_Metadata__c);
                    }
                }
            }
        }
    }

    /**
     * This method will work after deleteMetadataIndex method is done
     * It is used to create git Org Commit record before do commit
     * @see gitCommitCommons resource to see how it called
     * @see GitCommit_Grid component to see how pageController.gitOrgCommit is used
     * @see GitCommit_MainPageController.parseGitOperationsFile  to find how pageController.snapshot and pageController.operationItem are populated
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     */
    @RemoteAction public static String createGitOrgCommit(String commitMessage, String orgId, String snapshotId, String operationName) {
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c ();
        gitOrgCommit.Commit_Message__c = commitMessage;
        gitOrgCommit.Org__c = orgId;
        gitOrgCommit.Git_Backup__c = snapshotId;
        gitOrgCommit.Status__c = 'Pending';
        gitOrgCommit.Git_Operation__c = operationName;

        Utilities.Secure_DML(gitOrgCommit, Utilities.DML_Action.INS, schema.SObjectType.Git_Org_Commit__c);

        return gitOrgCommit.Id;
    }

    /**
     * It is used to redirect to the user story waiting for page after doCommit is done at JS
     * @return UserStoryPageWaitingFor page
     */
    public PageReference goToWaitingForPage() {
        String commitId = ApexPages.currentPage().getParameters().get('commitId');
        PageReference preference = ((pageController.variant.toLowerCase() == 'userstorycommit' || pageController.variant.toLowerCase() == 'dxcommit') && String.isNotBlank(pageController.userStory.Id)) ? Page.UserStoryPageWaitingFor : Page.SnapshotWaitingFor;
        Id recordId = String.isNotBlank(pageController.userStory.Id) ? pageController.userStory.Id : pageController.snapshot.Id;
        preference.getParameters().put('id', recordId);
        preference.getParameters().put('type', 'co_commitChanges');
        preference.getParameters().put('ep', pageController.operationItem.endpoint);
        if(String.isNotBlank(pageController.userStory.Id) && String.isNotBlank(pageController.snapshot.Id)) {
            preference.getParameters().put('sId', pageController.snapshot.Id);
        }
        preference.getParameters().put('cType', pageController.operationItem.operationLabel);
        preference.getParameters().put('cId', commitId);
        if(null != pageController.operationItem && null != pageController.operationItem.operationFormElements) {
            for(GitCommit_PageBase.OperationFormElement ofe : pageController.operationItem.operationFormElements) {
                if(ofe.name == RECREATE_FEATURE_BRANCH) {
                    preference.getParameters().put(ofe.name, String.valueOf(ofe.boolValue));
                }
            }
        }
        preference.setRedirect(true);
        return preference;
    }
}