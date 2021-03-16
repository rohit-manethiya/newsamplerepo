@isTest
private class TestDeploymentEmailController {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void TestFullComponent(){
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
        Step__c testStep2 = testMethodUtilities.create('Step 2','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep2;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [select Id from Deployment_Job__c where Step__r.Deployment__c=:testDeployment.Id and Step__r.Type__c='Git MetaData'];
        system.assertEquals(2, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        DeploymentEmailController.deployId = null;
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        system.assertEquals('Deployment record not found.', DeploymentEmailController.statusMessage);

        DeploymentEmailController.deployId = testDeployment.Id;
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        system.assertEquals('No error attachment was found.', DeploymentEmailController.statusMessage);

        String attBody = '[{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""}]';
        system.debug('@@@ jobs Id: '+testJobs[0].Id+'.json');
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', attBody);
        insert testAttachment;
        attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        testAttachment = createAttachment(testStep.Id, 'MetaData', attBody);
        insert testAttachment;
        attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        testAttachment = createAttachment(testStep2.Id, 'MetaData', attBody);
        insert testAttachment;
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        system.assertEquals('', DeploymentEmailController.statusMessage);

        test.stopTest();
    }

    static testMethod void MaxSizeAttachmentError(){
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [select Id from Deployment_Job__c where Step__r.Deployment__c=:testDeployment.Id and Step__r.Type__c='Git MetaData'];
        system.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.deployId = testDeployment.Id;
        //Now create attachment against deployment.
        String attBody = '{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},';
        for(Integer i=0; i<=11; i++){
            attBody += attBody;
        }
        System.debug('test class att' + attBody);
        attBody = attBody.substring(0, attBody.length()-1); //removes last comma.
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', '['+attBody+']');
        insert testAttachment;
        List<Attachment> attr = [select Id, BodyLength from Attachment where Id=:testAttachment.Id];
       
        system.assert(attr[0].BodyLength>BuildTaskEmailController.MAX_BODY_LENGTH);
        DeploymentEmailController.getErrorMessages();
        system.assertEquals('The maximum file size for the error list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.', DeploymentEmailController.statusMessage);

        test.stopTest();
    }

    static testMethod void MaxSizeAttachmentMeta(){
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [select Id from Deployment_Job__c where Step__r.Deployment__c=:testDeployment.Id and Step__r.Type__c='Git MetaData'];
        system.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.deployId = testDeployment.Id;
        //Now create attachment against deployment.
        String attBody = '{\"t\":\"ApexTrigger\",\"n\":\"AccountTrigger\",\"s\":true},';
        for(Integer i=0; i<=11; i++){
            attBody += attBody;
        }
        attBody = attBody.substring(0, attBody.length()-1); //removes last comma.
        Attachment testAttachment = createAttachment(testStep.Id, 'MetaData', '['+attBody+']');
        insert testAttachment;
        List<Attachment> attr = [select Id, BodyLength from Attachment where Id=:testAttachment.Id];
        system.assert(attr[0].BodyLength>BuildTaskEmailController.MAX_BODY_LENGTH);
        DeploymentEmailController.getDeploymentSteps();
        system.assertEquals('The maximum file size for the error list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.', DeploymentEmailController.statusMessage);

        test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
}