@isTest
private with sharing class WebhookSchedulable_Test {

    @TestSetup
    private static void setup() {
        createUserAPIKey();
    }

    @isTest
    private static void checkUserApiKeyAdded() {
        // Setup
        String webhookUrl = 'https://test.com/webhook';
        Scheduled_Job__c job = createJob(webhookUrl);


        // Exercise
        Test.startTest();
        WebhookSchedulable schedulable = new WebhookSchedulable(job.Id);
        schedulable.execute(null);
        Test.stopTest();


        // Verify
        Scheduled_Job_Run__c jobRun = [SELECT Called_URL__c FROM Scheduled_Job_Run__c WHERE Scheduled_Job__c = :job.Id];
        PageReference page = new PageReference(jobRun.Called_URL__c);
        String calledUrl = page.getUrl();
        Map<String, String> urlParameters = page.getParameters();

        System.assertEquals(webhookUrl, calledUrl.substringBefore('?'), 'URL should not change');
        System.assert(urlParameters.containsKey('api_key'), 'Query parameters should contain api_key parameter');
        System.assertEquals(getUserAPIKey(), urlParameters.get('api_key'), 'The api_key value should match the user API Key');
    }

    @isTest
    private static void includeQueryParameters() {
        // Setup
        String webhookUrl = 'https://test.com/webhook&param1=a&param2=b&api_key=c';
        Scheduled_Job__c job = createJob(webhookUrl);


        // Exercise
        Test.startTest();
        WebhookSchedulable schedulable = new WebhookSchedulable(job.Id);
        schedulable.execute(null);
        Test.stopTest();


        // Verify
        Scheduled_Job_Run__c jobRun = [SELECT Called_URL__c FROM Scheduled_Job_Run__c WHERE Scheduled_Job__c = :job.Id];
        PageReference page = new PageReference(jobRun.Called_URL__c);
        String calledUrl = page.getUrl();
        Map<String, String> urlParameters = page.getParameters();

        System.assertEquals(webhookUrl.substringBefore('&'), calledUrl.substringBefore('?'), 'URL should not change');
        System.assert(urlParameters.containsKey('param1'), 'Query parameters should not change');
        System.assert(urlParameters.containsKey('param2'), 'Query parameters should not change');
        System.assert(urlParameters.containsKey('api_key'), 'Query parameters should contain api_key parameter');
        System.assertEquals(getUserAPIKey(), urlParameters.get('api_key'), 'The api_key value should match the user API Key');
    }

    private static void createUserAPIKey() {
        Personal_Settings__c setting = new Personal_Settings__c(
            Name = 'Personal Settings for current user',
            SetupOwnerId = UserInfo.getUserId(),
            API_Key__c = DeployAPI.encryptAPIKey('test_apikey')
        );
        insert setting;
    }

    private static Scheduled_Job__c createJob(String url) {
        Scheduled_Job__c job = new Scheduled_Job__c(
            Name = 'test job', 
            Webhook_Url__c = url, 
            Run_As_User__c = UserInfo.getUserId());
        insert job;
        return job;
    }

    private static String getUserAPIKey() {
        return DeployAPI.getUserAPIKey();
    }
    
}