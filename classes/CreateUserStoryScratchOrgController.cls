public with sharing class CreateUserStoryScratchOrgController extends ScratchOrgWizardPageBase {
    private final String NEXT = 'Next';
    public User_Story__c thisUserStory { get; set; }
    public ScratchOrgWizardComponentBase componentController { get; set; }
    public String definition { get; set; }
    public String metadata { get; set; }
    public String extension { get; set; }
    public String review { get; set; }
    public String nextButtonLabel { get; set; }
    public Boolean disableNextButton { get; set; }
    public Boolean disablePreviousButton { get; set; }
    public Boolean isDXEnabled { get; set; }
    public String selectedPermissions { get; set; }
    public Boolean jobFinished { get; set; } 
    public Boolean showExtensionStatus { get; set; }
    public String dxDeploymentFlowMode { get; set; }
    public String dxRepositoryId { get; private set; }
    private Boolean hasExtensions { get; set; }
    private String currentStage = Stage.CURRENT.name();
    private String completeStage = Stage.COMPLETE.name();
    private String incompleteStage = Stage.INCOMPLETE.name();

    public enum Stage {
        CURRENT,
        INCOMPLETE,
        COMPLETE
    }

    public CreateUserStoryScratchOrgController(ApexPages.StandardController std) {
        if (!Test.isRunningTest()) {
            std.addFields(new List<String>(SObjectType.User_Story__c.fields.getMap().keySet()));
            std.addFields(new List<String>{ 'Project__r.Deployment_Flow__c', 'Release__r.Project__r.Deployment_Flow__c' });
        }
        thisUserStory = (User_Story__c) std.getRecord();
        initDefaults();
        if (thisUserStory.Org_Credential__c != null) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DX_US_ALREADY_HAS_AN_ORG);
        }
    }

    private void initDefaults() {
        hasExtensions = false;
        showExtensionStatus = false;
        isDXEnabled = dxIsEnabledOnPipeline();
        jobFinished = false;
        setStandardControllerId(thisUserStory.Id);
        definition = Stage.INCOMPLETE.name();
        metadata = Stage.CURRENT.name();
        extension = Stage.INCOMPLETE.name();
        review = Stage.INCOMPLETE.name();
        nextButtonLabel = NEXT;
        disableNextButton = false;
        disablePreviousButton = true;
    }

    public override void setChildComponentController(ScratchOrgWizardComponentBase wizCompController) {
        componentController = (ScratchOrgWizardComponentBase) wizCompController;
    }

    public override ScratchOrgWizardComponentBase getChildComponentController() {
        return componentController;
    }

    public void loadReviewData() {
        ScratchOrgCompletionController completionController = (ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion');
        completionController.orgDefinition = getOrgTemplate();
        completionController.JSONFileDefinition = getJSONSettingsFeatures();
        completionController.artifactProject = getArtifactProject();
        completionController.parentId = getStandardControllerId();
        completionController.deploymentFlowOperations();
    }

    public void nextStepOrgTemplate() {
        nextStep();
    }

    public void nextStep() {
        if (currentStage == metadata) {
            setupMetadataStage();
        } else if (currentStage == definition) {
            setupDefinitionStage();
        } else if (currentStage == extension) {
            setupExtensionStage();
        } else if (currentStage == review) {
            setupReviewStage();
        }
    }

    private void setupMetadataStage() {
        ScratchOrgMetadataController controller = (ScratchOrgMetadataController) getComponentController('ScratchOrgMetadata');
        controller.setDXProjectPackageDirectories();
        setArtifactProject(controller.thisDxProject);
        System.debug('controller.getDxRepositoryId(): ' + controller.getDxRepositoryId());
        updatePageFlags(currentStage, incompleteStage, completeStage, incompleteStage, false, false, NEXT);
    }

    private void setupDefinitionStage() {
        ScratchOrgController controller = (ScratchOrgController) getComponentController('ScratchOrgTemplate');
        
        setDevHubOrgId(controller.getDevHubOrgId());
        setOrgTemplate(controller.orgTemplate);
        getOrgTemplate().setOrgName(controller.getDxUserStoryName());        
        String jsonSettingsFeatures = prepareDataForJsonEditor(getOrgTemplate(), getJSONSettingsFeatures());
        setJSONSettingsFeatures(jsonSettingsFeatures);
        controller.jsonSettingsFeatures = jsonSettingsFeatures;
        updatePageFlags(completeStage, currentStage, completeStage, incompleteStage, false, false, NEXT);
    }

    private void setupExtensionStage() {
        ScratchOrgExtensionsController controller = (ScratchOrgExtensionsController) getComponentController('ScratchOrgExtensions');
        updatePageFlags(completeStage, completeStage, completeStage, currentStage, false, false, 'Complete Setup');
        hasExtensions = !controller.getDeploymentInfoList().isEmpty();
    }

    private void setupReviewStage() {
        jobFinished = false;
        updatePageFlags(completeStage, completeStage, completeStage, completeStage, true, true, 'Creating Scratch Org');

        ScratchOrgCompletionController completionController = (ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion');
        completionController.showPermissionsPanel = false;
        completionController.showDeploymentFlow = false;
        completionController.showSetup = false;

        Id flowId = completionController.depFlowId;
        Id targetEnv = completionController.getFlowDXDestination();
        String orgName = getOrgTemplate().getOrgName();
        Integer durationDays = ((ScratchOrgController) getComponentController('ScratchOrgTemplate')).duration;
        Id userStoryId = getStandardControllerId();
        String orgTemplateJSON = prepareOrgDefinition(getOrgTemplate(), getJSONSettingsFeatures());
        ScratchOrgMetadataController metadataController = (ScratchOrgMetadataController) getComponentController('ScratchOrgMetadata');
        AbstractArtifact thisArtifact = metadataController.thisArtifact;
        metadataController.setArtifactParameters();

        AbstractDXOrg dxOrgService = DXOrgFactory.getInstance('DevHubService');
        dxOrgService.setOrgId(getDevHubOrgId());
        dxOrgService.setOrgDefinitionJSON(orgTemplateJSON);
        dxOrgService.setScratchOrgName(orgName);
        ((DevHubService) dxOrgService).setArtifact(thisArtifact);
        ((DevHubService) dxOrgService).createFullScratchOrg(durationDays, flowId, targetEnv, selectedPermissions, userStoryId);
        completionController.completionMessage = Label.CreateFullScratchOrg_Init_Message;
    }

    public void previousStep() {
        disableNextButton = false;
        disablePreviousButton = true;
        if (currentStage == definition) {
            updatePageFlags(incompleteStage, incompleteStage, currentStage, incompleteStage, true, false, NEXT);
        } else if (currentStage == extension) {
            updatePageFlags(currentStage, incompleteStage, completeStage, incompleteStage, false, false, NEXT);
        } else if (currentStage == review) {
            updatePageFlags(completeStage, currentStage, completeStage, incompleteStage, false, false, NEXT);
        }
    }

    private void updatePageFlags(
        String definitionStage,
        String extensionStage,
        String metadataStage,
        String reviewStage,
        Boolean disablePreviousBtnStage,
        Boolean disableNextBtnStage,
        String nextBtnLabel
    ) {
        definition = definitionStage;
        extension = extensionStage;
        metadata = metadataStage;
        review = reviewStage;
        disablePreviousButton = disablePreviousBtnStage;
        disableNextButton = disableNextBtnStage;
        nextButtonLabel = nextBtnLabel;
    }

    public PageReference jobStatusNotification() {
        ApexPages.getMessages().clear();
        Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
        jobFinished = pageParameters.get('jobFinished') == 'true';

        if (jobFinished) {
            Boolean jobSuccess = pageParameters.get('jobSuccess') == 'true';
            if (jobSuccess) {
                String jobType = pageParameters.get('jobType');
                if (String.isNotBlank(jobType)) {
                    jobFinished = true;
                    ScratchOrgCompletionController controller = ((ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion'));
                    if (controller != null) {
                        controller.completionMessage = null;
                    }
                    if (jobType == DXLabel.CREATE_FULL_ORG) {
                        addPageMessage(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success);
                    } else if (jobType == DXLabel.LIST_REPO_BRANCHES) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'Branches retrieved successfully');
                    }
                }
            } else {
                String jobMessage = pageParameters.get('jobMessage');
                if (String.isNotBlank(jobMessage)) {
                    jobFinished = true;
                    addPageMessage(ApexPages.Severity.ERROR, jobMessage);
                }
            }
        }
        return null;
    }

    public PageReference fullCreateCompleted() {
        if (!hasExtensions || showExtensionStatus) {
            return null;
        }

        ScratchOrgExtensionsController controller = ((ScratchOrgExtensionsController) getComponentController('ScratchOrgExtensions'));
        showExtensionStatus = true;
        disablePreviousButton = true;
        disableNextButton = true;
        hasExtensions = false;
        List<User_Story__c> userStories = new List<User_Story__c>();
        try {
            userStories = [SELECT Org_Credential__c FROM User_Story__c WHERE Id = :controller.getDxUserStoryId() WITH SECURITY_ENFORCED];
        } catch (System.QueryException e) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + e.getMessage());
        }
        if (userStories.isEmpty()) {
            return null;
        }
        User_Story__c thisUserStory = userStories[0];
        if (thisUserStory.Org_Credential__c == null) {
            return null;
        }

        Map<Id, Destination_Org__c> destinationOrgMap = controller.getDestinationOrgMap(thisUserStory.Org_Credential__c);
        // Not reported by sonarqube
        try {
            for (Deployment__c deployment : [
                SELECT Id, (SELECT Id FROM Destination_Orgs__r WHERE To_Org__c = :thisUserStory.Org_Credential__c)
                FROM Deployment__c
                WHERE Id = :destinationOrgMap.keySet() AND Promotion__c = null AND Status__c = 'Draft'
                WITH SECURITY_ENFORCED
            ]) {
                for (Destination_Org__c destinationOrg : deployment.Destination_Orgs__r) {
                    if (destinationOrgMap.containsKey(deployment.Id)) {
                        destinationOrgMap.remove(deployment.Id);
                    }
                }
            }
        } catch (System.QueryException e) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + e.getMessage());
        }

        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, destinationOrgMap.values());
            insert decision.getRecords(); 
            controller.executeSteps();
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Extension_Deployment_Error + ex.getMessage());
        }
        return null;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    private Boolean dxIsEnabledOnPipeline() {
        Boolean isEnabled = true;
        Deployment_Flow__c thisPipeline = getUserStoryPipeline();
        if (thisPipeline == null) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DX_NO_US_FLOW);
            isEnabled = false;
        } else if (!thisPipeline.Enable_Copado_DX__c) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DX_NOT_ENABLED_DF);
            isEnabled = false;
        } else if (thisPipeline.Deployment_Flow_Steps__r.isEmpty()) {
            addPageMessage(ApexPages.Severity.WARNING, Label.DF_HAS_NO_DX_TARGET);
            isEnabled = false;
        }
        if (isEnabled) {
            dxDeploymentFlowMode = thisPipeline.Copado_DX_Mode__c;
        }
        if (String.isNotBlank(thisPipeline?.Git_Repository__c)) {
            dxRepositoryId = thisPipeline.Git_Repository__c;
        }
        return isEnabled;
    }

    private Deployment_Flow__c getUserStoryPipeline() {
        String pipelineId;
        if (thisUserStory.Project__r.Deployment_Flow__c != null) {
            pipelineId = thisUserStory.Project__r.Deployment_Flow__c;
        } else if (thisUserStory.Release__r.Project__r.Deployment_Flow__c != null) {
            pipelineId = thisUserStory.Release__r.Project__r.Deployment_Flow__c;
        }
        Deployment_Flow__c thisPipeline;
        try {
            List<Deployment_Flow__c> pipelines = [
                SELECT
                    Enable_Copado_DX__c,
                    Copado_DX_Mode__c,
                    Git_Repository__c,
                    (SELECT Id FROM Deployment_Flow_Steps__r WHERE Enable_as_Scratch_Org_Destination__c != null)
                FROM Deployment_Flow__c
                WHERE Id = :pipelineId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ]; //NOT REPORTED BY SONARQUBE

            if (!pipelines.isEmpty()) {
                thisPipeline = pipelines[0];
            }
        } catch (System.QueryException e) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + e.getMessage());
        }

        return thisPipeline;
    }
 
    private String prepareOrgDefinition(ScratchOrgDefinition orgTemplate, String jsonSettingFeature) {
        if (!String.isBlank(orgTemplate.getEdition())) {
            Map<String, Object> orgTemplateMap = new Map<String, Object>();
            if (String.isNotBlank(jsonSettingFeature)) {
                orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(jsonSettingFeature));
            }
            orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orgTemplate)));
            return JSON.serializePretty(orgTemplateMap);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DX_Edition_is_required));
        }
        return null;
    }

    private String prepareDataForJsonEditor(ScratchOrgDefinition orgDefinition, String jsonDefinition) {
        Map<String, Object> templateMap = new Map<String, Object>((Map<String, Object>) JSON.deserializeUntyped(jsonDefinition));
        for (String generalProperty : orgDefinition.getProperties()) {
            templateMap.remove(generalProperty);
        }
        return JSON.serialize(templateMap);
    }
}