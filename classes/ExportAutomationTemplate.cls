global with sharing class ExportAutomationTemplate {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Automation Template Id' required=true)
        global Id automationTemplateId;
        @InvocableVariable(label='Automation Template Name' required=false)
        global String automationTemplateName;
    }

    @InvocableMethod(label='Export Automation Template' description='Export Automation template record with related steps')
    global static List<String> execute(List<InvocableVariables> variables) {
        String contentDocumentFileId = AutomationTemplateExportImportHelper.exportAutomationAndReturnContentDocumentId(
            variables[0].automationTemplateId,
            variables[0].automationTemplateName
        );
        return new List<String>{ contentDocumentFileId };
    }
}