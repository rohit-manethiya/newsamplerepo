@isTest
private class TestComplianceScanResultTriggerHandler {
    @testSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @isTest
    static void environmentScanResult() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                Environment__c = environments[0].Id
            );
            insert complianceScanResult;

            Test.setCreatedDate(complianceScanResult.Id, Datetime.now().addDays(-2));
            complianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :complianceScanResult.Id
            ];
            update complianceScanResult;

            Environment__c environment = [
                SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c
                FROM Environment__c
                WHERE Id = :environments[0].Id
            ];
            System.assertEquals(complianceScanResult.Status__c, environment.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, environment.Last_Compliance_Scan_Date__c);

            Compliance_Scan_Result__c newComplianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'In Progress',
                Environment__c = environments[0].Id
            );
            insert newComplianceScanResult;
            Test.setCreatedDate(newComplianceScanResult.Id, Datetime.now().addMinutes(-5));
            newComplianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :newComplianceScanResult.Id
            ];
            update newComplianceScanResult;

            Test.startTest();
            environment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :environments[0].Id];
            System.assertEquals(newComplianceScanResult.Status__c, environment.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, environment.Last_Compliance_Scan_Date__c);

            newComplianceScanResult.Status__c = 'Completed - Resolved';
            update newComplianceScanResult;
            environment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :environments[0].Id];
            System.assertEquals(newComplianceScanResult.Status__c, environment.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, environment.Last_Compliance_Scan_Date__c);

            delete newComplianceScanResult;
            environment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :environments[0].Id];
            System.assertEquals(complianceScanResult.Status__c, environment.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, environment.Last_Compliance_Scan_Date__c);

            delete complianceScanResult;
            environment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :environments[0].Id];
            System.assertEquals(null, environment.Compliance_Status__c);
            System.assertEquals(null, environment.Last_Compliance_Scan_Date__c);
            Test.stopTest();
        }
    }

    @isTest
    static void orgScanResult() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                Org_Credential__c = orgs[0].Id
            );
            insert complianceScanResult;

            Test.setCreatedDate(complianceScanResult.Id, Datetime.now().addDays(-2));
            complianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :complianceScanResult.Id
            ];
            update complianceScanResult;

            Org__c org = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgs[0].Id];
            System.assertEquals(complianceScanResult.Status__c, org.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, org.Last_Compliance_Scan_Date__c);

            Compliance_Scan_Result__c newComplianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'In Progress',
                Org_Credential__c = orgs[0].Id
            );
            insert newComplianceScanResult;
            Test.setCreatedDate(newComplianceScanResult.Id, Datetime.now().addMinutes(-5));
            newComplianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :newComplianceScanResult.Id
            ];
            update newComplianceScanResult;

            Test.startTest();
            org = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgs[0].Id];
            System.assertEquals(newComplianceScanResult.Status__c, org.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, org.Last_Compliance_Scan_Date__c);

            newComplianceScanResult.Status__c = 'Completed - Resolved';
            update newComplianceScanResult;
            org = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgs[0].Id];
            System.assertEquals(newComplianceScanResult.Status__c, org.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, org.Last_Compliance_Scan_Date__c);

            delete newComplianceScanResult;
            org = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgs[0].Id];
            System.assertEquals(complianceScanResult.Status__c, org.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, org.Last_Compliance_Scan_Date__c);

            delete complianceScanResult;
            org = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgs[0].Id];
            System.assertEquals(null, org.Compliance_Status__c);
            System.assertEquals(null, org.Last_Compliance_Scan_Date__c);
            Test.stopTest();
        }
    }

    @isTest
    static void userStoryScanResult() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, environments[0].Id, orgs[0].Id);
            insert userStory;

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                User_Story__c = userStory.Id
            );
            insert complianceScanResult;

            Test.setCreatedDate(complianceScanResult.Id, Datetime.now().addDays(-2));
            complianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :complianceScanResult.Id
            ];
            update complianceScanResult;

            userStory = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(complianceScanResult.Status__c, userStory.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, userStory.Last_Compliance_Scan_Date__c);

            Compliance_Scan_Result__c newComplianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'In Progress',
                User_Story__c = userStory.Id
            );
            insert newComplianceScanResult;
            Test.setCreatedDate(newComplianceScanResult.Id, Datetime.now().addMinutes(-5));
            newComplianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :newComplianceScanResult.Id
            ];

            Test.startTest();
            update newComplianceScanResult;

            userStory = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(newComplianceScanResult.Status__c, userStory.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, userStory.Last_Compliance_Scan_Date__c);

            newComplianceScanResult.Status__c = 'Completed - Resolved';
            update newComplianceScanResult;
            userStory = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(newComplianceScanResult.Status__c, userStory.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, userStory.Last_Compliance_Scan_Date__c);

            delete newComplianceScanResult;
            userStory = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(complianceScanResult.Status__c, userStory.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, userStory.Last_Compliance_Scan_Date__c);

            delete complianceScanResult;
            userStory = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(null, userStory.Compliance_Status__c);
            System.assertEquals(null, userStory.Last_Compliance_Scan_Date__c);
            Test.stopTest();
        }
    }

    @isTest
    static void gitBackupScanResult() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Git Backup creation
            Git_Backup__c snapshot = TestDataFactory.createGitBackup('test snapshot', orgs[2].Id, gitRepository.Id);
            insert snapshot;

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                Git_Snapshot__c = snapshot.Id
            );
            insert complianceScanResult;

            Test.setCreatedDate(complianceScanResult.Id, Datetime.now().addDays(-2));
            complianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :complianceScanResult.Id
            ];
            update complianceScanResult;

            snapshot = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :snapshot.Id];
            System.assertEquals(complianceScanResult.Status__c, snapshot.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, snapshot.Last_Compliance_Scan_Date__c);

            Compliance_Scan_Result__c newComplianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'In Progress',
                Git_Snapshot__c = snapshot.Id
            );
            insert newComplianceScanResult;
            Test.setCreatedDate(newComplianceScanResult.Id, Datetime.now().addMinutes(-5));
            newComplianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :newComplianceScanResult.Id
            ];
            update newComplianceScanResult;

            Test.startTest();
            snapshot = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :snapshot.Id];
            System.assertEquals(newComplianceScanResult.Status__c, snapshot.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, snapshot.Last_Compliance_Scan_Date__c);

            newComplianceScanResult.Status__c = 'Completed - Resolved';
            update newComplianceScanResult;
            snapshot = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :snapshot.Id];
            System.assertEquals(newComplianceScanResult.Status__c, snapshot.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, snapshot.Last_Compliance_Scan_Date__c);

            delete newComplianceScanResult;
            snapshot = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :snapshot.Id];
            System.assertEquals(complianceScanResult.Status__c, snapshot.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, snapshot.Last_Compliance_Scan_Date__c);

            delete complianceScanResult;
            snapshot = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :snapshot.Id];
            System.assertEquals(null, snapshot.Compliance_Status__c);
            System.assertEquals(null, snapshot.Last_Compliance_Scan_Date__c);
            Test.stopTest();
        }
    }

    @isTest
    static void deploymentScanResult() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgs[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            Compliance_Scan_Result__c complianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'Completed - Findings detected',
                Deployment__c = deployment.Id
            );
            insert complianceScanResult;

            Test.setCreatedDate(complianceScanResult.Id, Datetime.now().addDays(-2));
            complianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :complianceScanResult.Id
            ];
            update complianceScanResult;

            deployment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deployment.Id];
            System.assertEquals(complianceScanResult.Status__c, deployment.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, deployment.Last_Compliance_Scan_Date__c);

            Compliance_Scan_Result__c newComplianceScanResult = new Compliance_Scan_Result__c(
                Status__c = 'In Progress',
                Deployment__c = deployment.Id
            );
            insert newComplianceScanResult;
            Test.setCreatedDate(newComplianceScanResult.Id, Datetime.now().addMinutes(-5));
            newComplianceScanResult = [
                SELECT Id, CreatedDate, LastModifiedDate, Status__c
                FROM Compliance_Scan_Result__c
                WHERE Id = :newComplianceScanResult.Id
            ];
            update newComplianceScanResult;

            Test.startTest();
            deployment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deployment.Id];
            System.assertEquals(newComplianceScanResult.Status__c, deployment.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, deployment.Last_Compliance_Scan_Date__c);

            newComplianceScanResult.Status__c = 'Completed - Resolved';
            update newComplianceScanResult;
            deployment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deployment.Id];
            System.assertEquals(newComplianceScanResult.Status__c, deployment.Compliance_Status__c);
            System.assertEquals(newComplianceScanResult.CreatedDate, deployment.Last_Compliance_Scan_Date__c);

            delete newComplianceScanResult;
            deployment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deployment.Id];
            System.assertEquals(complianceScanResult.Status__c, deployment.Compliance_Status__c);
            System.assertEquals(complianceScanResult.CreatedDate, deployment.Last_Compliance_Scan_Date__c);

            delete complianceScanResult;
            deployment = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deployment.Id];
            System.assertEquals(null, deployment.Compliance_Status__c);
            System.assertEquals(null, deployment.Last_Compliance_Scan_Date__c);
            Test.stopTest();
        }
    }
}