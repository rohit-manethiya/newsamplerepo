@isTest
private class TestManageGitBranchesController {
    @testSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
    }

    @isTest static void test_get_branches_no_repoId() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;

        PageReference pageRef = Page.ManageGitBranches;
        Test.setCurrentPage(pageRef);

        string b = '{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

            ManageGitBranchesController mGB = new ManageGitBranchesController();
            mGB.refreshBranchCache();
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertNotEquals(0, pageMessages.size());//The Message Was Added
            System.assertEquals('master', mGB.branchNamesInUseJoined, 'Branches in use should be master');

        Test.stopTest();
    }


	@isTest static void test_get_branches() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        Environment__c env2 = new Environment__c(Name='Dev2 Environment',Type__c='Sandbox');
        insert new List<Environment__c>{env1,env2};

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        Deployment_Flow_Step__c flowStep = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        insert flowStep;

        PageReference pageRef = Page.ManageGitBranches;
        pageRef.getParameters().put('repoId', gitRepo.Id);
        Test.setCurrentPage(pageRef);

        string b = '{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

            ManageGitBranchesController mGB = new ManageGitBranchesController();
            mGB.refreshBranchCache();
            mGB.cancel();
            System.assertEquals('master', mGB.branchNamesInUseJoined, 'Branches in use should be master');

        Test.stopTest();
	}

    @isTest static void test_Delete_branches_noParam() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;

        PageReference pageRef = Page.ManageGitBranches;
        pageRef.getParameters().put('repoId', gitRepo.Id);
        Test.setCurrentPage(pageRef);

        string b = '{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

            ManageGitBranchesController mGB = new ManageGitBranchesController();
            try {
                mGB.deleteGitBranches();
            }catch (exception e){
                system.assert(e.getMessage().contains('An error has occured while deleting branches'));
            }
            System.assertEquals('master', mGB.branchNamesInUseJoined, 'Branches in use should be master');
        Test.stopTest();
    }

    @isTest static void test_Delete_branches() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;

        PageReference pageRef = Page.ManageGitBranches;
        pageRef.getParameters().put('repoId', gitRepo.Id);
        pageRef.getParameters().put('deleteGitBranches', '{"gitBranches": ["dev9","dev10"]}');
        Test.setCurrentPage(pageRef);

        string b = '{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

            ManageGitBranchesController mGB = new ManageGitBranchesController();
            mGB.deleteGitBranches();
            System.assertEquals('master', mGB.branchNamesInUseJoined, 'Branches in use should be master');

        Test.stopTest();
    }
}