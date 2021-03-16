public with sharing class SalesforceFlowStepController {

    public static String executeSelectedFlow(final Map<String, Object> selectedFlowWithParameters) {

        try {
            final Flow.Interview flowInterviewToExecute = getFlowInterview(selectedFlowWithParameters);
            flowInterviewToExecute.start();
            return Label.FLOW_EXECUTED_SUCCESSFULLY;
        } catch (final Exception e) {
            return String.format(Label.ERROR_FLOW_EXECUTION, new List<Object>{ e.getMessage() });
        }
    }


    private static Flow.Interview getFlowInterview(final Map<String, Object> selectedFlowWithParameters) {
        String flowApiName = (String) selectedFlowWithParameters.get('flowApiName');
        String flowNamespace = '';
        if (flowApiName.contains('.')) {
            flowNamespace = flowApiName.substringBefore('.');
            flowApiName = flowApiName.substringAfter('.');
        }
        return Flow.Interview.createInterview(flowNamespace, flowApiName, (Map<String, Object>) selectedFlowWithParameters.get('flowParameters'));

    }
}