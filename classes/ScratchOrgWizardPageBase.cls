/**
 * @description this virtual class serves as a communication medium between custom component controllers and their
 * parent Visualforce page.
 * @see https://developer.salesforce.com/page/Controller_Component_Communication
 */
public with sharing virtual class ScratchOrgWizardPageBase {
    private ScratchOrgWizardComponentBase childComponentController;
    private Map<String, ScratchOrgWizardComponentBase> componentControllerMap;
    private Id devHubOrgId;
    private Id standardControllerId;
    private String JSONSettingsFeatures;
    private ScratchOrgDefinition orgTemplate;
    private DXProject artifactProject;

    /**
     * @description a getter for the current instance of this page controller.
     *
     * @return the current controller instance.
     */
    public ScratchOrgWizardPageBase getThis() {
        return this;
    }

    /**
     * @description a setter for the childComponentController private variable.
     *
     * @param childComponentController is a reference to a child component controller of the current page.
     */
    public virtual void setChildComponentController(ScratchOrgWizardComponentBase childComponentController) {
        this.childComponentController = childComponentController;
    }

    /**
     * @description a getter for the childComponentController private variable.
     *
     * @return a reference of the current child component controller of the current page.
     */
    public virtual ScratchOrgWizardComponentBase getChildComponentController() {
        return this.childComponentController;
    }

    /**
     * @description a setter for the componentControllerMap private variable.
     *
     * @param key is the name of a child component to which the component controller corresponds.
     * @param compController is the child component controller that belongs to the current page.
     */
    public virtual void setComponentControllerMap(String key, ScratchOrgWizardComponentBase compController) {
        if(componentControllerMap == null) {
            this.componentControllerMap = new Map<String, ScratchOrgWizardComponentBase>();
        }
        this.componentControllerMap.put(key, compController);
    }

    /**
     * @description a getter for the componentControllerMap private variable.
     *
     * @return a map with references of child component controllers of the current page.
     */
    public virtual Map<String, ScratchOrgWizardComponentBase> getComponentControllerMap() {
        return this.componentControllerMap;
    }

    /**
     * @description a getter for individual component controller references stored in the componentControllerMap
     * private variable.
     *
     * @param key is the name of a child component to which the component controller corresponds.
     *
     * @return a reference of the child component controller that belongs to the current page.
     */
    public virtual ScratchOrgWizardComponentBase getComponentController(String key) {
        return this.componentControllerMap.get(key);
    }

    /**
     * @description a setter for the devHubOrgId private variable.
     *
     * @param devHubOrgId is the id of the target Dev Hub org that was selected by the user.
     */
    public void setDevHubOrgId(String devHubOrgId) {
        this.devHubOrgId = devHubOrgId;                 // TODO: CHANGE DATA TYPE IN METHOD SIGNATURE TO ID
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
     * @description a setter for the standardControllerId private variable.
     *
     * @param standardControllerId is the id of the child page controller that inherits this controller's functionality.
     */
    public void setStandardControllerId(Id standardControllerId) {
        this.standardControllerId = standardControllerId;
    }

    /**
     * @description a getter for the standardControllerId private variable.
     *
     * @return the id of the current child page controller that inherits this controller's functionality.
     */
    public Id getStandardControllerId()  {
        return this.standardControllerId;
    }

    /**
     * @description a setter for the JSONSettingsFeatures private variable.
     *
     * @param JSONSettingsFeatures is the JSON string with additional settings to be included in the scratch org
     * creation process.
     */
    public void setJSONSettingsFeatures(String JSONSettingsFeatures) {
        this.JSONSettingsFeatures = JSONSettingsFeatures;
    }

    /**
     * @description a getter for the JSONSettingsFeatures private variable.
     *
     * @return the JSON string with additional settings to be included in the scratch org creation process.
     */
    public String getJSONSettingsFeatures() {
        return this.JSONSettingsFeatures;
    }

    /**
     * @description a setter for the orgTemplate private variable.
     *
     * @param orgTemplate is the Scratch Org Definition template created by the user to create a scratch org with
     * predefined parameters.
     */
    public void setOrgTemplate(ScratchOrgDefinition orgTemplate) {
        this.orgTemplate = orgTemplate;
    }

    /**
     * @description a getter for the orgTemplate private variable.
     *
     * @return the Scratch Org Definition template that was created by the user to create scratch orgs with predefined
     * parameters.
     */
    public ScratchOrgDefinition getOrgTemplate() {
        return this.orgTemplate;
    }

    /**
     * @description a setter for the artifactProject private variable.
     *
     * @param artifactProject is the current DX Project built by a user that contains all the metadata source and
     * directory information that needs to be installed in a scratch org.
     */
    public void setArtifactProject(DXProject artifactProject) {
        this.artifactProject = artifactProject;
    }

    /**
     * @description a getter for the artifactProject private variable.
     *
     * @return the DX Project that was defined by the user to install metadata in a selected scratch org.
     */
    public DXProject getArtifactProject() {
        return this.artifactProject;
    }
}