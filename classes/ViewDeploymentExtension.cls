public with sharing class ViewDeploymentExtension {
    public ApexPages.StandardController stdController {get; set;}
    public Deployment__c deployment {get;set;}
    
    public List<Step__c> steps {get;set;}   
    public List<Destination_Org__c> destinationOrgs {get;set;}
    public List<matrixWrapper> matrix {get;set;}
    public Map<String, Deployment_Job__c> mapDeploymentJobsString {get;set;}
    
    // STEPS
    public ID selectedStep {get;set;}
    public Step__c step {get; set;}
    public ApexPages.StandardController stepController {get; set;}
    public Map<Id, Step__c> mapSteps {get;set;}
    public String dataStepQuery {get;set;}
    public String dataStepObject {get;set;}
    public String dataStepExternalId {get;set;}
    
    // ERRORS
    public boolean runPoller {get;set;}
    public Map<String, boolean> mapAttachments {get;set;}
    
    public class matrixWrapper{
        public Step__c step {get;set;}
        public List<Deployment_Job__c> jobs {get;set;}
        public matrixWrapper(Step__c s, List<Deployment_Job__c> js){
            this.step = s;
            this.jobs = js;
        }
    }
    public ViewDeploymentExtension(ApexPages.StandardController stdController) {
        deployment = (Deployment__c)stdController.getRecord();
        if(deployment==null)deployment=new Deployment__c();
        buildMatrix();

    }
    public void getStepDetail(){
        step = new Step__c();
        step = Utilities.getStepById(selectedStep);
        dataStepQuery = '';
        dataStepObject = '';
        dataStepExternalId = '';
        if(step.type__c=='Data'||step.type__c=='Bulk Data'){
            Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(step.datajson__c);
            dataStepQuery = (String)fullMap.get('q');
            dataStepObject = (String)fullMap.get('o');
            dataStepExternalId = (String)fullMap.get('f');
        }
    }
    public PageReference buildMatrix(){
        runPoller = false;
        deployment = Utilities.getDeploymentById(EncodingUtil.urlEncode(ApexPages.currentPage().getParameters().get('id'),'UTF-8'));
        if(deployment.status__c=='In progress'||deployment.status__c=='Scheduled'){
            runPoller = true;
        }
        steps = new List<Step__c>();
        step = new Step__c();
        stepController = new ApexPages.StandardController(step);
        destinationOrgs = new List<Destination_Org__c>();
        matrix = new List<matrixWrapper>();
        mapDeploymentJobsString = new Map<String, Deployment_Job__c>();
        mapSteps = new Map<Id, Step__c>();
        
        steps = Utilities.getStepsByDeploymentId(deployment.Id);
        for(Step__c s : steps){ 
            mapSteps.put(s.id, s); 
            if(selectedStep == s.id){
                step = s;
            }
        }
        destinationOrgs = Utilities.getDestinationOrgsByDeploymentId(deployment.Id);
        
        List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>();
        if(Schema.sObjectType.Deployment_Job__c.isQueryable() && Schema.sObjectType.Deployment_Job__c.isAccessible()) deploymentJobs = [SELECT Id, Name, Deployed__c, Destination_Org__c, External_Id__c, Status__c, Status_Flag__c, Step__c, To_Org_Name__c FROM Deployment_Job__c WHERE Step__r.deployment__c = :EncodingUtil.urlEncode(deployment.Id,'UTF-8') LIMIT 10000];
        Set<Id> completedJobs = new Set<Id>();
        mapAttachments = new Map<String, boolean>();
        //Set<Id> parentIdSet = new Set<Id>();
        for(Deployment_Job__c d : deploymentJobs){
            mapDeploymentJobsString.put(d.step__c+''+d.destination_org__c, d);
            if(d.status__c=='Failed')completedJobs.add(d.Id);
            //parentIdSet.add(d.Id);
            mapAttachments.put(d.Id+'.json', false);
        }
        //if(deployment.status__c == 'Completed with Errors'){
           // parentIdSet.add(deployment.Id);
        //}
        mapAttachments.put(deployment.Id+'.json', false);
        List<Attachment> attachments = [SELECT Id, ParentId, Name, Body FROM Attachment WHERE
            //ParentId in :parentIdSet and 
            ParentId = :EncodingUtil.urlEncode(deployment.Id,'UTF-8') and
            Name LIKE '%.json' AND (NOT(Name LIKE 'OLD_%')) LIMIT 10000];
        Attachment deploymentErrorAttachment = null;
        for(Attachment a : attachments){
            if(a.name==deployment.Id+'.json'){
                deploymentErrorAttachment = a;
            }
            mapAttachments.put(a.name, true);
        }
        if(deploymentErrorAttachment != null){
            //system.debug('#### deployment error attachement body: '+deploymentErrorAttachment.body.tostring());
            List<errorWrapper> errorList = new List<errorWrapper>();
            errorList = (List<errorWrapper>)JSON.deserialize(deploymentErrorAttachment.body.tostring(), List<errorWrapper>.class);
            //system.debug('#### errorList.size(): '+errorList.size());
            for(errorWrapper er : errorList){
                //system.debug('#### er.m: '+er.m);
                if(er.l=='ERROR')ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, er.m));
                else if(er.l=='INFO')ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, er.m));
                else if(er.l=='WARNING')ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, er.m));
                else if(er.l=='CONFIRM')ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, er.m));
                else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, er.m));
            }               
        }
        Integer rowCount = 0;
        for(Step__c s : steps){
            List<Deployment_Job__c> tmpList = new List<Deployment_Job__c>();
            for(Deployment_Job__c d : deploymentJobs){
                if(d.step__c == s.id)tmpList.add(d);
            }
            matrix.add(new matrixWrapper(s, tmpList));
        }
        return null;
    }
    public class errorWrapper{
        public string l{get;set;}
        public string m{get;set;}
        public string t{get;set;}
        public errorWrapper(String sl, String sm, String st){
            this.l = sl;
            this.m = sm;
            this.t = st;
        }
    }   
}