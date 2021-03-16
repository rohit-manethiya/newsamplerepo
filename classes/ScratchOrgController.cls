/**
 * @description this class and its component are responsible for the configuration and management of new and existing
 * Scratch Org Definition templates. The component is also used as an additional step in the creation process of a new
 * scratch org.
 */
public with sharing class ScratchOrgController extends ScratchOrgWizardComponentBase {
    public String jsonSettingsFeatures { get; set; }
    public String templateName { get; set; }
    public String templateBody { get; set; }
    public Integer duration { get; set; }
    public Id selectedFlowStepId { get; set; }
    public Id selectedPipelineId { get; set; }
    public Id templateId {
        get;
        set {
            // if you make changes here make sure the test component from standard layout. It was not working correctly before this changes. It was entering 2-3 times here and it was overriding latest changes.
            if (String.isNotBlank(value)) {
                if (String.isBlank(templateId) || templateId != value) {
                    templateId = value;
                    if (String.isNotBlank(templateId)) {
                        readOrgDefinitionFromTemplate();
                    }
                }
            }
        }
    }
    public ScratchOrgDefinition orgTemplate {
        get {
            if (orgTemplate == null) {
                List<Attachment> attachments = new List<Attachment>();
                try {
                    attachments = [
                        SELECT Body
                        FROM Attachment
                        WHERE Name = :DXLabel.DEFINITION_FILE AND ParentId = :getParentStandardControllerId()
                        WITH SECURITY_ENFORCED
                    ];
                } catch (QueryException queryEx) {
                    addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
                }
                if (!attachments.isEmpty()) {
                    String definitionTemplate = attachments[0].Body.toString();
                    orgTemplate = (ScratchOrgDefinition) JSON.deserialize(definitionTemplate, ScratchOrgDefinition.class);
                    jsonSettingsFeatures = prepareDataForJsonEditor(orgTemplate, definitionTemplate);
                } else {
                    getOrgTemplateInstance();
                }
            }
            return orgTemplate;
        }
        set;
    }
    public List<SelectOption> dfsSelectOptionList { get; set; }
    public List<SelectOption> countryPicklistOptions { get; set; }
    public List<SelectOption> templatesWithHubId {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', Label.NONE_SELECTED));
            try {
                if (String.isNotBlank(getDevHubOrgId())) {
                    for (Scratch_Org_Definition__c definition : [
                        SELECT Name
                        FROM Scratch_Org_Definition__c
                        WHERE Developer_Hub_Org__c = :getDevHubOrgId()
                        WITH SECURITY_ENFORCED
                    ]) {
                        options.add(new SelectOption(definition.Id, definition.Name));
                    }
                } else {
                    for (Scratch_Org_Definition__c definition : [
                        SELECT Name
                        FROM Scratch_Org_Definition__c
                        WHERE Developer_Hub_Org__c != NULL
                        WITH SECURITY_ENFORCED
                    ]) {
                        options.add(new SelectOption(definition.Id, definition.Name));
                    }
                }
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            }
            return options;
        }
    }
    public List<SelectOption> deploymentFlowOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', Label.NONE_SELECTED));
            try {
                for (Deployment_Flow__c thisPipeline : [
                    SELECT Name
                    FROM Deployment_Flow__c
                    WHERE Enable_Copado_DX__c = TRUE
                    WITH SECURITY_ENFORCED
                ]) {
                    options.add(new SelectOption(thisPipeline.Id, thisPipeline.Name));
                }
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            }
            return options;
        }
    }

    public ScratchOrgController() {
        Boolean isAuthorizedToViewScratchOrgDef = hasAccessTo(Scratch_Org_Definition__c.SObjectType);
        Boolean isAuthorizedToCreateScratchOrgDef = Scratch_Org_Definition__c.SObjectType.getDescribe().isCreateable();
        Boolean isAuthorizedToUpdateScratchOrgDef = Scratch_Org_Definition__c.SObjectType.getDescribe().isUpdateable();
        if (!isAuthorizedToViewScratchOrgDef || !isAuthorizedToCreateScratchOrgDef || !isAuthorizedToUpdateScratchOrgDef) {
            addPageMessage(ApexPages.Severity.WARNING, SObjectType.Scratch_Org_Definition__c.label + ': ' + Label.Insufficient_Access_Rights);
        }
        setShowTemplateSaveAsButton(isAuthorizedToViewScratchOrgDef && isAuthorizedToCreateScratchOrgDef);
        setShowTemplateUpdateButton(isAuthorizedToViewScratchOrgDef && isAuthorizedToUpdateScratchOrgDef);
        if (getDevHubOrgId() == null) {
            getDevHubOrgs();
        }
        countryPicklistOptions = CountryPicklistValues.prepareCountryPicklist();
        templateName = '';
        duration = 7;
        setParentStandardControllerId(ApexPages.currentPage().getParameters().get('Id'));
    }

    /**
     * @description when a user selects a pipeline for the new scratch org in the template form, this method retrieves
     * all the available pipeline connections so the user can choose where to attach the new scratch org within the
     * selected pipeline.
     */
    public void populateDeploymentFlowSteps() {
        dfsSelectOptionList = new List<SelectOption>();
        dfsSelectOptionList.add(new SelectOption('', Label.NONE_SELECTED));
        if (String.isNotBlank(selectedPipelineId)) {
            try {
                List<Deployment_Flow__c> pipelines = [
                    SELECT
                        Name,
                        (
                            SELECT
                                Name,
                                Enable_as_Scratch_Org_Destination__c,
                                Destination_Environment__c,
                                Destination_Environment__r.Name,
                                Source_Environment__c,
                                Source_Environment__r.Name
                            FROM Deployment_Flow_Steps__r
                            WHERE Enable_as_Scratch_Org_Destination__c != NULL
                        )
                    FROM Deployment_Flow__c
                    WHERE Id = :selectedPipelineId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (!pipelines.isEmpty()) {
                    Deployment_Flow__c thisPipeline = pipelines[0];
                    for (Deployment_Flow_Step__c thisStep : thisPipeline.Deployment_Flow_Steps__r) {
                        String optionName = thisStep.Source_Environment__r.Name + '-->' + thisStep.Destination_Environment__r.Name;
                        dfsSelectOptionList.add(new SelectOption(thisStep.Source_Environment__c, optionName));
                        if (thisStep.Enable_as_Scratch_Org_Destination__c == 'Default DX Target') {
                            selectedFlowStepId = thisStep.Source_Environment__c;
                        }
                    }
                }
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            }
        }
    }

    /**
     * @description this method sends an org creation request to the backend using the DevHubService entity, redirects
     * the user back to the DX Operations page and monitors the status of the request.
     * @see DevHubService
     *
     * @return a page redirection to the DX Operations page.
     */
    public PageReference createOrg() {
        if (!validateStep(false)) {
            return null;
        }

        orgTemplate.setOrgName(getDxUserStoryName());
        templateBody = prepareOrgDefinition(orgTemplate, jsonSettingsFeatures);
        Id dxUserStoryId = getDxUserStoryId();
        Id userStoryId = String.isNotBlank(dxUserStoryId) ? dxUserStoryId : null;
        Id devHubOrgId = getDevHubOrgId();

        AbstractDXOrg dxOrgService = DXOrgFactory.getInstance('DevHubService');
        dxOrgService.setOrgId(devHubOrgId);
        dxOrgService.setOrgDefinitionJSON(templateBody);
        dxOrgService.setScratchOrgName(orgTemplate.getOrgName());
        ((DevHubService) dxOrgService).createScratchOrg(duration, selectedPipelineId, selectedFlowStepId, userStoryId);

        PageReference thisPage = Page.DXOperation;
        if (String.isNotBlank(devHubOrgId)) {
            thisPage.getParameters().put('id', devHubOrgId);
        }
        thisPage.setRedirect(true);
        return thisPage;
    }

    /**
     * @description called by the Save Template button to insert a new Scratch_Org_Definition_Template__c record into
     * the database.
     */
    public PageReference newTemplate() {
        return saveTemplate(true);
    }

    /**
     * @description called by the Update Template button to update an existing Scratch_Org_Definition_Template__c record
     * in the database.
     */
    public PageReference updateTemplate() {
        return saveTemplate(false);
    }

    /**
     * @description saves a Scratch_Org_Definition_Template__c record to the database (new or existing) holding all the
     * information entered by the user.
     *
     * @param isNew is a flag indicating if the record should be saved as a new one or be updated.
     *
     * @return a page redirection to the template detail page.
     */
    public PageReference saveTemplate(Boolean isNew) {
        if (String.isEmpty(templateName)) {
            addPageMessage(ApexPages.Severity.ERROR, Label.SOD_Template_Name_Validation);
            return null;
        }
        if (!validateStep(true)) {
            return null;
        }

        orgTemplate.setOrgName(getDxUserStoryName());
        Scratch_Org_Definition__c template = new Scratch_Org_Definition__c(
            Name = templateName,
            Developer_Hub_Org__c = getDevHubOrgId(),
            Duration_in_days__c = duration,
            Scratch_Org_Definition_JSON__c = prepareOrgDefinition(orgTemplate, jsonSettingsFeatures)
        );

        if (isNew) {
            if (String.isNotBlank(templateId)) {
                template.Id = templateId;
            }
        }
        try {
            Utilities.Secure_DML(template, Utilities.DML_Action.UPS, Schema.SObjectType.Scratch_Org_Definition__c);
            addPageMessage(ApexPages.Severity.CONFIRM, Label.DX_Template_Success_Update);
        } catch (NoAccessException ex) {
            addPageMessage(ApexPages.Severity.WARNING, ex.getMessage());
            return null;
        }

        if (String.isNotBlank(template.Id)) {
            templateId = template.Id;
            String componentMode = getComponentMode();
            if (componentMode == 'newStd' || componentMode == 'editStd' || componentMode == 'cloneStd') {
                PageReference toRecords = new PageReference('/' + template.Id);
                toRecords.setRedirect(true);
                return toRecords;
            }
        }
        return null;
    }

    /**
     * @description this method reads a Scratch Org Definition Template that was selected by the user from the database.
     * The org template contains information that will be used to generate the Scratch Org Definition (scratch-def.json)
     * file.
     */
    public void readOrgDefinitionFromTemplate() {
        ApexPages.getMessages().clear();
        getOrgTemplateInstance();
        if (String.isBlank(templateId)) {
            templateId = ApexPages.currentPage().getParameters().get('templateId');
            jsonSettingsFeatures = '{"features":[],"settings":{}}';
        } else {
            try {
                Scratch_Org_Definition__c template = [
                    SELECT Name, Scratch_Org_Definition_JSON__c, Developer_Hub_Org__c, Duration_in_days__c
                    FROM Scratch_Org_Definition__c
                    WHERE Id = :templateId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                setDevHubOrgId(template.Developer_Hub_Org__c);
                duration = (Integer) template.Duration_in_days__c;
                templateName = template.Name;
                orgTemplate = (ScratchOrgDefinition) JSON.deserialize(template.Scratch_Org_Definition_JSON__c, ScratchOrgDefinition.class);
                setDxUserStoryName(orgTemplate.getOrgName());
                jsonSettingsFeatures = prepareDataForJsonEditor(orgTemplate, template.Scratch_Org_Definition_JSON__c);
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Read_DX_Template_Error + ': ' + ex.getMessage());
            }
        }
    }

    /**
     * @description this method makes sure all the basic parameters required for a scratch org creation are in place,
     * throwing an error and canceling the backend request otherwise.
     *
     * @param skip is a flag indicating if the org is to be associated with an existing User Story and if so, validate
     * the User Story name.
     *
     * @return a flag indicating if the validation was successful or not.
     */
    private Boolean validateStep(Boolean skip) {
        if (String.isBlank(getDevHubOrgId())) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Please_select_hub);
            return false;
        } else if (!skip && String.isEmpty(getDxUserStoryName())) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Set_Org_Name);
            return false;
        } else if (duration == null || duration < 1 || duration > 30) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Scratch_Org_Duration_Validation);
            return false;
        } else if (String.isEmpty(orgTemplate.getEdition())) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Org_Edition_Validation);
            return false;
        }
        return true;
    }

    /**
     * @description initializes a new org template instance with default values.
     * @see ScratchOrgDefinition
     */
    private void getOrgTemplateInstance() {
        orgTemplate = new ScratchOrgDefinition();
    }

    /**
     * @description this method retrieves a list of available Dev Hub orgs from which a user can create a new scratch
     * org.
     */
    private void getDevHubOrgs() {
        addDevHubOption(new SelectOption('', Label.NONE_SELECTED));
        try {
            for (Org__c thisOrg : [SELECT Name FROM Org__c WHERE is_Developer_Hub_Org__c = TRUE WITH SECURITY_ENFORCED]) {
                addDevHubOption(new SelectOption(thisOrg.Id, thisOrg.Name));
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
    }

    /**
     * @description this method organizes all the Scratch Org Definition settings into a JSON string and stores it as
     * the template body in a Scratch_Org_Definition_Template__c record.
     *
     * @param orgTemplate is the wrapper class that holds information about the scratch org definition parameters.
     * @param jsonSettingFeatures is a JSON string with additional parameters that are collected from the component
     * form, entered by the user manually. These settings are optional.
     *
     * @return the full body of the Scratch Org Definition template in JSON format.
     */
    private String prepareOrgDefinition(ScratchOrgDefinition orgTemplate, String JSONSettingsFeatures) {
        if (!String.isBlank(orgTemplate.getEdition())) {
            Map<String, Object> orgTemplateMap = new Map<String, Object>();
            if (String.isNotBlank(JSONSettingsFeatures)) {
                orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSONSettingsFeatures));
            }
            orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orgTemplate)));
            return JSON.serializePretty(orgTemplateMap);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DX_Edition_is_required));
            return null;
        }
    }

    /**
     * @description this method parses a Scratch Org Definition Template body so that it can be presented to a user for
     * editing it in the component screen.
     *
     * @param orgDefinition is the wrapper class that holds information about the scratch org definition parameters.
     * @param jsonDefinition is a JSON string with additional parameters that are collected from the component
     * form, entered by the user manually. These settings are optional.
     *
     * @return the full body of the Scratch Org Definition template in JSON format.
     */
    private String prepareDataForJsonEditor(ScratchOrgDefinition orgDefinition, String jsonDefinition) {
        Map<String, Object> templateMap = new Map<String, Object>((Map<String, Object>) JSON.deserializeUntyped(jsonDefinition));
        for (String generalProperty : orgDefinition.getProperties()) {
            templateMap.remove(generalProperty);
        }
        return JSON.serialize(templateMap);
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