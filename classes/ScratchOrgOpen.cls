/**
 * @description this page serves as an intermediary loading page for when a user opens a scratch org from the DX
 * Operations page. The page will show a loading icon while retrieve the scratch org information and signing the user
 * into the selected scratch org.
 */
public with sharing class ScratchOrgOpen {
    private String cJobId = '';
    public String soId { get; set; }
    public String slockerMessage { get; set; }
    public Boolean copadoJobFinished { get; set; }
    private Boolean canOpen = false;

    public ScratchOrgOpen() {
        slockerMessage = 'Loading...';
        Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(DXLabel.OPEN_ORG, soId);
        if (cn != null) {
            cJobId = cn.Matching_Key__c;
        }
    }

    /**
     * @description this method starts a new job and creates Copado Notifications to track the progress in the backend.
     * Once the job finishes, the user is redirected to the scratch org's home page.
     *
     * @return a reference to the scratch org's home page.
     */
    public PageReference rScratchOrgJob() {
        PageReference pr = null;
        try {
            if (String.isNotBlank(soId)) {
                try {
                    List<Org__c> org = [SELECT OwnerId, CreatedById FROM Org__c WHERE Id = :soId WITH SECURITY_ENFORCED];
                    if (!org.isEmpty() && (UserInfo.getUserId() != org[0].OwnerId && UserInfo.getUserId() != org[0].CreatedById)) {
                        addPageMessage(ApexPages.Severity.ERROR, 'Only Owner or Creator can open this Org');
                        copadoJobFinished = true;
                        canOpen = false;
                    } else if (org.isEmpty()) {
                        addPageMessage(ApexPages.Severity.ERROR, 'Org Credential does not exist or is not accessible');
                        copadoJobFinished = true;
                        canOpen = false;
                    } else {
                        canOpen = true;
                    }
                } catch (QueryException queryEx) {
                    addPageMessage(ApexPages.Severity.ERROR, queryEx.getMessage());
                }
            } else {
                // This is only possible from User Story page, since from Org Credential page Id will never be empty
                copadoJobFinished = true;
                addPageMessage(ApexPages.severity.ERROR, Label.ORG_CREDENTIAL_NOT_COMPLETED);
            }
            if (!canOpen) {
                return pr;
            }
            if (String.isBlank(cJobId) && String.isNotBlank(soId)) {
                String s = SfdxAPI.orgOpen(soId);
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(
                    s,
                    CopadoNotificationHelper.copadoFrontAPIreponse.class
                );
                if (r.copadoJobId != null && r.copadoJobId != '') {
                    cJobId = r.copadoJobId;
                    if (
                        !sObjectType.Copado_Notification__c.fields.Name.isCreateable() ||
                        !sObjectType.Copado_Notification__c.fields.ParentId__c.isCreateable() ||
                        !Schema.sObjectType.Copado_Notification__c.fields.Type__c.isCreateable() ||
                        !Schema.sObjectType.Copado_Notification__c.fields.Matching_Key__c.isCreateable() ||
                        !Schema.sObjectType.Copado_Notification__c.fields.status__c.isCreateable()
                    ) {
                        return null;
                    }
                    Copado_Notification__c newCN = CopadoNotificationHelper.instCopadoNotification(
                        CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                        soId,
                        DXLabel.OPEN_ORG,
                        cJobId
                    );
                    Utilities.Secure_DML(newCN, Utilities.DML_Action.INS, Sobjecttype.Copado_Notification__c);
                    copadoJobFinished = false;
                } else if (r.error != null && r.error != '') {
                    copadoJobFinished = true;
                    addPageMessage(ApexPages.severity.ERROR, r.error);
                } else if (r.ok == 'AccessUrl Valid') {
                    pr = checkURLRedirectionAttack();
                    copadoJobFinished = true;
                }
            } else if (cJobId != '') {
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if (c.isFinished__c != null && c.isFinished__c) {
                    if (c.isSuccess__c) {
                        pr = checkURLRedirectionAttack();
                        if (pr != null) {
                            pr.setRedirect(true);
                        }
                        copadoJobFinished = true;
                    } else {
                        addPageMessage(
                            ApexPages.severity.ERROR,
                            c.Message__c != null ? c.Message__c : c.status__c != null ? c.status__c : 'Could not open scratch org'
                        );
                        copadoJobFinished = true;
                    }
                } else {
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }
            } else {
                addPageMessage(ApexPages.severity.ERROR, 'Org Id Invalid');
            }
        } catch (Exception e) {
            addPageMessage(ApexPages.severity.ERROR, e.getMessage());
            copadoJobFinished = true;
        }
        return pr;
    }

    /**
     * @description this method verifies that the scratch org's access URL is correct in order to avoid any changes to
     * the target URL while being redirected to the scratch org's home page.
     *
     * @return a URL reference to the correct scratch org's page.
     */
    private PageReference checkURLRedirectionAttack() {
        PageReference pr;
        List<Attachment> att = new List<Attachment>();
        try {
            att = [
                SELECT Body
                FROM Attachment
                WHERE ParentId = :soId AND Name = 'AccessUrl.txt'
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
            ];
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
        if (!att.isEmpty()) {
            String secureURL = EncodingUtil.urlDecode(DeployAPI.decryptAPIKey(att[0].Body.toString()), 'UTF-8');

            Set<String> whiteListedDomains = new Set<String>();
            if (ApexPages.currentPage() != null) {
                URL currentURL = new URL('https://' + ApexPages.currentPage().getUrl());
                whiteListedDomains.add(currentURL.getHost());
            }
            String urlHost = new URL(secureURL).getHost();
            if (urlHost.endsWith('salesforce.com')) {
                whiteListedDomains.add(urlHost);
            }

            whiteListedDomains.add('www.salesforce.com');
            if (secureURL == null || !whiteListedDomains.contains(new URL(secureURL).getHost())) {
                pr = new PageReference('/home/home.jsp');
            } else {
                pr = new PageReference(secureURL);
            }
        }
        return pr;
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