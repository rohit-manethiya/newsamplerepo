@isTest
private class TestContinuousIntegrationPermTrg {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	static testMethod void insertTest(){
		Profile p = [select id from Profile where Name='Standard User']; 
        User u1 = new User(profileid=p.Id, alias='standt1', email='insertUpdateTest1@testorg.com', username='insertUpdateTest1@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        User u2 = new User(profileid=p.Id, alias='standt2', email='insertUpdateTest2@testorg.com', username='insertUpdateTest2@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        insert u1;
        insert u2;

		Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI', OwnerId=u1.Id);
		insert ci;

		List<Continuous_Integration__Share> results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		//Expect 2 results (Owner + Sharing rule)
		system.assertEquals(1, results.size());

		Continuous_Integration_Permission__c cip1 = new Continuous_Integration_Permission__c(User__c=u2.Id, Access__c='Read Only', Continuous_Integration__c=ci.Id);
		insert cip1;
		results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		//Expect 3 results (Owner + 2*Sharing rule)
		system.assertEquals(2, results.size());
	}
	static testMethod void updateTest(){
		Profile p = [select id from Profile where Name='Standard User']; 
        User u1 = new User(profileid=p.Id, alias='standt1', email='insertUpdateTest1@testorg.com', username='insertUpdateTest1@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        User u2 = new User(profileid=p.Id, alias='standt2', email='insertUpdateTest2@testorg.com', username='insertUpdateTest2@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        insert u1;
        insert u2;

		Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI', OwnerId=u1.Id);
		insert ci;

		List<Continuous_Integration__Share> results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		//Expect 1 results (1 Sharing rule)
		system.assertEquals(1, results.size());

		Continuous_Integration_Permission__c cip1 = new Continuous_Integration_Permission__c(User__c=u2.Id, Access__c='Read Only', Continuous_Integration__c=ci.Id);
		insert cip1;
		results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		//Expect 2 results (2*Sharing rule)
		system.assertEquals(2, results.size());

		cip1.Access__c='Validate Only';
		update cip1;
		results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		//Expect 2 results (2*Sharing rule)
		system.assertEquals(2, results.size());
	}
	static testMethod void deleteTest(){
		Profile p = [select id from Profile where Name='Standard User']; 
        User u1 = new User(profileid=p.Id, alias='standt1', email='deleteTest1@testorg.com', username='deleteTest1@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        User u2 = new User(profileid=p.Id, alias='standt2', email='deleteTest2@testorg.com', username='deleteTest2@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
        insert u1;
        insert u2;

		Continuous_Integration__c ci = new Continuous_Integration__c(Name='My CI', OwnerId=u1.Id);
		insert ci;

		Continuous_Integration_Permission__c cip1 = new Continuous_Integration_Permission__c(User__c=u2.Id, Access__c='Read Only', Continuous_Integration__c = ci.Id);
		insert cip1;
		List<Continuous_Integration__Share> results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];

		delete cip1;
		results = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share where ParentId=:ci.Id];
		system.assertEquals(1, results.size());
	}
}