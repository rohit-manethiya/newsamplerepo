@isTest
private class TestUserStoryAssignmentSetController {

    static testMethod void testMassAssignment() {
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=1; i<=2; i++){
        	User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
        	userStories.add(u);
        }
        insert userStories;
        
        Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
        insert testRelease;
        
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
        UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
        ext.records = userStories;
        
        Test.startTest();
        ext.dummy.Release__c = testRelease.Id;
        PageReference result = ext.assign();
        system.assertEquals(new PageReference('/'+testRelease.Id).getUrl(), result.getUrl());
        system.assertEquals(2,[select Id, Release__c from User_Story__c where Release__c=:testRelease.Id].size());
        Test.stopTest();
    }
    static testMethod void test_Cancel(){
    	List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=1; i<=2; i++){
        	User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
        	userStories.add(u);
        }
        insert userStories;
        
        Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
        insert testRelease;
        
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
        UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
        ext.records = userStories;
        
        Test.startTest();
        PageReference result = ext.cancel();
        Test.stopTest();
    	system.assert(result != null);
    }
    static testMethod void test_Add_Error(){
    	List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=1; i<=2; i++){
        	User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
        	userStories.add(u);
        }
        insert userStories;
        
        Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
        insert testRelease;
        
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
        UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
        Test.startTest();
        ext.dummy.Release__c = testRelease.Id;
        PageReference result = ext.assign();
        system.assertEquals(null, result);
        //system.assert(testMethodUtilities.hasMessage(Label.SELECT_AT_LEAST_ONE_RECORD));
        Test.stopTest();
    }
}