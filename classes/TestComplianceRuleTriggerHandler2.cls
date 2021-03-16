/**
 * Created by fede on 28/12/2017.
 */

@IsTest
private class TestComplianceRuleTriggerHandler2 {
    @testSetup static void setupData() {
        TestUtilities.enableLicenses(2, 0, 0, 0, 0);//no compliance feature.
    }
    @isTest static void testComplianceRuleTriggerErrors() {
        System.assertEquals(false, FeatureHelper.isFeatureEnabled('Compliance Hub'));

        Compliance_Rule__c rule1 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = 'Medium', Action__c = 'Continue with alert');

        try {
            insert rule1;
            System.assert(false, 'this must fail');
        } catch(Exception e) {
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.FEATURE_NOT_SUPPORTED+': Compliance Hub'));
        }
    }
}