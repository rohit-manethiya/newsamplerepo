trigger SeleniumTestCaseTrigger on Selenium_Test_Case__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(SeleniumTestCaseTriggerHandler.class);
}