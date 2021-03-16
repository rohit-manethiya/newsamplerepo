@IsTest
public with sharing class UserStoryBundleCtrlTest {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void testUserStoryBundleCtrlSelectedUserStories() {
        System.runAs(getUser()) {
            // Setup
            Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>([SELECT Id, Name FROM User_Story__c LIMIT 4]);
            PageReference pageRef = Page.UserStoryBundle;
            Test.setCurrentPage(pageRef);

            // Exercise 1
            ApexPages.StandardSetController userStoryStandardSetController = new ApexPages.StandardSetController(selectedUserStories.values());
            userStoryStandardSetController.setSelected(selectedUserStories.values());
            UserStoryBundleCtrl bundleController = new UserStoryBundleCtrl(userStoryStandardSetController);
            List<String> storyIds = bundleController.stories.remove('"').remove('[').remove(']').split(',');

            // Exercise 2
            List<User_Story__c> stories = UserStoryBundleCtrl.selectedStories(storyIds);

            // Verify
            Set<Id> assertIds = new Set<Id>((List<Id>) storyIds);
            System.assertEquals(selectedUserStories.keySet(), assertIds, 'Ids does not match');
            System.assertEquals(selectedUserStories.values(), stories, 'User Stories does not match');
        }
    }

    @IsTest
    private static void testGetMetadata() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> assertMetadata = testMetadata();
            List<MetaDataItem> assertProfiles = testFullProfiles();
            List<MetaDataItem> assertDestructive = testDestructive();
            Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>([SELECT Id, Name FROM User_Story__c LIMIT 4]);

            // Exercise
            List<String> storyIds = new List<String>((List<String>) new List<Id>(selectedUserStories.keySet()));
            List<MetaDataItem> metadata = UserStoryBundleCtrl.getAllMetadata(storyIds, new List<String>{ 'Commit Files', 'Recommit Files' });
            List<MetaDataItem> fullProfiles = UserStoryBundleCtrl.getAllMetadata(storyIds, new List<String>{ 'Full Profiles & Permission Sets' });
            List<MetaDataItem> destructiveChanges = UserStoryBundleCtrl.getAllMetadata(storyIds, new List<String>{ 'Destructive Changes' });

            // Verify
            System.assertEquals(JSON.serialize(assertMetadata), JSON.serialize(metadata), 'Metadata Items does not match');
            System.assertEquals(JSON.serialize(assertProfiles), JSON.serialize(fullProfiles), 'Profiles and Permission Set Items does not match');
            System.assertEquals(JSON.serialize(assertDestructive), JSON.serialize(destructiveChanges), 'Destructive changes Items does not match');
        }
    }

    @IsTest
    private static void testCreateBundleHappyPath() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> metadata = testMetadata();
            List<MetaDataItem> profiles = testFullProfiles();
            List<MetaDataItem> destructive = testDestructive();

            Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>(
                [SELECT Id, Name, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c LIMIT 4]
            );
            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');

            // Exercise
            String bundleId = UserStoryBundleCtrl.createBundleRecords(bundle, selectedUserStories.values(), metadata, profiles, destructive);
            // Verify
            List<Bundled_UserStory__c> junctionRecords = [SELECT User_Story__c, User_Story_Bundle__c FROM Bundled_UserStory__c];
            List<Attachment> bundleAttachments = [SELECT Name FROM Attachment WHERE ParentId = :bundleId];
            System.assert(String.isNotBlank(bundleId), 'This should be populated');
            System.assertEquals(4, junctionRecords.size(), 'This should be populated');

            for (Bundled_UserStory__c record : junctionRecords) {
                System.assertEquals(bundleId, record.User_Story_Bundle__c, 'Bundle Id does not match');
                System.assert(selectedUserStories.keySet().contains(record.User_Story__c), 'User Story assignation is not correct');
            }
        }
    }

    @IsTest
    private static void testCreateBundleWithoutUS() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> metadata = testMetadata();
            List<MetaDataItem> profiles = testFullProfiles();
            List<MetaDataItem> destructive = testDestructive();

            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');
            List<User_Story__c> stories = new List<User_Story__c>();

            // Exercise
            AuraHandledException ex;
            try {
                UserStoryBundleCtrl.createBundleRecords(bundle, stories, metadata, profiles, destructive);
            } catch (AuraHandledException e) {
                ex = e;
            }

            // Verify
            System.assertEquals(System.Label.USB_WARNING_NO_US_SELECTED, ex.getMessage());

            List<Bundled_UserStory__c> junctionRecords = [SELECT User_Story__c, User_Story_Bundle__c FROM Bundled_UserStory__c];
            System.assertEquals(0, junctionRecords.size(), 'No juntion records should be created');
        }
    }

    @IsTest
    private static void testCreateBundleWithoutCommits() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> metadata = new List<MetaDataItem>();
            List<MetaDataItem> profiles = new List<MetaDataItem>();
            List<MetaDataItem> destructive = new List<MetaDataItem>();

            List<User_Story__c> selectedUserStories = [SELECT Id, Name, Environment__c FROM User_Story__c LIMIT 2];
            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');

            // Exercise
            AuraHandledException ex;
            try {
                UserStoryBundleCtrl.createBundleRecords(bundle, selectedUserStories, metadata, profiles, destructive);
            } catch (AuraHandledException e) {
                ex = e;
            }

            // Verify
            System.assertEquals(System.Label.USB_WARNING_NO_COMMITS, ex.getMessage());

            List<Bundled_UserStory__c> junctionRecords = [SELECT User_Story__c, User_Story_Bundle__c FROM Bundled_UserStory__c];
            System.assertEquals(0, junctionRecords.size(), 'No juntion records should be created');
        }
    }

    @IsTest
    private static void testCreateBundleWithMultipleEnvironmentsInUS() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> metadata = testMetadata();
            List<MetaDataItem> profiles = testFullProfiles();
            List<MetaDataItem> destructive = testDestructive();

            List<User_Story__c> selectedUserStories = [
                SELECT Id, Name, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM User_Story__c
                LIMIT 2
            ];
            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');

            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);

            selectedUserStories.get(0).Environment__c = environments.get(0).Id;
            selectedUserStories.get(1).Environment__c = environments.get(1).Id;

            update selectedUserStories;

            // Exercise
            AuraHandledException ex;
            try {
                UserStoryBundleCtrl.createBundleRecords(bundle, selectedUserStories, metadata, profiles, destructive);
            } catch (AuraHandledException e) {
                ex = e;
            }

            // Verify
            System.assertEquals(System.Label.USB_WARNING_DIFFERENT_ENVIRONMENTS, ex.getMessage());

            List<Bundled_UserStory__c> junctionRecords = [SELECT User_Story__c, User_Story_Bundle__c FROM Bundled_UserStory__c];
            System.assertEquals(0, junctionRecords.size(), 'No juntion records should be created');
        }
    }

    @IsTest
    private static void testCreateBundle_With_DiffEnv_And_DiffPipelines_InUS() {
        System.runAs(getUser()) {
            // Setup
            List<MetaDataItem> metadata = testMetadata();
            List<MetaDataItem> profiles = testFullProfiles();
            List<MetaDataItem> destructive = testDestructive();

            List<User_Story__c> selectedUserStories = [
                SELECT Id, Name, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM User_Story__c
                LIMIT 2
            ];
            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');

            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);

            selectedUserStories.get(0).Environment__c = environments.get(0).Id;
            selectedUserStories.get(1).Environment__c = environments.get(1).Id;

            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            Deployment_Flow__c deploymentFlow1 = TestDataFactory.createDeploymentFlow('Deployment Flow 1', true, gitRepository.Id, false);
            Deployment_Flow__c deploymentFlow2 = TestDataFactory.createDeploymentFlow('Deployment Flow 2', true, gitRepository.Id, false);
            insert new List<Deployment_Flow__c>{ deploymentFlow1, deploymentFlow2 };

            Project__c project1 = TestDataFactory.createProject('My project 1', deploymentFlow1.Id, false);
            Project__c project2 = TestDataFactory.createProject('My project 2', deploymentFlow2.Id, false);
            insert new List<Project__c>{ project1, project2 };

            Release__c release = TestDataFactory.createRelease('Test Release', project2.Id);

            selectedUserStories.get(0).Project__c = project1.Id;
            selectedUserStories.get(1).Release__c = release.Id;
            update selectedUserStories;

            selectedUserStories = [
                SELECT Id, Name, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM User_Story__c
                LIMIT 2
            ];

            // Exercise
            AuraHandledException ex;
            try {
                UserStoryBundleCtrl.createBundleRecords(bundle, selectedUserStories, metadata, profiles, destructive);
            } catch (AuraHandledException e) {
                ex = e;
            }

            // Verify
            System.assertEquals(
                true,
                ex.getMessage().contains(System.Label.USB_WARNING_DIFFERENT_ENVIRONMENTS),
                ex.getMessage() +
                ' should contain ' +
                System.Label.USB_WARNING_DIFFERENT_ENVIRONMENTS
            );
            System.assertEquals(
                true,
                ex.getMessage().contains(System.Label.USB_WARNING_DIFFERENT_PIPELINES),
                ex.getMessage() +
                ' should contain ' +
                System.Label.USB_WARNING_DIFFERENT_PIPELINES
            );

            List<Bundled_UserStory__c> junctionRecords = [SELECT User_Story__c, User_Story_Bundle__c FROM Bundled_UserStory__c];
            System.assertEquals(0, junctionRecords.size(), 'No juntion records should be created');
        }
    }

    @IsTest
    private static void testNavigateToRecord() {
        System.runAs(getUser()) {
            // Setup
            User_Story_Bundle__c bundle = new User_Story_Bundle__c(Title__c = 'My Bundle');
            insert bundle;
            List<User_Story__c> stories = new List<User_Story__c>();
            ApexPages.StandardSetController userStoryStandardSetController = new ApexPages.StandardSetController(stories);
            UserStoryBundleCtrl bundleController = new UserStoryBundleCtrl(userStoryStandardSetController);
            bundleController.recordId = bundle.Id;

            // Exercise
            Pagereference recordPage = bundleController.navigate();

            // Verify
        }
    }

    @IsTest
    private static void testNavigateToListView() {
        System.runAs(getUser()) {
            // Setup
            List<User_Story__c> stories = new List<User_Story__c>();
            ApexPages.StandardSetController userStoryStandardSetController = new ApexPages.StandardSetController(stories);
            UserStoryBundleCtrl bundleController = new UserStoryBundleCtrl(userStoryStandardSetController);

            // Exercise
            Pagereference recordPage = bundleController.navigate();

            // Verify
        }
    }

    private static List<MetaDataItem> testMetadata() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Template1';
        item.r = false;
        item.s = true;
        item.t = 'EmailTemplate';

        MetaDataItem item2 = new MetaDataItem();
        item2.n = 'Template2';
        item2.s = true;
        item2.t = 'EmailTemplate';

        MetaDataItem item3 = new MetaDataItem();
        item3.n = 'a_Template';
        item3.s = true;
        item3.t = 'EmailTemplate';

        return new List<MetaDataItem>{ item, item2, item3 };
    }

    private static List<MetaDataItem> testFullProfiles() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Charly_Permission';
        item.s = true;
        item.t = 'PermissionSet';

        return new List<MetaDataItem>{ item };
    }

    private static List<MetaDataItem> testDestructive() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Hi';
        item.r = false;
        item.s = true;
        item.t = 'ApexClass';
        item.cb = '';

        return new List<MetaDataItem>{ item };
    }

    private static User getUser() {
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true, true);
        return standardUser;
    }

    private static void createData() {
        TestUtilities.enableLicenses(10, 10, 10, 10, 10, 100);
        ITestDefaults users = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = users.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095cEEAQ_0050X000007h8hTQAQ_6')
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095CBEAY_0050X000007h8hTQAQ_3')
                .setDataSize(Org__c.SObjectType, 1)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            update (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType);

            Git_Repository__c createdRepo = (Git_Repository__c) orgCredentialDefaults.getTestData(Git_Repository__c.SObjectType)[0];

            Org__c dev1Org = new Org__c();
            Org__c stagingOrg = new Org__c();

            List<Org__c> createdOrgs = (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType);
            for (Org__c org : createdOrgs) {
                switch on org.Name {
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                }
            }

            ITestDefaults gitSnapshot = new CopadoDeploymentWizardTestDefaults.GitBackupDefaults()
                .setFieldDefaults()
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Repository__c, createdRepo.Id)
                .includeDefaults(CopadoDeploymentWizardTestDefaults.GitOrgCommitDefaults.class)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Status__c, 'Complete')
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Git_Operation__c, 'Commit Files')
                .setSObjectRelation(
                    Git_Org_Commit__c.SObjectType,
                    Git_Backup__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Git_Org_Commit__c.Git_Backup__c => 1 }
                )
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        Git_Org_Commit__c.SObjectType => new Set<Schema.SObjectField>{ Git_Org_Commit__c.Commit_Id__c }
                    }
                )
                .setDataSize(Git_Backup__c.SObjectType, 1)
                .setDataSize(Git_Org_Commit__c.SObjectType, 2)
                .generateDefaults()
                .includeDefaults(CopadoDeploymentWizardTestDefaults.GitOrgCommitDefaults.class)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Git_Org_Commit__c.Commit_Id__c, 'cmm 2')
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Status__c, 'Complete')
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Git_Operation__c, 'Full Profiles & Permission Sets')
                .setSObjectRelation(
                    Git_Org_Commit__c.SObjectType,
                    Git_Backup__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Git_Org_Commit__c.Git_Backup__c => 1 }
                )
                .setDataSize(Git_Org_Commit__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoDeploymentWizardTestDefaults.GitOrgCommitDefaults.class)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Git_Org_Commit__c.Commit_Id__c, 'cmm 3')
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Status__c, 'Complete')
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Git_Operation__c, 'Destructive Changes')
                .setSObjectRelation(
                    Git_Org_Commit__c.SObjectType,
                    Git_Backup__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Git_Org_Commit__c.Git_Backup__c => 1 }
                )
                .setDataSize(Git_Org_Commit__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Git_Org_Commit__c orgCommit1 = new Git_Org_Commit__c();
            Git_Org_Commit__c orgCommit2 = new Git_Org_Commit__c();
            Git_Org_Commit__c orgCommitProfiles = new Git_Org_Commit__c();
            Git_Org_Commit__c orgCommitDestructive = new Git_Org_Commit__c();

            List<Git_Org_Commit__c> orgCommits = (List<Git_Org_Commit__c>) gitSnapshot.getTestData(Git_Org_Commit__c.SObjectType);
            for (Git_Org_Commit__c record : orgCommits) {
                if (record.Commit_Id__c == 'cmm 0' & record.Git_Operation__c == 'Commit Files') {
                    orgCommit1 = record;
                }
                if (record.Commit_Id__c == 'cmm 1' & record.Git_Operation__c == 'Commit Files') {
                    orgCommit2 = record;
                }
                if (record.Git_Operation__c == 'Full Profiles & Permission Sets') {
                    orgCommitProfiles = record;
                }
                if (record.Git_Operation__c == 'Destructive Changes') {
                    orgCommitDestructive = record;
                }
            }

            ITestDefaults stories = new CopadoUserStoryTestDefaults.UserStoryDefaults()
                .setFieldDefaults()
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        User_Story__c.SObjectType => new Set<Schema.SObjectField>{ User_Story__c.User_Story_Title__c }
                    }
                )
                .setDataSize(User_Story__c.SObjectType, 6)
                .generateDefaults()
                .executeDML();

            User_Story__c story1 = new User_Story__c();
            User_Story__c story2 = new User_Story__c();
            User_Story__c story3 = new User_Story__c();
            User_Story__c story4 = new User_Story__c();

            List<User_Story__c> storiesCreated = (List<User_Story__c>) stories.getTestData(User_Story__c.SObjectType);
            for (User_Story__c record : storiesCreated) {
                switch on record.User_Story_Title__c {
                    when 'My new User Story 0' {
                        story1 = record;
                    }
                    when 'My new User Story 1' {
                        story2 = record;
                    }
                    when 'My new User Story 2' {
                        story3 = record;
                    }
                    when 'My new User Story 3' {
                        story4 = record;
                    }
                }
            }

            ITestDefaults userStoryCommitDefaults = new CopadoUserStoryTestDefaults.UserStoryCommitDefaults()
                .setFieldDefaults()
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.User_Story__c, story1.Id)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.Snapshot_Commit__c, orgCommit1.Id)
                .setDataSize(User_Story_Commit__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryCommitDefaults.class)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.User_Story__c, story2.Id)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.Snapshot_Commit__c, orgCommit2.Id)
                .setDataSize(User_Story_Commit__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryCommitDefaults.class)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.User_Story__c, story1.Id)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.Snapshot_Commit__c, orgCommitProfiles.Id)
                .setDataSize(User_Story_Commit__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryCommitDefaults.class)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.User_Story__c, story2.Id)
                .setFieldValue(User_Story_Commit__c.SObjectType, User_Story_Commit__c.Snapshot_Commit__c, orgCommitDestructive.Id)
                .setDataSize(User_Story_Commit__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            ITestDefaults deploymentTaskDefaults = new CopadoUserStoryTestDefaults.DeploymentTaskDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.User_Story__c, story1.Id)
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.Task_Description__c, 'Deployment Task Description')
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.Type__c, 'Manual Task')
                .setDataSize(Deployment_Task__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentTaskDefaults.class)
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.User_Story__c, story2.Id)
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.Task_Description__c, 'Deployment Task Apex')
                .setFieldValue(Deployment_Task__c.SObjectType, Deployment_Task__c.Type__c, 'Apex')
                .setDataSize(Deployment_Task__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Deployment_Task__c deploymentTask1 = new Deployment_Task__c();
            List<Deployment_Task__c> deploymentTasks = (List<Deployment_Task__c>) deploymentTaskDefaults.getTestData(Deployment_Task__c.SObjectType);
            for (Deployment_Task__c record : deploymentTasks) {
                switch on record.Type__c {
                    when 'Apex' {
                        deploymentTask1 = record;
                    }
                }
            }

            Attachment att1 = new Attachment(
                ParentId = orgCommit1.Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":true}, {"t":"EmailTemplate","n":"Template2","s":false}]')
            );

            Attachment att2 = new Attachment(
                ParentId = orgCommit2.Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":false}, {"t":"EmailTemplate","n":"a_Template","s":true}]')
            );

            Attachment fullProfiles = new Attachment(
                ParentId = orgCommitProfiles.Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"PermissionSet","n":"Charly_Permission"}]')
            );

            Attachment destructive = new Attachment(
                ParentId = orgCommitDestructive.Id,
                Name = 'Git Deletion',
                Body = Blob.valueOf('[{"n":"Hi","s":true,"b":"","cb":"","r":false,"t":"ApexClass"}]')
            );

            Attachment testOnlyAttachment = new Attachment(
                ParentId = story1.Id,
                Name = 'Test Classes',
                Body = Blob.valueOf('[{"n":"test_class","s":true,"r":false,"ns":""}]')
            );

            Attachment testApexDeploymentTask = new Attachment(
                ParentId = deploymentTask1.Id,
                Name = 'Apex',
                Body = Blob.valueOf('System.debug(\'debug\')')
            );

            insert new List<Attachment>{ att1, att2, fullProfiles, destructive, testOnlyAttachment, testApexDeploymentTask };
        }
    }
}