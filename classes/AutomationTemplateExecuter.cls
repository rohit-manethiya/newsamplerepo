public with sharing class AutomationTemplateExecuter {
    private static String automationTemplateName { get; set; }
    private static Result__c result = new Result__c();
    private static Deployment__c automationTemplate = new Deployment__c();
    private static final String NOT_STARTED = 'Not started';
    private static final String FAILED = 'Failed';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String SCHEDULED = 'Scheduled';
    private static final String FAIL_JOB_TYPE = 'Coverting an Automation Template Failed';

    public static List<Result__c> execute(Id automationTemplateId, Id sourceCredentialId, Id targetCredentialId, Boolean execute) {
        try {
            getAutomationTemplateDetails(automationTemplateId);
            result.Job_Type__c = automationTemplate.Name;
            result.Status__c = IN_PROGRESS;
            result.Start_Time__c = System.now();
            Boolean bothVariableNotDefined =
                (sourceCredentialId != null && targetCredentialId == null) || (sourceCredentialId == null && targetCredentialId != null);
            if (bothVariableNotDefined) {
                result.Status__c = FAILED;
                result.Error_Message__c = Label.Source_and_Target_Credential_Warning;
                result.End_Time__c = System.now();
                Utilities.Secure_DML(result, Utilities.DML_Action.INS, schema.Sobjecttype.Result__c);
                return new List<Result__c>{ result };
            }

            Id clonedAdvancedDeploymentId = cloneDeployment(sourceCredentialId);
            result.Deployment__c = clonedAdvancedDeploymentId;
            cloneSteps(automationTemplateId, clonedAdvancedDeploymentId);
            createDestinationOrgs(targetCredentialId, clonedAdvancedDeploymentId);
            cloneAttachments(new Map<Id, Id>{ automationTemplateId => clonedAdvancedDeploymentId });

            // TODO : Credit check
            if (execute) {
                automationTemplate.Status__c = SCHEDULED;
                automationTemplate.Date__c = System.now();
                automationTemplate.Deployment_command_sent__c = null;
                Utilities.Secure_DML(automationTemplate, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);
                DeployAPI.deploy(new List<Id>{ clonedAdvancedDeploymentId }, UserInfo.getSessionId());
            }

            Utilities.Secure_DML(result, Utilities.DML_Action.INS, schema.Sobjecttype.Result__c);
            return new List<Result__c>{ result };
        } catch (Exception ex) {
            result.Status__c = FAILED;
            result.Job_Type__c = FAIL_JOB_TYPE;
            result.Error_Message__c = ex.getMessage();
            result.End_Time__c = System.now();
            Utilities.Secure_DML(result, Utilities.DML_Action.INS, schema.Sobjecttype.Result__c);
            return new List<Result__c>{ result };
        }
    }

    /**
     * returnDefaultOrgId: It is returning the main org credential id, it will be used of the source credential id is not specified
     *
     * @@ Return Id: main org credential id
     */
    private static Id returnDefaultOrgId() {
        String orgId = Userinfo.getOrganizationId() + '_' + Userinfo.getUserId();
        List<Org__c> orgs = [SELECT Id FROM Org__c WHERE Validated_Date__c != null AND SFDC_Org_ID__c = :orgId WITH SECURITY_ENFORCED LIMIT 1];
        return !orgs.isEmpty() ? orgs[0].Id : null;
    }

    /**
     * getAutomationTemplateDetails: It is getting all detail of Automation Template record and preapring for clone
     *
     * ## automationTemplateId (Id): automationTemplateId
     */
    private static void getAutomationTemplateDetails(Id automationTemplateId) {
        automationTemplate = Utilities.getDeploymentById(automationTemplateId);
    }

    /**
     * cloneDeployment: It is cloning the automation template type deployment into advanced multi step deployment
     *
     * @@ Return Id: Return cloned advanced multi step deployment record id
     */
    private static Id cloneDeployment(Id sourceCredentialId) {
        String advancedDeploymentRecordId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
            .get('Advanced_multi_step')
            .getRecordTypeId();

        Deployment__c executionDeploymentOfAutomation = automationTemplate.clone(false, false, false, false);
        executionDeploymentOfAutomation.Name = Label.Execution_of + ' ' + executionDeploymentOfAutomation.Name;
        executionDeploymentOfAutomation.RecordTypeId = advancedDeploymentRecordId;
        executionDeploymentOfAutomation.Template__c = automationTemplate.Id;
        executionDeploymentOfAutomation.From_Org__c = sourceCredentialId != null ? sourceCredentialId : returnDefaultOrgId();

        Utilities.Secure_DML(executionDeploymentOfAutomation, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment__c);

        result.Deployment__c = executionDeploymentOfAutomation.Id;
        return executionDeploymentOfAutomation.Id;
    }

    /**
     * cloneSteps: It is cloning the steps related to the automation template into advanced multi step deployment steps
     *
     * ## automationTemplateId (Id): automationTemplateId
     * ## advancedDeploymentRecordId (Id): advancedDeploymentRecordId
     */
    private static void cloneSteps(Id automationTemplateId, Id advancedDeploymentRecordId) {
        List<Step__c> steps = Utilities.getStepsByDeploymentId(automationTemplateId);
        List<Step__c> newSteps = new List<Step__c>();
        for (Step__c stepRecord : steps) {
            Step__c newStep = stepRecord.clone();
            newStep.Deployment__c = advancedDeploymentRecordId;
            newStep.Status__c = NOT_STARTED;
            newSteps.add(newStep);
        }
        if (!newSteps.isEmpty()) {
            Utilities.Secure_DML(newSteps, Utilities.DML_Action.INS, schema.Sobjecttype.Step__c);
            Map<Id, Id> newParentIdsByOldParentIds = new Map<Id, Id>();
            for (Step__c oldStepRecord : steps) {
                for (Step__c newStepRecord : newSteps) {
                    if (oldStepRecord.Order__c == newStepRecord.Order__c) {
                        newParentIdsByOldParentIds.put(oldStepRecord.Id, newStepRecord.Id);
                    }
                }
            }
            cloneAttachments(newParentIdsByOldParentIds);
        }
    }

    /**
     * createDestinationOrgs: It is creating destination org for new automation deployment.
     *
     * ## targetCredentialId (Id): targetCredentialId
     * ## advancedDeploymentRecordId (Id): advancedDeploymentRecordId
     */
    private static void createDestinationOrgs(Id targetCredentialId, Id advancedDeploymentRecordId) {
        Destination_Org__c destinationOrg = new Destination_Org__c();
        destinationOrg.Deployment__c = advancedDeploymentRecordId;
        destinationOrg.To_Org__c = targetCredentialId != null ? targetCredentialId : returnDefaultOrgId();
        destinationOrg.Status__c = NOT_STARTED;
        Utilities.Secure_DML(DestinationOrg, Utilities.DML_Action.INS, schema.Sobjecttype.Destination_Org__c);
    }

    /**
     * cloneAttachments: It is going to clone attachments under automation template into new advanced deployment record
     *
     * ## newParentIdsByOldParentIds (Id): newParentIdsByOldParentIds
     */
    private static void cloneAttachments(Map<Id, Id> newParentIdsByOldParentIds) {
        List<Attachment> newAttachments = new List<Attachment>();
        for (Attachment attachmentRecord : [
            SELECT Id, Body, Name, ContentType, IsPrivate, ParentId
            FROM Attachment
            WHERE ParentId = :newParentIdsByOldParentIds.keySet()
            WITH SECURITY_ENFORCED
        ]) {
            Attachment newAtachmentRecord = attachmentRecord.clone(false, false, false, false);
            newAtachmentRecord.ParentId = newParentIdsByOldParentIds.get(attachmentRecord.ParentId);
            newAttachments.add(newAtachmentRecord);
        }
        if (!newAttachments.isEmpty()) {
            Utilities.Secure_DML(newAttachments, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
        }
    }

    // INNER

    // TODO: this is only used in nextJob triger so when refactoring it,
    // should me moved trigger helper
    public class StepAttachmentDetails {
        public String automationId { get; set; }
    }
}