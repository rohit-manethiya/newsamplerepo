global with sharing class CloneAutomationTemplate {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Automation Template Id' required=true)
        global Id automationTemplateId;
    }

    @InvocableMethod(label='Clone Automation Template' description='Clone Automation template record with related steps')
    global static List<String> execute(List<InvocableVariables> variables) {
        String clonedAutomationId = AutomationTemplateCloneHandler.cloneAutomationAndReturnClonedAutomationId(variables[0].automationTemplateId);
        return new List<String>{ clonedAutomationId };
    }
}