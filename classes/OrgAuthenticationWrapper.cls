/**
 * This is main class to store variables to move to interface classes
 */
public with sharing class OrgAuthenticationWrapper {

    /**
     * This wrapper will be used to hold value of current step
     */
    public class SetStepWrapper {
        public String currentInnerStep { get; set; }
        public Boolean createNewOrg { get; set; }
        public SetStepWrapper() {
            this.currentInnerStep = '';
            this.createNewOrg = true;
        }
    }

    /**
     * This wrapper will be used to return result after set step
     */
    public class SetStepReturnWrapper {
        public String newInnerStep { get; set; }
        public Map<String, String> possibleActionStatusMap { get; set; }
        public Boolean stopTakingSnapshotPoller { get; set; }
        public Boolean stopCreatingRecordsPoller { get; set; }
        public Boolean stopCreatingBranchesPoller { get; set; }
        public SetStepReturnWrapper() {
            this.newInnerStep = '';
            this.possibleActionStatusMap = new Map<String, String>();
            this.stopTakingSnapshotPoller = true;
            this.stopCreatingRecordsPoller = true;
            this.stopCreatingBranchesPoller = true;
        }
    }

    /**
     * This wrapper will be used to pass json value to the interface method
     */
    public class ResponseActionPollerWrapper {
        public Map<String, String> possibleActionStatusMap { get; set; }
        public Boolean stopTakingSnapshotPoller { get; set; }
        public Boolean stopCreatingRecordsPoller { get; set; }
        public Boolean stopCreatingBranchesPoller { get; set; }
        public ResponseActionPollerWrapper() {
            this.possibleActionStatusMap = new Map<String, String>();
            this.stopTakingSnapshotPoller = true;
            this.stopCreatingRecordsPoller = true;
            this.stopCreatingBranchesPoller = true;
        }
    }
}