global with sharing class RunUserStoryComplianceScan {
    /**
     * Custom object for storing InvocableVariables. InvocableMethods requires List<T> where T is a user defined type.
     * You cannot pass Boolean, String or any other primitive type as a variable to an Invocable method.
     * Custom Object types, sObjects or Ids are the only supported types.
     * @see InvocableVariable
     * @see InvocableMethod
     */
    global with sharing class InvocableVariables {
        @InvocableVariable(label = 'User Story Id' required = TRUE)
        global Id storyId;
        @InvocableVariable(label = 'Git Repository Id' required = TRUE)
        global Id repoId;
        @InvocableVariable(label = 'Branch Name' required = TRUE)
        global String branch;
    }
    /**
     * Invocable method for allowing users to call Copado webhook urls for running a Compliance Scan
     * @param  variables InvocableVariables
     * @return           void
     * @see InvocableVariable
     * @see InvocableMethod
     */
    @InvocableMethod(label = 'User Story Compliance Scan' description = 'Sends request to given Copado webhookUrl')
    global static void execute(List<InvocableVariables> variables){
        String apiKey = DeployAPI.getUserAPIKey();
        String copadoURL = Settings.Server_URL;
        if(String.isBlank(apiKey)) throw new AsyncException(System.Label.API_KEY_MISSING);
        String url = copadoURL+'/json/v1/webhook/scanCompliance?api_key='+apiKey+'&userStoryId='+variables[0].storyId+'&repositoryId='+variables[0].repoId+'&branch='+variables[0].branch;
        RunUserStoryComplianceScan.doCallout(url);
    }
    /**
     * Future method that executes the HTTP request against given webhook.
     * Defined as future in order to avoid "You have uncommitted work pending. Please commit or rollback before calling out" issue
     * Since process builder depends on a DML on the given object there will always be an uncommited work for immediate actions
     * @param url     Complete copado webhook url that will appear as a required parameter while creating the process from process builder
     */
    @Future(callout = TRUE)
    private static void doCallout(String url) {
        WebhookAPI.callGenericWebhook(url);
    }
}