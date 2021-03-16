@IsTest
private with sharing class UserStoryComplianceScanTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        TestUtilities.insertUser('user1-TestUserStoryComplianceScan@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense('user1-TestUserStoryComplianceScan@test-copado.org', false, false, false, true, false);
    }

    @IsTest
    private static void testUserStoryComplianceScanRequestSuccess() {
        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c(Name = 'Main Setting');
        insert complianceSetting;

        Environment__c envUAT = new Environment__c(Name = 'UAT Environment', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envUAT;
        Environment__c envProd = new Environment__c(Name = 'Prod Environment', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envProd;

        Org__c orgUAT = new Org__c(Name = 'test Org UAT', Environment__c = envUAT.Id);
        insert orgUAT;
        Org__c orgProd = new Org__c(Name = 'test Org Prod', Environment__c = envProd.Id);
        insert orgProd;

        Feature__c featureCBM = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        insert featureCBM;
        Feature__c featureGitBackup = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert featureGitBackup;
        Feature__c featureComplianceHub = new Feature__c(Name = 'Compliance Hub', Enabled__c = true);
        insert featureComplianceHub;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'test GitRepo');
        insert gitRepo;

        Deployment_Flow__c flow = new Deployment_Flow__c(
            Name = 'test Flow',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gitRepo.Id
        );
        insert flow;

        Project__c project = new Project__c(Name = 'Test Project', Deployment_Flow__c = flow.Id);
        insert project;

        User_Story__c userStory = new User_Story__c(Project__c = project.Id, Org_Credential__c = orgUAT.Id, Environment__c = envUAT.Id);
        insert userStory;

        String attachmentBody = '[{"t":"Profile","n":"Admin"}]';
        Attachment testAttachment = createAttachment(userStory.Id, 'MetaData', attachmentBody);
        insert testAttachment;

        attachmentBody = '[{"t":"Profile","n":"Admin"},{"t":"Profile","n":"Standard_User"}]';
        testAttachment = createAttachment(userStory.Id, 'Git MetaData', attachmentBody);
        insert testAttachment;

        attachmentBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(userStory.Id, 'Delete MetaData', attachmentBody);
        insert testAttachment;

        Deployment_Flow_Step__c flowStep = new Deployment_Flow_Step__c(
            Deployment_Flow__c = flow.Id,
            Branch__c = 'uat',
            Source_Environment__c = envUAT.Id,
            Destination_Environment__c = envProd.Id
        );
        insert flowStep;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        UserStoryComplianceScanController uscsController = new UserStoryComplianceScanController(new ApexPages.StandardController(userStory));
        uscsController.requestComplianceScan();
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMPLIANCE_SCAN_REQUESTED));

        Test.stopTest();
    }

    @IsTest
    private static void testUserStoryComplianceScanRequestFailure() {
        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c(Name = 'Main Setting');
        insert complianceSetting;

        Environment__c envUAT = new Environment__c(Name = 'UAT Environment', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envUAT;
        Environment__c envProd = new Environment__c(Name = 'Prod Environment', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envProd;

        Org__c orgUAT = new Org__c(Name = 'test Org UAT', Environment__c = envUAT.Id);
        insert orgUAT;
        Org__c orgProd = new Org__c(Name = 'test Org Prod', Environment__c = envProd.Id);
        insert orgProd;

        Feature__c featureCBM = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        insert featureCBM;
        Feature__c featureGitBackup = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert featureGitBackup;
        Feature__c featureComplianceHub = new Feature__c(Name = 'Compliance Hub', Enabled__c = true);
        insert featureComplianceHub;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'test GitRepo');
        insert gitRepo;

        Deployment_Flow__c flow = new Deployment_Flow__c(
            Name = 'test Flow',
            Active__c = true,
            Main_Branch__c = 'master',
            Git_Repository__c = gitRepo.Id
        );
        insert flow;

        Project__c project = new Project__c(Name = 'Test Project', Deployment_Flow__c = flow.Id);
        insert project;

        User_Story__c userStory = new User_Story__c(Project__c = project.Id, Org_Credential__c = orgUAT.Id, Environment__c = envUAT.Id);
        insert userStory;

        String attachmentBody = '[{"t":"Profile","n":"Admin"}]';
        Attachment testAttachment = createAttachment(userStory.Id, 'MetaData', attachmentBody);
        insert testAttachment;

        attachmentBody = '[{"t":"Profile","n":"Admin"},{"t":"Profile","n":"Standard_User"}]';
        testAttachment = createAttachment(userStory.Id, 'Git MetaData', attachmentBody);
        insert testAttachment;

        attachmentBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(userStory.Id, 'Delete MetaData', attachmentBody);
        insert testAttachment;

        Deployment_Flow_Step__c flowStep = new Deployment_Flow_Step__c(
            Deployment_Flow__c = flow.Id,
            Branch__c = 'uat',
            Source_Environment__c = envUAT.Id,
            Destination_Environment__c = envProd.Id
        );
        insert flowStep;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        envUAT.Compliance_Rule_Group__c = null;
        envProd.Compliance_Rule_Group__c = null;
        update envUAT;
        update envProd;

        UserStoryComplianceScanController uscsController5 = new UserStoryComplianceScanController(new ApexPages.StandardController(userStory));
        uscsController5.requestComplianceScan();
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMPLIANCE_SETTING_NOT_FOUND));

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestUserStoryComplianceScan@test-copado.org'];
        System.runAs(user) {
            UserStoryComplianceScanController uscsController6 = new UserStoryComplianceScanController(new ApexPages.StandardController(userStory));
            uscsController6.requestComplianceScan();
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMPLIANCE_SETTING_NOT_FOUND));
        }
        Test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(ParentId = parentId, Name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }
}