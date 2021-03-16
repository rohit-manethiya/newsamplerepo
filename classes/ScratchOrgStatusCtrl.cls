/**
 * @description this component controller tracks status changes in a scratch org, such as the current status or the
 * org deletion status.
 */
public with sharing class ScratchOrgStatusCtrl extends ScratchOrgWizardPageBase {
    private AbstractDXOrg dxOrgService;
    private String copadoJobId = '';
    private Id repositoryId;
    public Id scratchOrgId { get; set; }
    public Id selectedOrgId {
        get {
            if(String.isBlank(selectedOrgId) && scratchOrgId != null) {
                selectedOrgId = scratchOrgId;
                orgChanged();
                setRepositoryId();
                dxOrgService.setOrgId(scratchOrgId);
            }
            return selectedOrgId;
        }
        set;
    }
    public Datetime lastStatusCheck { get; set; }
    public String slockerMessage { get; set; }
    public List<SelectOption> scratchOrgOptions {
        get {
            if(scratchOrgOptions == null) {
                scratchOrgOptions = new List<SelectOption>();
                scratchOrgOptions.add(new SelectOption('', 'Please Select a Scratch Org'));
                try {
                    List<Org__c> orgCredentials = getOrgCredentials();
                    for(Org__c orgCredential : orgCredentials) {
                        scratchOrgOptions.add(new SelectOption(orgCredential.Id, orgCredential.Name));
                    }
                } catch(QueryException queryEx) {
                    addPageMessage(ApexPages.Severity.WARNING,Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
                }
            }
            return scratchOrgOptions;
        }
        set;
    }
    public Boolean copadoJobFinished { get; set; }
    public Boolean hasRepository {
        get {
            return String.isNotBlank(repositoryId);
        }
    }
    public Boolean isScratchOrg {
         get {
             return soOrg != null && soOrg.Org_Type__c == 'Scratch Org';
         }
    }
    public Org__c soOrg { get; set; }

    public ScratchOrgStatusCtrl(ApexPages.StandardController stdCtrl) {}

    public ScratchOrgStatusCtrl() {
        selectedOrgId = scratchOrgId;
        copadoJobId = '';
        dxOrgService = DXOrgFactory.getInstance('ScratchOrgService');
    }

    /**
     * @description this method retrieves and sets the repository linked to the select scratch org's Environment__c
     * record.
     */
    private void setRepositoryId() {
        List<Deployment_Flow_Step__c> flowSteps;
        try {
            flowSteps = [
                    SELECT Deployment_Flow__r.Git_Repository__c
                    FROM Deployment_Flow_Step__c
                    WHERE Deployment_Flow__r.Git_Repository__c != null
                    AND Source_Environment__c = :soOrg.Environment__c
                    WITH SECURITY_ENFORCED
            ];
        } catch(QueryException queryEx) {
            addPageMessage(ApexPages.Severity.WARNING,Deployment_Flow_Step__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        if(!flowSteps.isEmpty()) {
            repositoryId = flowSteps[0].Deployment_Flow__r.Git_Repository__c;
        }
    }

    /**
     * @description this method populates a list of available scratch org credential options for the user to choose.
     *
     * @return a list of available scratch org credentials.
     */
    private List<Org__c> getOrgCredentials() {
        String queryString = 'SELECT Name, Org_Type__c, Is_Developer_Hub_Org__c, Scratch_Org_Status__c FROM Org__c';
        queryString += ' WHERE Org_Type__c = \'Scratch Org\'';
        queryString += ' WITH SECURITY ENFORCED';
        return Database.query(queryString);
    }

    /**
     * @description this method tracks changes to the current scratch org selection and refreshes the org status
     * information each time the user selects a new org.
     */
    public void orgChanged() {
        lastStatusCheck = null;
        if(String.isNotBlank(selectedOrgId)) {
            try {
                soOrg = [
                        SELECT Name, Org_Type__c, Scratch_Org_Expiration_Date__c, Developer_Hub_Org__c, Environment__c, is_Developer_Hub_Org__c,
                        (SELECT LastModifiedDate FROM Attachments WHERE Name = 'SourceStatus' ORDER BY LastModifiedDate DESC LIMIT 1)
                        FROM Org__c
                        WHERE Id = :selectedOrgId
                        WITH SECURITY_ENFORCED
                ];
            } catch(QueryException queryEx) {
                addPageMessage(ApexPages.Severity.WARNING,Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            }
            if(!soOrg.Attachments.isEmpty()) {
                lastStatusCheck = soOrg.Attachments[0].LastModifiedDate;
            }
        } else {
            soOrg = null;
        }
    }

    /**
     * @description a getter for the isActive variable.
     *
     * @return a flag indicating if the currently selected scratch org is still arctive or not.
     */
    public Boolean getIsActive() {
        return isScratchOrg && soOrg.Scratch_Org_Expiration_Date__c > Datetime.now();
    }

    /**
     * @description this method tracks the status of a callout operation performed on a selected scratch org. It uses
     * the Copado_Notification__c object to display status messages on the user screen.
     */
    public void requestStatus() {
        ApexPages.getMessages().clear();
        copadoJobFinished = false;
        if(soOrg == null) {
            orgChanged();
        }
        try {
            Copado_Notification__c notification = CopadoNotificationHelper.qInProgressCopadoNotification(DXLabel.SOURCE_STATUS, soOrg.Id);
            if(notification != null) {
                copadoJobId = notification.Matching_Key__c;
            } else {
                copadoJobId = '';
            }
        } catch(Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
        }
        retrieveStatus();
    }

    /**
     * @description this method uses the ScratchOrgService class to send a callout to the backend that will retrieve
     * the latest status information about the selected scratch org.
     */
    public void retrieveStatus() {
        try {
            if(copadoJobId == '' && soOrg.Id != null) {
                String responseBody;
                dxOrgService.setOrgId(soOrg.Id);
                if(dxOrgService instanceof ScratchOrgService) {
                    responseBody = ((ScratchOrgService)dxOrgService).getSourceStatus(repositoryId, DXLabel.PROJECT_BRANCH + String.valueOf(soOrg.Id).substring(3,15));
                } else {
                    throw new UnsupportedOperationException(Label.UnSupportedOperation);
                }
                if(String.isNotBlank(responseBody)) {
                    CopadoNotificationHelper.copadoFrontAPIreponse frontAPIResponse = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(responseBody, CopadoNotificationHelper.copadoFrontAPIreponse.class);
                    if(String.isNotBlank(frontAPIResponse.copadoJobId)) {
                        copadoJobFinished = false;
                        copadoJobId = frontAPIResponse.copadoJobId;
                    } else if(String.isNotBlank(frontAPIResponse.error)) {
                        copadoJobFinished = true;
                        addPageMessage(ApexPages.Severity.ERROR, frontAPIResponse.error);
                    }
                } else {
                    addPageMessage(ApexPages.Severity.ERROR, 'No response');
                }
            } else {
                Copado_Notification__c notification = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(copadoJobId);
                if(notification != null) {
                    if(notification.isFinished__c) {
                        copadoJobFinished = true;
                        if(notification.isSuccess__c) {
                            addPageMessage(ApexPages.Severity.CONFIRM, 'Status Retrieved Successfully');
                            copadoJobId = '';
                        } else {
                            addPageMessage(ApexPages.Severity.ERROR, notification.Message__c);
                        }
                    } else {
                        copadoJobFinished = false;
                        slockerMessage = notification.Status__c;
                    }
                }
            }
        } catch(Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            copadoJobFinished = true;
        }
    }

    /**
     * @description a utility method for displaying messages on the parent page.
     *
     * @param severity is the ApexPages.Severity enum value for the type of message.
     * @param message is the actual message to be shown to the user.
     */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}