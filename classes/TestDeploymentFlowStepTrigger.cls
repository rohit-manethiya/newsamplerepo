@isTest
public class TestDeploymentFlowStepTrigger {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(1, 1, 1, 1, 1, 2);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    @isTest
    static void BranchMgmtEnabled() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test');
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(
                Name = 'test',
                Active__c = true,
                Main_Branch__c = 'master',
                Git_Repository__c = gitRepository.Id,
                Disable_Validations__c = true
            );
            insert deploymentFlow;
            Test.stopTest();
        }
    }
    static testMethod void testInsertion() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
            Feature__c featrue1 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
            insert new List<Feature__c>{ feature, featrue1 };

            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test');
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(
                Name = 'test',
                Active__c = true,
                Main_Branch__c = 'master',
                Git_Repository__c = gitRepository.Id
            );
            insert deploymentFlow;

            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 6; i++) {
                Environment__c environment = new Environment__c(Name = 'Env' + i);
                environments.add(environment);
            }
            insert environments;

            List<Org__c> orgs = new List<Org__c>();
            for (Integer i = 0; i < 6; i++) {
                Org__c org = new Org__c(Name = 'Org' + i, Environment__c = environments[i].Id);
                orgs.add(org);
            }
            insert orgs;

            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>();
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Branch__c = 'dev1',
                    Source_Environment__c = environments[0].Id,
                    Destination_Environment__c = environments[1].Id
                )
            );
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Branch__c = 'dev2',
                    Source_Environment__c = environments[1].Id,
                    Destination_Environment__c = environments[2].Id
                )
            );

            try {
                insert deploymentFlowSteps;
                system.assert(true, 'Insert successful.');
            } catch (DmlException e) {
                system.assert(false, 'Should not have had an exception during insert of flow step.' + e.getMessage());
            }
            Test.stopTest();
        }
    }
    static testMethod void testUpdate() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test');
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(
                Name = 'test',
                Active__c = true,
                Main_Branch__c = 'master',
                Git_Repository__c = gitRepository.Id,
                Disable_Validations__c = true
            );
            insert deploymentFlow;

            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 6; i++) {
                Environment__c environment = new Environment__c(Name = 'Env' + i);
                environments.add(environment);
            }
            insert environments;

            List<Org__c> orgs = new List<Org__c>();
            for (Integer i = 0; i < 6; i++) {
                Org__c org = new Org__c(Name = 'Org' + i, Environment__c = environments[i].Id);
                orgs.add(org);
            }
            insert orgs;

            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>();
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Branch__c = 'dev1',
                    Source_Environment__c = environments[0].Id,
                    Destination_Environment__c = environments[1].Id
                )
            );
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Source_Environment__c = environments[1].Id,
                    Destination_Environment__c = environments[2].Id
                )
            );
            insert deploymentFlowSteps;
            Test.stopTest();
        }
    }

    static testMethod void validationsTest() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();

            Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
            Feature__c featrue1 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
            insert new List<Feature__c>{ feature, featrue1 };

            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test');
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(
                Name = 'test',
                Active__c = true,
                Main_Branch__c = 'master',
                Git_Repository__c = gitRepository.Id
            );
            insert deploymentFlow;

            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 6; i++) {
                Environment__c environment = new Environment__c(Name = 'Env' + i);
                environments.add(environment);
            }
            insert environments;

            List<Org__c> orgs = new List<Org__c>();
            for (Integer i = 0; i < 6; i++) {
                Org__c org = new Org__c(Name = 'Org' + i, Environment__c = environments[i].Id);
                orgs.add(org);
            }
            insert orgs;

            Deployment_Flow_Step__c deploymentFlowStep1 = new Deployment_Flow_Step__c(
                Deployment_Flow__c = deploymentFlow.Id,
                Branch__c = 'dev1',
                Source_Environment__c = environments[0].Id,
                Destination_Environment__c = environments[2].Id
            );
            Deployment_Flow_Step__c deploymentFlowStep2 = new Deployment_Flow_Step__c(
                Deployment_Flow__c = deploymentFlow.Id,
                Branch__c = 'dev2',
                Source_Environment__c = environments[1].Id,
                Destination_Environment__c = environments[2].Id
            );
            List<Deployment_Flow_Step__c> deploymentFlowSteps = new List<Deployment_Flow_Step__c>();
            deploymentFlowSteps.add(deploymentFlowStep1);
            deploymentFlowSteps.add(deploymentFlowStep2);
            insert deploymentFlowSteps;

            deploymentFlowStep1.Branch__c = 'dev2';
            deploymentFlowStep1.Source_Environment__c = environments[0].Id;
            try {
                update deploymentFlowSteps;
                System.assert(false, 'Should have failed due to repeated branch name.');
            } catch (DmlException e) {
                Boolean expectedExceptionThrown = e.getMessage().contains(Label.REPEATED_BRANCH_NAME) ? true : false;
                System.debug('Actual Message thrown 3: ' + e.getMessage());
                System.assertEquals(expectedExceptionThrown, true);
            }

            deploymentFlowStep1.Branch__c = 'dev1';
            deploymentFlowStep1.Source_Environment__c = environments[1].Id;
            try {
                update deploymentFlowSteps;
                System.assert(false, 'Should have failed due to repeated source Environment.');
            } catch (DmlException e) {
                Boolean expectedExceptionThrown = e.getMessage().contains(Label.REPEATED_SOURCE_ENVIRONMENT) ? true : false;
                System.debug('Actual Message thrown 4: ' + e.getMessage());
                System.assertEquals(expectedExceptionThrown, true);
            }

            deploymentFlowStep1.Branch__c = 'Env0';
            deploymentFlowStep1.Source_Environment__c = environments[0].Id;
            deploymentFlowStep2.Branch__c = 'Env1';
            update deploymentFlowSteps;
            deploymentFlow.Equal_Branch_Environment_Name__c = true;
            update deploymentFlow;
            deploymentFlowStep1.Branch__c = 'dev1';
            deploymentFlowStep1.Source_Environment__c = environments[0].Id;
            try {
                update deploymentFlowSteps;
                System.assert(false, 'Should have failed due to a mismatch between Environment and Branch names.');
            } catch (DmlException e) {
                Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_AND_SOURCE_ENVIRONMENT_EQUALS) ? true : false;
                System.debug('Actual Message thrown 5: ' + e.getMessage());
                System.assertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }
}