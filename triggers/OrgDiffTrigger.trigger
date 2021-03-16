trigger OrgDiffTrigger on OrgDiff__c (after delete, after insert, after update, before delete, before insert, before update)
{
    TriggerFactory.createAndExecuteHandler(OrgDiffTriggerHandler.class);
}