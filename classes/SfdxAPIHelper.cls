/**
 * @description The Sfdx API helper. Generic operation handlers are given in this class for SFDX operations
 * @author Mert YALTI
 * @author Ferhat Ozsavran
 * @author Umit Can Uckan
 */
public with sharing abstract class SfdxAPIHelper {
    // Set of consts that represents attachment names
    //public static final String DX_PROJECT_BRANCH = 'project/DX-'; //+scratchOrgId (15 chars)
    //public static final String DX_DEFINITION_FILE = 'project-scratch-def.json';
    //public static final String DX_PROJECT_FILE = 'sfdx-project.json';
    //public static final String DX_DEFAULT_PATH = 'force-app';
    //public static final String DX_METADATA_SOURCES = 'metadataSources.json';
    public static final String DX_SCRATCH_ORG_DISPLAY = 'ScratchOrgDisplay.json';
    //public static final String DX_PACKAGE_DETAILS = 'packageDetail.json';
    //public static final String DX_CONVERT_IGNORE = 'convertForceIgnore';
    //public static final String DX_PUSH_IGNORE = 'pushForceIgnore';
    //public static final String DX_PACKAGE_INSTALLATION = 'packageInstallationDetails';
    public static String flowMessage;
    static String SOQL_STRING = 'SELECT {0} FROM {1} WHERE {2}';
    // Supported Http call methods
    static Set<String> callMethods = new Set<String>{
            'DELETE',
            'GET',
            'HEAD',
            'POST',
            'PUT',
            'TRACE'
    };
    /**
     * The default keyword is reserved so that we cannot use it as a variable name
     * Therefore we use defaultArtifact and replace it with default before calling the backend out
     * @param jsonBody raw org definition json
     * @return org definition json with replaced reserved names
     */
    public static String orgDefinitionDefaultKeyFixer(String jsonBody) {
        return jsonBody.replaceAll(',"defaultArtifact":false', '').replace('"defaultArtifact":true', '"default":true');
    }
    /**
     * ScratchOrgDefinition is a wrapper we use the store org definition values
     * With this method we generate a proper JSON to be used in callouts
     * Note: Reserved keywords are not removed since this maybe used for another operation than callout
     * @param orgTemplate
     * @return org definition json
     */
    public static String prepareOrgDefinition(ScratchOrgDefinition orgTemplate, String jsonSettingFeature) {
        if(!String.isBlank(orgTemplate.edition)) {
            Map<String, Object> orgTemplateMap = new Map<String, Object>();
            if(String.isNotBlank(jsonSettingFeature)) {
                orgTemplateMap.putAll((Map<String, Object>)JSON.deserializeUntyped(jsonSettingFeature));
            }
            orgTemplateMap.putAll((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(orgTemplate)));
            return JSON.serializePretty(orgTemplateMap);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DX_Edition_is_required));
            return null;
        }
    }
    public static String prepareDataforJsonEditor(ScratchOrgDefinition orgTemplate, String jsonDefinition) {
        Map<String, Object> templateMap = new Map<String, Object>((Map<String, Object>)JSON.deserializeUntyped(jsonDefinition));
        for(String generalProperty : orgTemplate.generalSettingsList()) {
            templateMap.remove(generalProperty);
        }
        return JSON.serialize(templateMap);
    }
    /**
     * Generates SFDX default org definition
     * @return org definition json
     */
    public static String prepareDefaultOrgDefinitionJSON() {
        SfdxAPIHelper.ScratchOrgDefinition defaultOrgDef = new scratchOrgDefinition(null, 'US', null, UserInfo.getUserEmail(), 'Developer', null, false, 'en_US');
        return JSON.serialize(defaultOrgDef, true);
    }
    /**
     * Queries the complete list of dev hub orgs
     * @return List devhub org credentials
     */
    /*public static List<Org__c> listDevHubOrgs() {
        SecureOperations so = new SecureOperations();
        if(so.isAuthorizedToQuery(Org__c.SObjectType)) {
            return [SELECT Id,Name FROM Org__c WHERE is_Developer_Hub_Org__c = TRUE LIMIT 999];
        }
        throw new CopadoDxException(Schema.SObjectType.Org__c.label + ': ' + Label.Insufficient_Access_Rights);
    }*/
    /**
     * Generates list of select options for available dev hub org credentials
     * @return List<SelectOption> for org credentials
     */
    /*public static List<SelectOption> listDevHubOrgOptions() {
        List<SelectOption> devHubs = new List<SelectOption>();
        devHubs.add(new SelectOption('-- None --', '-- None --'));
        for(Org__c dhubs : SfdxAPIHelper.listDevHubOrgs()) {
            devHubs.add(new SelectOption(dhubs.Id, dhubs.Name));
        }
        return devHubs;
    }*/
    /**
     * Calls backend with given Http callout setup
     * @param callMethod Http method
     * @param callURL Http endpoint
     * @param callBody Http payload body
     * @param bodyRequired Boolen param that decides to add body or not
     * @param runningJobName the Copado job name to be created in order to track the status of the job
     * @see CopadoNotificationHelper
     * @see JobsManager
     * @return string result
     */
    public static String callDxJob(String callMethod, String callURL, String callBody, Boolean bodyRequired, String runningJobName) {
        HttpResponse res = SfdxAPIHelper.callDxJob(callMethod, callURL, callBody, bodyRequired);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.copadoJobId, runningJobName, null, 'Starting...');
        }
        return body;
    }
    /**
     * Calls backend with given Http callout setup
     * @param callMethod Http method
     * @param callURL Http endpoint
     * @param callBody Http payload bodyt
     * @param bodyRequired Boolen param that decides to add body or not
     * @return HttpResponse of the callout
     */
    public static HttpResponse callDxJob(String callMethod, String callURL, String callBody, Boolean bodyRequired) {
        if(!callMethods.contains(callMethod)) {
            throw new CopadoDxException(Label.Unknown_HTTP_Request_method);
        }
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        DeployAPI.setAuthHeaders(req);
        if(bodyRequired && String.isEmpty(callBody)) {
            return null;
        } else if(!String.isEmpty(callBody)) {
            req.setBody(callBody);
        }
        req.setHeader('Accept', 'application/json');
        req.setHeader('content-type', 'application/json');
        req.setEndpoint(callURL);
        req.setMethod(callMethod);
        if (callMethod == 'POST' && req.getBodyAsBlob() == null) {
            req.setHeader('content-length', '0');
        }
        Http h = new Http();
        HttpResponse res = h.send(req);
        return res;
    }
    /**
     * Returns the list of org credentials corresponds to given where clause
     * @param whereClause filtering options for org credential query
     * @return List<Org__c>
     */
    public static List<Org__c> getOrgCredentials(String whereClause) {
        String orgFields = Utilities.getAllFields('Org__c').get(Label.FIELDS);
        String soql = String.format(SOQL_STRING, new String[]{
                orgFields, 'Org__c', whereClause
        });
        Boolean isOrgAccessible = Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible();
        return isOrgAccessible ? (List<Org__c>) Database.query(soql) : new List<Org__c>();
    }
    public static List<Artifact__c> getArtifacts(String whereClause) {
        String orgFields = Utilities.getAllFields('Artifact__c').get(Label.FIELDS);
        String soql = String.format(SOQL_STRING, new String[]{
                orgFields, 'Artifact__c', whereClause
        });
        Boolean isArtifactAccessible = Schema.SObjectType.Artifact__c.isQueryable() && Schema.SObjectType.Artifact__c.isAccessible();
        return isArtifactAccessible ? (List<Artifact__c>) Database.query(soql) : new List<Artifact__c>();
    }
    //Given a Scratch org Id, get the org Id of the artifacts or Org where de metadata was selected
    public static String getSOartifactParentId(String scratchOrgId) {
        String orgCredentialId = '';
        if(String.isNotBlank(scratchOrgId)) {
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                List<Attachment> metadatSourcesAttachment = [SELECT Body FROM Attachment WHERE ParentId = :scratchOrgId AND Name = :DXLabel.METADATA_SOURCES ORDER BY CreatedDate DESC LIMIT 1];
                if(!metadatSourcesAttachment.isEmpty()) {
                    Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(metadatSourcesAttachment.get(0).Body.toString());
                    String mSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? String.valueOf(deserializedJsonMap.get('metadataSourceType')) : '';
                    String mSource = deserializedJsonMap.containsKey('metadataSource') ? String.valueOf(deserializedJsonMap.get('metadataSource')) : '';
                    if(String.isNotBlank(mSource) && String.isNotBlank(mSource) && mSourceType == 'org') {
                        orgCredentialId = mSource;
                    } else if(String.isNotBlank(mSource) && String.isNotBlank(mSourceType) && (mSourceType == 'artifact'  || mSourceType== 'unlocked')) {
                        String firstArtifactId = mSource.split(',')[0];
                        List<Artifact__c> parentOrg = new List<Artifact__c>();
                        if(Schema.SObjectType.Artifact__c.isQueryable() && Schema.SObjectType.Artifact__c.isAccessible()) {
                            parentOrg = [SELECT Org_Credential__c FROM Artifact__c WHERE Id = :firstArtifactId];
                            if(!parentOrg.isEmpty() && parentOrg[0].Org_Credential__c != null) {
                                orgCredentialId = parentOrg[0].Org_Credential__c;
                            }
                        } else {
                           UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Artifact__c.label);
                        }
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.label);
            }
        }
        return orgCredentialId;
    }
    public static String returnJsonAfterCorrection(String scratchJson) {
        SfdxAPIHelper.ScratchOrgDefinition tempwrapperItem = (SfdxAPIHelper.ScratchOrgDefinition) JSON.deserialize(scratchJson, SfdxAPIHelper.ScratchOrgDefinition.class);
        tempwrapperItem.adminEmail = UserInfo.getUserEmail();
        String jsonSettingsFeatures = prepareDataforJsonEditor(tempwrapperItem, scratchJson);
        String returnCorrectJson = prepareOrgDefinition(tempwrapperItem, jsonSettingsFeatures);
        return returnCorrectJson;
    }
    public class ScratchOrgDefinition {
        public String orgName { get; set; }
        public String country { get; set; }
        public String username { get; set; }
        public String adminEmail { get; set; }
        public String edition { get; set; }
        public String description { get; set; }
        public Boolean hasSampleData { get; set; }
        public String language { get; set; }
        public scratchOrgDefinition(String orgName, String country, String username, String adminEmail, String edition, String description, Boolean hasSampleData, String language) {
            this.orgName = orgName;
            this.country = country;
            this.username = username;
            this.adminEmail = adminEmail;
            this.edition = edition;
            this.description = description;
            this.hasSampleData = hasSampleData;
            this.language = language;
        }
        public Set<String> generalSettingsList() {
            Set<String> generalSettingsValues = new Set<String>();
            Map<String,Object> propertiesMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this));
            return propertiesMap.keySet();
        }
    }
    public static Deployment_Flow__c usDeploymentFlow(String usId) {
        try {
            User_Story__c us = new User_Story__c();
            if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                us = [SELECT Id, Project__c, Project__r.Deployment_Flow__c, Release__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE Id = :usId LIMIT 1];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.label);
            }
            String dfId;
            if(us.Project__r.Deployment_Flow__c != null) {
                dfId = us.Project__r.Deployment_Flow__c;
            } else if(us.Release__r.Project__r.Deployment_Flow__c != null) {
                dfId = us.Release__r.Project__r.Deployment_Flow__c;
            }
            Deployment_Flow__c depFlow = new Deployment_Flow__c();
            if(Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                depFlow = [
                    SELECT Id, Name,Enable_Copado_DX__c,Copado_DX_Mode__c,Block_Commits__c,Active__c,Main_Branch__c, (
                            SELECT Id, Name, Enable_as_Scratch_Org_Destination__c, Destination_Environment__c,
                                    Destination_Environment__r.Name, Source_Environment__c, Source_Environment__r.Name
                            FROM Deployment_Flow_Steps__r
                            WHERE Enable_as_Scratch_Org_Destination__c != NULL
                    )
                    FROM Deployment_Flow__c
                    WHERE Id = :dfId
                    LIMIT 1
            ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow__c.label);
            }
            return depFlow;
        } catch(Exception e) {
            flowMessage = Label.UNEXPECTED_DX_DF_ERROR + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
            return null;
        }
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(Deployment_Flow__c depFlow) {
        if(depFlow == null) {
            flowMessage = Label.DX_NO_US_FLOW;
            return false;
        }
        if(!depFlow.Enable_Copado_DX__c) {
            flowMessage = Label.DX_NOT_ENABLED_DF;
            return false;
        }
        if(depFlow.Deployment_Flow_Steps__r.size() == 0) {
            flowMessage = Label.DF_HAS_NO_DX_TARGET;
            return false;
        }
        return true;
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(String usId) {
        Deployment_Flow__c depFlow = usDeploymentFlow(usId);
        return isDXEnabledForUSDeploymentFlow(depFlow);
    }
    public static String dxModeForUserStory(Deployment_Flow__c depFlow) {
        return depFlow.Copado_DX_Mode__c != null ? depFlow.Copado_DX_Mode__c : '';
    }
    public class Result {
        public String state { get; set; }
        public String fullName { get; set; }
        public String type { get; set; }
        public String filePath { get; set; }
    }
    public class Error {
        public String message { get; set; }
        public Integer status { get; set; }
        public String stack { get; set; }
        public String name { get; set; }
        public String action { get; set; }
    }
    /*public class SfdxProject {
        public List<SfdxProjectArtifacts> packageDirectories { get; set; }
        public String namespace { get; set; }
        public String sfdcLoginUrl { get; set; }
        public String sourceApiVersion { get; set; }
        public Map<String, String> packageAliases { get; set; }
        public sfdxProject(List<SfdxProjectArtifacts> packageDirectories, String namespace, String sfdcLoginUrl, String sourceApiVersion, Map<String, String> packageAliases) {
            this.packageDirectories = packageDirectories;
            this.namespace = namespace;
            this.sfdcLoginUrl = sfdcLoginUrl;
            this.sourceApiVersion = sourceApiVersion;
            this.packageAliases = packageAliases;
        }
        public sfdxProject(List<SfdxProjectArtifacts> packageDirectories, String namespace, String sfdcLoginUrl, String sourceApiVersion) {
            this.packageDirectories = packageDirectories;
            this.namespace = namespace;
            this.sfdcLoginUrl = sfdcLoginUrl;
            this.sourceApiVersion = sourceApiVersion;
            this.packageAliases = new Map<String, String>();
        }
        public void checkIfAliasesAreEmptyAndClearMap() {
            if(this.packageAliases != null && this.packageAliases.isEmpty()) {
                this.packageAliases = null; 
            }
        }
    }*/
    /*public class MetadataSources {
        public String metadataSource { get; set; }
        public String metadataSourceType { get; set; }
        public List<String> selectedArtifactIDs { get; set; }
        public String repositoryId { get; set; }
        public Boolean isPatch { get; set; }
        public metadataSources() {
            this.metadataSource = '';
            this.metadataSourceType = '';
            this.selectedArtifactIDs = new List<String>();
            this.repositoryId = '';
            this.isPatch = false;
        }
        public metadataSources(String metadataSource, String metadataSourceType, List<String> selectedArtifactIDs, String repositoryId) {
            this.metadataSource = metadataSource;
            this.metadataSourceType = metadataSourceType;
            this.selectedArtifactIDs = selectedArtifactIDs;
            this.repositoryId = repositoryId;
            this.isPatch = false;
        }
        public metadataSources(String metadataSource, String metadataSourceType, String repositoryId) {
            this.metadataSource = metadataSource;
            this.metadataSourceType = metadataSourceType;
            this.selectedArtifactIDs = new List<String>();
            this.repositoryId = repositoryId;
            this.isPatch = false;
        }
    }*/
    /*public class SfdxProjectArtifacts {
        public String path { get; set; }
        public String packageName { get; set; }
        public Boolean defaultArtifact { get; set; }
        public String definitionFile { get; set; }
        public String versionName { get; set; }
        public String versionNumber { get; set; }
        public String versionDescription { get; set; }
        public List<PackageDependencies> dependencies { get; set; }
        public sfdxProjectArtifacts(String path, Boolean defaultArtifact) {
            this.path = path;
            this.defaultArtifact = defaultArtifact;
            this.definitionFile = 'config/' + DX_DEFINITION_FILE;
            this.dependencies = new List<SfdxAPIHelper.PackageDependencies>();
        }
        public sfdxProjectArtifacts(String path, String packageName, Boolean defaultArtifact) {
            this.path = path;
            this.defaultArtifact = defaultArtifact;
            this.packageName = packageName;
            this.definitionFile = 'config/' + DX_DEFINITION_FILE;
            this.dependencies = new List<SfdxAPIHelper.PackageDependencies>();
        }
        public void checkIfDependenciesAreEmptyAndClearArray() {
            if(this.dependencies != null && this.dependencies.isEmpty()) {
                this.dependencies = null;
            }
        }
    }*/
    /*public class PackageDependencies {
        public String packageName { get; set; }
        public String versionNumber { get; set; }
    }*/
    /*public class SfdxOrgDisplay {
        public String username { get; set; }
        public String id { get; set; }
        public String connectedStatus { get; set; }
        public String accessToken { get; set; }
        public String instanceURL { get; set; }
        public String clientId { get; set; }
        public String password { get; set; }
        public sfdxOrgDisplay(String username, String id, String connectedStatus, String accessToken, String instanceUrl, String clientId) {
            this.username = username;
            this.id = id;
            this.connectedStatus = connectedStatus;
            this.accessToken = accessToken;
            this.instanceURL = instanceUrl;
            this.clientId = clientId;
        }
        public sfdxOrgDisplay() {
            this.username = '';
            this.id = '';
            this.connectedStatus = '';
            this.accessToken = '';
            this.instanceURL = '';
            this.clientId = '';
            this.password = '';
        }
    }*/
    public class PackageCreateResponse {
        public String status { get; set; }//always populated
        public String message { get; set; }//gets populated when any error occurs
        public String stack { get; set; }//gets populated when any error occurs
        public String name { get; set; }//gets populated when any error occurs
        public PackageCreateResponseResult result { get; set; }
    }
    /*public class PackageStatusTrackingResponse {
        public Integer status { get; set; }
        public List<PackageCreateResponseResult> result { get; set; }
    }*/
    public class PackageCreateResponseResult {
        public String Id { get; set; }
        public String Status { get; set; }
        public String Package2Id { get; set; }
        public String Package2VersionId { get; set; }
        public String SubscriberPackageVersionId { get; set; }
        public String Tag { get; set; }
        public String Branch { get; set; }
        public String CreatedDate { get; set; }
    }
    /*public class PackageInfos {
        public List<PackageDetails> packages { get; set; }
    }
    public class PackageDetails {
        public String packageId { get; set; }
        public String installationKey { get; set; }
        public String packageName { get; set; }
        public String packageVersion { get; set; }
    }*/
    public class CopadoDxException extends Exception {
    }
}