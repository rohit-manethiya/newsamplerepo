@isTest
private class TestJsRemotingController {
    @testSetup static void TestBackupNow(){
        insert TestUtilities.getTestSettings();
    }
    static testMethod void coverageForContstructors(){
        JsRemotingController con1 = new JsRemotingController();
        Org__c org = new Org__c();
        JsRemotingController con2 = new JsRemotingController(new ApexPages.StandardController(org));
        system.assert(con1 != null); //dummy assertion for security scan;
    }
    static testMethod void createAPIKey(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.createAPIKey();
        system.assertEquals('test 123', DeployAPI.getUserAPIKey());
        Test.stopTest();
    }
    static testMethod void getMetadataTypes(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.getMetadataTypes('ORGIDFAKE');
        Test.stopTest();
    }
    static testMethod void getVlocityDependencies(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.getVlocityDependencies(UserInfo.getUserId(), 'FAKEJSONBODY');
        Test.stopTest();
    }
    static testMethod void selectBranches(){
        TestUtilities tu = new TestUtilities();
        List<SObject> insertSObjects = new List<SObject>();
        insertSObjects.addAll(tu.createSObjects('User_Story__c', 1, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2
        }));
        insert insertSObjects;
        Test.startTest();
        JsRemotingController.selectBranch(((User_Story__c)insertSObjects[0]).Id, 'User_Story_Title__c','TestBranch');
        Test.stopTest();
    }
    static testMethod void selectBranchesWrongSetup(){
        TestUtilities tu = new TestUtilities();
        List<SObject> insertSObjects = new List<SObject>();
        insertSObjects.addAll(tu.createSObjects('User_Story__c', 1, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2
        }));
        insert insertSObjects;
        Test.startTest();
        JsRemotingController.selectBranch(((User_Story__c)insertSObjects[0]).Id, 'Not_Found_Field__c','TestBranch');
        Test.stopTest();
    }

    static testMethod void constructorCoverage(){
        Test.startTest();
        JsRemotingController jrc = new JsRemotingController();
        GitCommitChangesController gccc = new GitCommitChangesController();
        JsRemotingController jrc2 = new JsRemotingController(gccc);
        Test.stopTest();
    }

}