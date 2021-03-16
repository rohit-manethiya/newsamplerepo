public without sharing class AttachmentTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {}
    public AttachmentTriggerHandler() {
    }

    public void bulkBefore() {
        AttachmentTriggerHelper.prepareData();
    }

    public void bulkAfter() {
        AttachmentTriggerHelper.processExternalCIDeploymentJobs();
        AttachmentTriggerHelper.prepareAfterData();
        AttachmentTriggerHelper.prepareDataBulkAfter();
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }
    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        AttachmentTriggerHelper.populateUserStoryFields((Attachment)so);
        AttachmentTriggerHelper.processUserStoryMetadata((Attachment)so);
        AttachmentTriggerHelper.createOrFinishCopadoNotification((Attachment)so, false);
        AttachmentTriggerHelper.processSeleniumLocators((Attachment)so, false);
        AttachmentTriggerHelper.processDeploymentFlowStep((Attachment)so);
        AttachmentTriggerHelper.processDeploymentFlow((Attachment)so);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        AttachmentTriggerHelper.populateUserStoryFields((Attachment)so);
        AttachmentTriggerHelper.processUserStoryMetadata((Attachment)so);
        AttachmentTriggerHelper.createOrFinishCopadoNotification((Attachment)so, false);
        AttachmentTriggerHelper.processDeploymentFlowStep((Attachment)so);
        AttachmentTriggerHelper.processDeploymentFlow((Attachment)so);
        AttachmentTriggerHelper.processSeleniumLocators((Attachment)so, false);
    }

    public void afterDelete(SObject so) {
        AttachmentTriggerHelper.createOrFinishCopadoNotification((Attachment)so, true);
        AttachmentTriggerHelper.processSeleniumLocators((Attachment)so, true);
    }

    public void afterUndelete(SObject so) {
    }

    public void andFinally() {
        AttachmentTriggerHelper.upsertCopadoNotifications();
        AttachmentTriggerHelper.persistSeleniumLocators();
        AttachmentTriggerHelper.updateUS();
    }
}