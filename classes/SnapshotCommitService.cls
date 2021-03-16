/**
 * This is the main controller for snapshot commit which implements CommitService interface and extends GitCommit_PageBase to populate fields for component controllers
 */
public with sharing class SnapshotCommitService extends GitCommit_PageBase implements CommitService {
    private final String DYNAMIC_QUERY = 'SELECT {0} FROM {1} WHERE {2}';

    /**
     * It is used to populate page header text at GitCommit_Header component
     *
     * @return String text of page header
     */
    public String getPageHeader() {
        return Label.Snapshot_Commit;
    }

    /**
     * User story is not necessary for snapshot commit
     * Branch name is not necessary for snapshot commit
     * Getting all necessary field for snapshot record
     * Checking if the Git_Backup__c.Git_Commit_Header fieldset fields are already in query.
     *
     * @param namespace
     * @param usId user story id if passed
     * @param sId snapshot id if passed
     */
    public GitCommit_PageBase loadAndValidateBaseRecords(String namespace, String usId, String sId) {
        if(String.isNotBlank(sId)) {
            String selectSnapshotString = ('Id, Name, Org__r.Name, Branch__c, Git_Repository__r.Name, Frequency__c, Git_Snapshot_Permissions__c').toLowerCase();
            for(Schema.FieldSetMember fsm : SObjectType.Git_Backup__c.fieldSets.Git_Commit_Header.getFields()) {
                Boolean alreadyAdded = selectSnapshotString.containsIgnoreCase(fsm.getFieldPath().removeStartIgnoreCase(namespace)) ? true : false;
                selectSnapshotString += alreadyAdded ? '' : ', ' + fsm.getFieldPath().removeStartIgnoreCase(namespace);
            }
            String fromSnapshotString = Schema.SObjectType.Git_Backup__c.name;
            String whereSnapshotString = 'Id = :sId';
            String mainSnapshotQuery = String.format(DYNAMIC_QUERY, new List<String>{
                selectSnapshotString, fromSnapshotString, whereSnapshotString
            });

            if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                snapshotList = Database.query(mainSnapshotQuery);
                snapshot = snapshotList[0];
            } else {
                String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Git_Backup__c.label;
                throw new SnapshotCommitServiceException(errorMessage);
            }
        }
        return getThis();
    }

    /**
     * It is used to return snapshot record
     *
     * @return
     */
    public PageReference returnParentRecord() {
        PageReference pr = new ApexPages.StandardController(snapshot).view();
        pr.setRedirect(true);
        return pr;
    }

    public class SnapshotCommitServiceException extends Exception {
    }
}