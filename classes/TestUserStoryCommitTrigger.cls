@IsTest
private class TestUserStoryCommitTrigger {
    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_new_defaults() {
        Org__c o = new Org__c(Name = 'test');
        insert o;
        Git_Repository__c r = new Git_Repository__c(Name = 'test');
        insert r;
        Git_Backup__c bk = new Git_Backup__c(Git_Repository__c = r.Id, Org__c = o.Id);
        insert bk;
        Git_Org_Commit__c c = new Git_Org_Commit__c(Git_Backup__c = bk.Id, Org__c = o.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today(), Commit_Message__c = 'test', Status__c = 'Complete');
        insert c;
        User_Story__c us = new User_Story__c();
        insert us;
        String usName = [SELECT Name FROM User_Story__c WHERE Id = :us.Id].Name;
        User_Story_Commit__c uc = new User_Story_Commit__c(User_Story__c = us.Id, Snapshot_Commit__c = c.Id);
        insert uc;
        User_Story_Commit__c usc = [SELECT Name, External_Id__c FROM User_Story_Commit__c WHERE Id = :uc.Id];
        System.assertEquals(usName + ' b7adccf', usc.Name);
        System.assertEquals(us.Id + '_b7adccf3937495e8928d1023c5a5c644198b8974', usc.External_Id__c);
        update uc;
        delete uc;
        undelete uc;
    }
}