/**
 * @description this is a wrapper class for artifact versions that form part of a DX Project definition file. Entities
 * of this type define some additional rules/paramters for artifact version installation, such as order and any
 * existing artifact dependencies.
 */
public with sharing class ArtifactVersion {
    private Integer order;
    private String includedBy;
    private String artifactName;
    private Artifact_Version__c version;

    public ArtifactVersion(String includedBy, String artifactName, Artifact_Version__c version) {
        this.includedBy = includedBy;
        this.artifactName = artifactName;
        this.version = version;
    }

    /**
     * @description a setter for the order private variable.
     *
     * @param order is the actual order in which this artifact version will be installed along with other selected
     * versions.
     */
    public void setOrder(Integer order) {
        this.order = order;
    }

    /**
     * @description a getter for the order private variable.
     *
     * @return the order installation index for the given artifact version.
     */
    public Integer getOrder() {
        return this.order;
    }

    /**
     * @description a setter for the includedBy private variable.
     *
     * @param includedBy is the name of the parent artifact that has a dependency on the given artifact and hence needs
     * to be included in the package bundle for a successful installation.
     */
    public void setIncludedBy(String includedBy) {
        this.includedBy = includedBy;
    }

    /**
     * @description a getter for the includedBy private variable.
     *
     * @return the name of the parent artifact that has a dependency on the given artifact version.
     */
    public String getIncludedBy() {
        return this.includedBy;
    }

    /**
     * @description a setter for the artifactName private variable.
     *
     * @param artifactName is the name of the main artifact to be installed in the target org.
     */
    public void setArtifactName(String artifactName) {
        this.artifactName = artifactName;
    }

    /**
     * @description a getter for the artifactName private variable.
     *
     * @return the name of the main artifact that is part of the current package bundle.
     */
    public String getArtifactName() {
        return this.artifactName;
    }

    /**
     * @description a setter for the version private variable.
     *
     * @param version is the Salesforce record which holds information about the given artifact version.
     */
    public void setVersion(Artifact_Version__c version) {
        this.version = version;
    }

    /**
     * @description a getter for the version private variable.
     *
     * @return the Salesforce record representing the given artifact version.
     */
    public Artifact_Version__c getVersion() {
        return this.version;
    }
}