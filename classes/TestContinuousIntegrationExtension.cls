@isTest
private class TestContinuousIntegrationExtension {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	static testMethod void runTests(){
		Profile p = [select id from Profile where Name='Standard User']; 
		User u1 = new User(profileid=p.Id, alias='standt1', email='insertUpdateTest1@testorg.com', username='insertUpdateTest1@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
    	User u2 = new User(profileid=p.Id, alias='standt2', email='insertUpdateTest2@testorg.com', username='insertUpdateTest2@testorg.com', emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
    	insert u1; 
    	insert u2;
		
		Org__c testOrg = testMethodUtilities.createOrg('OrgName','Production','SFDC_OrgId','SFDC_TOKEN','USERNAME', null);
        insert testOrg;
		Continuous_Integration__c ci = new Continuous_Integration__c(OwnerId=u1.Id, Name='My First CI', Destination_Org_Credential__c=testOrg.Id);
		insert ci;

		Test.startTest();
    	PageReference pref = Page.ContinuousIntegration;
	    pref.getParameters().put('id',ci.id);
	    Test.setCurrentPage(pref);

	    ContinuousIntegrationExtension ext = new ContinuousIntegrationExtension(new ApexPages.StandardController(ci));
	    system.assertEquals(false, ext.showHookUrl);
	    Test.stopTest();
	}
}