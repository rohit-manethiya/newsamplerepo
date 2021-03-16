/**
 * It is main controller for DW_Deployment page
 */
public with sharing class DW_DeploymentExtension extends DeploymentHelper {
    // Non Constants
    @TestVisible
    private String copadoNotificationId;
    @TestVisible
    private List<Copado_Notification__c> copadoNotificationList;
    @TestVisible
    private String parentId;
    public Boolean startActionPoller { get; set; }
    public Boolean enableCancelDeploymentButton { get; set; }
    public String currentStatusOfAction { get; set; }
    public Map<String, Set<Object>> componentMessagesMap {
        get {
            if (null == componentMessagesMap) {
                componentMessagesMap = new Map<String, Set<Object>>();
            }
            return componentMessagesMap;
        }
        set;
    }

    // Constants
    private final String C_STATUS = 'status';
    private final String C_STATUS_ERROR = 'Completed with Errors';
    private final String C_STATUS_SUCCESS = 'Completed Successfully';
    private final String IN_PROGRESS = 'In Progress';
    private final String ERROR = 'Error';
    private final String SUCCESSFUL = 'Successful';
    private final String C_DSW_DEPLOYMENT_PAGE = 'dw_deployment';

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_DeploymentExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
        startActionPoller = false;
        enableCancelDeploymentButton = false;
        List<Step__c> stepList = getDeploymentSteps();
        Boolean statusActionInProgress =
            !stepList.isEmpty() &&
            stepList[0].Status__c == C_STATUS_ERROR &&
            deployment.Deployment_Last_Step__c.toLowerCase() == C_DSW_DEPLOYMENT_PAGE;
        currentStatusOfAction = statusActionInProgress ? ERROR : IN_PROGRESS;
    }

    /**
     * It is used to initialize correct poller for showing the message until the job is done
     */
    public void initPoller() {
        startActionPoller = true;
        checkCancelDeploymentButton();
        String message = Label.Initializing;
        componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
    }

    /**
     * This is used to find latest copado notification record to populate necessary information to the user.
     * @return
     */
    public PageReference copadoNotificationProcesses() {
        parentId = String.isBlank(parentId) ? getDeploymentJobId() : parentId;
        checkCancelDeploymentButton();
        String notificationType = 'Deployer';
        String copadoNotificationName = CopadoNotificationHelper.PROGRESS_STATUS_COPADO;

        try {
            String deploymentStatus = [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id LIMIT 1].Status__c;
            if (deploymentStatus == C_STATUS_ERROR) {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_WARNING,
                    new List<String>{ C_STATUS_ERROR },
                    componentMessagesMap
                );
                startActionPoller = false;
                currentStatusOfAction = ERROR;
                return null;
            } else if (deploymentStatus == C_STATUS_SUCCESS) {
                startActionPoller = false;
                currentStatusOfAction = SUCCESSFUL;
                if (String.isNotBlank(deploymentActionName) && deploymentActionName == C_DEPLOYMENT) {
                    if (pageMessagesMap.isEmpty()) {
                        upsertDeployment(true);
                        return goToNextStep();
                    }
                }
            }

            if (Schema.SObjectType.Copado_Notification__c.isAccessible() && Schema.SObjectType.Copado_Notification__c.isQueryable()) {
                if (copadoNotificationList == null || copadoNotificationList.isEmpty()) {
                    copadoNotificationList = [
                        SELECT Id, status__c, isSuccess__c, isFinished__c
                        FROM Copado_Notification__c
                        WHERE
                            Type__c = :notificationType
                            AND isSuccess__c = false
                            AND isFinished__c = false
                            AND Name = :copadoNotificationName
                            AND ParentId__c = :parentId
                            AND CreatedById = :UserInfo.getUserId()
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];

                    if (!copadoNotificationList.isEmpty()) {
                        copadoNotificationId = copadoNotificationList[0].Id;
                    }
                } else {
                    if (String.isNotBlank(copadoNotificationId)) {
                        copadoNotificationList = [
                            SELECT status__c, isSuccess__c, isFinished__c
                            FROM Copado_Notification__c
                            WHERE Id = :copadoNotificationId
                            LIMIT 1
                        ];
                    }
                }
                if (!copadoNotificationList.isEmpty() && !copadoNotificationList[0].isFinished__c) {
                    componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                        C_INFO,
                        new List<String>{ copadoNotificationList[0].status__c },
                        componentMessagesMap
                    );
                    return null;
                }
            } else {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_WARNING,
                    new List<String>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        ' ' +
                        Schema.SObjectType.Copado_Notification__c.getLabel()
                    },
                    componentMessagesMap
                );
                return null;
            }
        } catch (Exception ex) {
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_ERROR,
                new List<String>{ ex.getMessage() },
                componentMessagesMap
            );
            return null;
        }
        if (
            !copadoNotificationList.isEmpty() &&
            copadoNotificationList[0].status__c != null &&
            copadoNotificationList[0].status__c.contains(C_DONE) &&
            copadoNotificationList[0].isFinished__c
        ) {
            if (copadoNotificationList[0].isSuccess__c) {
                startActionPoller = false;
                currentStatusOfAction = SUCCESSFUL;
                if (String.isNotBlank(deploymentActionName) && deploymentActionName == C_DEPLOYMENT) {
                    if (pageMessagesMap.isEmpty()) {
                        upsertDeployment(true);
                        return goToNextStep();
                    }
                }
                return null;
            } else {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_WARNING, new List<String>{ ' ' }, componentMessagesMap);
                startActionPoller = false;
                currentStatusOfAction = ERROR;
                return null;
            }
        } else {
            String message = Label.Initializing;
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
            return null;
        }
    }

    /**
     * It is used to retrieve deployment job id for parent Id to use at copado notification record
     *
     * @return
     */
    public String getDeploymentJobId() {
        Deployment_Job__c deploymentJob = getDeploymentJob();
        return (deploymentJob != null && deploymentJob.Id != null) ? deploymentJob.Id : '';
    }

    /**
     * It is used to retrieve deployment job based on step
     *
     * @return
     */
    private Deployment_Job__c getDeploymentJob() {
        List<Deployment_Job__c> deploymentJobList = new List<Deployment_Job__c>();
        if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            deploymentJobList = [
                SELECT Id, Status__c, Async_Job_ID__c, Destination_Org__r.To_Org__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :deployment.Id
                LIMIT 1
            ];
        } else {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Job__c.getLabel() }
            );
        }
        return !deploymentJobList.isEmpty() ? deploymentJobList[0] : new Deployment_Job__c();
    }

    /**
     * It is used to get attachment related to deployment job to render "Cancel Deployment" button
     */
    public void checkCancelDeploymentButton() {
        try {
            List<Attachment> attachmentList = new List<Attachment>();
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                attachmentList = [
                    SELECT Id, Body
                    FROM Attachment
                    WHERE ParentId = :getDeploymentJobId() AND Name = :'DEPLOYMENT_STATUS_COPADO'
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];

                if (!attachmentList.isEmpty()) {
                    String body = attachmentList[0].Body.toString();
                    Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(body);

                    if (!fullMap.isEmpty() && fullMap.containsKey(C_STATUS)) {
                        if (fullMap.get(C_STATUS) == IN_PROGRESS.replaceAll(' ', '') || fullMap.get(C_STATUS) == PENDING) {
                            enableCancelDeploymentButton = true;
                        }
                    }
                }
            } else {
                pageMessagesMap.put(
                    C_WARNING,
                    new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Attachment.getLabel() }
                );
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return;
        }
    }

    /**
     * It is used to cancel deployment and go back to overview step
     */
    public void cancelDeployment() {
        try {
            HttpRequest req = new HttpRequest();
            Deployment_Job__c dj = getDeploymentJob();
            String orgId = dj.Destination_Org__r.To_Org__c;
            String asyncJobId = dj.Async_Job_ID__c;
            String jobId = dj.Id;
            Settings sttng = new Settings();
            String url = sttng.urlBase + 'cancelDeployment/' + orgId + '/' + asyncJobId + sttng.urlParameters + '&jobId=' + jobId;
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'text/json');
            req.setHeader('userId', UserInfo.getUserId());
            req.setHeader('orgId', UserInfo.getOrganizationId());
            req.setHeader('token', DeployAPI.getAuthToken());
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return;
        }
    }

    /**
     * It is used to return to DW_Overview page after cancelDeployment job is called.
     * It need to update deployment.Deployment_Last_Step__c with "DW_Overview"
     *
     * @return
     */
    public PageReference goToOverviewPage() {
        if (pageMessagesMap.isEmpty()) {
            try {
                deployment.Deployment_Last_Step__c = 'DW_Overview';
                Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);
            } catch (Exception excp) {
                pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
                return null;
            }
        }
        PageReference pReference = Page.DW_Overview;
        pReference.getParameters().put(C_ID, deployment.Id);
        pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
        pReference.setRedirect(true);
        return pageMessagesMap.isEmpty() ? pReference : null;
    }

    /**
     * It is used to count messages size in the list, so at the component it will be used to render icons and spinner
     *
     * @return
     */
    public Integer getComponentMessageSize() {
        Integer listSize = 0;
        for (String severity : componentMessagesMap.keySet()) {
            listSize += componentMessagesMap.get(severity).size();
        }
        return listSize;
    }

    /**
     * It is used to go back to source step if validation or deployment fails
     * First update the deployment
     *
     * @return
     */
    public PageReference goToSourceStep() {
        try {
            deployment.Deployment_Last_Step__c = 'DW_Source';
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }

        PageReference pReference = Page.DW_Source;
        pReference.getParameters().put(C_ID, deployment.Id);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to go back to select change step if validation or deployment fails
     *
     * @return
     */
    public PageReference goToSelectChangesStep() {
        Boolean isMetadataDeployment = deploymentInterface.getStepGeneralHeader() != Label.New_Data_Deployment;
        try {
            deployment.Deployment_Last_Step__c = isMetadataDeployment ? 'DW_SelectChanges' : 'DW_SelectDataTemplate';
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.SObjectType.Deployment__c);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }

        PageReference pReference = isMetadataDeployment ? Page.DW_SelectChanges : Page.DW_SelectDataTemplate;
        pReference.getParameters().put(C_ID, deployment.Id);
        if (isMetadataDeployment) {
            pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**º
     * It is used to go back to overview step if validation success
     *
     * @return
     */
    public PageReference goToOverviewStep() {
        try {
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPS, schema.SObjectType.Deployment__c);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }

        PageReference pReference = Page.DW_Overview;
        pReference.getParameters().put(C_ID, deployment.Id);
        pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to update step Check_Only__c chekcbox to false to quick deploy after successful validation
     *
     * @return
     */
    public void updateStepForDeployment() {
        pageMessagesMap.clear();
        deploymentActionName = C_DEPLOYMENT;
        deploymentDMLs();
    }
}