public with sharing class WebhookAPI {
    public static String copadoURL = Settings.Server_URL;
    class ServerException extends Exception {}
    public static void runSeleniumTest(Id runId, String api_key){
        String url = copadoURL+'/json/v1/webhook/selenium/TestRun/'+runId+'?api_key='+api_key;
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
		req.setHeader('Content-Length', '0');
        sendReq(req);
    }
    
    public static void runSeleniumTestGroup(Id groupId, String api_key){
        if(!Test.isRunningTest()){
            String url = copadoURL+'/json/v1/webhook/selenium/TestGroupRun/'+groupId+'?api_key='+api_key;
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            req.setEndpoint(url);
            req.setMethod('POST');
            // fix for GCP issue with POST without body: Force Content-Length: 0
			req.setHeader('Content-Length', '0');
            sendReq(req);
        }
        
    }
    
    public static void setJobStatus(Id copadoJobId, String status, String api_key){
        String url = copadoURL+'/json/v1/webhook/jobStatus/'+copadoJobId+'/'+ status +'?api_key='+api_key;
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
		req.setHeader('Content-Length', '0');
        sendReq(req);
    }
    
    public static void setGroupJobStatus(Id groupId, String status, String api_key){
        String url = copadoURL+'/json/v1/webhook/groupJobStatus/'+groupId+'/'+ EncodingUtil.urlEncode(status,'UTF-8') +'?api_key='+api_key;
        System.debug('POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
		req.setHeader('Content-Length', '0');
        sendReq(req);
    }
    
    @Future(callout=true)
    public static void callGenericWebhookAtFuture(String url, String schedId){
        Scheduled_Job__c sched = new Scheduled_Job__c();
        if(Schema.sObjectType.Scheduled_Job__c.isQueryable()) sched = [select Id, Name, Run_as_User__c, Delete_Runs_after_days__c from Scheduled_Job__c where Id=:schedId];
        Scheduled_Job_Run__c run = new Scheduled_Job_Run__c(Scheduled_Job__c = schedId, Called_URL__c = url, Run_as_User__c = sched.Run_as_User__c);
        try{
         	WebhookAPI.callGenericWebhook(url);
            run.Status__c = 'Success';
        }
        catch(Exception e){
            run.Status__c = 'Failure';
            run.Message__c = e.getMessage();
        }
        Utilities.Secure_DML(run, Utilities.DML_Action.INS, schema.Sobjecttype.Scheduled_Job_Run__c);
        sched.Status__c = run.Status__c;
        sched.Message__c= run.Message__c;
        if(sched.Delete_Runs_after_days__c == null)sched.Delete_Runs_after_days__c = 10;
        Utilities.Secure_DML(sched, Utilities.DML_Action.UPD, schema.Sobjecttype.Scheduled_Job__c);
        Date d = System.today() - sched.Delete_Runs_after_days__c.intValue();
        Utilities.Secure_DML([select id from Scheduled_Job_Run__c where CreatedDate < :d], Utilities.DML_Action.DEL, schema.Sobjecttype.Scheduled_Job_Run__c);
    }
    public static void callGenericWebhook(String url){
        System.debug('POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
		req.setHeader('Content-Length', '0');
        sendReq(req);
    }
    public static void callGenericWebhookWithJsonBody(String url, String jsonBody){
        System.debug('POST -> ' + url);
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        req.setHeader('Accept', 'application/json' );
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setEndpoint(url);
        req.setBody(jsonBody);
        req.setMethod('POST');
        sendReq(req);
    }
    private static void sendReq(HttpRequest req){
        Http h = new Http();
        HttpResponse res = h.send(req);
        String body = res.getBody();
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(body);
        if(m.containsKey('error')){
            String errorMessage = (String)m.get('error');
            throw new ServerException(errorMessage);
        }
        if(res.getStatusCode() >=400){
            throw new ServerException(res.getStatusCode() + ' - ' + res.getStatus());
        }
    }
}