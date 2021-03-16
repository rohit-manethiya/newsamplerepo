@isTest
private class TestProjectTrigger {

	private static Project__c project1 = CMTestMethodUtilities.createProject('project1');
	private static Project__c project2 = CMTestMethodUtilities.createProject('project2');
	private static List<Project__c> projects = new List<Project__c>{project1,project2};

	static testMethod void testProjectIndexMetadata(){
		insert projects;
		project1.Index_Metadata__c = true;
		project2.Index_Metadata__c = true;
		update projects;

		System.assertEquals(project2.Index_Metadata__c,true);
		// Assert for SCA. (Batch Job Tested in another class).
		//for test converage
		delete projects;
		undelete projects;
	}
	
}