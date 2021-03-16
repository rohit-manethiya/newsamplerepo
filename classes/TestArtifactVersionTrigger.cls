@IsTest
private class TestArtifactVersionTrigger {
    @testSetup static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.insertUser('user1-dxOperations@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @IsTest
    static void testArtifactVersionDmlOperations() {
        Git_Repository__c thisRepository = [SELECT Id FROM Git_Repository__c WHERE Name = :'git 1'];

        Artifact__c thisArtifact = new Artifact__c();
        thisArtifact.Name = 'Test';
        thisArtifact.Package_Type__c = 'Unlocked';
        thisArtifact.Artifact_Repository__c = thisRepository.Id;
        insert thisArtifact;

        Artifact_Version__c thisVersion = new Artifact_Version__c();
        thisVersion.Artifact__c = thisArtifact.Id;
        thisVersion.Name = thisArtifact.Name;
        thisVersion.Version_number__c = '1.0.0.0';

        Sensitive_Information__c thisInformation = new Sensitive_Information__c();
        thisInformation.Name = thisVersion.Name + ' - ' + thisVersion.Version_number__c;
        thisInformation.Version_Name__c = thisInformation.Name;
        insert thisInformation;

        Test.startTest();

        insert thisVersion;
        List<Artifact_Version__c> insertedVersions = [SELECT Id FROM Artifact_Version__c WHERE Name = :thisVersion.Name];
        System.assertEquals(1, insertedVersions.size());

        thisVersion.Name = 'Test2';
        update thisVersion;
        List<Artifact_Version__c> updatedVersions = [SELECT Id FROM Artifact_Version__c WHERE Id IN :insertedVersions];
        System.assertEquals(1, updatedVersions.size());

        delete thisVersion;
        List<Artifact_Version__c> deletedVersions = [SELECT Id FROM Artifact_Version__c WHERE Id IN :insertedVersions];
        System.assertEquals(true, deletedVersions.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testGenerateArtifactMetadataAttachmentsFromPackage() {
        Git_Repository__c thisRepository = [SELECT Id FROM Git_Repository__c WHERE Name = :'git 1'];

        Artifact__c thisArtifact = new Artifact__c();
        thisArtifact.Name = 'Test';
        thisArtifact.Package_Type__c = 'Unlocked';
        thisArtifact.Artifact_Repository__c = thisRepository.Id;
        insert thisArtifact;

        Attachment thisAttachment = new Attachment();
        thisAttachment.ParentId = thisArtifact.Id;
        thisAttachment.Name = 'ArtifactMetaData';
        thisAttachment.Body = Blob.valueOf('TEST BODY');
        insert thisAttachment;

        Artifact_Version__c thisVersion = new Artifact_Version__c();
        thisVersion.Artifact__c = thisArtifact.Id;
        thisVersion.Name = thisArtifact.Name;
        thisVersion.Version_number__c = '1.0.0.0';

        Test.startTest();

        Utilities.Secure_DML(thisVersion, Utilities.DML_Action.INS, SObjectType.Artifact_Version__c);

        List<Attachment> versionAttachments = [SELECT Id FROM Attachment WHERE ParentId = :thisVersion.Id AND Name = 'ArtifactMetaData'];
        System.assert(!versionAttachments.isEmpty());

        Test.stopTest();
    }
}