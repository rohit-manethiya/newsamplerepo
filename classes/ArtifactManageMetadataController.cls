public with sharing class ArtifactManageMetadataController {
    private Artifact__c artifact {get;set;}
    public Boolean hasOrg {get;set;}
    public String metadata_url_art {get;set;}
    public Settings settingsClass{get;set;}
    public Boolean showError {get;set;}
    public Boolean showOptions {get;set;}
    public List<Id> relatedArtifactIds{get;set;}
    public Boolean copadoJobFinished {get;set;}
    public String slockerMessage {get; set;}
    private String cJobId = '';
    private Boolean gitExistAndValid = false;
    public Boolean jobisExecuting  {get;set;}
    public Boolean hasOLS {get;set;}

    public ArtifactManageMetadataController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>{ 'Org_Credential__c', 'Artifact_Repository__c', 'RecordTypeId', 'Package_Type__c' });
        }
        hasOLS = hasAccessTo(Artifact__c.SObjectType) && hasAccessTo(Org__c.SObjectType) && hasAccessTo(Git_Repository__c.SObjectType);
        slockerMessage = CopadoNotificationHelper.STATUS_DEFAULT_VALUE;
        settingsClass = new Settings();
        copadoJobFinished = false;
        hasOrg = false;
        showOptions = true;
        showError = false;
        this.artifact = (Artifact__c)stdController.getRecord();
        gitExistAndValid = isGitExistAndValid();
        if(this.artifact.Org_Credential__c != null) {
            hasOrg=true;
            String urlParameters = '';
            String herokuServer = settingsClass.herokuServer;
            String urlBase = herokuServer + '/json/v1/';
            metadata_url_art = urlBase + 'metadata/' + EncodingUtil.urlEncode(artifact.Org_Credential__c,DXLabel.UTF_8) + urlParameters + '?dates=format&parentId=' + EncodingUtil.urlEncode(artifact.Org_Credential__c,DXLabel.UTF_8);
            relatedArtifactIds = new List<Id>();
            if(hasAccessTo(Artifact__c.SObjectType)) {
                for(Artifact__c a : [SELECT Id FROM Artifact__c WHERE Org_Credential__c =: artifact.Org_Credential__c AND Id != : artifact.Id]){
                    relatedArtifactIds.add(a.Id);
                }
            }
            Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(DXLabel.ARTIFACT_GIT_SNAPSHOT,artifact.Id);
            if(cn != null){
                cJobId = cn.Matching_Key__c;
                slockerMessage = cn.status__c;
                jobisExecuting = true;
            }
        } else {
            addPageMessage(ApexPages.Severity.WARNING, Label.Org_Credential_Is_Missing_On_Artifact);
        }
    }

    public PageReference redirectIfUnlocked() {
        PageReference unmanagedPackagePage = null;
        if(SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId() == artifact.RecordTypeId && artifact.Package_Type__c == 'Unmanaged'){
            unmanagedPackagePage = Page.ArtifactPackage;
            unmanagedPackagePage.getParameters().put('Id', artifact.Id);
            unmanagedPackagePage.setRedirect(true);
        }
        return unmanagedPackagePage;
    }

    public PageReference callJob() {
        gitExistAndValid = isGitExistAndValid();
        copadoJobFinished = false;
        cJobId = '';
        return checkJobApex();
    }

    public PageReference checkJobApex() {
        PageReference pr = null;
        try {
            if(!gitExistAndValid) {
                addPageMessage(ApexPages.Severity.WARNING, Label.Git_Repo_is_Not_Set);
                copadoJobFinished = true;
                return null;
            }
            if(cJobId == '' && artifact.Id != null) {
                String s = SfdxAPI.artifactSnapshot(artifact.Id);
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(s,CopadoNotificationHelper.copadoFrontAPIreponse.class);
                if(r.copadoJobId != null && r.copadoJobId != '') {
                    cJobId = r.copadoJobId;
                    slockerMessage = r.ok;
                    Copado_Notification__c newCN = CopadoNotificationHelper.instCopadoNotification(CopadoNotificationHelper.PROGRESS_STATUS_COPADO, artifact.Id,DXLabel.ARTIFACT_GIT_SNAPSHOT,cJobId);
                    try {
                        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, new List<Copado_Notification__c>{ newCN });
                        upsert decision.getRecords();
                        newCN = (Copado_Notification__c)decision.getRecords()[0];
                    } catch(NoAccessException ex) {
                        addPageMessage(ApexPages.Severity.WARNING, ex.getMessage());
                    }
                    copadoJobFinished = false;
                } else if(r.error != null && r.error != '') {
                    copadoJobFinished = true;
                    addPageMessage(ApexPages.Severity.ERROR,r.error);
                }
            } else {
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if(c.isFinished__c) {
                    if(c.isSuccess__c) {
                        copadoJobFinished = true;
                        addPageMessage(ApexPages.Severity.CONFIRM,'Success');
                        cJobId = '';
                    } else {
                        addPageMessage(ApexPages.Severity.ERROR,c.Message__c != null ? c.Message__c : c.status__c != null ? c.status__c : Label.Could_Not_Push_To_Repo);
                        copadoJobFinished = true;
                    }
                } else {
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }

            }
        } catch(Exception e) {
            addPageMessage(ApexPages.Severity.ERROR,e.getMessage());
            copadoJobFinished = true;
        }
        return pr;
    }
    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public String errorLevel {get; set;}
    public String messageName {get; set;}
    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.WARNING;
        }else{
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        addPageMessage(level, messageName);
    }

    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if(!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING,thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
    }

    private Boolean isGitExistAndValid() {
        if(String.isNotBlank(this.artifact.Artifact_Repository__c)) {
            return DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success;
        }
        return false;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}