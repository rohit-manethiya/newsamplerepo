public with sharing class ArtifactVersionTriggerHandler implements ITrigger{
    public void bulkBefore() {}

    public void bulkAfter() {
        if(Trigger.isInsert) {
            ArtifactVersionTriggerHelper.updateVersionInstallationKeyDetails(Trigger.new);
            ArtifactVersionTriggerHelper.generateArtifactMetadataAttachmentsFromPackage(Trigger.new);
        }
    }

    public void beforeInsert(SObject so) {}

    public void beforeUpdate(SObject oldSo, SObject so) {}

    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {}

    public void afterUpdate(SObject oldSo, SObject so) {}

    public void afterDelete(SObject so) {}

    public void afterUndelete(SObject so) {}

    public void andFinally() {}
}