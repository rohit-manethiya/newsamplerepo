global with sharing class DeploymentExt {
    public JsRemotingController remotingController { get; set; }
    /**
     * final configuration page
     */

    /**
     * This public instance of deployment obj is the bridge for the standard controller obj
     */
    public Deployment__c dep { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }

    public String errorLevel { get; set; }
    public String messageName { get; set; }

    public List<Map<String, String>> messagesQueue = new List<Map<String, String>>();
    public String jsonMessagesQueue { set; }

    /*flag for custom fieldset*/
    public Boolean showOtherInformation { get; set; }
    /*flag for ccd to enable streaming functionality for steps*/
    public Boolean ccdEnabled { get; set; }

    /*helper to remove destination org*/
    public String selectedToOrg { get; set; }
    /*helper to select an step*/
    public String selectedStepId { get; set; }
    public String selectStepOrg { get; set; }
    public String selectStepAction { get; set; }

    public Boolean isNew { get; set; }
    public Boolean fromValid { get; set; }
    public Boolean showStepsOnly { get; set; } // MY: Added for DX post SO job preview. Since we will use deployments as data load and post success jobs we need to display steps on DX operation panel.

    public Boolean historyVisible = false;

    /* helper parameter */
    public String destinationId { get; set; }
    /**
     * helpers to serialize apex data into json
     */
    public String depJson;
    public String destinationsJson;
    public String stepsJson;

    /**
     * TODO
     */
    public Destination_Org__c[] destinations { get; set; }
    public Set<String> destinationOrgSet;

    /**
     * TODO
     */
    public Step__c[] steps { get; set; }

    /* shortcut to last added step*/
    //public Step__c lastStep {get;set;}

    /**
     * TODO
     */
    //public Step__c selectedStep {get;set;}

    public Org__c fromOrg { get; set; }

    /**
     * this flag shows ir from org has metadata filters activated.
     * this flag is useful in stepGrid component.
     */
    public Boolean orgFiltered { get; set; }

    /**
     * url's helpers to heroku api calls
     */
    public String metadata_url { get; set; }
    public String describe_url { get; set; }
    public String sobjects_url { get; set; }
    public String testquery_url { get; set; }
    public String users_url { get; set; }
    public String cancel_url { get; set; }
    public String custom_settings_url { get; set; }
    public String git_metadata_url { get; set; }
    public String quick_actions_url { get; set; }

    public String urlParameters { get; set; }
    public String herokuServer { get; set; }
    public Boolean isShareable { get; set; }

    private final String OK_STRING = 'OK';

    public String getDestinationsJson() {
        return JSON.serialize(this.destinations);
    }

    public String getStepsJson() {
        return JSON.serialize(this.steps);
    }

    public String getDepJson() {
        return JSON.serialize(this.dep);
    }

    public String getjsonMessagesQueue() {
        return JSON.serialize(this.messagesQueue);
    }

    /**
     * This method get a list of step IDs and save them setting the recived order.
     * @param ids String[] in order to be set
     */
    @RemoteAction
    global static void sortSteps(String[] ids) {
        Step__c[] toUpsert = new List<Step__c>{};
        Integer i = 1;
        for (String idStr : ids) {
            toUpsert.add(new Step__c(Id = idStr, Order__c = i));
            i++;
        }
        Utilities.Secure_DML(toUpsert, Utilities.DML_Action.UPS, schema.SObjectType.Step__c);
    }

    /**
     * Override the standard save action to validate from org credentials.
     */
    public PageReference saveDeployment() {
        if (String.isNotBlank(dep.From_Org__c) && !DeployAPI.validateOrg(dep.From_Org__c)) {
            addMsgError(Label.WRONG_CREDENTIALS);
            return null;
        }
        if (LicenseHelper.isLicensesExceeded()) {
            addMsgError(Label.LICENSES_EXCEEDED);
            return null;
        }
        if (LicenseHelper.isCopadoEnabled()) {
            try {
                Boolean isCreate = String.isBlank(dep.Id);
                Utilities.Secure_DML(dep, Utilities.DML_Action.UPS, schema.SObjectType.Deployment__c);
                setUrls();
                isNew = false;
                addMsgOk(Label.Deployment_Saved);
                if (isCreate) {
                    return new Apexpages.StandardController(dep).view();
                }
            } catch (Exception ex) {
                addMsgError(ex.getMessage());
                System.debug(ex.getStackTraceString());
                return null;
            }
        } else {
            addMsgError(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        }
        return null;
    }
    /**
     * constructor method.
     */
    public DeploymentExt(ApexPages.StandardController sc) {
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        if (!Test.isRunningTest()) {
            sc.addFields(Utilities.getAllFields('Deployment__c').get(Label.FIELDS).split(','));
            sc.addFields(new List<String>{ 'From_Org__r.Disable_Validation__c', 'From_Org__r.Oauth_Signature__c' });
        }

        reset();

        this.dep = (Deployment__c) sc.getRecord();

        //instance for new
        if (String.isBlank(this.dep.Id)) {
            //this.dep = new Deployment__c();
            isNew = true;
        } else {
            isNew = false;
            //get previous fromOtrg
            if (dep.From_Org__c != null) {
                fromOrg = Utilities.getOrgById(dep.From_Org__c);
                orgFiltered = String.isNotBlank(fromOrg.Metadata_Types__c);
                checkAndValidateFromOrg();
            }
        }

        setUrls();
        initDestination();
        initSteps();

        showOtherInformation = SObjectType.Deployment__c.fieldSets.CustomFields.getFields().size() > 0;
        Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        isShareable = gdMap.containsKey('Deployment__Share');

        // MY: Added for DX post SO job preview. Since we will use deployments as data load and post success jobs we need to display steps on DX operation panel.
        String stepsOnlyParam = ApexPages.currentPage().getParameters().get('stepsOnly');
        showStepsOnly = String.isNotBlank(stepsOnlyParam) ? true : false;
        //
    }

    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditDeployment')) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCH_or_CCM_License))
            );
            showError = true;
            showOptions = false;
        }
        return;
    }
    /**
     * Validate the fromOrg
     */
    public Boolean checkAndValidateFromOrg() {
        if (fromOrg.Validated_Status__c != OK_STRING) {
            //TODO add more logic like checkbox
            Boolean res = DeployAPI.validateOrg(fromOrg.Id);
            //refresh from api credentials.
            fromOrg = Utilities.getOrgById(dep.From_Org__c);
            orgFiltered = String.isNotBlank(fromOrg.Metadata_Types__c);
            if (!res) {
                addMsgError(Label.ORG_NOT_VALIDATED);
            }
            fromValid = res;
        } else {
            fromValid = true;
        }
        return fromValid;
    }

    /**
     * get org detail and Validate connection status
     */
    public PageReference validateFromOrg() {
        PageReference ref = null;
        System.debug('selected ' + dep.From_Org__c);
        if (dep.From_Org__c == null) {
            fromOrg = null;
            return ref;
        }

        fromOrg = Utilities.getOrgById(dep.From_Org__c);

        if (checkAndValidateFromOrg()) {
            ref = saveDeployment();
            setUrls();
        }
        return ref;
    }

    /**
     *  fill destinations list and create a default destination if is empty
     */
    public void initDestination() {
        destinationOrgSet = new Set<String>();
        Set<String> destinationEnvIdSet = new Set<String>();

        if (isNew) {
            destinations = new List<Destination_Org__c>{};
        } else {
            destinations = CopadoAPI.getDestinationsOrg(this.dep.Id);
            //pre-fill set helper in order to validate faster duplicates
            for (Destination_Org__c dest : destinations) {
                destinationOrgSet.add(dest.To_Org__c);
                destinationEnvIdSet.add(dest.To_Org__r.Environment__c);
            }
            if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible() && destinations.size() == 1) {
                List<Org__c> tempOrgList = [
                    SELECT Id, Environment__c, Environment__r.Connection_Behavior__c, Environment__r.Connection_Behavior__r.Promotion_Behavior__c
                    FROM Org__c
                    WHERE Id IN :destinationOrgSet
                ];
                for (Org__c org : tempOrgList) {
                    Boolean hasConnectionBehavior = (null != org.Environment__r.Connection_Behavior__c &&
                        org.Environment__r.Connection_Behavior__r.Promotion_Behavior__c != ''
                        ? true
                        : false);
                    orgId_hasManualConnectionBehaviorMap.put(org.Id, hasConnectionBehavior);
                    ccdEnabled = hasConnectionBehavior;
                }
            }
            if (null != dep.Promotion__c & destinations.size() == 1) {
                Promotion__c proItem = [
                    SELECT Id, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                    FROM Promotion__c
                    WHERE Id = :dep.Promotion__c
                ];
                Id depflowId = null != proItem.Project__c ? proItem.Project__r.Deployment_Flow__c : proItem.Release__r.Project__r.Deployment_Flow__c;
                for (Deployment_Flow_Step__c dfs : [
                    SELECT Id, Connection_Behavior__c
                    FROM Deployment_Flow_Step__c
                    WHERE
                        Source_Environment__c = :dep.Source_Environment__c
                        AND Destination_Environment__c IN :destinationEnvIdSet
                        AND Deployment_Flow__c = :depflowId
                ]) {
                    if (String.isNotBlank(dfs.Connection_Behavior__c)) {
                        ccdEnabled = true;
                    }
                }
            }
        }
        if (destinations.isEmpty()) {
            addDestination();
        }
    }
    /**
     * get from the API the list of step for this deployment.
     */
    public void initSteps() {
        //get initial steps
        //then they will be manage in the frontend
        if (isNew) {
            steps = new List<Step__c>{};
        } else {
            steps = CopadoAPI.listSteps(this.dep.Id);
        }
    }

    /**
     * Set Heroku urls to call API from javascript
     */
    public void setUrls() {
        cancel_url = getCancelURL();
        urlParameters = '?nosid=1';
        herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';
        git_metadata_url = urlBase + 'gitmetadata/{repositoryId}/{commitId}' + urlParameters + '&branch={branch}';
        System.debug('**f**git_metadata_url : ' + git_metadata_url);
        if (dep.From_Org__c == null) {
            return;
        }
        if (fromOrg != null && String.isNotBlank(fromOrg.Metadata_Types__c)) {
            urlParameters += '&filter=' + EncodingUtil.urlEncode(fromOrg.Metadata_Types__c, 'UTF-8');
        }
        String fromOrgEncoded = EncodingUtil.urlEncode(dep.From_Org__c, 'UTF-8');
        metadata_url = urlBase + 'metadata/' + fromOrgEncoded + urlParameters + '&dates=format';
        describe_url = urlBase + 'describe/' + fromOrgEncoded + '/{sobject}' + urlParameters;
        sobjects_url = urlBase + 'listSObjects/' + fromOrgEncoded + urlParameters;
        testquery_url = urlBase + 'test-query/' + fromOrgEncoded + urlParameters;
        users_url = urlBase + 'users/' + fromOrgEncoded + urlParameters;
        custom_settings_url = urlBase + 'customSetting/' + fromOrgEncoded + '/{sobject}' + urlParameters;
        quick_actions_url = urlBase + 'quickActions/' + fromOrgEncoded + '/{sobject}' + urlParameters;
    }

    public Map<Id, Boolean> orgId_hasManualConnectionBehaviorMap {
        get {
            if (null == orgId_hasManualConnectionBehaviorMap) {
                orgId_hasManualConnectionBehaviorMap = new Map<Id, Boolean>();
            }
            return orgId_hasManualConnectionBehaviorMap;
        }
        set;
    }

    public Boolean getMapIsEmpty() {
        return (orgId_hasManualConnectionBehaviorMap.size() == 0 ? true : false);
    }

    /**
     * Save list of destinations
     */
    public void saveDestination() {
        Set<String> destinationEnvIdSet = new Set<String>();
        for (Destination_Org__c dest : destinations) {
            orgId_hasManualConnectionBehaviorMap.put(dest.To_Org__c, false);
        }
        if (!Schema.SObjectType.Org__c.isQueryable() && !Schema.SObjectType.Org__c.isAccessible()) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Org__c.getName() + ': ' + Label.Insufficient_Access_Rights)
            );
            return;
        }
        List<Org__c> tempOrgList = [
            SELECT Environment__c, Environment__r.Connection_Behavior__c, Environment__r.Connection_Behavior__r.Promotion_Behavior__c
            FROM Org__c
            WHERE Id IN :orgId_hasManualConnectionBehaviorMap.keyset()
        ];
        for (Org__c org : tempOrgList) {
            Boolean hasConnectionBehavior = (null != org.Environment__r.Connection_Behavior__c &&
                org.Environment__r.Connection_Behavior__r.Promotion_Behavior__c != ''
                ? true
                : false);
            orgId_hasManualConnectionBehaviorMap.put(org.Id, hasConnectionBehavior);
            ccdEnabled = hasConnectionBehavior;
            destinationEnvIdSet.add(org.Environment__c);
        }

        if (null != dep.Promotion__c & destinations.size() == 1) {
            Promotion__c proItem = [
                SELECT Id, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                FROM Promotion__c
                WHERE Id = :dep.Promotion__c
            ];
            Id depflowId = null != proItem.Project__c ? proItem.Project__r.Deployment_Flow__c : proItem.Release__r.Project__r.Deployment_Flow__c;
            for (Deployment_Flow_Step__c dfs : [
                SELECT Id, Connection_Behavior__c
                FROM Deployment_Flow_Step__c
                WHERE
                    Source_Environment__c = :dep.Source_Environment__c
                    AND Destination_Environment__c IN :destinationEnvIdSet
                    AND Deployment_Flow__c = :depflowId
            ]) {
                if (String.isNotBlank(dfs.Connection_Behavior__c)) {
                    ccdEnabled = true;
                }
            }
        }

        for (Destination_Org__c dest : destinations) {
            //find the new one
            if (String.isBlank(dest.Id)) {
                if (String.isBlank(dest.To_Org__c)) {
                    addMsgError(Label.ORG_NOT_VALIDATED);
                    return;
                }
                /*validation removed by Fede request
                if(d.To_Org__c == dep.From_Org__c){
                    addMsgError('Destination Org can not be the same than From Org.');
                    return ;
                }*/
                if (destinationOrgSet.contains(dest.To_Org__c)) {
                    addMsgError(Label.DESTINATION_ORG_ALREADY_SELECTED);
                    return;
                }

                //validate conection
                Org__c org = Utilities.getOrgById(dest.To_Org__c);

                if (org.Validated_Status__c != OK_STRING) {
                    if (!DeployAPI.validateOrg(org.Id)) {
                        addMsgError(Label.DESTINATION_ORG_NOT_VALIDATED);
                        return;
                    }
                }
                // if was ok or validation is Ok then save and refresh
                CopadoAPI.addDestinationOrg(this.dep.Id, dest.To_Org__c);

                // refresh from API
                initDestination();
                addMsgOk(Label.DESTINATION_ORG_SAVED);

                break;
            }
        }
    }
    /**
     * error message in frontend helper
     */
    public void addMsgError(String msg) {
        addMsg('ERROR', msg);
    }
    /**
     * generic message in frontend helper
     */
    public void addMsg(String type, String msg) {
        //we are using this map in order to save messages from apex
        //and then render them as a json object in order to be used by the JSApp
        Map<String, String> messageMap = new Map<String, String>();
        messageMap.put('s', type);
        messageMap.put('m', msg);

        messagesQueue.add(messageMap);
        //Apexpages.addMessage(new Apexpages.Message(type, msg));
    }

    /**
     * success message in frontend helper
     */
    public void addMsgOk(String msg) {
        addMsg('CONFIRM', msg);
    }

    /**
     * delete destination org and refresh local list
     */
    public PageReference deleteDestOrg() {
        ccdEnabled = false;
        CopadoAPI.removeDestinationOrg(this.dep.Id, selectedToOrg);
        initDestination();
        return null;
    }
    /**
     * remote action to remove an step
     */
    @RemoteAction
    global static void deleteStep(String stepId) {
        if (String.isNotBlank(stepId)) {
            CopadoAPI.removeStep(stepId);
        }
    }

    /**
     * helper to get http param
     * for remote actions
     */
    public static String getParam(String p) {
        return ApexPages.currentPage().getParameters().get(p);
    }

    /**
     * Add empty Step
     */
    public void addDestination() {
        //add new local
        destinations.add(new Destination_Org__c(Deployment__c = this.dep.Id));
    }

    /**
     * reset page status
     */
    public void reset() {
        fromValid = false;
    }
    /**
     * TODO
     * by now it is working on redirection only
     */
    public void deploy() {
    }

    /**
     * TODO
     */
    public PageReference fullCloneRedirect() {
        return null;
    }

    /**
     * TODO
     */
    public void sharing() {
    }

    /**
     * helper to get return url to deployment list tab
     */
    public String getCancelURL() {
        Schema.DescribeSObjectResult result = Deployment__c.SObjectType.getDescribe();
        return '/' + result.getKeyPrefix();
    }
    public Boolean getHistoryVisible() {
        return Schema.SObjectType.Deployment_History__c.fields.Deployment__c.isAccessible();
    }

    /**
     * Create the string that will match the copado notification to other pages that might start a job on the same repo+branch
     * It only has a value if there is a Git Promotion step, and it should never fail.
     **/
    public String getJobsManagerMatchingKey() {
        String matchingKey = '';
        String flow_id = '', target_branch = '';
        Step__c gitPromotionStep = null;
        for (Step__c stp : steps) {
            if (stp.Type__c == 'Git Promotion') {
                gitPromotionStep = stp;
                break;
            }
        }
        if (gitPromotionStep == null) {
            return '';
        }
        try {
            for (Attachment att : [
                SELECT Id, Body
                FROM Attachment
                WHERE ParentId = :gitPromotionStep.Id AND Name = 'Git-Promotion.json'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]) {
                Map<String, Object> contents = (Map<String, Object>) JSON.deserializeUntyped(att.Body.toString());
                flow_id = (String) contents.get('flow_id');
                target_branch = (String) contents.get('target_branch');
                break;
            }

            if (String.isNotBlank(flow_id) && String.isNotBlank(target_branch)) {
                if (!Schema.SObjectType.Deployment_Flow__c.isQueryable() && !Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.WARNING,
                            Schema.SObjectType.Deployment_Flow__c.getName() +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }
                for (Deployment_Flow__c df : [SELECT Git_Repository__c FROM Deployment_Flow__c WHERE Id = :flow_id LIMIT 1]) {
                    matchingKey = 'GIT-' + df.Git_Repository__c + '-' + target_branch;
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('getJobsManagerMatchingKey() error=' + e);
        }

        return matchingKey;
    }
    /*
        This is used to check if org has chatter enabled so chatter component is hidden
        and not rendered
     */
    public static Boolean getisChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Deployment__c.isFeedEnabled();
    }
}