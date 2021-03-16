@isTest
private class TestDeployCommits {

    @TestSetup static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    static testMethod void sortList() {
        List<GitHelper.ACommit> commitList = new List<GitHelper.ACommit>();
        commitList.add(new GitHelper.ACommit('today','today', DateTime.now(), 'master'));
        DateTime yesterday = DateTime.now().addDays(-1);
		commitList.add(new GitHelper.ACommit('yesterday','yesterday', yesterday, 'master'));
        DateTime tomorrow = DateTime.now().addDays(1);
		commitList.add(new GitHelper.ACommit('tomorrow','tomorrow', tomorrow, 'master'));
        System.assertEquals('today', commitList.get(0).id);
        System.assertEquals('yesterday', commitList.get(1).id);
        System.assertEquals('tomorrow', commitList.get(2).id);
        commitList.sort();
        System.assertEquals('tomorrow', commitList.get(0).id);
        System.assertEquals('today', commitList.get(1).id);
        System.assertEquals('yesterday', commitList.get(2).id);
    }

    static testMethod void createDeploymentFromGitRepository() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            DateTime yesterday = DateTime.now().addDays(-1);
            DateTime lastTwoYear = DateTime.now().addYears(-2);
            DateTime tomorrow = DateTime.now().addDays(1);
            
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test repo');
            insert gitRepository;

            Git_Commit__c gitCommit1 = new Git_Commit__c(Commit_Id__c = 'today', Commit_Date__c = DateTime.now().date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit2 = new Git_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit3 = new Git_Commit__c(Commit_Id__c = 'tomorrow', Commit_Date__c = tomorrow.date(), Git_Repository__c = gitRepository.Id);
            insert new List<Git_Commit__c>{ gitCommit1, gitCommit2, gitCommit3 };
            
            Org__c org = new Org__c (Name = 'test org');
            insert org;

            Git_Backup__c snapshot = new Git_Backup__c(Name = 'test snapshot', Git_Repository__c = gitRepository.id, Org__c = org.Id);
            insert snapshot;

            Git_Org_Commit__c gitOrgCommit1 = new Git_Org_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            Git_Org_Commit__c gitOrgCommit2 = new Git_Org_Commit__c(Commit_Id__c = 'last 2 year', Commit_Date__c = lastTwoYear.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            insert new List<Git_Org_Commit__c>{ gitOrgCommit1, gitOrgCommit2 };
            
            PageReference pReference = Page.DeployCommits;
            pReference.getParameters().put('repositoryId', gitRepository.Id);
            Test.setCurrentPage(pReference);

            DeployCommits deployCommitController = new DeployCommits();

            Boolean showDeploymentDetail = deployCommitController.getShowDeploy();
            System.assertEquals(false, showDeploymentDetail);

            Boolean showTable = deployCommitController.getShowTable();
            System.assertEquals(true, showTable);
            
            List<GitHelper.ACommit> commitList = deployCommitController.getCommits();
            System.assertEquals(3, commitList.size());
            System.assertEquals('tomorrow', commitList.get(0).id);
            System.assertEquals('today', commitList.get(1).id);
            System.assertEquals('yesterday', commitList.get(2).id);
            
            deployCommitController.dateFrom.Commit_Date__c = lastTwoYear.date();
            commitList = deployCommitController.getCommits();
            System.assertEquals(4, commitList.size());
            System.assertEquals('tomorrow', commitList.get(0).id);
            System.assertEquals('today', commitList.get(1).id);
            System.assertEquals('yesterday', commitList.get(2).id);
            System.assertEquals('last 2 year', commitList.get(3).id);

            deployCommitController.chooseCommit = commitList[0].Id;
            deployCommitController.chooseCommit();
            System.assertEquals(commitList[0].Id, deployCommitController.startCommit);
            System.assertEquals(commitList[0], deployCommitController.startGitCommit);

            deployCommitController.chooseCommit = commitList[1].Id;
            deployCommitController.chooseCommit();
            System.assertEquals(commitList[1].Id, deployCommitController.endCommit);
            System.assertEquals(commitList[1], deployCommitController.endGitCommit);
        }
    }

    static testMethod void createDeploymentFromGitRepositoryAndCancel() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            DateTime yesterday = DateTime.now().addDays(-1);
            DateTime lastTwoYear = DateTime.now().addYears(-2);
            DateTime tomorrow = DateTime.now().addDays(1);
            
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test repo');
            insert gitRepository;

            Git_Commit__c gitCommit1 = new Git_Commit__c(Commit_Id__c = 'today', Commit_Date__c = DateTime.now().date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit2 = new Git_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit3 = new Git_Commit__c(Commit_Id__c = 'tomorrow', Commit_Date__c = tomorrow.date(), Git_Repository__c = gitRepository.Id);
            insert new List<Git_Commit__c>{ gitCommit1, gitCommit2, gitCommit3 };
            
            Org__c org = new Org__c (Name = 'test org');
            insert org;

            Git_Backup__c snapshot = new Git_Backup__c(Name = 'test snapshot', Git_Repository__c = gitRepository.id, Org__c = org.Id);
            insert snapshot;

            Git_Org_Commit__c gitOrgCommit1 = new Git_Org_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            Git_Org_Commit__c gitOrgCommit2 = new Git_Org_Commit__c(Commit_Id__c = 'last 2 year', Commit_Date__c = lastTwoYear.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            insert new List<Git_Org_Commit__c>{ gitOrgCommit1, gitOrgCommit2 };
            
            PageReference pReference = Page.DeployCommits;
            pReference.getParameters().put('repositoryId', gitRepository.Id);
            Test.setCurrentPage(pReference);

            DeployCommits deployCommitController = new DeployCommits();

            Boolean showDeploymentDetail = deployCommitController.getShowDeploy();
            System.assertEquals(false, showDeploymentDetail);

            Boolean showTable = deployCommitController.getShowTable();
            System.assertEquals(true, showTable);

            PageReference returnedPage = deployCommitController.cancel();
            PageReference expectedPage = new ApexPages.StandardController(deployCommitController.repo).view();
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

        }
    }

    static testMethod void createDeploymentFromGitRepositoryWithStandardController() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            DateTime yesterday = DateTime.now().addDays(-1);
            DateTime lastTwoYear = DateTime.now().addYears(-2);
            DateTime tomorrow = DateTime.now().addDays(1);
            
            Git_Repository__c gitRepository = new Git_Repository__c(Name = 'test repo');
            insert gitRepository;

            Git_Commit__c gitCommit1 = new Git_Commit__c(Commit_Id__c = 'today', Commit_Date__c = DateTime.now().date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit2 = new Git_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Repository__c = gitRepository.Id);
            Git_Commit__c gitCommit3 = new Git_Commit__c(Commit_Id__c = 'tomorrow', Commit_Date__c = tomorrow.date(), Git_Repository__c = gitRepository.Id);
            insert new List<Git_Commit__c>{ gitCommit1, gitCommit2, gitCommit3 };
            
            Org__c org = new Org__c (Name = 'test org');
            insert org;

            Git_Backup__c snapshot = new Git_Backup__c(Name = 'test snapshot', Git_Repository__c = gitRepository.id, Org__c = org.Id);
            insert snapshot;

            Git_Org_Commit__c gitOrgCommit1 = new Git_Org_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yesterday.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            Git_Org_Commit__c gitOrgCommit2 = new Git_Org_Commit__c(Commit_Id__c = 'last 2 year', Commit_Date__c = lastTwoYear.date(), Git_Backup__c = snapshot.Id, org__c = org.Id, Status__c = 'Complete');
            insert new List<Git_Org_Commit__c>{ gitOrgCommit1, gitOrgCommit2 };
            
            PageReference pReference = Page.DeployCommits;
            pReference.getParameters().put('repositoryId', gitRepository.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(new Deployment__c());
            DeployCommits deployCommitController = new DeployCommits(sc);

            Boolean showDeploymentDetail = deployCommitController.getShowDeploy();
            System.assertEquals(false, showDeploymentDetail);

            Boolean showTable = deployCommitController.getShowTable();
            System.assertEquals(true, showTable);
            
            List<GitHelper.ACommit> commitList = deployCommitController.getCommits();
            System.assertEquals(3, commitList.size());
            System.assertEquals('tomorrow', commitList.get(0).id);
            System.assertEquals('today', commitList.get(1).id);
            System.assertEquals('yesterday', commitList.get(2).id);
            
            deployCommitController.dateFrom.Commit_Date__c = lastTwoYear.date();
            commitList = deployCommitController.getCommits();
            System.assertEquals(4, commitList.size());
            System.assertEquals('tomorrow', commitList.get(0).id);
            System.assertEquals('today', commitList.get(1).id);
            System.assertEquals('yesterday', commitList.get(2).id);
            System.assertEquals('last 2 year', commitList.get(3).id);

            deployCommitController.chooseCommit = commitList[0].Id;
            deployCommitController.chooseCommit();
            System.assertEquals(commitList[0].Id, deployCommitController.startCommit);
            System.assertEquals(commitList[0], deployCommitController.startGitCommit);

            deployCommitController.chooseCommit = commitList[1].Id;
            deployCommitController.chooseCommit();
            System.assertEquals(commitList[1].Id, deployCommitController.endCommit);
            System.assertEquals(commitList[1], deployCommitController.endGitCommit);
        }
    }
}