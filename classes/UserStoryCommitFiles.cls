global with sharing class UserStoryCommitFiles {
    /**
     * Custom object for storing InvocableVariables. InvocableMethods requires List<T> where T is a user defined type.
     * You cannot pass Boolean, String or any other primitive type as a variable to an Invocable method.
     * Custom Object types, sObjects or Ids are the only supported types.
     * @see InvocableVariable
     * @see InvocableMethod
     */
    global with sharing class InvocableVariables {
        @InvocableVariable(label = 'User Story Id' required = TRUE)
        Global Id userStoryId;
        @InvocableVariable(label = 'Commit Message' required = TRUE)
        Global String commitMessage;
        @InvocableVariable(label = 'JSON Body' required = TRUE)
        Global String jsonBody;
    }
    /**
     * Invocable method for allowing users to call Copado webhook urls for running a User Story commit.
     * @param  variables InvocableVariables
     * @return           void
     * @see InvocableVariable
     * @see InvocableMethod
     * @see RecalculateBranchStatus.doCallout
     */
    @InvocableMethod(label = 'Commit User Story' description = 'Sends request to given Copado webhookUrl')
    global static void execute(List<InvocableVariables> variables) {
        String apiKey = DeployAPI.getUserAPIKey();
        String copadoURL = Settings.Server_URL;
        if(String.isBlank(apiKey)) throw new AsyncException(System.Label.API_KEY_MISSING);
        String url = copadoURL+'/json/v1/webhook/commitFiles/'+variables[0].userStoryId+'?api_key='+apiKey+'&commitMessage='+EncodingUtil.urlEncode(variables[0].commitMessage, 'UTF-8');
        UserStoryCommitFiles.doCallout(url, variables[0].jsonBody);
    }
    /**
     * Future method that executes the HTTP request against given webhook.
     * Defined as future in order to avoid "You have uncommitted work pending. Please commit or rollback before calling out" issue
     * Since process builder depends on a DML on the given object there will always be an uncommited work for immediate actions
     * @param url     Complete copado webhook url that will appear as a required parameter while creating the process from process builder
     */
    @Future(callout = TRUE)
        private static void doCallout(String url, String jsonBody) {
        WebhookAPI.callGenericWebhookWithJsonBody(url, jsonBody);
    }
}