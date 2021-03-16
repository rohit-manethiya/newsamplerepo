@isTest
private class TestFeatureHelper {

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
    private static final String MERGE_STRING = 'merge';
    
    @TestSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
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
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, DEV_2)
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
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
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_1)
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, DEV_2)
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c dev1Org = new Org__c();
            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'Dev1 0' {
                        dev1Org = org;
                    }
                }
            }

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

            ITestDefaults userStoryDefaults = new CopadoPromotionTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Project__c, project.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, dev1Org.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.OwnerId, standardUser.Id)
                .setIncrementalFields(new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                    User_Story__c.SObjectType => new Set<Schema.SObjectField>{User_Story__c.User_Story_Title__c}
                })
                .setDataSize(User_Story__c.SObjectType, 4)
                .generateDefaults()
                .executeDML();
        }
    }
 
    static testMethod void productionEnvironmentCalculationGeneralTest() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            Test.startTest();
            List<Environment__c> environments = [SELECT Id, Name, Type__c FROM Environment__c LIMIT 1000];
            System.debug('**f**environments : ' + environments);

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : environments) {
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
    
            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(dev1Environment.Id, stagingEnvironment.Id, deploymentFlow.Id, '');
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(dev2Environment.Id, stagingEnvironment.Id, deploymentFlow.Id, '');
            Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(stagingEnvironment.Id, productionEnvironment.Id, deploymentFlow.Id, '');
            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>{
                    deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3
            };
            insert deploymentFlowSteps;

            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();

            Test.stopTest();

            Integer numberOfProductionEnvironment = FeatureManagement.checkPackageIntegerValue('Number_of_Prod_Envs');
            System.assertEquals(2, numberOfProductionEnvironment, 'Value 2, because we have one active pipeline created in test method and one will come from test setup');
        }
    }

    static testMethod void productionEnvironmentCalculationInsertNotActivePipeline() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            Test.startTest();
            List<Environment__c> environments = [SELECT Id, Name FROM Environment__c LIMIT 1000];

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : environments) {
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
    
            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', false, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(dev1Environment.Id, stagingEnvironment.Id, deploymentFlow.Id, '');
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(dev2Environment.Id, stagingEnvironment.Id, deploymentFlow.Id, '');
            Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(stagingEnvironment.Id, productionEnvironment.Id, deploymentFlow.Id, '');
            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>{
                    deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3
            };
            insert deploymentFlowSteps;

            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();

            Test.stopTest();

            Integer numberOfProductionEnvironment = FeatureManagement.checkPackageIntegerValue('Number_of_Prod_Envs');
            System.assertEquals(1, numberOfProductionEnvironment, 'Value 1, because we have one active pipeline created in test method, the one we created is not active so not considered in calculation');
        }
    }

    static testMethod void productionEnvironmentCalculationDeletePipeline() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            Test.startTest();
            List<Deployment_Flow__c> pipelines = [SELECT Id FROM Deployment_Flow__c LIMIT 1000];
            delete pipelines;

            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();

            Test.stopTest();

            Integer numberOfProductionEnvironment = FeatureManagement.checkPackageIntegerValue('Number_of_Prod_Envs');
            System.assertEquals(1, numberOfProductionEnvironment, 'Value 1, there are no pipeline and the default value of the feature parameter is 1');
        }
    }

    static testMethod void productionEnvironmentCalculationNewPipelineWithSandboxEnvironment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

        System.runAs(standardUser) {
            Test.startTest();
            //Environment creation
            Environment__c environment1 = TestDataFactory.createEnvironments('Environment 1', 'Sandbox');
            Environment__c environment2 = TestDataFactory.createEnvironments('Environment 2', 'Sandbox');
            Environment__c environment3 = TestDataFactory.createEnvironments('Environment 3', 'Sandbox');
            List<Environment__c> environments = new List<Environment__c>{
                environment1, environment2, environment3
            };
            insert environments;

            // Org Credential creation
            Org__c org1 = TestDataFactory.createOrgCredentials(standardUser.Username, environment1.Id, 'Sandbox');
            Org__c org2 = TestDataFactory.createOrgCredentials(standardUser.Username, environment2.Id, 'Sandbox');
            Org__c org3 = TestDataFactory.createOrgCredentials(standardUser.Username, environment3.Id, 'Sandbox');
            List<Org__c> orgs = new List<Org__c>{
                org1, org2, org3
            };
            insert orgs;

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(environment1.Id, environment3.Id, deploymentFlow.Id, '');
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(environment2.Id, environment3.Id, deploymentFlow.Id, '');
            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>{
                    deploymentFlowStep1, deploymentFlowStep2
            };
            insert deploymentFlowSteps;

            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();

            Test.stopTest();

            Integer numberOfProductionEnvironment = FeatureManagement.checkPackageIntegerValue('Number_of_Prod_Envs');
            System.assertEquals(1, numberOfProductionEnvironment, 'Value 1, because we have one active pipeline created in test setup and the one we created in the test method is not counted because it is sandbox');
        }
    }
 
    static testMethod void isChangeManagementEnabled() {
        System.assertEquals(true,FeatureHelper.isChangeChangeManagementEnabled());
    }
 
    static testMethod void isComplianceHubEnabled() {
        System.assertEquals(true,FeatureHelper.isComplianceHubEnabled());
    }
 
    static testMethod void isSeleniumEnabled() {
        System.assertEquals(true,FeatureHelper.isFeatureEnabled('Selenium Testing'));
    }
 
    static testMethod void isCopadoEnabled() {
        System.assertEquals(true,FeatureHelper.isFeatureEnabled('Git Backup'));
        System.assertEquals(true,FeatureHelper.isFeatureEnabled('Git MetaData'));
    }
}