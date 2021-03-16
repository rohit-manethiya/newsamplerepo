/**
 * @description this class serves as a DTO for encapsulating DX Projects' artifact-related information, such as version,
 * name of the parent package, directory and dependencies. It is used to generate a DX Project Definition file
 * (sfdx-project.json) when a user wants to install metadata in an org.
 */
public with sharing class ProjectArtifact {
    private String path;
    private String packageName;
    private String definitionFile;
    private String versionName;
    private String versionNumber;
    private String versionDescription;
    private Boolean defaultArtifact;
    private List<PackageDependency> dependencies;

    public ProjectArtifact(String path, Boolean defaultArtifact) {
        this.path = path;
        this.defaultArtifact = defaultArtifact;
        this.definitionFile = 'config/' + DXLabel.DEFINITION_FILE;
        this.dependencies = new List<PackageDependency>();
    }

    public ProjectArtifact(String path, String packageName, Boolean defaultArtifact, Artifact_Version__c artifactVersion) {
        this.path = path;
        this.packageName = packageName;
        this.definitionFile = 'config/' + DXLabel.DEFINITION_FILE;
        this.versionName = artifactVersion.Name;
        this.versionNumber = artifactVersion.Version_number__c;
        this.versionDescription = artifactVersion.Version_Description__c;
        this.defaultArtifact = defaultArtifact;
        this.dependencies = new List<PackageDependency>();
    }

    /**
     * @description a setter for the path private variable.
     *
     * @param path is the directory under which the artifact lives.
     */
    public void setPath(String path) {
        this.path = path;
    }

    /**
     * @description a getter for the path private variable.
     *
     * @return the directory under which the current artifact lives.
     */
    public String getPath() {
        return this.path;
    }

    /**
     * @description a setter for the packageName private variable.
     *
     * @param packageName is the name of the parent artifact.
     */
    public void setPackageName(String packageName) {
        this.packageName = packageName;
    }

    /**
     * @description a getter for the packageName private variable.
     *
     * @return the name of the parent artifact.
     */
    public String getPackageName() {
        return this.packageName;
    }

    /**
     * @description a setter for the definitionFile private variable.
     *
     * @param definitionFile is the name of the Scratch Org Definition file (project-scratch-def.json) of the given
     * artifact.
     */
    public void setDefinitionFile(String definitionFile) {
        this.definitionFile = definitionFile;
    }

    /**
     * @description a getter for the definitionFile private variable.
     *
     * @return the name of the Scratch Org Definition file of the given artifact.
     */
    public String getDefinitionFile() {
        return this.definitionFile;
    }

    /**
     * @description a setter for the versionName private variable.
     *
     * @param versionName is the name of the latest version of the current artifact.
     */
    public void setVersionName(String versionName) {
        this.versionName = versionName;
    }

    /**
     * @description a getter for the versionName private variable.
     *
     * @return the name of the latest version of the current artifact.
     */
    public String getVersionName() {
        return this.versionName;
    }

    /**
     * @description a setter for the versionNumber private variable.
     *
     * @param versionNumber is the number of latest version of the current artifact.
     */
    public void setVersionNumber(String versionNumber) {
        this.versionNumber = versionNumber;
    }

    /**
     * @description a getter for the versionNumber private variable.
     *
     * @return the number of the latest version of the current artifact.
     */
    public String getVersionNumber() {
        return this.versionNumber;
    }

    /**
     * @description a setter for the versionDescription private variable.
     *
     * @param versionDescription is the optional description a user gives to the artifact version.
     */
    public void setVersionDescription(String versionDescription) {
        this.versionDescription = versionDescription;
    }

    /**
     * @description a getter for the versionDescription private variable.
     *
     * @return the current artifact version description.
     */
    public String getVersionDescription() {
        return this.versionDescription;
    }

    /**
     * @description a setter for the defaultArtifact private variable.
     *
     * @param defaultArtifact is a flag indicating if the given artifact is the default one in the Project Definition
     * file (sfdx-project.json).
     */
    public void setDefaultArtifact(Boolean defaultArtifact) {
        this.defaultArtifact = defaultArtifact;
    }

    /**
     * @description a getter for the defaultArtifact private variable.
     *
     * @return a flag indicating if the given artifact is the default one in the Project Definition file
     * (sfdx-project.json).
     */
    public Boolean getDefaultArtifact() {
        return this.defaultArtifact;
    }

    /**
     * @description this method adds a dependency to the list of all artifact dependencies.
     *
     * @param dependency is an artifact version on which the current artifact depends.
     */
    public void addDependency(PackageDependency dependency) {
        if(this.dependencies == null) {
            this.dependencies = new List<PackageDependency>();
        }
        this.dependencies.add(dependency);
    }

    /**
     * @description a setter for the dependencies private variable.
     *
     * @param dependencies is a list of artifact versions that depend on or on which the current artifact version
     * depends.
     */
    public void setDependencies(List<PackageDependency> dependencies) {
        if(this.dependencies == null) {
            this.dependencies = new List<PackageDependency>();
        }
        this.dependencies.addAll(dependencies);
    }

    /**
    * @description When a Project Definition file is created or updated, only mandatory and non-empty attributes
    * shall be included in it. The method checks whether the dependencies attribute is empty and clears the list
    * so the attribute won't be added to the JSON file as null.
    */
    public void checkIfDependenciesAreEmptyAndClearArray() {
        if(this.dependencies != null && this.dependencies.isEmpty()) {
            this.dependencies = null;
        }
    }
}