/**
* This class will test following scenarios
* 1. User has no license
* 2. User has no pipeline in custom setting and we will shows PipelineName as first step
* 3. User has pipeline with no git repository and we will show GitRepositorySelection as first step
* 4. User has pipeline and attached git repo that is not authenticated so we will show GitAuthenticationDetails as first step and we will do https auth
* 5. User has pipeline and attached git repo that is not authenticated so we will show GitAuthenticationDetails as first step and we will do ssh auth
* 6. User has pipeline and attached git repo that is authenticated so we will show GitBaseUrls as first step
* 7. Save & Close for first steps
* 8. Save & Close for last steps
* 9. Skip for urls step
* */
@IsTest
private with sharing class Test_PipelineSettingsComponentController {

    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Pipeline Setting Jr.',
                'Email' => 'test@pipeline-settings123.com',
                'Username' => 'test@pipeline-settings123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Settings',
                'Title' => 'ps-title',
                'Alias' => 'ps-alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                'LastName' => 'Pipeline Setting Jr. 2',
                'Email' => 'test@pipeline-settings-noaccess123.com',
                'Username' => 'test@pipeline-settings-noaccess123.com' + System.currentTimeMillis(),
                'CompanyName' => 'Pipeline Settings',
                'Title' => 'ps-title2',
                'Alias' => 'ps-alia2',
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
    @IsTest static void testUserHasNoLicense() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), false, false, false, false, false);

        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);

            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains('You need a license to continue'));
            System.assertEquals(null, controller.currentPipelineStepName);

            Test.stopTest();
        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is empty in the custom setting, show PipelineName as first step
    */
    @IsTest static void testPipelineSettingsStartWithNoPipeline() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false); //assigning enterprise license

        System.runAs(testUser) {
            Test.startTest();

            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);

            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName.name(), controller.currentPipelineStepName);

            Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
            usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
            System.assertNotEquals(null, usersSetup);
            System.assertEquals(null, usersSetup.Pipeline_Id__c);

            controller.newPipeline.Name = 'New Test Pipeline';
            controller.setStep();

            usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);
            System.assertNotEquals(null, usersSetup.Pipeline_Id__c);
            System.assertEquals('master', controller.newPipeline.Main_Branch__c);

            Test.stopTest();
        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is NOT empty in the custom setting but related Pipeline does not have
    * attached git repository, show GitRepositorySelection as first step also assert when git repo name and provider empty we get a message
    */
    @IsTest static void testPipelineSettingsStartWithNoGitRepository() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
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

            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);

            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);

            System.assertNotEquals(null, usersSetup);
            System.assertEquals(testPipeline.Id, usersSetup.Pipeline_Id__c);
            System.assertEquals(null, testPipeline.Git_Repository__c);

            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);
            System.assertEquals(2, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.Please_Enter));
            System.assert(ApexPages.getMessages()[1].getDetail().contains('Please select'));

            controller.gitRepository.Name = 'Test Git Repo 123';
            controller.updateAndGoToNext();
            System.Test.clearApexPageMessages(); //this is because page messages does not get cleared in controller for test methods

            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);
            System.assertEquals(1, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains('Please select'));

            controller.gitRepository.Git_Provider__c = 'Bitbucket';
            controller.updateAndGoToNext();

            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            Test.stopTest();
        }
    }

    /**
    * Go to git repository selection step and click on go back button 
    */
    @IsTest static void testPipelineSettingsStartWithNoGitRepositoryGoBack() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
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

            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);

            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);

            System.assertNotEquals(null, usersSetup);
            System.assertEquals(testPipeline.Id, usersSetup.Pipeline_Id__c);
            System.assertEquals(null, testPipeline.Git_Repository__c);

            controller.goToPreviousStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName.name(), controller.currentPipelineStepName);

            Test.stopTest();
        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is NOT empty in the custom setting AND related Pipeline have
    * attached git repository that is NOT authenticated, show GitAuthenticationDetails as first step and we will do https auth
    */
    @IsTest static void testPipelineSettingsStartWithNoAuthGitRepositoryHTTPS() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline'
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {

            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            String errorResponseForGitValidation = '{"error":"YOU SHALL NOT BE VALIDATED!"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(errorResponseForGitValidation, null));
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            List<Git_Repository__c> repoList = controller.getGitRepositories();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            System.assertEquals(1, repoList.size());

            //auth with https
            controller.gitAuthTypeValue = controller.HTTPS_STRING;
            controller.saveGitRepository();
            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            System.assertEquals(3, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Schema.SObjectType.Git_Repository__c.fields.URI__c.getLabel()));
            System.assert(ApexPages.getMessages()[1].getDetail().contains('username'));
            System.assert(ApexPages.getMessages()[2].getDetail().contains('password'));

            System.Test.clearApexPageMessages();

            controller.gitRepository.URI__c = 'git@bitbucket.org:copado/testing-pipeline.git';
            controller.gitRepositoryUsername = 'test-username-for-git';
            controller.gitRepositoryPassword = 'test-pass';
            controller.gitRepositoryExtraHeaders = 'Test: Extra Headers';
            controller.saveGitRepository();
            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            System.assertEquals(1, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.SSH_URI_validation));

            System.Test.clearApexPageMessages();

            controller.gitRepository.URI__c = 'https://copado@bitbucket.org/copado/testing-pipeline.git';
            controller.saveGitRepository();
            Test.startTest();
            String successResponseForGitValidation = '{"success":true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));

            controller.setStep();
            Test.stopTest();
            Note extraHeader = [SELECT Id, Title FROM Note WHERE ParentId = :controller.gitRepository.Id];
            System.assertEquals('Extra Headers', extraHeader.Title);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess.name(), controller.currentPipelineStepName);
            System.assertEquals(0, ApexPages.getMessages().size());
        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is NOT empty in the custom setting AND related Pipeline have
    * attached git repository that is NOT authenticated, show GitAuthenticationDetails as first step and we will do SSH auth
    */
    @IsTest static void testPipelineSettingsStartWithNoAuthGitRepositorySSH() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline'
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {

            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            String errorResponseForGitValidation = '{"error":"YOU SHALL NOT BE VALIDATED!"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(errorResponseForGitValidation, null));
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);

            //auth with ssh

            controller.gitAuthTypeValue = controller.SSH_STRING;
            controller.checkIfSSHKeyExist();
            controller.saveGitRepository();
            controller.setStep();

            System.assertEquals(null, controller.gitRepositorySshKey);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            System.assertEquals(2, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Schema.SObjectType.Git_Repository__c.fields.URI__c.getLabel()));
            System.assert(ApexPages.getMessages()[1].getDetail().contains('SSH Key'));

            System.Test.clearApexPageMessages();


            controller.gitRepository.URI__c = 'https://copado@bitbucket.org/copado/testing-pipeline.git';
            controller.createSshKey();
            controller.saveGitRepository();
            controller.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);
            System.assertEquals(2, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.SSH_URI_validation));
            System.assert(ApexPages.getMessages()[1].getDetail().contains('SSH Key'));

            System.Test.clearApexPageMessages();

            controller.gitRepository.URI__c = 'git@bitbucket.org:copado/testing-pipeline.git';
            Attachment sshKey = new Attachment(Name = 'id_rsa.pub', ParentId = controller.gitRepository.Id, Body = Blob.valueOf('test-ssh-key'));
            insert sshKey;
            Test.startTest();
            String successResponseForGitValidation = '{"ok": "test-ssh-key"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            controller.createSshKey();
            Test.stopTest();
            controller.saveGitRepository();
            System.assertNotEquals(null, controller.gitRepositorySshKey);
            System.assertEquals(0, ApexPages.getMessages().size());
        }
    }

    /**
    * Go to git repository credential step and click on go back button
    */
    @IsTest static void testPipelineSettingsStartWithNoAuthGitRepositorySSHGoBack() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline'
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            String errorResponseForGitValidation = '{"error":"YOU SHALL NOT BE VALIDATED!"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(errorResponseForGitValidation, null));
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails.name(), controller.currentPipelineStepName);

            controller.goToPreviousStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection.name(), controller.currentPipelineStepName);
            Test.stopTest();
        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is NOT empty in the custom setting AND related Pipeline have
    * attached git repository that is authenticated, show GitBaseUrls as first step and we will do base url merging
    */
    @IsTest static void testPipelineSettingsStartWithAuthGitRepositorySSH() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'Git_Provider__c' => 'Bitbucket',
                'URI__c' => 'git@bitbucket.org:copado/testing-pipeline.git'
        });

        tu.insertSObject('Attachment', new Map<String, Object>{
                'Name' => 'id_rsa.pub',
                'Body' => Blob.valueOf('my-ssh-string'),
                'ParentId' => tu.item('Git_Repository__c', 0).Id
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            String successResponseForGitValidation = '{"success": true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls.name(), controller.currentPipelineStepName);

            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/src/', controller.gitRepository.Tag_Base_URL__c);

            controller.gitRepositoryUsername = 'cop ado';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals(1, ApexPages.getMessages().size());
            System.assertEquals(Label.Pipeline_Username_Repo_Name_Empty_Space_Warning, ApexPages.getMessages()[0].getDetail());

            controller.gitRepositoryUsername = 'copado';
            controller.gitRepositoryRepoName = '   ';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals(1, ApexPages.getMessages().size());
            System.assertEquals(Label.Pipeline_Username_Repo_Name_Empty_Space_Warning, ApexPages.getMessages()[0].getDetail());

            controller.gitRepositoryRepoName = '';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/src/', controller.gitRepository.Tag_Base_URL__c);

            controller.gitRepositoryUsername = 'copado-test';
            controller.gitRepositoryRepoName = 'test-repo';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals('https://bitbucket.org/copado-test/test-repo/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/src/', controller.gitRepository.Tag_Base_URL__c);

            //TODO assert all provider urls

            controller.updateRepoAndMoveToNext();

            usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());

            System.assertEquals('PipelineTemplatesWizard', usersSetup.Last_Step__c);

            Test.stopTest();

        }
    }

    /**
    * When starting pipeline settings step if user's pipeline id field is NOT empty in the custom setting AND related Pipeline have
    * attached git repository that is authenticated, show GitBaseUrls as first step and we will assert for Other provider merge fields are not populated
    * Also we will test save & close
    */
    @IsTest static void testPipelineSettingsOtherGitRepositoryBaseUrls() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'Git_Provider__c' => 'Others',
                'URI__c' => 'git@other.org:copado/testing-pipeline.git'
        });

        tu.insertSObject('Attachment', new Map<String, Object>{
                'Name' => 'id_rsa.pub',
                'Body' => Blob.valueOf('my-ssh-string'),
                'ParentId' => tu.item('Git_Repository__c', 0).Id
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        usersSetup.Last_Step__c = 'PipelineSettingsWizard';
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            String successResponseForGitValidation = '{"success": true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls.name(), controller.currentPipelineStepName);

            System.assertEquals(null, controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Tag_Base_URL__c);

            controller.saveAndClose();

            usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());

            System.assertEquals('PipelineSettingsWizard', usersSetup.Last_Step__c);

            Test.stopTest();

        }
    }

    /**
    * Go to git repository url setup step and click on go back button
    */
    @IsTest static void testPipelineSettingsOtherGitRepositoryBaseUrlsGoBack() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'Git_Provider__c' => 'Others',
                'URI__c' => 'git@other.org:copado/testing-pipeline.git'
        });

        tu.insertSObject('Attachment', new Map<String, Object>{
                'Name' => 'id_rsa.pub',
                'Body' => Blob.valueOf('my-ssh-string'),
                'ParentId' => tu.item('Git_Repository__c', 0).Id
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        usersSetup.Last_Step__c = 'PipelineSettingsWizard';
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            String successResponseForGitValidation = '{"success": true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls.name(), controller.currentPipelineStepName);

            System.assertEquals(null, controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals(null, controller.gitRepository.Tag_Base_URL__c);

            controller.goToPreviousStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess.name(), controller.currentPipelineStepName);
            Test.stopTest();

        }
    }

    /**
    * this method tests skip urls method
    */
    @IsTest static void testPipelineSettingsSkipUrls() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'Git_Provider__c' => 'Bitbucket',
                'URI__c' => 'git@bitbucket.org:copado/testing-pipeline.git'
        });

        tu.insertSObject('Attachment', new Map<String, Object>{
                'Name' => 'id_rsa.pub',
                'Body' => Blob.valueOf('my-ssh-string'),
                'ParentId' => tu.item('Git_Repository__c', 0).Id
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            String successResponseForGitValidation = '{"success": true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, controller.currentPipelineStep);
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls.name(), controller.currentPipelineStepName);

            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/src/', controller.gitRepository.Tag_Base_URL__c);

            controller.gitRepositoryUsername = 'copado';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado/{RepositoryName}/src/', controller.gitRepository.Tag_Base_URL__c);

            controller.gitRepositoryUsername = 'copado-test';
            controller.gitRepositoryRepoName = 'test-repo';
            controller.updateBaseUrlsMergeFields();

            System.assertEquals('https://bitbucket.org/copado-test/test-repo/branch/', controller.gitRepository.Branch_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/commit/', controller.gitRepository.Commit_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/', controller.gitRepository.Pull_Request_Base_URL__c);
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/src/', controller.gitRepository.Tag_Base_URL__c);

            controller.skipUrls();

            usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());

            Git_Repository__c pipelineGitRepo = [
                    SELECT Id, Branch_Base_URL__c, Commit_Base_URL__c, Pull_Request_Base_URL__c, Tag_Base_URL__c
                    FROM Git_Repository__c
                    WHERE Id = :usersSetup.Git_Repository_Id__c
            ];

            System.assertEquals('PipelineTemplatesWizard', usersSetup.Last_Step__c);
            System.assertEquals(null, pipelineGitRepo.Branch_Base_URL__c);
            System.assertEquals(null, pipelineGitRepo.Commit_Base_URL__c);
            System.assertEquals(null, pipelineGitRepo.Pull_Request_Base_URL__c);
            System.assertEquals(null, pipelineGitRepo.Tag_Base_URL__c);

            Test.stopTest();

        }
    }

    /**
    * this method tests permission errors
    */
    @IsTest static void testPipelineSettingsPermissionErrors() {
        User testUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test@pipeline-settings-noaccess123.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Create git repository
        tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                'Name' => 'Test pipeline',
                'Git_Provider__c' => 'Bitbucket',
                'URI__c' => 'git@bitbucket.org:copado/testing-pipeline.git'
        });

        tu.insertSObject('Attachment', new Map<String, Object>{
                'Name' => 'id_rsa.pub',
                'Body' => Blob.valueOf('my-ssh-string'),
                'ParentId' => tu.item('Git_Repository__c', 0).Id
        });

        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'My Awesome Test Pipeline With Repo 123',
                'Main_Branch__c' => 'master',
                'Calculate_Based_on__c' => 'User Story',
                'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                'OwnerId' => testUser.Id
        });

        Deployment_Flow__c testPipeline = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'My Awesome Test Pipeline With Repo 123'];
        Setup_Wizard_Steps__c usersSetup = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        usersSetup.Pipeline_Id__c = testPipeline.Id;
        usersSetup.Git_Repository_Id__c = testPipeline.Git_Repository__c;
        usersSetup.SetupOwnerId = testUser.Id;
        insert usersSetup;
        System.runAs(testUser) {
            Test.startTest();
            PageReference pReference = Page.PipelineSettingsWizard;
            Test.setCurrentPage(pReference);
            PipelineSettingsComponentController controller = new PipelineSettingsComponentController();
            System.assertNotEquals(null, controller.errorMessageJSON);
            System.assert(controller.errorMessageJSON.contains('license'));

            Test.stopTest();
        }
    }
}