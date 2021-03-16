@IsTest
private class Test_DataTemplateObjectResultController {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }
    /**
     * Show data templte results
     */
    @IsTest
    static void showDataTemplateResults() {
        String sourceTargetUrlMapResult = '{"target":"https://login.salesforce.com/","source":"https://login.salesforce.com/"}';
        //StepId is only needed for the name, it is not created in the test.
        String stepId = 'a0x1n000005HedVAAS';
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);
            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);
            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Account Template',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            insert dt;
            // Only CSV attachment needed for the test class. The other one is retrieved by the JS functions.
            String attachmentName = stepId + '_' + dt.Name + '_' + dt.Id;

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('My new Data Deployment', dataDeploymentRecordTypeId, orgList[0].Id);
            insert deployment;

            Destination_Org__c destination = TestDataFactory.createDestinationOrg(deployment.Id, orgList[0].Id);
            insert destination;

            Attachment csvAttachmentResult = TestDataFactory.createAttachment(attachmentName + '.csv', deployment.Id, ''); // No content needed for the test
            insert csvAttachmentResult;

            Test.startTest();
            PageReference pReference = Page.DataTemplateObjectResult;
            Test.setCurrentPage(pReference);

            pReference.getParameters().put('templateName', dt.Name);
            pReference.getParameters().put('deploymentId', deployment.Id);
            pReference.getParameters().put('stepId', stepId);
            pReference.getParameters().put('templateId', dt.Id);

            DataTemplateObjectResultController dataTemplateResult = new DataTemplateObjectResultController();

            System.assertEquals(sourceTargetUrlMapResult, dataTemplateResult.sourceTargetUrlMap);
            System.assertEquals(dt.Name, dataTemplateResult.templateName);
            System.assertEquals(csvAttachmentResult.Id, dataTemplateResult.csvAttachmentId);
            System.assertEquals(attachmentName, dataTemplateResult.attachmentName);
            System.assertEquals(deployment.Id, dataTemplateResult.deploymentId);

            Test.stopTest();
        }
    }
}