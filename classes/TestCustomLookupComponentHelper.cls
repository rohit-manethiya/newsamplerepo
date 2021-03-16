@IsTest
private with sharing class TestCustomLookupComponentHelper {
    private static final String DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME = 'Automation_Template';
    private static final String STANDARD_USER = 'test_user@myorg.com';

    private static Map<String, Schema.RecordTypeInfo> recordTypeInfoByDeveloperName = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();

    @TestSetup
    static void makeData() {
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
                    recordTypeInfoByDeveloperName.get(DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME).getRecordTypeId()
                )
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void testFindRecordsWithoutExtraFilter() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = new CustomLookupQueryConfiguration();
            queryConfig.searchField = 'Name';
            queryConfig.objectName = 'Deployment__c';
            queryConfig.searchKey = 'Deploy';
            List<SObject> records = CustomLookupComponentHelper.findRecords(queryConfig);

            List<Deployment__c> expectedResult = [SELECT Name FROM Deployment__c WHERE Name LIKE '%Deploy%' WITH SECURITY_ENFORCED LIMIT 10];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expectedResult size (1 record)');
        }
    }

    @IsTest
    static void testFindRecordsWithExtraFilters() {
        System.runAs(getStandardUser()) {
            Deployment__c deployment = [SELECT Id FROM Deployment__c];
            CustomLookupQueryConfiguration queryConfig = new CustomLookupQueryConfiguration();
            queryConfig.searchField = 'Name';
            queryConfig.objectName = 'Deployment__c';
            queryConfig.searchKey = 'Deploy';
            queryConfig.extraFilterType = 'AutomationTemplateFilter';
            queryConfig.filterFormattingParameters = new List<Object>{ deployment.Id };
            List<SObject> records = CustomLookupComponentHelper.findRecords(queryConfig);

            List<Deployment__c> expectedResult = [
                SELECT Name
                FROM Deployment__c
                WHERE Name LIKE '%Deploy%' AND RecordType.DeveloperName = 'Automation_Template' AND Active__c = TRUE AND Id != :deployment.Id
                WITH SECURITY_ENFORCED
                LIMIT 10
            ];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expecteResult size (empty with 0 records)');
        }
    }

    @IsTest
    static void testFindRecordsWithInvalidExtraFilters() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = new CustomLookupQueryConfiguration();
            queryConfig.searchField = 'Name';
            queryConfig.objectName = 'Deployment__c';
            queryConfig.searchKey = 'Deploy';
            queryConfig.extraFilterType = 'NotAutomationTemplateFilter';
            List<SObject> records = CustomLookupComponentHelper.findRecords(queryConfig);

            List<Deployment__c> expectedResult = [SELECT Name FROM Deployment__c WHERE Name LIKE '%Deploy%' WITH SECURITY_ENFORCED LIMIT 10];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expectedResult size (1 record)');
        }
    }

    private static User getStandardUser() {
        return [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
    }
}