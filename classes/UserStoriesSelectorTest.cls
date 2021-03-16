@IsTest
public with sharing class UserStoriesSelectorTest {
    @IsTest
    private static void defaultFields() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        List<SObjectField> metadataFields = selector.getSObjectFieldList();

        // Verify
        List<SObjectField> assertFields = new List<SObjectField>{ User_Story__c.Id };
        System.assertEquals(assertFields, metadataFields, 'Fields returned does not match');
    }

    @IsTest
    private static void queryByIds() {
        // Setup
        User_Story__c story = new User_Story__c();
        insert story;
        
        // Exercise
        List<User_Story__c> storiesById = new UserStoriesSelector().byId(new Set<Id>{ story.Id });

        // Verify
        List<User_Story__c> assertStories = [SELECT Id FROM User_Story__c LIMIT 1];
        System.assertEquals(1, storiesById.size(), 'Number of records returned should be 1');
        System.assert(assertStories.equals(storiesById), 'Lists must be identical');
    }

    @IsTest
    private static void queryByIdWithIndexingEnabled() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        Database.QueryLocator query = selector.byIdWithIndexingEnabled(new Set<Id>());

        // Verify
        String assertQuery = 'SELECT Id FROM User_Story__c WHERE Id IN :ids AND Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }

    @IsTest
    private static void queryWithIndexingEnabled() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        Database.QueryLocator query = selector.withIndexingEnabled();

        // Verify
        String assertQuery = 'SELECT Id FROM User_Story__c WHERE Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }
}