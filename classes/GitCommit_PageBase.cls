public with sharing virtual class GitCommit_PageBase {
    // Non Constants
    public Git_Repository__c repository { get; set; }
    public Git_Backup__c snapshot { get; set; }
    public Org__c org { get; set; }
    public User_Story__c userStory { get; set; }
    public List<Git_Backup__c> snapshotList { get; set; }
    public Boolean showVlocity { get; set; }
    public Boolean showCreateDXBranchPrompt { get; set; }
    public String orgRecordJson { get; set; }
    public String userStoryRecordJson { get; set; }
    public String snapshotRecordJson { get; set; }
    public String repositoryRecordJson { get; set; }
    public String pageHeaderText { get; set; }
    private GitCommit_ComponentBase myComponentController;
    private Map<String, GitCommit_ComponentBase> componentControllerMap;
    public Operation operationItem { get; set; }
    public Map<String, Operation> operationsMap { get; set; }
    public String selectedGitOperation { get; set; }
    public String userStoryBaseBranch { get; set; }
    public String variant { get; set; }
    public Map<String, Set<Object>> pageMessagesMap { get; set; }
    public Boolean userHasAccess { get; set; }

    // Constants
    public final String VLOCITY = 'Vlocity';
    public final String COMMIT_FILES = 'Commit Files';
    public final String C_DONE = 'done';
    public final String C_ERROR = 'error';
    public final String C_WARNING = 'warning';
    public final String C_INFO = 'info';
    public final String C_SUCCESS = 'success';

    public GitCommit_PageBase() {
        repository = new Git_Repository__c();
        snapshot = new Git_Backup__c();
        org = new Org__c();
        userStory = new User_Story__c();
        snapshotList = new List<Git_Backup__c>();
        orgRecordJson = '';
        userStoryRecordJson = '';
        snapshotRecordJson = '';
        repositoryRecordJson = '';
        pageHeaderText = '';
        operationsMap = new Map<String, Operation>();
        operationItem = new Operation();
        operationsMap.put(COMMIT_FILES, operationItem);
        variant = '';
        showVlocity = false;
        showCreateDXBranchPrompt = false;
        userHasAccess = true;
        pageMessagesMap = new Map<String, Set<Object>>();
    }

    public virtual void setComponentController(GitCommit_ComponentBase compController) {
        myComponentController = compController;
    }

    public GitCommit_PageBase getThis() {
        return this;
    }

    /**
     * Wrapper object to parse Git Operations file easily
     */
    public class Operation {
        public String operationType { get; set; }
        public String operationLabel { get; set; }
        public String operationButtonLabel { get; set; }
        public String endpoint { get; set; }
        public Boolean showCommitMessage { get; set; }
        public String helpText { get; set; }
        public String helpLink { get; set; }
        public List<OperationFormElement> operationFormElements { get; set; }
        public String pages { get; set; }
        public String attachmentName { get; set; }
        public Boolean showAdvancedSection { get; set; }

        // Grid
        public Boolean showGrid { get; set; }
        public Boolean editGrid { get; set; }
        public Boolean reloadGridData { get; set; }
        public String gridMetadataTypes { get; set; }
        public Boolean showUserStorySelections { get; set; }

        // Table
        public Boolean showTable { get; set; }
        public String tableSObject { get; set; }

        public String possibleRunningJob { get; set; }

        public Operation() {
            this.operationLabel = 'Commit Files';
            this.operationType = 'CommitFiles';
            this.showGrid = true;
            this.editGrid = false;
            this.showCommitMessage = true;
            this.endpoint = 'commit';
            this.pages = 'GitSnapshotCommit,UserStoryCommit,DxCommit';
            this.showAdvancedSection = true;
        }
    }

    /**
     * Wrapper object to parse Git Operation file easily
     */
    public class OperationFormElement {
        public String label { get; set; }
        public String name { get; set; }
        public String type { get; set; }
        public String helpText { get; set; }
        public String value { get; set; }
        public Boolean boolValue {
            get {
                if (null == boolValue) {
                    return false;
                }
                return boolValue;
            }
            set;
        }
    }

    /**
     * It is used to return json value of whole operation values
     *
     * @see GitCommitCommon resource to see how it is used
     * @return json value of operationsMap map
     */
    public String getAllOperationsMap() {
        return JSON.serialize(operationsMap);
    }
}