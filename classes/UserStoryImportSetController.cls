public with sharing class UserStoryImportSetController {
    private ApexPages.StandardSetController stdController;
    public List<User_Story__c> userStoryList { get; set; }
    public Deployment_Task__c dummyUserStoryLookup { get; set; } // used only to render/read the lookup field
    // list of all the metadata items selected in all the commits, unique

    public UserStoryImportSetController(ApexPages.StandardSetController std) {
        stdController = std;
        dummyUserStoryLookup = new Deployment_Task__c();
        userStoryList = (List<User_Story__c>) std.getSelected();
    }

    public List<MetaDataItem> getAllMetadata() {
        Map<String, MetaDataItem> allMetadataItemsByKey = new Map<String, MetaDataItem>();
        if (userStoryList.size() < 1) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.AtLeastOneUS);
            return null;
        }
        Set<String> usIdSet = new Set<String>();
        for (User_Story__c currentRecord : userStoryList) {
            usIdSet.add(currentRecord.Id);
        }
        List<Attachment> metadataAttachments = new List<Attachment>();
        if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
            // fetch each MetaData attachment from each commit associated with each user story
            metadataAttachments = [
                SELECT Id, Body
                FROM Attachment
                WHERE
                    Name = 'Metadata'
                    AND ParentId IN (
                        SELECT Snapshot_Commit__c
                        FROM User_Story_Commit__c
                        WHERE User_Story__r.Id IN :usIdSet AND Snapshot_Commit__r.Status__c = 'Complete'
                    )
                ORDER BY CreatedDate DESC
            ];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.getLabel());
            return null;
        }

        for (Attachment att : metadataAttachments) {
            List<MetaDataItem> metaDataItems = new List<MetaDataItem>();
            try {
                metaDataItems = (List<MetaDataItem>) JSON.deserialize(att.Body.toString(), List<MetaDataItem>.class);
            } catch (Exception excp) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.CouldntParse);
            }
            // merge the commit metadata to the allMetadataItemsByKey set.
            for (MetaDataItem metadata : metaDataItems) {
                String key = metadata.t + '.' + metadata.n;
                if (!allMetadataItemsByKey.containsKey(key)) {
                    metadata.s = true;
                    allMetadataItemsByKey.put(key, metadata);
                } else {
                    // if it exists, check if it has metadata.r = false, and ensure it's also false in allMetadataItemsByKey
                    // this is to ensure if it is not retrieve-only at least once, it must be not retrieve only.
                    if (metadata.r == null || !metadata.r) {
                        allMetadataItemsByKey.get(key).r = false;
                    }
                }
            }
        }
        return allMetadataItemsByKey.values();
    }

    public PageReference cancel() {
        return stdController.cancel();
    }

    public PageReference assign() {
        List<MetaDataItem> allMetadataItems = getAllMetadata();
        // we have to check allMetadataItems returning null, because if there is no user story selected getAllMetadata method is returning null
        if (allMetadataItems == null) {
            return null;
        }
        if (allMetadataItems.size() < 1) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.NoMetadataSelected);
            return null;
        }
        User_Story__c tempUs = new User_Story__c();
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            tempUs = [SELECT Id, Environment_Type__c FROM User_Story__c WHERE Id = :dummyUserStoryLookup.User_Story__c];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return null;
        }
        //approved or rejected approvals are checked because some process like to keep record locked after approval or rejection
        List<ProcessInstance> lockedRecords = new List<ProcessInstance>(
            [
                SELECT
                    Id,
                    TargetObjectId,
                    (
                        SELECT Id, StepStatus, Comments
                        FROM StepsAndWorkitems
                        WHERE StepStatus = 'Pending' OR StepStatus = 'Approved' OR StepStatus = 'Rejected'
                    )
                FROM ProcessInstance
                WHERE TargetObjectId = :tempUs.Id
            ]
        );
        //we are doing second check to make sure record is locked. with Savepoint record will not be updated in the system
        if (!lockedRecords.isEmpty()) {
            System.Savepoint currentPoint = Database.setSavepoint();
            try {
                Utilities.Secure_DML(tempUs, Utilities.DML_Action.UPD, Schema.SObjectType.User_Story__c);
            } catch (Exception excp) {
                if (excp.getMessage().containsIgnoreCase('locked')) {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.UnlockedSelection);
                    Database.rollback(currentPoint); //this is because it will return below
                    return null;
                }
            }
            Database.rollback(currentPoint); //this is for successful try or exception is not about record being locked
        }
        Attachment att = new Attachment(
            ParentId = tempUs.Id,
            Name = 'MetadataPreselection-UsertStoryImport',
            Body = Blob.valueOf(JSON.serialize(allMetadataItems))
        );
        Utilities.Secure_DML(att, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);

        PageReference pReference = Page.GitCommitMain;
        pReference.setRedirect(true);
        pReference.getParameters().put('userStoryId', tempUs.Id);
        pReference.getParameters().put('MetadataPreselectionId', att.Id);
        Boolean isScratcOrg = String.isNotBlank(tempUs.Environment_Type__c) && tempUs.Environment_Type__c.containsIgnoreCase('Scratch Org');
        pReference.getParameters().put('variant', isScratcOrg ? 'DxCommit' : 'UserStoryCommit');
        return pReference;
    }

    public class MetaDataItem {
        public String t { get; set; }
        public String n { get; set; }
        public Boolean r;
        public Boolean s;
        public String cb;
        public String cd;
    }
}