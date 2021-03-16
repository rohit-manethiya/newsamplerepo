trigger ConnectionBehaviorTrigger on Connection_Behavior__c (after delete, after insert, after undelete,
        after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(ConnectionBehaviorTriggerHandler.class);
}