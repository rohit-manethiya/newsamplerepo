trigger UserStoryCommitTrigger on User_Story_Commit__c (after delete, after insert, after update, before delete, before insert, before update)
{

	TriggerFactory.createAndExecuteHandler(UserStoryCommitTriggerHandler.class);
}