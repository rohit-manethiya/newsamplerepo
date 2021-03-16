/**
 * @description this class and its component are responsible for the final steps in the scratch org creation process,
 * such as gather all the information entered by the user and generating configuration files for projects and org
 * definitions, and sending out create commands to the backend.
 */
public with sharing class ScratchOrgCompletionController extends ScratchOrgWizardComponentBase {
    private Map<Id, Deployment_Flow_Step__c> flowStepsMap;
    public Id depFlowId { get; set; }
    public Id parentId { get; set; }
    public Boolean showDeploymentFlow { get; set; }
    public Boolean showPermissionsPanel { get; set; }
    public Boolean showSetup { get; set; }
    public String JSONFileDefinition { get; set; }
    public String selectedStep { get; set; }
    public String deploymentFlowName { get; set; }
    public String selectedPermissions { get; set; }
    public String completionMessage { get; set; }
    public String sourceBranch { get; set; }
    public DXProject artifactProject { get; set; }
    public ScratchOrgDefinition orgDefinition { get; set; }
    public Test_Run__c tRun { get; set; }
    public List<ProjectArtifact> artifactDirectories { get; set; }
    public List<SelectOption> dxTargetFlowSteps { get; set; }

    public ScratchOrgCompletionController() {
        showDeploymentFlow = SObjectType.Deployment_Flow__c.isUpdateable() && SObjectType.Deployment_Flow__c.isCreateable();
        showPermissionsPanel = true;
        showSetup = true;
        flowStepsMap = new Map<Id, Deployment_Flow_Step__c>();
    }

    /**
     * @description this method sends a create scratch org command to the backend through the DevHubService entity which
     * handles the callout operations behind the scenes.
     * @see DevHubService
     */
    public void createFullScratchOrg() {
        if (tRun == null || tRun.Id == null) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Test_Run_Is_Empty);
            return;
        }
        Id devHubId = tRun.Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c;
        String sourceBranch = DXLabel.PROJECT_BRANCH + String.valueOf(tRun.Test_Script__r.User_Story__r.Org_Credential__c).substring(3, 15);
        String soName = tRun.Name + ' Scratch Org';
        Id orgId = tRun.Test_Script__r.User_Story__r.Org_Credential__c;

        String definitionBody = '';
        try {
            List<Attachment> attDefinition = [
                SELECT Body
                FROM Attachment
                WHERE ParentId = :orgId AND Name = :DXLabel.DEFINITION_FILE
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!attDefinition.isEmpty()) {
                definitionBody = attDefinition[0].Body.toString();
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }

        ScratchOrgDefinition orgTemplate = (ScratchOrgDefinition) JSON.deserialize(definitionBody, ScratchOrgDefinition.class);
        String jsonSettingsFeatures = prepareDataForJsonEditor(orgTemplate, definitionBody);

        orgTemplate.setOrgName(tRun.Name + ' Scratch Org');
        orgTemplate.setUsername('');
        String definitionJSON = prepareOrgDefinition(orgTemplate, jsonSettingsFeatures);

        // TODO: WHY IS THE METADATASOURCE ALWAYS BRANCH?
        MetadataSource artifactSource = new MetadataSource(
            DXLabel.PROJECT_BRANCH + String.valueOf(tRun.Test_Script__r.User_Story__r.Org_Credential__c).substring(3, 15),
            DXLabel.BRANCH,
            getRepositoryId()
        );
        String mdSource = JSON.serialize(artifactSource);

        String projectJSON;
        try {
            List<Attachment> dxProject = [
                SELECT Body
                FROM Attachment
                WHERE ParentId = :orgId AND Name = :DXLabel.PROJECT_FILE
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!dxProject.isEmpty()) {
                projectJSON = dxProject[0].Body.toString();
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }

        AbstractDXOrg dxOrgService = DXOrgFactory.getInstance('DevHubService');
        dxOrgService.setOrgId(devHubId);
        dxOrgService.setOrgDefinitionJSON(definitionJSON);
        dxOrgService.setScratchOrgName(soName);
        ((DevHubService) dxOrgService).createFullScratchOrg(sourceBranch, projectJSON, mdSource);
    }

    /**
     * @description when a user chooses to create a scratch org for executing a test run (coming from the Test Run
     * detail page), this method retrieves the repository linked to the parent User Story and sets it as the target
     * for the new scratch org.
     *
     * @return the id of the parent User Story repository that can be either pulled from the User Story's Project
     * Pipeline or Release.
     */
    private Id getRepositoryId() {
        Id repositoryId;
        try {
            // Not reported by sonarqube?
            User_Story__c thisUserStory = [
                SELECT Project__r.Deployment_Flow__r.Git_Repository__c, Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
                FROM User_Story__c
                WHERE Id = :tRun.Test_Script__r.User_Story__c
                WITH SECURITY_ENFORCED
            ];
            String projectPipelineRepository = thisUserStory.Project__r.Deployment_Flow__r.Git_Repository__c;
            String releaseProjectPipelineRepository = thisUserStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
            if (projectPipelineRepository != null) {
                repositoryId = projectPipelineRepository;
            } else if (releaseProjectPipelineRepository != null) {
                repositoryId = releaseProjectPipelineRepository;
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
        return repositoryId;
    }

    /**
     * @description this method sets the target environment the user has selected to link the new scratch to it within
     * the chosen pipeline.
     *
     * @return the id of the target environment to which the new scratch org will be linked in the pipeline.
     */
    public Id getFlowDXDestination() {
        Id targetEnvironment;
        Deployment_Flow_Step__c thisStep = flowStepsMap.get(selectedStep);
        if (thisStep != null) {
            targetEnvironment = thisStep.Source_Environment__c;
        }
        return targetEnvironment;
    }

    /**
     * @description this method retrieves a list of all the available pipelines and pipeline connections for the user.
     */
    public void deploymentFlowOperations() {
        if (!showDeploymentFlow) {
            return;
        }
        depFlowId = findDeploymentFlowId();
        if (depFlowId == null) {
            showDeploymentFlow = false;
        }
        dxTargetFlowSteps = new List<SelectOption>();
        dxTargetFlowSteps.add(new SelectOption('', Label.NONE_SELECTED));
        try {
            List<Deployment_Flow__c> pipelines = [
                SELECT
                    Name,
                    (
                        SELECT Name, Enable_as_Scratch_Org_Destination__c, Source_Environment__c, Source_Environment__r.Name
                        FROM Deployment_Flow_Steps__r
                        WHERE Enable_as_Scratch_Org_Destination__c != null
                    )
                FROM Deployment_Flow__c
                WHERE Id = :depFlowId
                WITH SECURITY_ENFORCED
            ];
            if (!pipelines.isEmpty()) {
                Deployment_Flow__c thisPipeline = pipelines[0];
                deploymentFlowName = thisPipeline.Name;
                dxTargetFlowSteps = new List<SelectOption>();

                for (Deployment_Flow_Step__c thisStep : thisPipeline.Deployment_Flow_Steps__r) {
                    dxTargetFlowSteps.add(new SelectOption(thisStep.Source_Environment__c, thisStep.Source_Environment__r.Name));
                    flowStepsMap.put(thisStep.Source_Environment__c, thisStep);
                    if (thisStep.Enable_as_Scratch_Org_Destination__c == 'Default DX Target') {
                        selectedStep = thisStep.Source_Environment__c;
                    }
                }
            }
        } catch (QueryException queryEx) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
        }
    }

    /**
     * @description this method finds the pipeline id associated with the current User Story and sets it as the selected
     * one by default (only if there is any pipeline available).
     *
     * @return the id of the pipeline associated with the User Story.
     */
    private Id findDeploymentFlowId() {
        Id pipelineId;
        Id parentStandardControllerId = getPageController().getStandardControllerId();
        if (parentStandardControllerId == null) {
            return null;
        }
        if (parentStandardControllerId.getSObjectType() == User_Story__c.SObjectType) {
            try {
                User_Story__c thisUserStory = [
                    SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
                    FROM User_Story__c
                    WHERE Id = :parentStandardControllerId
                    WITH SECURITY_ENFORCED
                ];
                if (thisUserStory.Project__r.Deployment_Flow__c != null) {
                    pipelineId = thisUserStory.Project__r.Deployment_Flow__c;
                } else if (thisUserStory.Release__r.Project__r.Deployment_Flow__c != null) {
                    pipelineId = thisUserStory.Release__r.Project__r.Deployment_Flow__c;
                }
            } catch (QueryException queryEx) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + queryEx.getMessage());
            }
        }
        return pipelineId;
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
     * @description a utility method for displaying messages on the parent page.
     *
     * @param severity is the ApexPages.Severity enum value for the type of message.
     * @param message is the actual message to be shown to the user.
     */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}