public with sharing class DataStepValidatorResultHandler {
    private Id stepId;

    public DataStepValidatorResultHandler(Id stepId) {
        this.stepId = stepId;
    }

    public void handle(DataTemplateDeploymentValidationResult result) {
        attachResultToStep(result);
    }

    private Attachment attachResultToStep(DataTemplateDeploymentValidationResult result) {
        Attachment validationResult = new Attachment(
            ParentId = this.stepId,
            Name = DataTemplateDeploymentValidationResult.ATTACHMENT_NAME,
            Body = Blob.valueOf(JSON.serialize(result))
        );

        List<Attachment> attachments = new AttachmentsSelector()
            .byParentIdAndName(new List<Id>{ this.stepId }, new List<String>{ DataTemplateDeploymentValidationResult.ATTACHMENT_NAME });
        if (!attachments.isEmpty()) {
            Attachment existingAttachment = attachments[0];
            validationResult.Id = existingAttachment.Id;
        }

        Utilities.Secure_DML(validationResult, Utilities.DML_Action.UPS, Schema.SObjectType.Attachment);

        return validationResult;
    }
}