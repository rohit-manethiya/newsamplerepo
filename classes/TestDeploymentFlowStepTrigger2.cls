/**
 * Created by fede on 29/12/2017.
 */

@IsTest
private class TestDeploymentFlowStepTrigger2 {
    @testSetup static void setupData() {
        TestUtilities.getTestSettingsMultilicense();//NO CBM
    }
    static void setupDataDML() {
        TestUtilities.assignLicense(UserInfo.getUserName(),true, true, false, false, false);
    }
    @isTest static void BranchMgmtNotEnabled(){
        setupDataDML();
        Test.startTest();
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id, Disable_Validations__c = true);

        try{
            insert df;
            system.assert(false, 'Exception should have been thrown due to disabled Branch Management.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_NOT_ENABLED)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }
}