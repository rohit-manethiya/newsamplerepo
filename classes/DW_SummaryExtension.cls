/**
 * It is main controller for DW_Summary page
 */
public with sharing class DW_SummaryExtension extends DeploymentHelper {
    public final String C_SUCCESS = 'Completed Successfully';
    public String deploymentJobId { get; set; }
    public String stepId { get; set; }
    public String namespace { get; set; }

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_SummaryExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
        namespace = Settings.ns;

        if(deploymentInterface.getStepGeneralHeader() != Label.New_Data_Deployment) {
            initializeMetadataUrl();
        } else {
            getDataTemplateDetails();
        }

        List<Step__c> stepList = new List<Step__c>();
        if(Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            stepList = new List<Step__c>([SELECT Id, Status__c FROM Step__c WHERE Deployment__c = :deployment.Id LIMIT 1]);
            stepId = !stepList.isEmpty() ? stepList[0].Id : '';
        }
        if(!stepList.isEmpty() && stepList[0].Status__c == C_SUCCESS) {
            Deployment_Job__c djItem;
            if(Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
                djItem = [SELECT Id FROM Deployment_Job__c WHERE Step__c = :stepList[0].Id ORDER BY CreatedDate DESC];
            }
            deploymentJobId = djItem != null ? djItem.Id : '';
        }
    }

    /**
     * It is used to clone the deployment with all related records and attachment
     * Deployment record will be cloned and "Deployment_Last_Step__c" set as "DW_Source" to start wizard from first step
     * Destination org will be cloned and tied to cloned Deployment
     * Step will be cloned and tied to cloned Deployment
     * "MetaData" or "Git Metadata" attachment will be cloned and tied to cloned Step
     * Used database savepoint to prevent creation of failure records
     *
     * @return It will go to the first step of the deployment wizard
     */
    public PageReference deepCloneDeployment() {
        // setup the save point for rollback
        Savepoint sp;
        if(!Test.isRunningTest()) {
            sp = Database.setSavepoint();
        }
        String deploymentId = deployment.Id;
        try {
            // Clone Deployment
            Deployment__c clonedDeployment = deployment.clone(false, false, false, false);
            clonedDeployment.Deployment_Last_Step__c = 'DW_Source';
            Utilities.Secure_DML(clonedDeployment, Utilities.DML_Action.INS, schema.SObjectType.Deployment__c);

            // Clone Destination Org
            Map<String, Schema.SObjectField> schemaDestinationOrgFieldMap = Schema.SObjectType.Destination_Org__c.fields.getMap();
            List<String> destinationOrgFieldsList = new List<String>();
            for(String fieldName : schemaDestinationOrgFieldMap.keySet()) {
                destinationOrgFieldsList.add(fieldName);
            }
            String destinationOrgFields = String.join(destinationOrgFieldsList, ',');
            String destinationOrgQuery = 'SELECT ' + destinationOrgFields + ' FROM Destination_Org__c WHERE Deployment__c = :deploymentId LIMIT 1';
            if(Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
                List<Destination_Org__c> doList = Database.query(destinationOrgQuery);

                Destination_Org__c clonedDestinationOrg = doList[0].clone(false, false, false, false);
                clonedDestinationOrg.Deployment__c = clonedDeployment.Id;
                Utilities.Secure_DML(clonedDestinationOrg, Utilities.DML_Action.INS, schema.SObjectType.Destination_Org__c);
            } else {
                pageMessagesMap.put(C_WARNING, new List<Object>{
                        Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Destination_Org__c.getLabel()
                });
                return null;
            }

            // Clone Step
            Map<String, Schema.SObjectField> schemaStepFieldMap = Schema.SObjectType.Step__c.fields.getMap();
            List<String> stepFieldsList = new List<String>();
            for(String fieldName : schemaStepFieldMap.keySet()) {
                stepFieldsList.add(fieldName);
            }
            String stepFields = String.join(stepFieldsList, ',');
            String stepQuery = 'SELECT ' + stepFields + ' FROM Step__c WHERE Deployment__c = :deploymentId LIMIT 1';
            List<Step__c> stepList = new List<Step__c>();
            Step__c clonedStep;
            if(Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
                stepList = Database.query(stepQuery);

                clonedStep = stepList[0].clone(false, false, false, false);
                clonedStep.Deployment__c = clonedDeployment.Id;
                Utilities.Secure_DML(clonedStep, Utilities.DML_Action.INS, schema.SObjectType.Step__c);
            } else {
                pageMessagesMap.put(C_WARNING, new List<Object>{
                        Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Step__c.getLabel()
                });
                return null;
            }

            // Clone Attachment
            Map<String, Schema.SObjectField> schemaAttachmentFieldMap = Schema.SObjectType.Attachment.fields.getMap();
            List<String> attachmentFieldsList = new List<String>();
            for(String fieldName : schemaAttachmentFieldMap.keySet()) {
                attachmentFieldsList.add(fieldName);
            }
            String attachmentFields = String.join(attachmentFieldsList, ',');
            String stepId = stepList[0].Id;
            String attachmentQuery = 'SELECT ' + attachmentFields + ' FROM Attachment WHERE ParentId = :stepId LIMIT 1';
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                List<Attachment> attachmentList = Database.query(attachmentQuery);

                Attachment clonedAttachment = attachmentList[0].clone(false, false, false, false);
                clonedAttachment.ParentId = clonedStep.Id;
                Utilities.Secure_DML(clonedAttachment, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
            } else {
                pageMessagesMap.put(C_WARNING, new List<Object>{
                        Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Attachment.getLabel()
                });
                return null;
            }

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put(C_ID, clonedDeployment.Id);
            pReference.setRedirect(true);
            return pReference;
        } catch(Exception excp) {
            // roll everything back in case of error
            Database.rollback(sp);
            pageMessagesMap.put(C_ERROR, new List<Object>{
                    excp.getMessage()
            });
            return null;
        }
    }

    /**
     * It is used when user want to start a new deployment
     *
     * @return
     */
    public PageReference startNewDeployment() {
        PageReference pReference = Page.DW_Intermediary;
        pReference.setRedirect(true);
        return pReference;
    }
}