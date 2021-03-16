@isTest
private class TestBuildTaskEmailController {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void TestFullComponent(){
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [SELECT Id FROM Deployment_Job__c WHERE Step__r.Deployment__c=:testDeployment.Id AND Step__r.Type__c='Git MetaData'];
        System.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');


        String attBody = '[{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""}]';
        System.debug('@@@ jobs Id: '+testJobs[0].Id+'.json');
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', attBody);
        insert testAttachment;

        attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        testAttachment = createAttachment(testStep.Id, 'MetaData', attBody);
        insert testAttachment;

        Continuous_Integration__c ci = new Continuous_Integration__c(Name = 'My CI 1', Active__c = true, Status__c = 'Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c = ci.Id, Duration__c = 1, Status__c = 'Pending');
        bt.Deployment__c = testDeployment.Id;
        insert bt;
        System.debug('@@@ bt 1: '+bt);
        Test.startTest();
        BuildTaskEmailController.buildTaskId = null;
        BuildTaskEmailController con = new BuildTaskEmailController();
        con.getErrorList();
        con.getBuildTaskList();
        System.assertEquals('Build task record not found.', BuildTaskEmailController.statusMessage);
        System.assertEquals('Build task record not found.', BuildTaskEmailController.buildTaskMessage);
        BuildTaskEmailController.buildTaskId = bt.Id;
        System.debug('@@ bt 2: '+bt);
        System.debug('@@ BuildTaskEmailController.buildTaskId: '+BuildTaskEmailController.buildTaskId);
        con.getErrorList();
        con.getBuildTaskList();
        Test.stopTest();
        System.assertEquals('', BuildTaskEmailController.statusMessage);
        System.assertEquals(2, BuildTaskEmailController.errorDetails.size());
        System.assertEquals('ERROR', BuildTaskEmailController.errorDetails[0].l);
        System.assertEquals('[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027', BuildTaskEmailController.errorDetails[0].m);
        System.assertEquals('', BuildTaskEmailController.errorDetails[0].t);
        System.assertEquals('', BuildTaskEmailController.buildTaskMessage);
        System.assertEquals(1, BuildTaskEmailController.buildTaskDetails.size());
        System.assertEquals('ApexClass', BuildTaskEmailController.buildTaskDetails[0].t);
		System.assertEquals('TestAccountTrigger', BuildTaskEmailController.buildTaskDetails[0].n);
    }
    static testMethod void testComparable(){
        BuildTaskEmailController.sortType = null;
        BuildTaskEmailController con = new BuildTaskEmailController();
        BuildTaskEmailController.BuildTaskContent btc1 = new BuildTaskEmailController.BuildTaskContent();
        btc1.n = 'OpportunityTrigger';
        btc1.t = 'ApexTrigger';
        BuildTaskEmailController.buildTaskDetails = new List<BuildTaskEmailController.BuildTaskContent>();
        BuildTaskEmailController.buildTaskDetails.add(btc1);
        BuildTaskEmailController.BuildTaskContent btc2 = new BuildTaskEmailController.BuildTaskContent();
        btc2.n = 'Account';
        btc2.t = 'Workflow';
        BuildTaskEmailController.buildTaskDetails.add(btc2);
        BuildTaskEmailController.buildTaskDetails.sort();
        System.assertEquals('Account', BuildTaskEmailController.buildTaskDetails[0].n);

        BuildTaskEmailController.sortType = 'type';
        BuildTaskEmailController.buildTaskDetails.sort();
        System.assertEquals('OpportunityTrigger', BuildTaskEmailController.buildTaskDetails[0].n);
    }
    static testMethod void NoBuildTaskRecordFound(){
        Test.startTest();
        BuildTaskEmailController.buildTaskId = null;
        BuildTaskEmailController con = new BuildTaskEmailController();
        List<BuildTaskEmailController.ErrorContent> result1 = con.getErrorList();
        List<BuildTaskEmailController.BuildTaskContent> result2 = con.getBuildTaskList();
        String resultId = BuildTaskEmailController.getBuildTaskId();
        Test.stopTest();
        System.assertEquals('Build task record not found.', BuildTaskEmailController.buildTaskMessage);
        System.assertEquals('Build task record not found.', BuildTaskEmailController.statusMessage);
        System.assertEquals(null, resultId);
    }
    static testMethod void NoBuildTasksException(){
        Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c=ci.Id, Duration__c=1, Status__c='Pending');
        insert bt;
        Test.startTest();
        BuildTaskEmailController.buildTaskId = bt.Id;
        BuildTaskEmailController con = new BuildTaskEmailController();
        List<BuildTaskEmailController.ErrorContent> result1 = con.getErrorList();
        List<BuildTaskEmailController.BuildTaskContent> result2 = con.getBuildTaskList();
        Test.stopTest();
        String expected = 'Using a Build Task Id no records were found. Please make sure this build task ('+bt.Id+') has a Deployment, you have access to it and has not been deleted.';
        System.assertEquals(expected, BuildTaskEmailController.buildTaskMessage);
        System.assertEquals(expected, BuildTaskEmailController.statusMessage);
    }
    static testMethod void NoDeploymentJobsFound(){
        Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), null, 'Deploy now', 'Scheduled');
        insert testDeployment;
        Continuous_Integration__c ci = new Continuous_Integration__c(Name = 'My CI 1', Active__c = true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c = ci.Id, Duration__c = 1, Status__c='Pending');
        bt.Deployment__c = testDeployment.Id;
		insert bt;
        Test.startTest();
        BuildTaskEmailController.buildTaskId = bt.Id;
        BuildTaskEmailController con = new BuildTaskEmailController();
        List<BuildTaskEmailController.ErrorContent> result1 = con.getErrorList();
        List<BuildTaskEmailController.BuildTaskContent> result2 = con.getBuildTaskList();
        Test.stopTest();
        System.assertEquals('No deployment jobs could be found.', BuildTaskEmailController.buildTaskMessage);
        System.assertEquals('No deployment jobs could be found.', BuildTaskEmailController.statusMessage);
    }
    static testMethod void NoAttachmentsFound(){
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;

        Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [SELECT Id FROM Deployment_Job__c WHERE Step__r.Deployment__c=:testDeployment.Id AND Step__r.Type__c='Git MetaData'];
        System.assertEquals(1, testJobs.size());

        Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c=ci.Id, Duration__c=1, Status__c='Pending');
        bt.Deployment__c = testDeployment.Id;
        insert bt;

        Test.startTest();
        BuildTaskEmailController.buildTaskId = bt.Id;
        BuildTaskEmailController con = new BuildTaskEmailController();
        con.getErrorList();
        con.getBuildTaskList();
        Test.stopTest();
        System.assertEquals('No error attachment was found', BuildTaskEmailController.statusMessage);
        System.assertEquals(0, BuildTaskEmailController.errorDetails.size());
        System.assertEquals('No selected metadata attachment was found', BuildTaskEmailController.buildTaskMessage);
        System.assertEquals(0, BuildTaskEmailController.buildTaskDetails.size());
    }
    static testMethod void AttachmentTooBig(){
    	Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [SELECT Id FROM Deployment_Job__c WHERE Step__r.Deployment__c=:testDeployment.Id AND Step__r.Type__c='Git MetaData'];
        System.assertEquals(1, testJobs.size());

        //Now create attachment against deployment.
        String attBody = '{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},';
        String attBody2 = '{"t":"ApexClass","n":"TestAccountTrigger"},"t":"ApexClass","n":"TestAccountTrigger"},"t":"ApexClass","n":"TestAccountTrigger"},"t":"ApexClass","n":"TestAccountTrigger"},"t":"ApexClass","n":"TestAccountTrigger"},';
        for(Integer i=0; i<=11; i++){
            attBody += attBody;
            attBody2 += attBody2;
        }
        attBody = attBody.substring(0, attBody.length()-1); //removes last comma.
        attBody2 = attBody2.substring(0, attBody2.length()-1);
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', '['+attBody+']');
        insert testAttachment;
        List<Attachment> attr = [SELECT Id, BodyLength FROM Attachment WHERE Id=:testAttachment.Id];
        System.assert(attr[0].BodyLength>BuildTaskEmailController.MAX_BODY_LENGTH);

        Attachment testAttachment2 = createAttachment(testStep.Id, 'MetaData', '['+attBody2+']');
        insert testAttachment2;

        Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c=ci.Id, Duration__c=1, Status__c='Pending');
        bt.Deployment__c = testDeployment.Id;
        insert bt;

        Test.startTest();
        BuildTaskEmailController.buildTaskId = bt.Id;
        BuildTaskEmailController con = new BuildTaskEmailController();
        con.getErrorList();
        con.getBuildTaskList();
        Test.stopTest();
        System.assertEquals('The maximum file size for the error list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.', BuildTaskEmailController.statusMessage);
        System.assertEquals(0, BuildTaskEmailController.errorDetails.size());
        System.assertEquals('The maximum file size for the build list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.', BuildTaskEmailController.buildTaskMessage);
        System.assertEquals(0, BuildTaskEmailController.buildTaskDetails.size());
    }
    private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
}