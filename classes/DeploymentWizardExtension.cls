public with sharing class DeploymentWizardExtension {
    public ApexPages.StandardController stdController { get; set; }
    public Deployment__c deployment { get; set; }
    //AUTHORIZATION
    public static String userId {
        get {
            return UserInfo.getUserId();
        }
    }
    public static String orgId {
        get {
            return UserInfo.getOrganizationId();
        }
    }
    public static String sessionId {
        get {
            return UserInfo.getSessionId() != null ? UserInfo.getSessionId() : '';
        }
    }
    public static String token {
        get {
            return DeployAPI.getAuthToken();
        }
    }

    // METADATA
    public String selectedRetrievables { get; set; }
    public String metadata_url { get; set; }
    public String describe_url { get; set; }
    public String sobjects_url { get; set; }
    public String testquery_url { get; set; }
    public String users_url { get; set; }
    public Boolean fromOrgFiltered;

    // STEP TOGGLE
    public String gotoStep { get; set; }
    public Boolean step_createDeployment { get; set; }
    public Boolean step_addStep { get; set; }
    public Boolean step_selectDestinationOrgs { get; set; }
    public Boolean step_setupSchedule { get; set; }

    // STEPS
    public ApexPages.StandardController stepController { get; set; }
    public Step__c step { get; set; }
    public Boolean step_Step_edit { get; set; }
    public Boolean step_Step_new { get; set; }
    public Boolean hasSteps { get; set; }
    public Id selectedStep { get; set; }
    public List<Step__c> steps { get; set; }
    public String stepDescription { get; set; }
    public Integer stepCount { get; set; }

    // Destination orgs
    public Destination_Org__c destinationOrg { get; set; }
    public List<Destination_Org__c> destinationOrgs { get; set; }
    public Boolean hasDestOrgs { get; set; }
    public Boolean step_DestOrg_edit { get; set; }
    public String selectedDestOrg { get; set; }

    // Promotion
    public Promotion__c promotion { get; set; }
    public Deployment_Flow__c df { get; set; }

    // Setup schedule
    public Boolean showDateField { get; set; }

    public Boolean showOtherInformation { get; set; }

    public Boolean ui2 { get; set; }

    public Boolean canDeployThis { get; set; }
    public Boolean goToDeployment { get; set; }

    public Boolean getfromOrgFiltered() {
        if (this.fromOrgFiltered != null) {
            return this.fromOrgFiltered;
        }

        if (deployment.From_Org__c != null && Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            String types = [SELECT Metadata_Types__c FROM Org__c WHERE Id = :deployment.From_Org__c].Metadata_Types__c;
            this.fromOrgFiltered = String.isNotBlank(types);
        }

        return this.fromOrgFiltered;
    }

    public void setUrls() {
        //TODO: move this to external util method in order to use it in other classes
        String urlParameters = '?nosid=1';
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';
        if (deployment.From_Org__c == null) {
            return;
        }
        metadata_url = urlBase + 'metadata/' + EncodingUtil.urlEncode(deployment.From_Org__c, 'UTF-8') + urlParameters;
        describe_url = urlBase + 'describe/' + EncodingUtil.urlEncode(deployment.From_Org__c, 'UTF-8') + '/{sobject}' + urlParameters;
        sobjects_url = urlBase + 'listSObjects/' + EncodingUtil.urlEncode(deployment.From_Org__c, 'UTF-8') + urlParameters;
        testquery_url = urlBase + 'test-query/' + EncodingUtil.urlEncode(deployment.From_Org__c, 'UTF-8') + urlParameters;
        users_url = urlBase + 'users/' + EncodingUtil.urlEncode(deployment.From_Org__c, 'UTF-8') + urlParameters;
    }
    public DeploymentWizardExtension(ApexPages.StandardController stdController) {
        //this flag is when the request came from the new UI in order to replace back url
        ui2 = false;
        if (ApexPages.currentPage().getParameters().get('_ui') != null && ApexPages.currentPage().getParameters().get('_ui') == '2') {
            ui2 = true;
        }

        deployment = (Deployment__c) stdController.getRecord();
        if (deployment == null) {
            deployment = new Deployment__c();
        }
        setUrls();

        step = new Step__c();
        stepController = new ApexPages.StandardController(step);
        steps = new List<Step__c>();

        destinationOrg = new Destination_Org__c();
        destinationOrgs = new List<Destination_Org__c>();

        selectedStep = ApexPages.currentPage().getParameters().get('stepId');
        gotoStep = ApexPages.currentPage().getParameters().get('gotoStep');

        step_createDeployment = true;
        step_addStep = false;
        step_selectDestinationOrgs = false;
        step_setupSchedule = false;

        if (gotoStep == 'deployNow') {
            Boolean validationPassed = true;
            step_createDeployment = false;
            steps = getSteps();
            destinationOrgs = getDestinationOrgs();
            canDeployThis = validateDeployment();
            if (steps.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MISSING_STEPS_MESSAGE));
                validationPassed = false;
            }
            if (destinationOrgs.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MISSING_DEST_ORGS_MESSAGE));
                validationPassed = false;
            }

            if (validationPassed) {
                goto_setupSchedule();
            } else {
                step_createDeployment = true;
            }
        }
        if (String.isNotBlank(selectedStep)) {
            step_createDeployment = false;
            goto_addStep();
        }
        showOtherInformation = SObjectType.Deployment__c.fieldSets.CustomFields.getFields().size() > 0;
        goToDeployment = false;
    }
    public PageReference save_deployment() {
        ApexPages.Message msg = null;
        if (!DeployAPI.validateOrg(deployment.From_Org__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.WRONG_CREDENTIALS));
            return null;
        }
        try {
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPS, schema.SObjectType.Deployment__c);
            setUrls();

            goto_addStep();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, '' + ex));
        }
        return null;
    }
    public Boolean validateDeployment() {
        Deployment__c d = new Deployment__c();
        if (Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
            d = [SELECT Promotion__c FROM Deployment__c WHERE Id = :deployment.Id];
        }
        Boolean isActiveFlow = false;
        Boolean isCCMFlow = false;
        Boolean isValidCBMFlow = false;
        Boolean isSandboxDestinations = false;
        if (LicenseHelper.isLicensesExceeded()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.LICENSES_EXCEEDED));
            return false;
        }
        if (d.Promotion__c != null && (LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled())) {
            // CCM Only user validation

            if (!LicenseHelper.isCopadoEnabled() && LicenseHelper.isCCMEnabled()) {
                List<Id> destinationOrgIds = new List<Id>();
                List<Id> destinationEnvIds = new List<Id>();
                for (Destination_Org__c dOrg : destinationOrgs) {
                    if (dOrg.To_Org__c != null) {
                        destinationOrgIds.add(dOrg.To_Org__c);
                    }
                }
                if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
                    for (Org__c org : [SELECT Environment__c FROM Org__c WHERE Id IN :destinationOrgIds]) {
                        destinationEnvIds.add(org.Environment__c);
                    }
                }
                if (Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
                    for (Environment__c env : [SELECT Type__c FROM Environment__c WHERE Id IN :destinationEnvIds]) {
                        if (env.Type__c == 'Sandbox') {
                            isSandboxDestinations = true;
                        } else {
                            isSandboxDestinations = false;
                            break;
                        }
                    }
                }
                if (!isSandboxDestinations) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_DESTINATION_ORG_INVALID));
                    return false;
                }
            }

            // Promotion flow validation
            promotion = [
                SELECT
                    Project__r.Deployment_Flow__c,
                    Project__r.Deployment_Flow__r.Active__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Project__r.Deployment_Flow__r.Main_Branch__c,
                    Release__r.Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__r.Active__c,
                    Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                    Release__r.Project__r.Deployment_Flow__r.Main_Branch__c
                FROM Promotion__c
                WHERE Id = :d.Promotion__c
            ];
            if (
                promotion.Project__r.Deployment_Flow__c != null && Schema.SObjectType.Deployment_Flow__c.isQueryable() &&
                Schema.SObjectType.Deployment_Flow__c.isAccessible()
            ) {
                df = [
                    SELECT Active__c, Git_Repository__c, Main_Branch__c
                    FROM Deployment_Flow__c
                    WHERE Id = :promotion.Project__r.Deployment_Flow__c
                ];
            } else if (
                promotion.Release__r.Project__r.Deployment_Flow__c != null && Schema.SObjectType.Deployment_Flow__c.isQueryable() &&
                Schema.SObjectType.Deployment_Flow__c.isAccessible()
            ) {
                df = [
                    SELECT Active__c, Git_Repository__c, Main_Branch__c
                    FROM Deployment_Flow__c
                    WHERE Id = :promotion.Release__r.Project__r.Deployment_Flow__c
                ];
            }
            if (df != null) {
                if (df.Active__c) {
                    isActiveFlow = true;
                }
                if (df.Git_Repository__c == null && df.Main_Branch__c == null) {
                    isCCMFlow = true;
                } else if (df.Git_Repository__c != null && df.Main_Branch__c != null) {
                    isValidCBMFlow = true;
                }
            }

            if (isActiveFlow) {
                if (LicenseHelper.isCopadoEnabled() && isCCMFlow) {
                    return true;
                } else if (isValidCBMFlow) {
                    return true;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CBM_FLOW_INVALID));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PROMOTION_FLOW_INACTIVE));
            }
        } else if (LicenseHelper.isCopadoEnabled()) {
            return true;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED));
        }
        return false;
    }
    public List<Step__c> getSteps() {
        steps = new List<Step__c>();
        steps = Utilities.getStepsByDeploymentId(deployment.Id);
        if (!steps.isEmpty()) {
            hasSteps = true;
        }
        stepCount = steps.size();
        return steps;
    }
    public void newStep() {
        step = new Step__c();
        step_Step_edit = true;
        step.Order__c = steps.size() + 1;
        step.Name = 'Step ' + step.Order__c;
        selectedStep = null;
        step_Step_new = true;
    }
    public PageReference useStep() {
        ApexPages.Message msg = null;
        step = Utilities.getStepById(selectedStep);
        step_Step_edit = true;
        return null;
    }
    public PageReference deleteStep() {
        Utilities.Secure_DML(Utilities.getStepById(selectedStep), Utilities.DML_Action.DEL, schema.SObjectType.Step__c);
        enforceStepsOrder();
        getSteps();
        return null;
    }
    public PageReference updateStepDescription() {
        if (step.Type__c == 'MetaData') {
            stepDescription = Label.STEP_DESCRIPTION_METADATA;
        }
        if (step.Type__c == 'Full Profiles') {
            stepDescription = Label.STEP_DESCRIPTION_FULL_PROFILES;
        }
        if (step.Type__c == 'Users') {
            stepDescription = Label.STEP_DESCRIPTION_USERS;
        }
        if (step.Type__c == 'Translations') {
            stepDescription = Label.STEP_DESCRIPTION_TRANSLATIONS;
        }
        if (step.Type__c == 'Data') {
            stepDescription = Label.STEP_DESCRIPTION_DATA;
        }
        if (step.Type__c == 'Bulk Data') {
            stepDescription = Label.STEP_DESCRIPTION_BULK_DATA;
        }
        if (step.Type__c == null) {
            stepDescription = Label.STEP_DESCRIPTION_NONE_SELECTED;
        }
        return null;
    }
    public PageReference deleteDestOrg() {
        Utilities.Secure_DML(
            [SELECT Id FROM Destination_Org__c WHERE Id = :selectedDestOrg],
            Utilities.DML_Action.DEL,
            schema.SObjectType.Destination_Org__c
        );
        getDestinationOrgs();
        return null;
    }

    public List<Destination_Org__c> getDestinationOrgs() {
        destinationOrgs = new List<Destination_Org__c>();
        destinationOrgs = Utilities.getDestinationOrgsByDeploymentId(deployment.Id);
        if (destinationOrgs.size() > 0) {
            hasDestOrgs = true;
        }
        return destinationOrgs;
    }
    public PageReference newDestOrg() {
        destinationOrg = new Destination_Org__c();
        step_DestOrg_edit = true;
        return null;
    }
    public PageReference saveDestOrg() {
        ApexPages.Message msg = null;
        if (!DeployAPI.validateOrg(destinationOrg.To_Org__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.WRONG_CREDENTIALS));
            return null;
        }
        try {
            destinationOrg.Deployment__c = deployment.Id;
            Utilities.Secure_DML(destinationOrg, Utilities.DML_Action.UPS, schema.SObjectType.Destination_Org__c);
            destinationOrg = Utilities.getDestinationOrgsById(destinationOrg.Id);
            destinationOrgs.add(destinationOrg);
            goto_selectDestinationOrgs();
        } catch (Exception ex) {
            msg = new ApexPages.Message(ApexPages.Severity.ERROR, '' + ex);
            ApexPages.addMessage(msg);
        }
        return null;
    }
    public PageReference goto_createDeployment() {
        step_createDeployment = true;
        step_addStep = false;
        step_selectDestinationOrgs = false;
        step_setupSchedule = false;
        return null;
    }
    public PageReference goto_addStep() {
        steps = getSteps();
        step_createDeployment = false;
        step_addStep = true;
        step_selectDestinationOrgs = false;
        step_setupSchedule = false;
        step_Step_edit = false;
        return null;
    }

    public PageReference enforceStepsOrder() {
        //enforce strict steps order
        getSteps();
        Integer i = 1;
        for (Step__c st : steps) {
            st.Order__c = i;
            i++;
        }
        Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
        return null;
    }

    public PageReference goto_selectDestinationOrgs() {
        enforceStepsOrder();
        //prepare destination orgs
        destinationOrgs = getDestinationOrgs();
        step_createDeployment = false;
        step_addStep = false;
        step_selectDestinationOrgs = true;
        step_setupSchedule = false;
        step_DestOrg_edit = false;
        return null;
    }
    public List<SelectOption> getScheduleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Deployment__c.Schedule__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    public PageReference goto_setupSchedule() {
        step_createDeployment = false;
        step_addStep = false;
        step_selectDestinationOrgs = false;
        step_setupSchedule = true;
        showDateField = false;
        return null;
    }
    public PageReference scheduleShowDate() {
        showDateField = false;
        if (deployment.Schedule__c == 'Deploy later') {
            Org__c customerOrg = DeployAPI.getCustomerOrg();
            if (customerOrg == null) {
                deployment.Schedule__c = '';
                deployment.Schedule__c.addError(Label.CUSTOMER_ORG_NOT_EXISTS);
                return null;
            }
            if (!DeployAPI.validateOrg(customerOrg.Id)) {
                deployment.Schedule__c = '';
                deployment.Schedule__c.addError(Label.CUSTOMER_ORG_NOT_VALIDATED);
                return null;
            }
            showDateField = true;
        }
        return null;
    }

    public PageReference creditCheckAndValidations() {
        try {
            Integer creds = DeployAPI.getCredits();
            if ((deployment.Date__c == null || deployment.Date__c < System.now()) && deployment.Schedule__c == 'Deploy later') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DEPLOYLATER_DT_MUST_BE_FUTURE));
                return null;
            }
            if (totalEstimations > creds && DeployAPI.orgMap.get('autoRecharge') == 'false') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NOT_ENOUGH_CREDITS));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public PageReference confirmAll() {
        resetStatuses(true);
        return null;
    }

    public PageReference confirmOutstanding() {
        resetStatuses(false);
        return null;
    }

    public PageReference deployCall() {
        try {
            if (deployment.Schedule__c == 'Deploy now') {
                DeployAPI.deploy(deployment.Id, UserInfo.getSessionId());
            } else if (deployment.Schedule__c == 'Deploy later') {
                // Build a CRON Expression corresponding to selected date
                String cronExpression = GetCRONExpression(deployment.Date__c);

                // Instantiate a new Scheduled Apex class
                DeployLater scheduledJob = new DeployLater(deployment.Id);

                // Schedule our class to run at our given execute time,
                System.schedule(deployment.Name + ' Deploy Later ' + cronExpression, cronExpression, scheduledJob);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // Builds a CRON Expression out of a Datetime
    public static String GetCRONExpression(Datetime dt) {
        return ('' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year());
    }

    public PageReference confirm() {
        try {
            Integer creds = DeployAPI.getCredits();
            if ((deployment.Date__c == null || deployment.Date__c < System.now()) && deployment.Schedule__c == 'Deploy later') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DEPLOYLATER_DT_MUST_BE_FUTURE));
                return null;
            }
            if (totalEstimations > creds && DeployAPI.orgMap.get('autoRecharge') == 'false') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NOT_ENOUGH_CREDITS));
                return null;
            }
            if (
                !Schema.SObjectType.Deployment__c.fields.Deployment_Completed_email_sent__c.isUpdateable() ||
                !Schema.SObjectType.Deployment__c.fields.Status__c.isUpdateable() ||
                !Schema.SObjectType.Deployment__c.fields.Date__c.isUpdateable()
            ) {
                return null;
            }
            deployment.Deployment_Completed_email_sent__c = false;
            deployment.Status__c = 'Scheduled';
            deployment.Deployment_command_sent__c = null;
            if (deployment.Schedule__c == 'Deploy now') {
                deployment.Date__c = System.now();
            }

            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);

            Integer pendingJobs = 0;
            if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
                pendingJobs = [SELECT COUNT() FROM Deployment_Job__c WHERE Step__r.Deployment__c = :deployment.Id AND Status__c = 'Pending'];
            }
            if (pendingJobs == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Nothing to deploy. Try "Deploy All" button'));
                return null;
            }
            System.debug('**f**goToDeployment : ' + goToDeployment);
            goToDeployment = true;
            System.debug('**f**goToDeployment : ' + goToDeployment);
        } catch (Exception e) {
            System.debug('**f**e.getMessage() : ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public void resetStatuses(Boolean allJobs) {
        try {
            Deployment_Job__c[] deploymentJobs;
            if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
                deploymentJobs = [
                    SELECT Id, Status__c, Step__r.Deployment__c, Deployed__c
                    FROM Deployment_Job__c
                    WHERE Step__r.Deployment__c = :deployment.Id
                    LIMIT 10000
                ];
            }

            Destination_Org__c[] destinationOrgs;
            if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
                destinationOrgs = [SELECT Id, Status__c, Deployment__c FROM Destination_Org__c WHERE Deployment__c = :deployment.Id LIMIT 10000];
            }

            List<Deployment_Job__c> deploymentJobsToBeUpdated = new List<Deployment_Job__c>();
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                if ((allJobs || deploymentJob.Status__c != 'Success') && Schema.SObjectType.Deployment_Job__c.fields.Status__c.isUpdateable()) {
                    deploymentJob.Status__c = 'Pending';
                    if (allJobs) {
                        deploymentJob.Early_Completion_Status__c = 'Pending';
                    }
                    deploymentJob.Deployed__c = 0;
                    deploymentJobsToBeUpdated.add(deploymentJob);
                }
            }

            for (Destination_Org__c destinationOrg : destinationOrgs) {
                if (Schema.SObjectType.Destination_Org__c.fields.Status__c.isUpdateable()) {
                    destinationOrg.Status__c = 'Not started';
                }
            }

            Utilities.Secure_DML(destinationOrgs, Utilities.DML_Action.UPD, schema.SObjectType.Destination_Org__c);

            if (!deploymentJobsToBeUpdated.isEmpty()) {
                Utilities.Secure_DML(deploymentJobsToBeUpdated, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    public class Estimation {
        public Step__c step { get; set; }
        public String stepId { get; set; }
        public Integer credits { get; set; }
        public String Status { get; set; }
        public Integer outstandingCredits { get; set; }
    }
    public List<Estimation> estimations;
    public Integer subTotalEstimations { get; set; }
    public Integer totalEstimations { get; set; }
    public Integer orgCount { get; set; }
    public Integer subTotalOutstandingEstimations { get; set; }
    public Integer totalOutstandingEstimations { get; set; }

    public List<Estimation> getEstimations() {
        // Check if estimations have been previously calculated
        if (estimations != null && estimations.size() == getSteps().size()) {
            return estimations;
        }
        estimations = new List<Estimation>();
        if (getSteps().size() == 0 || !step_setupSchedule) {
            return estimations;
        }
        orgCount = destinationOrgs.size();
        totalEstimations = 0;
        totalOutstandingEstimations = 0;

        Map<String, Object> mapa = estimateDeploy(deployment.Id);
        Map<Id, Integer> outstandings = new Map<Id, Integer>();
        if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            for (Deployment_Job__c dj : [SELECT Id, Status__c, Step__c FROM Deployment_Job__c WHERE Step__c IN :mapa.keySet() LIMIT 10000]) {
                if (outstandings.get(dj.Step__c) == null) {
                    outstandings.put(dj.Step__c, 0);
                }
                if (dj.Status__c != 'Success') {
                    outstandings.put(dj.Step__c, outstandings.get(dj.Step__c) + 1);
                }
            }
        }
        if (Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            for (Step__c st : [SELECT Id, Name, CheckOnly__c FROM Step__c WHERE Id IN :mapa.keySet() ORDER BY Order__c]) {
                Estimation e = new Estimation();
                e.step = st;
                e.stepId = st.Id;
                try {
                    e.credits = Integer.valueOf((String) mapa.get(st.Id)) * orgCount;
                    e.outstandingCredits = Integer.valueOf((String) mapa.get(st.Id)) * outstandings.get(st.Id);
                    totalEstimations += e.credits;
                    totalOutstandingEstimations += e.outstandingCredits;
                    e.Status = 'Estimation Done';
                } catch (Exception ex) {
                    e.Status = (String) mapa.get(st.Id);
                }
                estimations.add(e);
            }
        }
        return estimations;
    }
    private class UserAttachment {
        public List<String> userIds;
        public String fromSuffix;
        public String toSuffix;
        public Boolean active;
        public Boolean userTerritories;

        public UserAttachment parse(String json) {
            return (UserAttachment) System.JSON.deserialize(json, UserAttachment.class);
        }
    }
    public Map<String, Object> estimateDeploy(String deploymentId) {
        Map<String, Object> eMap = new Map<String, Object>();
        List<String> mStepsIds = new List<String>();
        Set<String> gitStepsIds = new Set<String>();
        for (Step__c step : [SELECT Type__c FROM Step__c WHERE Deployment__c = :deploymentId]) {
            eMap.put(step.Id, '1');
            if (
                step.Type__c == 'MetaData' ||
                step.Type__c == 'Full Profiles' ||
                step.Type__c == 'Full Permission Sets' ||
                step.Type__c == 'Users' ||
                step.Type__c == 'Translations' ||
                step.Type__c == 'Delete MetaData' ||
                step.Type__c == 'Custom Settings' ||
                step.Type__c == 'Git MetaData'
            ) {
                if (step.Type__c == 'Git MetaData') {
                    gitStepsIds.add(step.Id);
                }
                // The credits are based on the number of items in the step's attachment
                mStepsIds.add(step.id);
            } else if (step.Type__c == 'Manual Task' || step.Type__c == 'Git Promotion' || step.Type__c == 'Salesforce Flow') {
                eMap.put(step.Id, '0');
            } else {
                // 1 credit per execution of all other step types (Data, Bulk Data, Apex, URL Callout and any other)
                eMap.put(step.Id, '1');
            }
        }
        List<String> atts = new List<String>{
            'MetaData',
            'Delete MetaData',
            'Full Profiles',
            'Full Permission Sets',
            'Translations',
            'Users',
            'Custom Settings'
        };
        //try {
        for (Attachment att : [SELECT Name, ParentId, Body FROM Attachment WHERE ParentId IN :mStepsIds AND Name IN :atts]) {
            String b = EncodingUtil.base64Decode(EncodingUtil.base64Encode(att.Body)).toString();
            // Attachments of 'Users' and 'Custom Settings' have irregular json structures
            if (att.Name == 'Users') {
                if (String.isNotBlank(b)) {
                    UserWrapper usWrapper = (UserWrapper) System.JSON.deserialize(b, UserWrapper.class);
                    if (usWrapper.userIds != null) {
                        eMap.put(att.ParentId, String.valueOf(usWrapper.userIds.size()));
                    } else {
                        eMap.put(att.ParentId, '1');
                    }
                } else {
                    eMap.put(att.ParentId, '1');
                }
            } else if (att.Name == 'Custom Settings') {
                if (String.isNotBlank(b)) {
                    CustomSettingWrapper rItems = (CustomSettingWrapper) JSON.deserialize(b, CustomSettingWrapper.class);
                    if (rItems.prevRes != null) {
                        Integer totalSelected = 0;
                        for (CustomSettingValues csv : rItems.prevRes) {
                            if (csv.s) {
                                totalSelected++;
                            }
                        }
                        eMap.put(att.ParentId, String.valueOf(totalSelected));
                    } else {
                        eMap.put(att.ParentId, '1');
                    }
                } else {
                    eMap.put(att.ParentId, '1');
                }
            } else {
                // All other attachments have regular json structures
                List<Object> mItems = (List<Object>) JSON.deserializeUntyped(b);
                if (att.Name == 'Translations' || att.Name == 'Full Profiles' || att.Name == 'Full Permission Sets') {
                    // 5 credits per translation, full profile and full permission set
                    eMap.put(att.ParentId, String.valueOf(mItems.size() * 5));
                } else if (gitStepsIds.contains(att.ParentId) && mItems.size() > 50) {
                    // 50 max credits for 'Git MetaData'
                    eMap.put(att.ParentId, String.valueOf(50));
                } else if (mItems.size() > 0) {
                    // 1 credit per metadata item
                    eMap.put(att.ParentId, String.valueOf(mItems.size()));
                } else {
                    eMap.put(att.ParentId, '1');
                }
            }
        }
        return eMap;
    }
    public void moveUp() {
        try {
            Step__c lowerStep = new Step__c();
            Step__c upperStep = new Step__c();
            Map<Decimal, Step__c> stepMap = new Map<Decimal, Step__c>();
            for (Step__c a : steps) {
                stepMap.put(a.Order__c, a);
                if (a.Id == selectedStep) {
                    lowerStep = a;
                }
            }
            upperStep = stepMap.get(lowerStep.Order__c - 1);
            lowerStep.Order__c = lowerStep.Order__c - 1;
            upperStep.Order__c = upperStep.Order__c + 1;
            Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
            getSteps();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getStackTraceString()));
        }
    }
    public void moveDown() {
        try {
            Step__c lowerStep = new Step__c();
            Step__c upperStep = new Step__c();
            Map<Decimal, Step__c> stepMap = new Map<Decimal, Step__c>();
            for (Step__c a : steps) {
                stepMap.put(a.Order__c, a);
                if (a.Id == selectedStep)
                    upperStep = a;
            }
            lowerStep = stepMap.get(upperStep.Order__c + 1);
            lowerStep.Order__c = lowerStep.Order__c - 1;
            upperStep.Order__c = upperStep.Order__c + 1;
            Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
            getSteps();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getStackTraceString()));
        }
    }
    public List<SelectOption> getStepTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        options.add(new SelectOption('MetaData', 'MetaData'));
        options.add(new SelectOption('Full Profiles', 'Full Profiles'));
        options.add(new SelectOption('Full Permission Sets', 'Full Permission Sets'));
        options.add(new SelectOption('Users', 'Users'));
        options.add(new SelectOption('Translations', 'Translations'));
        options.add(new SelectOption('Data', 'Data'));
        options.add(new SelectOption('Bulk Data', 'Bulk Data'));
        options.add(new SelectOption('Delete MetaData', 'Delete MetaData'));
        return options;
    }

    public class UserWrapper {
        public String fromSuffix { get; set; }
        public String toSuffix { get; set; }
        public Boolean active { get; set; }
        public String userTerritories { get; set; }
        public List<String> userIds { get; set; }
    }

    public class CustomSettingWrapper {
        public String fromSuffix { get; set; }
        public String toSuffix { get; set; }
        public List<String> settings { get; set; }
        public String sco { get; set; }
        public String csName { get; set; }
        public List<CustomSettingValues> prevRes { get; set; }
    }

    public class CustomSettingValues {
        public Boolean s { get; set; }
        public String Name { get; set; }
        public String type { get; set; }
    }
}