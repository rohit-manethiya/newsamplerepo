trigger StepTrigger on Step__c (after delete, after insert, after update, before delete, before insert, before update)
{

	TriggerFactory.createAndExecuteHandler(StepTriggerHandler.class);
}