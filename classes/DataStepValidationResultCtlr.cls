public with sharing class DataStepValidationResultCtlr {
    private Step__c step;

    public Id dataStepId {
        get;
        set {
            if (value != null) {
                dataStepId = value;
                step = getStepById(dataStepId);
                refreshAttachment();
            }
        }
    }

    public String validationResultMessage {
        get {
            if (step == null) {
                validationResultMessage = null;
            } else if (validationResultAttachment == null) {
                validationResultMessage = Label.Step_Not_Validated;
            } else {
                validationResultMessage = getResultMessage(validationResultAttachment);
            }
            return validationResultMessage;
        }
        set;
    }

    public String validationStatus {
        get {
            if (step == null) {
                validationStatus = null;
            } else if (validationResultAttachment == null) {
                validationStatus = 'none';
            } else {
                validationStatus = getStatus(validationResultAttachment);
            }
            return validationStatus;
        }
        set;
    }

    public String validationStatusIcon {
        get {
            if (step == null) {
                validationStatusIcon = null;
            } else if (validationResultAttachment == null) {
                validationStatusIcon = 'warning.png';
            } else {
                validationStatusIcon = getStatusIcon(validationResultAttachment);
            }
            return validationStatusIcon;
        }
        set;
    }

    public List<DataTemplateDeploymentValidationResult.ValidationError> validationErrors {
        get {
            return parseValidationErrors(validationResultAttachment);
        }
        set;
    }

    private Attachment validationResultAttachment {
        get {
            if (step == null) {
                return null;
            }
            if (validationResultAttachment == null) {
                List<Attachment> attachments = getAttachmentByStepId(step.Id);
                validationResultAttachment = !attachments.isEmpty() ? attachments[0] : null;
            }
            return validationResultAttachment;
        }
        set;
    }

    public DataStepValidationResultCtlr() {
    }

    public void setStepId() {
        String stepId = ApexPages.currentPage().getParameters().get('stepId');
        if (String.isBlank(stepId)) {
            step = null;
        } else if (stepId instanceof Id) {
            dataStepId = (Id) stepId;
        }
    }

    public void refreshAttachment() {
        if (step != null) {
            List<Attachment> attachments = getAttachmentByStepId(step.Id);
            validationResultAttachment = !attachments.isEmpty() ? attachments[0] : null;
        }
    }

    private static Step__c getStepById(Id stepId) {
        List<Step__c> steps = new StepsSelector().byId(new List<Id>{ stepId });
        return !steps.isEmpty() ? steps[0] : null;
    }

    private static List<Attachment> getAttachmentByStepId(Id stepId) {
        return new AttachmentsSelector()
            .byParentIdAndName(new List<Id>{ stepId }, new List<String>{ DataTemplateDeploymentValidationResult.ATTACHMENT_NAME });
    }

    private static String getResultMessage(Attachment attachment) {
        DataTemplateDeploymentValidationResult result = (DataTemplateDeploymentValidationResult) JSON.deserialize(
            attachment.Body.toString(),
            DataTemplateDeploymentValidationResult.class
        );
        String validationResultMessage = Label.Last_Step_Validation + ': ';
        validationResultMessage += String.format(Label.Number_Warnings_Found, new List<String>{ String.valueOf(result.getErrors().size()) });
        validationResultMessage += ' (' + attachment.LastModifiedDate.format() + ').';

        return validationResultMessage;
    }

    private static String getStatus(Attachment attachment) {
        DataTemplateDeploymentValidationResult result = (DataTemplateDeploymentValidationResult) JSON.deserialize(
            attachment.Body.toString(),
            DataTemplateDeploymentValidationResult.class
        );
        return result.getErrors().isEmpty() ? 'success' : 'error';
    }

    private static String getStatusIcon(Attachment attachment) {
        DataTemplateDeploymentValidationResult result = (DataTemplateDeploymentValidationResult) JSON.deserialize(
            attachment.Body.toString(),
            DataTemplateDeploymentValidationResult.class
        );
        return result.getErrors().isEmpty() ? 'check.png' : 'error.png';
    }

    private static List<DataTemplateDeploymentValidationResult.ValidationError> parseValidationErrors(Attachment attachment) {
        List<DataTemplateDeploymentValidationResult.ValidationError> errors = new List<DataTemplateDeploymentValidationResult.ValidationError>();
        if (attachment != null) {
            DataTemplateDeploymentValidationResult result = (DataTemplateDeploymentValidationResult) JSON.deserialize(
                attachment.Body.toString(),
                DataTemplateDeploymentValidationResult.class
            );
            errors.addAll(result.getErrors());
        }
        return errors;
    }
}