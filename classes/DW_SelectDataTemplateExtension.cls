public with sharing class DW_SelectDataTemplateExtension extends DeploymentHelper {

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_SelectDataTemplateExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        initializeServiceClasses();
        populateActiveDataTemplates();
        populateStepsList();
        populatePagesList();
    }

    /**
     * It is used to populate active data template records
     */
    private void populateActiveDataTemplates() {
        List<Data_Template__c> dataTemplateList = new List<Data_Template__c>();
        try {
            dataTemplateList = [SELECT Id, Name, Description__c FROM Data_Template__c WHERE Active__c = TRUE WITH SECURITY_ENFORCED LIMIT 1000];
        } catch(Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{
                    excp.getMessage()
            });
            return;
        }
        String existingDataTemplateId = checkExistingDeploymentStep();
        sourceList = new List<SourceWrapper>();
        if(!dataTemplateList.isEmpty()) {
            for(Data_Template__c dt : dataTemplateList) {
                Boolean alreadyExist = String.isNotBlank(existingDataTemplateId) && existingDataTemplateId == dt.Id;
                sourceList.add(new SourceWrapper(alreadyExist, null, '', '', '', '', '', '', null, dt));
            }
            sourceList.sort();
        }
    }


    /**
     * It is used to insert step and attachment before do any operations.
     * If there is already step created before, it will check if the data template is changed or not
     */
    private void upsertStepAndAttachment() {
        try {
            List<Step__c> stepList = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deployment.Id AND Type__c = :DATA_TEMPLATE WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
            if(!stepList.isEmpty()) {
                StepAttachmentDetails existingJson = (StepAttachmentDetails) JSON.deserialize(stepList[0].dataJson__c, StepAttachmentDetails.class);
                Boolean dataTemplateChanged = false;
                for(SourceWrapper sw : sourceList) {
                    if(sw.isSelected && sw.template.Id != existingJson.dataTemplateId) {
                        existingJson.dataTemplateId = sw.template.Id;
                        dataTemplateChanged = true;
                    }
                }
                if(dataTemplateChanged) {
                    StepAttachmentDetails sad = new StepAttachmentDetails();
                    sad.dataTemplateId = existingJson.dataTemplateId;
                    stepList[0].dataJson__c = JSON.serialize(sad);
                    Utilities.Secure_DML(stepList, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);

                    List<Attachment> attachmentList = [SELECT Id, Body FROM Attachment WHERE ParentId = :stepList[0].Id AND Name = :DATA_TEMPLATE WITH SECURITY_ENFORCED];

                    if(!attachmentList.isEmpty()) {
                        attachmentList[0].Body = Blob.valueOf(JSON.serialize(sad));
                        Utilities.Secure_DML(attachmentList, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
                    }
                }
                return;
            }

            Boolean dataTemplateIsSelected = false;
            String selectedTemplateId = '';
            for(SourceWrapper sWrapper : sourceList) {
                if(sWrapper.isSelected) {
                    dataTemplateIsSelected = true;
                    selectedTemplateId = sWrapper.template.Id;
                }
            }

            if(!dataTemplateIsSelected) {
                pageMessagesMap.put(C_ERROR, new List<Object>{
                        Label.Select_One_Data_Deployment
                });
                return;
            }

            StepAttachmentDetails sad = new StepAttachmentDetails();
            sad.dataTemplateId = selectedTemplateId;

            Step__c step = new Step__c();
            if(Schema.SObjectType.Step__c.fields.Deployment__c.isCreateable() && Schema.SObjectType.Step__c.fields.Type__c.isCreateable() && Schema.SObjectType.Step__c.fields.Status__c.isCreateable() && Schema.SObjectType.Step__c.fields.Order__c.isCreateable() && Schema.SObjectType.Step__c.fields.Commit_Name__c.isCreateable() && Schema.SObjectType.Step__c.fields.dataJson__c.isCreateable()) {
                step.Deployment__c = deployment.Id;
                step.Name = 'Step 1';
                step.Type__c = DATA_TEMPLATE;
                step.Status__c = 'Not Started';
                step.Order__c = 1;
                step.Commit_Name__c = null;
                step.dataJson__c = JSON.serialize(sad);
                Utilities.Secure_DML(step, Utilities.DML_Action.INS, schema.SObjectType.Step__c);
            }

            Attachment att = new Attachment();
            att.Name = DATA_TEMPLATE;
            att.ParentId = step.Id;
            att.Body = Blob.valueOf(JSON.serialize(sad));
            Utilities.Secure_DML(att, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
        } catch(Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{
                    excp.getMessage()
            });
            return;
        }
    }

    /**
     * It is used to save current step and go to deployment tab
     *
     * @return
     */
    public PageReference saveStepAndClose() {
        pageMessagesMap.clear();
        upsertStepAndAttachment();
        return pageMessagesMap.isEmpty() ? goToDeploymentTab() : null;
    }

    /**
     * It is used when user click on "Review Filters"
     * First of all, we will try to upsert step
     *
     * @see DeploymentHelper
     * @return
     */
    public PageReference confirmAndGoNextStep() {
        pageMessagesMap.clear();
        goOverrideFilters = true;
        upsertStepAndAttachment();
        upsertDeployment(true);
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }

    /**
     * It is used when user click on "Confirm Selection"
     * First of all, we will try to upsert step
     *
     * @see DeploymentHelper
     * @return
     */
    public PageReference confirmAndGoOverride() {
        skipOverrideFilters = true;
        return confirmAndGoNextStep();
    }
}