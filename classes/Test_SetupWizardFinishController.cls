/**
* This class will test below scenarios for last step of the setup wizard
* Enjoy copado button clicked with existing pipeline
* Enjoy copado button clicked with no existing pipeline
* Permission error
* No custom setting defined
* */
@IsTest
private with sharing class Test_SetupWizardFinishController {

    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'SetupWizardFinish',
                'Email' => 'test@setup-wizard-finish123.com',
                'Username' => 'test@setup-wizard-finish123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Wizard',
                'Title' => 'swtitle',
                'Alias' => 'swalias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'SetupWizardFinish Jr',
                'Email' => 'test@setup-wizard-finish-noaccess123.com',
                'Username' => 'test@setup-wizard-finish-noaccess123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Wizard',
                'Title' => 'swtitln',
                'Alias' => 'swalian',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    /**
   * This method asserts Enjoy Copado clicked with existing Custom Setting that has Pipeline Id populated for Enterprise User
   */
    @IsTest static void testSetupWizardFinishWithCustomSettingPipeline() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@setup-wizard-finish123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.SetupWizardFinish;
            Test.setCurrentPage(pReference);

            SetupWizardFinishController controller = new SetupWizardFinishController();
            controller.enjoyCopado();

            usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
            System.assertEquals(null, usersSetup.Pipeline_Id__c);  //we are asserting this because getInstance returns empty user setup after delete
            System.assertEquals(null, usersSetup.Id);  //we are asserting this because getInstance returns empty user setup after delete
        }
    }

    /**
  * This method asserts Enjoy Copado clicked with no Pipeline Id in Custom Setting but that has Pipeline Id populated in the url
  */
    @IsTest static void testSetupWizardFinishWithPipelineAsParameter() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@setup-wizard-finish123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.SetupWizardFinish;
            pReference.getParameters().put('pipelineId', testPipeline.Id);
            Test.setCurrentPage(pReference);

            SetupWizardFinishController controller = new SetupWizardFinishController();
            controller.enjoyCopado();

            usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
            System.assertEquals(null, usersSetup.Pipeline_Id__c);  //we are asserting this because getInstance returns empty user setup after delete
            System.assertEquals(null, usersSetup.Id);  //we are asserting this because getInstance returns empty user setup after delete
        }
    }

    /**
      * This method asserts Enjoy Copado clicked with no Pipeline Id in Custom Setting and no Pipeline Id populated in the url
      * and no pipeline exists in the system this method asserts user is redirected to home page
      */
    @IsTest static void testSetupWizardFinishWithNoExistingPipeline() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@setup-wizard-finish123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.SetupWizardFinish;
            Test.setCurrentPage(pReference);

            SetupWizardFinishController controller = new SetupWizardFinishController();
            PageReference testResult = controller.enjoyCopado();

            System.debug(testResult.getUrl());
            System.assert(testResult.getUrl().contains('home/home.jsp') || testResult.getUrl().contains('one/one.app'));
        }
    }

    /**
     * This method asserts Enjoy Copado clicked with no Pipeline Id in Custom Setting and no Pipeline Id populated in the url
     * and pipeline exists in the system this method asserts user is redirected to an existing pipeline
     */
    @IsTest static void testSetupWizardFinishWithExistingPipeline() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@setup-wizard-finish123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.SetupWizardFinish;
            Test.setCurrentPage(pReference);

            SetupWizardFinishController controller = new SetupWizardFinishController();
            PageReference testResult = controller.enjoyCopado();
            System.debug(testResult.getUrl());
            System.assert(testResult.getUrl().containsIgnoreCase('PipelineManager?Id=' + testPipeline.Id));
        }
    }

    /**
    * This method tests Enjoy Copado clicked with no access to Deployment Flow object and asserts correct error message is thrown
    */
    @IsTest static void testSetupWizardFinishWithPermissionError() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@setup-wizard-finish-noaccess123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), false, false, false, false, false);

        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(testUser.Id);
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.SetupWizardFinish;
            Test.setCurrentPage(pReference);

            SetupWizardFinishController controller = new SetupWizardFinishController();
            controller.enjoyCopado();

            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains(Label.Insufficient_Access_Rights));

        }
    }
}