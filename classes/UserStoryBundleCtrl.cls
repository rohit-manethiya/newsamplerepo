public with sharing class UserStoryBundleCtrl {
    public String stories { get; private set; }
    public String recordId { get; set; }
    private static Set<String> allMetadataNames = new Set<String>();

    // CONSTRUCTOR
    public UserStoryBundleCtrl(ApexPages.StandardSetController ctrl) {
        stories = JSON.serialize(selectedRecordIds(ctrl));
    }

    // PUBLIC
    @AuraEnabled(cacheable=true)
    public static List<User_Story__c> selectedStories(List<String> ids) {
        try {
            return new UserStoriesSelector().byIds(new Set<Id>((List<Id>) ids));
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MetaDataItem> getAllMetadata(List<String> ids, List<String> operations) {
        return metadataItems(attachments(ids, operations));
    }

    @AuraEnabled
    public static String createBundleRecords(
        User_Story_Bundle__c bundle,
        List<User_Story__c> stories,
        List<MetaDataItem> metadata,
        List<MetaDataItem> fullProfiles,
        List<MetaDataItem> destructiveChanges
    ) {
        List<String> validationErrors = new UserStoryBundleValidator(stories, metadata, fullProfiles, destructiveChanges).execute();
        if (!validationErrors.isEmpty()) {
            throw createAuraException(String.join(validationErrors, ','));
        }

        User_Story_Bundle__c result = new User_Story_Bundle__c();
        try {
            result = (User_Story_Bundle__c) Utilities.Secure_DML(bundle, Utilities.DML_Action.INS, Schema.SObjectType.User_Story_Bundle__c);
            createJunctionRecords(result, stories);
            createAttachments(result, stories, metadata, fullProfiles, destructiveChanges);
        } catch (Exception ex) {
            throw createAuraException(ex.getMessage());
        }
        return result.Id;
    }

    public Pagereference navigate() {
        PageReference result = new ApexPages.Action('{!List}').invoke();
        if (String.isNotBlank(recordId)) {
            result = new ApexPages.StandardController(new User_Story_Bundle__c(Id = recordId)).view();
            result.setRedirect(true);
        }
        return result;
    }

    // PRIVATE

    private static AuraHandledException createAuraException(String message) {
        AuraHandledException result = new AuraHandledException(message);
        result.setMessage(message);

        return result;
    }

    private Set<Id> selectedRecordIds(ApexPages.StandardSetController ctrl) {
        Map<Id, User_Story__c> selected = new Map<Id, User_Story__c>((List<User_Story__c>) ctrl.getSelected());
        return selected.keySet();
    }

    private static void createJunctionRecords(User_Story_Bundle__c bundle, List<User_Story__c> stories) {
        List<Bundled_UserStory__c> junctions = new List<Bundled_UserStory__c>();
        for (User_Story__c item : stories) {
            junctions.add(new Bundled_UserStory__c(User_Story__c = item.Id, User_Story_Bundle__c = bundle.Id));
        }
        Utilities.Secure_DML(junctions, Utilities.DML_Action.INS, Schema.SObjectType.Bundled_UserStory__c);
    }

    private static void createAttachments(
        User_Story_Bundle__c bundle,
        List<User_Story__c> stories,
        List<MetaDataItem> metadata,
        List<MetaDataItem> fullProfiles,
        List<MetaDataItem> destructiveChanges
    ) {
        List<Attachment> bundleAttachments = new List<Attachment>();

        if (!metadata.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Metadata', metadata));
        }

        if (!fullProfiles.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Full Profiles & Permission Sets', fullProfiles));
        }

        if (!destructiveChanges.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Destructive Changes', destructiveChanges));
        }

        List<MetaDataItem> testClasses = testOnlyAttachment(new Map<Id, User_Story__c>(stories).keySet());
        if (!testClasses.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Test Classes', testClasses));
        }

        insert bundleAttachments;
    }

    private static Attachment createAttachment(User_Story_Bundle__c bundle, String attachmentName, List<MetaDataItem> metadataItems) {
        return new Attachment(ParentId = bundle.Id, Name = attachmentName, Body = Blob.valueOf(JSON.serialize(metadataItems)));
    }

    private static List<MetaDataItem> testOnlyAttachment(Set<Id> storyIds) {
        Map<String, MetaDataItem> result = new Map<String, MetaDataItem>();
        for (Attachment record : new AttachmentsSelector().byParentIdAndName(storyIds, new Set<String>{ 'Test Classes' })) {
            // Merge the metadata to the result set.
            // Also checks if any class checked as Test only is commited, then that class will be removed from 'Test Classes' Attachment
            for (MetaDataItem metadata : metadataItems(record)) {
                if (!result.containsKey(metadata.n) && !allMetadataNames.contains(metadata.n)) {
                    result.put(metadata.n, metadata);
                }
            }
        }
        return result.values();
    }

    private static List<Attachment> attachments(List<String> ids, List<String> operations) {
        List<Attachment> result = new List<Attachment>();
        try {
            result = [
                SELECT Id, Body
                FROM Attachment
                WHERE
                    Name IN ('Metadata', 'Git Deletion')
                    AND ParentId IN (
                        SELECT Snapshot_Commit__c
                        FROM User_Story_Commit__c
                        WHERE
                            User_Story__r.Id IN :ids
                            AND Snapshot_Commit__r.Git_Operation__c = :operations
                            AND Snapshot_Commit__r.Status__c = 'Complete'
                    )
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
        } catch (System.QueryException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    private static List<MetaDataItem> metadataItems(List<Attachment> attachments) {
        Map<String, MetaDataItem> result = new Map<String, MetaDataItem>();
        for (Attachment record : attachments) {
            for (MetaDataItem metadata : metadataItems(record)) {
                String key = metadata.t + '.' + metadata.n;
                if (!result.containsKey(key)) {
                    metadata.s = true;
                    result.put(key, metadata);
                    allMetadataNames.add(metadata.n);
                } else {
                    // If it exists, check if it has metadata.r = false, and ensure it's also false in result
                    // This is to ensure if it is not retrieve-only at least once, it must be not retrieve only.
                    if (metadata.r == null || !metadata.r) {
                        result.get(key).r = false;
                    }
                }
            }
        }
        return result.values();
    }

    private static List<MetaDataItem> metadataItems(Attachment record) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        try {
            result = (List<MetaDataItem>) JSON.deserialize(record.Body.toString(), List<MetaDataItem>.class);
        } catch (Exception ex) {
            throw new AuraHandledException('Not parsed data ' + ex.getMessage());
        }
        return result;
    }

    private class UserStoryBundleValidator {
        private List<User_Story__c> stories;
        private List<MetaDataItem> metadata;
        private List<MetaDataItem> fullProfiles;
        private List<MetaDataItem> destructiveChanges;

        UserStoryBundleValidator(
            List<User_Story__c> stories,
            List<MetaDataItem> metadata,
            List<MetaDataItem> fullProfiles,
            List<MetaDataItem> destructiveChanges
        ) {
            this.stories = stories;
            this.metadata = metadata;
            this.fullProfiles = fullProfiles;
            this.destructiveChanges = destructiveChanges;
        }

        public List<String> execute() {
            List<String> result = new List<String>();

            if (stories.isEmpty() || stories.size() == 1) {
                result.add(System.Label.USB_WARNING_NO_US_SELECTED);
            } else if (metadata.isEmpty() && fullProfiles.isEmpty() && destructiveChanges.isEmpty()) {
                result.add(System.Label.USB_WARNING_NO_COMMITS);
            } else {
                if (differentEnvironmentsIn(stories)) {
                    result.add(System.Label.USB_WARNING_DIFFERENT_ENVIRONMENTS);
                }
                if (differentPipelinesIn(stories)) {
                    result.add(System.Label.USB_WARNING_DIFFERENT_PIPELINES);
                }
            }

            return result;
        }

        private Boolean differentEnvironmentsIn(List<User_Story__c> stories) {
            Boolean result = false;

            Id refEnvironment = stories.get(0).Environment__c;
            for (User_Story__c story : stories) {
                if (story.Environment__c != refEnvironment) {
                    result = true;
                    break;
                }
            }

            return result;
        }

        private Boolean differentPipelinesIn(List<User_Story__c> stories) {
            Boolean result = false;

            Id refPipeline = getPipelineRelatedTo(stories.get(0));
            for (User_Story__c story : stories) {
                if (getPipelineRelatedTo(story) != refPipeline) {
                    result = true;
                    break;
                }
            }

            return result;
        }

        private Id getPipelineRelatedTo(User_Story__c story) {
            Id result;

            if (story.Project__r.Deployment_Flow__c != null) {
                result = story.Project__r.Deployment_Flow__c;
            } else if (story.Release__r.Project__r.Deployment_Flow__c != null) {
                result = story.Release__r.Project__r.Deployment_Flow__c;
            }

            return result;
        }
    }
}