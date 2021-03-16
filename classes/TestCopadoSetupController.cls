@IsTest
private class TestCopadoSetupController {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String PRODUCTION = 'Production';
    private static final String STAGING = 'Staging';
    private static final String DEV_1 = 'Dev1';
    private static final String DEV_2 = 'Dev2';
    private static final String PRODUCTION_0 = 'Production 0';
    private static final String STAGING_0 = 'Staging 0';
    private static final String DEV1_0 = 'Dev1 0';
    private static final String DEV2_0 = 'Dev2 0';
    private static final String STAGING_BRANCH = 'staging';
    private static final String DEV_1_BRANCH = 'dev1';
    private static final String DEV_2_BRANCH = 'dev2';

    @TestSetup
    static void setupTestData(){
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults()
            .createRunAsUsers()
            .executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, PRODUCTION)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, STAGING)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, DEV_1)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, DEV_2)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, PRODUCTION)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, STAGING)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_1)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_2)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults pipelineDefaults = new CopadoUserStoryTestDefaults.PipelineDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment_Flow__c.SObjectType, Deployment_Flow__c.Active__c, false)
                .setFieldValue(Deployment_Flow__c.SObjectType, Deployment_Flow__c.Calculate_Based_on__c, 'Branch')
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
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV_1_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, DEV_2_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipeline.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, STAGING_BRANCH)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'master')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void testGettingStartedPage() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        System.runAs(standardUser) {
            Test.startTest();

            List<Org__c> orgCredentialList = new List<Org__c>();
            //add this org
            Org__c o = testMethodUtilities.createOrg('this org', 'Production/Developer', '', '', '', System.now());
            orgCredentialList.add(o);
            //add a 2nd org
            Org__c o2 = testMethodUtilities.createOrg('org2', 'Production/Developer', '', '', '', System.now());
            orgCredentialList.add(o2);
            //add a 3rd org
            Org__c o3 = testMethodUtilities.createOrg('org3', 'Production/Developer', '', '', '', System.now());
            orgCredentialList.add(o3);

            insert orgCredentialList;

            //add a git repository
            Git_Repository__c g = testMethodUtilities.createGitRepository('git 1','https://git.com');
            insert g;

            //add a git snapshot
            Git_Backup__c s = testMethodUtilities.create('my first git snapshot', 'master', '', g, Date.today(), o);
            insert s;

            Deployment_Flow__c df = new Deployment_Flow__c();
            df.Name = 'Deployment Flow';
            df.Active__c = true;
            insert df;

            Copado_License__c lc = Copado_License__c.getInstance();
            lc.SetupOwnerId = standardUser.Id;
            lc.Enable_CCM__c = true;
            lc.Enable_Copado__c = false;
            upsert lc;

            ApexPages.currentPage().getParameters().put('setOauth',o.Id);

            CopadoSetupController con = new CopadoSetupController();

            //retrieving the org credentials
            con.getExistingOrgCredentials();
            System.assertEquals(7,con.orgCredentialMap.size());

            //refreshing the org credential panels
            con.refreshOrgCredentialList();

            //creating new org credentials
            con.orgCredentials.Name = 'New Org';
            con.orgCredentials.Org_Type__c = 'Production/Developer';
            con.orgCredentials.Test_Frequency__c = 'Daily';
            con.createOrgCredentials();
            con.getExistingOrgCredentials();
            System.assertEquals(8,con.orgCredentialMap.size());

            //set oauth authentication
            con.doOauth();

            //get current user`s api key
            con.getAPIKey();

            //get git repos
            con.getGitRepos();

            //get git snapshots depend on the selected git repos
            con.selectedGitRepositories = 'none';
            con.getsGitSnapshots();  // it will cover if condition
            con.selectedGitRepositories = g.Id;
            con.getsGitSnapshots(); // it will cover else condition

            //open new git snapshot form
            con.openGitSnapshotForm();

            //creating new git snapshot
            con.createGitSnapshot(); // returned becuase name is null
            System.assertEquals(null,con.gitSnapshot.Name);
            con.gitSnapshot.Name = 'Git Snapshot';
            con.createGitSnapshot(); // returned because branch is null
            System.assertEquals(null,con.gitSnapshot.Branch__c);
            con.gitSnapshot.Branch__c = 'master';
            con.createGitSnapshot(); // returned because permission is null
            System.assertEquals(null,con.gitSnapshot.Git_Snapshot_Permissions__c);
            con.gitSnapshot.Git_Snapshot_Permissions__c = 'Allow Commit Only';
            con.createGitSnapshot(); // returned because org credential is null
            System.assertEquals(null,con.gitSnapshot.Org__c);
            con.gitSnapshot.Org__c = o.Id;
            con.createGitSnapshot(); // inserted git snapshot successfully

            //get deployment flows
            con.getDeploymentFlows();

            //get deployment flow steps depend on selected deployment flow
            con.selectedDeploymentFlow = 'none';
            con.getsDeploymentFlowSteps(); // covers if condition

            //open new deployment flow form
            con.openDeploymentFlowForm();

            //create new deployment flow
            con.createDeploymentFlow(); // returned becuase name is null
            System.assertEquals(null,con.deploymentFlow.Name);
            con.deploymentFlow.Name = 'New Deployment Flow';
            con.createDeploymentFlow(); // inserted deployment flow successfully

            //get deployment flow steps depend on selected deployment flow to cover else condition
            con.selectedDeploymentFlow = df.Id;
            con.getsDeploymentFlowSteps(); // covers else

            //open new deployment flow step to create new one
            con.openDeploymentFlowStepForm();

            //insert deployment flow step
            con.createDeploymentFlowSteps();

            //close deployment flow form
            con.closeDeploymentFlowForm();

            //close deployment flow step form
            con.closeDeploymentFlowStepsForm();

            //close git snapshot form
            con.closeGitSnapshotForm();
            Test.stopTest();
        }
    }

    /**
     * Test Pipeline with Calculated based on "Branch". If pipeline is active or not, is not relevant for this test due to, the result will be the same.
     */
    @IsTest 
    static void testPipelineBranchBased() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        Deployment_Flow__c assertPipeline = [SELECT Id, Name FROM Deployment_Flow__c WHERE Name = 'MyPipeline 0'];
        System.runAs(standardUser) {
            Test.startTest();
            PageReference gettingStartedPage = Page.GettingStarted;
            Test.setCurrentPage(gettingStartedPage);

            CopadoSetupController gettingStartedController = new CopadoSetupController();
            List<SelectOption> returnedPipelines = gettingStartedController.getDeploymentFlows();
            System.assertEquals(assertPipeline.Id, returnedPipelines[1].getValue(), 'Pipeline id is not correct');
            System.assertEquals(assertPipeline.Name, returnedPipelines[1].getLabel(), 'Pipeline name is not correct');
            
            gettingStartedController.selectedDeploymentFlow = returnedPipelines[1].getValue();
            PageReference manageReleasesPage = gettingStartedController.manageReleases();
            
            PageReference assertBranchManagementPage = Page.BranchManagement;
            assertBranchManagementPage.getParameters().put('id', assertPipeline.Id);
            System.assertEquals(assertBranchManagementPage.getUrl(), manageReleasesPage.getUrl(), 'Returning url is not Branchmanagement or Pipeline Id is not correct');            
            Test.stopTest();
        }
    }

    /**
     * Test Pipeline with Calculated based on "User Story". Pipeline is not active.
     */
    @IsTest 
    static void testPipelineUserStoryBasedNotActive() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        Deployment_Flow__c assertPipeline = [SELECT Id, Name, Active__c, Calculate_Based_on__c FROM Deployment_Flow__c WHERE Name = 'MyPipeline 0'];
        assertPipeline.Calculate_Based_on__c = 'User Story';
        update assertPipeline;

        System.runAs(standardUser) {
            Test.startTest();
            PageReference gettingStartedPage = Page.GettingStarted;
            Test.setCurrentPage(gettingStartedPage);

            CopadoSetupController gettingStartedController = new CopadoSetupController();
            List<SelectOption> returnedPipelines = gettingStartedController.getDeploymentFlows();
            System.assertEquals(assertPipeline.Id, returnedPipelines[1].getValue(), 'Pipeline id is not correct');
            System.assertEquals(assertPipeline.Name, returnedPipelines[1].getLabel(), 'Pipeline name is not correct');
            
            gettingStartedController.selectedDeploymentFlow = returnedPipelines[1].getValue();
            PageReference manageReleasesPage = gettingStartedController.manageReleases();
            
            PageReference assertPipelineManager = Page.PipelineManager;
            assertPipelineManager.getParameters().put('id', assertPipeline.Id);
            assertPipelineManager.getParameters().put('mode', 'diagram');
            System.assertEquals(assertPipelineManager.getUrl(), manageReleasesPage.getUrl(), 'Returning url is not PipelineManager, Pipeline Id, or mode is not correct');            
            Test.stopTest();
        }
    }

    /**
     * Test Pipeline with Calculated based on "User Story". Pipeline is Active.
     */
    @IsTest 
    static void testPipelineIsActiveUserStoryBased() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        System.runAs(standardUser) {
            Test.startTest();
            Deployment_Flow__c assertPipeline = [SELECT Id, Name, Active__c, Calculate_Based_on__c FROM Deployment_Flow__c WHERE Name = 'MyPipeline 0'];
            assertPipeline.Calculate_Based_on__c = 'User Story';
            assertPipeline.Active__c = true;
            update assertPipeline;

            PageReference gettingStartedPage = Page.GettingStarted;
            Test.setCurrentPage(gettingStartedPage);

            CopadoSetupController gettingStartedController = new CopadoSetupController();
            List<SelectOption> returnedPipelines = gettingStartedController.getDeploymentFlows();
            System.assertEquals(assertPipeline.Id, returnedPipelines[1].getValue(), 'Pipeline id is not correct');
            System.assertEquals(assertPipeline.Name  + ' {Active}', returnedPipelines[1].getLabel(), 'Pipeline name is not correct');
            
            gettingStartedController.selectedDeploymentFlow = returnedPipelines[1].getValue();
            PageReference manageReleasesPage = gettingStartedController.manageReleases();
            
            PageReference assertPipelineManager = Page.PipelineManager;
            assertPipelineManager.getParameters().put('id', assertPipeline.Id);
            assertPipelineManager.getParameters().put('mode', 'manager');
            System.assertEquals(assertPipelineManager.getUrl(), manageReleasesPage.getUrl(), 'Returning url is not PipelineManager, Pipeline Id, or mode is not correct');            
            Test.stopTest();
        }
    }
}