trigger ArtifactVersionTrigger on Artifact_Version__c (before insert, before update, before delete, after insert, after update, after delete) {
    TriggerFactory.createAndExecuteHandler(ArtifactVersionTriggerHandler.class);
}