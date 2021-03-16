public with sharing class AutomationTemplateCloneHandler {
    public static Id cloneAutomationAndReturnClonedAutomationId(Id automationTemplateId) {
        Savepoint savepointItem = Database.setSavepoint();
        Deployment__c newDeployment;
        try {
            List<Deployment__c> deployments = AutomationTemplateExportImportHelper.returnAutomationWithSteps(automationTemplateId);
            Map<Id, Step__c> stepsByIds = new Map<Id, Step__c>();
            for (Deployment__c deploymentRecord : deployments) {
                newDeployment = deploymentRecord.clone(false);
                for (Step__c stepRecord : deploymentRecord.Steps__r) {
                    Step__c newStep = stepRecord.clone(false);
                    stepsByIds.put(stepRecord.Id, newStep);
                }
            }
            String automationDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Automation_Template')
                .getRecordTypeId();
            newDeployment.RecordTypeId = automationDeploymentRecordTypeId;
            newDeployment.Name = Label.Clone_of + ' ' + newDeployment.Name;
            Utilities.Secure_DML(newDeployment, Utilities.DML_Action.INS, Schema.SObjectType.Deployment__c);

            for (Step__c stepRecord : stepsByIds.values()) {
                stepRecord.Deployment__c = newDeployment.Id;
            }

            Utilities.Secure_DML(stepsByIds.values(), Utilities.DML_Action.INS, Schema.SObjectType.Step__c);
            List<Attachment> attachments = new List<Attachment>();
            for (Attachment attachmentRecord : [SELECT ParentId, Name, ContentType, Body FROM Attachment WHERE ParentId IN :stepsByIds.keyset()]) {
                Attachment newAttachment = attachmentRecord.clone(false);
                newAttachment.ParentId = stepsByIds.get(attachmentRecord.ParentId).Id;
                attachments.add(newAttachment);
            }
            Utilities.Secure_DML(attachments, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);
        } catch (Exception ex) {
            Database.rollback(savepointItem);
        }
        return newDeployment?.Id;
    }
}