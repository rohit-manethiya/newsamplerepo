@IsTest
public with sharing class Test_NewPipelineExtension {

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

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'LastName',
                'Email' => 'test2@test2.com',
                'Username' => 'puser002@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title2',
                'Alias' => 'alias2',
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
     * @description when you click on "new pipeline" and there's no new pipeline in progress (no custom setting "Setup_Wizard_Steps__c" with current user created) user have to be redirected to PipelineWizard first step
     */
    @IsTest
    static void newPipeline() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, false, false, false, false);

        System.runAs(u) {
            Test.startTest();
            PageReference assertPipeline = Page.SetupWizardStart;
            assertPipeline.getParameters().put('newPipeline', 'true');

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);
            Deployment_Flow__c dpf =  new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
            NewPipelineExtension newpipelineController = new NewPipelineExtension(sc);
            PageReference returnPageref = newpipelineController.setupDecisioner();
            System.assertEquals(returnPageref.getUrl(), assertPipeline.getUrl());

            Test.stopTest();
        }
    }

    /**
    * @description when you click on "new pipeline" and there's a pipeline in progress (custom setting "Setup_Wizard_Steps__c" with current user created) user have to stay in NewPipeline.page to click on "Continue" to keep with pipeline in progress.
    */
    @IsTest
    static void inProgressPipeline() {

        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, false, false, false, false);

        System.runAs(u){
            Test.startTest();

            // Create deployment flow
            tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'test',
                    'Active__c' => false,
                    'Main_Branch__c' => 'master',
                    'Calculate_Based_on__c' => 'User Story'
            });
            // Create custom settings
            tu.insertSObject('Setup_Wizard_Steps__c', new Map<String, Object>{
                    'SetupOwnerId' => u.Id,
                    'Pipeline_Id__c' => tu.item('Deployment_Flow__c',0).Id,
                    'Wizard_Last_Action__c' => 'null',
                    'Org_Credential_Id__c' => null,
                    'Last_Step__c' => null,
                    'Git_Snapshot_Id__c' => null,
                    'Git_Repository_Id__c' => null,
                    'Diagram_Last_Action__c' => null
            });
            Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(u.Id);

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);
            Deployment_Flow__c dpf =  new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
            NewPipelineExtension newpipelineController = new NewPipelineExtension(sc);
            PageReference returnPageref = newpipelineController.setupDecisioner();
            System.assertEquals(returnPageref, null);
            newpipelineController.startNew();

            Test.stopTest();
        }
    }

    /**
    * @description when you click on "new pipeline" and the pipeline that was in progress (custom setting "Setup_Wizard_Steps__c" with current user created) was deleted go back to start
    */
    @IsTest
    static void deletedPipeline() {

        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, false, false, false, false);

        System.runAs(u){
            Test.startTest();

            // Create deployment flow
            tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'test',
                    'Active__c' => false,
                    'Main_Branch__c' => 'master',
                    'Calculate_Based_on__c' => 'User Story'
            });
            // Create custom settings
            tu.insertSObject('Setup_Wizard_Steps__c', new Map<String, Object>{
                    'SetupOwnerId' => u.Id,
                    'Pipeline_Id__c' => tu.item('Deployment_Flow__c',0).Id,
                    'Wizard_Last_Action__c' => 'null',
                    'Org_Credential_Id__c' => null,
                    'Last_Step__c' => null,
                    'Git_Snapshot_Id__c' => null,
                    'Git_Repository_Id__c' => null,
                    'Diagram_Last_Action__c' => null
            });
            Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(u.Id);
            delete tu.item('Deployment_Flow__c',0);
            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);
            Deployment_Flow__c dpf =  new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
            NewPipelineExtension newpipelineController = new NewPipelineExtension(sc);
            PageReference returnPageref = newpipelineController.setupDecisioner();
            setupWizardSettings = Setup_Wizard_Steps__c.getInstance(u.Id);
            System.assertEquals(returnPageref, null);
            System.assertEquals(setupWizardSettings.Pipeline_Id__c, null);

            Test.stopTest();
        }
    }

    /**
     * @description Test OLSFLS security message
     */
    @IsTest
    static void noAccessPipeline() {

        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);
        // Create deployment flow
        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'test',
                'Active__c' => false,
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story'
        });
        System.runAs(u){
            Test.startTest();


            // Create custom settings
            tu.insertSObject('Setup_Wizard_Steps__c', new Map<String, Object>{
                    'SetupOwnerId' => u.Id,
                    'Pipeline_Id__c' => tu.item('Deployment_Flow__c',0).Id,
                    'Wizard_Last_Action__c' => 'null',
                    'Org_Credential_Id__c' => null,
                    'Last_Step__c' => null,
                    'Git_Snapshot_Id__c' => null,
                    'Git_Repository_Id__c' => null,
                    'Diagram_Last_Action__c' => null
            });
            Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(u.Id);

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);
            Deployment_Flow__c dpf =  new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
            NewPipelineExtension newpipelineController = new NewPipelineExtension(sc);
            PageReference returnPageref = newpipelineController.setupDecisioner();

            System.assertEquals(ApexPages.getMessages().size(), 2);
            for(ApexPages.Message msg : ApexPages.getMessages()) {
                System.debug('for msg' + msg.getDetail());
                System.assert((msg.getDetail() == Label.Insufficient_Access_Rights || msg.getDetail() ==  Label.Related_Object + ' '+ Schema.SObjectType.Deployment_Flow__c.getLabel()));
            }

            Test.stopTest();
        }
    }
}