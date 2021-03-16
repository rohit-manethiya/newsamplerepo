/**
 * This is the main controller for user story commit which implements CommitService interface and extends GitCommit_PageBase to populate fields for component controllers
 */
public with sharing class DxCommitService extends GitCommit_PageBase implements CommitService {
    private final String DYNAMIC_QUERY = 'SELECT {0} FROM {1} WHERE {2}';

    /**
     * It is used to populate page header text at GitCommit_Header component
     *
     * @return String text of page header
     */
    public String getPageHeader() {
        return Label.DX_Commit;
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
        String selectUSString = ('Id, Name, Base_Branch__c, Release__r.Base_Branch__c, Environment__c, Org_Credential__c, Project__r.Deployment_Flow__r.Git_Repository__c, Release__r.Project__r.Deployment_Flow__r.Git_Repository__c, Org_Credential__r.Org_Type__c, User_Story_Title__c');
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
            throw new DxServiceException(errorMessage);
        }

        if(String.isBlank(userStory.Environment__c)) {
            throw new DxServiceException(Label.USER_STORY_COMMIT_NO_ENVIRONMENT);
        }

        Deployment_Flow__c flowDetails = SfdxAPIHelper.usDeploymentFlow(userStory.Id);
        if(flowDetails == null || !flowDetails.Active__c) {
            // Check if Flow is Active
            throw new DxServiceException(Label.PROMOTION_FLOW_INACTIVE);
        } else if(flowDetails != null && flowDetails.Block_Commits__c) {
            // Check if Commits are allowed
            throw new DxServiceException(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED);
        } else if(!flowDetails.Enable_Copado_DX__c) {
            throw new DxServiceException(Label.DX_NOT_ENABLED_DF);
        } else if(flowDetails.Deployment_Flow_Steps__r.size() == 0) {
            throw new DxServiceException(Label.DF_HAS_NO_DX_TARGET);
        }

        // Get Main Branch of Deployment Flow
        userStoryBaseBranch = flowDetails.Main_Branch__c != null ? flowDetails.Main_Branch__c : '';
        if(String.isNotEmpty(userStory.Base_Branch__c)) {
            userStoryBaseBranch = userStory.Base_Branch__c;
        } else if(String.isNotEmpty(userStory.Release__r.Base_Branch__c)) {
            userStoryBaseBranch = userStory.Release__r.Base_Branch__c;
        }

        if(String.isNotBlank(userStory.Environment__c)) {
            String selectSnapshotString = ('Id, Name, Org__r.Name, Org__r.Org_Type__c, Branch__c, Git_Repository__r.Name, Frequency__c, Git_Snapshot_Permissions__c');
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
                    //If no snapshot and it's Scratch Org, we look for the attachmet to see if scratch org was created from ArtifactUMP if so, we allow users to create it
                    List<Attachment> attList = new List<Attachment>();
                    if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                        attList = [SELECT Body FROM Attachment WHERE ParentId = :userStory.Org_Credential__c AND Name = :DXLabel.METADATA_SOURCES LIMIT 1];
                    } else {
                        String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Attachment.label;
                        throw new DxServiceException(errorMessage);
                    }

                    if(!attList.isEmpty()) {
                        Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(attList.get(0).Body.toString());
                        String mSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? String.valueOf(deserializedJsonMap.get('metadataSourceType')) : '';
                        String mSource = deserializedJsonMap.containsKey('metadataSource') ? String.valueOf(deserializedJsonMap.get('metadataSource')) : '';
                        if(String.isNotBlank(mSource) && String.isNotBlank(mSourceType)) {
                            showCreateDXBranchPrompt = true;
                            return getThis();
                        } else {
                            throw new DxServiceException(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
                        }
                    } else {
                        throw new DxServiceException(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
                    }
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
                throw new DxServiceException(errorMessage);
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

    public class DxServiceException extends Exception {
    }
}