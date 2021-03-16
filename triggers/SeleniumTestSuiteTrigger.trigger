trigger SeleniumTestSuiteTrigger on Selenium_Test_Suite__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(SeleniumTestSuiteTriggerHandler.class);
}