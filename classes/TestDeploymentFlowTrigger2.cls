/**
 * Created by fede on 28/12/2017.
 */

@IsTest
private class TestDeploymentFlowTrigger2 {
    @testSetup static void setupTestData(){
        TestUtilities.enableLicenses(2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches',2);
    }
    public class MyTestClassException extends Exception {}
    static testMethod void featureNotEnabled(){
        testMethodUtilities.upsertOrgwideSettings();
        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=false, Quantity__c=2);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f2;

        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=false);

        try {
            insert df;
            system.assert(df.Id != null);
        } catch(Exception e) {
            system.assert(false, 'Exception thrown: '+e.getMessage());
        }

        Test.startTest();


        // Warning feature not enabled
        try {
            df = new Deployment_Flow__c(Name='test', Active__c=true);
            insert df;
        } catch(DmlException e) {
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_NOT_ENABLED)?true:false;
            system.debug('Actual Message thrown: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }

        Test.stopTest();
    }
}