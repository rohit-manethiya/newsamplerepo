trigger GitOrgCommitTrigger on Git_Org_Commit__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
  TriggerFactory.createAndExecuteHandler(GitOrgCommitTriggerHandler.class);
}