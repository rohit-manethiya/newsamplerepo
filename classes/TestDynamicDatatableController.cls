@IsTest
private with sharing class TestDynamicDatatableController {
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    static void makeData() {
        Map<String, RecordTypeInfo> deploymentRecordTypes = SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    Deployment__c.SObjectType,
                    Deployment__c.RecordTypeId,
                    deploymentRecordTypes.get('Automation_Template').getRecordTypeId()
                )
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
                .setFieldValue(Step__c.SObjectType, Step__c.DataJson__c, '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}')
                .setDataSize(Step__c.SObjectType, 10)
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
    static void testGetTableInfo() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            Deployment__c deployment = [SELECT Id FROM Deployment__c];

            String namespace = Settings.ns;
            String pageType = 'RecordPage';
            String objectName = namespace + 'Deployment__c';
            String childObjectLabel = 'Step';
            String desiredFieldSet = 'Deployment_Steps';

            Test.startTest();
            Map<String, String> availableChildObjects = new Map<String, String>();
            RelatedListVisualPicklist picklistHandler = new RelatedListVisualPicklist(pageType, objectName);
            System.assertEquals(null, picklistHandler.getDefaultValue(), 'There should not be a default value');
            VisualEditor.DynamicPickListRows relatedObjects = picklistHandler.getValues();
            List<VisualEditor.DataRow> rows = relatedObjects.getDataRows();
            for (VisualEditor.DataRow row : rows) {
                availableChildObjects.put(row.getLabel(), String.valueOf(row.getValue()));
            }
            System.assertEquals(
                namespace + 'Step__c',
                availableChildObjects.get(childObjectLabel),
                'Step__c should be available'
            );

            List<ColumnConfig> columnsConfig = DynamicDatatableController.fetchColumnsConfig(availableChildObjects.get(childObjectLabel), desiredFieldSet, true);
            System.assertEquals(2, columnsConfig.size(), 'columnsConfig size should match the number of fields in the field set');

            DynamicDatatableQueryConfiguration queryConfig = new DynamicDatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = availableChildObjects.get(childObjectLabel);
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            List<SObject> data = DynamicDatatableController.fetchData(queryConfig);
            System.assertEquals(10, data.size(), 'There should be 10 step records related to the deployment');

            // If relationshipField is not provided, it tries to find the default
            queryConfig.relationshipField = null;
            data = DynamicDatatableController.fetchData(queryConfig);
            System.assertEquals(10, data.size(), 'There should be 10 step records related to the deployment');

            try {
                queryConfig.fromObject = childObjectLabel;
                DynamicDatatableController.fetchData(queryConfig);
                System.assert(false, 'fetchData should have thrown an exception due to invalid object api name');
            } catch (Exception e) {
                // Skip silently
                System.debug(e);
            }
            Test.stopTest();
        }
    }
}