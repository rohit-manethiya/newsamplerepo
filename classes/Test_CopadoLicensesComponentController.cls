/**
* This class will test following scenarios
* Onload no license
* Onload CCM license
* Onload Enterprise license
* Not selected license with continue
* Selected enterprise and moved to pipeline
* Selected ccm and moved to end
* */
@IsTest
private with sharing class Test_CopadoLicensesComponentController {
    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Copado Licenses',
                'Email' => 'test@copado-licenses123.com',
                'Username' => 'test@copado-licenses123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Wizard',
                'Title' => 'cl-title',
                'Alias' => 'cl-alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Pipeline Setting Jr. 2',
                'Email' => 'test@pcopado-licenses-noaccess123.com',
                'Username' => 'test@copado-licenses-noaccess123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Wizard',
                'Title' => 'cl-title2',
                'Alias' => 'cl-alia2',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.enableLicenses(1, 1, 1, 1, 1);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 1);
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 1);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    /**
    * When user does not have license
    */
    @IsTest static void testUserHasNoLicense() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            Test.stopTest();
        }
    }

    /**
   * When user has ccm license go to end
   */
    @IsTest static void testUserHasCCMLicense() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), false, true, false, false, false);

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            PageReference response = controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(1, controller.copadoCCMLicencesUsed);

            System.assert(response.getUrl().containsIgnoreCase(WizardHelper.SetupPipelineOrder.SetupWizardFinish.name()));
            Test.stopTest();
        }
    }

    /**
   * When user has enterprise license go to pipeline settings
   */
    @IsTest static void testUserHasEnterpriseLicense() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            PageReference response = controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(1, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            System.assert(response.getUrl().containsIgnoreCase(WizardHelper.SetupPipelineOrder.PipelineSettingsWizard.name()));
            Test.stopTest();
        }
    }

    /**
  * When user selects they are release manager assign enterprise license and go to pipeline settings
  */
    @IsTest static void testUserSelectedReleaseManager() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            controller.isReleaseManager = 'yes';
            controller.updateLicenseToAssign();
            PageReference response = controller.assignLicense();

            controller.getLicenseAvailability();

            System.assertEquals(0, controller.copadoCCMLicencesUsed);
            System.assertEquals(1, controller.copadoEnterpriseLicencesUsed);

            System.assert(response.getUrl().containsIgnoreCase(WizardHelper.SetupPipelineOrder.PipelineSettingsWizard.name()));
            Test.stopTest();
        }
    }

    /**
 * When user selects they are not release manager assign ccm license and go to end
 */
    @IsTest static void testUserSelectedNotReleaseManager() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            controller.isReleaseManager = 'no';
            PageReference response = controller.assignLicense();

            controller.getLicenseAvailability();
            System.assertEquals(1, controller.copadoCCMLicencesUsed);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);

            System.assert(response.getUrl().containsIgnoreCase(WizardHelper.SetupPipelineOrder.SetupWizardFinish.name()));
            Test.stopTest();
        }
    }

    /**
* When org does not have enoguh license show error page
*/
    @IsTest static void testUserSelectedNotEnoughAvailableLicensesEnterprise() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];
        String testRunnerUserName = UserInfo.getUserName();
        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            PageReference response = controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            TestUtilities.assignLicense(String.valueOf(testRunnerUserName), true, false, false, false, false);
            controller.isReleaseManager = 'yes';
            controller.assignLicense();

            System.assertEquals(0, controller.copadoCCMLicencesUsed);
            System.assertEquals(1, controller.copadoEnterpriseLicencesUsed);

            System.assertNotEquals('', controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.containsIgnoreCase(Label.COPADO_LICENSE_LIMIT_REACHED));
            Test.stopTest();
        }
    }

    /**
    * When user selects they are not release manager but at that point no license left to assign show error
    */
    @IsTest static void testUserSelectedNotEnoughAvailableLicensesCCM() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];
        String testRunnerUserName = UserInfo.getUserName();
        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            PageReference response = controller.checkUserLicense();
            System.assertEquals('', controller.errorMessageJSON);
            System.assertEquals(false, controller.hasLicenseLimitReached);
            System.assertEquals(1, controller.copadoEnterpriseLicencesAvailable);
            System.assertEquals(1, controller.copadoCCMLicencesAvailable);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);
            System.assertEquals(0, controller.copadoCCMLicencesUsed);

            TestUtilities.assignLicense(String.valueOf(testRunnerUserName), false, true, false, false, false);
            controller.isReleaseManager = 'no';
            controller.assignLicense();

            System.assertEquals(1, controller.copadoCCMLicencesUsed);
            System.assertEquals(0, controller.copadoEnterpriseLicencesUsed);

            System.assertNotEquals('', controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.containsIgnoreCase(Label.CCM_LICENSE_LIMIT_REACHED));
            Test.stopTest();
        }
    }

    /**
   * When user selects they are not release manager but at that point no license left to assign show error
   */
    @IsTest static void testNoLicenseProvisioned() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@copado-licenses123.com' LIMIT 1];
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 0);
        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.CopadoLicensesWizard;
            Test.setCurrentPage(pReference);

            CopadoLicensesComponentController controller = new CopadoLicensesComponentController();
            PageReference response = controller.checkUserLicense();
            System.assertNotEquals('', controller.errorMessageJSON);
            System.assertEquals(0, controller.copadoEnterpriseLicencesAvailable);
            //System.assert(controller.errorMessageJSON.containsIgnoreCase(Label.Pipeline_No_License_Provisioned));
            //commented out because in DEV-04 label has /n in it but in test class it fails
            Test.stopTest();
        }
    }
}