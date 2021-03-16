@isTest
private class TestOrgDiffTrigger {
	@testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
	@isTest static void test_method_one() {
		Org__c org1 = new Org__c(name='x');
		insert org1;
		Org__c org2 = new Org__c(name='y');
		insert org2;
		OrgDiff__c orgDiff1 = new OrgDiff__c(name='d1',from_Org__c=org1.id, to_Org__c=org2.id);
		insert orgDiff1;
		update orgDiff1;
		System.assertEquals(true,FeatureHelper.isFeatureEnabled('Org Difference'));
		System.assert(orgDiff1.id != null);
		
		delete orgDiff1;
	}
}