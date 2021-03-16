public without sharing class UserStoryTriggerHandler implements ITrigger {
    public UserStoryTriggerHandler() {
    }

    public void bulkBefore() {
        UserStoryTriggerHelper.prepareMaps();
    }

    public void bulkAfter() {
    }

    /**
        Modifier is set to private after checking that it was not being referenced anywhere else,
        so that way the scope of the method funcionality can be reduced and more clear
    */
    private void beforeCommon(SObject oldSo, SObject so) {
        UserStoryTriggerHelper.setProject((User_Story__c) so);
        UserStoryTriggerHelper.setEnvironment((User_Story__c) so);
        UserStoryTriggerHelper.validateOrgEnvironmentRelationship((User_Story__c) so);
        UserStoryTriggerHelper.checkSprints((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.setOrderBeforeUpdate((User_Story__c) oldSo, (User_Story__c) so);
    }

    public void beforeInsert(SObject so) {
        beforeCommon(null, so);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        beforeCommon(oldSo, so);
        UserStoryTriggerHelper.setChildPromotedUserStoriesAsOutdated((User_Story__c) oldSo, (User_Story__c) so);
    }
    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        UserStoryTriggerHelper.addUserStoryToPromoteDeployQueue((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.stopIndexingMetadata((User_Story__c) oldSo, (User_Story__c) so);
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        UserStoryTriggerHelper.promoteAndDeployUserStories();
        UserStoryTriggerHelper.updateUserStories();
        UserStoryTriggerHelper.executeIndexMetadataJob();
        update new List<Promoted_User_Story__c>(UserStoryTriggerHelper.promotedUserStoriesToUpdateAsOutdated);
    }
}