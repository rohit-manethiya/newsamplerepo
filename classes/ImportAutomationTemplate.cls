global with sharing class ImportAutomationTemplate {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Content' required=true)
        global List<String> contentDocumentIds;
    }

    @InvocableMethod(label='Import Automation Template' description='Import Automation template record with related steps')
    global static List<String> execute(List<InvocableVariables> variables) {
        String automationId = AutomationTemplateExportImportHelper.parseContentDocumentDataAndReturnAutomationRecordId(
            variables[0].contentDocumentIds
        );
        return new List<String>{ automationId };
    }
}