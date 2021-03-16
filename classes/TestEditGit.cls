@IsTest
private class TestEditGit {

    @TestSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }

    static testMethod void testSuccess() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.EditOrg;
	    pref.getParameters().put('id',null);
	    Test.setCurrentPage(pref);
	    
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
	    ext.git = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test','http://www.bitbucket.org/');
		pref = ext.save();
		System.assert(pref.getUrl() != Page.EditOrg.getUrl());
		
		Git_Repository__c g = [SELECT Id FROM Git_Repository__c WHERE Name='%$£GFDS!P@Copado_test' LIMIT 1];
		pref = Page.EditOrg;
	    pref.getParameters().put('id',g.Id);
	    Test.setCurrentPage(pref);
		
		Test.startTest();
		String b = '{"Status":"Ok"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(testMethodUtilities.hasMessage(Label.OK_CREDENTIALS));
		Test.stopTest();
    }

    static testMethod void testError() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.EditOrg;
	    pref.getParameters().put('id',null);
	    Test.setCurrentPage(pref);
	    
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
	    ext.git = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2','http://www.bitbucket.org/');
		pref = ext.save();
		System.assert(pref.getUrl() != Page.EditOrg.getUrl());
		
		Git_Repository__c g = [SELECT Id FROM Git_Repository__c WHERE Name='%$£GFDS!P@Copado_test2' LIMIT 1];
		pref = Page.EditOrg;
	    pref.getParameters().put('id',g.Id);
	    Test.setCurrentPage(pref);
		Test.startTest();
		String b = 'error';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(testMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));
		Test.stopTest();
    }

    static testMethod void testExistingGitRepo() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2','http://www.bitbucket.org/');
        insert gitRepo;
        PageReference pref = Page.EditOrg;
	    pref.getParameters().put('id', gitRepo.Id);
	    Test.setCurrentPage(pref);
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
		
		Test.startTest();
		String b = 'error';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(testMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));
		Test.stopTest();
    }

    static testMethod void testSSH(){
        testMethodUtilities.upsertOrgwideSettings();
        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2','git@test.org');
        insert gitRepo;
        Sensitive_Information__c gitRepositoryConfiguration = new Sensitive_Information__c(Name = gitRepo.Id,Username__c = 'umit@theoffi.ce',Password__c = 'somethingHashed!');
        insert gitRepositoryConfiguration;
        PageReference pref = Page.viewGit;
	    pref.getParameters().put('id', gitRepo.Id);
	    Test.setCurrentPage(pref);

	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
        Test.startTest();
		System.assertEquals(false, ext.keyVisible);
        System.assertEquals(false, ext.hasKeys);
        System.assertEquals(true, ext.isSSHauthentication);
        
        String b = '{"ok": "Keys created"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        PageReference resultRef = ext.createSSHKey();
        Attachment att1 = new Attachment(Name='id_rsa.pub', Body=Blob.valueOf('test'), ParentId=ext.git.Id);
        insert att1;
        PageReference pr = new ApexPages.StandardController(ext.git).view();
        System.assertEquals(pr.getUrl(), resultRef.getUrl());
        List<Attachment> result = new List<Attachment>();
        result = [SELECT Id, Name, Body FROM Attachment WHERE ParentId=:ext.git.Id AND Name=:ext.KEYNAME];
        System.assertEquals(1, result.size());
        ext = new EditGit(new ApexPages.StandardController(gitRepo));
        System.assertEquals(false, ext.keyVisible);
        System.assertEquals(true, ext.hasKeys);

        ext.selectedKeyId = result.get(0).Id;
        ext.viewKey();
        System.assertEquals(true, ext.keyVisible);
        System.assertEquals(result[0].Body.toString(), ext.selectedKeyContent);
        PageReference pr1 = new ApexPages.StandardController(ext.git).view();
        System.assertEquals(pr1.getUrl(), ext.hideSSHkey().getUrl());
        
        ext.selectedKeyId = result.get(0).Id;
        ext.viewKey();
        System.assertEquals(true, ext.keyVisible);
        ext.selectedKeyId = result.get(0).Id;

        System.assertEquals(new ApexPages.StandardController(ext.git).view().getUrl(), ext.deleteKey().getUrl());
        result = [SELECT Id, Name, Body FROM Attachment WHERE ParentId=:ext.git.Id AND Name=:ext.KEYNAME];
        System.assertEquals(0, result.size());
                
        ext.deleteKey();
        result = new List<Attachment>();
        result = [SELECT Id, Name, Body FROM Attachment WHERE ParentId=:ext.git.Id AND Name=:ext.KEYNAME];
        System.assertEquals(0, result.size());
        ext.getCommits();
        ext.deployCommits();
        ext.retrieveCommits();
        ext.goToManageGITBranches();
        Test.stopTest();
    }

    static testMethod void saveWithEmptyFields() {
        testMethodUtilities.upsertOrgwideSettings();
        // Start with null GIT
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.EditOrg;
        pref.getParameters().put('id',null);
        Test.setCurrentPage(pref);


        EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
        pref = ext.save();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        Boolean messageFound = false;
        String detail = '';

        // Check that the error message you are expecting is in pageMessages
        for(ApexPages.Message message : pageMessages) {
            detail = Label.Please_Enter + ' ' + Schema.SObjectType.Git_Repository__c.fields.Name.getLabel();
            if(message.getDetail() == detail && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        // fill name and save again
        ext.git.Name = 'Test';
        messageFound = false;
        detail = '';
        pref = ext.save();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        // Check that the error message you are expecting is in pageMessages
        for(ApexPages.Message message : pageMessages) {
            detail = Label.Please_Enter + ' ' + Schema.SObjectType.Git_Repository__c.fields.URI__c.getLabel();
            if(message.getDetail() == detail && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        // fill uri and save again
        ext.authTypeValue = 'ssh';
        ext.git.URI__c = 'https://test';
        messageFound = false;
        detail = '';
        pref = ext.save();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        // Check that the error message you are expecting is in pageMessages
        for(ApexPages.Message message : pageMessages) {
            detail = Label.SSH_URI_validation;
            if(message.getDetail() == detail && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        // fill uri with https and save again
        ext.authTypeValue = 'https';
        ext.git.URI__c = 'https://test';
        messageFound = false;
        detail = '';
        pref = ext.save();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        // Check that the error message you are expecting is in pageMessages
        for(ApexPages.Message message : pageMessages) {
            detail = Label.Please_Enter + ' ' + Label.USERNAME;
            if(message.getDetail() == detail && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        // fill username and save again
        ext.c_username = 'test';
        messageFound = false;
        detail = '';
        pref = ext.save();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        // Check that the error message you are expecting is in pageMessages
        for(ApexPages.Message message : pageMessages) {
            detail = Label.Please_Enter + ' ' + Label.PASSWORD;
            if(message.getDetail() == detail && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        // fill password and save again
        ext.c_password = 'test';
        pref = ext.save();
    }

    static testMethod void test_PopulatingBaseURLFields() {
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.EditOrg;
        pref.getParameters().put('id',null);
        Test.setCurrentPage(pref);

        EditGit editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
        pref = editGitController.save();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        editGitController.git.Git_Provider__c = 'Github';
        editGitController.populateURLFields();
        editGitController.git.Git_Provider__c = 'Bitbucket';
        editGitController.populateURLFields();
        editGitController.git.Git_Provider__c = 'GitLab';
        editGitController.populateURLFields();
        editGitController.git.Git_Provider__c = 'Microsoft Team Service';
        editGitController.populateURLFields();
        editGitController.git.Git_Provider__c = 'Others';
        editGitController.populateURLFields();
    }
    static testMethod void test_DeleteGitRepository() {
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.EditOrg;
        pref.getParameters().put('id', null);
        Test.setCurrentPage(pref);


        EditGit editGitController = new EditGit(new ApexPages.StandardController(gitRepo));
        editGitController.git = testMethodUtilities.createGitRepository('%$£GFDS!P@Copado_test2', 'http://www.bitbucket.org/');
        pref = editGitController.save();
        System.assert(pref.getUrl() != Page.EditOrg.getUrl());

        editGitController.deleteGitRepository();
    }
}