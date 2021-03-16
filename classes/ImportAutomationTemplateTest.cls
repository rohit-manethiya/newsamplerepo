@IsTest
private with sharing class ImportAutomationTemplateTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    private static void importTemplateAndReturnDeploymentId() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);
            String namespace = ImportAutomationTemplateTest.class
                .getName()
                .substringBefore('ImportAutomationTemplateTest')
                .removeEnd('.')
                .toLowerCase();
            namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;
            String fileContent =
                '{"attributes":{"type":"' +
                namespace +
                'Deployment__c","url":"/services/data/v50.0/sobjects/' +
                namespace +
                'Deployment__c/a0Q5p00000NF42DEAT"},"Name":"Automation 1","' +
                namespace +
                'Active__c":true,"Id":"a0Q5p00000NF42DEAT","' +
                namespace +
                'Steps__r":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"' +
                namespace +
                'Step__c","url":"/services/data/v50.0/sobjects/' +
                namespace +
                'Step__c/a1K5p00000Buk0dEAB"},"' +
                namespace +
                'Deployment__c":"a0Q5p00000NF42DEAT","Id":"a1K5p00000Buk0dEAB","Name":"Apex","' +
                namespace +
                'Read_Only__c":false,"' +
                namespace +
                'Notify_Task_Owner__c":"None","' +
                namespace +
                'Manual_Task_Notified__c":false,"' +
                namespace +
                'SUM_Deployed__c":0,"' +
                namespace +
                'Org_Count__c":0,"' +
                namespace +
                'Count_Completed__c":0,"' +
                namespace +
                'Type__c":"Apex","' +
                namespace +
                'Status__c":"Not started","' +
                namespace +
                'Run_all_tests__c":false,"' +
                namespace +
                'Order__c":1,"' +
                namespace +
                'Deployed__c":0,"' +
                namespace +
                'Completed__c":0,"' +
                namespace +
                'CheckOnly__c":false},{"attributes":{"type":"' +
                namespace +
                'Step__c","url":"/services/data/v50.0/sobjects/' +
                namespace +
                'Step__c/a0x1n00000580oYAAQ"},"' +
                namespace +
                'Deployment__c":"a0E1n00000Hfxk3EAB","Id":"a0x1n00000580oYAAQ","Name":"Automation","' +
                namespace +
                'Read_Only__c":false,"' +
                namespace +
                'Notify_Task_Owner__c":"None","' +
                namespace +
                'Manual_Task_Notified__c":false,"' +
                namespace +
                'SUM_Deployed__c":0,"' +
                namespace +
                'Org_Count__c":0,"' +
                namespace +
                'Count_Completed__c":0,"' +
                namespace +
                'Type__c":"Automation Template","' +
                namespace +
                'Status__c":"Not started","' +
                namespace +
                'Run_all_tests__c":false,"' +
                namespace +
                'Order__c":2,"' +
                namespace +
                'Deployed__c":0,"' +
                namespace +
                'Completed__c":0,"' +
                namespace +
                'CheckOnly__c":false}]}}';

            ContentVersion contentVersionRecord = new ContentVersion();
            contentVersionRecord.ContentLocation = 'S';
            contentVersionRecord.PathOnClient = 'test.json';
            contentVersionRecord.Title = 'Title';
            contentVersionRecord.VersionData = Blob.valueOf(fileContent);
            insert contentVersionRecord;

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRecord.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentRecordLink = new ContentDocumentLink();
            contentDocumentRecordLink.ContentDocumentId = contentDocumentId;
            contentDocumentRecordLink.LinkedEntityId = orgs[0].Id;
            contentDocumentRecordLink.shareType = 'V';
            insert contentDocumentRecordLink;

            Test.startTest();
            List<ImportAutomationTemplate.InvocableVariables> variables = new List<ImportAutomationTemplate.InvocableVariables>();
            ImportAutomationTemplate.InvocableVariables firstSet = new ImportAutomationTemplate.InvocableVariables();
            firstSet.contentDocumentIds = new List<String>{ contentDocumentId };
            variables.add(firstSet);
            List<String> expectedAutomations = ImportAutomationTemplate.execute(variables);
            System.assertEquals(1, expectedAutomations.size());
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c];
            System.assertEquals(1, deployments.size());
            List<Step__c> steps = [SELECT Id FROM Step__c WHERE Deployment__c = :deployments[0].Id];
            System.assertEquals(2, steps.size());
            Test.stopTest();
        }
    }
}