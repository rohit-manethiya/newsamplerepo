public with sharing class ArtifactVersionTriggerHelper {
    /**
    * @description When a new Artifact Version record is inserted from the backend, its installation key record (stored in
    * the Sensitive_Information__c custom setting) name needs to be updated to ensure uniqueness across the org.
    *
    * @param newList is the Trigger.new list containing all newly inserted records
     */
    public static void updateVersionInstallationKeyDetails(List<Artifact_Version__c> newList) {
        Map<String, Sensitive_Information__c> sensitiveInformationMap = Sensitive_Information__c.getAll();
        List<Sensitive_Information__c> sensitiveInformationToUpdate = new List<Sensitive_Information__c>();
        for(Artifact_Version__c thisVersion : newList) {
            Sensitive_Information__c thisInformation = sensitiveInformationMap.get(thisVersion.Name);
            if(thisInformation != null) {
                thisInformation.Name = thisVersion.Id;
                sensitiveInformationToUpdate.add(thisInformation);
            }
        }

        if(sensitiveInformationToUpdate.isEmpty()) {
            return; 
        }

        Utilities.Secure_DML(sensitiveInformationToUpdate, Utilities.DML_Action.UPD, SObjectType.Artifact_Version__c);
    }

    /**
     * @description When a new Artifact Version is generated, an attachment containing all the package metadata shall be
     * created for it in order to reflect the current metadata scope of that particular version coming from the original
     * package.
     *
     * @param newList is the Trigger.new list containing all newly inserted records
     */
    public static void generateArtifactMetadataAttachmentsFromPackage(List<Artifact_Version__c> newList) {
        Set<Id> artifactIds = new Set<Id>();
        List<Artifact_Version__c> artifactVersionsForAttachments = new List<Artifact_Version__c>();
        for(Artifact_Version__c thisVersion : newList) {
            if(thisVersion.Artifact__c != null) {
                artifactIds.add(thisVersion.Artifact__c);
                artifactVersionsForAttachments.add(thisVersion);
            }
        }

        if(artifactVersionsForAttachments.isEmpty()) {
            return;
        }

        List<Attachment> attachmentsToInsert = getVersionAttachmentsToInsert(artifactVersionsForAttachments, artifactIds);
        Utilities.Secure_DML(attachmentsToInsert, Utilities.DML_Action.INS, SObjectType.Attachment);
    }

    /**
     * @description creates a list of Attachment records to be inserted for the newly created Artifact Versions.
     *
     * @param artifactVersionsForAttachments is the list of Artifact Versions whose Artifact__c field is not null.
     * @param artifactIds is the set of related Artifact Ids needed for querying the attachments.
     *
     * @return a list of new Attachment records to be inserted for each Artifact Version.
     */
    private static List<Attachment> getVersionAttachmentsToInsert(List<Artifact_Version__c> artifactVersionsForAttachments, Set<Id> artifactIds) {
        Map<Id, Attachment> attachmentsByArtifact = getArtifactMetadataAttachmentsByArtifactMap(artifactIds);
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        for(Artifact_Version__c thisVersion : artifactVersionsForAttachments) {
            Attachment thisAttachment = attachmentsByArtifact.get(thisVersion.Artifact__c);
            if(thisAttachment != null) {
                Attachment thisVersionAttachment = thisAttachment.clone(false, false, false, false);
                thisVersionAttachment.ParentId = thisVersion.Id;
                attachmentsToInsert.add(thisVersionAttachment);
            }
        }
        return attachmentsToInsert;
    }

    /**
     * @description creates a map with all the ArtifactMedaData attachments belonging to the Artifact Version's related Artifact
     *
     * @param artifactIds is the set of related Artifact Ids needed for querying the attachments.
     *
     * @return a map of ArtifactMedaData attachments by Artifact Id
     */
    private static Map<Id, Attachment> getArtifactMetadataAttachmentsByArtifactMap(Set<Id> artifactIds) {
        List<Attachment> artifactAttachments = [SELECT Name, Body, ParentId FROM Attachment WHERE ParentId IN :artifactIds AND Name = 'ArtifactMetaData'];
        Map<Id, Attachment> attachmentsByArtifact = new Map<Id, Attachment>();
        for(Attachment thisAttachment : artifactAttachments) {
            if(!attachmentsByArtifact.containsKey(thisAttachment.ParentId)) {
                attachmentsByArtifact.put(thisAttachment.ParentId, thisAttachment);
            }
        }
        return attachmentsByArtifact;
    }
}