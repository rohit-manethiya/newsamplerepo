/**
 * Created by dineshdk on 20/08/2018.
 */

@isTest
private class TestViewOrgDiffCSV {

    @testSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    @isTest
    static void TestViewOrgDiffCSVWithJson() {
        List<Org__c> orgLst = new List<Org__c>();
        Org__c org1 = new Org__c(Name = 'x');
        orgLst.add(org1);
        Org__c org2 = new Org__c(Name = 'y');
        orgLst.add(org2);
        insert orgLst;

        Test.startTest();
        OrgDiff__c orgDiff1 = new OrgDiff__c(Name = 'd1', From_Org__c = org1.Id, To_Org__c = org2.Id);
        insert orgDiff1;
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Org Difference'));
        System.assert(orgDiff1.Id != null);

        Id recordId = ApexPages.currentPage().getParameters().put('Id', orgDiff1.Id);
        ApexPages.currentPage().getParameters().put('currentPage', 'ViewOrgDiffCSV');
        Attachment attach = new Attachment();
        attach.Name = 'OrgDiff';
        Blob bodyBlob = Blob.valueOf('[{"t":"Certificate","n":"SelfSignedCert_18Jun2018_120656","s":"create","d":null,"b":"Dineshkumar rajamani","cd":"2018-06-18","cb":"Dineshkumar rajamani"}]');
        attach.Body = bodyBlob;
        attach.ParentId = orgDiff1.Id;
        insert attach;
        ApexPages.StandardController sc = new ApexPages.StandardController(orgDiff1);
        GenericMDAPIDiffCSV orgDiffCSV = new GenericMDAPIDiffCSV(sc);
        GenericMDAPIDiffCSV.JsonWrapperOrgDiff jsonWrapper = new GenericMDAPIDiffCSV.JsonWrapperOrgDiff();
        jsonWrapper.t = 'test';
        jsonWrapper.n = 'test';
        jsonWrapper.s = 'test';
        jsonWrapper.d = 'test';
        jsonWrapper.b = 'test';
        jsonWrapper.cb = 'test';
        jsonWrapper.cd = 'test';

        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Parent.Id = :orgDiff1.Id LIMIT 1];
        System.assertEquals(1, attachments.size());
        System.assertEquals('OrgDiff', attachments[0].Name);
        Test.stopTest();
    }

    @isTest
    static void TestViewOrgDiffCSVWithoutJson() {
        List<Org__c> orgLst = new List<Org__c>();
        Org__c org1 = new Org__c(Name = 'x');
        orgLst.add(org1);
        Org__c org2 = new Org__c(Name = 'y');
        orgLst.add(org2);
        insert orgLst;
        OrgDiff__c orgDiff1 = new OrgDiff__c(Name = 'd1', From_Org__c = org1.Id, To_Org__c = org2.Id);
        insert orgDiff1;

        Test.startTest();
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Org Difference'));
        System.assert(orgDiff1.Id != null);
        Id recordId = ApexPages.currentPage().getParameters().put('Id', orgDiff1.Id);
        ApexPages.currentPage().getParameters().put('currentPage', 'ViewOrgDiffCSV');
        Attachment attach = new Attachment();
        attach.Name = 'OrgDiff';
        Blob bodyBlob = Blob.valueOf('[]');
        attach.Body = bodyBlob;
        attach.ParentId = orgDiff1.Id;
        insert attach;
        ApexPages.StandardController sc = new ApexPages.StandardController(orgDiff1);
        GenericMDAPIDiffCSV orgDiffCSV = new GenericMDAPIDiffCSV(sc);
        GenericMDAPIDiffCSV.JsonWrapperOrgDiff jsonWrapper = new GenericMDAPIDiffCSV.JsonWrapperOrgDiff();
        jsonWrapper.t = 'test';
        jsonWrapper.n = 'test';
        jsonWrapper.s = 'test';
        jsonWrapper.d = 'test';
        jsonWrapper.b = 'test';
        jsonWrapper.cb = 'test';
        jsonWrapper.cd = 'test';

        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Parent.Id = :orgDiff1.Id LIMIT 1];
        System.assertEquals(1, attachments.size());
        System.assertEquals('OrgDiff', attachments[0].Name);
        Test.stopTest();
    }
}