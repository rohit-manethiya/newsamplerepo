@IsTest
private with sharing class ViewDeploymentExtensionTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.setTestSettingsEE();
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void myUnitTest() {
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;

        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id', testDeployment.id);
        Test.setCurrentPage(pref);

        ViewDeploymentExtension ext = new ViewDeploymentExtension(new ApexPages.StandardController(testDeployment));
        System.assertEquals(true, ext.runPoller);
        System.assertEquals(1, ext.mapDeploymentJobsString.size());
        System.debug('## keys: ' + ext.mapAttachments.keySet());
        System.debug('## values: ' + ext.mapAttachments.values());
        System.assertEquals(2, ext.mapAttachments.size());
        System.assertEquals(1, ext.matrix.size());
        System.assertEquals(testStep.Id, ext.matrix[0].step.Id);
        System.assertEquals(1, ext.matrix[0].jobs.size());

        Attachment depErrors = new Attachment(
            Body = Blob.valueOf('[{"l":"ERROR","m":"This is a deployment error message","t":""}]'),
            Name = testDeployment.Id + '.json',
            ParentId = testDeployment.Id
        );
        insert depErrors;
        Attachment jobError = new Attachment(
            Body = Blob.valueOf('[{"l":"INFO","m":"Deployment job message","t":""}]'),
            Name = ext.matrix[0].jobs[0].Id + '.json',
            ParentId = testDeployment.Id
        );
        insert jobError;
        testDeployment.status__c = 'Completed Successfully';
        update testDeployment;
        ext = new ViewDeploymentExtension(new ApexPages.StandardController(testDeployment));
        System.assertEquals(false, ext.runPoller);
        for (String i : ext.mapAttachments.keySet()) {
            System.assertEquals(true, ext.mapAttachments.get(i));
        }
        System.assert(testMethodUtilities.hasMessage('This is a deployment error message'));

        ext.selectedStep = testStep.Id;
        ext.getStepDetail();

        DeployAPI.cancelDeployment(ext.deployment.Id);
    }
}