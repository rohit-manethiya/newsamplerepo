@IsTest
public with sharing class TestUserStoryApexTestResultsExtension {

    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    @IsTest static void missingSourceOrg() {
        TestUtilities tu = new TestUtilities();

        // Create user record
        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        // Create project record
        tu.insertSObject('Project__c', new Map<String, Object>{
                'Name' => 'My project'
        });

        // Create 28 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 28, new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id
        });

        System.runAs((User) tu.item('User', 0)) {
            Test.startTest();
            Test.setCurrentPage(Page.UserStoryApexTestResults);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));
            UserStoryApexTestResultsExtension controller = new UserStoryApexTestResultsExtension(sc);

            System.assert(testMethodUtilities.hasMessage('This user story does not have a source org. Please add a Source Org to the User Story and try again.'));
            Test.stopTest();
        }
    }

    @IsTest static void invalidOrgAndNoAttachment() {
        TestUtilities tu = new TestUtilities();

        // Create user record
        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        // Create environments record
        tu.insertSObject('Environment__c', new Map<String, Object>{
                'Name' => 'MyProdOrg',
                'org_id__c' => 'SFDC_OrgId'
        });

        // Create org credentials record
        tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => 'MyOrg1',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => 'SFDC_OrgId',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 0).Id
        });

        // Create project record
        tu.insertSObject('Project__c', new Map<String, Object>{
                'Name' => 'My project'
        });

        // Create 28 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 28, new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id,
                'Org_Credential__c' => tu.item('Org__c', 0).Id
        });

        System.runAs((User) tu.item('User', 0)) {
            Test.startTest();
            Test.setCurrentPage(Page.UserStoryApexTestResults);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));
            UserStoryApexTestResultsExtension controller = new UserStoryApexTestResultsExtension(sc);

            System.assert(testMethodUtilities.hasMessage('The selected org is not validated.'));
            Test.stopTest();
        }
    }

    @IsTest static void orgWithAttachment() {
        TestUtilities tu = new TestUtilities();

        // Create user record
        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        // Create environments record
        tu.insertSObject('Environment__c', new Map<String, Object>{
                'Name' => 'MyProdOrg',
                'org_id__c' => 'SFDC_OrgId'
        });

        // Create org credentials record
        tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => 'MyOrg1',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => 'SFDC_OrgId',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 0).Id
        });

        // Create apex test result object record
        tu.insertSObject('Apex_Test_Result__c', new Map<String, Object>{
                'Org__c' => tu.item('Org__c', 0).Id
        });

        // Create attachment object record
        tu.insertSObject('Attachment', new Map<String, Object>{
                'ParentId' => tu.item('Apex_Test_Result__c', 0).Id,
                'Name' => 'ApexTestResult',
                'Body' => Blob.valueOf('{"failures":0,"coverageWarning":"Average test coverage across all Apex Classes and Triggers is 69%, at least 75% test coverage is required.","time":333,"errors":true,"testClassResults":{"classCoverageResults":{"methods":[{"message":"","name":"test_after_insert_Errors","success":true},{"message":"TEST FAILED","name":"test_after_insert_OKs","success":false}]},"copado__UserStoryTrigger":{"methods":[{"message":"","name":"testBackup_errors_CustomerOrgMissing","success":true},{"message":"","name":"testBackup_success","success":true}]}},"tests":88,"details":"For details visit the Apex Test Results page from Salesforce setup.","classCoverageResults":{"copado__ApexResultsObject":{"coverage":0},"copado__UserStoryTrigger":{"coverage":100}}}')
        });

        // Create project record
        tu.insertSObject('Project__c', new Map<String, Object>{
                'Name' => 'My project'
        });

        // Create 28 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 28, new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id,
                'Org_Credential__c' => tu.item('Org__c', 0).Id
        });

        System.runAs((User) tu.item('User', 0)) {
            Test.startTest();
            Test.setCurrentPage(Page.UserStoryApexTestResults);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));
            UserStoryApexTestResultsExtension controller = new UserStoryApexTestResultsExtension(sc);

            System.assertEquals(true, controller.hasAttachment);
            controller.goToWaitingForPage();
            Test.stopTest();
        }
    }
}