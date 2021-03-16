public with sharing class DeploymentTaskExtension {

    public Deployment_Task__c task {get; set;}
    public String dataJson {get; set;}
    public String describe_url {get; set;}
    public String sobjects_url {get; set;}
    public String testquery_url {get; set;}
    public String metadata_url {get; set;}
    public String custom_settings_url {get; set;}
    public Settings settings {get; set;}
    public User_Story__c  ustry {get; set;}
    public Id orgId {get; set;}
    public Id currentId;
    public String DEFAULT_SERVER_URL = 'https://app-api.copado.com';
    private final ApexPages.StandardController std;
    /**
     * Constructor method for Deployment task page.
     * @param  stdController
     * @see  Settings__c
     * @see  Utilities
     * @return
     */
    public DeploymentTaskExtension(ApexPages.StandardController stdController) {
        this.std = stdController;
        Id recordID = (Id)stdController.getId();
        settings = new Settings();
        /**
         * Adding all fields to the standard controller scope to avoid field exceptions
         */
        if(!Test.isRunningTest()){
            stdController.addFields(
                Utilities.getAllFields('Deployment_Task__c').get(Label.FIELDS).split(',')
            );
        }
        this.task = (Deployment_Task__c)stdController.getRecord();
        if (this.task.Type__c == null) {
            dataJson = '{"Perform_in_Source_Org":' + this.task.Perform_in_Source_Org__c;
            dataJson += ',"Perform_in_Destination_Orgs":' + this.task.Perform_in_Destination_Orgs__c;
            dataJson +=  ',"Task_Description":"';
            if (this.task.Task_Description__c != null) {
                dataJson += this.task.Task_Description__c.escapeJava();
            }
            dataJson += '"}';
            this.task.Type__c = 'Manual Task';
        }
        else {
            dataJson = task.dataJson__c;
        }
        populateUserStoryRelation();
    }
    
    public PageReference deleteAction(){
        Utilities.Secure_DML(task, Utilities.DML_Action.DEL, schema.SObjectType.Deployment_Task__c);
        String newPageUrl = '/' + task.User_Story__c;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }

    public PageReference saveAction() {
        Deployment_Task__c taskToSave = (Deployment_Task__c)std.getRecord();
        currentId = taskToSave.Id;
        if(null != currentId && !Utilities.HasEditAccess(currentId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, Label.InSuffPriv));
            return null;
        }
        String data = ApexPages.currentPage().getParameters().get('detail');
        System.debug(loggingLevel.Error, '*** data: ' + data);
        System.debug(loggingLevel.Error, '*** taskToSave: ' + taskToSave);
        System.debug(loggingLevel.Error, '*** taskToSave.Type__c: ' + taskToSave.Type__c);
        if (String.isBlank(taskToSave.Name) || String.isBlank(taskToSave.Type__c) || taskToSave.User_Story__c == null || String.isBlank(taskToSave.Perform_Manual_Task__c)  ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.FILL_REQUIRED_FIELDS));
            return null;
        }
        if (data != null && taskToSave.Type__c != NULL && taskToSave.Type__c != 'Delete MetaData' && taskToSave.Type__c != 'Apex') {
            taskToSave.dataJson__c = data;
        } else {
            taskToSave.dataJson__c = null;
        }
        if(ApexPages.currentPage().getParameters().get('clone') != null && Integer.valueOf(ApexPages.currentPage().getParameters().get('clone')) == 1){
            taskToSave.id = null;
        }
        Utilities.Secure_DML(taskToSave, Utilities.DML_Action.UPS, schema.Sobjecttype.Deployment_Task__c);
        if (data != null && taskToSave.Type__c != null && (taskToSave.Type__c == 'Apex' || taskToSave.Type__c == 'Delete MetaData' || taskToSave.Type__c == 'Custom Settings')) {
            List<Attachment> attList = new List<Attachment>([SELECT Id FROM Attachment WHERE ParentId = :taskToSave.Id AND (Name = 'Apex' OR Name = 'Delete MetaData' OR Name = 'Custom Settings')]);
            if (!attList.isEmpty()) {
                Utilities.Secure_DML(attList, Utilities.DML_Action.DEL, schema.Sobjecttype.Attachment);
            }
            Attachment att = new Attachment();
            att.Name = taskToSave.Type__c;
            att.Body = Blob.valueOf(data);
            att.ParentId = taskToSave.Id;
            Utilities.Secure_DML(att, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
        }
        String newPageUrl = '/' + taskToSave.id;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }

    public PageReference populateUserStoryRelation() {
        try {
            Deployment_Task__c currentVersion = (Deployment_Task__c)std.getRecord();
            String ustryName = ApexPages.currentPage().getParameters().get('ustryName');
            Settings__c s = Settings__c.getOrgDefaults(); // Copado settings (custom setting)
            String server_url = String.isNotBlank(s.Server_URL__c) ? s.Server_URL__c : DEFAULT_SERVER_URL; // Copado server url to shape callout urls
            System.debug('ustryName >>> ' + ustryName);
            System.debug('currentVersion.User_Story__c >>> ' + currentVersion.User_Story__c);
            /**
             * Query the record itself to get org credentials from related user story.
             * Org credentials Id is in use to generate below end point urls
             */
            ustry = [SELECT Id, Org_Credential__c FROM User_Story__c WHERE Id = : currentVersion.User_Story__c OR Name = :ustryName LIMIT 1];
            
            System.debug('ustry ***' + ustry);
            if (ustry != NULL && ustry.Org_Credential__c != NULL) {
                String urlParameters = '?nosid=1';
                String herokuServer = server_url;
                String urlBase = herokuServer + '/json/v1/';
                orgId = ustry.Org_Credential__c;
                sobjects_url = urlBase + 'listSObjects/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + urlParameters; // to retrieve sobjects by using copado API
                testquery_url = urlBase + 'test-query/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + urlParameters; // to test defined query at data step
                describe_url = urlBase + 'describe/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + '/{sobject}' + urlParameters; // to get sObject description
                custom_settings_url =  urlBase + 'customSetting/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + '/{sobject}' + urlParameters; // to get custom settings
                metadata_url = urlBase + 'metadata/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + urlParameters + EncodingUtil.urlEncode('&dates=format', 'UTF-8'); //to get metadata
            }
            return null;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
    }
    @RemoteAction
    public static User_Story__c getUserStory(String userStoryName){
        try {
            return [SELECT Id, Org_Credential__c FROM User_Story__c WHERE Name = :userStoryName LIMIT 1];
        } catch(Exception e) {
            System.debug(e.getMessage());
            return null;
        }
    }
}