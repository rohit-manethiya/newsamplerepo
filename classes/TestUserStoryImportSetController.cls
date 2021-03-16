@IsTest
public class TestUserStoryImportSetController {
    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    public class testData {
        public List<User_Story__c> userStories = new List<User_Story__c>();
        public User_Story__c usResult = new User_Story__c();
        public List<User_Story_Commit__c> usCommits = new List<User_Story_Commit__c>();
        public List<Git_Org_Commit__c> commits = new List<Git_Org_Commit__c>();
        public List<Attachment> commitAttachments = new List<Attachment>();
        User_Story__c usWithoutcommits;
    }

    static testData generateData() {
        testData dataTest = new testData();
        Org__c o = new Org__c(Name = 'test');
        insert o;

        Git_Repository__c r = new Git_Repository__c(Name = 'test');
        insert r;

        Git_Backup__c bk = new Git_Backup__c(Git_Repository__c = r.Id, Org__c = o.Id);
        insert bk;

        Git_Org_Commit__c c1 = new Git_Org_Commit__c(Git_Backup__c = bk.Id, Org__c = o.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today(), Commit_Message__c = 'test', Status__c = 'Complete');
        Git_Org_Commit__c c2 = new Git_Org_Commit__c(Git_Backup__c = bk.Id, Org__c = o.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8975', Commit_Date__c = Date.today(), Commit_Message__c = 'test 2', Status__c = 'Complete');
        insert new List<Git_Org_Commit__c>{
                c1, c2
        };

        // Metadata selections via the grid
        Attachment att1 = new Attachment(ParentId = c1.Id, Name = 'Metadata', Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":true}, {"t":"EmailTemplate","n":"Template2","s":false}]'));
        // insert separately, so it is the latest attachment
        Attachment att2 = new Attachment(ParentId = c2.Id, Name = 'Metadata', Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":false}, {"t":"EmailTemplate","n":"a_Template","s":true}]'));
        insert new List<Attachment>{
                att1, att2
        };
        dataTest.commitAttachments.add(att1);
        dataTest.commitAttachments.add(att2);

        User_Story__c us = new User_Story__c();
        User_Story__c us2 = new User_Story__c();
        insert new List<User_Story__c>{
                us, us2
        };
        dataTest.userStories.add(us);
        dataTest.userStories.add(us2);

        dataTest.usWithoutcommits = new User_Story__c();
        insert dataTest.usWithoutcommits;

        // user story that will hold the results
        insert dataTest.usResult;

        User_Story_Commit__c uc1 = new User_Story_Commit__c(User_Story__c = us.Id, Snapshot_Commit__c = c1.Id);
        User_Story_Commit__c uc2 = new User_Story_Commit__c(User_Story__c = us2.Id, Snapshot_Commit__c = c2.Id);
        insert new List<User_Story_Commit__c>{
                uc1, uc2
        };
        dataTest.usCommits.add(uc1);
        dataTest.usCommits.add(uc2);
        return dataTest;
    }

    static testMethod void test_empty() {
        testData dataTest = generateData();

        // now "select" a few US in "userStories", and test the controller
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);

        List<User_Story__c> empties = new List<User_Story__c>();
        empties.add(dataTest.usWithoutcommits);

        ApexPages.StandardSetController con = new ApexPages.StandardSetController(empties);
        UserStoryImportSetController ext = new UserStoryImportSetController(con);
        ext.userStoryList = empties;
        ext.getAllMetadata();

        Test.startTest();
        ext.dummyUserStoryLookup.User_Story__c = dataTest.usResult.Id;
        PageReference result = ext.assign();
        System.assertEquals(null, result, 'User stories without metadata should show an error message');
        Test.stopTest();
    }

    static testMethod void test_with_commits() {
        testData dataTest = generateData();

        // now "select" a few US in "userStories", and test the controller
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardSetController con = new ApexPages.StandardSetController(dataTest.userStories);
        UserStoryImportSetController ext = new UserStoryImportSetController(con);
        ext.userStoryList = dataTest.userStories;
        ext.getAllMetadata();
        System.assertEquals(2, dataTest.userStories.size());
        System.assertEquals(2, ext.userStoryList.size());

        Test.startTest();
        ext.dummyUserStoryLookup.User_Story__c = dataTest.usResult.Id;
        PageReference result = ext.assign();

        PageReference pref = Page.GitCommitMain;
        String expected = pref.getUrl();

        System.assertNotEquals(null, result, 'User stories with metadata should be able to advance, but it threw an error');
        System.assert(result.getUrl().startsWith(expected), 'got: ' + result.getUrl() + ' expected: ' + expected + ';');
        System.assertEquals(result.getParameters().get('userStoryId'), dataTest.usResult.Id);
        System.assertNotEquals(result.getParameters().get('MetadataPreselectionId'), '');

        String aid = result.getParameters().get('MetadataPreselectionId');
        Attachment a = [SELECT Id, Body FROM Attachment WHERE Id = :aid];
        System.debug('Body=' + a.Body.toString());
        List<UserStoryImportSetController.MetaDataItem> metadata = (List<UserStoryImportSetController.MetaDataItem>) JSON.deserialize(a.Body.toString(), List<UserStoryImportSetController.MetaDataItem>.class);
        Integer timesFound = 0;
        for(UserStoryImportSetController.MetaDataItem mi : metadata) {
            System.debug('-rs: ' + mi.s + ' ' + mi.r + ' ' + mi.n + ' ' + mi + ' ; ' + mi.t.equals('EmailTemplate') + ',' + mi.n.equals('Template1'));
            if(mi.t.equals('EmailTemplate') && mi.n.equals('Template1')) {
                System.assertNotEquals(true, mi.r);
                timesFound++;
            }
        }
        System.assertEquals(1, timesFound);

        ext.cancel();
        Test.stopTest();
    }
    
    static testMethod void noUserStorySelected() {
        testData dataTest = generateData();

        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);

        List<User_Story__c> empties = new List<User_Story__c>();

        ApexPages.StandardSetController con = new ApexPages.StandardSetController(empties);
        UserStoryImportSetController ext = new UserStoryImportSetController(con);
        ext.userStoryList = empties;
        ext.getAllMetadata();

        Test.startTest();
        ext.dummyUserStoryLookup.User_Story__c = dataTest.usResult.Id;
        PageReference result = ext.assign();
        System.assertEquals(null, result, 'If you do not have any user story selected it should stay on the page and show a error message that user story is not selected');
        Test.stopTest();
    }
}