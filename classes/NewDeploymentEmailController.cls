public with sharing class NewDeploymentEmailController {
    private static final String EMPTY_STRING = '';
    @TestVisible
    private static final Integer MAX_BODY_LENGTH = 200000;
    private static final String EXPECTED_INVALID_CONVERSION_JSON_EXCEPTION = 'Invalid conversion from runtime type Map<String,ANY> to List<ANY>';

    public String statusMessage { get; set; }
    public String statusMessageErrorMessages { get; set; }

    public String deploymentId {
        get;
        set {
            deploymentId = value;
            if (String.isBlank(value)) {
                statusMessage = Label.RECORD_NOT_FOUND;
            } else {
                statusMessage = EMPTY_STRING;
            }
        }
    }

    public Deployment__c deployment {
        get {
            // Needed since, when passing the entire SObject record as a paramenter to the component,
            // we only get "one bite at the cherry", not including custom fields
            if (deployment == null) {
                if (String.isNotBlank(deploymentId)) {
                    try {
                        deployment = [SELECT Name, Status__c FROM Deployment__c WHERE Id = :deploymentId WITH SECURITY_ENFORCED];
                    } catch (Exception e) {
                        statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                    }
                }
            }
            return deployment;
        }
        set;
    }

    public List<Deployment_Job__c> deploymentJobs {
        get {
            if (deploymentJobs == null) {
                if (String.isNotBlank(deploymentId)) {
                    try {
                        deploymentJobs = [
                            SELECT Status__c, To_Org_Name__c, Step__r.Name, Step__r.Type__c, Step__r.CheckOnly__c, Step__r.Deployment__r.Name
                            FROM Deployment_Job__c
                            WHERE Step__r.Deployment__c = :deploymentId
                            WITH SECURITY_ENFORCED
                            ORDER BY Step__r.Order__c ASC
                        ];
                    } catch (Exception e) {
                        statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                    }
                } else {
                    deploymentJobs = new List<Deployment_Job__c>();
                }
            }
            return deploymentJobs;
        }
        set;
    }

    public Map<String, Attachment> deploymentAttachmentsByName {
        get {
            if (deploymentAttachmentsByName == null) {
                if (String.isNotBlank(deploymentId)) {
                    Set<String> deployJobsNamesJson = new Set<String>();
                    for (Deployment_Job__c deploymentJob : deploymentJobs) {
                        deployJobsNamesJson.add(deploymentJob.Id + '.json');
                    }
                    try {
                        deploymentAttachmentsByName = new Map<String, Attachment>();
                        for (Attachment attachment : [
                            SELECT ParentId, Body, BodyLength, Name
                            FROM Attachment
                            WHERE ParentId = :deploymentId AND Name IN :deployJobsNamesJson AND IsDeleted = FALSE
                            WITH SECURITY_ENFORCED
                        ]) {
                            deploymentAttachmentsByName.put(attachment.Name, attachment);
                        }
                    } catch (Exception e) {
                        statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                    }
                } else {
                    deploymentAttachmentsByName = new Map<String, Attachment>();
                }
            }
            return deploymentAttachmentsByName;
        }
        set;
    }

    public NewDeploymentEmailController() {
        statusMessage = EMPTY_STRING;
        statusMessageErrorMessages = EMPTY_STRING;
    }

    public String getRecordUrl() {
        return Settings.ORGANIZATION_URL + '/' + deploymentId;
    }

    public List<WrapperError> getErrorMessages() {
        List<WrapperError> errorMessages = new List<WrapperError>();

        try {
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                List<WrapperError> errors = getDeploymentJobErrors(deploymentJob);
                errorMessages.addAll(errors);
            }
            if (errorMessages.isEmpty()) {
                statusMessageErrorMessages = Label.NO_ERROR_ATTACHMENT_FOUND;
            }
        } catch (Exception e) {
            statusMessageErrorMessages = e.getMessage();
        }

        return errorMessages;
    }

    private List<WrapperError> getDeploymentJobErrors(Deployment_Job__c deploymentJob) {
        List<WrapperError> jobErrors = new List<WrapperError>();

        String deploymentJobAttachmentName = deploymentJob.Id + '.json';
        if (deploymentAttachmentsByName.containsKey(deploymentJobAttachmentName)) {
            Attachment attachmentRecord = deploymentAttachmentsByName.get(deploymentJobAttachmentName);
            if (attachmentRecord.BodyLength > MAX_BODY_LENGTH) {
                throw new DeploymentEmailControllerException(Label.MAX_FILE_SIZE_EXCEEDED);
            }
            List<WrapperError> errors = parseErrorMessages(attachmentRecord);
            jobErrors.addAll(errors);
        }

        return jobErrors;
    }

    private List<WrapperError> parseErrorMessages(Attachment attachmentRecord) {
        Boolean isDataDeployment = false;
        // try to parse as regular deployment result
        List<Object> results;
        try {
            results = (List<Object>) JSON.deserializeUntyped(attachmentRecord.Body.toString());
        } catch (Exception e) {
            // This means that it is a data deployment
            // try to parse as data deployment result
            if (e.getMessage() == EXPECTED_INVALID_CONVERSION_JSON_EXCEPTION) {
                Map<String, Object> parsedJSONContent = (Map<String, Object>) JSON.deserializeUntyped(attachmentRecord.Body.toString());
                results = (List<Object>) parsedJSONContent.get('results');
                isDataDeployment = true;
            } else {
                throw new DeploymentEmailControllerException(Label.ERROR_PARSING_JSON + ' ' + e.getMessage());
            }
        }

        List<WrapperError> errors = getErrorsFromResults(results, isDataDeployment);
        return errors;
    }

    private List<WrapperError> getErrorsFromResults(List<Object> results, Boolean isDataDeployment) {
        List<WrapperError> errors = new List<WrapperError>();
        if (results != null) {
            for (Object result : results) {
                Map<String, Object> errorAttributesByKey = (Map<String, Object>) result;

                String errorMessage = getErrorMessage(errorAttributesByKey, isDataDeployment);

                // If is a data deployment, but any result contains an exception, then it was not successful and error message must be shown
                if (String.isNotBlank(errorMessage)) {
                    WrapperError error = new WrapperError();
                    error.type = getErrorType(errorAttributesByKey);
                    error.message = errorMessage;
                    error.copadoTip = getCopadoTip(errorAttributesByKey);
                    errors.add(error);
                }
            }
        }
        return errors;
    }

    private String getErrorType(Map<String, Object> result) {
        try {
            return (String) result.get('l');
        } catch (Exception ex) {
            return EMPTY_STRING;
        }
    }

    private String getErrorMessage(Map<String, Object> result, Boolean isDataDeployment) {
        try {
            if (isDataDeployment) {
                Map<String, Object> messageAttributesByKey = (Map<String, Object>) result.get('m');
                return (String) messageAttributesByKey.get('exception');
            } else {
                return (String) result.get('m');
            }
        } catch (Exception ex) {
            return EMPTY_STRING;
        }
    }

    private String getCopadoTip(Map<String, Object> result) {
        try {
            return ((String) result.get('t')).replaceAll('&lt;', '<').replaceAll('&gt;', '>');
        } catch (Exception ex) {
            return EMPTY_STRING;
        }
    }

    public List<WrapperStep> getDeploymentSteps() {
        List<WrapperStep> deploymentSteps = new List<WrapperStep>();

        for (Deployment_Job__c deploymentJob : deploymentJobs) {
            WrapperStep step = new WrapperStep();
            step.name = deploymentJob.Step__r.Name;
            step.type = deploymentJob.Step__r.Type__c;
            step.status = deploymentJob.Status__c;
            step.destinationOrg = deploymentJob.To_Org_Name__c;
            if (deploymentJob.Step__r.Type__c == 'Data template') {
                // if job results have error records
                // change step status value to Warning
                List<Map<String, Object>> results = getDeploymentJobResults(deploymentJob);
                for (Map<String, Object> result : results) {
                    WrapperDataTemplateResult dataTemplateResult = (WrapperDataTemplateResult) JSON.deserialize(
                        JSON.serialize(result),
                        WrapperDataTemplateResult.class
                    );
                    if (dataTemplateResult.failedRecords > 0) {
                        step.status = 'Completed with Warnings';
                        break;
                    }
                }
            }
            deploymentSteps.add(step);
        }

        return deploymentSteps;
    }

    // generic approach in case we want to show more details on the email for different step types
    private List<Map<String, Object>> getDeploymentJobResults(Deployment_Job__c deploymentJob) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        String deploymentJobAttachmentName = deploymentJob.Id + '.json';
        if (deploymentAttachmentsByName.containsKey(deploymentJobAttachmentName)) {
            Attachment attachmentRecord = deploymentAttachmentsByName.get(deploymentJobAttachmentName);
            // add more condition for different step types
            if (deploymentJob.Step__r.Type__c == 'Data template') {
                List<WrapperDataTemplateResult> dataTemplateResults = parseDataTemplateResults(attachmentRecord);
                // convert to untyped map for generic use
                for (WrapperDataTemplateResult dataTemplateResult : dataTemplateResults) {
                    Map<String, Object> untypedResult = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(dataTemplateResult));
                    results.add(untypedResult);
                }
            }
        }

        return results;
    }

    private List<WrapperDataTemplateResult> parseDataTemplateResults(Attachment attachmentRecord) {
        List<WrapperDataTemplateResult> wrapperResults = new List<WrapperDataTemplateResult>();
        Map<String, Object> parsedJSONContent = (Map<String, Object>) JSON.deserializeUntyped(attachmentRecord.Body.toString());
        List<Object> results = (List<Object>) parsedJSONContent.get('results');
        for (Object result : results) {
            Map<String, Object> resultObject = (Map<String, Object>) result;
            Map<String, Object> dataTemplateAttributesByKey = (Map<String, Object>) resultObject.get('m');
            WrapperDataTemplateResult wrapperResult = (WrapperDataTemplateResult) JSON.deserialize(
                JSON.serialize(dataTemplateAttributesByKey),
                WrapperDataTemplateResult.class
            );
            wrapperResults.add(wrapperResult);
        }
        return wrapperResults;
    }

    public with sharing class WrapperError {
        public String type { get; set; }
        public String message { get; set; }
        public String copadoTip { get; set; }
    }

    public with sharing class WrapperStep {
        public String name { get; set; }
        public String type { get; set; }
        public String status { get; set; }
        public String destinationOrg { get; set; }
    }

    public with sharing class WrapperDataTemplateResult {
        public String templateName { get; set; }
        public String objectName { get; set; }
        public Integer deployedRecords { get; set; }
        public Integer failedRecords { get; set; }
        public Integer generatedIds { get; set; }
    }

    public class DeploymentEmailControllerException extends Exception {
    }
}