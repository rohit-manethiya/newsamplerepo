@IsTest
private with sharing class ExportAutomationTemplateTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    private static void executeAutomationTemplate() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            String automationDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Automation_Template')
                .getRecordTypeId();
            Deployment__c automationTemplate = TestDataFactory.createDeployment('Test Dev 1', automationDeploymentRecordTypeId, orgs[2].Id);

            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c advancedDeployment = TestDataFactory.createDeployment('Test Dev 1', advancedDeploymentRecordTypeId, orgs[2].Id);
            insert new List<Deployment__c>{ automationTemplate, advancedDeployment };

            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(advancedDeployment.Id, orgs[1].Id);
            insert destinationOrg;

            Step__c automationTemplateStep = TestDataFactory.createStep(automationTemplate.Id, 'Step 1', 'Apex', 'Not Started', 1, null, '');
            Step__c advancedDeploymentStep = TestDataFactory.createStep(advancedDeployment.Id, 'Step 1', 'Automation', 'Not Started', 1, null, '');
            advancedDeploymentStep.dataJson__c = '{"automationId":"' + automationTemplate.Id + '"}';
            insert new List<Step__c>{ automationTemplateStep, advancedDeploymentStep };

            String automationStepAttachmentBody = 'System.debug("test automation ");';
            Attachment automationStepAttachment = TestDataFactory.createAttachment('Apex', automationTemplateStep.Id, automationStepAttachmentBody);

            String advancedStepAttachmentBody = '"{\"automationId\":\"' + automationTemplate.Id + '\"}"';
            Attachment advancedStepAttachment = TestDataFactory.createAttachment('Apex', advancedDeploymentStep.Id, advancedStepAttachmentBody);
            insert new List<Attachment>{ automationStepAttachment, advancedStepAttachment };

            Test.startTest();
            List<ExportAutomationTemplate.InvocableVariables> variables = new List<ExportAutomationTemplate.InvocableVariables>();
            ExportAutomationTemplate.InvocableVariables firstSet = new ExportAutomationTemplate.InvocableVariables();
            firstSet.automationTemplateId = automationTemplate.Id;
            variables.add(firstSet);
            List<String> expectedContentDocuments = ExportAutomationTemplate.execute(variables);

            List<String> contentDocuments = new List<String>();
            for (ContentDocument contentDocumentRecord : [SELECT Id, Title, FileExtension, CreatedDate FROM ContentDocument LIMIT 1]) {
                contentDocuments.add(contentDocumentRecord.Id);
            }
            System.assertEquals(expectedContentDocuments.size(), contentDocuments.size());
            Test.stopTest();
        }
    }
}