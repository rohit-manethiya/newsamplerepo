/**
 * Created by dineshdk on 23/08/2018.
 */

@isTest
private class TestGenericMDAPIDiffCSV {

    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    @isTest
    static void TestViewSnapDiffCSVWithJson() {

        TestUtilities tu = new TestUtilities();
        List<Org__c> orgLst = new List<Org__c>();

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), null);
        orgLst.add(testOrg1);

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), null);
        orgLst.add(testOrg2);

        insert orgLst;

        Snapshot_Difference__c sn = (Snapshot_Difference__c) tu.insertSObject('Snapshot_Difference__c', new Map<String,Object>{
                'Source_Org_Credential__c' => testOrg1.Id,
                'Destination_Org_Credential__c' => testOrg2.Id,
                'Name' => 'test',
                'Source_Option__c' => 'Salesforce Org',
                'Destination_Option__c' => 'Salesforce Org'

        });
        snapshotDifferenceExtension ext = new snapshotDifferenceExtension(new ApexPages.StandardController(sn));
        Id recordId = ApexPages.currentPage().getParameters().put('Id', sn.Id);
        String currentPage = ApexPages.currentPage().getParameters().put('currentPage', 'SnapshotDifferenceCSV');

        Attachment attach = (Attachment) tu.insertSObject('Attachment', new Map<String,Object>{
                'name' => 'index.json',
                'body' => Blob.valueOf('[{"f":"objects/Speaker__c.object","s":false,"d":"create","n":"Speaker__c","t":"CustomObject"}]'),
                'parentId' => sn.Id
        });
        ApexPages.StandardController sc = new ApexPages.standardController(sn);
        GenericMDAPIDiffCSV genericMDAPIDiffCSV = new GenericMDAPIDiffCSV(sc);
        GenericMDAPIDiffCSV.JsonWrapperSnapDiff jsonWrapper = new GenericMDAPIDiffCSV.JsonWrapperSnapDiff();
        jsonWrapper.f = 'test';
        jsonWrapper.s = true;
        jsonWrapper.d = 'test';
        jsonWrapper.n = 'test';
        jsonWrapper.t = 'test';
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Parent.Id = :sn.Id LIMIT 1];
        System.assertEquals(1, attachments.size());
        System.assertEquals('index.json', attachments[0].Name);
    }

    @isTest
    static void TestViewOrgDiffCSVWithJson() {

        TestUtilities tu = new TestUtilities();
        Org__c org1 = (Org__c) tu.insertSObject('Org__c', new Map<String,Object>{
                'name' => 'x'
        });

        Org__c org2 = (Org__c) tu.insertSObject('Org__c', new Map<String,Object>{
                'name' => 'y'
        });

        OrgDiff__c orgDiff1 = (OrgDiff__c) tu.insertSObject('OrgDiff__c', new Map<String,Object>{
                'name' => 'd1',
                'from_Org__c' => org1.Id,
                'to_Org__c' => org2.Id
        });

        Attachment attach = (Attachment) tu.insertSObject('Attachment', new Map<String,Object>{
                'name' => 'OrgDiff',
                'body' => Blob.valueOf('[{"t":"Certificate","n":"SelfSignedCert_18Jun2018_120656","s":"create","d":null,"b":"Dineshkumar rajamani","cd":"2018-06-18","cb":"Dineshkumar rajamani"}]'),
                'parentId' => orgDiff1.Id
        });

        Test.startTest();
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Org Difference'));
        System.assert(orgDiff1.Id != null);
        Id recordId = ApexPages.currentPage().getParameters().put('Id', orgDiff1.Id);
        String currentPage = ApexPages.currentPage().getParameters().put('currentPage', 'ViewOrgDiffCSV');
        ApexPages.StandardController sc = new ApexPages.standardController(orgDiff1);
        GenericMDAPIDiffCSV genericMDAPIDiffCSV = new GenericMDAPIDiffCSV(sc);
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