@IsTest
public class TestAbstractArtifact {
    @TestSetup 
    static void setup() {
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        createTestData();
    }

    @IsTest
    static void loadGitArtifact() {
        setMockHttpResponse();
        createArtifactAndVersion('Git Package', null);

        Org__c scratchOrgCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13-Scratch-Org' LIMIT 1];
        Org__c devCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13' LIMIT 1];

        ScratchOrgMetadataController_t controller_t = new ScratchOrgMetadataController_t();
        controller_t.setSelectedOrgIdFromDxOperation(scratchOrgCredential.Id)
                    .setArtifactType('artifact')
                    .selectType()
                    .setSelectedOrgId(devCredential.Id)
                    .getOrgArtifacts()
                    .setSelectedArtifactIds(new List<Id>{ controller_t.getArtifactOptions()[0].getValue() })
                    .updateSourceSelections();

        Test.startTest();
        PageReference actualPage = controller_t.loadMetadata();
        Test.stopTest();

        PageReference expectedPage = Page.DXOperation;
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    static void loadPatchArtifact() {
        setMockHttpResponse();
        createArtifactAndVersion('Git Package', null);

        Org__c scratchOrgCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13-Scratch-Org' LIMIT 1];
        Org__c devCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13' LIMIT 1];

        ScratchOrgMetadataController_t controller_t = new ScratchOrgMetadataController_t();
        controller_t.setSelectedOrgIdFromDxOperation(scratchOrgCredential.Id)
                    .setArtifactType('patch')
                    .selectType()
                    .setSelectedOrgId(devCredential.Id)
                    .getOrgArtifacts()
                    .setSelectedArtifactIds(new List<Id>{ controller_t.getArtifactOptions()[0].getValue() })
                    .updateSourceSelections();

        Test.startTest();
        PageReference actualPage = controller_t.loadMetadata();
        Test.stopTest();

        PageReference expectedPage = Page.DXOperation;
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    static void loadBranchArtifact() {
        setMockHttpResponse();
        createArtifactAndVersion('Git Package', null);

        Org__c scratchOrgCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13-Scratch-Org' LIMIT 1];
        Org__c devCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13' LIMIT 1];

        ScratchOrgMetadataController_t controller_t = new ScratchOrgMetadataController_t();
        controller_t.setSelectedOrgIdFromDxOperation(scratchOrgCredential.Id)
                    .setArtifactType('branch')
                    .selectType()
                    .setSelectedOrgId(devCredential.Id)
                    .getOrgArtifacts()
                    .setSelectedArtifactIds(new List<Id>{ controller_t.getArtifactOptions()[0].getValue() })
                    .updateSourceSelections();

        Test.startTest();
        PageReference actualPage = controller_t.loadMetadata();
        Test.stopTest();

        PageReference expectedPage = Page.DXOperation;
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    static void loadUnlockedArtifact() {
        setMockHttpResponse();
        createArtifactAndVersion('Salesforce Package', 'Unlocked');

        Org__c scratchOrgCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13-Scratch-Org' LIMIT 1];
        Org__c devCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13' LIMIT 1];

        ScratchOrgMetadataController_t controller_t = new ScratchOrgMetadataController_t();
        controller_t.setSelectedOrgIdFromDxOperation(scratchOrgCredential.Id)
                    .setArtifactType('unlocked')
                    .selectType()
                    .setSelectedOrgId(devCredential.Id)
                    .getOrgArtifacts()
                    .setSelectedArtifactId(controller_t.getArtifactOptions()[1].getValue())
                    .populateArtifactVersions()
                    .setSelectedVersionId(controller_t.getArtifactVersionOptions()[1].getValue())
                    .addValuesToSelectedPackages();

        Test.startTest();
        PageReference actualPage = controller_t.loadMetadata();
        Test.stopTest();

        PageReference expectedPage = Page.DXOperation;
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    static void loadSecondGenerationArtifact() {
        setMockHttpResponse();
        createArtifactAndVersion('Salesforce Package', 'Second-Generation Package');
        
        Org__c scratchOrgCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13-Scratch-Org' LIMIT 1];
        Org__c devCredential = [SELECT Id FROM Org__c WHERE Name = 'DEV-13' LIMIT 1];

        ScratchOrgMetadataController_t controller_t = new ScratchOrgMetadataController_t();
        controller_t.setSelectedOrgIdFromDxOperation(scratchOrgCredential.Id)
                    .setArtifactType('managed')
                    .selectType()
                    .setSelectedOrgId(devCredential.Id)
                    .getOrgArtifacts()
                    .setSelectedArtifactId(controller_t.getArtifactOptions()[1].getValue())
                    .populateArtifactVersions()
                    .setSelectedVersionId(controller_t.getArtifactVersionOptions()[1].getValue())
                    .addValuesToSelectedPackages();

        Test.startTest();
        PageReference actualPage = controller_t.loadMetadata();
        Test.stopTest();

        PageReference expectedPage = Page.DXOperation;
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    private static void createTestData() {
        Git_Repository__c repository = new Git_Repository__c(Name = 'DEV-13-Repository');
        insert repository;

        List<Environment__c> environments = new List<Environment__c>();
        Environment__c devEnvironment = CMTestMethodUtilities.createEnvironment('DEV-13', '000000000000000002');
        environments.add(devEnvironment);
        Environment__c devHubEnvironment = CMTestMethodUtilities.createEnvironment('DEV-HUB-13', '000000000000000001');
        environments.add(devHubEnvironment);
        Environment__c scratchOrgEnvironment = CMTestMethodUtilities.createEnvironment('DEV-13-Scratch-Org', '000000000000000000');
        environments.add(scratchOrgEnvironment);
        insert environments;

        Org__c devCredential = CMTestMethodUtilities.createOrg('DEV-13', 'Production', '000000000000000002', null, null, System.now(), devEnvironment.Id);
        insert devCredential;
        Org__c devHubCredential = CMTestMethodUtilities.createOrg('DEV-HUB-13', 'Production', '000000000000000001', null, null, System.now(), devHubEnvironment.Id);
        devHubCredential.is_Developer_Hub_Org__c = true;
        insert devHubCredential;
        Org__c scratchOrgCredential = CMTestMethodUtilities.createOrg('DEV-13-Scratch-Org', 'Scratch Org', '000000000000000000', null, null, System.now(), scratchOrgEnvironment.Id);
        scratchOrgCredential.Developer_Hub_Org__c = devHubCredential.Id;
        insert scratchOrgCredential;
    }

    private static void setMockHttpResponse() {
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"status":0,"copadoJobId":"testcopadoJobId","result":{"Id":"0Hof2000000PAx3CAG"}}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
    }

    private static void createArtifactAndVersion(String recordType, String packageType) {
        Artifact__c artifact = createArtifact(recordType, packageType);
        insert artifact;
        Artifact_Version__c version = createArtifactVersion(artifact.Id);
        insert version;
        artifact.Artifact_Version__c = version.Id;
        update artifact;
    }

    private static Artifact__c createArtifact(String recordType, String packageType) {
        Id packageArtifactRecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        Git_Repository__c repository = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'DEV-13-Repository'];
        List<Org__c> orgs = [SELECT Id, Name FROM Org__c WHERE Name IN ('DEV-HUB-13','DEV-13')];
        Map<String, Id> credentialMap = new Map<String, Id>();
        for (Org__c org : orgs) {
            credentialMap.put(org.Name, org.Id);
        }
        Artifact__c artifact = new Artifact__c(
            Name = 'DEV_13_ARTIFACT',
            Source_Api_Version__c = '43.0',
            Sfdc_Login_Url__c = 'https://login.salesforce.com',
            RecordTypeId = packageArtifactRecordTypeId,
            Artifact_Repository__c = repository.Id,
            Target_Dev_Hub_Org__c = credentialMap.get('DEV-HUB-13'),
            Package_Type__c = packageType,
            Org_Credential__c = credentialMap.get('DEV-13'),
            Package_Id__c = '000000111111',
            Description__c = '',
            Package_Namespace__c = 'dev_test_namespace'
        );
        return artifact;
    }

    private static Artifact_Version__c createArtifactVersion(Id artifactId) {
        Artifact_Version__c version = new Artifact_Version__c();
        version.Name = 'DEV_13_ARTIFACT_VERSION';
        version.Subscriber_Version_Id__c = '000000111111';
        version.Artifact__c = artifactId;
        return version;
    }
}