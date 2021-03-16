@IsTest
public with sharing class Test_SetupWizardStartController {

    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {
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

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches',2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the page first time without any org credential or licenses and click on start button.
     */
    @IsTest static void clickPipelineManagerFirstTime() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SetupWizardStart);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, false);
            System.assertEquals(controller.userHasLicense, false);

            PageReference pRef = controller.checkLastStepForWizard();
            System.assertEquals(pRef, null);

            controller.startWizard();
            Test.stopTest();
        }
    }

    /**
     * Open the page first time with org credential is created and no licenses assigned to the user.
     */
    @IsTest static void clickPipelineManagerFirstTimeWithOrg() {
        User u = [SELECT Id,Name,LastName,Email,Username,Alias FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);

        System.runAs(u) {

            // Create org credential for current user
            tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => UserInfo.getOrganizationName().left(80),
                'Org_Type__c' => 'Production/Developer',
                'Username__c' => u.Username
            });

            Test.startTest();
            Test.setCurrentPage(Page.SetupWizardStart);
            String response = '{"organizationId":"' + tu.item('Org__c',0).Id + '","OrganizationName":"' + UserInfo.getOrganizationName().left(80) + '","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"' + u.Username + '","UserId":"' + u.Id + '","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"' + u.Email + '","UserFullName":"' + u.Name + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, true);
            System.assertEquals(controller.userHasLicense, false);

            PageReference pRef = controller.checkLastStepForWizard();
            System.assertEquals(pRef, null);

            controller.startWizard();
            Test.stopTest();
        }
    }

    /**
     * Open the page second time by checking the existing custom setting value for current user.
     */
    @IsTest static void redirectOnLoadWithExistingCustomSetting() {
        User u = [SELECT Id,Name,LastName,Email,Username,Alias FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);

        System.runAs(u) {

            // Create custom settings
            tu.insertSObject('Setup_Wizard_Steps__c', new Map<String, Object>{
                'SetupOwnerId' => u.Id,
                'Pipeline_Id__c' => 'null',
                'Wizard_Last_Action__c' => 'null',
                'Org_Credential_Id__c' => null,
                'Last_Step__c' => 'CopadoLicensesWizard',
                'Git_Snapshot_Id__c' => null,
                'Git_Repository_Id__c' => null,
                'Diagram_Last_Action__c' => null
            });

            // Create org credential for current user
            tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => UserInfo.getOrganizationName().left(80),
                'Org_Type__c' => 'Production/Developer',
                'Username__c' => u.Username
            });

            Test.startTest();
            Test.setCurrentPage(Page.SetupWizardStart);
            String response = '{"organizationId":"' + tu.item('Org__c',0).Id + '","OrganizationName":"' + UserInfo.getOrganizationName().left(80) + '","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"' + u.Username + '","UserId":"' + u.Id + '","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"' + u.Email + '","UserFullName":"' + u.Name + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, true);
            System.assertEquals(controller.userHasLicense, false);

            PageReference nextPage = Page.CopadoLicensesWizard;
            String nextPageURL = nextPage.getUrl();
            PageReference pRef = controller.checkLastStepForWizard();
            String pRefURL = pRef.getUrl().toLowerCase();
            Boolean sameURL = pRefURL.contains(nextPageURL);
            System.assertEquals(sameURL, true);

            controller.startWizard();
            Test.stopTest();
        }
    }

    /**
     * Click on manager button while user have org credential but no licences assigned.
     */
    @IsTest static void clickManagerButtonReturnNull() {
        User u = [SELECT Id,Name,LastName,Email,Username,Alias FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);

        System.runAs(u) {

            // Create org credential for current user
            tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => UserInfo.getOrganizationName().left(80),
                'Org_Type__c' => 'Production/Developer',
                'Username__c' => u.Username
            });

            Test.startTest();
            Test.setCurrentPage(Page.SetupWizardStart);
            String response = '{"organizationId":"' + tu.item('Org__c',0).Id + '","OrganizationName":"' + UserInfo.getOrganizationName().left(80) + '","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"' + u.Username + '","UserId":"' + u.Id + '","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"' + u.Email + '","UserFullName":"' + u.Name + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, true);
            System.assertEquals(controller.userHasLicense, false);

            PageReference pRef = controller.checkLastStepForWizard();
            System.assertEquals(pRef, null);

            PageReference pageManagerRef = controller.goToManager();
            System.assertEquals(pageManagerRef, null);

            Test.stopTest();
        }
    }

    /**
     * Click on manager button while user have org credential and licenses assigned but there is no deployment flow record.
     */
    @IsTest static void clickManagerButtonCatch() {
        User u = [SELECT Id,Name,LastName,Email,Username,Alias FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {

            // Create org credential for current user
            tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => UserInfo.getOrganizationName().left(80),
                'Org_Type__c' => 'Production/Developer',
                'Username__c' => u.Username
            });

            Test.startTest();
            Test.setCurrentPage(Page.SetupWizardStart);
            String response = '{"organizationId":"' + tu.item('Org__c',0).Id + '","OrganizationName":"' + UserInfo.getOrganizationName().left(80) + '","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"' + u.Username + '","UserId":"' + u.Id + '","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"' + u.Email + '","UserFullName":"' + u.Name + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, true);
            System.assertEquals(controller.userHasLicense, true);

            PageReference pRef = controller.checkLastStepForWizard();
            System.assertEquals(pRef, null);

            PageReference pageManagerRef = controller.goToManager();
            System.assertEquals(pageManagerRef, null);

            Test.stopTest();
        }
    }

    /**
     * Click on manager button while user have org credential and licenses assigned but there is no deployment flow record.
     */
    @IsTest static void clickManagerButtonSuccess() {
        User u = [SELECT Id,Name,LastName,Email,Username,Alias FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {

            // Create org credential for current user
            tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => UserInfo.getOrganizationName().left(80),
                'Org_Type__c' => 'Production/Developer',
                'Username__c' => u.Username
            });

            // Create git repository
            tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'URI__c' => 'git@bitbucket.org:fozsavran/fopipeline.git'
            });

            // Create deployment flow
            tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'test',
                'Active__c' => true,
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c',0).Id
            });

            Test.startTest();

            Deployment_Flow__c depFlow = [SELECT Id FROM Deployment_Flow__c LIMIT 1 FOR VIEW];

            Test.setCurrentPage(Page.SetupWizardStart);
            String response = '{"organizationId":"' + tu.item('Org__c',0).Id + '","OrganizationName":"' + UserInfo.getOrganizationName().left(80) + '","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"' + u.Username + '","UserId":"' + u.Id + '","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"' + u.Email + '","UserFullName":"' + u.Name + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            SetupWizardStartController controller = new SetupWizardStartController();
            System.assertEquals(controller.userHasCopadoCredential, true);
            System.assertEquals(controller.userHasLicense, true);

            PageReference pRef = controller.checkLastStepForWizard();
            System.assertEquals(pRef, null);

            PageReference nextPage = Page.PipelineManager;
            String nextPageURL = nextPage.getUrl();
            PageReference pManagerRef = controller.goToManager();
            String pRefURL = pManagerRef.getUrl().toLowerCase();
            Boolean sameURL = pRefURL.contains(nextPageURL);
            System.assertEquals(sameURL, true);

            Test.stopTest();
        }
    }
}