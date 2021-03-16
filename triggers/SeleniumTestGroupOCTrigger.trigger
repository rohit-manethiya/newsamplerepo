trigger SeleniumTestGroupOCTrigger on Selenium_Group_Org_Credential__c (after delete, after insert, after update, before delete, before insert, before update)
{

	TriggerFactory.createAndExecuteHandler(SeleniumTestGroupOCTriggerHandler.class);
}