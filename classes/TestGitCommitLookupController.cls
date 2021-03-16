@isTest
public class TestGitCommitLookupController {

    @TestSetup static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    static testMethod void runTest() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();

            // Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Git Repository createEnvironments
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            PageReference pageRef = Page.GitCommitMain;
            pageRef.getParameters().put('frm', 'test');
            pageRef.getParameters().put('txt', 'test');
            Test.setCurrentPage(pageRef);

            GitCommitLookupController con = new GitCommitLookupController();
            List<SelectOption> optionsList = GitCommitLookupController.getRepositories();
            System.assertEquals(2, optionsList.size());
            con.selectedRepository = 'test';
            String fromTag = con.getFormTag();
            System.assertEquals('test', fromTag);
            String textBox = con.getTextBox();
            System.assertEquals('test', textBox);
        }
    }
}