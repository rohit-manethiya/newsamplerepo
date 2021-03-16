@isTest
private class TestNewBuildTaskEmailController {
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
        Test.startTest();
        NewBuildTaskEmailController.buildTaskId = null;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        con.getErrorList();
        System.assertEquals(Label.RECORD_NOT_FOUND, NewBuildTaskEmailController.statusMessage);
        NewBuildTaskEmailController.buildTaskId = bt.Id;
        NewBuildTaskEmailController.continuousIntegrationId = ci.Id;
        con.getErrorList();
        Test.stopTest();
        System.assertEquals('My CI 1', NewBuildTaskEmailController.continuousIntegrationRecord.Name);
        System.assertEquals('', NewBuildTaskEmailController.statusMessage);
        System.assertEquals(2, NewBuildTaskEmailController.errorDetails.size());
        System.assertEquals('ERROR', NewBuildTaskEmailController.errorDetails[0].type);
        System.assertEquals('[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027', NewBuildTaskEmailController.errorDetails[0].message);
        System.assertEquals('', NewBuildTaskEmailController.errorDetails[0].copadoTip);
    }
    static testMethod void NoBuildTaskRecordFound(){
        Test.startTest();
        NewBuildTaskEmailController.buildTaskId = null;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        List<NewBuildTaskEmailController.WrapperError> result1 = con.getErrorList();
        String resultId = NewBuildTaskEmailController.buildTaskId;
        Test.stopTest();
        System.assertEquals(Label.RECORD_NOT_FOUND, NewBuildTaskEmailController.statusMessage);
        System.assertEquals(null, resultId);
    }
    static testMethod void NoBuildTasksException(){
        Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c=ci.Id, Duration__c=1, Status__c='Pending');
        insert bt;
        Test.startTest();
        NewBuildTaskEmailController.buildTaskId = bt.Id;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        List<NewBuildTaskEmailController.WrapperError> result1 = con.getErrorList();
        Test.stopTest();
        String expected = String.format(Label.BUILD_TASK_RECORD_NOT_FOUND, new List<String>{bt.Id});
        System.assertEquals(expected, NewBuildTaskEmailController.statusMessage);
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
        NewBuildTaskEmailController.buildTaskId = bt.Id;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        List<NewBuildTaskEmailController.WrapperError> result1 = con.getErrorList();
        Test.stopTest();
        System.assertEquals('No deployment jobs could be found.', NewBuildTaskEmailController.statusMessage);
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
        NewBuildTaskEmailController.buildTaskId = bt.Id;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        con.getErrorList();
        Test.stopTest();
        System.assertEquals(Label.NO_ERROR_ATTACHMENT_FOUND, NewBuildTaskEmailController.statusMessage);
        System.assertEquals(0, NewBuildTaskEmailController.errorDetails.size());
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
        System.assert(attr[0].BodyLength>NewBuildTaskEmailController.MAX_BODY_LENGTH);

        Attachment testAttachment2 = createAttachment(testStep.Id, 'MetaData', '['+attBody2+']');
        insert testAttachment2;

        Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        insert ci;
        Build_Task__c bt = new Build_Task__c(Continuous_Integration__c=ci.Id, Duration__c=1, Status__c='Pending');
        bt.Deployment__c = testDeployment.Id;
        insert bt;

        Test.startTest();
        NewBuildTaskEmailController.buildTaskId = bt.Id;
        NewBuildTaskEmailController con = new NewBuildTaskEmailController();
        con.getErrorList();
        Test.stopTest();
        System.assertEquals(Label.MAX_FILE_SIZE_EXCEEDED, NewBuildTaskEmailController.statusMessage);
        System.assertEquals(0, NewBuildTaskEmailController.errorDetails.size());
    }
    private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
}