@IsTest
private class TestSnapshotDifferenceExtension {
    private static final User RUNNING_USER;

    static {
        RUNNING_USER = createRunningUser();
    }

    @TestSetup
    private static void setupData() {
        assignUserPermissions(RUNNING_USER.Id);
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        TestUtilities.setTestSettingsEE();

        System.runAs(RUNNING_USER) {
            TestMethodUtilities.upsertOrgwideSettings();
            createTestData();
        }
    }

    @IsTest
    private static void checkEnvironment() {


            SnapshotDifferenceExtension extension = getPageController();
            extension.us4Lookup.User_Story__c = [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'DEV-1 Test' LIMIT 1]?.Id;

            Test.startTest();
            extension.checkEnvironment();
            Test.stopTest();

            System.assert(!extension.showError, 'No errors should appear when the selected user story environment matches the snapshot source environment.');
        }



    @IsTest
    private static void save() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();

            Test.startTest();
            PageReference actualPage = extension.save();
            Test.stopTest();

            String expectedUrl = '/' + String.valueOf(extension.snapshot.Id).substring(0, 15);
            System.assertEquals(expectedUrl, actualPage.getUrl(), 'Saving failed to redirect the user to the record detail page.');
        }
    }

    @IsTest
    private static void cancel() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();

            Test.startTest();
            PageReference actualPage = extension.cancel();
            Test.stopTest();

            String expectedUrl = '/' + String.valueOf(extension.snapshot.Id).substring(0, 15);
            System.assertEquals(expectedUrl, actualPage.getUrl(), 'Canceling failed to redirect the user to the record detail page.');
        }
    }

    @IsTest
    private static void edit() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();

            Test.startTest();
            extension.edit();
            Test.stopTest();

            System.assert(extension.isEdit, 'Failed to switch to edit mode on the page.');
        }
    }

    @IsTest
    private static void isSnapshotEnabled() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();

            Test.startTest();
            Boolean isSnapshotEnabled = extension.isSnapshotEnabled;
            Test.stopTest();

            System.assert(isSnapshotEnabled, 'Snapshots should be enabled for this user, but they are not.');
        }
    }

    @IsTest
    private static void keyPrefix() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();

            Test.startTest();
            String keyPrefix = extension.keyPrefix;
            Test.stopTest();

            String expectedKeyPrefix = Git_Org_Commit__c.SObjectType.getDescribe().getKeyPrefix();
            System.assertEquals(expectedKeyPrefix, keyPrefix, 'Incorrect Key Prefix was retrieved for Git_Org_Commit__c object.');


        }
    }

    @IsTest

    private static void namespace() {
        System.runAs(RUNNING_USER) {
            Test.startTest();
            String namespace = SnapshotDifferenceExtension.settings.namespace;
            Test.stopTest();

            System.assertEquals(namespace, Settings.ns, 'Incorrect namespace retrieved by the page.');
        }
    }

    @IsTest
    private static void doRerenderForGitCommitOption() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();
            extension.snapshot.Source_Option__c = 'Git Commit';
            extension.snapshot.Destination_Option__c = 'Git Commit';
            update extension.snapshot;

            Test.startTest();
            extension.doRerender();
            Test.stopTest();

            System.assertEquals(null, extension.snapshot.Source_Org_Credential__c, 'When the selected Source is not Salesforce Org, no Source Org Credential shall be set.');
            System.assertEquals(null, extension.snapshot.Destination_Org_Credential__c, 'When the selected Destination is not Salesforce Org, no Destination Org Credential shall be set.');
        }
    }


    @IsTest
    private static void doRerenderForSalesforceOrgOption() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();
            extension.snapshot.Source_Git_Commit__c = [SELECT Id FROM Git_Org_Commit__c WHERE Org__c = :extension.snapshot.Source_Org_Credential__c LIMIT 1]?.Id;
            extension.snapshot.Destination_Git_Commit__c = [SELECT Id FROM Git_Org_Commit__c WHERE Org__c = :extension.snapshot.Destination_Org_Credential__c LIMIT 1]?.Id;
            update extension.snapshot;

            Test.startTest();
            extension.doRerender();
            Test.stopTest();

            System.assertEquals(null, extension.snapshot.Source_Git_Commit__c, 'When the selected Source is not Git Commit, no Source Git Commit shall be set.');
            System.assertEquals(null, extension.snapshot.Destination_Git_Commit__c, 'When the selected Destination is not Git Commit, no Destination Git Commit shall be set.');
        }
    }

    @IsTest
    private static void doRerenderForNullOption() {
        System.runAs(RUNNING_USER) {
            SnapshotDifferenceExtension extension = getPageController();
            extension.snapshot.Source_Option__c = null;
            extension.snapshot.Destination_Option__c = null;
            update extension.snapshot;

            Test.startTest();
            extension.doRerender();
            Test.stopTest();

            System.assertEquals(null, extension.snapshot.Source_Org_Credential__c, 'When the selected Source is not Salesforce Org, no Source Org Credential shall be set.');
            System.assertEquals(null, extension.snapshot.Destination_Org_Credential__c, 'When the selected Destination is not Salesforce Org, no Destination Org Credential shall be set.');
            System.assertEquals(null, extension.snapshot.Source_Git_Commit__c, 'When the selected Source is not Git Commit, no Source Git Commit shall be set.');
            System.assertEquals(null, extension.snapshot.Destination_Git_Commit__c, 'When the selected Destination is not Git Commit, no Destination Git Commit shall be set.');
        }
    }

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        return users[0];
    }

    private static void assignUserPermissions(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :userId
        ];
        if (assignments.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        }
    }

    private static void assignAllLicenses() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true, true);
    }

    private static void createTestData() {
        List<Org__c> credentials = new List<Org__c>();
        Org__c sourceCredential = CMTestMethodUtilities.createOrg('DEV-1', 'Production', 'SFDC_OrgId', null, null, System.now(), null);
        credentials.add(sourceCredential);
        Org__c destinationCredential = CMTestMethodUtilities.createOrg('DEV-2', 'Production', 'SFDC_OrgId2', null, null, System.now(), null);
        credentials.add(destinationCredential);
        insert credentials;

        User_Story__c userStory = new User_Story__c();
        userStory.User_Story_Title__c = 'DEV-1 Test';
        userStory.Org_Credential__c = sourceCredential.Id;
        insert userStory;

        User_Story_Task__c usTask = new User_Story_Task__c();
        usTask.User_Story__c = userStory.Id;
        insert usTask;

        List<Git_Org_Commit__c> gitCommits = new List<Git_Org_Commit__c>();
        Git_Org_Commit__c sourceCommit = new Git_Org_Commit__c();
        sourceCommit.Org__c = sourceCredential.Id;
        gitCommits.add(sourceCommit);
        Git_Org_Commit__c destinationCommit = new Git_Org_Commit__c();
        destinationCommit.Org__c = destinationCredential.Id;
        gitCommits.add(destinationCommit);
        insert gitCommits;

        Snapshot_Difference__c snapshotDif = new Snapshot_Difference__c(
            Source_Org_Credential__c = sourceCredential.Id,
            Destination_Org_Credential__c = destinationCredential.Id,
            Name = 'Test Snapshot Difference',
            Source_Option__c = 'Salesforce Org',
            Destination_Option__c = 'Salesforce Org'
        );
        insert snapshotDif;

        Attachment indexFile = new Attachment();
        indexFile.Name = 'index.json';
        indexFile.ParentId = snapshotDif.Id;
        indexFile.Body = Blob.valueOf(
            '[{"f":"tabs/copado__Copado_Feature__c.tab","s":false,"d":"create","n":"copado__Copado_Feature__c","t":"CustomTab"}]'
        );
        insert indexFile;
    }

    private static SnapshotDifferenceExtension getPageController() {
        Snapshot_Difference__c snapshotDif = [
            SELECT
                Name,
                Source_Org_Credential__c,
                Destination_Org_Credential__c,
                Source_Option__c,
                Destination_Option__c,
                Source_Org_Credential__r.Environment__c,
                Last_Run__c
            FROM Snapshot_Difference__c
            WHERE Name = 'Test Snapshot Difference'
            LIMIT 1
        ];
        ApexPages.StandardController controller = new ApexPages.StandardController(snapshotDif);
        SnapshotDifferenceExtension extension = new SnapshotDifferenceExtension(controller);
        return extension;
    }
}