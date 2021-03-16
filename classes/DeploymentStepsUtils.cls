public with sharing class DeploymentStepsUtils {
    @AuraEnabled
    public static void updateRecords(List<SObject> records) {
        try {
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, records);
            update securityDecision.getRecords();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getLastAttachmentBodyAsString(final String name, final String parentId) {
        try {
            final Attachment attachment = getLastChildAttachmentByName(name, parentId);
            return attachment.Body.toString();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String upsertAttachment(final String name, final String parentId, final String body) {
        final Attachment attachment;
        try {
            attachment = getLastChildAttachmentByName(name, parentId);
        } catch (System.QueryException e) {
            attachment = new Attachment(Name = name, ParentId = parentId);
        }
        attachment.Body = Blob.valueOf(body);
        try {
            // FALSE POSITIVE: Security.stripInaccessible removes parentId
            // causing an error and permissions over Attachment can not be controlled
            upsert attachment;
            return body;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    private static Attachment getLastChildAttachmentByName(final String name, final String parentId) {
        return [
            SELECT Body
            FROM Attachment
            WHERE Name = :name AND parentId = :parentId
            WITH SECURITY_ENFORCED
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
    }

    /**
     * TriggerType values can be Scheduled, PlatformEvent, RecordAfterSave, among others. Null means it is not automatically fired by itself.
     * NamespacePrefix will contain the namespace if the flow was installed from a package, which is ManegeableState = true
     * ProcessType can have also values Flow which means it is an screen flow, and Workflow, CustomEvent OR InvocableProcess which means it is a process builder
     */
    @AuraEnabled(cacheable=true)
    public static String getFlowsAvailableForExecution() {
        try {
            final List<FlowOptionWrapper> flowOptionWrappersAvailableForExecution = new List<FlowOptionWrapper>();
            for (FlowDefinitionView flowAvailableForExecution : [
                SELECT ApiName, Label, NamespacePrefix
                FROM FlowDefinitionView
                WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = TRUE AND IsTemplate = FALSE AND TriggerType = NULL
            ]) {
                final String namespace = getFlowNamespace(flowAvailableForExecution);
                flowOptionWrappersAvailableForExecution.add(
                    new FlowOptionWrapper(namespace + flowAvailableForExecution.ApiName, namespace + flowAvailableForExecution.Label)
                );
            }
            return JSON.serialize(flowOptionWrappersAvailableForExecution);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String getFlowNamespace(FlowDefinitionView flowDefinition) {
        return flowDefinition.NamespacePrefix != null ? flowDefinition.NamespacePrefix + '.' : '';
    }

    @TestVisible
    private class FlowOptionWrapper {
        private final String flowApiName;
        private final String flowLabel;

        @TestVisible
        private FlowOptionWrapper(final String flowApiName, final String flowLabel) {
            this.flowApiName = flowApiName;
            this.flowLabel = flowLabel;
        }
    }
}