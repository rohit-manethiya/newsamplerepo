@isTest
private class TestExecuteTestRunExtension {
	@testSetup static void setupData() {
		TestUtilities.setTestSettingsEE();
	}
    static testMethod void myUnitTest() {
    	
    	Test_Script__c script = CMTestMethodUtilities.createTestScript('Test');
    	insert script;
    	Test_Script_Step__c step = CMTestMethodUtilities.createTestScriptStep(script.Id, 'Test');
    	insert step;
    	Test_Run__c run = CMTestMethodUtilities.createTestRun(script.Id);
    	insert run;
    	Test_Run_Step__c trs = CMTestMethodUtilities.createTestRunStep(run.Id, step.Id);
    	insert trs;
    	
    	Test.startTest();
    	PageReference pref = Page.MassAddToRelease;
	    pref.getParameters().put('id',run.id);
	    Test.setCurrentPage(pref);
	    
    	ExecuteTestRunExtension ext = new ExecuteTestRunExtension(new ApexPages.StandardController(run));
    	ext.access_statusColumn = 'Dropdown box';
    	ext.updateAccess_statusColumn();
    	system.assertEquals('Dropdown box', ext.access_statusColumn);
    	ext.access_statusColumn = 'Images';
    	ext.updateAccess_statusColumn();
    	system.assertEquals('Images', ext.access_statusColumn);
    	
    	ext.steps[0].Status__c = 'Changed';
    	ext.saveProgress();
    	ext = new ExecuteTestRunExtension(new ApexPages.StandardController(run));
    	system.assertEquals('Changed', ext.steps[0].Status__c);
        
        ext.thisStepId = trs.Id;
        ext.thisStepStatus = 'Pass';
        ext.updateTestRunStatus();
        system.assertEquals('', ext.thisStepId);
        system.assertEquals('', ext.thisStepStatus);
        system.assertEquals('Pass', [select Id, Status__c from Test_Run_Step__c where Id=:trs.Id].Status__c);
        
    	Test.stopTest();
    }
}