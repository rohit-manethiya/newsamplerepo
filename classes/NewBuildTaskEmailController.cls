public with sharing class NewBuildTaskEmailController {
    public static final Integer MAX_BODY_LENGTH = 200000;
    public static final String EMPTY_STRING = '';
    public static String buildTaskId { get; set; }
    public static String statusMessage { get; set; }
    public static String deploymentName { get; set; }
    public static List<WrapperError> errorDetails { get; set; }
    public static List<Build_Task__c> buildTasks { get; set; }
    public static List<Deployment_Job__c> deploymentJobs { get; set; }
    public static String continuousIntegrationId { get; set; }

    public static Continuous_Integration__c continuousIntegrationRecord {
        get {
            if (continuousIntegrationRecord == null && String.isNotBlank(continuousIntegrationId)) {
                continuousIntegrationRecord = [SELECT Name FROM Continuous_Integration__c WHERE Id = :continuousIntegrationId WITH SECURITY_ENFORCED];
            }
            return continuousIntegrationRecord;
        }
        set;
    }

    public NewBuildTaskEmailController() {
        statusMessage = EMPTY_STRING;
        errorDetails = new List<WrapperError>();
    }

    public List<WrapperError> getErrorList() {
        if (errorDetails != null && !errorDetails.isEmpty())
            return errorDetails;
        if (String.isBlank(buildTaskId)) {
            statusMessage = Label.RECORD_NOT_FOUND;
            return new List<WrapperError>();
        }
        buildTasks = getBuildTasks(buildTaskId);
        if (buildTasks == null || buildTasks.isEmpty()) {
            statusMessage = String.format(Label.BUILD_TASK_RECORD_NOT_FOUND, new List<String>{ buildTaskId });
            return new List<WrapperError>();
        } else {
            deploymentJobs = getDeploymentJobs(buildTasks[0].Deployment__c, 'Git MetaData');
            if (!deploymentJobs.isEmpty()) {
                List<Attachment> attachments = getAttachment(buildTasks[0].Deployment__c, deploymentJobs[0].Id + '.json');
                if (!attachments.isEmpty()) {
                    if (attachments[0].BodyLength <= MAX_BODY_LENGTH) {
                        try {
                            List<Object> results = (List<Object>) JSON.deserializeUntyped(attachments[0].Body.toString());
                            for (Object currentObject : results) {
                                Map<String, Object> errorAttributesByKey = (Map<String, Object>) currentObject;
                                WrapperError error = new WrapperError();
                                try {
                                    error.type = (String) errorAttributesByKey.get('l');
                                } catch (Exception ex) {
                                    error.type = EMPTY_STRING;
                                }
                                try {
                                    error.message = (String) errorAttributesByKey.get('m');
                                } catch (Exception ex) {
                                    error.message = EMPTY_STRING;
                                }
                                try {
                                    error.copadoTip = (String) errorAttributesByKey.get('t');
                                } catch (Exception ex) {
                                    error.copadoTip = EMPTY_STRING;
                                }
                                errorDetails.add(error);
                            }
                            statusMessage = '';
                            return errorDetails;
                        } catch (Exception e) {
                            statusMessage = Label.ERROR_PARSING_JSON + ' ' + e.getMessage();
                            return new List<WrapperError>();
                        }
                    } else {
                        statusMessage = Label.MAX_FILE_SIZE_EXCEEDED;
                        return new List<WrapperError>();
                    }
                } else {
                    statusMessage = Label.NO_ERROR_ATTACHMENT_FOUND;
                    return new List<WrapperError>();
                }
            } else {
                statusMessage = Label.NO_DEPLOYMENT_JOBS_FOUND;
                return new List<WrapperError>();
            }
        }
    }

    public static String getPodUrl() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }

    private static List<Build_Task__c> getBuildTasks(String btId) {
        if (buildTasks != null) {
            return buildTasks;
        }
        buildTasks = [
            SELECT Id, Name, Status__c, Type__c, Deployment__c, Deployment__r.Status__c
            FROM Build_Task__c
            WHERE Id = :btId AND Deployment__c != null
            WITH SECURITY_ENFORCED
        ];
        return buildTasks;
    }

    private static List<Deployment_Job__c> getDeploymentJobs(String deploymentId, String stepType) {
        if (deploymentJobs != null) {
            return deploymentJobs;
        }
        deploymentJobs = [
            SELECT Id, Step__c, Step__r.Deployment__r.Name
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deploymentId AND Step__r.Type__c = :stepType
            WITH SECURITY_ENFORCED
        ];
        deploymentName = (String.isBlank(deploymentName) && !deploymentJobs.isEmpty()) ? deploymentJobs[0].Step__r.Deployment__r.Name : EMPTY_STRING;
        return deploymentJobs;
    }

    private static List<Attachment> getAttachment(String parentId, String name) {
        List<Attachment> attachmentList = new List<Attachment>();
        attachmentList = [
            SELECT Id, ParentId, Body, BodyLength, Name, IsDeleted
            FROM Attachment
            WHERE ParentId = :parentId AND Name = :name AND IsDeleted = false
            WITH SECURITY_ENFORCED
        ];
        return attachmentList;
    }

    public class WrapperError {
        public String type { get; set; }
        public String message { get; set; }
        public String copadoTip { get; set; }
    }
}