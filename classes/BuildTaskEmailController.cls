public with sharing class BuildTaskEmailController {

    public static String buildTaskId {get;set;}
    public static String sortType {get;set;}
    public static String statusMessage {get;set;}
    public static String buildTaskMessage {get;set;}
    public static List<ErrorContent> errorDetails {get;set;}
    public static List<BuildTaskContent> buildTaskDetails {get;set;}
    public static final Integer MAX_BODY_LENGTH = 200000;

    public static List<Build_Task__c> buildTasks {get;set;}
    public static List<Deployment_Job__c> deploymentJobs {get;set;}


    public class BuildTaskContent implements Comparable {
        public String t {get;set;}
        public String n {get;set;}
        public Integer compareTo(Object compareTo) {
            BuildTaskContent wrapper = (BuildTaskContent) compareTo;
            if(String.isBlank(sortType) || sortType.toLowerCase()=='name'){
            	if(this.n == wrapper.n) return 0;
            	if(this.n > wrapper.n) return 1;
            }
            else{
                if(this.t == wrapper.t) return 0;
            	if(this.t > wrapper.t) return 1;
            }
            return -1;
        }
    }
    public boolean renderBuildTaskContent {get;set;}

    public static String deploymentName {get;set;}
    public static String deploymentId {get;set;}

    public class ErrorContent{
        public String l {get;set;}
        public String m {get;set;}
        public String t {get;set;}
    }
    public boolean renderTable {get;set;}

    public BuildTaskEmailController(){
        statusMessage = '';
        renderTable = false;
        renderBuildTaskContent = false;
        errorDetails = new List<ErrorContent>();
        buildTaskDetails = new List<BuildTaskContent>();
    }
    public static String getBuildTaskId(){
        return buildTaskId;
    }

    public List<BuildTaskContent> getBuildTaskList(){

        if(buildTaskDetails!=null && buildTaskDetails.size()>0)return buildTaskDetails;
        if(String.isBlank(buildTaskId)){
            buildTaskMessage = 'Build task record not found.';
            return new List<BuildTaskContent>();
        }
        buildTasks = getBuildTasks(buildTaskId);
        if(buildTasks==null || buildTasks.size()==0){
        	buildTaskMessage = 'Using a Build Task Id no records were found. Please make sure this build task ('+buildTaskId+') has a Deployment, you have access to it and has not been deleted.';
        	return new List<BuildTaskContent>();
        }
        else{
            deploymentJobs = getDeploymentJobs(buildTasks[0].Deployment__c, 'Git MetaData');
            deploymentId = buildTasks[0].Deployment__c;
            if(deploymentJobs.size()>0){
                List<Attachment> atts = getAttachment(deploymentJobs[0].Step__c, 'MetaData');
                if(atts.size()>0){
                    if(atts[0].BodyLength<=MAX_BODY_LENGTH){
                        try{
                            List<Object> results = (List<Object>)JSON.deserializeUntyped(atts[0].Body.toString());
                            for(Object o : results){
                                Map<String, Object> err = (Map<String, Object>)o;
                                BuildTaskContent ed = new BuildTaskContent();
                                try{ ed.n = (String)err.get('n'); }catch(Exception ex){ ed.n=''; }
                                try{ ed.t = (String)err.get('t'); }catch(Exception ex){ ed.t=''; }
                                buildTaskDetails.add(ed);
                            }
                            buildTaskDetails.sort();
                            buildTaskMessage = '';
                            renderBuildTaskContent = true;
                            return buildTaskDetails;
                        }
                        catch(Exception e){
                            buildTaskMessage = 'Error during parsing of JSON for build task content: '+e.getMessage();
                            return new List<BuildTaskContent>();
                        }
                    }
                    else{
                        buildTaskMessage = 'The maximum file size for the build list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.';
                    	return new List<BuildTaskContent>();
                    }
                }
                else{
                    buildTaskMessage = 'No selected metadata attachment was found';
        			return new List<BuildTaskContent>();
                }
            }
            else{
                buildTaskMessage = 'No deployment jobs could be found.';
        		return new List<BuildTaskContent>();
            }
        }
    }
    public List<ErrorContent> getErrorList(){
        if(errorDetails!=null && errorDetails.size()>0)return errorDetails;
        if(String.isBlank(buildTaskId)){
            statusMessage = 'Build task record not found.';
            return new List<ErrorContent>();
        }
        buildTasks = getBuildTasks(buildTaskId);
        if(buildTasks==null || buildTasks.size()==0){
        	statusMessage = 'Using a Build Task Id no records were found. Please make sure this build task ('+buildTaskId+') has a Deployment, you have access to it and has not been deleted.';
            return new List<ErrorContent>();
        }
        else{
            deploymentJobs = getDeploymentJobs(buildTasks[0].Deployment__c, 'Git MetaData');
            if(deploymentJobs.size()>0){
                List<Attachment> atts = getAttachment(buildTasks[0].Deployment__c, deploymentJobs[0].Id+'.json');
                if(atts.size()>0){
                    if(atts[0].BodyLength<=MAX_BODY_LENGTH){
                        try{
                            List<Object> results = (List<Object>)JSON.deserializeUntyped(atts[0].Body.toString());
                            for(Object o : results){
                                system.debug('PPP o: '+o);
                                Map<String, Object> err = (Map<String, Object>)o;
                                system.debug('PPP err: '+err+'||'+err.get('l'));
                                ErrorContent ed = new ErrorContent();
                                try{ ed.l = (String)err.get('l'); }catch(Exception ex){ ed.l=''; }
                                try{ ed.m = (String)err.get('m'); }catch(Exception ex){ ed.m=''; }
                                try{ ed.t = (String)err.get('t'); }catch(Exception ex){ ed.t=''; }
                                errorDetails.add(ed);
                            }
                            statusMessage = '';
                            renderTable = true;
                            return errorDetails;
                        }
                        catch(Exception e){
                            statusMessage = 'Error during parsing of JSON: '+e.getMessage();
                            return new List<ErrorContent>();
                        }
                    }
                    else{
                        statusMessage = 'The maximum file size for the error list attachment has been exceeded. To avoid reaching the Salesforce Heapsize limits, please review the deployment in Salesforce.';
                        return new List<ErrorContent>();
                    }
                }
                else{
                    statusMessage = 'No error attachment was found';
                	 return new List<ErrorContent>();
                }
            }
            else{
                statusMessage = 'No deployment jobs could be found.';
            	return new List<ErrorContent>();
            }
        }
    }

    public static String podUri{get;set;}
    public static String getPodUrl(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }

    private static List<Build_Task__c> getBuildTasks(String btId){
        if(buildTasks!=null){
            return buildTasks;
        }
        if(Schema.SObjectType.Build_Task__c.isQueryable() && Schema.SObjectType.Build_Task__c.isAccessible()){
            buildTasks = [SELECT Id, Deployment__c FROM Build_Task__c WHERE Id=:btId AND Deployment__c!=null];
        }
        return buildTasks;
    }
    private static List<Deployment_Job__c> getDeploymentJobs(String dId, String stepType){
        if(deploymentJobs!=null){
            return deploymentJobs;
        }
        if(Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()){
            deploymentJobs = [SELECT Id, Step__c, Step__r.Deployment__r.Name FROM Deployment_Job__c WHERE Step__r.Deployment__c=:dId AND Step__r.Type__c=:stepType];
            deploymentName = (String.isBlank(deploymentName) && deploymentJobs.size()>0)?deploymentJobs[0].Step__r.Deployment__r.Name:'';
        }
        return deploymentJobs;
    }
    private static List<Attachment> getAttachment(String parentId, String name){
        List<Attachment> attachmentList = new List<Attachment>();
        if(Schema.SObjectType.Build_Task__c.isQueryable() && Schema.SObjectType.Build_Task__c.isAccessible()){
            attachmentList = [SELECT Id, ParentId, Body, BodyLength, Name, IsDeleted FROM Attachment WHERE ParentId=:parentId AND Name=:name AND IsDeleted=false];
        }
        return attachmentList;
    }
}