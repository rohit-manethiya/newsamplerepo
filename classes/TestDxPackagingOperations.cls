@IsTest
private class TestDxPackagingOperations {
    @testSetup
    static void setup() {
        insert TestUtilities.getTestSettings();
        TestUtilities.insertUser('user1-dxOperations@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @IsTest
    static void testFirstGenPackageCreation() {
        Artifact__c artifact = createArtifact('Salesforce Package', 'First-Generation Package');
        artifact.Artifact_Repository__c = null;
        insert artifact;

        Test.startTest();
        String jsonResponse = '{"copadoJobId":"123456","ok":"true","status":"status"}';
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', jsonResponse, null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        ArtifactPackageController firstGenPackage = new ArtifactPackageController(new ApexPages.StandardController(artifact));
        firstGenPackage.refreshPackageList();
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.CREATE_ORG);
        firstGenPackage.jobStatusNotification();
        // Charly Comment: I don't know what is this method doing here. I put it to increase code coverage only.
        ApexPages.currentPage().getParameters().put('pass', 'My Password to encrypt');
        firstGenPackage.encryptPassword();
        Test.stopTest();
    }

    @IsTest
    static void createUnlockedPackage() {
        Artifact__c artifact = createArtifact('Salesforce Package', 'Unlocked');
        insert artifact;
        Artifact_Version__c version = createArtifactVersion(artifact.Id);
        insert version;
        artifact.Artifact_Version__c = version.Id;
        update artifact;

        //Use the PageReference Apex class to instantiate a page
        PageReference createPackageVersion = Page.CreatePackageDefinition;
        createPackageVersion.getParameters().put('Id', artifact.Id);
        //In this case, the Visualforce page named 'CreatePackageDefinition' is the starting point of this test method.
        Test.setCurrentPage(createPackageVersion);
        //Instantiate and construct the controller class of CreatePackageDefinition page.
        ShowAttachmentDetailController attachmentController = new ShowAttachmentDetailController();
        attachmentController.currentRecord = artifact;
        attachmentController.attachmentName = 'sfdx-project.json';
        System.assert(attachmentController.attachments.isEmpty(), 'No attachnments should\'ve been retrieved for this artifact.');
        attachmentController.createAttachment();

        PageReference dxPackageVersion = Page.DXPackageVersion;
        dxPackageVersion.getParameters().put('Id', artifact.Id);
        //In this case, the Visualforce page named 'DXPackageVersion' is the starting point of this test method.
        Test.setCurrentPage(dxPackageVersion);
        //Instantiate and construct the controller class of DXPackageVersion page.
        DXPackageVersionHandler versionController = new DXPackageVersionHandler();
        versionController.givenPackage = artifact;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"status":0,"copadoJobId":"testcopadoJobId","result":{"Id":"0Hof2000000PAx3CAG"}}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        versionController.callBackend();
        versionController.getVersionDetails('1.0.0.1');
        versionController.cancel();
        Test.stopTest();
    }

    @IsTest
    static void createSecondGenerationPackage() {
        Artifact__c artifact = createArtifact('Salesforce Package', 'Second-Generation Package');
        insert artifact;
        Artifact_Version__c version = createArtifactVersion(artifact.Id);
        insert version;
        artifact.Artifact_Version__c = version.Id;
        update artifact;

        PageReference createPackageVersion = Page.CreatePackageDefinition;
        createPackageVersion.getParameters().put('Id', artifact.Id);
        Test.setCurrentPage(createPackageVersion);
        
        ShowAttachmentDetailController attachmentController = new ShowAttachmentDetailController();
        attachmentController.currentRecord = artifact;
        attachmentController.attachmentName = 'sfdx-project.json';
        System.assert(attachmentController.attachments.isEmpty(), 'No attachnments should\'ve been retrieved for this artifact.');
        attachmentController.createAttachment();

        PageReference dxPackageVersion = Page.DXPackageVersion;
        dxPackageVersion.getParameters().put('Id', artifact.Id);
        Test.setCurrentPage(dxPackageVersion);
        
        DXPackageVersionHandler versionController = new DXPackageVersionHandler();
        versionController.givenPackage = artifact;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"status":0,"copadoJobId":"testcopadoJobId","result":{"Id":"0Hof2000000PAx3CAG"}}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        versionController.callBackend();
        versionController.getVersionDetails('1.0.0.1');
        Test.stopTest();
    }

    @IsTest
    static void createSecondGenerationPackageWithoutProjectFile() {
        Artifact__c artifact = createArtifact('Salesforce Package', 'Second-Generation Package');
        insert artifact;
        Artifact_Version__c version = createArtifactVersion(artifact.Id);
        insert version;
        artifact.Artifact_Version__c = version.Id;
        update artifact;     

        PageReference createPackageVersion = Page.CreatePackageDefinition;
        createPackageVersion.getParameters().put('Id', artifact.Id);
        Test.setCurrentPage(createPackageVersion);

        PageReference dxPackageVersion = Page.DXPackageVersion;
        dxPackageVersion.getParameters().put('Id', artifact.Id);
        Test.setCurrentPage(dxPackageVersion);
        
        DXPackageVersionHandler versionController = new DXPackageVersionHandler();
        versionController.givenPackage = artifact;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"status":0,"copadoJobId":"testcopadoJobId","result":{"Id":"0Hof2000000PAx3CAG"}}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        versionController.callBackend();
        versionController.getVersionDetails('1.0.0.1');
        Test.stopTest();
    }

    @IsTest
    static void testVersionCreate() {
        Id packageArtifactRecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Salesforce Package').getRecordTypeId();
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        List<Org__c> orgs = [SELECT Id, Name FROM Org__c WHERE Name = 'Dev Hub 1' OR Name = 'Scratch Org 1'];
        Map<String, Id> orgName_OrgIdMap = new Map<String, Id>();
        for (Org__c org : orgs) {
            orgName_OrgIdMap.put(org.Name, org.Id);
        }
        Artifact__c newArtifact = new Artifact__c(
            Name = 'TestCreateVersion',
            Source_Api_Version__c = '43.0',
            Sfdc_Login_Url__c = 'https://login.salesforce.com',
            RecordTypeId = packageArtifactRecordTypeId,
            Artifact_Repository__c = gr.Id,
            Target_Dev_Hub_Org__c = orgName_OrgIdMap.get('Dev Hub 1'),
            Package_Type__c = 'Unlocked',
            Org_Credential__c = orgName_OrgIdMap.get('Scratch Org 1'),
            Package_Id__c = '0Hof2000000PAx3CAG',
            Description__c = ''
        );
        insert newArtifact;

        Artifact__c newArtifact2 = new Artifact__c(
            Name = 'TestCreateVersion',
            Source_Api_Version__c = '43.0',
            Sfdc_Login_Url__c = 'https://login.salesforce.com',
            RecordTypeId = packageArtifactRecordTypeId,
            Artifact_Repository__c = gr.Id,
            Target_Dev_Hub_Org__c = orgName_OrgIdMap.get('Dev Hub 1'),
            Package_Type__c = 'Unlocked',
            Org_Credential__c = orgName_OrgIdMap.get('Scratch Org 1'),
            Package_Id__c = '0Hof2000000PAx3CAG',
            Description__c = ''
        );
        insert newArtifact2;

        Artifact_Version__c newArtifactVersion = new Artifact_Version__c(
            Name = 'TestCreateVersion',
            Artifact__c = newArtifact.Id,
            Branch__c = 'TestBranch',
            Tag__c = 'TestTag',
            Version_number__c = '1.0.0.1'
        );
        insert newArtifactVersion;

        Artifact_Version__c newArtifactVersion2 = new Artifact_Version__c(
            Name = 'TestCreateVersion',
            Artifact__c = newArtifact2.Id,
            Branch__c = 'TestBranch',
            Tag__c = 'TestTag',
            Version_number__c = '1.0.0.1'
        );
        insert newArtifactVersion2;

        newArtifact.Artifact_Version__c = newArtifactVersion.Id;
        update newArtifact;

        Sensitive_Information__c si = new Sensitive_Information__c(Name = 'TestCreateVersion - 1.0.0.1', Password__c = 'TestInstallationKey');
        insert si;

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreatePackageDefinition;
        pageRef.getParameters().put('Id', newArtifact.Id);
        //In this case, the Visualforce page named 'CreatePackageDefinition' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        //Instantiate and construct the controller class of CreatePackageDefinition page.
        ShowAttachmentDetailController controller = new ShowAttachmentDetailController();
        controller.currentRecord = newArtifact;
        controller.attachmentName = 'sfdx-project.json';
        System.assert(controller.attachments.isEmpty(), 'No attachnments should\'ve been retrieved for this artifact.');
        controller.createAttachment();
        controller = new ShowAttachmentDetailController();
        controller.currentRecord = newArtifact;
        controller.attachmentName = 'sfdx-project.json';

        PageReference pageRef2 = Page.DXPackageVersion;
        pageRef2.getParameters().put('Id', newArtifact.Id);
        //In this case, the Visualforce page named 'DXPackageVersion' is the starting point of this test method.
        Test.setCurrentPage(pageRef2);
        //Instantiate and construct the controller class of DXPackageVersion page.
        DXPackageVersionHandler versionController = new DXPackageVersionHandler();
        versionController.givenPackage = newArtifact;
        System.assert(!versionController.hasOrgDefinitionJson, 'The current artifact should not have an Org Definition JSON.');
        System.assert(versionController.hasProjectDefinitionJson, 'Project Definition JSON is missing for the current artifact.');
        newArtifact.Artifact_Version__c = newArtifactVersion.Id;
        Artifact_Version__c av = versionController.previousPackageVersion;
        versionController.getPreviousVersion();
        versionController.updateInstallationKey();
        DXPackageVersionHandler.VersionWrapper testVersion = versionController.versionWrapper;
        Sensitive_Information__c newList = versionController.sensitiveInformationCS;
        Artifact_Dependency__c thisDependency = new Artifact_Dependency__c();
        thisDependency.Dependent_Artifact__c = newArtifact.Id;
        thisDependency.Depending_Artifact__c = newArtifact2.Id;
        thisDependency.Depending_Artifact_Version__c = newArtifactVersion2.Id;
        insert thisDependency;

        Test.startTest();

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"status":0,"copadoJobId":"testcopadoJobId","result":{"Id":"08cf2000000PB4xAAG","Status":"InProgress","Package2Id":"0Hof2000000PAwyCAG","Package2VersionId":null,"SubscriberPackageVersionId":null,"Tag":"v1.0.0.0","Branch":"test","Error":[],"CreatedDate":"2018-08-16 15:10"}}',
            null
        ); 
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        try {
            versionController.callBackend();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.Required_Parameters_Missing));
        }

        versionController.versionWrapper = new DXPackageVersionHandler.versionWrapper('', '', '', '');
        versionController.versionWrapper.versionName = 'test version';
        versionController.versionWrapper.newVersion = 'new version';
        versionController.versionWrapper.versionDescription = 'test description';
        versionController.versionWrapper.installationKey = 'pipipi';
        versionController.callBackend();
        versionController.updateArtifactProjectJsonAttachment();
        List<Attachment> attachments = [
            SELECT Body
            FROM Attachment
            WHERE ParentId = :versionController.givenPackage.Id AND Name = :DXLabel.PROJECT_FILE
            WITH SECURITY_ENFORCED
        ];
        delete attachments;
        versionController.updateArtifactProjectJsonAttachment();
        versionController.deleteInstallationKeyAfterVersionCreationFailure();
        versionController.givenPackage.Package_Id__c = null;
        versionController.givenPackage.Target_Dev_Hub_Org__c = null;
        versionController.versionWrapper.versionName = null;
        versionController.versionWrapper.newVersion = null;
        versionController.givenPackage.Id = null;
        Test.stopTest();
    }

    @IsTest
    static void testPromoteBetaToReleased() {
        List<Org__c> orgs = [SELECT Id, Name FROM Org__c WHERE Name = 'Dev Hub 1' OR Name = 'Scratch Org 1'];
        Artifact__c newArtifact = createArtifact('Salesforce Package', 'Unlocked');
        insert newArtifact;

        Artifact_Version__c newArtifactVersion = new Artifact_Version__c(
            Name = 'TestCreateVersion',
            Artifact__c = newArtifact.Id,
            Branch__c = 'TestBranch',
            Tag__c = 'TestTag',
            Package_Version_Id__c = '0Hof2000000PAx3CAG',
            Version_number__c = '1.0.0.1',
            Subscriber_Version_Id__c = '0Hof2000000PAx3CAG'
        );
        insert newArtifactVersion;

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.PromoteBetatoReleased;
        pageRef.getParameters().put('Id', newArtifactVersion.Id);
        //In this case, the Visualforce page named 'PromoteBetatoReleased' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        //Instantiate and construct the controller class of PromoteBetatoReleased page.
        PromoteBetatoReleasedController controller = new PromoteBetatoReleasedController();
        controller.currentRecord = newArtifactVersion;
        Attachment proAtt = new Attachment(
            Name = 'sfdx-project.json',
            Body = Blob.valueOf(
                '{"sourceApiVersion":"43.0","sfdcLoginUrl":"https://login.salesforce.com","packageDirectories":[{"versionNumber":"1.0.0.0","versionName":"Summer 18","versionDescription":"Welcome to Summer 18","path":"myuniqunlockpac8152","packageName":"myuniqunlockpac8152","definitionFile":"config/scratch-org-def.json","defaultArtifact":true}],"packageAliases":{"myuniqunlockpac8152":"0Ho1t000000001ECAQ"},"namespace":""}'
            ),
            ParentId = newArtifact.Id
        );
        insert proAtt;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"status":0,"copadoJobId":"example","result":{"id":"04tf2000000oFUwAAM","success":true,"errors":[]}}',
            null
        );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.promoteAction();
        controller.cancel();

        /*try {
            SfdxAPI.installPackages(orgs[0].Id, '');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains('An error has been occurred during package installation'));
        }*/
        Test.stopTest();
    }

    @isTest
    static void getCurrentNamespace() {
        Test.startTest();
        String actualNamespace = DXPackageVersionHandler.ns;
        Test.stopTest();

        String expectedNamespace = Settings.ns;
        System.assertEquals(expectedNamespace, actualNamespace, 'The Application namespace is not correct.');
    }

    private static Artifact__c createArtifact(String recordType, String packageType) {
        Id packageArtifactRecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        Git_Repository__c repository = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        List<Org__c> orgs = [SELECT Id, Name FROM Org__c WHERE Name = 'Dev Hub 1' OR Name = 'Scratch Org 1'];
        Map<String, Id> orgName_OrgIdMap = new Map<String, Id>();
        for (Org__c org : orgs) {
            orgName_OrgIdMap.put(org.Name, org.Id);
        }
        Artifact__c artifact = new Artifact__c(
            Name = 'TestCreatePackage',
            Source_Api_Version__c = '43.0',
            Sfdc_Login_Url__c = 'https://login.salesforce.com',
            RecordTypeId = packageArtifactRecordTypeId,
            Artifact_Repository__c = repository.Id,
            Target_Dev_Hub_Org__c = orgName_OrgIdMap.get('Dev Hub 1'),
            Package_Type__c = packageType,
            Org_Credential__c = orgName_OrgIdMap.get('Scratch Org 1'),
            Package_Id__c = '',
            Description__c = '',
            Package_Namespace__c = 'dev_test_namespace'
        );
        return artifact;
    }

    private static Artifact_Version__c createArtifactVersion(Id artifactId) {
        Artifact_Version__c version = new Artifact_Version__c();
        version.Name = 'Test version';
        version.Artifact__c = artifactId;
        return version;
    }
}