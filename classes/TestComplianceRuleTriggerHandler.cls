@isTest
private class TestComplianceRuleTriggerHandler {
	@testSetup static void setupData() {
		TestUtilities.enableLicenses(2, 0, 0, 0, 2);
	}
	@isTest static void testComplianceRuleTriggerSuccess() {
        testMethodUtilities.upsertOrgwideSettings();
		System.assertEquals(true, FeatureHelper.isFeatureEnabled('Compliance Hub'));
		String ns = TestUtilities.getTestNameSpace();
		if(ns == 'none'){
			ns = '';//for the describe below
		}

		TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
		List<Schema.PicklistEntry> severityPle = Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Severity__c').getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> actionPle = Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Action__c').getDescribe().getPicklistValues();
		Compliance_Rule__c rule1 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = severityPle[0].getValue(), Action__c = actionPle[0].getValue(),
				Record_Count__c = 1, Record_Count_Criteria__c = 'Number of groups', Matching_Criteria__c = 'Greater or equal');
		insert rule1;
		update rule1;
		delete rule1;
		undelete rule1;

		try {
			TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
			update rule1;
			System.assert(false, 'this must fail');
		} catch(Exception e) {
			System.assertEquals(true, testMethodUtilities.hasMessage(Label.CCH_LICENSE_NOT_ENABLED));
		}
	}
}