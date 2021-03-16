@IsTest
private class TestCopadoSetup {
    private static final String UTF_8  = 'UTF-8';
    private static final String ADMIN_USER = 'test_admin@myorg.com';
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    static void makeData(){
        TestUtilities.enableLicenses(1,1,1,1,1);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults()
        .createRunAsUsers()
        .executeDML();

        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];
        System.runAs(adminUser) {
            ITestDefaults environmentSetupDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setSObjectRelation(Org__c.SObjectType, Environment__c.SObjectType, new Map<Schema.SObjectField, Integer>{
                        Org__c.Environment__c => 4
                })
            .setDataSize(Environment__c.SObjectType,2)
            .setDataSize(Org__c.SObjectType,7)
            .generateDefaults()
            .executeDML();
        }
    }

    // TODO: This test have problems with standard user in License Manager. 
    @IsTest
    static void testProdOrgCredentialCreation() {
        User adminUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :ADMIN_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
        System.runAs(adminUser) {
            ITestDefaults productionOrgCredential = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setDataSize(Org__c.SObjectType,1)
                .generateDefaults();
            
            Test.startTest();
            productionOrgCredential.executeDML();

            Org__c productionOrg = (Org__c)productionOrgCredential.getTestData(Org__c.SObjectType)[0];
            EditOrg editOrgController = new EditOrg(new ApexPages.StandardController(productionOrg));
            PageReference pageRef = editOrgController.doOauth();

            // Assert if URL generated is correct.
            Map<String, String> authorizeCalloutUrl = pageRef.getParameters();
            System.assert(pageRef.getUrl().contains('/Authorize/sforceLogin'), 'Page does not have the proper url');
            System.assertEquals(authorizeCalloutUrl.get('orgId'), productionOrg.Id);
            System.assertEquals(authorizeCalloutUrl.get('copadoOrgId'), EncodingUtil.urlEncode(UserInfo.getOrganizationId(), UTF_8));
            System.assertEquals(authorizeCalloutUrl.get('copadoUserId'), EncodingUtil.urlEncode(UserInfo.getUserId(), UTF_8));
            Test.stopTest();
        }
    }

    @IsTest
    static void testCopadoEnterpriseLicense(){
        User usrAdmin;
        User usrStandard;

        for (User usr : [SELECT Id,Name,Email,Username FROM User WHERE Username IN (:ADMIN_USER,:STANDARD_USER)]) {
            switch on usr.Username {
                when 'test_admin@myorg.com' {
                    usrAdmin = usr;
                }
                when 'test_user@myorg.com' {
                    usrStandard = usr;
                }
            }
        }

        Test.startTest();
        System.runAs(usrAdmin) {
            LicenseManagerController con = new LicenseManagerController();

            con.dummyUser.ManagerId = usrAdmin.Id;
            con.assignCopado = true;
            con.assignCCM = false;
            con.assignCST = false;
            con.assignCAD = false;
            con.assignCCH = false;
            con.assignADD = false;
            con.addUser();

            String adminMessageResult = ApexPages.getMessages()[0].getDetail();

            con.dummyUser.ManagerId = usrStandard.Id;
            con.assignCopado = true;
            con.assignCCM = false;
            con.assignCST = false;
            con.assignCAD = false;
            con.assignCCH = false;
            con.assignADD = false;
            con.addUser();

            String standardUserMessageResult = ApexPages.getMessages()[1].getDetail();

            System.assertEquals(1, con.copadoLicensesUsed);
            System.assertEquals(1, con.copadoUsage.size());
            System.assertEquals(Label.LICENSE_UPSERT_SUCCESSFUL, adminMessageResult);
            System.assertEquals(Label.COPADO_LICENSE_LIMIT_REACHED, standardUserMessageResult);
        }
        Test.stopTest();
    }

    // Create Git repository SSH (SSH key creation)
    @IsTest
    static void createSshGitrepository() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        
        System.runAs(standardUser){
            Git_Repository__c gitRepo = new Git_Repository__c();
            PageReference pref = Page.EditOrg;
            pref.getParameters().put('id',null);
            Test.setCurrentPage(pref);

            EditGit editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
            editGitController.git.Name = 'MyRepoName';
            editGitController.git.Source_Format__c = 'Metadata';
            editGitController.authTypeValue = 'SSH';
            editGitController.git.URI__c = 'git@github.com:myuser/myrepo.git';
            editGitController.git.Git_Provider__c = 'Github';

            Pagereference returnSave = editGitController.save();
            Test.startTest();
            Git_Repository__c newGitRepo = [SELECT Id, Name FROM Git_Repository__c WHERE Name = 'MyRepoName' LIMIT 1];

            returnSave.getParameters().put('id', newGitRepo.Id);
            Test.setCurrentPage(returnSave);

            String validationError = 'error';
	        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(validationError, null));
            editGitController.validate();
            String errorMessage = Apexpages.getMessages()[0].getDetail();
            System.assert(errorMessage.contains(Label.WRONG_CREDENTIALS));

            // Create SSH Key. 
            String sshKeyRepsonse = '{"ok": "Keys created"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(sshKeyRepsonse, null));
            Pagereference sshKeyCreation = editGitController.createSSHKey();
            // Backend call creates an Attachment with the key.
            Attachment sshKeyAttchament = new Attachment(Name='id_rsa.pub', Body=Blob.valueOf('testSshKey'), ParentId=newGitRepo.Id);
            insert sshKeyAttchament;

            editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
            editGitController.selectedKeyId = sshKeyAttchament.Id;
            editGitController.viewKey();
            System.assertEquals(true, editGitController.hasKeys);
            System.assertEquals(true, editGitController.keyVisible);

            editGitController.hideSSHkey();
            editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
            editGitController.selectedKeyId = sshKeyAttchament.Id;
            System.assertEquals(true, editGitController.hasKeys);
            System.assertEquals(false, editGitController.keyVisible);

            editGitController.deleteKey();
            editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
            System.assertEquals(false, editGitController.hasKeys);
            List<Attachment> deletedKey = [SELECT Id FROM Attachment WHERE Id = :sshKeyAttchament.Id];
            System.assert(deletedKey.isEmpty());
            
            System.assertEquals(true, editGitController.isSSHauthentication);

            Test.stopTest();
        }
    }
    // Create Git repository Https
    @IsTest
    static void createHttpsGitrepository() {
        User standardUser = [SELECT Id,Name,Email,Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
        
        System.runAs(standardUser){
            Git_Repository__c gitRepo = new Git_Repository__c();
            PageReference pref = Page.EditOrg;
            pref.getParameters().put('id',null);
            Test.setCurrentPage(pref);

            EditGit editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
            editGitController.git.Name = 'MyRepoName';
            editGitController.git.Source_Format__c = 'Metadata';
            editGitController.authTypeValue = 'Https';
            editGitController.git.URI__c = 'https://github.com/myuser/myrepo.git';
            editGitController.git.Git_Provider__c = 'Github';
            editGitController.c_username = 'myreposusername@copado.com';
            editGitController.c_password = 'MyrepoPasswd';

            Pagereference returnSave = editGitController.save();
            Test.startTest();
            Git_Repository__c newGitRepo = [SELECT Id, Name FROM Git_Repository__c WHERE Name = 'MyRepoName' LIMIT 1];

            returnSave.getParameters().put('id', newGitRepo.Id);
            Test.setCurrentPage(returnSave);

            String b = '{"success":true}';
	        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
            editGitController.validate();
            String successMessage = Apexpages.getMessages()[0].getDetail();
            System.assert(successMessage.contains(Label.OK_CREDENTIALS));
            
            Test.stopTest();
        }
    }
}