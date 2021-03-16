@isTest
public class TestMetadataselectorExtension {
    @testSetup static void setupTestData(){
        insert TestUtilities.getTestSettings();
    }
    static testMethod void testmode_missingSourceOrg(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = null;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/MetadataSelector?id='+testUserStory.Id+'&mode=Metadata');
        Test.setCurrentPageReference(pageRef);
        MetadataselectorExtension ext = new MetadataselectorExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assertEquals(false, ext.hasOrg);
        system.assert(testMethodUtilities.hasMessage(Label.NO_ORG_CREDENTIAL_ON_USER_STORY));
        Test.stopTest();
    }
    static testMethod void testmode_metadata(){
        Org__c testOrg = new Org__c(Name='testOrg');
        insert testOrg;
        
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = testOrg.Id;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/MetadataSelector?id='+testUserStory.Id+'&mode=Metadata');
        Test.setCurrentPageReference(pageRef);
        MetadataselectorExtension ext = new MetadataselectorExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assertEquals(true, ext.hasOrg);
        system.assert(!ext.metadata_url.contains('/testClasses/'));
        Test.stopTest();
    }
    static testMethod void testmode_apextests(){
        Org__c testOrg = new Org__c(Name='testOrg');
        insert testOrg;
        
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = testOrg.Id;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/MetadataSelector?id='+testUserStory.Id+'&mode=ApexTests');
        Test.setCurrentPageReference(pageRef);
        MetadataselectorExtension ext = new MetadataselectorExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assertEquals(true, ext.hasOrg);
        system.assert(ext.metadata_url.contains('/testClasses/'));
        
        //Now test showmessage();
        ext.errorLevel = 'WARNING';
        ext.messageName = 'WARNING MSG';
        ext.showMessage();
        system.assert(testMethodUtilities.hasMessage('WARNING MSG'));
        
        ext.errorLevel = 'ERROR';
        ext.messageName = 'ERROR MSG';
        ext.showMessage();
        system.assert(testMethodUtilities.hasMessage('ERROR MSG'));
        
        ext.errorLevel = 'CONFIRM';
        ext.messageName = 'CONFIRM MSG';
        ext.showMessage();
        system.assert(testMethodUtilities.hasMessage('CONFIRM MSG'));
        
        ext.openAddTestClass();
        Test.stopTest();
    }
}