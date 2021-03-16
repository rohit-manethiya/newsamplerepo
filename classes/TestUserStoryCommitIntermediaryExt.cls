@isTest
private class TestUserStoryCommitIntermediaryExt {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @testSetup static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    static testMethod void scenario0NoSnapshotsFound() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, ext.showError, 'No snapshots should be found, hence showError=true.');
            system.assertEquals(false, ext.showOptions, 'Expecting false because showError is true');
            Test.stopTest();
        }
    }
    static testMethod void scenario1SnapshotsFoundForEnvironment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            List<Org__c> orgCredes = new List<Org__c>();
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            Org__c devorgCredential = testMethodUtilities.createOrg('Copado Dev Org', 'Production/Developer', '', null, null, DateTime.now());
            orgCredes.add(orgCredential);
            orgCredes.add(devorgCredential);
            insert orgCredes;
            orgCredes.clear();
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            devorgCredential.SFDC_Org_ID__c = '00D24000000aZxJFAE_005240000013JyBAAU';
            orgCredes.add(orgCredential);
            orgCredes.add(devorgCredential);
            update orgCredes;
            orgCredential = Utilities.getOrgById(orgCredential.Id);
            Map<String, Environment__c> environments = new Map<String, Environment__c>();
            for(Environment__c env : [select Id, Name,Org_ID__c from Environment__c limit 2]) {
                environments.put(env.Org_ID__c, env);
            }
            system.assertEquals(2, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Git_Backup__c snapshot1 = testMethodUtilities.create('My Snapshot1', 'master', 'None', gitRepo, Date.today(), devorgCredential);
            insert snapshot1;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(environments.get(devorgCredential.SFDC_Org_ID__c.substring(0, 18)).Id, environments.get(orgCredential.SFDC_Org_ID__c.substring(0, 18)).Id, flow.Id);
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = devorgCredential.Id;
            story1.Environment__c = environments.get(devorgCredential.SFDC_Org_ID__c.substring(0, 18)).Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            ext.getOptions();
            system.assertEquals(1, ext.snapshots.size());
            system.assertEquals(snapshot1.Id, ext.snapshotId, 'The ID of the snapshot Id was not set.');
            system.assertEquals(snapshot1.Git_Repository__c, ext.repoId);
            system.assertEquals(snapshot1.Org__c, ext.orgId);
            system.assertEquals(false, ext.showError, '1 snapshots should be found, hence showError=false.');
            system.assertEquals(false, ext.showOptions, 'Expecting false because we have a match on Environment hence we will redirect.');
            Test.stopTest();
        }
    }
    static testMethod void scenario2MoreThan1SnapshotsFound() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Git_Backup__c snapshot1 = testMethodUtilities.create('My Snapshot1', 'master', 'None', gitRepo, Date.today(), orgCredential);
            insert snapshot1;
            Git_Backup__c snapshot2 = testMethodUtilities.create('My Snapshot2', 'dev', 'None', gitRepo, Date.today(), orgCredential);
            insert snapshot2;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(2, ext.snapshots.size());
            system.assertEquals('', ext.snapshotId, 'The ID of the snapshot Id was not set.');
            system.assertEquals(false, ext.showError, '1 snapshots should be found, hence showError=false.');
            system.assertEquals(true, ext.showOptions, 'Expecting true because we have more than one snapshot');
            Test.stopTest();
        }
    }
    static testMethod void scenario3SnapshotsPermissionsFiltering() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Git_Backup__c snapshot1 = testMethodUtilities.create('My Snapshot1', 'master', 'None', gitRepo, Date.today(), orgCredential);
            snapshot1.Git_Snapshot_Permissions__c = 'Allow Snapshots Only';
            Git_Backup__c snapshot2 = testMethodUtilities.create('My Snapshot2', 'dev', 'None', gitRepo, Date.today(), orgCredential);
            snapshot2.Git_Snapshot_Permissions__c = 'Allow Commits Only';
            insert new List<Git_Backup__c>{ snapshot1, snapshot2 };
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(1, ext.snapshots.size());
            system.assertEquals(snapshot2.Id, ext.snapshotId, 'The ID of the snapshot Id was not set right.');
            system.assertEquals(snapshot1.Git_Repository__c, ext.repoId);
            system.assertEquals(snapshot1.Org__c, ext.orgId);
            system.assertEquals(false, ext.showError, '1 snapshots should be found, (because of permissions) hence showError=false.');
            system.assertEquals(false, ext.showOptions, 'Expecting false only 1 match should be found due to permissions being set, hence we will redirect.');
            Test.stopTest();
        }
    }
    static testMethod void testExceptionHandling() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            orgCredential = Utilities.getOrgById(orgCredential.Id);
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = '00D24000000aZrZEAU' limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = new Git_Repository__c(name = 'g');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', false);
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            insert new List<Deployment_Flow__c>{ flow, flowCBM };
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            Release__c testRelease = CMTestMethodUtilities.createRelease('My Test Release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Linked To A Project');
            User_Story__c story2 = CMTestMethodUtilities.createUserStory('My User Story Linked To A Release');
            insert new List<User_Story__c>{ story1, story2 };
            Test.startTest();
            UserStoryCommitIntermediaryExt ext2 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, ext2.showError, 'No Snapshot set, hence showError=true.');
            system.assertEquals(false, ext2.showOptions, 'No Snapshot set, so only show error message... hence expecting false.');
            system.assertEquals(0, ext2.snapshots.size());
            system.assertEquals('', ext2.snapshotId, 'The ID of the snapshot should be empty because we are only showing errors.');
            system.assertEquals(false, testMethodUtilities.hasMessage(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND));
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            story2.Org_Credential__c = orgCredential.Id;
            story2.Environment__c = environments[0].Id;
            story2.Release__c = testRelease.Id;
            update new List<User_Story__c>{ story1, story2 };
            // Project linked to an inactive deployment flow
            UserStoryCommitIntermediaryExt ext3 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assertEquals(false, ext3.flowDetails.flow.Active__c);
            // Release linked to an inactive deployment flow
            UserStoryCommitIntermediaryExt ext4 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story2));
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assertEquals(false, ext4.flowDetails.flow.Active__c);
            // Valid CBMFlow
            testProject.Deployment_Flow__c = flowCBM.Id;
            update testProject;
            UserStoryCommitIntermediaryExt ext5 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            System.assertEquals(true, ext5.flowDetails.isCBMFlow);
            System.assertEquals(false, testMethodUtilities.hasMessage(Label.MISSING_PERMISSIONS_CBM_FLOW));
            // Blocked Commits
            flowCBM.Block_Commits__c = true;
            update flowCBM;
            UserStoryCommitIntermediaryExt ext6 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            System.assertEquals(true, ext6.flowDetails.flow.Block_Commits__c);
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED));
            Test.stopTest();
        }
    }
    static testMethod void testMainBranchAssignment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            orgCredential = Utilities.getOrgById(orgCredential.Id);
            List<Environment__c> environments = [SELECT Id, Name FROM Environment__c WHERE Org_ID__c = '00D24000000aZrZEAU' LIMIT 1];
            System.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = new Git_Repository__c(name = 'Git Repository 1');
            insert gitRepo;
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
            insert flowCBM;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            insert testProject;
            Release__c testRelease = CMTestMethodUtilities.createRelease('My Test Release');
            testRelease.Project__c = testProject.Id;
            insert testRelease;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Linked To A Release');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Release__c = testRelease.Id;
            insert story1;
            Test.startTest();
            // Valid CBMFlow
            UserStoryCommitIntermediaryExt ext1 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            System.assertEquals(true, ext1.flowDetails.isCBMFlow);
            System.assertEquals(flowCBM.Main_Branch__c, ext1.mainBranch);
            // Main Branch from User Story Base Branch
            story1.Base_Branch__c = 'int';
            update story1;
            UserStoryCommitIntermediaryExt ext2 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            System.assertEquals(ext2.userStory.Base_Branch__c, ext2.mainBranch);
            Test.stopTest();
        }
    }
    static testMethod void testPageWithoutUserStory() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Test.startTest();
            UserStoryCommitIntermediaryExt ext1 = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(new User_Story__c()));
            system.assertEquals(true, testMethodUtilities.hasMessage(Label.USER_STORY_COMMIT_NO_USER_STORY));
            Test.stopTest();
        }
    }
    static testMethod void testPageFeatureNotEnabled() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Git_Backup__c snapshot1 = testMethodUtilities.create('My Snapshot1', 'master', 'None', gitRepo, Date.today(), orgCredential);
            snapshot1.Git_Snapshot_Permissions__c = 'Allow Snapshots Only';
            Git_Backup__c snapshot2 = testMethodUtilities.create('My Snapshot2', 'dev', 'None', gitRepo, Date.today(), orgCredential);
            snapshot2.Git_Snapshot_Permissions__c = 'Allow Commits Only';
            insert new List<Git_Backup__c>{ snapshot1, snapshot2 };
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            TestUtilities.enableLicenses(0, 0, 0, 0, 0, 0);
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, testMethodUtilities.hasMessage(Label.FEATURE_NOT_SUPPORTED));
            Test.stopTest();
        }
    }
    static testMethod void testPageUserStoryWithoutOrgAndEnvironment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Git_Backup__c snapshot1 = testMethodUtilities.create('My Snapshot1', 'master', 'None', gitRepo, Date.today(), orgCredential);
            snapshot1.Git_Snapshot_Permissions__c = 'Allow Snapshots Only';
            Git_Backup__c snapshot2 = testMethodUtilities.create('My Snapshot2', 'dev', 'None', gitRepo, Date.today(), orgCredential);
            snapshot2.Git_Snapshot_Permissions__c = 'Allow Commits Only';
            insert new List<Git_Backup__c>{ snapshot1, snapshot2 };
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, testMethodUtilities.hasMessage(Label.USER_STORY_COMMIT_NO_ENVIRONMENT));
            ext.getAdditionalParams();
            Test.stopTest();
        }
    }
    static testMethod void testPageDXBranchCreate() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Scratch Org', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            Attachment att = new Attachment();
            att.Name = DXLabel.METADATA_SOURCES;
            att.ParentId = orgCredential.Id;
            att.Body = Blob.valueOf('{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}');
            insert att;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, testMethodUtilities.hasMessage('DX Project has not been created would you like to create it?'));
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"copadoJobId":"1458f75f-1c4f-4116-a92f-607fb3fb4bbc","ok":"Job has started!","status":"initializing"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            PageReference expectedUrl = ext.createDXBranch();
            system.assertEquals(null, expectedUrl);
            ApexPages.currentPage().getParameters().put('jobFinished', 'true');
            ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
            ApexPages.currentPage().getParameters().put('jobMessage', '');
            ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH);
            expectedUrl = ext.jobStatusNotification();
            system.assertNotEquals(null, expectedUrl);
            Test.stopTest();
        }
    }
    static testMethod void testPageDXBranchCreateNoSnapshot() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Scratch Org', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            Attachment att = new Attachment();
            att.Name = DXLabel.METADATA_SOURCES;
            att.ParentId = orgCredential.Id;
            att.Body = Blob.valueOf('{"selectedArtifactIDs":[""],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"","isPatch":false,"projectBranchCreated":true}');
            insert att;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, testMethodUtilities.hasMessage(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND));
            Test.stopTest();
        }
    }
    static testMethod void testPageDXBranchCreateFailJob() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true);
        System.runAs(standardUser) {
            Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Scratch Org', '', null, null, DateTime.now());
            insert orgCredential;
            orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
            update orgCredential;
            Attachment att = new Attachment();
            att.Name = DXLabel.METADATA_SOURCES;
            att.ParentId = orgCredential.Id;
            att.Body = Blob.valueOf('{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}');
            insert att;
            List<Environment__c> environments = [select Id, Name from Environment__c where Org_ID__c = :orgCredential.SFDC_Org_ID__c.substring(0, 18) limit 1];
            system.assertEquals(1, environments.size(), 'Environment was not created during Org Credential creation.');
            Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('Main Repo', 'https://gitrepo@git.com');
            insert gitRepo;
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
            flow.Git_Repository__c = gitRepo.Id;
            insert flow;
            Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            User_Story__c story1 = CMTestMethodUtilities.createUserStory('My User Story Title');
            story1.Org_Credential__c = orgCredential.Id;
            story1.Environment__c = environments[0].Id;
            story1.Project__c = testProject.Id;
            insert story1;
            Test.startTest();
            PageReference pref = Page.UserStoryCommitIntermediary;
            pref.getParameters().put('id', story1.id);
            Test.setCurrentPage(pref);
            UserStoryCommitIntermediaryExt ext = new UserStoryCommitIntermediaryExt(new ApexPages.StandardController(story1));
            system.assertEquals(true, testMethodUtilities.hasMessage('DX Project has not been created would you like to create it?'));
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"copadoJobId":"1458f75f-1c4f-4116-a92f-607fb3fb4bbc","ok":"Job has started!","status":"initializing"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            PageReference expectedUrl = ext.createDXBranch();
            system.assertEquals(null, expectedUrl);
            ApexPages.currentPage().getParameters().put('jobFinished', 'false');
            ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
            ApexPages.currentPage().getParameters().put('jobMessage', '');
            ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH);
            expectedUrl = ext.jobStatusNotification();
            system.assertEquals(null, expectedUrl);
            ApexPages.currentPage().getParameters().put('jobFinished', 'true');
            ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
            ApexPages.currentPage().getParameters().put('jobMessage', 'Error');
            ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH);
            expectedUrl = ext.jobStatusNotification();
            system.assertEquals(true, testMethodUtilities.hasMessage('Error'));
            Test.stopTest();
        }
    }
}