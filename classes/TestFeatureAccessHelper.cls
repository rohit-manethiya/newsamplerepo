@isTest
private class TestFeatureAccessHelper {

	@testSetup static void setupData() {
		TestUtilities.enableLicenses(2,2,2,2,2);
	}

	static void setupDataPermissionSet() {
		profile p = [select id from Profile where name = 'Standard User'];
        User user1 = new User(firstname = 'Future', lastname = 'User',
            alias = 'xyz1', 
            email = 'copado-test-1@test.org',
            emailencodingkey = 'UTF-8', 
			languagelocalekey='en_US', 
            localesidkey='en_US', 
			profileid = p.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'copado-test-1+SCA1@test.org'
            );
        insert(user1);
        User user2 = new User(firstname = 'Future2', lastname = 'User',
            alias = 'xyz2', 
            email = 'copado-test-2@test.org',
            emailencodingkey = 'UTF-8', 
			languagelocalekey='en_US', 
            localesidkey='en_US', 
			profileid = p.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'copado-test-2+Admin@test.org'
            );
        insert(user2);

		PermissionSet pscopadUser = [SELECT Id FROM PermissionSet WHERE name = 'Copado_User'];	
		PermissionSetAssignment psAssignment1 = new PermissionSetAssignment(PermissionSetId = pscopadUser.Id, AssigneeId = user1.Id);		
		insert psAssignment1;	
		system.assertNotEquals(null,psAssignment1.Id);

		User user3 = new User(firstname = 'Future3', lastname = 'User',
            alias = 'xyz3', 
            email = 'copado-test-3@test.org',
            emailencodingkey = 'UTF-8', 
			languagelocalekey='en_US', 
            localesidkey='en_US', 
			profileid = p.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'copado-test-3+ComplianceHub@test.org'
            );
        insert(user3);
		
        PermissionSetAssignment psAssignment2 = new PermissionSetAssignment(PermissionSetId = pscopadUser.Id, AssigneeId = user3.Id);		
		insert psAssignment2;	
		system.assertNotEquals(null,psAssignment2.Id);
    }
    static testMethod void test_isSCAFeatureAccessible() {
		setupDataPermissionSet();
		User user1 = [SELECT Id FROM User WHERE username = 'copado-test-1+SCA1@test.org'];
		User user2 = [SELECT Id FROM User WHERE username = 'copado-test-2+Admin@test.org'];
		Test.startTest(); 

			System.runAs(user1) {
				for(PermissionSetAssignment psa : [select PermissionSet.Name from PermissionSetAssignment where AssigneeId = :user1.Id]){
					System.debug('**** user1 assigned to: ' + psa.PermissionSet.Name);
				}
				Boolean sca = FeatureAccessHelper.isSCAFeatureAccessible();
				System.assertEquals(true,sca);
			}
			System.runAs(user2) {
				Boolean sca = FeatureAccessHelper.isSCAFeatureAccessible();
				System.assertEquals(false,sca);
			}
		Test.stopTest();	
	}
	static testMethod void test_isComplianceScanResultAccessible() {
		setupDataPermissionSet();
		User user2 = [SELECT Id FROM User WHERE username = 'copado-test-2+Admin@test.org'];
		User user3 = [SELECT Id FROM User WHERE username = 'copado-test-3+ComplianceHub@test.org'];
		Test.startTest(); 
			
			System.runAs(user3) {
				Boolean isComplianceScanResultAccessible = FeatureAccessHelper.isComplianceScanResultAccessible();
				System.assertEquals(true, isComplianceScanResultAccessible);
			}
			System.runAs(user2) {
				Boolean isComplianceScanResultAccessible = FeatureAccessHelper.isComplianceScanResultAccessible();
				System.assertEquals(false, isComplianceScanResultAccessible);
			}
		Test.stopTest();	
	}
	
}