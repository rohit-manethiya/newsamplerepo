@IsTest
public with sharing class TestGitSnapshot {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    
    @TestSetup
    static void makeData(){
        TestUtilities.enableLicenses(1,1,1,1,1);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults()
        .createRunAsUsers()
        .executeDML();

        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
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
        }
    }

    /**
     * Test snapshot record when click on "Commit Changes"
     */
    @IsTest
    static void testGitSnapshotCommitChanges() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        Org__c testOrg = [SELECT Id, Name FROM Org__c WHERE Name = 'dev1 0' LIMIT 1];
        Git_Repository__c testRepo = [SELECT Id, Name FROM Git_Repository__c WHERE Name = 'MyGitRepo 0' LIMIT 1];

        System.runAs(standardUser) {
            String mockResult = '{"ok":"Git validated"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(mockResult, null));

            ITestDefaults gitSnapshot = new CopadoDeploymentWizardTestDefaults.GitBackupDefaults()
                .setFieldDefaults()
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Org__c, testOrg.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Repository__c, testRepo.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Snapshot_Permissions__c, 'Allow Commits Only')
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Branch__c, 'master')
                .setDataSize(Git_Backup__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Git_Backup__c currentSnapshot = (Git_Backup__c) gitSnapshot.getTestData(Git_Backup__c.SObjectType)[0];
            Test.startTest();
            PageReference viewGitSnapshotPage = Page.ViewGitBackup;
            Test.setCurrentPage(viewGitSnapshotPage);
            
            BackupNow viewGitSnapshotController = new BackupNow(new ApexPages.StandardController(currentSnapshot));
            PageReference gitCommitMainPage = viewGitSnapshotController.goToGitCommitPage();
            Test.setCurrentPage(gitCommitMainPage);

            PageReference assertGitCommitMainPage = Page.GitCommitMain;
            assertGitCommitMainPage.getParameters().put('snapshotId', currentSnapshot.Id);
            assertGitCommitMainPage.getParameters().put('variant', 'GitSnapshotCommit');
            System.assertEquals(assertGitCommitMainPage.getUrl(), gitCommitMainPage.getUrl(), 'Next Page is not GitCommitMain.page');

            String mockResponse = '[{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Complete', mockResponse, null));
            
            GitCommit_MainPageController gitCommitController = new GitCommit_MainPageController();
            System.assertEquals(0, gitCommitController.pageMessagesMap.size(), 'There are error messages in the page');
            System.assertEquals(3, gitCommitController.operationsMap.size(), 'Git Operations are different from 3');
            System.assertEquals(1, gitCommitController.snapshotList.size(), 'Snapshot list size is different from 1');
            System.assertEquals(currentSnapshot.Id, gitCommitController.snapshot.Id, 'Snapshot Id is not correct');

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = gitCommitController;
            
            System.assertEquals('', headerController.commitMessage, 'Commit message must be empty');
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(3, options.size(), 'Commit Options to select are different from 3');

            headerController.commitMessage = 'test';
            String commitId = GitCommit_HeaderController.createGitOrgCommit(headerController.commitMessage, testOrg.Id, gitCommitController.snapshot.Id, 'Commit Files');
            System.assertNotEquals(null, commitId);

            Git_Org_Commit__c assertOrgCommit = [SELECT Id, Commit_Message__c, Org__c, Git_Backup__c, Status__c, Git_Operation__c FROM Git_Org_Commit__c WHERE Id = :commitId LIMIT 1];
            System.assertEquals('test', assertOrgCommit.Commit_Message__c, 'Commit message is not the configured');
            System.assertEquals(testOrg.Id, assertOrgCommit.Org__c, 'Org Credential is not the selected in the gitsnapshot record');
            System.assertEquals(gitCommitController.snapshot.Id, assertOrgCommit.Git_Backup__c, 'Gitsnapshot record is not correct');
            System.assertEquals('Pending', assertOrgCommit.Status__c, 'Current status is different from "Pending"');
            System.assertEquals('Commit Files', assertOrgCommit.Git_Operation__c, 'Org Credential is not the selected in the gitsnapshot record');
            
            Test.stopTest();
        }
    }

     /**
     * Test negative Compliance Scan
     */
    @IsTest
    static void testGitSnapshotNoComplianceSetting() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        Org__c testOrg = [SELECT Id, Name FROM Org__c WHERE Name = 'dev1 0' LIMIT 1];
        Git_Repository__c testRepo = [SELECT Id, Name FROM Git_Repository__c WHERE Name = 'MyGitRepo 0' LIMIT 1];

        System.runAs(standardUser) {
            String gitMockResult = '{"ok":"Git validated"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(gitMockResult, null));
            ITestDefaults gitSnapshot = new CopadoDeploymentWizardTestDefaults.GitBackupDefaults()
                .setFieldDefaults()
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Org__c, testOrg.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Repository__c, testRepo.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Snapshot_Permissions__c, 'Allow Commits Only')
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Branch__c, 'master')
                .setDataSize(Git_Backup__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
            Git_Backup__c currentSnapshot = (Git_Backup__c) gitSnapshot.getTestData(Git_Backup__c.SObjectType)[0];
            
            Test.startTest();
            PageReference viewGitSnapshotPage = Page.ViewGitBackup;
            Test.setCurrentPage(viewGitSnapshotPage);
            
            BackupNow viewGitSnapshotController = new BackupNow(new ApexPages.StandardController(currentSnapshot));
            viewGitSnapshotController.testOK = true;
            viewGitSnapshotController.gitBackupComplianceScan();
            System.assertEquals(Label.COMPLIANCE_SETTING_NOT_FOUND, ApexPages.getMessages()[1].getDetail(), 'Message received is not about Compliance Setting');
            
            Test.stopTest();
        }
    }
}