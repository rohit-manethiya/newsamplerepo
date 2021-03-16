@isTest
private class TestMaddAddOrg {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testAdd_Success(){
        Org__c masterOrg = TestMethodUtilities.createOrg('OrgNameM','Production','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        Org__c testOrg1 = TestMethodUtilities.createOrg('OrgName1','Production','SFDC_OrgId1','SFDC_TOKEN','USERNAME1', System.now());
        Org__c testOrg2 = TestMethodUtilities.createOrg('OrgName2','Production','SFDC_OrgId2','SFDC_TOKEN','USERNAME2', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        orgs.add(testOrg1);
        orgs.add(testOrg2);
        insert orgs;
        
        Deployment__c oldDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert oldDeployment;
        Destination_Org__c testDestOrg1 = TestMethodUtilities.create(oldDeployment.Id,'Draft',testOrg1.Id);
        Destination_Org__c testDestOrg2 = TestMethodUtilities.create(oldDeployment.Id,'Draft',testOrg2.Id);
        insert testDestOrg1;
        insert testDestOrg2;
        
        Deployment__c newDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        ext.orgs = orgs;
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.add();
        System.assertEquals(new PageReference('/'+newDeployment.Id).getUrl(), result.getUrl());
        System.assertEquals(2,[SELECT Id FROM Destination_Org__c WHERE Deployment__c=:newDeployment.Id].size());
        Test.stopTest();
    }
    static testMethod void test_Cancel(){
        Org__c masterOrg = TestMethodUtilities.createOrg('OrgNameM','Production','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        Org__c testOrg1 = TestMethodUtilities.createOrg('OrgName1','Production','SFDC_OrgId1','SFDC_TOKEN','USERNAME1', System.now());
        Org__c testOrg2 = TestMethodUtilities.createOrg('OrgName2','Production','SFDC_OrgId2','SFDC_TOKEN','USERNAME2', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        orgs.add(testOrg1);
        orgs.add(testOrg2);
        insert orgs;
        
        Deployment__c oldDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert oldDeployment;
        Destination_Org__c testDestOrg1 = TestMethodUtilities.create(oldDeployment.Id,'Draft',testOrg1.Id);
        Destination_Org__c testDestOrg2 = TestMethodUtilities.create(oldDeployment.Id,'Draft',testOrg2.Id);
        insert testDestOrg1;
        insert testDestOrg2;
        
        Deployment__c newDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        ext.orgs  =orgs;
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.cancel();
        ID resultID = testOrg1.Id;
        Test.stopTest();
        System.assert(result != null);
    }
    static testMethod void test_Add_Error(){
        Org__c masterOrg = TestMethodUtilities.createOrg('OrgNameM','Production','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        
        Deployment__c oldDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),masterOrg.Id,'Deploy now','Pending');
        insert oldDeployment;
        
        Deployment__c newDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),masterOrg.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        pref.getParameters().put('id',masterOrg.Id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.add();
        System.assertEquals(null, result);
        System.assert(TestMethodUtilities.hasMessage(Label.SELECT_AT_LEAST_ONE_RECORD));
        Test.stopTest();
    }
}