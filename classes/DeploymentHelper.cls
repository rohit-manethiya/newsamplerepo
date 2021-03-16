/**
 * This is generic class for deployment wizard classes
 */
public with sharing virtual class DeploymentHelper {
    // NON Constants
    public Deployment__c deployment { get; set; }
    public String metadataURL { get; set; }
    public String attId { get; set; }
    public DeploymentInterface deploymentInterface { get; set; }
    public List<String> pagesList { get; set; }
    public List<String> stepsList { get; set; }
    public List<SourceWrapper> sourceList { get; set; }
    public Map<String, List<Object>> pageMessagesMap { get; set; }
    public Integer currentStepValue { get; set; }
    public String deploymentActionName { get; set; }
    public Data_Template__c dataTemplate { get; set; }
    private Map<String, Type> serviceLayerMap;
    private String currentURL;
    public Boolean skipOverrideFilters;
    public Boolean goOverrideFilters;
    public Deployment__c deploymentWillBeRedirected = new Deployment__c();

    // Constants
    public final String C_ERROR = 'error';
    public final String C_SUCCESS = 'Completed Successfully';
    public final String C_DSW_DEPLOYMENT_PAGE = 'dw_deployment';
    public final String C_DSW_SUMMARY_PAGE = 'DW_Summary';
    public final String C_DSW_SOURCE_PAGE = 'DW_Source';
    public final String C_DSW_OVERVIEW = 'DW_Overview';
    public final String C_DSW_OVERRIDE_FILTERS = 'DW_OverrideFilters';
    public final String C_WARNING = 'warning';
    public final String C_INFO = 'info';
    public final String REFRESH_CACHE = 'refreshCache';
    public final String C_DONE = 'done';
    public final String ORG = 'org';
    public final String GIT = 'git';
    public final String DATA = 'data';
    public final String METADATA = 'MetaData';
    public final String GIT_METADATA = 'Git MetaData';
    public final String NOT_STARTED = 'Not Started';
    public final String STEP_ONE = 'Step 1';
    public final String METADATA_PRESELECTION_ID = 'MetadataPreselectionId';
    public final String VALIDATION = 'validation';
    public final String C_DEPLOYMENT = 'deployment';
    public final String PENDING = 'Pending';
    public final String C_ID = 'id';
    public final String DATA_TEMPLATE = 'Data Template';
    public final String C_OTHER = 'other';
    public final String C_OK = 'OK';
    public final String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
        .get('Data Deployment')
        .getRecordTypeId();
    public final String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
        .get('Metadata Deployment')
        .getRecordTypeId();
    public final String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
        .get('Advanced (multi-step)')
        .getRecordTypeId();

    public DeploymentHelper() {
        deploymentActionName = ApexPages.currentPage().getParameters().get('deploymentActionType');
        attId = ApexPages.currentPage().getParameters().get(METADATA_PRESELECTION_ID);
        pagesList = new List<String>();
        stepsList = new List<String>();
        pageMessagesMap = new Map<String, List<Object>>();
        serviceLayerMap = new Map<String, Type>{
            metadataDeploymentRecordTypeId => MetadataDeploymentService.class,
            dataDeploymentRecordTypeId => DataDeploymentService.class
        };
        currentURL = ApexPages.currentPage().getUrl();
        skipOverrideFilters = false; // it will be true only for Data template if user do not want to override filters
        goOverrideFilters = false;

        Boolean bigMetadataEnabled = false;
        for (Copado_Setting__mdt cs : [SELECT Id, Enabled__c FROM Copado_Setting__mdt WHERE DeveloperName = :'Big_Metadata' LIMIT 1]) {
            bigMetadataEnabled = cs.Enabled__c;
        }

        if (bigMetadataEnabled) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ Label.Big_Metadata_Warning });
        }
    }

    /**
     * Strategy pattern
     * Based on the page content, different services will be initialised by using DeploymentInterface interface
     * Metadata deployment type will initialize MetadataDeploymentService
     * @see DeploymentInterface
     */
    public void initializeServiceClasses() {
        if (deployment.RecordTypeId != null && advancedDeploymentRecordTypeId != deployment.RecordTypeId) {
            if (serviceLayerMap.containsKey(deployment.RecordTypeId)) {
                deploymentInterface = (DeploymentInterface) (serviceLayerMap.get(deployment.RecordTypeId).newInstance());
            } else {
                pageMessagesMap.put(C_ERROR, new List<Object>{ Label.Unsupported_Service });
            }
        }
        currentStepValue = (String.isNotBlank(currentURL) && deploymentInterface != null) ? deploymentInterface.getComponentIndex(currentURL) : 0;
    }

    /**
     * It is used to populate metadataURL to use it in the config for grid
     */
    public void initializeMetadataUrl() {
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';
        metadataURL = urlBase + 'metadata/' + deployment.From_Org__c + '?dates=format';
    }

    /**
     * It is used to populate org credential records based on last viewed date
     *
     * @return
     */
    public List<Org__c> getLastViewedOrgs() {
        List<Org__c> orgs = new List<Org__c>();
        try {
            return orgs = [
                SELECT Id, Name, Username__c, Environment__r.Name
                FROM Org__c
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT 1000
            ];
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Org__c.getLabel()
                }
            );
            return null;
        }
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getPageMessageSize() {
        Integer listSize = 0;
        for (String severity : pageMessagesMap.keySet()) {
            listSize += pageMessagesMap.get(severity).size();
        }
        return listSize;
    }

    /**
     * It is used to populate available steps for selected type
     * call this method in the page controller after deployment interface is initialized
     *
     * @see DeploymentInterface
     */
    public void populateStepsList() {
        if (deploymentInterface != null) {
            stepsList = deploymentInterface.returnAvailableSteps();
        }
    }

    /**
     * It is used to populate available pages for selected type
     * call this method in the page controller after deployment interface is initialized
     *
     * @see DeploymentInterface
     */
    public void populatePagesList() {
        if (deploymentInterface != null) {
            pagesList = deploymentInterface.returnAvailablePages();
        }
    }

    /**
     * It is used to validate selected org record
     * !Test.isRunningTest() is to prevent async callout issue which can not be caught on try catch
     */
    public void validateOrg() {
        try {
            if (String.isNotBlank(deployment.From_Org__c)) {
                Org__c fromOrg = [SELECT Id, Validated_Status__c FROM Org__c WHERE Id = :deployment.From_Org__c WITH SECURITY_ENFORCED];
                if (fromOrg.Validated_Status__c != C_OK && !Test.isRunningTest()) {
                    DeployAPI.validateOrgAsync(fromOrg.Id);
                }
            }
        } catch (System.QueryException excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return;
        }
    }

    /**
     * It is used to save / update deployment in any step before go to next step or close step
     */
    public void upsertDeployment(Boolean updateDeploymentLastStep) {
        if (LicenseHelper.isLicensesExceeded()) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ Label.LICENSES_EXCEEDED });
            return;
        }
        if (!LicenseHelper.isCopadoEnabled()) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED });
            return;
        }

        try {
            // We are getting the new instance of deployment with the id and necessary fields to update only necessary fields. There were a case that deployment were remained "Scheduled". It was the reason.
            // In else we are assigning standard controller deployment to be insertded deployment record.
            if (String.isNotBlank(deployment.Id)) {
                deploymentWillBeRedirected = new Deployment__c(
                    Id = deployment.Id,
                    Name = deployment.Name,
                    Deployment_Last_Step__c = deployment.Deployment_Last_Step__c,
                    From_Org__c = deployment.From_Org__c,
                    Deployment_Source_Type__c = deployment.Deployment_Source_Type__c
                );
            } else {
                deploymentWillBeRedirected = deployment;
            }

            Integer lastStepIndex = deploymentInterface.getComponentIndex(deploymentWillBeRedirected.Deployment_Last_Step__c);
            Integer currentPageIndex = deploymentInterface.getComponentIndex(currentURL);
            if (lastStepIndex == currentPageIndex) {
                Integer newIndex = updateDeploymentLastStep ? lastStepIndex + 1 : lastStepIndex;
                deploymentWillBeRedirected.Deployment_Last_Step__c = !pagesList.isEmpty() ? pagesList[newIndex] : null;
            }
            if (skipOverrideFilters) {
                deploymentWillBeRedirected.Deployment_Last_Step__c = C_DSW_OVERVIEW;
            }
            if (goOverrideFilters && !skipOverrideFilters) {
                deploymentWillBeRedirected.Deployment_Last_Step__c = C_DSW_OVERRIDE_FILTERS;
            }
            // Strip fields that are not UPSERTABLE
            //SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, new List<Deployment__c>{ deployment });
            //upsert decision.getRecords();
            Utilities.Secure_DML(deploymentWillBeRedirected, Utilities.DML_Action.UPS, schema.SObjectType.Deployment__c);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    /**
     * It is used when user click to "Cancel" button
     *
     * @return Deployment tab view
     */
    public PageReference goToDeploymentTab() {
        String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
        return new PageReference(url);
    }

    /**
     * It is used to redirect to the advanced deployment page
     *
     * @return
     */
    public PageReference goToDeployment() {
        PageReference pageReference = Page.Deployment;
        pageReference.getParameters().put(C_ID, deployment.Id);
        pageReference.setRedirect(true);
        return pageReference;
    }

    /**
     * It is used to redirect next step
     *
     * @see DeploymentInterface
     * @return
     */
    public PageReference goToNextStep() {
        try {
            List<Step__c> deploymentSteps = getDeploymentSteps();
            if (
                !deploymentSteps.isEmpty() &&
                deploymentSteps[0].Status__c == C_SUCCESS &&
                deployment.Deployment_Last_Step__c.toLowerCase() == C_DSW_DEPLOYMENT_PAGE
            ) {
                deploymentWillBeRedirected = new Deployment__c(Id = deployment.Id, Deployment_Last_Step__c = deployment.Deployment_Last_Step__c);
                deploymentWillBeRedirected.Deployment_Last_Step__c = C_DSW_SUMMARY_PAGE;
                // Strip fields that are not updatable
                SObjectAccessDecision decision = Security.stripInaccessible(
                    AccessType.UPDATABLE,
                    new List<Deployment__c>{ deploymentWillBeRedirected }
                );
                update decision.getRecords();
            }
            return (deploymentInterface != null && pageMessagesMap.isEmpty())
                ? deploymentInterface.goToNextStep(deploymentWillBeRedirected, deploymentActionName)
                : null;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to redirect previous step
     *
     * @see DeploymentInterface
     * @return
     */
    public PageReference goToPreviousStep() {
        try {
            return deploymentInterface != null ? deploymentInterface.goToPreviousStep(deployment) : null;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }
    }

    /**
     * It is used to update records before starting the deployment
     * For Steps: Status will be: Not started and Order field will be populated, if operation is validation step will be updated with CheckOnly__c checkbox
     * For Destination Org: Status will be: "Not started"
     * For Deployment Job: Status will be: "Pending"
     */
    public void deploymentDMLs() {
        // setup the save point for rollback
        Savepoint sp;
        if (!Test.isRunningTest()) {
            sp = Database.setSavepoint();
        }
        try {
            if (pageMessagesMap.isEmpty()) {
                // Deployment DML
                deployment.Status__c = 'Scheduled';
                deployment.Schedule__c = 'Deploy now';
                deployment.Date__c = System.now();
                deployment.Deployment_command_sent__c = null;
                // Strip fields that are not updatable
                //SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Deployment__c>{ deployment });
                //update decision.getRecords();
                Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);

                // Step DML
                List<Step__c> deploymentSteps = new List<Step__c>();
                for (Step__c step : getDeploymentSteps()) {
                    if (step.Status__c == null || step.Status__c != NOT_STARTED || (String.isNotBlank(deploymentActionName))) {
                        step.Status__c = NOT_STARTED;
                        step.CheckOnly__c = (deploymentActionName == VALIDATION &&
                        deploymentInterface.getStepGeneralHeader() != Label.New_Data_Deployment);
                        deploymentSteps.add(step);
                    }
                }

                if (!deploymentSteps.isEmpty()) {
                    // Strip fields that are not updatable
                    //decision = Security.stripInaccessible(AccessType.UPDATABLE, deploymentSteps);
                    //update decision.getRecords();
                    Utilities.Secure_DML(deploymentSteps, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
                }

                // Deployment Job DML
                List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>();
                for (Deployment_Job__c deploymentJob : [
                    SELECT Id, Status__c, Deployed__c
                    FROM Deployment_Job__c
                    WHERE Step__r.Deployment__c = :deployment.Id
                    WITH SECURITY_ENFORCED
                ]) {
                    if (deploymentJob.Status__c == null || deploymentJob.Status__c != PENDING) {
                        deploymentJob.Status__c = PENDING;
                        deploymentJob.Deployed__c = 0;
                        deploymentJobs.add(deploymentJob);
                    }
                }

                if (!deploymentJobs.isEmpty()) {
                    // Strip fields that are not updatable
                    //decision = Security.stripInaccessible(AccessType.UPDATABLE, deploymentJobs);
                    //update decision.getRecords();
                    Utilities.Secure_DML(deploymentJobs, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
                }

                // Destination Org DML
                List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();
                for (Destination_Org__c dOrg : [
                    SELECT Id, Name, Status__c
                    FROM Destination_Org__c
                    WHERE Deployment__c = :deployment.Id
                    WITH SECURITY_ENFORCED
                ]) {
                    if (dOrg.Status__c == null || dOrg.Status__c != NOT_STARTED) {
                        dOrg.Status__c = NOT_STARTED;
                        destinationOrgs.add(dOrg);
                    }
                }

                if (!destinationOrgs.isEmpty()) {
                    // Strip fields that are not updatable
                    //decision = Security.stripInaccessible(AccessType.UPDATABLE, destinationOrgs);
                    //update decision.getRecords();
                    Utilities.Secure_DML(destinationOrgs, Utilities.DML_Action.UPD, schema.SObjectType.Destination_Org__c);
                }
            }
        } catch (Exception excp) {
            // roll everything back in case of error
            Database.rollback(sp);
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    /**
     * It is used to retrieve deployment step of deployment
     *
     * @return
     */
    public List<Step__c> getDeploymentSteps() {
        List<Step__c> steps = new List<Step__c>();
        try {
            steps = [
                SELECT Id, Commit_Name__c, Status__c, CheckOnly__c, Git_Repository__c, Commit_Id__c
                FROM Step__c
                WHERE Deployment__c = :deployment.Id AND (Type__c = :GIT_METADATA OR Type__c = :METADATA OR Type__c = :DATA_TEMPLATE)
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Step__c.getLabel()
                }
            );
        }
        return steps;
    }

    /**
     * It is used to return single step from deployment
     */
    public Step__c getDeploymentStepRecord() {
        List<Step__c> steps = getDeploymentSteps();
        return !steps.isEmpty() ? steps[0] : new Step__c();
    }

    /**
     * It is used to retrieve destination org to show as target in the overview page
     *
     * @return
     */
    public Destination_Org__c getDestinationOrg() {
        List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();
        try {
            destinationOrgs = [
                SELECT Id, To_Org__c, To_Org__r.Environment__r.Name, To_Org__r.Environment__r.Connection_Behavior__c
                FROM Destination_Org__c
                WHERE Deployment__c = :deployment.Id
                WITH SECURITY_ENFORCED
            ];
            return !destinationOrgs.isEmpty() ? destinationOrgs[0] : new Destination_Org__c();
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Destination_Org__c.getLabel()
                }
            );
        }
        return new Destination_Org__c();
    }

    /**
     * It is used to retrieve commit name to show as target in the overview page if selected source is "git"
     *
     * @return
     */
    public SObject getCommit() {
        SObject sobj = null;
        List<Step__c> steps = getDeploymentSteps();
        if (!steps.isEmpty() && steps[0].Commit_Name__c != null) {
            for (Git_Commit__c gitCommit : getGitCommits(steps[0].Commit_Name__c)) {
                sobj = gitCommit;
            }
            for (Git_Org_Commit__c gitOrgCommit : getGitOrgCommits(steps[0].Commit_Name__c)) {
                sobj = gitOrgCommit;
            }
        }
        return sobj;
    }

    /**
     * It is used to populate git commit records based on given name
     *
     * @return
     */
    private List<Git_Commit__c> getGitCommits(String commitName) {
        List<Git_Commit__c> gitCommits = new List<Git_Commit__c>();
        try {
            return gitCommits = [SELECT Id, Name FROM Git_Commit__c WHERE Name = :commitName WITH SECURITY_ENFORCED];
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Git_Commit__c.getLabel()
                }
            );
            return null;
        }
    }

    /**
     * It is used to populate git org commit records based on given name
     *
     * @return
     */
    private List<Git_Org_Commit__c> getGitOrgCommits(String commitName) {
        List<Git_Org_Commit__c> gitOrgCommits = new List<Git_Org_Commit__c>();
        try {
            return gitOrgCommits = [SELECT Id, Name FROM Git_Org_Commit__c WHERE Name = :commitName WITH SECURITY_ENFORCED];
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Git_Org_Commit__c.getLabel()
                }
            );
            return null;
        }
    }

    /**
     * It is used to calculate total credit usage for deployment
     *
     * @return
     */
    public Integer getCalculatedCredit() {
        if (String.isNotBlank(attId)) {
            Boolean isOrgToOrgDeployment = deployment.Deployment_Source_Type__c != null && deployment.Deployment_Source_Type__c == ORG;
            try {
                for (Attachment att : [SELECT Name, ParentId, Body FROM Attachment WHERE Id = :attId WITH SECURITY_ENFORCED]) {
                    String attBody = EncodingUtil.base64Decode(EncodingUtil.base64Encode(att.Body)).toString();
                    List<Object> mItems = (List<Object>) JSON.deserializeUntyped(attBody);
                    return isOrgToOrgDeployment ? mItems.size() : mItems.size() > 50 ? 50 : mItems.size() > 0 ? mItems.size() : 1;
                }
            } catch (System.QueryException exceptions) {
                pageMessagesMap.put(C_WARNING, new List<Object>{ exceptions.getMessage() });
            }
        }
        return 0;
    }

    /**
     * It is used to get all information of data template
     */
    public void getDataTemplateDetails() {
        dataTemplate = new Data_Template__c();
        String existingDataTemplateId = checkExistingDeploymentStep();

        List<Data_Template__c> dataTemplates;
        try {
            if (String.isNotBlank(existingDataTemplateId)) {
                dataTemplates = [
                    SELECT Id, Name, Template_Source_Org__c, Batch_Size__c, Max_Record_Limit__c, Main_Object__c
                    FROM Data_Template__c
                    WHERE Id = :existingDataTemplateId
                    WITH SECURITY_ENFORCED
                ];

                if (!dataTemplates.isEmpty()) {
                    dataTemplate = dataTemplates[0];
                }
            }
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(C_WARNING, new List<Object>{ exceptions.getMessage() });
        }
    }

    /**
     * It is used to check previous deployment step and returning the selected data template id
     */
    public String checkExistingDeploymentStep() {
        List<Step__c> steps = returnDateTemplateStep('');
        StepAttachmentDetails existingJson = new StepAttachmentDetails();
        if (!steps.isEmpty()) {
            existingJson = returnParsedValueOfDataJSONField(steps[0]);
        }
        return existingJson != null ? existingJson.dataTemplateId : '';
    }

    /**
     * It is used to return parsed value of the data_json__c field of step object
     */
    public StepAttachmentDetails returnParsedValueOfDataJSONField(Step__c step) {
        try {
            StepAttachmentDetails existingJson = (StepAttachmentDetails) JSON.deserialize(step.dataJson__c, StepAttachmentDetails.class);
            return existingJson;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to return step for data template deployment
     */
    public List<Step__c> returnDateTemplateStep(String stepId) {
        try {
            List<Step__c> steps = new List<Step__c>();
            if (String.isNotBlank(stepId)) {
                steps = [
                    SELECT Id, dataJson__c, Deployment__c
                    FROM Step__c
                    WHERE Id = :stepId AND Type__c = :DATA_TEMPLATE
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            } else {
                steps = [
                    SELECT Id, dataJson__c
                    FROM Step__c
                    WHERE Deployment__c = :deployment.Id AND Type__c = :DATA_TEMPLATE
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            return steps;
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Step__c.getLabel()
                }
            );
        }
        return new List<Step__c>();
    }

    /**
     * It is used to redirect user to relation template in a new tab
     */
    public PageReference openRelationTemplate() {
        String relTemplateId = ApexPages.currentPage().getParameters().get('relTemplateId');
        Id relationTemplateId = null;
        PageReference pReference = null;
        if (String.isNotBlank(relTemplateId)) {
            relationTemplateId = relTemplateId;
            pReference = new ApexPages.StandardController(relationTemplateId.getSobjectType().newSObject(relationTemplateId)).view();
            pReference.setRedirect(true);
        }
        return pReference;
    }

    /**
     * It is used to restart the deployment if validation or deployment fails
     *
     * @return
     */
    public PageReference restartDeployment() {
        try {
            if (pageMessagesMap.isEmpty()) {
                DeployAPI.deploy(deployment.Id, UserInfo.getSessionId());
            }
        } catch (Exception exceptions) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ exceptions.getMessage() });
            return null;
        }

        PageReference pReference = Page.DW_Deployment;
        pReference.getParameters().put(C_ID, deployment.Id);
        pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
        String newDeploymentActionName = deployment.Deployment_Last_Step__c.toLowerCase() == C_DSW_DEPLOYMENT_PAGE
            ? deploymentActionName
            : C_DEPLOYMENT;
        pReference.getParameters().put('deploymentActionType', newDeploymentActionName);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to populate org credential or git commit records
     */
    public class SourceWrapper implements Comparable {
        public Boolean isSelected { get; set; }
        public Org__c orgRecord { get; set; }
        public String commitName { get; set; }
        public String commitId { get; set; }
        public String commitMessage { get; set; }
        public String branchName { get; set; }
        public String gitRepository { get; set; }
        public String gitRepositoryName { get; set; }
        public String commitDate { get; set; }
        public Data_Template__c template { get; set; }

        public SourceWrapper(
            Boolean isSel,
            Org__c org,
            String cName,
            String cId,
            String cMessage,
            String bName,
            String rId,
            String rName,
            String cDate,
            Data_Template__c dTemplate
        ) {
            this.isSelected = isSel;
            this.orgRecord = org;
            this.commitName = cName;
            this.commitId = cId;
            this.commitMessage = cMessage;
            this.branchName = bName;
            this.gitRepository = rId;
            this.gitRepositoryName = rName;
            this.commitDate = cDate;
            this.template = dTemplate;
        }

        public Integer compareTo(Object obj) {
            return ((SourceWrapper) obj).isSelected ? 1 : 0;
        }
    }

    public class StepAttachmentDetails {
        public String dataTemplateId { get; set; }
        public String dataTemplateName { get; set; }
        public String filterLogic { get; set; }
        public Boolean filterOverride { get; set; }
        public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }
    }
}