global with sharing class RunUserStoryTests {
    /**
    * Custom object for storing InvocableVariables. InvocableMethods requires List<T> where T is a user defined type.
    * You cannot pass Boolean, String or any other primitive type as a variable to an Invocable method.
    * Custom Object types, sObjects or Ids are the only supported types.
    * @see InvocableVariable
    * @see InvocableMethod
    */
    global class InvocableVariables {
        @InvocableVariable(Label = 'User Story Id' Required = TRUE)
        global Id userStoryId;
    }
    /**
     * Invocable method for allowing users to call Copado webhook urls for running a User Story unit tests.
     * @param  variables InvocableVariables
     * @return           void
     * @see InvocableVariable
     * @see InvocableMethod
     * @see RunUserStoryTests.doCallout
     */
    @InvocableMethod(Label = 'Run User Story Test' Description = 'Sends request to given Copado webhookUrl')
    global static void execute(List<InvocableVariables> variables) {
        String apiKey = DeployAPI.getUserAPIKey();
        String copadoURL = Settings.server_url;
        if(String.isBlank(apiKey)) {
            throw new AsyncException(System.Label.API_KEY_MISSING);
        }
        String url = copadoURL + '/json/v1/webhook/apexTest/' + variables[0].userStoryId + '?api_key=' + apiKey;
        RunUserStoryTests.doCallout(url);
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