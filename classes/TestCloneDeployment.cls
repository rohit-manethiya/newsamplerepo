@isTest
private class TestCloneDeployment {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
    static testMethod void testBothSuccess(){
        Org__c testFromOrg = testMethodUtilities.createOrg('a','b','c','d','e', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('a',System.now(), System.now(),testFromOrg.Id,'c','d');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('a','b','c',testDeployment.Id,0,'e','f');
		insert testStep;
		Destination_Org__c destOrg = testMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
		insert destOrg;
		
		Blob b = Blob.valueOf('Test Data');  
        Attachment testAttachment = new Attachment();  
        testAttachment.ParentId = testStep.Id;  
        testAttachment.Name = 'Test Attachment for Parent';  
        testAttachment.ContentType = 'Text';
        testAttachment.Body = b;  
        insert testAttachment;
		
        test.startTest();
			cloneDeploymentExtension ext = new cloneDeploymentExtension(new ApexPages.StandardController(testDeployment));
			ext.clone_steps = true;
			ext.clone_destOrgs = true;
			ext.doClone();
			PageReference pageRef = ext.cancel();
		test.stopTest();
		
		system.assertEquals('/'+testDeployment.Id,pageRef.getUrl());
		
		Deployment__c[] resultDeployment = [select Id, Name from Deployment__c where Name =: 'Copy of '+testDeployment.name];
		system.assertEquals(1, resultDeployment.size());
		Step__c[] resultStep = Utilities.getStepsByDeploymentId(resultDeployment[0].Id);
		system.assertEquals(1, resultStep.size());
		Destination_Org__c[] resultDestOrgs = Utilities.getDestinationOrgsByDeploymentId(resultDeployment[0].Id);
		system.assertEquals(1, resultDestOrgs.size());
    }
    static testMethod void testNONEselected(){
        Org__c testFromOrg = testMethodUtilities.createOrg('a','b','c','d','e', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('a',System.now(), System.now(),testFromOrg.Id,'c','d');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('a','b','c',testDeployment.Id,0,'e','f');
		insert testStep;
		Destination_Org__c destOrg = testMethodUtilities.create(testDeployment.Id, 'Pending', testFromOrg.Id);
		insert destOrg;
		
		Blob b = Blob.valueOf('Test Data');  
        Attachment testAttachment = new Attachment();  
        testAttachment.ParentId = testStep.Id;  
        testAttachment.Name = 'Test Attachment for Parent';  
        testAttachment.ContentType = 'Text';
        testAttachment.Body = b;  
        insert testAttachment;
		
        test.startTest();
			cloneDeploymentExtension ext = new cloneDeploymentExtension(new ApexPages.StandardController(testDeployment));
			ext.clone_steps = false;
			ext.clone_destOrgs = false;
			ext.doClone();
			PageReference pageRef = ext.cancel();
		test.stopTest();
		
		system.assertEquals('/'+testDeployment.Id,pageRef.getUrl());
		
		Deployment__c[] resultDeployment = [select Id, Name from Deployment__c where Name =: 'Copy of '+testDeployment.name];
		system.assertEquals(1, resultDeployment.size());
		Step__c[] resultStep = Utilities.getStepsByDeploymentId(resultDeployment[0].Id);
		system.assertEquals(0, resultStep.size());
		Destination_Org__c[] resultDestOrgs = Utilities.getDestinationOrgsByDeploymentId(resultDeployment[0].Id);
		system.assertEquals(0, resultDestOrgs.size());
    }
}