/**
 * Created by fede on 28/12/2017.
 */

@IsTest
private class TestFeatureHelperNegative {
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(1,0,0,1,0,0);
    }
    static testMethod void tests_all_disabled(){
        FeatureHelper con = new FeatureHelper();
        system.assertEquals(false, con.complianceHubEnabled);
        system.assertEquals(false, con.branchMgmtEnabled);
    }
}