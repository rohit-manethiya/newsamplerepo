@isTest
public class TestDeploymentFlowTrigger {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(1, 1, 1, 1, 1, 2);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    public class MyTestClassException extends Exception {
    }
    static testMethod void featureNotEnabled() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(Name = 'test', Active__c = false);
            try {
                insert deploymentFlow;
                System.assert(deploymentFlow.Id != null);
            } catch (Exception e) {
                System.assert(false, 'Exception thrown: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }
    static testMethod void featureLimitExceeded_inserts() {
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
                    Deployment_Flow__c = deploymentflow.Id,
                    Branch__c = 'dev1',
                    Source_Environment__c = environments[0].Id,
                    Destination_Environment__c = environments[1].Id
                )
            );
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentflow.Id,
                    Branch__c = 'dev2',
                    Source_Environment__c = environments[1].Id,
                    Destination_Environment__c = environments[2].Id
                )
            );
            try {
                insert deploymentFlowSteps;
                System.assert(true, 'No expections thrown (expected)');
            } catch (Exception e) {
                System.assert(false, 'Exception thrown 1: ' + e.getMessage());
            }

            // Insert an inactive flow which should not trigger the exception.
            try {
                deploymentFlow = new Deployment_Flow__c(Name = 'test', Active__c = false);
                insert deploymentFlow;
                System.assert(true, 'No expections thrown (expected)');
            } catch (Exception e) {
                System.assert(false, '');
            }
            // Insert an active flow (we are now over the limit), so an exception must be triggered.
            try {
                deploymentFlow = new Deployment_Flow__c(
                    Name = 'test',
                    Active__c = true,
                    Main_Branch__c = 'master',
                    Git_Repository__c = gitRepository.Id
                );
                insert deploymentFlow;
                Deployment_Flow_Step__c deploymentFlowstep = new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Branch__c = 'dev1',
                    Source_Environment__c = environments[0].Id,
                    Destination_Environment__c = environments[1].Id
                );
                insert deploymentFlowstep;

                System.assert(false, 'Should not have reached this code.');
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_LICENSE_EXCEEDED) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }
    static testMethod void featureLimitExceeded_update() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test');
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = new Deployment_Flow__c(
                Name = 'test',
                Active__c = false,
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
            deploymentFlowSteps.add(
                new Deployment_Flow_Step__c(
                    Deployment_Flow__c = deploymentFlow.Id,
                    Branch__c = 'dev3',
                    Source_Environment__c = environments[2].Id,
                    Destination_Environment__c = environments[3].Id
                )
            );
            insert deploymentFlowSteps;

            // Update an inactive flow (we are now over the limit), so an exception must be triggered.
            try {
                deploymentFlow.Active__c = true;
                update deploymentFlow;
                System.assert(false, 'Should not have reached this code.');
            } catch (DmlException e) {
                Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_LICENSE_EXCEEDED) ? true : false;
                System.debug('Actual Message thrown 5: ' + e.getMessage());
                System.AssertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }
}