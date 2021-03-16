@isTest
private class TestCreateTestScriptStepsController {

    @testSetup static void setupTestData(){
        insert TestUtilities.getTestSettings();
    }

    static testMethod void myUnitTest() {
    	Test_Script__c script = CMTestMethodUtilities.createTestScript('test');
    	insert script;
    	
    	PageReference pref = Page.MassAddToRelease;
	    pref.getParameters().put('tId',script.id);
	    Test.setCurrentPage(pref);
	    
        Test.startTest();
        CreateTestScriptStepsController con = new CreateTestScriptStepsController();
        List<CreateTestScriptStepsController.stepRow> steps = con.getSteps();
        system.assertEquals(0, steps.size());
        
        con.dummyStep.Action_Description__c = 'Login to Salesforce';
        con.dummyStep.Expected_Result__c = 'You are logged in';
        con.addRow();
        steps = con.getSteps();
        system.assertEquals(1, steps.size());
        
        con.scriptSteps[0].step.Action_Description__c = 'Login with password';
        con.scriptSteps[0].saveStep();
        steps = con.getSteps();
        system.assertEquals(1, steps.size());
        system.assertEquals('Login with password', steps[0].step.Action_Description__c);
        
        String longString = '12345678901234567890123456789012345678901234567890';
       	longString = longString+longString+longString+longString+longString+longString; // 300 character string.
        con.scriptSteps[0].step.Action_Description__c = longString;
        con.scriptSteps[0].saveStep();
        steps = con.getSteps();
        system.assertEquals(1, steps.size());
        system.assertEquals('Login with password', steps[0].step.Action_Description__c);
        // Page Message error that should appear
        //Action/Description: data value too large: (max length=255):
        boolean hasMessage = false;
        for(ApexPages.Message p : ApexPages.getMessages()){
        	if(p.getSummary().contains('data value too large')){
        		hasMessage = true;
        	}
        }
        system.assertEquals(true, hasMessage);
        con.scriptSteps[0].deleteStep();
        steps = con.getSteps();
        system.assertEquals(0, steps.size());
        
        
		pref = con.returnToTestScript();
		system.assertEquals('/'+script.id, pref.getUrl());
        Test.stopTest();
    	
    }
}