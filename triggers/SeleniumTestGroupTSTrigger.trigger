trigger SeleniumTestGroupTSTrigger on Selenium_Group_Test_Suite__c (after delete, after insert, after update, before delete, before insert, before update)
{

	TriggerFactory.createAndExecuteHandler(SeleniumTestGroupTSTriggerHandler.class);
}