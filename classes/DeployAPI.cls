public with sharing class DeployAPI {
    public static String FW_SLASH = '/';
    public static String CurrentUserId {
        get {
            return UserInfo.getUserId();
        }
        set;
    }

    public static String copadoURL = Settings.server_url;
    public class ApplicationException extends Exception {
    }
    public static Map<String, Object> orgMap;

    @Future(Callout=true)
    public static void deploy(List<Id> ids, String sid) {
        for (Id depId : ids) {
            deployNow(depId, sid);
        }
    }
    //@Future(callout=true)
    public static void deploy(Id depId, String sid) {
        deployNow(depId, sid);
    }

    public static void cancelDeployment(Id depId) {
        List<Deployment_Job__c> djs = new List<Deployment_Job__c>();
        if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            djs = [SELECT Id FROM Deployment_Job__c WHERE Step__r.Deployment__c = :depId AND Status__c IN ('Pending', 'Not started')];
        }
        for (Deployment_Job__c d : djs) {
            d.Status__c = 'Cancelled';
        }
        if (!djs.isEmpty()) {
            Utilities.Secure_DML(djs, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
        }
    }

    public static void deployNow(Id depId, String sid) {
        String copadoOrgId = UserInfo.getOrganizationId();
        if (!Schema.SObjectType.Deployment__c.isQueryable() && !Schema.SObjectType.Deployment__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForDeployment));
            return;
        }
        String copadoUserId = [SELECT OwnerId FROM Deployment__c WHERE Id = :depId].OwnerId;
        String url = copadoURL + '/json/v1/deployNow/' + depId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        if (res.getStatusCode() == 200) {
            renameDeploymentAttachments(depId);
        }
    }

    /**
     * This method renames old attachment names with OLD prefix
     * @param deploymentId
     */
    public static void renameDeploymentAttachments(String deploymentId) {
        if (!Schema.SObjectType.Deployment_Job__c.isQueryable() && !Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            return;
        }
        if (!Schema.SObjectType.Attachment.isQueryable() && !Schema.SObjectType.Attachment.isAccessible()) {
            return;
        }

        List<Attachment> atts = new List<Attachment>();
        //list only results json files from jobs to be re-deployed. so result are not lost for previously deployed jobs
        List<String> pendingJobs = new List<String>();
        //reset status of deployment jobs
        Set<Id> djIds = new Set<Id>();
        Boolean isDataTemplateDeployment = false;

        for (Deployment_Job__c dj : [SELECT Id, Status__c, Step__r.Type__c FROM Deployment_Job__c WHERE Step__r.Deployment__c = :deploymentId]) {
            djIds.add(dj.Id);
            if (dj.Status__c == 'Pending') {
                pendingJobs.add(dj.Id + '.json');
            }
            if (dj.Step__r.Type__c == 'Data Template') {
                isDataTemplateDeployment = true;
            }
        }

        for (Attachment at : [SELECT Id, Name FROM Attachment WHERE ParentId = :deploymentId AND (NOT Name LIKE 'OLD_%')]) {
            Boolean isErrorAttachment = pendingJobs.contains(at.Name) || at.Name.contains('ERROR');
            Boolean isStatusCopadoAttachment = djIds.contains(at.Id) && at.Name.contains('_STATUS_COPADO');

            if (isErrorAttachment || isStatusCopadoAttachment || isDataTemplateDeployment) {
                at.Name = 'OLD_' + at.Name;
                atts.add(at);
            }
        }

        if (!atts.isEmpty()) {
            Utilities.Secure_DML(atts, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
        }
    }

    public static void backupNow(Id backupId) {
        DeployAPI.backupNow(backupId, '', false, false);
    }

    public static void backupNow(Id backupId, String comment, Boolean applyEnvVars, Boolean applyYAML) {
        if (!Schema.SObjectType.Git_Backup__c.isQueryable() && !Schema.SObjectType.Git_Backup__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForGitBackup));
            return;
        }
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForOrg));
            return;
        }
        Git_Backup__c bk = [SELECT Org__c, Metadata_Types__c FROM Git_Backup__c WHERE Id = :backupId];
        String copadoOrgId = UserInfo.getOrganizationId();

        String copadoUserId = [SELECT OwnerId FROM Org__c WHERE Id = :bk.Org__c].OwnerId;
        String orgId = bk.Org__c;
        String url =
            copadoURL +
            '/json/v1/backupNow/' +
            backupId +
            '?message=' +
            EncodingUtil.urlEncode(comment, 'UTF-8') +
            '&copadoOrgId=' +
            copadoOrgId +
            '&copadoUserId=' +
            copadoUserId +
            '&orgId=' +
            orgId +
            '&applyEnvVars=' +
            applyEnvVars +
            '&applyYAML=' +
            applyYAML;
        if (bk.Metadata_Types__c != null && bk.Metadata_Types__c != '') {
            url += '&filter=' + EncodingUtil.urlEncode(bk.Metadata_Types__c, 'UTF-8');
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    public static void executeCI(Id ciId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String url = copadoURL + '/json/v1/buildTaskExec/' + ciId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody('{"commits":[]}');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    @Future(callout=true)
    public static void deployBuildTask(Set<Id> btIds, String sessionId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();

        for (Id btId : btIds) {
            String url = copadoURL + '/json/v1/deployBuildTask/' + btId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(btIds));
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
        }
    }

    public static void getCommits(Id backupId) {
        String url = copadoURL + '/json/v1/gitCommits/' + backupId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    public static void testNow(Id orgId) {
        String copadoOrgId = UserInfo.getOrganizationId();
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForOrg));
            return;
        }
        String copadoUserId = [SELECT OwnerId FROM Org__c WHERE Id = :orgId].OwnerId;
        String url = copadoURL + '/json/v1/testNow/' + orgId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    //seems like is not used
    public static Map<String, Object> estimateDeploy(Id depId, String sid) {
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String url = copadoURL + '/json/v1/estimateDeploy/' + depId + '?copadoOrgId=' + copadoOrgId + '&copadoUserId=' + copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        String r = res.getBody();
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        return m;
    }

    public static Integer getCredits() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(copadoURL + '/?nosid=1');
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        orgMap = (Map<String, Object>) fullMap.get('customerOrg');
        return (Integer) orgMap.get('credits');
    }
    //seems like is not used
    @Future(Callout=true)
    public static void saveDeploy(Id deployId, String sid) {
        String url = copadoURL + '/json/v1/saveDeploy/' + deployId + '?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    @Future(Callout=true)
    public static void cleanDeploy(Id deployId) {
        if (!Schema.SObjectType.Deployment__c.isQueryable() && !Schema.SObjectType.Deployment__c.isAccessible()) {
            return; // TODO: add message if possible
        }
        String url = copadoURL + '/json/v1/cleanDeploy/' + EncodingUtil.urlEncode(deployId, 'UTF-8');
        String status = [SELECT Status__c FROM Deployment__c WHERE Id = :deployId].Status__c;
        url += '?status=' + EncodingUtil.urlEncode(status, 'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    @Future(Callout=true)
    public static void deployJob(List<Id> ids, String sid) {
        if (!Schema.SObjectType.Deployment_Job__c.isQueryable() && !Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            return;
        }
        Map<Id, Deployment_Job__c> mp = new Map<Id, Deployment_Job__c>([SELECT Id, Step__r.Deployment__c FROM Deployment_Job__c WHERE Id IN :ids]);
        for (Id jobId : ids) {
            String url = copadoURL + '/json/v1/deployJob/' + jobId + '?deployId=' + mp.get(jobId).Step__r.Deployment__c;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
        }
    }

    @Future(Callout=true)
    public static void validateOrgAsync(Id orgId) {
        if (isOrgValidationDisabled(orgId)) {
            return;
        }

        String url = copadoURL + '/json/v1/validateOrg/' + orgId + '?setProfile=true';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        try {
            HerokuResponse hr = new HerokuResponse(res);
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('organizationId==> ' + mapa.get('organizationId'));
        } catch (Exception e) {
            System.debug('Exception==> ' + e.getMessage());
        }
    }

    public static Boolean validateOrg(Id orgId) {
        if (isOrgValidationDisabled(orgId)) {
            return true;
        }

        String url = copadoURL + '/json/v1/validateOrg/' + orgId + '?setProfile=true';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        try {
            HerokuResponse hr = new HerokuResponse(res);
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return mapa.get('organizationId') != null;
        } catch (Exception e) {
            return false;
        }
    }

    public static Boolean isOrgValidationDisabled(Id orgId) {
        Boolean isValidationDisabled = false;
        try {
            for (Org__c org : [SELECT Disable_Validation__c FROM Org__c WHERE Id = :orgId WITH SECURITY_ENFORCED]) {
                isValidationDisabled = org.Disable_Validation__c;
            }
        } catch (Exception ex) {
            // We show a WARNING since the user can still perform other operations on a record (for instance, a deployment).
            // This method is not supposed to block the user, it's purely informative.
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        Label.Insufficient_Access +
                        ' ' +
                        Org__c.SObjectType.getDescribe().getLabel() +
                        ': ' +
                        orgId
                    )
                );
            }
            isValidationDisabled = true;
        }
        return isValidationDisabled;
    }

    public class validateGitResult {
        public Boolean success { get; set; }
        public String message { get; set; }
    }

    public static validateGitResult validateGit(Id gitId) {
        String url = copadoURL + '/json/v1/validateGit/?nosid=1';
        Git_Repository__c git = new Git_Repository__c();
        if (Schema.SObjectType.Git_Repository__c.isQueryable() && Schema.SObjectType.Git_Repository__c.isAccessible()) {
            git = [SELECT Id, URI__c FROM Git_Repository__c WHERE Id = :EncodingUtil.urlEncode(gitId, 'UTF-8')];

            if (String.isBlank(git.URI__c)) {
                validateGitResult resultEmpty = new validateGitResult();
                resultEmpty.success = false;
                resultEmpty.message = Label.URI_cannot_be_empty;
                return resultEmpty;
            }

            url += '&uri=' + EncodingUtil.urlEncode(git.URI__c, 'UTF-8');
            url += '&repoId=' + EncodingUtil.urlEncode(git.Id, 'UTF-8');
        } else {
            validateGitResult resultEmpty = new validateGitResult();
            resultEmpty.success = false;
            resultEmpty.message = Label.DeployAPI_no_privileges_git_repo;
            return resultEmpty;
        }

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(gitId);
        if (null != gitRepositoryConfiguration) {
            if (String.isNotBlank(gitRepositoryConfiguration.Username__c)) {
                req.setHeader('un', gitRepositoryConfiguration.Username__c);
            }
            if (String.isNotBlank(gitRepositoryConfiguration.Password__c)) {
                req.setHeader('pw', gitRepositoryConfiguration.Password__c);
            }
        }
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        validateGitResult result = new validateGitResult();
        try {
            HerokuResponse hr = new HerokuResponse(res);
            result.success = true;
            result.message = Label.OK_CREDENTIALS;
        } catch (Exception e) {
            result.success = false;
            result.message = Label.WRONG_CREDENTIALS + ': ' + e.getMessage();
        }
        return result;
    }

    public static Org__c getCustomerOrg() {
        return getCustomerOrg(UserInfo.getUserId());
    }

    public static Org__c getCustomerOrg(String uid) {
        String oid = UserInfo.getOrganizationId();
        uid = uid == null ? UserInfo.getUserId() : uid;
        String key = oid + '_' + uid;
        List<Org__c> ls = new List<Org__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            ls = [SELECT Id FROM Org__c WHERE SFDC_Org_ID__c = :oid OR SFDC_Org_ID__c = :key];
        }
        Org__c copadoOrg = ls.size() > 0 ? ls.get(0) : null;
        return copadoOrg;
    }

    class ServerException extends Exception {
    }

    public class HerokuResponse {
        public Boolean success { get; set; }
        public String message { get; set; }
        public HerokuResponse(HttpResponse res) {
            System.debug('herokuresponse: ' + res);
            if (res.getStatusCode() != null) {
                Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                success = fullMap.get('error') == null;
                if (success) {
                    message = (String) fullMap.get('ok');
                } else {
                    message = (String) fullMap.get('error');
                }
            }
            if (!success) {
                throw new ServerException(message);
            }
        }
    }

    public static String getAuthToken(Id userId) {
        String sid = '<sessionId might change>'; //UserInfo.getSessionId()!=null?UserInfo.getSessionId():'';
        String cdate = Datetime.now().formatGmt('yyyy-MM-dd');
        String myData = 'Copado Deployer by Copado Ltd' + userId + UserInfo.getOrganizationId() + sid + cdate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(myData));
        return EncodingUtil.convertToHex(hash);
    }

    public static void setAuthHeaders(HttpRequest req, Id userId) {
        req.setHeader('userId', userId);
        req.setHeader('orgId', UserInfo.getOrganizationId());
        //req.setHeader('sessionId', UserInfo.getSessionId()!=null?UserInfo.getSessionId():'');
        req.setHeader('token', getAuthToken(userId));
        req.setTimeout(120000);
    }

    public static String getAuthToken() {
        String sid = '<sessionId might change>'; //UserInfo.getSessionId()!=null?UserInfo.getSessionId():'';
        String cdate = Datetime.now().formatGmt('yyyy-MM-dd');
        String myData = 'Copado Deployer by Copado Ltd' + currentUserId + UserInfo.getOrganizationId() + sid + cdate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(myData));
        return EncodingUtil.convertToHex(hash);
    }

    public static void setAuthHeaders(HttpRequest req) {
        req.setHeader('userId', currentUserId);
        req.setHeader('orgId', UserInfo.getOrganizationId());
        //req.setHeader('sessionId', UserInfo.getSessionId()!=null?UserInfo.getSessionId():'');
        req.setHeader('token', getAuthToken());
        req.setTimeout(120000);
    }

    public static List<String> metadataTypes(Id orgId, String sid) {
        String url = copadoURL + '/json/v1/metadataTypes/' + orgId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        String r = res.getBody();
        List<String> mt = (List<String>) JSON.deserialize(r, List<String>.class);
        mt.sort();
        return mt;
    }

    /**
     * Callout to refresh Features in customer orgs.
     */
    public static HerokuResponse refreshOrgFeatures(String installationParams) {
        String url = copadoURL + '/json/v1/checkProvisioning';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(installationParams);
        HttpResponse res = h.send(req);

        return new HerokuResponse(res);
    }

    /*
    retrieve the available features for this installation. features are in heroku database which are
    synchronized from main Copado salesforce APO org.
    */
    public static void checkSyncFeatures() {
        //if features has been updated today skip update
        List<Feature__c> existing = Feature__c.getAll().values();
        syncFeaturesNow();
    }

    public static void checkSyncLicenses() {
        syncLicensesNow();
    }

    public static void syncFeaturesNow() {
        //US-0001524 features are now handled by FMA/LMO standard features. No need to callout the backend.
        List<Feature__c> featureList = new List<Feature__c>();
        //LMO controlled features
        Integer eeLicensesInteger = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        Integer cadLicensesInteger = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
        Integer ccmLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        Integer cstLicensesInteger = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
        Integer cchLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
        Boolean multiLicense =
            eeLicensesInteger > 0 && (cadLicensesInteger > 0 || ccmLicensesInteger > 0 || cstLicensesInteger > 0 || cchLicensesInteger > 0);

        //CBM
        Feature__c cbmFeature = Feature__c.getInstance('Branch Management');
        if (cbmFeature == null) {
            cbmFeature = new Feature__c(Name = 'Branch Management');
        }
        cbmFeature.Enabled__c = FeatureManagement.checkPackageIntegerValue('CBM_Branches') > 0;
        cbmFeature.Expiration_Date__c = null;
        cbmFeature.Quantity__c = FeatureManagement.checkPackageIntegerValue('CBM_Branches');
        featureList.add(cbmFeature);
        //CCM
        Feature__c ccmFeature = Feature__c.getInstance('Change Management');
        if (ccmFeature == null) {
            ccmFeature = new Feature__c(Name = 'Change Management');
        }
        ccmFeature.Enabled__c = !multiLicense || ccmLicensesInteger > 0 || cadLicensesInteger > 0;
        ccmFeature.Expiration_Date__c = null;
        ccmFeature.Quantity__c = null;
        featureList.add(ccmFeature);
        //CST
        Feature__c cstFeature = Feature__c.getInstance('Selenium Testing');
        if (cstFeature == null) {
            cstFeature = new Feature__c(Name = 'Selenium Testing');
        }
        cstFeature.Enabled__c = cstLicensesInteger > 0;
        cstFeature.Expiration_Date__c = null;
        cstFeature.Quantity__c = null;
        featureList.add(cstFeature);
        //CCH
        Feature__c cchFeature = Feature__c.getInstance('Compliance Hub');
        if (cchFeature == null) {
            cchFeature = new Feature__c(Name = 'Compliance Hub');
        }
        cchFeature.Enabled__c = cchLicensesInteger > 0;
        cchFeature.Expiration_Date__c = null;
        cchFeature.Quantity__c = null;
        featureList.add(cchFeature);

        //Default, legacy features always enabled since there is no more Professional Edition.
        List<String> featuresStrings = new List<String>{
            'Apex Test',
            'Continuous Integration',
            'Full Permission Sets step',
            'Full Profiles step',
            'Git Backup',
            'Git MetaData',
            'Org Difference',
            'Snapshot Difference',
            'Full Translations step'
        };
        for (String featureName : featuresStrings) {
            Feature__c cs = Feature__c.getInstance(featureName);
            if (cs == null) {
                cs = new Feature__c(Name = featureName);
            }
            cs.Enabled__c = true;
            //we need to remove the expiration from the Feature list UI.
            cs.Expiration_Date__c = null;
            cs.Quantity__c = null;
            featureList.add(cs);
        }

        Utilities.Secure_DML(featureList, Utilities.DML_Action.UPS, schema.SObjectType.Feature__c);
    }

    public static void syncLicensesNow() {
        LicenseManagerController lmc = new LicenseManagerController();
    }

    public static String createAPIKeys() {
        String url = copadoURL + '/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return res.getBody();
    }

    public static void createAPIKey() {
        String url = copadoURL + '/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        //HerokuResponse hr = new HerokuResponse(res);
        Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String key = (String) mapa.get('api_key');
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        ps.API_Key__c = encryptAPIKey(key);
        Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.SObjectType.Personal_Settings__c);
    }

    private static Blob cryptoKey {
        get {
            if (!String.isEmpty(Settings__c.getOrgDefaults().CryptoKEY__c)) {
                return EncodingUtil.base64Decode(Settings__c.getOrgDefaults().CryptoKEY__c);
            } else {
                String metaKey = [
                    SELECT Id, DeveloperName, Text_Field__c
                    FROM Copado_Protected_Settiing__mdt
                    WHERE DeveloperName = 'Deprecated_Key'
                    LIMIT 1
                ]
                .Text_Field__c;
                return EncodingUtil.base64Decode(metaKey);
            }
        }
        set;
    }

    //takes a plain text api key and encrypt it using AES256. Finally base64 encode to be saved as Text.
    public static String encryptAPIKey(String clearAPIKey) {
        if (String.isBlank(clearAPIKey)) {
            return null;
        }
        Blob data = Blob.valueOf(clearAPIKey);
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.cryptoKey, data));
    }

    //takes a base64 text
    public static String decryptAPIKey(String APIKey) {
        if (String.isBlank(APIKey)) {
            return null;
        }
        Blob encryptedData = EncodingUtil.base64Decode(APIKey);
        return Crypto.decryptWithManagedIV('AES256', DeployAPI.cryptoKey, encryptedData).toString();
    }

    //read encrypted user api key and return it decrypted
    public static String getUserAPIKey() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        return decryptAPIKey(ps.API_Key__c);
    }

    public static String createSSHKey(String parentId) {
        try {
            if (String.isBlank(parentId)) {
                return '{"error":"The parentId variable was not specified.  Please contact Copado Solutions support. Error code: DeployAPI.createSSHkey"}';
            }
            String url = copadoURL + '/json/v1/keygen?parentId=' + parentId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            // fix for GCP issue with POST without body: Force Content-Length: 0
            req.setHeader('Content-Length', '0');
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
            return res.getBody();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }

    public static void getCommitsFromRepo(Id repositoryId, String branch) {
        if (String.isBlank(branch)) {
            branch = 'master';
        }
        String url = copadoURL + '/json/v1/gitCommitsFromRepo/' + repositoryId + '?branch=' + branch;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    /**
     * makes deployment callout with current User Id or commit user Id from Async trigger
     *
     * @param url
     * @param commitUserId
     */
    private static void makeDeploymentCallout(String url, Id commitUserId) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        if (null == commitUserId) {
            setAuthHeaders(req);
        } else {
            setAuthHeaders(req, commitUserId); //to authenticate agains heroku servers
        }
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        HttpResponse res = h.send(req);
        System.debug('res 4 heroku===> ' + res);
        System.debug('res 4 heroku===> ' + res.getBody());
        HerokuResponse hr = new HerokuResponse(res);
    }

    /**
     * checks variables and adds additional parameters to the url if needed
     *
     * @param url
     * @param checkOnly
     * @param pipelineId
     * @param currentPromotion
     * @param repositoryId
     *
     * @return up to date url
     */
    private static String checkAdditionalParameters(
        String url,
        Boolean checkOnly,
        Id pipelineId,
        Promotion__c currentPromotion,
        String repositoryId
    ) {
        if (checkOnly == false && String.isNotBlank(pipelineId)) {
            //check git repo branch here
            if (!Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && !Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.label);
                return null;
            }
            //query with pipeline id and source and destination
            String flowStepQuery = 'SELECT Destination_Branch__c, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :pipelineId';
            String sourceEnvironmentId;
            String destinationEnvironmentId;
            if (currentPromotion.Back_Promotion__c) {
                sourceEnvironmentId = currentPromotion.Destination_Environment__c;
                destinationEnvironmentId = currentPromotion.Source_Environment__c;
            } else {
                sourceEnvironmentId = currentPromotion.Source_Environment__c;
                destinationEnvironmentId = currentPromotion.Destination_Environment__c;
            }
            flowStepQuery +=
                ' AND Source_Environment__c = :sourceEnvironmentId' + ' AND Destination_Environment__c = :destinationEnvironmentId LIMIT 1';
            List<Deployment_Flow_Step__c> pipelineConnection = Database.query(flowStepQuery);
            if (pipelineConnection != null && !pipelineConnection.isEmpty()) {
                url += '&repositoryId=' + repositoryId;
                String destinationBranch = (currentPromotion.Back_Promotion__c
                    ? pipelineConnection[0].Branch__c
                    : pipelineConnection[0].Destination_Branch__c);
                url += '&branch=' + (String.isBlank(destinationBranch) ? '' : destinationBranch);
            }
        }
        return url;
    }

    /**
     * returns current promotion of the Id sent as a parameter
     *
     * @param promotionId
     *
     * @return Promotion record
     */
    private static Promotion__c returnCurrentPromotion(Id promotionId) {
        return [
            SELECT
                Id,
                Destination_Environment__c,
                Source_Environment__c,
                Destination_Environment__r.Name,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__c,
                Back_Promotion__c
            FROM Promotion__c
            WHERE Id = :promotionId AND (Project__r.Deployment_Flow__c != NULL OR Release__r.Project__r.Deployment_Flow__c != NULL)
        ];
    }

    @Future(Callout=true)
    public static void deployPromotionAsync(
        Id promotionId,
        String userStoryName,
        Boolean checkOnly,
        Boolean singleStep,
        String testLevel,
        Boolean isDeployParam,
        String commitUserIdParam
    ) {
        deployPromotion(promotionId, userStoryName, checkOnly, singleStep, testLevel, isDeployParam, commitUserIdParam);
    }
    /**
     * duplicate of old deployPromotion method with two additional parameters. CurrentUserId and isDeploy
     *
     * @param promotionId
     * @param userStoryName
     * @param checkOnly
     * @param singleStep
     * @param testLevel
     * @param isDeploy to decide to start the deployment right away or leave the decision (for CCD logic)to CCD quality Gate step creation
     * @param commitUserId userId to use in the callout for async calls in the async triggers flow
     */
    public static void deployPromotion(
        Id promotionId,
        String userStoryName,
        Boolean checkOnly,
        Boolean singleStep,
        String testLevel,
        Boolean isDeploy,
        Id commitUserId
    ) {
        testLevel = (String.isBlank(testLevel)) ? 'NoTestRun' : testLevel;
        if (!Schema.SObjectType.Promotion__c.isQueryable() && !Schema.SObjectType.Promotion__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForPromotion));
            return;
        }

        Promotion__c currentPromotion = returnCurrentPromotion(promotionId);
        String destEnv = currentPromotion.Destination_Environment__r.Name;
        String repositoryId = currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c == null
            ? currentPromotion.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
            : currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c;
        String pipelineId = String.isNotBlank(currentPromotion.Project__r.Deployment_Flow__c)
            ? currentPromotion.Project__r.Deployment_Flow__c
            : currentPromotion.Release__r.Project__r.Deployment_Flow__c;
        String deploymentName = 'CD: ' + (checkOnly ? 'Validate' : 'Deploy') + ' - ' + userStoryName + ' ➠ ' + destEnv;
        String url =
            copadoURL +
            '/json/v1/promote/' +
            promotionId +
            '?deploy=' +
            isDeploy +
            '&deploymentName=' +
            EncodingUtil.urlEncode(deploymentName, 'UTF-8') +
            '&checkOnly=' +
            checkOnly +
            '&singleStep=' +
            singleStep +
            '&testLevel=' +
            testLevel;

        url = checkAdditionalParameters(url, checkOnly, pipelineId, currentPromotion, repositoryId);
        //if url equals to null then there is a permission issue related to Deployment_Flow_Step__c object
        if (null == url) {
            return;
        }

        makeDeploymentCallout(url, commitUserId);
    }

    @Future(Callout=true)
    public static void deployPromotionAsync(Id promotionId, String userStoryName, Boolean checkOnly, Boolean singleStep, String testLevel) {
        deployPromotion(promotionId, userStoryName, checkOnly, singleStep, testLevel);
    }
    /**
     * legacy deployPromotion method without changes
     *
     * @param promotionId
     * @param userStoryName
     * @param checkOnly
     * @param singleStep
     * @param testLevel
     */
    public static void deployPromotion(Id promotionId, String userStoryName, Boolean checkOnly, Boolean singleStep, String testLevel) {
        testLevel = (String.isBlank(testLevel)) ? 'NoTestRun' : testLevel;
        if (!Schema.SObjectType.Promotion__c.isQueryable() && !Schema.SObjectType.Promotion__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForPromotion));
            return;
        }

        Promotion__c currentPromotion = returnCurrentPromotion(promotionId);
        String destEnv = currentPromotion.Destination_Environment__r.Name;
        String repositoryId = currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c == null
            ? currentPromotion.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
            : currentPromotion.Project__r.Deployment_Flow__r.Git_Repository__c;
        String pipelineId = String.isNotBlank(currentPromotion.Project__r.Deployment_Flow__c)
            ? currentPromotion.Project__r.Deployment_Flow__c
            : currentPromotion.Release__r.Project__r.Deployment_Flow__c;
        String deploymentName = 'CD: ' + (checkOnly ? 'Validate' : 'Deploy') + ' - ' + userStoryName + ' ➠ ' + destEnv;
        String url =
            copadoURL +
            '/json/v1/promote/' +
            promotionId +
            '?deploy=true&deploymentName=' +
            EncodingUtil.urlEncode(deploymentName, 'UTF-8') +
            '&checkOnly=' +
            checkOnly +
            '&singleStep=' +
            singleStep +
            '&testLevel=' +
            testLevel;

        url = checkAdditionalParameters(url, checkOnly, pipelineId, currentPromotion, repositoryId);
        //if url equals to null then there is a permission issue related to Deployment_Flow_Step__c object
        if (null == url) {
            return;
        }

        makeDeploymentCallout(url, null);
    }

    /**
     * Run SCA from Org Credential
     */
    public static void orgCodeAnalysis(Id orgId) {
        List<Org__c> currentOrg = new List<Org__c>();
        List<Deployment_Flow_Step__c> curentPipeline = new List<Deployment_Flow_Step__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            currentOrg = [SELECT Environment__c FROM Org__c WHERE Id = :orgId LIMIT 1];
        }
        if (currentOrg.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }
        if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            curentPipeline = [
                SELECT
                    Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
                FROM Deployment_Flow_Step__c
                WHERE
                    (Source_Environment__c = :currentOrg[0].Environment__c
                    OR Destination_Environment__c = :currentOrg[0].Environment__c)
                    AND Deployment_Flow__r.Static_Code_Analysis_Settings__c != NULL
                LIMIT 1
            ];
        }

        if (curentPipeline.isEmpty()) {
            throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
        }

        checkPmdRules(
            curentPipeline[0].Deployment_Flow__r.Static_Code_Analysis_Settings__c,
            curentPipeline[0].Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
        );

        String url = copadoURL + '/json/v1/code/analysis/static/mode/orgcredential/';
        url += orgId;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }
    /**
     * Launch Static Code Analysis from a User Story
     */
    public static void usCodeAnalysis(Id orgId, Id usId) {
        checkUserStoryMetadata(usId);
        List<User_Story__c> userStories = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStories = [
                SELECT
                    Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName,
                    Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                    Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName,
                    Release__r.Project__r.Deployment_Flow__c,
                    Environment__c,
                    Name
                FROM User_Story__c
                WHERE Id = :usId
                LIMIT 1
            ];
        }
        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        }

        String gitRepoId = getGitRepoId(userStories[0]);
        String scaSettingId = getscaSettingId(userStories[0]);
        String scaSettingRecordTypeDevName = getscaSettingRecordTypeDevName(userStories[0]);
        if (String.isBlank(scaSettingId)) {
            throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
        }
        checkPmdRules(scaSettingId, scaSettingRecordTypeDevName);
        String url = copadoURL + '/json/v1/code/analysis/static/mode/userstory/';
        url += usId;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        // fix for GCP issue with POST without body: Force Content-Length: 0
        req.setHeader('Content-Length', '0');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    /**
     * Returns Repo Id for SCA
     */
    private static String getGitRepoId(User_Story__c userStory) {
        return String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Git_Repository__c)
            ? userStory.Project__r.Deployment_Flow__r.Git_Repository__c
            : userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
    }
    /**
     * Returns SCA setting id
     */
    private static String getscaSettingId(User_Story__c userStory) {
        return userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c != null
            ? userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c
            : userStory.Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c;
    }

    /**
     * Returns record type name of current SCA setting
     */
    private static String getscaSettingRecordTypeDevName(User_Story__c userStory) {
        return String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName)
            ? userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
            : userStory.Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName;
    }

    /**
     * Checks if there are PMD rules in the PMD Setting.
     */
    private static void checkPmdRules(String scaSettingId, String scaSettingRecordTypeDevName) {
        if (!Schema.SObjectType.Static_Code_Analysis_Rule__c.isQueryable() && !Schema.SObjectType.Static_Code_Analysis_Rule__c.isAccessible()) {
            throw new ApplicationException(Label.SCA_RULES_NOT_FOUND);
        }
        List<Static_Code_Analysis_Rule__c> rules = [
            SELECT Id
            FROM Static_Code_Analysis_Rule__c
            WHERE Static_Code_Analysis_Settings__c = :scaSettingId
        ];
        if (rules.isEmpty() && scaSettingRecordTypeDevName != 'CodeScan') {
            throw new ApplicationException(Label.SCA_RULES_NOT_FOUND);
        }
    }

    /**
     * Checks if the user story contains data to send to SCA
     */
    private static void checkUserStoryMetadata(Id usId) {
        Set<String> attachmentNames = new Set<String>{ 'MetaData', 'Delete MetaData', 'Git MetaData' };
        Set<String> metadataTypes = new Set<String>{ 'ApexClass', 'ApexPage', 'ApexComponent', 'ApexTrigger', 'AuraDefinitionBundle' };
        List<String> gitClasses = new List<String>();
        List<String> metaClasses = new List<String>();
        Set<String> gitDeletes = new Set<String>();
        try {
            for (Attachment attachmentItem : [SELECT Id, Name, Body FROM Attachment WHERE Name = :attachmentNames AND ParentId = :usId]) {
                switch on attachmentItem.Name {
                    when 'MetaData' {
                        List<MetaData> metas = (List<MetaData>) JSON.deserialize(attachmentItem.Body.toString(), List<MetaData>.class);
                        for (MetaData m : metas) {
                            if (metadataTypes.contains(m.t)) {
                                metaClasses.add(m.n);
                            }
                        }
                    }
                    when 'Delete MetaData' {
                        String attBody = '{ \"att\": ' + attachmentItem.Body.toString() + '}';
                        GitWrapper gitMetas = (GitWrapper) JSON.deserialize(attBody, GitWrapper.class);
                        for (GitMetaData m : gitMetas.att) {
                            if (metadataTypes.contains(m.t)) {
                                gitDeletes.add(m.n);
                            }
                        }
                    }
                    when 'Git MetaData' {
                        String attBody = '{ \"att\": ' + attachmentItem.Body.toString() + '}';
                        GitWrapper gitMetas = (GitWrapper) JSON.deserialize(attBody, GitWrapper.class);
                        for (GitMetaData m : gitMetas.att) {
                            if (metadataTypes.contains(m.t) && !gitDeletes.contains(m.n)) {
                                gitClasses.add(m.n);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw new ApplicationException(Label.PROBLEM_RETRIEVING_META_ATTACH);
        }
        if (gitClasses.isEmpty() && metaClasses.isEmpty()) {
            throw new ApplicationException(Label.METADATA_NOT_FOUND);
        }
    }

    public class GitWrapper {
        List<GitMetaData> att { get; set; }
    }

    public class MetaData {
        public String n { get; set; }
        public Boolean s { get; set; }
        public String d { get; set; }
        public String b { get; set; }
        public String cd { get; set; }
        public String cb { get; set; }
        public String t { get; set; }
    }

    public class GitMetaData {
        public String t { get; set; }
        public String n { get; set; }
        public String cmm { get; set; }
    }

    public class PayloadWrapper {
        List<String> gitMetadata { get; set; }
        List<String> metadata { get; set; }
    }

    public static void orgComplianceScan(Id orgId) {
        List<Org__c> org = new List<Org__c>();
        List<Environment__c> environment = new List<Environment__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            org = [SELECT Environment__c FROM Org__c WHERE Id = :orgId LIMIT 1];
        }
        if (org.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }
        if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            environment = [SELECT Id, Compliance_Rule_Group__c FROM Environment__c WHERE Id = :org[0].Environment__c LIMIT 1];
        }
        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }
        String url = copadoURL + '/json/v1/scanCompliance';
        url += '?orgId=' + orgId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }
    public static void gitBackupComplianceScan(Id gitBackupId) {
        List<Git_Backup__c> gitBackup = new List<Git_Backup__c>();
        List<Environment__c> environment = new List<Environment__c>();
        if (Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            gitBackup = [SELECT Id, Org__r.Environment__c FROM Git_Backup__c WHERE Id = :gitBackupId LIMIT 1];
        }
        if (gitBackup.isEmpty()) {
            throw new ApplicationException(Label.GIT_BACKUP_NOT_FOUND);
        }
        if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            environment = [SELECT Id, Compliance_Rule_Group__c FROM Environment__c WHERE Id = :gitBackup[0].Org__r.Environment__c LIMIT 1];
        }
        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }

        String url = copadoURL + '/json/v1/scanCompliance';
        url += '?gitBackupId=' + gitBackupId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate agains heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }
    public static void usComplianceScan(Id orgId, Id usId) {
        List<User_Story__c> userStories = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStories = [
                SELECT
                    Name,
                    Environment__r.Compliance_Rule_Group__c,
                    Project__r.Deployment_Flow__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
                FROM User_Story__c
                WHERE Id = :usId
                LIMIT 1
            ];
        }

        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        } else {
            if (userStories[0].Environment__r.Compliance_Rule_Group__c == null) {
                throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
            }
        }

        // Metadata attachments are retrieved in the backend. Verify that the attachments exist.
        List<Attachment> attachments = new List<Attachment>();
        try {
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                attachments = [
                    SELECT Id, Body
                    FROM Attachment
                    WHERE ParentId = :usId AND (Name = 'MetaData' OR Name = 'Delete MetaData' OR Name = 'Git MetaData')
                ];
            }
        } catch (Exception e) {
            throw new ApplicationException(Label.PROBLEM_RETRIEVING_META_ATTACH);
        }

        if (attachments.isEmpty()) {
            throw new ApplicationException(Label.METADATA_NOT_FOUND_COMPLIANCE);
        } else {
            String url = copadoURL + '/json/v1/scanCompliance/';
            url += '?orgId=' + orgId + '&userStoryId=' + usId;
            if (userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId=' + userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            } else if (userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId=' + userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            }
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('GET');

            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
        }
    }

    public static void retrieveVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        calloutForVlocityDependencies(userStoryId, jsonSelectedMetadata);
    }
    private static void calloutForVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        String url = copadoURL + '/json/v1/metadataDependencies?userStoryId=' + userStoryId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(jsonSelectedMetadata);

        HttpResponse res = h.send(req);
        String body = res.getBody();
        HerokuResponse hr = new HerokuResponse(res);

        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(
            body,
            CopadoNotificationHelper.copadoFrontAPIreponse.class
        );
        if (String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.copadoJobId, CopadoNotificationHelper.METADATA_DEPENDENCIES, userStoryId, Label.Starting);
        }
    }
    /**
     * Calls Copado Backend API to know name and type of paths.
     * @param filesList
     * @return Retrievable class
     */
    public static WorkPushService.DxFormatConvertResponse fileToRet(WorkPushService.FileToRetWrapper retWrapper, String sourceFormat) {
        String endpointString = copadoURL.endsWith(FW_SLASH) ? copadoURL : copadoURL + FW_SLASH;
        String body;
        if (sourceFormat == 'DX') {
            endpointString += 'json/v1/dx/metadata/filenames2retrievables';
            body = JSON.serialize(retWrapper);
        } else {
            endpointString += 'json/v1/metadata/filenames2retrievables';
            body = JSON.serialize(retWrapper.fileList);
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req); //to authenticate against heroku servers
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endpointString);
        req.setMethod('POST');
        req.setBody(body);
        HttpResponse res = h.send(req);

        WorkPushService.DxFormatConvertResponse retrievableList = (WorkPushService.DxFormatConvertResponse) JSON.deserialize(
            res.getBody(),
            WorkPushService.DxFormatConvertResponse.class
        );
        return retrievableList;
    }
}