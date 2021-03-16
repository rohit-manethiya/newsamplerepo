@IsTest
public with sharing class UserStoriesMetadataSelectorTest {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void defaultFields() {
        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        List<SObjectField> metadataFields = selector.getSObjectFieldList();

        // Verify
        List<SObjectField> assertFields = new List<SObjectField>{
            User_Story_Metadata__c.Id,
            User_Story_Metadata__c.Status__c,
            User_Story_Metadata__c.User_Story__c,
            User_Story_Metadata__c.Metadata_API_Name__c
        };
        System.assertEquals(assertFields, metadataFields, 'Fields returned does not match');
    }

    @IsTest
    private static void queryByIds() {
        // Setup
        Map<Id, User_Story_Metadata__c> metadataById = new Map<Id, User_Story_Metadata__c>(
            [SELECT Id, Status__c, Metadata_API_Name__c, User_Story__c FROM User_Story_Metadata__c LIMIT 2]
        );

        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        List<User_Story_Metadata__c> storiesMetadataById = selector.byId(metadataById.keySet());

        // Verify
        System.assertEquals(2, storiesMetadataById.size(), 'Number of records returned should be 2');
        System.assert(metadataById.values().equals(storiesMetadataById), 'Lists must be identical');
    }

    @IsTest
    private static void queryByStoryIdsIndexingEnabled() {
        // Setup
        User_Story__c story = [SELECT Id FROM User_Story__c LIMIT 1];

        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        List<User_Story_Metadata__c> storiesIndexinEnabled = selector.byStoryIdsIndexingEnabled(new Set<Id>{ story.Id });

        // Verify
        List<User_Story_Metadata__c> assertList = [
            SELECT Id, Metadata_API_Name__c, Status__c, User_Story__c
            FROM User_Story_Metadata__c
            WHERE User_Story__c = :story.Id AND User_Story__r.Project__r.Index_Metadata__c = TRUE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
        ];
        System.assertEquals(2, storiesIndexinEnabled.size(), 'Number of records returned should be 2');
        System.assert(assertList.equals(storiesIndexinEnabled), 'Lists must be identical');
    }

    @IsTest
    private static void queryByStoryStatus() {
        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        Database.QueryLocator query = selector.byStoryStatus(new Set<Id>(), 'Potential Conflict');

        // Verify
        String assertQuery = 'SELECT Id, Metadata_API_Name__c, Status__c, User_Story__c FROM User_Story_Metadata__c WHERE User_Story__c = :ids AND Status__c = :status ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }

    @IsTest
    private static void queryByMetadataIndexingEnabled() {
        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        Database.QueryLocator query = selector.byMetadataIndexingEnabled(new Set<String>());

        // Verify
        String assertQuery = 'SELECT Id, Metadata_API_Name__c, Status__c, User_Story__c FROM User_Story_Metadata__c WHERE Metadata_API_Name__c = :apiNames AND User_Story__r.Project__r.Index_Metadata__c = true AND User_Story__r.Stop_Indexing_Metadata__c = false ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }

    @IsTest
    private static void byMetadatanameStatusIndexingEnabled() {
        // Exercise
        UserStoriesMetadataSelector selector = new UserStoriesMetadataSelector();
        Database.QueryLocator query = selector.byMetadatanameStatusIndexingEnabled(new Set<String>(), 'Potential Conflict');

        // Verify
        String assertQuery = 'SELECT Id, Metadata_API_Name__c, Status__c, User_Story__c FROM User_Story_Metadata__c WHERE Status__c = :status AND Metadata_API_Name__c = :apiNames AND User_Story__r.Project__r.Index_Metadata__c = true AND User_Story__r.Stop_Indexing_Metadata__c = false ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }

    private static void createData() {
        Project__c project = new Project__c(Name = 'My Project', Index_Metadata__c = true);
        insert project;
        User_Story__c story = new User_Story__c(Project__c = project.Id);
        insert story;

        User_Story_Metadata__c metadata1 = new User_Story_Metadata__c(
            Status__c = 'Potential Conflict',
            Metadata_API_Name__c = 'CustomField.Account.Number__c',
            User_Story__c = story.Id
        );

        User_Story_Metadata__c metadata2 = new User_Story_Metadata__c(
            Status__c = 'Potential Conflict',
            Metadata_API_Name__c = 'CustomField.Account.Text__c',
            User_Story__c = story.Id
        );

        insert new List<User_Story_Metadata__c>{ metadata1, metadata2 };
    }
}