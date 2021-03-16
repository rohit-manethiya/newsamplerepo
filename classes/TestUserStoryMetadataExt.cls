@IsTest
private class TestUserStoryMetadataExt {
    private static final String POTENTIAL_CONFLICT = 'Potential Conflict';
    private static final String CUSTOMOBJECT_ACCOUNT = 'CustomObject.Account';
    private static final String CONFLICT_RESOLVED = 'Conflict Resolved';
    private static final String US_0000777 = 'US-0000777 ';
    private static final String US_0000567 = 'US-0000567 ';
    private static final String US_0006186 = 'US-0006186 ';
    private static final String CUSTOMLABEL_VALIDATE = 'CustomLabel.VALIDATE';
    private static final String APEXCLASS_HELPER = 'ApexClass.Helper';
    private static final String CUSTOMFIELD_ACCOUNT_XYZ= 'CustomField.Account.XYZ__c';
    private static final String STATUS = 'Status';
    private static final String METADATAID = 'metadataId';
    private static final String COMPAREUS = 'compareUS';
    private static final String QPARAM_NAME2Id = US_0000777 + CUSTOMOBJECT_ACCOUNT;
    private static final String QPARAM_NAMEUsm3 = US_0000567 + CUSTOMOBJECT_ACCOUNT;
    private static final String TEST_USER = 'test_user@test-org.test';

    @TestSetup static void setupTestData() {
        //Execute @TestSetUp as admin user is to avoid MIXED_DML_OPERATION error.
        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser){
            TestUtilities.setTestSettingsEE();

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;

            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            testProject.Index_Metadata__c = true;
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;

            List<User_Story__c> uList = new List<User_Story__c>();
            User_Story__c testUserStory1 = CMTestMethodUtilities.createUserStory('test');
            testUserStory1.Project__c = testProject.Id;
            uList.add(testUserStory1);
            User_Story__c testUserStory2 = CMTestMethodUtilities.createUserStory('test2');
            testUserStory2.Project__c = testProject.Id;
            uList.add(testUserStory2);
            User_Story__c testUserStory3 = CMTestMethodUtilities.createUserStory('test3');
            testUserStory3.Project__c = testProject.Id;
            uList.add(testUserStory3);
            insert uList;

            List<User_Story_Metadata__c> uMList = new List<User_Story_Metadata__c>();
            User_Story_Metadata__c usm1 = new User_Story_Metadata__c(Name = US_0006186 + CUSTOMOBJECT_ACCOUNT, Metadata_API_Name__c = CUSTOMOBJECT_ACCOUNT, User_Story__c = testUserStory1.Id, Status__c = POTENTIAL_CONFLICT);
            uMList.add(usm1);
            User_Story_Metadata__c usm2 = new User_Story_Metadata__c(Name = QPARAM_NAME2Id, Metadata_API_Name__c = CUSTOMOBJECT_ACCOUNT, User_Story__c = testUserStory2.Id, Status__c = POTENTIAL_CONFLICT);
            uMList.add(usm2);
            User_Story_Metadata__c usm3 = new User_Story_Metadata__c(Name = QPARAM_NAMEUsm3, Metadata_API_Name__c = CUSTOMOBJECT_ACCOUNT, User_Story__c = testUserStory3.Id, Status__c = POTENTIAL_CONFLICT);
            uMList.add(usm3);
            User_Story_Metadata__c usm4 = new User_Story_Metadata__c(Name = US_0006186 + CUSTOMLABEL_VALIDATE, Metadata_API_Name__c = CUSTOMLABEL_VALIDATE, User_Story__c = testUserStory1.Id, Status__c = 'On Hold');
            uMList.add(usm4);
            User_Story_Metadata__c usm5 = new User_Story_Metadata__c(Name = US_0000777 + APEXCLASS_HELPER, Metadata_API_Name__c = APEXCLASS_HELPER, User_Story__c = testUserStory2.Id, Status__c = 'In Review');
            uMList.add(usm5);
            User_Story_Metadata__c usm6 = new User_Story_Metadata__c(Name = US_0000567 + CUSTOMFIELD_ACCOUNT_XYZ, Metadata_API_Name__c = CUSTOMFIELD_ACCOUNT_XYZ, User_Story__c = testUserStory3.Id, Status__c = '');
            uMList.add(usm6);
            insert uMList;

            System.assertEquals(6, [SELECT COUNT() FROM User_Story_Metadata__c]);
            System.assertEquals(3, [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = :POTENTIAL_CONFLICT]);
            System.assertEquals(3, [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = :POTENTIAL_CONFLICT AND Metadata_API_Name__c = :CUSTOMOBJECT_ACCOUNT]);
        }
    }
    static testMethod void testWithPermissions() {
        String usm2Id =[SELECT Id FROM User_Story_Metadata__c WHERE Name = :QPARAM_NAME2Id].Id;
        User_Story_Metadata__c usm3 =[SELECT Id, Metadata_API_Name__c, User_Story__c, Status__c FROM User_Story_Metadata__c WHERE Name = :QPARAM_NAMEUsm3];

        Test.startTest();

        ApexPages.currentPage().getParameters().put(STATUS, CONFLICT_RESOLVED);
        ApexPages.currentPage().getParameters().put(METADATAID, usm3.Id);
        ApexPages.currentPage().getParameters().put(COMPAREUS, usm2Id);

        UserStoryMetadataExt ext = new UserStoryMetadataExt(new ApexPages.StandardController(usm3));
        System.debug('#### UserStoryMetadata:"' + ext.usMetadata);
        System.assertEquals(POTENTIAL_CONFLICT, ext.usMetadata.Status__c);
        System.assertEquals(2, ext.usMetadataList.size());
        System.assertEquals(5, ext.getStatuses().size());//JG: now we "Back Promoted"

        ext.updateStatus();
        System.assertEquals(CONFLICT_RESOLVED, ext.usMetadata.Status__c);

        ext.metadataId = '';
        ext.updateStatuses();

        System.assertEquals(0, ext.offset);
        ext.nextUserStoryMetadatas();

        System.assertEquals(100, ext.offset);

        ext.previousUserStoryMetadatas();

        System.assertEquals(0, ext.offset);

        ext.preparePullRequest();

        ext.latestPull = new UserStoryMetadataExt.pullConfig('', '', '', '');

        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = :POTENTIAL_CONFLICT]);
        System.assertEquals(3, [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = :CONFLICT_RESOLVED AND Metadata_API_Name__c = :CUSTOMOBJECT_ACCOUNT]);
        ext.deleteJob();
    }
    static testMethod void testWithoutPermissions() {
        TestUtilities.insertUser(TEST_USER,'Standard User');
        User standardUser = [SELECT Id, Name,FirstName, LastName, Email FROM User WHERE Username = :TEST_USER];

        String usm2Id =[SELECT Id FROM User_Story_Metadata__c WHERE Name = :QPARAM_NAME2Id].Id;
        User_Story_Metadata__c usm3 =[SELECT Id, Metadata_API_Name__c, User_Story__c, Status__c FROM User_Story_Metadata__c WHERE Name = :QPARAM_NAMEUsm3];

        System.runAs(standardUser){
            Test.startTest();

            ApexPages.currentPage().getParameters().put(STATUS, CONFLICT_RESOLVED);
            ApexPages.currentPage().getParameters().put(METADATAID, usm3.Id);
            ApexPages.currentPage().getParameters().put(COMPAREUS, usm2Id);

            UserStoryMetadataExt ext = new UserStoryMetadataExt(new ApexPages.StandardController(usm3));

            ext.updateStatus();

            ext.metadataId = '';

            System.assertEquals(0, ext.offset);
            System.debug(ApexPages.getMessages()[0]);
            System.debug(ApexPages.getMessages()[1]);
            System.assertEquals(ApexPages.getMessages().size(), 2); //insufficient access and related object messages
            System.assert(ApexPages.getMessages()[0].getDetail().containsIgnoreCase(Label.Insufficient_Access_Rights));

            Test.stopTest();
        }
    }
}