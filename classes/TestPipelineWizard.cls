@IsTest
private with sharing class TestPipelineWizard {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String APEX = '/apex/';
    private static final String ID = 'Id';
    private static final String DEV1 = 'dev1';
    private static final String DEV2 = 'dev2';
    private static final String STAGING = 'staging';
    private static final String MODE = 'mode';
    private static final String DIAGRAM = 'diagram';
    private static final String STEP_ID = 'stepId';
    private static final String ENV_ID = 'envId';
    private static final String ENV_NAME = 'envName';
    private static final String BRANCH = 'branch';
    private static final String NEW_PIPELINE = 'newPipeline';
    private static final String PIPELINE_ID = 'pipelineId';
    private static final String AUTH_STAGE = 'authStage';
    private static final String ORG_ID = 'orgId';
    private static final String TRUE_STRING = 'true';
    private static final String QUESTION_MARK = '?';
    private static final String COMPLETE = 'Complete';
    private static final String MY_NEW_PIPELINE = 'My New Pipeline';
    private static final String MY_GIT_REPO = 'My new git repo';
    private static final String GITHUB = 'Github';
    private static final String GITHUB_URI = 'https://github.com/mygithubuser/usecaserepo.git';
    private static final String MY_GIT_USER = 'mygithubuser';
    private static final String MY_PASSWORD = 'mypassword';
    private static final String COPADO_TEST = 'copado-test';
    private static final String TEST_REPO = 'test-repo';
    private static final String MY_ALIAS_STAGING = 'myAlias-staging';
    private static final String MY_ALIAS_DEV1 = 'myAlias-dev1';
    private static final String MY_ALIAS_DEV2 = 'myAlias-dev2';
    private static final String EMPTY_STRING = '';

    @TestSetup
    static void makeData(){
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults()
            .createRunAsUsers()
            .executeDML();
    }

    /**
     * New pipeline without license
     */
    @IsTest
    static void testNewPipelineWithoutLicense() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            Test.startTest();
            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            PageReference assertPipeline = Page.SetupWizardStart;
            assertPipeline.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertPipeline.getUrl(), startPipeline.getUrl(),'SetupWizardStart.page is not next Page');

            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference gotoManagerPage = startPipelineController.goToManager();

            System.assertEquals(null, gotoManagerPage, 'PageReference is not returning "null"');
            System.assertEquals(false, startPipelineController.userHasCopadoCredential, 'Copado Credential has been asigned. It should be false');
            System.assertEquals(false, startPipelineController.userHasLicense, 'License has been assigned, it shouldn\'t be');
            Test.stopTest();
        }
    }

    /**
     * New pipeline w/ license.
     *  - New Repo
     *  - Repo is github
     *  - Repo is Https
     *  - Production org is current org
     */
    @IsTest
    static void testNewPipelineNewRepoPositive() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER  LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            // Click on "new Pipeline"
            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            PageReference assertPipeline = Page.SetupWizardStart;
            assertPipeline.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertPipeline.getUrl(), startPipeline.getUrl(), 'SetupWizardStart.page is not next Page');

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            System.assertEquals(null, startWizardWizardPage, 'Page reference is not "null"');
            System.assertEquals(true, startPipelineController.userHasCopadoCredential, 'Copado Credential has not been asigned.');
            System.assertEquals(true, startPipelineController.userHasLicense, 'License has not been assigned.');

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            Pagereference assertStartWizard = Page.PipelineSettingsWizard;
            assertStartWizard.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertStartWizard.getURL().toLowercase().substringAfter(APEX), pipelineSettings.getUrl().toLowercase().substringAfter(APEX), 'PipelineSettingsWizard.page is not next page');

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName, pipelineSettingsWizardSettingController.currentPipelineStep, 'PipelineName is not current Step');
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitRepositorySelection, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitRepositorySelection is not current Step');

            // Repository configuration
            pipelineSettingsWizardSettingController.gitRepository.Name = MY_GIT_REPO;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = GITHUB;
            pipelineSettingsWizardSettingController.updateAndGoToNext();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitAuthenticationDetails is not current Step');

            // Repository authentication
            pipelineSettingsWizardSettingController.gitAuthTypeValue = pipelineSettingsWizardSettingController.HTTPS_STRING;
            pipelineSettingsWizardSettingController.gitRepository.URI__c = GITHUB_URI;
            pipelineSettingsWizardSettingController.gitRepositoryUsername = MY_GIT_USER;
            pipelineSettingsWizardSettingController.gitRepositoryPassword = MY_PASSWORD;

            String successResponseForGitValidation = '{"success":true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            pipelineSettingsWizardSettingController.saveGitRepository();

            /**
             * Next step is set manully instead of use "setStep" to avoid callout
            */
            pipelineSettingsWizardSettingController.currentPipelineStep = PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess;
            pipelineSettingsWizardSettingController.updateSetupWizardCustomSetting(null, null, pipelineSettingsWizardSettingController.gitRepository.Id, pipelineSettingsWizardSettingController.newPipeline.Id, null, null, null);
            pipelineSettingsWizardSettingController.currentPipelineStepName = pipelineSettingsWizardSettingController.currentPipelineStep.name();
            /**
             * End of manual setStep
            */

            pipelineSettingsWizardSettingController.setStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitBaseUrls is not current Step');

            // Repository URL configuration
            System.assertEquals('https://github.com/{Username}/{RepositoryName}/tree/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'Repository "Base branch" initial URL is not correct');
            System.assertEquals('https://github.com/{Username}/{RepositoryName}/commit/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'Repository "Commit" initial URL is not correct');
            System.assertEquals('https://github.com/{Username}/{RepositoryName}/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'Repository "Pull Request" initial URL is not correct');
            System.assertEquals('https://github.com/{Username}/{RepositoryName}/tags/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'Repository "Tag" initial URL is not correct');

            pipelineSettingsWizardSettingController.gitRepositoryUsername = COPADO_TEST;
            pipelineSettingsWizardSettingController.gitRepositoryRepoName = TEST_REPO;
            pipelineSettingsWizardSettingController.updateBaseUrlsMergeFields();

            System.assertEquals('https://github.com/copado-test/test-repo/tree/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'Repository "Base branch" merged URL is not correct');
            System.assertEquals('https://github.com/copado-test/test-repo/commit/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'Repository "Commit" merged URL is not correct');
            System.assertEquals('https://github.com/copado-test/test-repo/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'Repository "Pull Request" merged URL is not correct');
            System.assertEquals('https://github.com/copado-test/test-repo/tags/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'Repository "Tag" merged URL is not correct');

            Pagereference pipelineWizardTemplates = pipelineSettingsWizardSettingController.updateRepoAndMoveToNext();
            Test.setCurrentPage(pipelineWizardTemplates);

            Pagereference assertTemplateWizardComponent = Page.PipelineTemplatesWizard;
            assertTemplateWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertTemplateWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardTemplates.getUrl().toLowercase().substringAfter(APEX), 'PipelineTemplatesWizard.page is not next page');

            // Templates configuration
            PipelineTemplateComponentController pipelineWizardTemplatesController = new PipelineTemplateComponentController();
            pipelineWizardTemplatesController.currentType = 'BASIC';
            pipelineWizardTemplatesController.processSelectedTemplateType();
            System.assertEquals(pipelineWizardTemplatesController.basicJson, pipelineWizardTemplatesController.selectionsJSON, 'Processed Template selection does no match with Basic Template');

            Pagereference pipelineWizardOrgAuth = pipelineWizardTemplatesController.selectTemplate();
            Test.setCurrentPage(pipelineWizardOrgAuth);

            List<Deployment_Flow_Step__c> pipelineConnections = [SELECT Id, Branch__c, Destination_Branch__c FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :pipelineSettingsWizardSettingController.newPipeline.Id ORDER BY Branch__c];
            System.assertEquals(3, pipelineConnections.size(), 'The number of Pipeline Connections must be three');
            System.assertEquals(DEV1, pipelineConnections[0].Branch__c, 'Branch for this step must be' + DEV1 );
            System.assertEquals(STAGING, pipelineConnections[0].Destination_Branch__c, 'Destination Branch for this step must be' + STAGING);
            System.assertEquals(DEV2, pipelineConnections[1].Branch__c, 'Branch for this step must be' + DEV2 );
            System.assertEquals(STAGING, pipelineConnections[1].Destination_Branch__c, 'Destination Branch for this step must be' + STAGING );
            System.assertEquals(STAGING, pipelineConnections[2].Branch__c, 'Branch for this step must be' + STAGING );
            System.assertEquals('master', pipelineConnections[2].Destination_Branch__c, 'Destination Branch for this step must be "master" ');

            Pagereference assertOrgAuthWizardComponent = Page.OrgAuthenticationWizard;
            assertOrgAuthWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertOrgAuthWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardOrgAuth.getUrl().toLowercase().substringAfter(APEX), 'OrgAuthenticationWizard.page is not next page');

            // Org Authentication
            OrgAuthenticationComponentController pipelineWizardOrgAuthController = new OrgAuthenticationComponentController();
            pipelineWizardOrgAuthController.setStep();

            Pagereference pipelineSetupWizardFinish = pipelineWizardOrgAuthController.goToNextComponent();
            Test.setCurrentPage(pipelineSetupWizardFinish);

            Pagereference assertPipelineSetupWizardFinish = Page.SetupWizardFinish;
            assertPipelineSetupWizardFinish.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertPipelineSetupWizardFinish.getUrl().toLowercase().substringAfter(APEX), pipelineSetupWizardFinish.getUrl().toLowercase().substringAfter(APEX), 'SetupWizardFinish.page is not next page');

            // Finish Wizard and redirect to Pipeline Diagram
            SetupWizardFinishController pipelineSetupWizardFinishController = new SetupWizardFinishController();
            Pagereference pipelineDiagram = pipelineSetupWizardFinishController.enjoyCopado();

            Pagereference assertPipelineDiagram = Page.PipelineManager;
            assertPipelineDiagram.getParameters().put(ID, String.valueOf(pipelineSettingsWizardSettingController.newPipeline.Id));
            assertPipelineDiagram.getParameters().put(MODE, DIAGRAM);
            System.assertEquals(assertPipelineDiagram.getUrl().toLowercase().substringAfter(APEX), pipelineDiagram.getUrl().toLowercase().substringAfter(APEX), 'PipelineManager.page is not next page');

            Deployment_Flow__c currentPipeline = new Deployment_Flow__c();
            currentPipeline = pipelineSettingsWizardSettingController.newPipeline;
            ApexPages.StandardController currentSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension pipelineManagerController = new PipelineManagerExtension(currentSc);
            pipelineManagerController.populateFlowGridMap();
            System.assertEquals(false, ApexPages.hasMessages(), 'This page has error messages');

            Test.stopTest();
        }
    }

    /**
     * User with "Copado User" perm set asssigned and Enterprise license assigned.
     *  - Existing repo
     *  - Production org different from current
     */
    @IsTest
    static void testNewPipelineExistingRepoGovernanceoOrgPositive() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        // Git repo has to be created as admin.
        ITestDefaults gitRepoSetupDefaults = new CopadoPipelineWizardTestDefaults.GitRepositoryDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoPipelineWizardTestDefaults.SensitiveInformationDefaults.class)
                .setFieldValue(Git_Repository__c.SObjectType, Git_Repository__c.Git_Provider__c, GITHUB)
                .setFieldValue(Git_Repository__c.SObjectType, Git_Repository__c.URI__c, 'https://github.com/UserName/MyGitRepo.git')
                .setSObjectRelation(Sensitive_Information__c.SObjectType, Git_Repository__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                    Sensitive_Information__c.Name => 1
                 })
                .setDataSize(Git_Repository__c.SObjectType,1)
                .setDataSize(Sensitive_Information__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            // Click on New Pipeline
            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            /**
             * Test Starts here. No assertions needed before. Previous part already tested in "testNewPipelineNewRepoPositive()" test.
            */

            // Repository configuration
            List<Git_Repository__c> gitRepositories = pipelineSettingsWizardSettingController.getGitRepositories();
            System.assertEquals(1,gitRepositories.size(), 'There are more than one repository for this configuration');

            pipelineSettingsWizardSettingController.gitRepository.Id = gitRepositories[0].Id;
            pipelineSettingsWizardSettingController.gitRepository.Name = gitRepositories[0].Name;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = gitRepositories[0].Git_Provider__c;

            /**
             *  This method is skipped to avoid callout: pipelineSettingsWizardSettingController.updateAndGoToNext();
             *  Instead, all methods inside are executed
             */
            pipelineSettingsWizardSettingController.gitRepository = pipelineSettingsWizardSettingController.gitRepositoryMap.get(pipelineSettingsWizardSettingController.gitRepository.Id);
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = gitRepositories[0].Git_Provider__c;

            pipelineSettingsWizardSettingController.currentPipelineStep = PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls;
            pipelineSettingsWizardSettingController.populateURLFields();

            Utilities.Secure_DML(pipelineSettingsWizardSettingController.gitRepository, Utilities.DML_Action.UPS, Schema.SObjectType.Git_Repository__c);
            pipelineSettingsWizardSettingController.newPipeline.Git_Repository__c = pipelineSettingsWizardSettingController.gitRepository.Id;
            Utilities.Secure_DML(pipelineSettingsWizardSettingController.newPipeline, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow__c);
            pipelineSettingsWizardSettingController.prepareAuthStep();
            /**
             * End of manual setStep
            */

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitBaseUrls is not current step');

            Sensitive_Information__c gitRepoData = Sensitive_Information__c.getInstance(gitRepositories[0].Id);
            String gitRepoName = gitRepositories[0].Name.deleteWhitespace();

            // Repository URL configuration
            pipelineSettingsWizardSettingController.gitRepositoryUsername = gitRepoData.Username__c;
            pipelineSettingsWizardSettingController.gitRepositoryRepoName = gitRepoName;

            pipelineSettingsWizardSettingController.updateBaseUrlsMergeFields();

            System.assertEquals('https://github.com/' + gitRepoData.Username__c + '/' + gitRepoName + '/tree/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'Repository "Base branch" merged URL is not correct');
            System.assertEquals('https://github.com/' + gitRepoData.Username__c + '/' + gitRepoName + '/commit/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'Repository "Commit" merged URL is not correct');
            System.assertEquals('https://github.com/' + gitRepoData.Username__c + '/' + gitRepoName + '/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c,'Repository "Pull Request" merged URL is not correct');
            System.assertEquals('https://github.com/' + gitRepoData.Username__c + '/' + gitRepoName + '/tags/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'Repository "Tag" merged URL is not correct');

            Pagereference pipelineWizardTemplates = pipelineSettingsWizardSettingController.updateRepoAndMoveToNext();
            Test.setCurrentPage(pipelineWizardTemplates);

            Pagereference assertTemplateWizardComponent = Page.PipelineTemplatesWizard;
            assertTemplateWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertTemplateWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardTemplates.getUrl().toLowercase().substringAfter(APEX), 'PipelineTemplatesWizard.page is note next page');

            // Templates configuration
            PipelineTemplateComponentController pipelineWizardTemplatesController = new PipelineTemplateComponentController();
            pipelineWizardTemplatesController.currentType = 'BASIC';
            pipelineWizardTemplatesController.processSelectedTemplateType();

            Pagereference pipelineWizardOrgAuth = pipelineWizardTemplatesController.selectTemplate();
            Test.setCurrentPage(pipelineWizardOrgAuth);

            // Org Authentication
            OrgAuthenticationComponentController pipelineWizardOrgAuthController = new OrgAuthenticationComponentController();
            pipelineWizardOrgAuthController.selectedOperation = 'No';
            PageReference oauthUrl = pipelineWizardOrgAuthController.doOauth();

            System.assert(oauthUrl.getUrl().toLowercase().contains('authorize/sforcelogin'), 'OAuth URL is not correct');

            // Test finish here. The rest is tested in tested in "testNewPipelineNewRepoPositive()" test.
            Test.stopTest();
        }
    }

    /**
     * Test skip templates, so when Wizard finish, Copado warn you to create manually Pipeline connections.
     */
    @IsTest
    static void testNewPipelineNewRepoSkipTemplateNegative() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            // Repository configuration
            pipelineSettingsWizardSettingController.gitRepository.Name = MY_GIT_REPO;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = GITHUB;
            pipelineSettingsWizardSettingController.updateAndGoToNext();

            // Repository authentication
            pipelineSettingsWizardSettingController.gitAuthTypeValue = pipelineSettingsWizardSettingController.HTTPS_STRING;
            pipelineSettingsWizardSettingController.gitRepository.URI__c = GITHUB_URI;
            pipelineSettingsWizardSettingController.gitRepositoryUsername = MY_GIT_USER;
            pipelineSettingsWizardSettingController.gitRepositoryPassword = MY_PASSWORD;

            String successResponseForGitValidation = '{"success":true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            pipelineSettingsWizardSettingController.saveGitRepository();

            /**
             * Next step is set manully instead of use "setStep" to avoid callout
            */
            pipelineSettingsWizardSettingController.currentPipelineStep = PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess;
            pipelineSettingsWizardSettingController.updateSetupWizardCustomSetting(null, null, pipelineSettingsWizardSettingController.gitRepository.Id, pipelineSettingsWizardSettingController.newPipeline.Id, null, null, null);
            pipelineSettingsWizardSettingController.currentPipelineStepName = pipelineSettingsWizardSettingController.currentPipelineStep.name();
            /**
             * End of manual step
             */

            pipelineSettingsWizardSettingController.setStep();

            pipelineSettingsWizardSettingController.gitRepositoryUsername = COPADO_TEST;
            pipelineSettingsWizardSettingController.gitRepositoryRepoName = TEST_REPO;
            pipelineSettingsWizardSettingController.updateBaseUrlsMergeFields();

            Pagereference pipelineWizardTemplates = pipelineSettingsWizardSettingController.updateRepoAndMoveToNext();
            Test.setCurrentPage(pipelineWizardTemplates);

            /**
             * Test Starts here. No assertions needed before. Previous part already tested in "testNewPipelineNewRepoPositive()" test.
            */

            // Templates configuration
            PipelineTemplateComponentController pipelineWizardTemplatesController = new PipelineTemplateComponentController();
            Pagereference pipelineWizardOrgAuth = pipelineWizardTemplatesController.skipTemplates();
            Test.setCurrentPage(pipelineWizardOrgAuth);

            Pagereference assertOrgAuthWizardComponent = Page.OrgAuthenticationWizard;
            assertOrgAuthWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertOrgAuthWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardOrgAuth.getUrl().toLowercase().substringAfter(APEX), 'OrgAuthenticationWizard.page is note next page');

            // Org Authentication
            OrgAuthenticationComponentController pipelineWizardOrgAuthController = new OrgAuthenticationComponentController();
            pipelineWizardOrgAuthController.setStep();

            Pagereference pipelineSetupWizardFinish = pipelineWizardOrgAuthController.goToNextComponent();
            Test.setCurrentPage(pipelineSetupWizardFinish);

            Pagereference assertPipelineSetupWizardFinish = Page.SetupWizardFinish;
            assertPipelineSetupWizardFinish.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertPipelineSetupWizardFinish.getUrl().toLowercase().substringAfter(APEX), pipelineSetupWizardFinish.getUrl().toLowercase().substringAfter(APEX), 'SetupWizardFinish.page is not next page');

            // Finish Wizard and redirect to Pipeline Diagram
            SetupWizardFinishController pipelineSetupWizardFinishController = new SetupWizardFinishController();
            Pagereference pipelineDiagram = pipelineSetupWizardFinishController.enjoyCopado();

            Pagereference assertPipelineDiagram = Page.PipelineManager;
            assertPipelineDiagram.getParameters().put(ID, String.valueOf(pipelineSettingsWizardSettingController.newPipeline.Id));
            assertPipelineDiagram.getParameters().put(MODE, DIAGRAM);
            System.assertEquals(assertPipelineDiagram.getUrl().toLowercase().substringAfter(APEX), pipelineDiagram.getUrl().toLowercase().substringAfter(APEX));

            Deployment_Flow__c currentPipeline = new Deployment_Flow__c();
            currentPipeline = pipelineSettingsWizardSettingController.newPipeline;
            ApexPages.StandardController currentSc = new ApexPages.StandardController(currentPipeline);
            PipelineManagerExtension pipelineManagerController = new PipelineManagerExtension(currentSc);
            pipelineManagerController.populateFlowGridMap();
            System.assertEquals(Label.Pipeline_Missing_Destination_Environment, ApexPages.getMessages()[0].getDetail(), 'Error message is not noticing an incomplete connection setup');

            Test.stopTest();
        }
    }

    /**
     * Save and close at Git Repository step. So when we want to start a new pipeline we can continue at the same point.
     */
    @IsTest
    static void testSaveandClosePositive() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.PipelineName, pipelineSettingsWizardSettingController.currentPipelineStep, 'PipelineName.page is not next step');
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            /**
             * Test Starts here. No assertions needed before. Previous part already tested in "testNewPipelineNewRepoPositive()" test.
            */

            // Repository configuration
            pipelineSettingsWizardSettingController.gitRepository.Name = MY_GIT_REPO;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = GITHUB;
            pipelineSettingsWizardSettingController.updateAndGoToNext();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitAuthenticationDetails.page is not current step');

            // Repository authentication
            PageReference saveAndClose = pipelineSettingsWizardSettingController.saveAndClose();
            PageReference assertsaveAndClose = new PageReference('/' + Schema.SObjectType.Deployment_Flow__c.getKeyPrefix());
            System.assertEquals(assertsaveAndClose.getUrl(), saveAndClose.getUrl(), 'Pipeline listview page is not the current page');

            Setup_Wizard_Steps__c wtf1 = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
            Test.setCurrentPage(saveAndClose);

            // New Pipeline to start where it was saved.
            Setup_Wizard_Steps__c wtf = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
            PipelineSettingsComponentController pipelineContinueSettingsWizardSettingController = new PipelineSettingsComponentController();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, pipelineContinueSettingsWizardSettingController.currentPipelineStep, 'GitAuthenticationDetails.page is not current page');

            // Test finish here. The rest is tested in "testNewPipelineNewRepoPositive()" test.
            Test.stopTest();
        }
    }

    /**
     * Covering populate urls when git repo is Bitbucket.
     * Github and gilab are covered by first test
     * Others is covered by unit test in test class : Test_PipelineSettingsComponentController
     */
    @IsTest
    static void testPopulateURlsBitbucketPositive() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            /**
             * Test Starts here. No assertions needed before. Previous part already tested in "testNewPipelineNewRepoPositive()" test.
            */

            // Repository configuration
            pipelineSettingsWizardSettingController.gitRepository.Name = MY_GIT_REPO;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = 'Bitbucket';
            pipelineSettingsWizardSettingController.updateAndGoToNext();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitAuthenticationDetails.page is not current page');

            // Repository authentication
            pipelineSettingsWizardSettingController.gitAuthTypeValue = pipelineSettingsWizardSettingController.HTTPS_STRING;
            pipelineSettingsWizardSettingController.gitRepository.URI__c = 'https://bitbucket.org/mygithubuser/usecaserepo.git';
            pipelineSettingsWizardSettingController.gitRepositoryUsername = MY_GIT_USER;
            pipelineSettingsWizardSettingController.gitRepositoryPassword = MY_PASSWORD;

            String successResponseForGitValidation = '{"success":true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            pipelineSettingsWizardSettingController.saveGitRepository();

            /**
             * Next step is set manully instead of use "setStep" to avoid callout
            */
            pipelineSettingsWizardSettingController.currentPipelineStep = PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess;
            pipelineSettingsWizardSettingController.updateSetupWizardCustomSetting(null, null, pipelineSettingsWizardSettingController.gitRepository.Id, pipelineSettingsWizardSettingController.newPipeline.Id, null, null, null);
            pipelineSettingsWizardSettingController.currentPipelineStepName = pipelineSettingsWizardSettingController.currentPipelineStep.name();
            /**
             * End of manual step
            */

            pipelineSettingsWizardSettingController.setStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitBaseUrls is not current step');

            // Repository URL configuration
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/branch/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'Bitbucket "Base branch" base URL is not correct');
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/commit/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'Bitbucket "Commit" base URL is not correct');
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'Bitbucket "Pull Request" base URL is not correct');
            System.assertEquals('https://bitbucket.org/{Username}/{RepositoryName}/src/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'Bitbucket "Tag" base URL is not correct');

            pipelineSettingsWizardSettingController.gitRepositoryUsername = COPADO_TEST;
            pipelineSettingsWizardSettingController.gitRepositoryRepoName = TEST_REPO;
            pipelineSettingsWizardSettingController.updateBaseUrlsMergeFields();

            System.assertEquals('https://bitbucket.org/copado-test/test-repo/branch/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'Bitbucket "Base branch" merged URL is not correct');
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/commit/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'Bitbucket "Commit" merged URL is not correct');
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'Bitbucket "Pull Request" merged URL is not correct');
            System.assertEquals('https://bitbucket.org/copado-test/test-repo/src/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'Bitbucket "Tag" merged URL is not correct');

            Pagereference pipelineWizardTemplates = pipelineSettingsWizardSettingController.updateRepoAndMoveToNext();
            Test.setCurrentPage(pipelineWizardTemplates);

            Pagereference assertTemplateWizardComponent = Page.PipelineTemplatesWizard;
            assertTemplateWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertTemplateWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardTemplates.getUrl().toLowercase().substringAfter(APEX), 'PipelineTemplatesWizard.page is not next page');

            // Test finish here. The rest is tested in "testNewPipelineNewRepoPositive()" test.
            Test.stopTest();
        }
    }

    /**
     * Covering populate urls when git repo is Microsoft Team Services.
     * Github and gilab are covered by first test
     * Others is covered by unit test in test class : Test_PipelineSettingsComponentController
     */
    @IsTest
    static void testPopulateURlsMTSPositive() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType,Org__c.Username__c, standardUser.Username)
                .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                            Org__c.Environment__c => 1
                    })
                .setDataSize(Environment__c.SObjectType,1)
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults()
                .executeDML();

            Test.startTest();

            PageReference pageRef = Page.NewPipeline;
            Test.setCurrentPage(pageRef);

            Deployment_Flow__c myNewPipeline = new Deployment_Flow__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(myNewPipeline);
            NewPipelineExtension newPipeline = new NewPipelineExtension(sc);
            Pagereference startPipeline = newPipeline.setupDecisioner();
            Test.setCurrentPage(startPipeline);

            String response = '{"organizationId":"' + environmentSetupDefaults.getTestData(Org__c.SObjectType)[0].Id + '"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, COMPLETE, response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Start Wizard page
            SetupWizardStartController startPipelineController = new SetupWizardStartController();
            Pagereference startWizardWizardPage = startPipelineController.goToManager();

            Pagereference pipelineSettings = startPipelineController.startWizard();
            Test.setCurrentPage(pipelineSettings);

            // Pipeline Wizard Give a name to the pipeline
            PipelineSettingsComponentController pipelineSettingsWizardSettingController = new PipelineSettingsComponentController();
            pipelineSettingsWizardSettingController.newPipeline.Name = MY_NEW_PIPELINE;
            pipelineSettingsWizardSettingController.setStep();

            /**
             * Test Starts here. No assertions needed before. Previous part already tested in "testNewPipelineNewRepoPositive()" test.
            */
            // Repository configuration
            pipelineSettingsWizardSettingController.gitRepository.Name = MY_GIT_REPO;
            pipelineSettingsWizardSettingController.gitRepository.Git_Provider__c = 'Microsoft Team Service';
            pipelineSettingsWizardSettingController.updateAndGoToNext();

            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationDetails, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitAuthenticationDetails is not current step');

            // Repository authentication
            pipelineSettingsWizardSettingController.gitAuthTypeValue = pipelineSettingsWizardSettingController.HTTPS_STRING;
            pipelineSettingsWizardSettingController.gitRepository.URI__c = 'https://visualstudio.com/mygithubuser/usecaserepo.git';
            pipelineSettingsWizardSettingController.gitRepositoryUsername = MY_GIT_USER;
            pipelineSettingsWizardSettingController.gitRepositoryPassword = MY_PASSWORD;

            String successResponseForGitValidation = '{"success":true}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(successResponseForGitValidation, null));
            pipelineSettingsWizardSettingController.saveGitRepository();

            /**
             * Next step is set manully instead of use "setStep" to avoid callout
            */
            pipelineSettingsWizardSettingController.currentPipelineStep = PipelineSettingsComponentController.PipelineSettingsOrder.GitAuthenticationSuccess;
            pipelineSettingsWizardSettingController.updateSetupWizardCustomSetting(null, null, pipelineSettingsWizardSettingController.gitRepository.Id, pipelineSettingsWizardSettingController.newPipeline.Id, null, null, null);
            pipelineSettingsWizardSettingController.currentPipelineStepName = pipelineSettingsWizardSettingController.currentPipelineStep.name();
            /**
             * End of manual step
            */

            pipelineSettingsWizardSettingController.setStep();
            System.assertEquals(PipelineSettingsComponentController.PipelineSettingsOrder.GitBaseUrls, pipelineSettingsWizardSettingController.currentPipelineStep, 'GitBaseUrls is not current step');

            // Repository URL configuration
            System.assertEquals('https://{Username}.visualstudio.com/_git/{RepositoryName}/tree/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'VisualStudio "Base branch" base URL is not correct');
            System.assertEquals('https://{Username}.visualstudio.com/_git/{RepositoryName}/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'VisualStudio "Commit" base URL is not correct');
            System.assertEquals('https://{Username}.visualstudio.com/_git/{RepositoryName}/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'VisualStudio "Commit" base URL is not correct');
            System.assertEquals('https://{Username}.visualstudio.com/_git/{RepositoryName}/tags/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'VisualStudio "Tag" base URL is not correct');

            pipelineSettingsWizardSettingController.gitRepositoryUsername = COPADO_TEST;
            pipelineSettingsWizardSettingController.gitRepositoryRepoName = TEST_REPO;
            pipelineSettingsWizardSettingController.updateBaseUrlsMergeFields();

            System.assertEquals('https://copado-test.visualstudio.com/_git/test-repo/tree/', pipelineSettingsWizardSettingController.gitRepository.Branch_Base_URL__c, 'VisualStudio "Base branch" merged URL is not correct');
            System.assertEquals('https://copado-test.visualstudio.com/_git/test-repo/', pipelineSettingsWizardSettingController.gitRepository.Commit_Base_URL__c, 'VisualStudio "Commit" merged URL is not correct');
            System.assertEquals('https://copado-test.visualstudio.com/_git/test-repo/', pipelineSettingsWizardSettingController.gitRepository.Pull_Request_Base_URL__c, 'VisualStudio "Commit" merged URL is not correct');
            System.assertEquals('https://copado-test.visualstudio.com/_git/test-repo/tags/', pipelineSettingsWizardSettingController.gitRepository.Tag_Base_URL__c, 'VisualStudio "Commit" merged URL is not correct');

            Pagereference pipelineWizardTemplates = pipelineSettingsWizardSettingController.updateRepoAndMoveToNext();
            Test.setCurrentPage(pipelineWizardTemplates);

            Pagereference assertTemplateWizardComponent = Page.PipelineTemplatesWizard;
            assertTemplateWizardComponent.getParameters().put(NEW_PIPELINE, TRUE_STRING);
            System.assertEquals(assertTemplateWizardComponent.getUrl().toLowercase().substringAfter(APEX), pipelineWizardTemplates.getUrl().toLowercase().substringAfter(APEX), 'PipelineTemplatesWizard.page is not next page');

            // Test finish here. The rest is tested in "testNewPipelineNewRepoPositive()" test.
            Test.stopTest();
        }
    }

    @IsTest
    static void testEnvironmentsAuthentication() {
        String assertLoginPage = 'authorize/sforcelogin';
        String assertOrgauthPage = Page.OrgAuthenticationWizard.getUrl().substringAfter(APEX);
        String assertPipelineManagerPage = Page.PipelineManager.getUrl().substringAfter(APEX);
        String assertSetupWizardFinishPage = Page.SetupWizardFinish.getUrl().substringAfter(APEX);

        User standardUser = [SELECT Id,Name,Email,Username, Alias FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, false, false, false, false);
        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Org_ID__c, UserInfo.getOrganizationId())
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

        Environment__c productionEnvironment = (Environment__c) environmentDefaults.getTestData(Environment__c.SObjectType)[0];

        // This data depends on certain specific records. That's why is splitted.
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c productionOrg = (Org__c) orgCredentialDefaults.getTestData(Org__c.SObjectType)[0];

        // This data depends on certain specific records. That's why is splitted.
        ITestDefaults pipelineDefaults = new CopadoUserStoryTestDefaults.PipelineDefaults()
            .setFieldDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.ProjectDefaults.class)
            .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
            .setSObjectRelation(
                Deployment_Flow__c.SObjectType,
                Git_Repository__c.SObjectType,
                new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
            )
            .setSObjectRelation(
                Project__c.SObjectType,
                Deployment_Flow__c.SObjectType,
                new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
            )
            .setDataSize(Git_Repository__c.SObjectType, 1)
            .setDataSize(Deployment_Flow__c.SObjectType, 1)
            .setDataSize(Project__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Project__c project = (Project__c) pipelineDefaults.getTestData(Project__c.SObjectType)[0];
        Deployment_Flow__c pipeline = (Deployment_Flow__c) pipelineDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

        // This data depends on certain specific records. That's why is splitted.
        ITestDefaults pipelineConnectionsDefaults = new CopadoUserStoryTestDefaults.PipelineConnectionDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV1)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING)
            .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV2)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING)
            .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, STAGING)
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'master')
            .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
            .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Deployment_Flow_Step__c stagingConnection = new Deployment_Flow_Step__c();
        Deployment_Flow_Step__c dev1Connection = new Deployment_Flow_Step__c();
        Deployment_Flow_Step__c dev2Connection = new Deployment_Flow_Step__c();

        for (Deployment_Flow_Step__c connection : (List<Deployment_Flow_Step__c>) pipelineConnectionsDefaults.getTestData(Deployment_Flow_Step__c.SObjectType)) {
            switch on connection.Branch__c {
                when 'staging' {
                    stagingConnection = connection;
                }
                when 'dev1' {
                    dev1Connection = connection;
                }
                when 'dev2' {
                    dev2Connection = connection;
                }
            }
        }

        System.runAs(standardUser) {

            Pagereference pipelineDiagramPage = Page.PipelineManager;
            Test.setCurrentPage(pipelineDiagramPage);
            pipelineDiagramPage.getParameters().put(ID, pipeline.Id);
            pipelineDiagramPage.getParameters().put(MODE, DIAGRAM);

            ApexPages.StandardController currentSc = new ApexPages.StandardController(pipeline);
            PipelineManagerExtension pipelineManagerController = new PipelineManagerExtension(currentSc);
            pipelineManagerController.populateFlowGridMap();

            System.assertEquals(Label.Source_and_Destination_Environment_Null, pipelineManagerController.pageMessagesMap.get('warning')[0], 'Message is not noticing source or destination can\'t be empty');

            Test.startTest();

            pipelineDiagramPage.getParameters().put(STEP_ID, stagingConnection.Id);
            pipelineDiagramPage.getParameters().put(ENV_ID, EMPTY_STRING);
            pipelineDiagramPage.getParameters().put(ENV_NAME, STAGING);
            pipelineDiagramPage.getParameters().put(BRANCH, STAGING);
            PageReference orgAuthPage = pipelineManagerController.authenticateEnvironment();
            Test.setCurrentPage(orgAuthPage);

            System.assertEquals(assertOrgauthPage, orgAuthPage.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'OrgAuthenticationWizard.page is not next page');

            OrgAuthenticationComponentController pipelineOrgAuthController = new OrgAuthenticationComponentController();
            pipelineOrgAuthController.orgCredential.Org_Type__c = 'Production/Developer';

            // Staging Environment Authentication
            PageReference authWeLoginRedirect = pipelineOrgAuthController.doOauth();
            System.assertEquals(true, authWeLoginRedirect.getUrl().toLowerCase().contains(assertLoginPage), 'OAuth url is not correct');

            // From here, it is simulating backend gets user back to Copado and updates org credential
            Org__c stagingOrg = [SELECT Id, Name, SFDC_Org_ID__c FROM Org__c WHERE Name = :MY_ALIAS_STAGING LIMIT 1];
            stagingOrg.SFDC_Org_ID__c = '00D1i00000095cEEAQ_0050X000007h8hTQAQ_6';
            update stagingOrg;

            PageReference orgAuthCompletePage = Page.OrgAuthenticationWizard;
            Test.setCurrentPage(orgAuthCompletePage);
            orgAuthCompletePage.getParameters().put(PIPELINE_ID, pipeline.Id);
            orgAuthCompletePage.getParameters().put(ENV_NAME, STAGING);
            orgAuthCompletePage.getParameters().put(AUTH_STAGE, TRUE_STRING);
            orgAuthCompletePage.getParameters().put(BRANCH, STAGING);
            // This parameter has to be commented. In "pipelineCompleteOrgAuthController" there is a callout causing an error for uncommited work.
            //orgAuthCompletePage.getParameters().put(ORG_ID, stagingOrg.Id);

            OrgAuthenticationComponentController pipelineCompleteOrgAuthController = new OrgAuthenticationComponentController();
            // now we can put the parameter to the page
            pipelineCompleteOrgAuthController.currentOrgAuthenticateStep = 'orgvalidation';
            orgAuthCompletePage.getParameters().put(ORG_ID, stagingOrg.Id);

            pipelineCompleteOrgAuthController.setStep();
            Pagereference pipelineSetupWizardFinish = pipelineCompleteOrgAuthController.goToNextComponent();
            Test.setCurrentPage(pipelineSetupWizardFinish);

            System.assertEquals(assertSetupWizardFinishPage, pipelineSetupWizardFinish.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'SetupWizardFinish is not next page');

            // Redirect to diagram to continue authenticating.
            SetupWizardFinishController pipelineSetupWizardFinishController = new SetupWizardFinishController();
            Pagereference pipelineDiagramStaging = pipelineSetupWizardFinishController.enjoyCopado();
            Test.setCurrentPage(pipelineDiagramStaging);

            System.assertEquals(assertPipelineManagerPage, pipelineDiagramStaging.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'PipelineManager.page is not next page');

            currentSc = new ApexPages.StandardController(pipeline);
            pipelineManagerController = new PipelineManagerExtension(currentSc);

            // Dev1 auth
            pipelineDiagramStaging.getParameters().put(STEP_ID, dev1Connection.Id);
            pipelineDiagramStaging.getParameters().put(ENV_ID, EMPTY_STRING);
            pipelineDiagramStaging.getParameters().put(ENV_NAME, DEV1);
            pipelineDiagramStaging.getParameters().put(BRANCH, DEV1);
            PageReference orgAuthPageDev1 = pipelineManagerController.authenticateEnvironment();
            Test.setCurrentPage(orgAuthPageDev1);

            System.assertEquals(assertOrgauthPage, orgAuthPageDev1.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'OrgAuthenticationWizard.page is not next page');

            OrgAuthenticationComponentController pipelineOrgAuthDev1Controller = new OrgAuthenticationComponentController();
            pipelineOrgAuthDev1Controller.orgCredential.Org_Type__c = 'Production/Developer';

            PageReference authDev1WeLoginRedirect = pipelineOrgAuthDev1Controller.doOauth();
            System.assertEquals(true, authDev1WeLoginRedirect.getUrl().toLowerCase().contains(assertLoginPage), 'OAuth url is not correct');
            Org__c dev1Org = [SELECT Id, Name, SFDC_Org_ID__c FROM Org__c WHERE Name = :MY_ALIAS_DEV1 LIMIT 1];
            dev1Org.SFDC_Org_ID__c = '00D1i00000095CBEAY_0050X000007h8hTQAQ_3';
            update dev1Org;

            PageReference dev1OrgAuthCompletePage = Page.OrgAuthenticationWizard;
            Test.setCurrentPage(dev1OrgAuthCompletePage);
            dev1OrgAuthCompletePage.getParameters().put(PIPELINE_ID, pipeline.Id);
            dev1OrgAuthCompletePage.getParameters().put(ENV_NAME, DEV1);
            dev1OrgAuthCompletePage.getParameters().put(AUTH_STAGE, TRUE_STRING);
            dev1OrgAuthCompletePage.getParameters().put(BRANCH, DEV1);
            // This parameter has to be commented. In "pipelineCompleteOrgAuthController" there is a callout causing an error for uncommited work.
            //orgAuthCompletePage.getParameters().put(ORG_ID, createdOrg.Id);

            OrgAuthenticationComponentController pipelineCompleteDev1OrgAuthController = new OrgAuthenticationComponentController();
            // Now we can put the parameter to the page
            pipelineCompleteDev1OrgAuthController.currentOrgAuthenticateStep = 'orgvalidation';
            dev1OrgAuthCompletePage.getParameters().put(ORG_ID, dev1Org.Id);

            pipelineCompleteDev1OrgAuthController.setStep();
            Pagereference pipelineSetupWizardDev1Finish = pipelineCompleteDev1OrgAuthController.goToNextComponent();
            Test.setCurrentPage(pipelineSetupWizardDev1Finish);

            System.assertEquals(assertSetupWizardFinishPage, pipelineSetupWizardDev1Finish.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), '');

            // Redirect to diagram to continue authenticating.
            SetupWizardFinishController pipelineSetupWizardDev1FinishController = new SetupWizardFinishController();
            Pagereference pipelineDiagramDev1 = pipelineSetupWizardDev1FinishController.enjoyCopado();
            Test.setCurrentPage(pipelineDiagramDev1);

            System.assertEquals(assertPipelineManagerPage, pipelineDiagramDev1.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK));

            currentSc = new ApexPages.StandardController(pipeline);
            pipelineManagerController = new PipelineManagerExtension(currentSc);

            Test.stopTest(); // stopTest is placed here to avoid 101 SOQL.

            // Dev2 auth
            pipelineDiagramDev1.getParameters().put(STEP_ID, dev2Connection.Id);
            pipelineDiagramDev1.getParameters().put(ENV_ID, EMPTY_STRING);
            pipelineDiagramDev1.getParameters().put(ENV_NAME, DEV2);
            pipelineDiagramDev1.getParameters().put(BRANCH, DEV2);
            PageReference orgAuthPageDev2 = pipelineManagerController.authenticateEnvironment();
            Test.setCurrentPage(orgAuthPageDev2);

            System.assertEquals(assertOrgauthPage, orgAuthPageDev2.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK));

            OrgAuthenticationComponentController pipelineOrgAuthDev2Controller = new OrgAuthenticationComponentController();
            pipelineOrgAuthDev2Controller.orgCredential.Org_Type__c = 'Production/Developer';

            PageReference authDev2WeLoginRedirect = pipelineOrgAuthDev2Controller.doOauth();
            System.assertEquals(true, authDev2WeLoginRedirect.getUrl().toLowerCase().contains(assertLoginPage), 'Redirects to backend login page');
            Org__c dev2Org = [SELECT Id, Name, SFDC_Org_ID__c FROM Org__c WHERE Name = :MY_ALIAS_DEV2 LIMIT 1];
            dev2Org.SFDC_Org_ID__c = '00D1U0000012Lm9UAE_0050X000007h8hTQAQ_1';
            update dev2Org;

            PageReference dev2OrgAuthCompletePage = Page.OrgAuthenticationWizard;
            Test.setCurrentPage(dev2OrgAuthCompletePage);
            dev2OrgAuthCompletePage.getParameters().put(PIPELINE_ID, pipeline.Id);
            dev2OrgAuthCompletePage.getParameters().put(ENV_NAME, DEV2);
            dev2OrgAuthCompletePage.getParameters().put(AUTH_STAGE, TRUE_STRING);
            dev2OrgAuthCompletePage.getParameters().put(BRANCH, DEV2);
            // This parameter has to be commented. In "pipelineCompleteOrgAuthController" there is a callout causing an error for uncommited work.
            //orgAuthCompletePage.getParameters().put(ORG_ID, createdOrg.Id);

            OrgAuthenticationComponentController pipelineCompleteDev2OrgAuthController = new OrgAuthenticationComponentController();
            // now we can put the parameter to the page
            pipelineCompleteDev2OrgAuthController.currentOrgAuthenticateStep = 'orgvalidation';
            dev2OrgAuthCompletePage.getParameters().put(ORG_ID, dev2Org.Id);

            pipelineCompleteDev2OrgAuthController.setStep();
            Pagereference pipelineSetupWizardDev2Finish = pipelineCompleteDev2OrgAuthController.goToNextComponent();
            Test.setCurrentPage(pipelineSetupWizardDev2Finish);

            System.assertEquals(assertSetupWizardFinishPage, pipelineSetupWizardDev2Finish.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'SetupWizardFinish.page is not next page');

            // Redirect to diagram to continue authenticating.
            SetupWizardFinishController pipelineSetupWizardDev2FinishController = new SetupWizardFinishController();
            Pagereference pipelineDiagramDev2 = pipelineSetupWizardDev2FinishController.enjoyCopado();
            Test.setCurrentPage(pipelineDiagramDev2);

            System.assertEquals(assertPipelineManagerPage, pipelineDiagramDev2.getUrl().toLowercase().substringBetween(APEX,QUESTION_MARK), 'PipelineManager.page is not next page');

            currentSc = new ApexPages.StandardController(pipeline);
            pipelineManagerController = new PipelineManagerExtension(currentSc);
            pipelineManagerController.populateFlowGridMap();
            System.assertEquals(false, ApexPages.hasMessages(), 'This page has error messages');
            for(Deployment_Flow_Step__c finalStep : [SELECT Id, Branch__c, Source_Environment__r.Name, Destination_Environment__r.Name FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipeline.Id]) {
                switch on finalStep.Branch__c {
                    when 'staging' {
                        System.assertEquals(MY_ALIAS_STAGING, finalStep.Source_Environment__r.Name, 'Source environment for Staging stage');
                        System.assertEquals('Production 0', finalStep.Destination_Environment__r.Name, 'Destination environment for Staging stage');
                    }
                    when 'dev1' {
                        System.assertEquals(MY_ALIAS_DEV1, finalStep.Source_Environment__r.Name, 'Source environment for Dev1 stage');
                        System.assertEquals(MY_ALIAS_STAGING, finalStep.Destination_Environment__r.Name, 'Destination environment for Dev1 stage');
                    }
                    when 'dev2' {
                        System.assertEquals(MY_ALIAS_DEV2, finalStep.Source_Environment__r.Name, 'Source environment for Dev2 stage');
                        System.assertEquals(MY_ALIAS_STAGING, finalStep.Destination_Environment__r.Name, 'Destination environment for Dev2 stage');
                    }
                }
            }
        }
    }
}