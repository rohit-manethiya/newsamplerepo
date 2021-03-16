/**
 * @description This class serves as a DTO for the generation of a Project Definition (sfdx-project.json) file
 * when generating new packages or installing existing packages in a scratch org.
 */
public with sharing class DXProject {
    private List<ProjectArtifact> packageDirectories;
    private String namespace;
    private String sfdcLoginUrl;
    private String sourceApiVersion;
    private Map<String, String> packageAliases;

    public DXProject(String namespace, String sfdcLoginUrl, String sourceApiVersion) {
        this.packageDirectories = new List<ProjectArtifact>();
        this.namespace = namespace;
        this.sfdcLoginUrl = sfdcLoginUrl;
        this.sourceApiVersion = sourceApiVersion;
        this.packageAliases = new Map<String, String>();
    }

    /**
    * @description When a Project Definition file is created or updated, only mandatory and non-empty attributes
    * shall be included. The method checks whether the packageAliases attribute is empty and deallocates the list
    * so the attribute won't be added to the JSON file.
    */
    public void clearAliasesIfEmpty() {
        if(this.packageAliases != null && this.packageAliases.isEmpty()) {
            this.packageAliases = null;
        }
    }

    /**
     * @description Assigns a list of package directories related to the current DX Project to be included in
     * the Project Definition file.
     *
     * @param packageDirectories is the list of project artifact directories to be included in the Project Definition
     * file of a DX Project.
     */
    public void setPackageDirectories(List<ProjectArtifact> packageDirectories) {
        initPackageDirectories();
        this.packageDirectories.addAll(packageDirectories);
    }

    /**
     * @description retrieves a list of project artifact directories to be included in the Project Definition file of
     * a DX Project.
     *
     * @return a list of project artifact directories of a given DX Project.
     */
    public List<ProjectArtifact> getPackageDirectories() {
        initPackageDirectories();
        return this.packageDirectories;
    }

    /**
     * @description instantiates a new, empty list of project artifact directories to be included in the Project
     * Definition file of a DX Project.
     */
    private void initPackageDirectories() {
        if(this.packageDirectories == null) {
            this.packageDirectories = new List<ProjectArtifact>();
        }
    }

    /**
     * @description removes all the project artifact directories that were added to a Project Definition file of a
     * DX Project.
     */
    public void clearPackageDirectories() {
        this.packageDirectories = new List<ProjectArtifact>();
    }

    /**
     * @description Assigns a map of artifact aliases related to the current DX Project to be included in
     * the Project Definition file.
     *
     * @param packageAliases is the map of project artifact aliases to be included in the Project Definition
     * file of a DX Project.
     */
    public void setPackageAliases(Map<String, String> packageAliases) {
        initPackageAliasesMap();
        this.packageAliases.putAll(packageAliases);
    }

    /**
     * @description retrieves a list of artifact aliases to be included in the Project Definition file of
     * a DX Project.
     *
     * @return a map of project artifact aliases of a given DX Project.
     */
    public Map<String, String> getPackageAliases() {
        initPackageAliasesMap();
        return this.packageAliases;
    }

    /**
     * @description instantiates a new, empty map of artifact aliases to be included in the Project
     * Definition file of a DX Project.
     */
    private void initPackageAliasesMap() {
        if(this.packageAliases == null) {
            this.packageAliases = new Map<String, String>();
        }
    }

    /**
     * @description a getter for the namespace private variable.
     *
     * @return the current DX Project's package namespace.
     */
    public String getNamespace() {
        return this.namespace;
    }

    /**
     * @description a setter for the namespace private variable.
     *
     * @param namespace is the namespace of the current Dx Project's package(s).
     */
    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }

    /**
     * @description a getter for the sfdxLoginUrl private variable.
     *
     * @return the default SFDC logic URL for the target dev hub org.
     */
    public String getSfdcLoginUrl() {
        return this.sfdcLoginUrl;
    }

    /**
     * @description a setter for the sfdcLoginUrl private variable.
     *
     * @param sfdcLoginUrl is the SFDC login URL of the target dev hub org.
     */
    public void setSfdcLoginUrl(String sfdcLoginUrl) {
        this.sfdcLoginUrl = sfdcLoginUrl;
    }

    /**
     * @description a getter for the sourceApiVersion private variable.
     *
     * @return the API version of the current DX Project.
     */
    public String getSourceApiVersion() {
        return this.sourceApiVersion;
    }

    /**
     * @description a setter for the sourceApiVersion private variable.
     *
     * @param sourceApiVersion is the API version of the current DX Project.
     */
    public void setSourceApiVersion(String sourceApiVersion) {
        this.sourceApiVersion = sourceApiVersion;
    }
}