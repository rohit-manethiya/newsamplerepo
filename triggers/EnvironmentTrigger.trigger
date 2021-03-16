trigger EnvironmentTrigger on Environment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(EnvironmentTriggerHandler.class);
}