/**
 * @description this class and its component are responsible for all the basic scratch org-related operations, such as
 * retrieving the org details, generating a password, or deleting the org. These operations are performed through the
 * ScratchOrgService entity.
 * @see AbstractDXOrg
 * @see ScratchOrgService
 */
public with sharing class ScratchOrgDisplayController {
    private AbstractDXOrg dxOrgService;
    public ScratchOrgDetail orgDetails { get; set; }
    public Boolean showDisplay { get; set; }
    public Boolean showDisplayButton { get; set; }
    public Boolean showPassword { get; set; }
    public Boolean showPasswordButton { get; set; }
    public Boolean showErrorButton { get; set; }
    public Boolean showOwnerOperations { get; set; }
    public Id scratchOrgId {
        get;
        set {
            if (value == null) {
                return;
            }
            scratchOrgId = value;
            initDefaults();
            Boolean success = checkIfCurrentUserHasCredentials();
            if (!success) {
                return;
            }
            success = success && initOrgDetailAttachments();
            if (!success) {
                return;
            }
            success = success && initIdeDetailAttachments();
            if (!success) {
                return;
            }
            initDxLoadMetadataErrorAttachments();
        }
    }

    /**
     * @description initializes controller variables with default values and gets an instance of ScratchOrgService
     * using a Static Factory pattern.
     * @see DXOrgFactory
     * @see ScratchOrgService
     */
    private void initDefaults() {
        showDisplay = true;
        showDisplayButton = true;
        showOwnerOperations = true;
        orgDetails = new ScratchOrgDetail();
        dxOrgService = DXOrgFactory.getInstance('ScratchOrgService');
        dxOrgService.setOrgId(scratchOrgId);
    }

    /**
     * @description this method verifies that a user has access to at least one Org Credential for the selected
     * scratch org. Otherwise, an error is displayed on the page.
     *
     * @return a flag indicating if the current user has access to the selected scratch org's credentials.
     */
    private Boolean checkIfCurrentUserHasCredentials() {
        Boolean success = true;
        try {
            List<Org__c> userOrgs = [
                SELECT OwnerId, CreatedById
                FROM Org__c
                WHERE Id = :scratchOrgId AND (OwnerId = :UserInfo.getUserId() OR CreatedById = :UserInfo.getUserId())
                WITH SECURITY_ENFORCED
            ];
            Boolean ownerIsCurrent = !userOrgs.isEmpty();
            showPassword = ownerIsCurrent;
            showOwnerOperations = ownerIsCurrent;
            showPasswordButton = ownerIsCurrent;
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            success = false;
        }
        return success;
    }

    /**
     * @description attempts to retrieve the scratch org details from the org credential's attachments to display them
     * on the screen for the user.
     *
     * @return a flag indicating if the retrieval was successful or not.
     */
    private Boolean initOrgDetailAttachments() {
        Boolean success = true;
        try {
            List<Attachment> displayAttList = new List<Attachment>();
            displayAttList = getOrgAttachmentsByName('OrgDetails');
            if (!displayAttList.isEmpty()) {
                Map<String, Object> resultParser = (Map<String, Object>) JSON.deserializeUntyped(
                    DeployAPI.decryptAPIKey(displayAttList[0].Body.toString())
                );
                orgDetails.accessToken = String.valueOf(resultParser.get('accessToken'));
                orgDetails.connectedStatus = [SELECT Scratch_Org_Status__c FROM Org__c WHERE Id = :scratchOrgId WITH SECURITY_ENFORCED LIMIT 1]
                    .Scratch_Org_Status__c;
                orgDetails.id = String.valueOf(resultParser.get('id'));
                orgDetails.username = String.valueOf(resultParser.get('username'));
                orgDetails.instanceURL = String.valueOf(resultParser.get('instanceUrl'));
                orgDetails.accessToken = 'SESSION ID REMOVED';
                showDisplayButton = false;
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR,  Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            success = false;
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            showDisplay = false;
        } 
        return success;
    }

    /**
     * @description attempts to retrieve the scratch org's IDE details from the org credential's attachments to
     * display them on the screen for the user.
     *
     * @return a flag indicating if the retrieval was successful or not.
     */
    private Boolean initIdeDetailAttachments() {
        Boolean success = true;
        try {
            List<Attachment> ideAttList = new List<Attachment>();
            ideAttList = getOrgAttachmentsByName('IdeDetails');
            if (!ideAttList.isEmpty()) {
                Map<String, Object> resultParser = (Map<String, Object>) JSON.deserializeUntyped(
                    DeployAPI.decryptAPIKey(ideAttList[0].Body.toString())
                );
                orgDetails.password = String.valueOf(resultParser.get('password'));
                showPasswordButton = false;
                showDisplay = true;
            }
        } catch (QueryException queryEx) {
           	addPageMessage(ApexPages.Severity.ERROR,  Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            success = false;
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            showPassword = false;
        } 
        return success;
    }

    /**
     * @description attempts to retrieve the scratch org's DXLoadMetadataError file from the org credential's
     * attachments to display the information on the screen for the user.
     *
     * @return a flag indicating if the retrieval was successful or not.
     */
    private Boolean initDxLoadMetadataErrorAttachments() {
        Boolean success = true;

        List<Attachment> errorAttList = new List<Attachment>();
        try {
            errorAttList = getOrgAttachmentsByName('DxLoadMetadataError');
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            success = false;
        }
        if (!errorAttList.isEmpty()) {
            showErrorButton = true;
        }

        return success;
    }

    /**
     * @description gets a list of attachments belonging to the selected scratch org by matching the name.
     *
     * @param name is the name of the attachment of interest.
     *
     * @return a list of one Attachment record that belongs to the selected scratch org credential.
     */
    private List<Attachment> getOrgAttachmentsByName(String name) {
        return [
            SELECT Body, Name
            FROM Attachment
            WHERE ParentId = :scratchOrgId AND Name = :name
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    /**
     * @description sends a command to the backend to delete the selected scratch org. This is achieved through the
     * ScratchOrgService entity.
     * @see ScratchOrgService
     */
    public void deleteScratchOrg() {
        if (dxOrgService instanceof ScratchOrgService) {
            ((ScratchOrgService) dxOrgService).deleteOrg();
        } else {
            throw new UnsupportedOperationException(Label.UnSupportedOperation);
        }
    }

    /**
     * @description sends a command to the backend to retrieve the details of the selected scratch org. This is
     * achieved through the ScratchOrgService entity.
     * @see ScratchOrgService
     */
    public void orgDetails() {
        if (dxOrgService instanceof ScratchOrgService) {
            ((ScratchOrgService) dxOrgService).getOrgDetails();
        } else {
            throw new UnsupportedOperationException(Label.UnSupportedOperation);
        }
    }

    /**
     * @description sends a command to the backend to generate a password for the selected scratch org. This is
     * achieved through the ScratchOrgService entity.
     * @see ScratchOrgService
     */
    public void generatePassword() {
        if (dxOrgService instanceof ScratchOrgService) {
            ((ScratchOrgService) dxOrgService).generatePassword();
        } else {
            throw new UnsupportedOperationException(Label.UnSupportedOperation);
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