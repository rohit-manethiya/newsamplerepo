@isTest
private class TestCopadoAPI {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	@isTest static void test_method_one() {
		//TODO - implement proper testing
		CopadoAPI.listDeployments();
		Org__c o = new Org__c(name ='0');
		insert o;
		Deployment__c d = TestMethodUtilities.create('test', System.now(), System.now(), o.id, 'Deploy now', 'Draft');
		insert d;

		CopadoAPI.getDeployment(d.id);
		CopadoAPI.createDeployment(new Deployment__c(name='test'));
		CopadoAPI.updateDeployment(new Deployment__c(name='test'));
		CopadoAPI.getDestinationsOrg(d.id);
		CopadoAPI.createStep(d.id,new Step__c(name='test'));
		CopadoAPI.updateStep(d.id,new Step__c(name='test'),'');
		//CopadoAPI.removeStep(d.id);
		CopadoAPI.scheduleDeployment(d.id, System.now());
		CopadoAPI.deploy(d.id,'type');
		CopadoAPI.cancelDeploy(d.id);
		CopadoAPI.getDeployHistory(d.id);
		CopadoAPI.getStepHistory(d.id);
		CopadoAPI.getStepHistoryDetail(d.id);
		CopadoAPI.getJobsByDeployment(d.id,'status');
		CopadoAPI.getJobsByStep(d.id,'status');
		CopadoAPI.getDeployStatus(d.id);
	}
}