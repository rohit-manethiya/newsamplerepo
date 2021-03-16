public with sharing class UserStoriesMetadataSelector extends fflib_SObjectSelector {
    private static final String INDEXING_ENABLED = 'AND User_Story__r.Project__r.Index_Metadata__c = true AND User_Story__r.Stop_Indexing_Metadata__c = false';
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story_Metadata__c.Id,
            User_Story_Metadata__c.Status__c,
            User_Story_Metadata__c.User_Story__c,
            User_Story_Metadata__c.Metadata_API_Name__c
        };
    }

    public SObjectType getSObjectType() {
        return User_Story_Metadata__c.sObjectType;
    }

    public Database.QueryLocator byStoryStatus(Set<Id> ids, String status) {
        return Database.getQueryLocator(newQueryFactory().setEnforceFLS(true).setCondition('User_Story__c = :ids AND Status__c = :status').toSOQL());
    }

    public List<User_Story_Metadata__c> byStoryIdsIndexingEnabled(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setEnforceFLS(true).setCondition('User_Story__c = :ids ' + INDEXING_ENABLED);
        return (List<User_Story_Metadata__c>) Database.query(query.toSOQL());
    }

    public Database.QueryLocator byMetadataIndexingEnabled(Set<String> apiNames) {
        return Database.getQueryLocator(
            newQueryFactory().setEnforceFLS(true).setCondition('Metadata_API_Name__c = :apiNames ' + INDEXING_ENABLED).toSOQL()
        );
    }

    public Database.QueryLocator byMetadatanameStatusIndexingEnabled(Set<String> apiNames, String status) {
        return Database.getQueryLocator(
            newQueryFactory()
                .setEnforceFLS(true)
                .setCondition('Status__c = :status AND Metadata_API_Name__c = :apiNames ' + INDEXING_ENABLED)
                .toSOQL()
        );
    }
}