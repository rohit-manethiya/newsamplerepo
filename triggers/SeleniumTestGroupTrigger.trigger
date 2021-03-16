trigger SeleniumTestGroupTrigger on Selenium_Test_Group__c (after delete, after insert, after update, before delete, before insert, before update)
{
    System.debug('Entering SeleniumTestGroupTrigger');
    if(SeleniumTestRunTriggerHelper.inTrigger){
        System.debug('Aborting SeleniumTestGroupTrigger');
     	return;   
    }
    System.debug('Calling SeleniumTestGroupTriggerHandler');
	TriggerFactory.createAndExecuteHandler(SeleniumTestGroupTriggerHandler.class);
}