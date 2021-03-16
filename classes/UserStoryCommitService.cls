/**
 * This is the main controller for user story commit which implements CommitService interface and extends GitCommit_PageBase to populate fields for component controllers
 */
public with sharing class UserStoryCommitService extends GitCommit_PageBase implements CommitService {
    private final String DYNAMIC_QUERY = 'SELECT {0} FROM {1} WHERE {2}';

    /**
     * It is used to populate page header text at GitCommit_Header component
     *
     * @return String text of page header
     */
    public String getPageHeader() {
        return Label.User_Story_Commit;
    }

    /**
     * It is used to retrieve all necessary field for user story record
     * Checking if the User_Story__c.Git_Commit_Header fieldset fields are already in query.
     * Populate branch name by using user story and deployment flow
     * Retrieve all necessary field fot git snapshot record
     * Checking if fieldset fields are already in query.
     * Checking if the Git_Backup__c.Git_Commit_Header fieldset fields are already in query.
     *
     * @param namespace
     * @param usId user story id if passed
     * @param sId snapshot id if passed
     */
    public GitCommit_PageBase loadAndValidateBaseRecords(String namespace, String usId, String sId) {
        String selectUSString = ('Id, Name, Base_Branch__c, Release__r.Base_Branch__c, Environment__c, Org_Credential__c, Project__r.Deployment_Flow__r.Git_Repository__c, Release__r.Project__r.Deployment_Flow__r.Git_Repository__c, Org_Credential__r.Org_Type__c, Org_Credential__r.Metadata_Types__c,User_Story_Title__c');
        for(Schema.FieldSetMember fsm : SObjectType.User_Story__c.fieldSets.Git_Commit_Header.getFields()) {
            Boolean alreadyAdded = selectUSString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(namespace)) ? true : false;
            selectUSString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(namespace);
        }
        String fromUSString = Schema.SObjectType.User_Story__c.name;
        String whereUSString = 'Id = :usId';
        String mainUSQuery = String.format(DYNAMIC_QUERY, new List<String>{
                selectUSString, fromUSString, whereUSString
        });
        //User_Story__c userStory = new User_Story__c();
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStory = Database.query(mainUSQuery);
            userStoryRecordJson = JSON.serialize(userStory);
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.User_Story__c.label;
            throw new UserStoryCommitServiceException(errorMessage);
        }

        if(String.isBlank(userStory.Environment__c)) {
            throw new UserStoryCommitServiceException(Label.USER_STORY_COMMIT_NO_ENVIRONMENT);
        }

        GlobalUtilities.deploymentFlowDetails flowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        if(flowDetails.flow == null || !flowDetails.flow.Active__c) {
            // Check if Flow is Active
            throw new UserStoryCommitServiceException(Label.PROMOTION_FLOW_INACTIVE);
        } else if(flowDetails.flow != null && flowDetails.flow.Block_Commits__c) {
            // Check if Commits are allowed
            throw new UserStoryCommitServiceException(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED);
        }

        // Get Main Branch of Deployment Flow
        userStoryBaseBranch = flowDetails.flow.Main_Branch__c != null ? flowDetails.flow.Main_Branch__c : '';
        if(String.isNotEmpty(userStory.Base_Branch__c)) {
            userStoryBaseBranch = userStory.Base_Branch__c;
        } else if(String.isNotEmpty(userStory.Release__r.Base_Branch__c)) {
            userStoryBaseBranch = userStory.Release__r.Base_Branch__c;
        }
        System.debug('**f**userStoryBaseBranch : ' + userStoryBaseBranch);

        if(String.isNotBlank(userStory.Environment__c)) {
            String selectSnapshotString = ('Id, Name, Org__r.Name, Branch__c, Git_Repository__r.Name, Frequency__c, Git_Snapshot_Permissions__c');
            for(Schema.FieldSetMember fsm : SObjectType.Git_Backup__c.fieldSets.Git_Commit_Header.getFields()) {
                Boolean alreadyAdded = selectSnapshotString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(namespace)) ? true : false;
                selectSnapshotString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(namespace);
            }
            String fromSnapshotString = Schema.SObjectType.Git_Backup__c.name;
            String whereSnapshotString = '(Git_Snapshot_Permissions__c = \'\' OR Git_Snapshot_Permissions__c != \'Allow Snapshots Only\')';
            String usEnvironment = userStory.Environment__c;
            whereSnapshotString += ' AND Org__r.Environment__c = :usEnvironment';
            String usProjectFlow = userStory.Project__r.Deployment_Flow__r.Git_Repository__c;
            String usReleaseProjectFlow = userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
            whereSnapshotString += ' AND (Git_Repository__c = :usProjectFlow OR Git_Repository__c = :usReleaseProjectFlow) LIMIT 100';
            String mainSnapshotQuery = String.format(DYNAMIC_QUERY, new List<String>{
                    selectSnapshotString, fromSnapshotString, whereSnapshotString
            });

            if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                snapshotList = Database.query(mainSnapshotQuery);

                if(snapshotList.isEmpty()) {
                    throw new UserStoryCommitServiceException(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
                } else if(!snapshotList.isEmpty()) {
                    if(snapshotList.size() == 1) {
                        snapshot = snapshotList[0];
                    } else {
                        String gitBackupId = ApexPages.currentPage().getParameters().get('gitSnapshotId');
                        for(Git_Backup__c gb : snapshotList) {
                            if(String.isNotBlank(gitBackupId) && gb.Id == gitBackupId) {
                                snapshot = gb;
                            }
                        }
                    }
                    if(snapshot != null) {
                        snapshotRecordJson = JSON.serialize(snapshot);
                    }
                }
            } else {
                String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.label;
                throw new UserStoryCommitServiceException(errorMessage);
            }
        }
        return getThis();
    }

    /**
     * It is used to return user story record
     *
     * @return
     */
    public PageReference returnParentRecord() {
        PageReference pr = new ApexPages.StandardController(userStory).view();
        pr.setRedirect(true);
        return pr;
    }

    public class UserStoryCommitServiceException extends Exception {
    }
}