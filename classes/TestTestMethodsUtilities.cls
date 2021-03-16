@IsTest
private class TestTestMethodsUtilities {
    @TestSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testUtilitiesMethods() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testFromOrg.Id, 'Deploy now', 'Pending');
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'Draft', 'MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        Deployment_Job__c testJob = testMethodUtilities.create(0, testDestOrg.Id, 'external_id', 'Draft', testStep.Id);
        insert testJob;
        System.assertEquals('DEPLOYMENT_NAME', testDeployment.Name);
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('test', 'http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, testFromOrg);
        insert gitBackup;
        Attachment att = testMethodUtilities.createAttachment(testFromOrg.Id, 'test', 'test');
        insert att;

        ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'test'));
        System.assert(testMethodUtilities.hasMessage('test'));
    }
}