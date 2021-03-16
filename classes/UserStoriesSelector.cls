public with sharing class UserStoriesSelector extends fflib_SObjectSelector {
    private static final String INDEXING_ENABLED = 'Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true';
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ User_Story__c.Id, User_Story__c.Name, User_Story__c.Environment__c };
    }

    public SObjectType getSObjectType() {
        return User_Story__c.sObjectType;
    }

    public List<User_Story__c> byIds(Set<Id> ids) {
        return (List<User_Story__c>) Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .selectField('Project__r.Deployment_Flow__c')
                .selectField('Release__r.Project__r.Deployment_Flow__c')
                .setCondition('Id IN :ids')
                .toSOQL()
        );
    }

    public Database.QueryLocator byIdWithIndexingEnabled(Set<Id> ids) {
        return Database.getQueryLocator(newQueryFactory().setEnforceFLS(true).setCondition('Id IN :ids AND ' + INDEXING_ENABLED).toSOQL());
    }

    public Database.QueryLocator withIndexingEnabled() {
        return Database.getQueryLocator(newQueryFactory().setEnforceFLS(true).setCondition(INDEXING_ENABLED).toSOQL());
    }
}