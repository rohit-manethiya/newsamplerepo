@IsTest
private with sharing class TestDeploymentStepsUtils {
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        final ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        final User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
            final ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
                .setFieldValue(Step__c.SObjectType, Step__c.DataJson__c, '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}')
                .setDataSize(Step__c.SObjectType, 1)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void testUpdateRecords() {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            final Deployment__c deployment = [SELECT Id FROM Deployment__c];

            Test.startTest();
            deployment.Name = 'Updated Deployment';
            DeploymentStepsUtils.updateRecords(new List<SObject>{deployment});
            Test.stopTest();

            System.assertEquals(
                'Updated Deployment',
                [SELECT Name FROM Deployment__c].Name,
                'Automation Template should have been successfully updated'
            );
        }
    }

    @IsTest
    static void testGetLastAttachmentBodyAsString() {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            final Step__c step = [SELECT Id FROM Step__c];

            final String attachmentBodyValue = 'System.debug(\'Write you awesome Apex code here!\');';

            insert new Attachment(Name = 'Apex', ParentId = step.Id, Body = Blob.valueOf(attachmentBodyValue));

            Test.startTest();
            final String attachmentBody = DeploymentStepsUtils.getLastAttachmentBodyAsString('Apex', step.Id);
            Test.stopTest();

            System.assertEquals(attachmentBodyValue, attachmentBody, 'Retrieved attachment body should match');
        }
    }

    @IsTest
    static void testUpsertAttachment() {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            final Step__c step = [SELECT Id FROM Step__c];

            final String attachmentBodyValue = 'System.debug(\'Write you awesome Apex code here!\');';

            insert new Attachment(Name = 'Apex', ParentId = step.Id, Body = Blob.valueOf(attachmentBodyValue));

            final String newAttachmentBodyValue = 'System.debug(\'Write you awful Apex code somewhere else!\');';

            Test.startTest();
            final String attachmentBody = DeploymentStepsUtils.upsertAttachment('Apex', step.Id, newAttachmentBodyValue);
            Test.stopTest();

            System.assertEquals(newAttachmentBodyValue, attachmentBody, 'Upserted attachment body should match');

            final Attachment stepAttachment = DeploymentStepsUtils.getLastChildAttachmentByName('Apex', step.Id);
            System.assertEquals(
                newAttachmentBodyValue,
                stepAttachment.Body.toString(),
                'Retrieved attachment body should match'
            );
        }
    }

    /**
     * Since FlowDefinitionView type is not creatable (Error: DML operation Insert not allowed on FlowDefinitionView),
     * we perforn a real query to the Org (this metadata is accessible from test context) and compare the results
     */
    @IsTest
    static void testGetFlowsAvailableForExecution() {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            Test.startTest();
            final String flowsResult = DeploymentStepsUtils.getFlowsAvailableForExecution();
            Test.stopTest();

            final List<DeploymentStepsUtils.FlowOptionWrapper> flowOptionWrappersAvailableForExecution = new List<DeploymentStepsUtils.FlowOptionWrapper>();
            for (FlowDefinitionView flowAvailableForExecution : [
                SELECT ApiName, Label, NamespacePrefix
                FROM FlowDefinitionView
                WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = true AND IsTemplate = false AND TriggerType = null
            ]) {
                final String namespace = flowAvailableForExecution.NamespacePrefix != null ? flowAvailableForExecution.NamespacePrefix + '.' : '';
                flowOptionWrappersAvailableForExecution.add(
                    new DeploymentStepsUtils.FlowOptionWrapper(
                        namespace + flowAvailableForExecution.ApiName,
                        namespace + flowAvailableForExecution.Label
                    )
                );
            }
            System.assertEquals(JSON.serialize(flowOptionWrappersAvailableForExecution), flowsResult, 'Results should match.');
        }
    }
}