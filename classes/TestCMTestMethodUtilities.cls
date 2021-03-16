@isTest
private class TestCMTestMethodUtilities {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    @testSetup 
    static void setupData() {
        TestUtilities.enableLicenses(10,10,10,10,10,100);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    static testMethod void UnitTestsForAllMethods() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            upsert TestUtilities.getTestSettings();
            Copado_License__c license = Copado_License__c.getInstance();
            license.Enable_Copado__c = true;
            license.Enable_CCM__c = false;
            license.Enable_CCH__c = false;
            license.Enable_CST__c = false;
            upsert license;

            Deployment_Flow__c testFlow = CMTestMethodUtilities.createFlow('s');
            insert testFlow;
            system.assert(testFlow.Id != null);
            
            Deployment_Flow__c testCCMFlow = CMTestMethodUtilities.createCCMFlow('s', true);
            insert testCCMFlow;
            system.assert(testCCMFlow.Id != null);
            system.assert(true, testCCMFlow.Active__c);
            
            Git_Repository__c g = new Git_Repository__c(name = 'g');
            insert g;
            Deployment_Flow__c testCBMFlow = CMTestMethodUtilities.createCBMFlow('s', true, g.Id, 'master');
            insert testCBMFlow;
            system.assert(testCBMFlow.Id != null);
            
            Project__c testProject = CMTestMethodUtilities.createProject('s');
            testProject.Deployment_Flow__c = testCCMFlow.Id;
            insert testProject;
            system.assert(testProject.Id != null);
            system.assertEquals('s', testProject.Name);
            
            Sprint__c testSprint = CMTestMethodUtilities.createSprint('s');
            insert testSprint;
            system.assert(testSprint.Id != null);
            system.assertEquals('s', testSprint.Name);
            
            User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('s');
            insert testUserStory;
            system.assert(testUserStory.Id != null);
            system.assertEquals('s', testUserStory.User_Story_Title__c);
            
            Test_Script__c testScript = CMTestMethodUtilities.createTestScript('s');
            insert testScript;
            system.assert(testScript.Id != null);
            system.assertEquals('s', testScript.Test_Title__c);
            
            Test_Script_Step__c testScriptStep = CMTestMethodUtilities.createTestScriptStep(testScript.Id, 's');
            insert testScriptStep;
            system.assert(testScriptStep.Id != null);
            system.assertEquals('s', testScriptStep.Step_Title__c);
            system.assertEquals(testScript.Id, testScriptStep.Test_Script__c);
            
            Test_Run__c testRun = CMTestMethodUtilities.createTestRun(testScript.Id);
            insert testRun;
            system.assert(testRun.Id != null);
        
            Test_Run_Step__c testRunStep = CMTestMethodUtilities.createTestRunStep(testRun.Id, testScriptStep.Id);
            insert testRunStep;
            system.assert(testRunStep.Id != null);
            system.assertEquals(testRun.Id, testRunStep.Test_Run__c);
            system.assertEquals(testScriptStep.Id, testRunStep.Script_Step__c);
            
            Release__c testRelease = CMTestMethodUtilities.createRelease('s');
            insert testRelease;
            system.assert(testRelease.Id != null);
            
            Environment__c env1 = new Environment__c(Name='UAT Environment');
            insert env1;
            Environment__c env2 = new Environment__c(Name='Production Environment');
            insert env2;

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, system.now(), env1.Id);
            insert testOrg1;
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            insert testOrg2;
            
            Deployment_Flow_Step__c testFlowStep = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, testCCMFlow.Id);
            insert testFlowStep;
            system.assert(testFlowStep.Id != null);
            
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            insert testPromotion;
            system.assert(testPromotion.Id != null);

            testProject.Deployment_Flow__c = testCBMFlow.Id;
            update testProject;
            Deployment_Flow_Step__c testFlowStep2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, testCBMFlow.Id);
            testFlowStep2.Branch__c = 'dev1';
            insert testFlowStep2;
            Promotion__c testBackPromotion = CMTestMethodUtilities.createBackPromotion(testProject.Id, env1.Id);
            insert testBackPromotion;
            system.assert(testBackPromotion.Id != null);
            
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'test'));
            system.assert(CMTestMethodUtilities.hasMessage('test'));
            Test.stopTest();
        }
    }
}