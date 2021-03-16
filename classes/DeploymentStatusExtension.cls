public with sharing class DeploymentStatusExtension{

    public Deployment__c deployment {get;set;}
    public ApexPages.StandardController controller {get;set;}
    public List<wrapper> wrapperList {get;set;}
    public List<String> destOrgs {get;set;}
    public Settings settings {get;set;}

    public static final String[] DEPLOYMENT_FIELDS = new String[] {'Id','Name','From_Org__c', 'From_Org__r.Name', 'Status__c'};
    
    public DeploymentStatusExtension(ApexPages.StandardController std){
        settings = new Settings();
        controller = std;
        if (!Test.isRunningTest())controller.addFields(DEPLOYMENT_FIELDS);
        deployment = (Deployment__c)std.getRecord();    
        getDeploymentJobs();
    }
    public void getDeploymentJobs(){
        wrapperList = new List<wrapper>();
        destOrgs = new List<String>();
        Map<Id,List<Deployment_Job__c>> tmpMap = new Map<Id,List<Deployment_Job__c>>();
        List<Id> orderedList = new List<Id>();
        List<Step__c> sl = new List<Step__c>();
        if(Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            sl = [SELECT Id, Name, Deployment__c, Type__c, Order__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :deployment.Id ORDER BY Order__c ASC];
        }
        Map<Id, Step__c> stepMap = new Map<Id, Step__c>();
        for(Step__c s : sl){
            orderedList.add(s.Id);
            stepMap.put(s.Id, s);
            tmpMap.put(s.Id, new List<Deployment_Job__c>());
        }
        List<Deployment_Job__c> jobs = new List<Deployment_Job__c>();
        if(Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            jobs = [SELECT Id, Status__c, To_Org_Name__c, Step__c, Async_Job_ID__c, Destination_Org__r.To_Org__c FROM Deployment_Job__c WHERE Step__r.Deployment__c=:deployment.Id];
        }
        
        for(Deployment_Job__c dj : jobs){
            List<Deployment_Job__c> tmp = tmpMap.get(dj.Step__c);
            tmp.add(dj);
            tmpMap.put(dj.Step__c, tmp);
        }
        String tmpId = '';
        for(Id i : orderedList){
            wrapperList.add(new wrapper(stepMap.get(i), tmpMap.get(i)));
            tmpId = i;
        }
        for(Deployment_Job__c dj : tmpMap.get(tmpId)){
            destOrgs.add(dj.To_Org_Name__c);
        }
    }
    public class wrapper{
        public Step__c step {get;set;}
        public List<Deployment_Job__c> jobs {get;set;}
        public wrapper(Step__c s, List<Deployment_Job__c> js){
            this.step = s;
            this.jobs = js;
        }
    }
}