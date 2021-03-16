/**
* This class will test following scenarios
* Onload no pipeline is specified in custom setting
* Onload standard autoselected assert
* Change template and assert
* */
@IsTest
private with sharing class Test_PipelineTemplatesController {

    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Pipeline Template',
                'Email' => 'test@pipeline-templates123.com',
                'Username' => 'test@pipeline-templates123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Templates',
                'Title' => 'pt-title',
                'Alias' => 'pt-alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Pipeline Template Jr',
                'Email' => 'test@pipeline-templates-noaccess123.com',
                'Username' => 'test@pipeline-templates-noaccess123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Templates',
                'Title' => 'pt-title2',
                'Alias' => 'pt-alia2',
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
    * When user does not have license show error page
    */
    @IsTest static void testPipelineTemplatesOnLoadNoPipeline() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false); //assigning enterprise license

        System.runAs(testUser) {
            Test.startTest();

            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();

            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains('Pipeline'));
        }

    }

    /**
    * This method asserts if pipeline in setup setting is deleted page will show and error to user
    */
    @IsTest static void testDeletedPipeline() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            delete testPipeline;
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains(Label.Pipeline_Pipeline_Needed_To_Continue));
            Test.stopTest();
        }
    }

    /**
    * This method asserts STANDARD is the default template on page load
    * and asserts that template change updates selectionJSON
    */
    @IsTest static void testPipelineTemplateChange() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertEquals('STANDARD', controller.currentType);

            controller.currentType = 'ADVANCED';
            controller.processSelectedTemplateType();

            System.assertEquals(controller.selectionsJSON, controller.advanceJson);

            controller.currentType = 'STANDARD';
            controller.processSelectedTemplateType();

            System.assertEquals(controller.selectionsJSON, controller.standardJson);

            controller.currentType = 'BASIC';
            controller.processSelectedTemplateType();

            System.assertEquals(controller.selectionsJSON, controller.basicJson);
            
            controller.currentType = 'NONEXISTING-TYPE';
            controller.processSelectedTemplateType();

            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains(Label.Pipeline_Unexpected_Template_Type));
            Test.stopTest();
        }
    }

    /**
   * This method asserts that selecting a template create relevant pipeline steps to
   * the pipeline
   */
    @IsTest static void testPipelineTemplatesSelectBasicTemplate() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertEquals('STANDARD', controller.currentType);

            controller.currentType = 'BASIC';
            controller.processSelectedTemplateType();
            controller.selectTemplate();

            List<Deployment_Flow_Step__c> flowSteps = [SELECT Id, Branch__c, Destination_Branch__c FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :usersSetup.Pipeline_Id__c ORDER BY Branch__c];

            System.assertEquals('dev1', flowSteps[0].Branch__c);
            System.assertEquals('staging', flowSteps[0].Destination_Branch__c);

            System.assertEquals('dev2', flowSteps[1].Branch__c);
            System.assertEquals('staging', flowSteps[1].Destination_Branch__c);

            System.assertEquals('staging', flowSteps[2].Branch__c);
            System.assertEquals('master', flowSteps[2].Destination_Branch__c);

            System.assertEquals(3, flowSteps.size());
            Test.stopTest();
        }
    }

    /**
   * This method asserts that selecting a template create relevant pipeline steps to
   * the pipeline
   */
    @IsTest static void testPipelineTemplatesSelectStandardTemplate() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertEquals('STANDARD', controller.currentType);
            controller.selectTemplate();

            List<Deployment_Flow_Step__c> flowSteps = [SELECT Id, Branch__c, Destination_Branch__c FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :usersSetup.Pipeline_Id__c ORDER BY Branch__c];

            System.assertEquals('dev1', flowSteps[0].Branch__c);
            System.assertEquals('integration', flowSteps[0].Destination_Branch__c);

            System.assertEquals('dev2', flowSteps[1].Branch__c);
            System.assertEquals('integration', flowSteps[1].Destination_Branch__c);

            System.assertEquals('integration', flowSteps[2].Branch__c);
            System.assertEquals('staging', flowSteps[2].Destination_Branch__c);

            System.assertEquals('staging', flowSteps[3].Branch__c);
            System.assertEquals('master', flowSteps[3].Destination_Branch__c);

            System.assertEquals(4, flowSteps.size());
            Test.stopTest();
        }
    }

    /**
   * This method asserts that selecting a template create relevant pipeline steps to
   * the pipeline
   */
    @IsTest static void testPipelineTemplatesSelectAdvanceTemplate() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertEquals('STANDARD', controller.currentType);

            controller.currentType = 'ADVANCED';
            controller.processSelectedTemplateType();
            controller.selectTemplate();

            List<Deployment_Flow_Step__c> flowSteps = [SELECT Id, Branch__c, Destination_Branch__c FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :usersSetup.Pipeline_Id__c ORDER BY Branch__c];

            System.assertEquals('dev1', flowSteps[0].Branch__c);
            System.assertEquals('integration', flowSteps[0].Destination_Branch__c);

            System.assertEquals('dev2', flowSteps[1].Branch__c);
            System.assertEquals('integration', flowSteps[1].Destination_Branch__c);

            System.assertEquals('integration', flowSteps[2].Branch__c);
            System.assertEquals('qa', flowSteps[2].Destination_Branch__c);

            System.assertEquals('qa', flowSteps[3].Branch__c);
            System.assertEquals('staging', flowSteps[3].Destination_Branch__c);

            System.assertEquals('staging', flowSteps[4].Branch__c);
            System.assertEquals('master', flowSteps[4].Destination_Branch__c);

            System.assertEquals(5, flowSteps.size());
            Test.stopTest();
        }
    }

    /**
   * This method asserts that skipping template creation opens next component and
   * asserts that only connection to master branch pipeline step is created
   */
    @IsTest static void testPipelineTemplatesSkipTemplates() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-templates123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With No Repo 123',
                'Main_Branch__c' => 'master',
                'Git_Repository__c' => null,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With No Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineTemplatesWizard;
            Test.setCurrentPage(pReference);

            PipelineTemplateComponentController controller = new PipelineTemplateComponentController();
            System.assertEquals('STANDARD', controller.currentType);

            controller.skipTemplates();

            List<Deployment_Flow_Step__c> flowSteps = [SELECT Id, Destination_Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :usersSetup.Pipeline_Id__c];

            System.assertEquals(1, flowSteps.size());
            System.assertEquals('master', flowSteps[0].Destination_Branch__c);
            Test.stopTest();
        }

    }

}