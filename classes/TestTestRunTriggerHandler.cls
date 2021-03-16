@isTest
private class TestTestRunTriggerHandler {

    static testMethod void myUnitTest() {
        
        Integer STEPSCOUNT = 25;
        Integer RUNSCOUNT = 10;
        
        Project__c testProject = CMtestMethodUtilities.createProject('My Project');
        insert testProject;
        
        Sprint__c testSprint = CMtestMethodUtilities.createSprint('My Sprint');
        testSprint.Project__c = testProject.Id;
        insert testSprint;
        
        User_Story__c userStory = CMtestMethodUtilities.createUserStory('testUserStoryName');
        userStory.Project__c = testProject.Id;
        userStory.Sprint__c = testSprint.Id;
        insert userStory;
        
        Test_Script__c ts = CMTestMethodUtilities.createTestScript('test');
        ts.User_Story__c = userStory.Id;
        ts.Expected_Result__c = 'Some expected result';
        ts.Introduction__c = 'Some introduction';
        insert ts;
        
        List<Test_Script_Step__c> steps = new List<Test_Script_Step__c>();
        for(Integer i=1; i<=STEPSCOUNT; i++){
        	Test_Script_Step__c tss = CMTestMethodUtilities.createTestScriptStep(ts.Id, i+' step title');
        	tss.Action_Description__c = ''+i+' some text';
        	tss.Expected_Result__c = ''+i+' some text';
        	tss.Guidance_notes__c = ''+i+' some text';
        	tss.Order__c = i;
        	steps.add(tss);
        }
        insert steps;
        Test.startTest();
        List<Test_Run__c> runs = new List<Test_Run__c>();
        for(Integer i=1; i<=RUNSCOUNT; i++){
	    	Test_Run__c run = new Test_Run__c();
	    	run.Test_Script__c = ts.Id;
	    	runs.add(run);
        }
        insert runs;
        
    	for(Test_Run__c r : [select Id, Project__c, Sprint__c, User_Story__c, Total_Steps__c from Test_Run__c]){
        	system.assertEquals(STEPSCOUNT, r.Total_Steps__c);
            system.assertEquals(userStory.Id, r.User_Story__c);
            system.assertEquals(testProject.Id, r.Project__c);
            system.assertEquals(testSprint.Id, r.Sprint__c);
        }
        Test.stopTest();
    }
}