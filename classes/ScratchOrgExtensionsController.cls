/**
 * @description this class and its component are responsible for the configuration of deployment extensions to a
 * scratch org. Deployment extensions are configurable deployment templates that can be used to move non-related
 * components to an org by using a Deployment__c record with deployment steps under it.
 */
public with sharing class ScratchOrgExtensionsController extends ScratchOrgWizardComponentBase {
    private Map<Id, Step__c> currentStepMap = new Map<Id, Step__c>();
    private List<Attachment> currentStepDetails = new List<Attachment>();
    private final String STEPSONLY = 'stepsOnly';
    private final String C_TRUE = 'true';
    private final String C_ID = 'id';
    public Id selectedDeploymentId { get; set; }
    public Id sourceOrgId { get; set; }
    public String sourceOrgName { get; set; }
    public String editingDeployment { get; set; }
    public Boolean appChangesToSelectedTemplate { get; set; }
    public Boolean editMode { get; set; }
    public PageReference pageRef { get; set; }
    public List<SelectOption> deploymentList { get; set; }

    public ScratchOrgExtensionsController() {
        resetDeploymentInfoList();
        initExtensionPrep();
    }

    /**
     * @description resets all the controller variables in this component.
     */
    public void initExtensionPrep() {
        selectedDeploymentId = null;
        deploymentList = new List<SelectOption>();
        sourceOrgName = '';
        sourceOrgId = null;
        appChangesToSelectedTemplate = false;
        pageRef = null;
        editMode = false;
    }

    /**
     * @description this runs all the selected deployment extensions against the target org. It sends a callout to the
     * backend using the DeployAPI utility and executes each deployment sequentially.
     */
    public void executeSteps() {
        if (getDeploymentInfoList().isEmpty()) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Prepare_At_Least_One_Extension_To_Deploy);
            return;
        }
        Set<Id> deploymentIds = getDeploymentIdsFromDeploymentInformationList();
        if (!deploymentIds.isEmpty()) {
            if (getComponentMode() == 'add') {
                if (getPageController() instanceof DXOperationController) {
                    ((DXOperationController) getPageController()).selectedAction = 'exs';
                }
            }
            DeployAPI.deploy(new List<Id>(deploymentIds), '');
        } else {
            addPageMessage(ApexPages.Severity.ERROR, Label.Extension_Deployments_Not_Found);
        }
    }

    /**
     * @description gets a list of available deployment templates whose source org is the one selected by the user in
     * the Extensions form.
     */
    public void populateDeployments() {
        deploymentList = new List<SelectOption>();
        deploymentList.add(new SelectOption('', Label.NONE_SELECTED));
        editMode = false;
        //TODO: THE SOURCE ORG ID IS NOT GETTING PASSED WHEN THE LOOKUP POPUP IS NOT OPENED
        if (String.isNotBlank(sourceOrgId)) {
            try {
                for (Deployment__c deployment : [
                    SELECT Name, (SELECT Id FROM Destination_Orgs__r)
                    FROM Deployment__c
                    WHERE From_Org__c = :sourceOrgId AND Promotion__c = null AND Status__c = 'Draft'
                    WITH SECURITY_ENFORCED
                ]) {
                    if (deployment.Destination_Orgs__r.isEmpty()) {
                        deploymentList.add(new SelectOption(deployment.Id, deployment.Name));
                    }
                }
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            }
        }
    }

    /**
     * @description adds a selected deployment template to the list of extensions that need to be deployed to the target
     * org.
     */
    public void addToExtensions() {
        if (String.isBlank(selectedDeploymentId)) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Please_Select_And_Prepare_And_Extension_First);
            return;
        }
        Map<String, String> deploymentFieldsMap = GlobalUtilities.getAllFieldsWithoutSharing('Deployment__c');
        String soqlDeploymentString =
            'SELECT ' +
            deploymentFieldsMap.get(Label.FIELDS) +
            ' FROM ' +
            deploymentFieldsMap.get(Label.OBJECT) +
            ' WHERE Id = :selectedDeploymentId WITH SECURITY_ENFORCED';
        Deployment__c existingDeployment;
        try {
            existingDeployment = Database.query(soqlDeploymentString);
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            return;
        }
        Id selectedOrgId = getSelectedOrgId();
        Id selectedOrgIdFromDxOperation = getSelectedOrgIdFromDxOperation();
        Id scratchOrgId = String.isEmpty(selectedOrgIdFromDxOperation) ? selectedOrgId : selectedOrgIdFromDxOperation;
        String orgName = '';
        if (String.isNotBlank(selectedOrgIdFromDxOperation) || String.isNotBlank(selectedOrgId)) {
            List<Org__c> orgsList = new List<Org__c>();
            try {
                orgsList = [SELECT Name FROM Org__c WHERE Id = :scratchOrgId WITH SECURITY_ENFORCED];
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
                return;
            }
            orgName = !orgsList.isEmpty() ? orgsList.get(0).Name : '';
        }

        Deployment__c newDeployment = existingDeployment.clone(false, false, false, false);
        String dxScratchOrgName = getDxScratchOrgName();
        if (String.isBlank(orgName) && String.isNotBlank(dxScratchOrgName)) {
            orgName = dxScratchOrgName;
        }
        newDeployment.Name = orgName + ' - ' + newDeployment.Name;
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Deployment__c>{ newDeployment });
            insert decision.getRecords();
            newDeployment = (Deployment__c) decision.getRecords()[0];
        } catch (NoAccessException ex) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights + ' ' + ex.getMessage());
            return;
        }
        if (String.isNotBlank(selectedOrgIdFromDxOperation) || String.isNotBlank(selectedOrgId)) {
            Destination_Org__c destination = new Destination_Org__c();
            destination.Deployment__c = newDeployment.Id;
            destination.To_Org__c = scratchOrgId;
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Destination_Org__c>{ destination });
                insert decision.getRecords();
                destination = (Destination_Org__c) decision.getRecords()[0];
            } catch (NoAccessException ex) {
                addPageMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights + ' ' + ex.getMessage());
                return;
            }
        }
        List<Step__c> stepList = new List<Step__c>();
        String soqlStepString =
            'SELECT Name, Deployment__c, Order__c FROM Step__c WHERE Deployment__c =\'' +
            existingDeployment.Id +
            '\' WITH SECURITY_ENFORCED ORDER BY Order__c ASC';
        try {
            stepList = Database.query(soqlStepString);
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            return;
        }

        Map<Id, Step__c> newStepMap = new Map<Id, Step__c>();
        Set<String> fieldApiset = new Set<String>();
        for (Step__c step : stepList) {
            Step__c st = step.clone(false, false, false, false);
            st.Deployment__c = newDeployment.Id;
            st.Order__c = step.Order__c;
            fieldApiset.addAll(st.getPopulatedFieldsAsMap().keySet());
            newStepMap.put(step.Id, st);
        }

        if (!newStepMap.isEmpty()) {
            try {
                Utilities.Secure_DML(newStepMap.values(), Utilities.DML_Action.INS, SObjectType.Step__c);
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.WARNING, Label.Error_Inserting_Extension_Steps + ' ' + ex.getMessage());
                return;
            }
            if (!hasAccessTo(Attachment.SObjectType)) {
                return;
            }

            List<Attachment> attList;
            try {
                attList = [
                    SELECT Body, ContentType, Description, Name, ParentId
                    FROM Attachment
                    WHERE ParentId IN :newStepMap.keySet()
                    WITH SECURITY_ENFORCED
                ];
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
                return;
            }
            List<Attachment> newAttList = new List<Attachment>();
            for (Attachment att : attList) {
                Attachment newAtt = att.clone(false, false, false, false);
                newAtt.ParentId = newStepMap.get(att.ParentId).Id;
                newAttList.add(newAtt);
            }

            if (!appChangesToSelectedTemplate) {
                List<Step__c> stepsToBeDeleted = new List<Step__c>();
                for (Id sId : newStepMap.keySet()) {
                    if (!currentStepMap.containsKey(sId)) {
                        Step__c temp = newStepMap.get(sId);
                        temp.Id = sId;
                        stepsToBeDeleted.add(temp);
                    }
                }

                for (Id stId : currentStepMap.keySet()) {
                    if (!newStepMap.containsKey(stId)) {
                        Step__c temp = currentStepMap.get(stId);
                        temp.Id = null;
                        currentStepMap.put(stId, temp);
                    }
                }

                try {
                    Utilities.Secure_DML(currentStepDetails, Utilities.DML_Action.UPD, SObjectType.Attachment);
                } catch (Exception ex) {
                    addPageMessage(ApexPages.Severity.WARNING, Label.Error_Updating_Extension_Steps + ' ' + ex.getMessage());
                    return;
                }
                try {
                    Utilities.Secure_DML(currentStepMap.values(), Utilities.DML_Action.UPS, SObjectType.Step__c);
                } catch (Exception ex) {
                    addPageMessage(ApexPages.Severity.WARNING, Label.Error_Upserting_Extension_Steps + ' ' + ex.getMessage());
                    return;
                }
                try {
                    Utilities.Secure_DML(stepsToBeDeleted, Utilities.DML_Action.DEL, SObjectType.Step__c);
                } catch (Exception ex) {
                    addPageMessage(ApexPages.Severity.WARNING, Label.Error_Deleting_Extension_Steps + ' ' + ex.getMessage());
                    return;
                }
            }
            if (!newAttList.isEmpty()) {
                try {
                    Utilities.Secure_DML(newAttList, Utilities.DML_Action.INS, SObjectType.Attachment);
                } catch (Exception ex) {
                    addPageMessage(ApexPages.Severity.WARNING, Label.Error_Inserting_Extension_Steps + ' ' + ex.getMessage());
                    return;
                }
            }
        }

        selectedDeploymentId = newDeployment.Id;

        pageRef = Page.Deployment;
        pageRef.getParameters().put(C_ID, selectedDeploymentId);
        pageRef.getParameters().put(STEPSONLY, C_TRUE);
        addDeploymentInfo(sourceOrgId, sourceOrgName, newDeployment.Id, newDeployment.Name);
        initExtensionPrep();
    }

    /**
     * @description cancels the changes made to the selected extension templat and resets the component variables.
     */
    public void cancelPrep() {
        if (!appChangesToSelectedTemplate) {
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, currentStepDetails);
                update decision.getRecords();
            } catch (NoAccessException ex) {
                addPageMessage(ApexPages.Severity.WARNING, Label.Error_Updating_Extension_Steps + ' ' + ex.getMessage());
                return;
            }
        }
        initExtensionPrep();
    }

    /**
     * @description gets the list of existing deployment steps under the selected deployment template.
     */
    public void initDeploymentStep() {
        if (String.isBlank(selectedDeploymentId)) {
            return;
        }
        if (!hasAccessTo(Step__c.SObjectType)) {
            return;
        }
        String queryString =
            'SELECT Name, Deployment__c, Order__c FROM Step__c WHERE Deployment__c =\'' +
            String.escapeSingleQuotes(selectedDeploymentId) +
            '\' WITH SECURITY_ENFORCED';
        try {
            currentStepMap = new Map<Id, Step__c>((List<Step__c>) Database.query(queryString));
            currentStepDetails = [
                SELECT Body, ContentType, Description, Name, ParentId
                FROM Attachment
                WHERE ParentId IN :currentStepMap.keySet()
                WITH SECURITY_ENFORCED
            ];
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights + ' ' + ex.getMessage());
            return;
        }
        pageRef = Page.Deployment;
        pageRef.getParameters().put(C_ID, selectedDeploymentId);
        pageRef.getParameters().put(STEPSONLY, C_TRUE);
    }

    /**
     * @description switches to the edition mode of a selected deployment extension so a user can modify the extension
     * template.
     */
    public void editExtension() {
        if (String.isBlank(selectedDeploymentId)) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Extension_Deployment_Cannot_Be_Empty);
        }
        Integer listSize = getDeploymentInfoList().size();
        for (Integer i = 0; i < listSize; i++) {
            if (getDeploymentInformationAt(i).getDeploymentId() == selectedDeploymentId) {
                sourceOrgName = getDeploymentInformationAt(i).getScratchOrgName();
                sourceOrgId = getDeploymentInformationAt(i).getScratchOrgId();
                editingDeployment = getDeploymentInformationAt(i).getDeploymentName();
                break;
            }
        }
        if (String.isNotBlank(sourceOrgId)) {
            populateDeployments();
            initDeploymentStep();
            editMode = true;
        }
    }

    /**
     * @description removes a deployment extension from the list of selected extensions.
     */
    public void deleteExtension() {
        if (String.isBlank(selectedDeploymentId)) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Extension_Deployment_Cannot_Be_Empty);
            return;
        }

        Integer listSize = getDeploymentInfoList().size();
        for (Integer i = listSize - 1; i >= 0; i--) {
            if (getDeploymentInformationAt(i).getDeploymentId() == selectedDeploymentId) {
                removeDeploymentInfo(i);
                break;
            }
        }
        try {
            if (Deployment__c.SObjectType.getDescribe().isAccessible() && Deployment__c.SObjectType.getDescribe().isDeletable()) {
                delete [SELECT Id FROM Deployment__c WHERE Id = :selectedDeploymentId WITH SECURITY_ENFORCED LIMIT 1];
            }
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Error_Deleting_Extension_Steps + ' ' + ex.getMessage());
            return;
        }
        initExtensionPrep();
        return;
    }

    /**
     * @description checks if the user has read access to a Salesforce Object and displays an error message otherwise.
     *
     * @param thisObjectType is the SObject type being evaluated.
     *
     * @return a flag indicating if a user has access to the given SObject type or not.
     */
    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if (!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING, thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
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