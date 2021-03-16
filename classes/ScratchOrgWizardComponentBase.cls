/**
 * @description this virtual class serves as a communication medium between custom component controllers and their
 * parent Visualforce page.
 * @see https://developer.salesforce.com/page/Controller_Component_Communication
 */
public with sharing virtual class ScratchOrgWizardComponentBase {
    private static final Set<String> componentModes = new Set<String>{
            'display',
            'edit',
            'wizard',
            'template',
            'new',
            'add',
            'editStd',
            'cloneStd',
            'newStd',
            'packageDependency'
    };
    private Id parentStandardControllerId;
    private Id devHubOrgId;
    private Id selectedOrgId;
    private Id selectedOrgIdFromDxOperation;
    private Id dxRepositoryId;
    private Id dxUserStoryId;
    private String dxDeploymentFlowMode;
    private String dxBranchName;
    private String dxUserStoryName;
    private String dxScratchOrgName;
    private String sourceSelections;
    private String componentMode;
    private String controllerKey;
    private Boolean showButtons;
    private Boolean showTemplateSaveAsButton;
    private Boolean showTemplateUpdateButton;
    private Boolean showTemplateButtons;
    private Object metadataSource;
    private SObjectType parentStandardControllerType;
    private ScratchOrgWizardPageBase pageController;
    private List<SelectOption> devHubOptions;
    private List<DeploymentInfo> deploymentInfoList;

    /**
     * @description this method enables or disables Save and Update buttons depending on the current screen there user
     * is navigating (so called "Component Mode").
     *
     * @param showSaveAs is a flag indicating whether the Save As button should be displayed on the page.
     * @param showUpdate is a flag indicating whether the Update button should be displayed on the page.
     */
    private void enableButtons(Boolean showSaveAs, Boolean showUpdate) {
        showTemplateSaveAsButton = showSaveAs;
        showTemplateUpdateButton = showUpdate;
    }

    /**
     * @description a setter for the parentStandardControllerId variable.
     *
     * @param parentStandardControllerId is the id of the parent page controller that contains this component in it.
     */
    public void setParentStandardControllerId(Id parentStandardControllerId) {
        this.parentStandardControllerId = parentStandardControllerId;
    }

    /**
     * @description a getter for the parentStandardControllerId variable.
     *
     * @return the id of the parent page controller that contains this component in it.
     */
    public Id getParentStandardControllerId() {
        return this.parentStandardControllerId;
    }

    /**
     * @description a setter for the devHubOrgId private variable.
     *
     * @param devHubOrgId is the id of the target Dev Hub org that was selected by the user.
     */
    public void setDevHubOrgId(Id devHubOrgId) {
        this.devHubOrgId = devHubOrgId;
    }

    /**
     * @description a getter for the devHubOrgId private variable.
     *
     * @return the id of the target Dev Hub org that was selected by the user.
     */
    public Id getDevHubOrgId() {
        return this.devHubOrgId;
    }

    /**
     * @description a setter for the selectedOrgId private variable.
     *
     * @param selectedOrgId is the id of the org from which any available artifacts are loaded into the page as a
     * dropdown list so the user can select and install them in a new or existing scratch org.
     */
    public void setSelectedOrgId(Id selectedOrgId) {
        this.selectedOrgId = selectedOrgId;
    }

    /**
     * @description a getter for the selectedOrgId private variable.
     *
     * @return the id of the org that was selected by the user as the source of the artifacts that are shown on the page
     * as a dropdown list.
     */
    public Id getSelectedOrgId() {
        return this.selectedOrgId;
    }

    /**
     * @description a setter for the selectedOrgIdFromDxOperation private variable.
     *
     * @param selectedOrgIdFromDxOperation is the id of the target scratch org where to perform the DX operations.
     */
    public void setSelectedOrgIdFromDxOperation(Id selectedOrgIdFromDxOperation) {
        this.selectedOrgIdFromDxOperation = selectedOrgIdFromDxOperation;
    }

    /**
     * @description a getter for the selectedOrgIdFromDxOperation private variable.
     *
     * @return the id of the selected scratch org on which to perform the DX operations.
     */
    public Id getSelectedOrgIdFromDxOperation() {
        return this.selectedOrgIdFromDxOperation;
    }

    /**
     * @description a setter for the dxRepositoryId private variable.
     *
     * @param dxRepositoryId is the id of the target DX repository where the source metadata lives.
     */
    public void setDxRepositoryId(Id dxRepositoryId) {
        this.dxRepositoryId = dxRepositoryId;
    }

    /**
     * @description a getter method for the dxRepositoryId private variable.
     *
     * @return the id of the target DX repository where the source metadata lives.
     */
    public Id getDxRepositoryId() {
        return this.dxRepositoryId;
    }

    /**
     * @description a setter for the dxUserStoryId private variable.
     *
     * @param dxUserStoryId is the id of the user story from which a new scratch org is to be created. Once the scratch
     * org is successfully created, the user story metadata is installed in it.
     */
    public void setDxUserStoryId(Id dxUserStoryId) {
        this.dxUserStoryId = dxUserStoryId;
    }

    /**
     * @description a getter for the dxUserStoryId private variable.
     *
     * @return the id of a user story for which a new scratch org will be created for development and testing purposes.
     */
    public Id getDxUserStoryId() {
        return this.dxUserStoryId;
    }

    /**
     * @description a setter for the dxDeploymentFlowMode private variable.
     *
     * @param dxDeploymentFlowMode is the pipeline Copado DX mode selected by the user (Git Package, Branch or
     * Salesforce Package).
     */
    public void setDxDeploymentFlowMode(String dxDeploymentFlowMode) {
        this.dxDeploymentFlowMode = dxDeploymentFlowMode;
    }

    /**
     * @description a getter for the dxDeploymentFlowMode private variable.
     *
     * @return the current pipeline Copado DX mode that was selected by the user (Git Package, Branch or Salesforce
     * Package).
     */
    public String getDxDeploymentFlowMode() {
        return this.dxDeploymentFlowMode;
    }

    /**
     * @description a setter for the dxBranchName private variable.
     *
     * @param dxBranchName is the name of the git branch containing the metadata sources in DX format.
     */
    public void setDxBranchName(String dxBranchName) {
        this.dxBranchName = dxBranchName;
    }

    /**
     * @description a getter for the dxBranchName private variable.
     *
     * @return the name of the git branch containing the metadata sources in DX format.
     */
    public String getDxBranchName() {
        return this.dxBranchName;
    }

    /**
     * @description a setter for the dxUserStoryName private variable.
     *
     * @param dxUserStoryName is the name of the user story for which a scratch org will be created.
     */
    public void setDxUserStoryName(String dxUserStoryName) {
        this.dxUserStoryName = dxUserStoryName;
    }

    /**
     * @description a getter for the dxUserStoryName private variable.
     *
     * @return the name of the user story for which a scratch org will be created.
     */
    public String getDxUserStoryName() {
        return this.dxUserStoryName;
    }

    /**
     * @description a setter for the dxScratchOrgName private variable.
     *
     * @param dxScratchOrgName is the name of the new scratch org that will be created by the user.
     */
    public void setDxScratchOrgName(String dxScratchOrgName) {
        this.dxScratchOrgName = dxScratchOrgName;
    }

    /**
     * @description a getter for the dxScratchOrgName private variable.
     *
     * @return the name of the new scratch org that will be created by the user.
     */
    public String getDxScratchOrgName() {
        return this.dxScratchOrgName;
    }

    /**
     * @description a setter for the sourceSelections private variable.
     *
     * @param sourceSelections is either a comma-separated list of artifact ids or a source branch name from where
     * to pull the selected metadata that will be installed in the target scratch org.
     */
    public void setSourceSelections(String sourceSelections) {
        this.sourceSelections = sourceSelections;
    }

    /**
     * @description a getter for the sourceSelections private variable.
     *
     * @return a string with the selected metadata source(s) that will be installed in the target scratch org.
     */
    public String getSourceSelections() {
        return this.sourceSelections;
    }

    /**
     * @description a setter for the componentMode private variable.
     *
     * @param componentMode is the current screen on which the user is working. Different screens may be displayed
     * to the user depending on where he is opening the DX Operations page from.
     */
    public void setComponentMode(String componentMode) {
        if(componentMode != null && componentModes.contains(componentMode)) {
            this.componentMode = componentMode;
        } else {
            throw new ComponentSetupException('Component mode is required.');
        }
    }

    /**
     * @description a getter for the componentMode private variable.
     *
     * @return the current screen on which the user is within the DX Operations page.
     */
    public String getComponentMode() {
        return this.componentMode;
    }

    /**
     * @description a setter for the controllerKey private variable.
     *
     * @param controllerKey is the name of one of the page's child component controllers that is to be stored in a
     * map holding all the child component controllers' references in it.
     */
    public void setControllerKey(String controllerKey) {
        if(controllerKey != null) {
            this.controllerKey = controllerKey;
            if(pageController != null) {
                pageController.setComponentControllerMap(this.controllerKey, this);
            }
        }
    }

    /**
     * @description a getter for the controllerKey private variable.
     *
     * @return the name of the page child component controller that is calling it. This name corresponds to the actual
     * reference of the child component controller held in the componentControllerMap private variable.
     */
    public String getControllerKey() {
        return this.controllerKey;
    }

    /**
     * @description a setter for the showButtons private variable.
     *
     * @param showButtons is a flag indicating whether action buttons should be enabled on a component or not.
     */
    public void setShowButtons(Boolean showButtons) {
        this.showButtons = showButtons;
    }

    /**
     * @description a getter for the showButtons private variable.
     *
     * @return a flag indicating whether action buttons on the current component should are enabled or not.
     */
    public Boolean getShowButtons() {
        return this.showButtons;
    }

    /**
     * @description a setter for the showTemplateSaveAsButton private variable.
     *
     * @param showTemplateSaveAsButton is a flag which enables the Save As button on the Scratch Org Template
     * component.
     */
    public void setShowTemplateSaveAsButton(Boolean showTemplateSaveAsButton) {
        this.showTemplateSaveAsButton = showTemplateSaveAsButton;
    }

    /**
     * @description a getter for the showTemplateSaveAsButton private variable.
     *
     * @return a flag indicating if the Save As button is currently enabled on the Scratch Org Template component.
     */
    public Boolean getShowTemplateSaveAsButton() {
        return this.showTemplateSaveAsButton;
    }

    /**
     * @description a setter for the showTemplateUpdateButton private variable.
     *
     * @param showTemplateUpdateButton is a flag which enables the Update (template) button on the Scratch Org Template
     * component.
     */
    public void setShowTemplateUpdateButton(Boolean showTemplateUpdateButton) {
        this.showTemplateUpdateButton = showTemplateUpdateButton;
    }

    /**
     * @description a getter for the showTemplateUpdateButton private variable.
     *
     * @return a flag indicating if the Update (template) button is currently enabled on the Scratch Org Template
     * component.
     */
    public Boolean getShowTemplateUpdateButton() {
        return this.showTemplateUpdateButton;
    }

    /**
     * @description a setter for the showTemplateButtons private variable. Buttons on the Scratch Org Template
     * component are enabled depending on the current mode of the page that is driven by the componentMode private
     * variable.
     *
     * @param showTemplateButtons is a flag indicating whether action buttons should be enabled on the Scratch Org
     * Template component or not.
     */
    public void setShowTemplateButtons(Boolean showTemplateButtons) {
        if(showTemplateButtons == null) {
            this.showTemplateButtons = true;
            enableButtons(true, true);
        } else {
            this.showTemplateButtons = showTemplateButtons;
            showTemplateSaveAsButton = showTemplateButtons;
            showTemplateUpdateButton = showTemplateButtons;
        }

        switch on componentMode {
            when 'editStd', 'add' {
                enableButtons(true, true);
            } when 'cloneStd' {
                enableButtons(true, false);
            }
        }
    }

    /**
     * @description a getter for the showTemplateButtons private variable.
     *
     * @return a flag indicating if action buttons are enabled on the Scratch Org Template component org not.
     */
    public Boolean getShowTemplateButtons() {
        return this.showTemplateButtons;
    }

    /**
     * @description a setter for the metadataSource private variable.
     *
     * @param metadataSource is the metadata source information retrieved from an attachment called 'metadataSources'
     * located under a selected scratch org. This attachment may or may not exist. If it exists, metadata sources will
     * be automatically set from the attachment information, otherwise the user is free to setup his own metadata
     * sources on the DX Operations page.
     */
    public void setMetadataSource(Object metadataSource) {
        this.metadataSource = metadataSource;
    }

    /**
     * @description a getter for the metadataSource private variable.
     *
     * @return the metadataSources.json information that was retrieved from an attachment located under a selected
     * scratch org.
     */
    public Object getMetadataSource() {
        return this.metadataSource; 
    }

    /**
     * @description a setter for the parentStandardControllerType private variable.
     *
     * @param parentStandardControllerType is the SObjectType of the parent page's standard controller that holds the
     * current component in it. At the time of this writing, the only standard controller-driven page that references
     * this component is CreateUserStoryScratchOrg, based on the User_Story__c object.
     */
    public void setParentStandardControllerType(SObjectType parentStandardControllerType) {
        this.parentStandardControllerType = parentStandardControllerType;
    }

    /**
     * @description a getter for the parentStandardControllerType private variable.
     *
     * @return the SObjectType of the parent page's standard controller object.
     */
    public SObjectType getParentStandardControllerType() {
        return this.parentStandardControllerType;
    }

    /**
     * @description a setter for the pageController private variable. At the time of this writing, only two DX pages
     * use scratch org components: DXOperations and CreateUserStoryScratchOrg. Depending on the current parent page,
     * different variables are preset upon page load.
     *
     * @param pageController is the controller of the parent page which extends the generic ScratchOrgWizardPageBase
     * class that communicates with the child component controllers using this class (ScratchOrgWizardComponentBase).
     */
    public void setPageController(ScratchOrgWizardPageBase pageController) {
        if(pageController == null) {
            return;
        }
        this.pageController = pageController;
        if(parentStandardControllerId != null) {
            setParentStandardControllerType(parentStandardControllerId.getSObjectType());
        }
        this.pageController.setChildComponentController(this);
        if(this.pageController instanceof DXOperationController) {
            Id selectedOrgId = ((DXOperationController) this.pageController).selectedOrgId;
            if(String.isNotBlank(selectedOrgId)) {
                setDevHubOrgId(selectedOrgId);
                setSelectedOrgIdFromDxOperation(selectedOrgId);
                setMetadataSource(((DXOperationController) this.pageController).metadataSource);
                setDxDeploymentFlowMode(((DXOperationController) this.pageController).dxDeploymentFlowMode);
                setDxRepositoryId(((DXOperationController) this.pageController).dxDeploymentFlowGitRepo);
                setDxBranchName(((DXOperationController) this.pageController).dxBranchName);
            } else {
                Id userStoryId = ((DXOperationController) this.pageController).userStoryInfo.usId;
                if(String.isNotBlank(userStoryId)) {
                    setDxUserStoryId(userStoryId);
                    String usName = ((DXOperationController) this.pageController).userStoryInfo.usName;
                    setDxUserStoryName(String.isNotBlank(usName) ? usName.replace('US-', 'SO-') : '');
                }
            }
        } else if(this.pageController instanceof CreateUserStoryScratchOrgController) {
            try {
                setDxScratchOrgName(((CreateUserStoryScratchOrgController) this.pageController).getOrgTemplate().getOrgName());
            } catch(Exception ex) {
                // Can stay silent since there no actual dependency to this variable;
            }
            setDxRepositoryId(((CreateUserStoryScratchOrgController) this.pageController).dxRepositoryId);
            Id userStoryId = ((CreateUserStoryScratchOrgController) this.pageController).thisUserStory.Id;
            if(String.isNotBlank(userStoryId)) {
                setDxUserStoryId(userStoryId);
                setDxUserStoryName(orgName());
                String depFlowMode = ((CreateUserStoryScratchOrgController) this.pageController).dxDeploymentFlowMode;
                if(String.isNotBlank(depFlowMode)) {
                    setDxDeploymentFlowMode(depFlowMode);
                }
            }
        } 
    }

    private String orgName() {
        String result = storyName();
        String overwrite = getDxUserStoryName();
    
        return ( !result.equals(overwrite) ) ?  String.isNotBlank(overwrite) ? overwrite : result : result;
    }
    
    private String storyName() {
        return (((CreateUserStoryScratchOrgController) pageController)
                    .thisUserStory.Name
                    .replace('US-', 'SO-'));
    }
    
    /**
     * @description a getter for the pageController private variable.
     *
     * @return an instance of the current parent page controller.
     */
    public ScratchOrgWizardPageBase getPageController() {
        return this.pageController;
    }

    /**
     * @description a setter for the devHubOptions private variable.
     *
     * @param devHubOptions is a list of all the available Dev Hub orgs a user can work with.
     */
    public void setDevHubOptions(List<SelectOption> devHubOptions) {
        this.devHubOptions = devHubOptions;
    }

    /**
     * @description a getter for the devHubOptions private variable.
     *
     * @return a list of all the available Dev Hub orgs a user can work with.
     */
    public List<SelectOption> getDevHubOptions() {
        return this.devHubOptions;
    }

    /**
     * @description adds a new Dev Hub org option to the devHubOptions list.
     *
     * @param devHubOption is the Dev Hub org that will be included in the available Dev Hub options for the user.
     */
    public void addDevHubOption(SelectOption devHubOption) {
        if(this.devHubOptions == null) {
            setDevHubOptions(new List<SelectOption>());
        }
        this.devHubOptions.add(devHubOption);
    }

    /**
     * @description a setter for the deploymentInfoList private variable.
     *
     * @param deploymentInfoList is a list of Deployment Extensions that will be loaded into the target scratch org
     * along with other items like metadata.
     */
    public void setDeploymentInfoList(List<DeploymentInfo> deploymentInfoList) {
        this.deploymentInfoList = deploymentInfoList;
    }

    /**
     * @description a getter for the deploymentInfoList private variable.
     *
     * @return a list of the current Deployment Extensions to be loaded into the target scratch org.
     */
    public List<DeploymentInfo> getDeploymentInfoList() {
        return this.deploymentInfoList;
    }

    /**
     * @description clears the current Deployment Extensions list.
     */
    public void resetDeploymentInfoList() {
        this.deploymentInfoList = new List<DeploymentInfo>();
    }

    /**
     * @description adds a new Deployment Extension to be loaded into the selected scratch org.
     *
     * @param scratchOrgId is the selected scratch org id to which the extension is to be deployed.
     * @param scratchOrgName is the selected scratch org name to which the extension is to be deployed.
     * @param deploymentId is the id of an existing deployment that serves as a template for Deployment Extensions
     * that are loaded into scratch orgs. The deployment record status is Draft, meaning that it has not been used
     * to perform any actual deployments from a source to a target org.
     * @param deploymentName is the name of the selected deployment template.
     */
    public void addDeploymentInfo(String scratchOrgId, String scratchOrgName, Id deploymentId, String deploymentName) {
        if(this.deploymentInfoList == null) {
            resetDeploymentInfoList();
        }
        this.deploymentInfoList.add(new DeploymentInfo(scratchOrgId, scratchOrgName, deploymentId, deploymentName));
    }

    /**
     * @description removes a Deployment Extension from the current extensions list.
     *
     * @param index is the index at which the target extension item is located.
     */
    public void removeDeploymentInfo(Integer index) {
        try {
            this.deploymentInfoList.remove(index);
        } catch(Exception ex) {
            throw new ComponentSetupException(ex.getMessage());
        }
    }

    /**
     * @description retrieves one Deployment Extension item from the deploymentInfoList private variable (if it exists).
     *
     * @param index is the index at which the target extension item is located.
     *
     * @return the selected Deployment Extension item.
     */
    public DeploymentInfo getDeploymentInformationAt(Integer index) {
        try {
            return this.deploymentInfoList.get(index);
        } catch(Exception ex) {
            throw new ComponentSetupException(ex.getMessage());
        }
    }

    /**
     * @description this method generates a map of destination orgs ordered by the extension deployments that are
     * targeting those destination orgs.
     *
     * @param destinationOrgId is the id of the destination org to which extensions are to be deployed.
     *
     * @return a map of destination orgs ordered by extension deployments (by their id).
     */
    public Map<Id, Destination_Org__c> getDestinationOrgMap(Id destinationOrgId) {
        Map<Id, Destination_Org__c> destinationOrgMap = new Map<Id, Destination_Org__c>();
        for(DeploymentInfo deploymentInfo : getDeploymentInfoList()) {
            Destination_Org__c destinationOrg = new Destination_Org__c();
            destinationOrg.Deployment__c = deploymentInfo.getDeploymentId();
            destinationOrg.To_Org__c = destinationOrgId;
            destinationOrgMap.put(deploymentInfo.getDeploymentId(), destinationOrg);
        }
        return destinationOrgMap;
    }

    /**
     * @description this method extracts all the deployment ids from the deploymentInfo list (if any)
     *
     * @return a set of deployment ids of the selected extension deployment records.
     */
    public Set<Id> getDeploymentIdsFromDeploymentInformationList() {
        Set<Id> deploymentIds = new Set<Id>();
        for(DeploymentInfo deploymentInfo: getDeploymentInfoList()) {
            deploymentIds.add(deploymentInfo.getDeploymentId());
        }
        return deploymentIds;
    }

    /**
     * @description this class is a wrapper for Deployment Extension records that holds information about a selected
     * scratch org and the deployment extension template that is to be loaded into it.
     */
    public class DeploymentInfo {
        private Id scratchOrgId;
        private String scratchOrgName;
        private Id deploymentId;
        private String deploymentName;

        public DeploymentInfo(Id scratchOrgId, String scratchOrgName, Id deploymentId, String deploymentName) {
            setScratchOrgId(scratchOrgId);
            setScratchOrgName(scratchOrgName);
            setDeploymentId(deploymentId);
            setDeploymentName(deploymentName);
        }

        /**
         * @description a setter for the scratchOrgId private variable.
         *
         * @param scratchOrgId is the id of the target scratch org where the extension is to be deployed.
         */
        public void setScratchOrgId(Id scratchOrgId) {
            this.scratchOrgId = scratchOrgId;
        }

        /**
         * @description a getter for the scratchOrgId private variable.
         *
         * @return the id of the target scratch org.
         */
        public Id getScratchOrgId() {
            return this.scratchOrgId;
        }

        /**
         * @description a setter for the scratchOrgName private variable.
         *
         * @param scratchOrgName is the name of the target scratch org where the extension is to be deployed.
         */
        public void setScratchOrgName(String scratchOrgName) {
            this.scratchOrgName = scratchOrgName;
        }

        /**
         * @description a getter for the scratchOrgName private variable.
         *
         * @return the name of the target scratch org.
         */
        public String getScratchOrgName() {
            return this.scratchOrgName;
        }

        /**
         * @description a setter for the deploymentId private variable.
         *
         * @param deploymentId is the id of the deployment extension template that will be loaded into the target
         * scratch org.
         */
        public void setDeploymentId(Id deploymentId) {
            this.deploymentId = deploymentId;
        }

        /**
         * @description a getter for the deploymentId private variable.
         *
         * @return the id of the deployment extension template that was selected by the user.
         */
        public Id getDeploymentId() {
            return this.deploymentId;
        }

        /**
         * @description a setter for the deploymentName private variable.
         *
         * @param deploymentName is the name of the deployment extension template that will be loaded into the target
         * scratch org.
         */
        public void setDeploymentName(String deploymentName) {
            this.deploymentName = deploymentName;
        }

        /**
         * @description a getter for the deploymentName private variable.
         *
         * @return the name of the selected deployment extension template.
         */
        public String getDeploymentName() {
            return this.deploymentName;
        }
    }

    /**
     * @description this class serves a as custom exception type to indicate that any possible errors are coming
     * from the parent class when it is thrown.
     */
    public class ComponentSetupException extends Exception {}
}