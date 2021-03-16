trigger EnvironmentalVariableTrigger on Environmental_Variable__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(EnvironmentalVariableTriggerHandler.class);
}