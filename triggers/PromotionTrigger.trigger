trigger PromotionTrigger on Promotion__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
  TriggerFactory.createAndExecuteHandler(PromotionTriggerHandler.class);
}