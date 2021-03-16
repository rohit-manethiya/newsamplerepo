global with sharing class WebhookSchedulable implements Schedulable, Database.AllowsCallouts {

    private Id scheduledJobID;

    public WebhookSchedulable(Id jobId) {
        this.scheduledJobID = jobId;
    }

    global void execute(SchedulableContext sc) {
        Scheduled_Job__c job = [
            SELECT Webhook_URL__c, Run_as_User__c
            FROM Scheduled_Job__c
            WHERE Id = :this.scheduledJobID
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        String url = treatJobUrl(job);

        if (String.isNotBlank(url)) {
            WebhookAPI.callGenericWebhookAtFuture(url, this.scheduledJobID);
        }
    }

    /**
     * Handles the webhook url to ensure query parameters are valid and they contain the API key
     * @param job the Scheduled_Job__c with the Webhook_URL__c field containing the url
     * @return a valid URL including the API key in the query parameters
     */
    private static String treatJobUrl(Scheduled_Job__c job) {
        String url = job.Webhook_URL__c;
        if(String.isNotBlank(url)){
            url = fixUrlQueryComponent(url);
            PageReference page = new PageReference(url);
            if (String.isNotBlank(job.Run_as_User__c)) {
                setApiKey(page);
            }
            url = page.getUrl();
        }
        return url;
    }

    private static String fixUrlQueryComponent(String url) {
        if (url.indexOf('?') == -1 && url.indexOf('&') > -1) {
            url = url.replaceFirst('&', '?');
        }
        return url;
    }

    private static void setApiKey(PageReference page) {
        String apiKey = DeployAPI.getUserAPIKey();
        page.getParameters().put('api_key', apiKey);

    }

}