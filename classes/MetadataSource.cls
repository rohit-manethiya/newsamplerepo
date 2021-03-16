/**
 * @description this class serves as a DTO for the generation of a Metadata Sources (metadataSources.json) file
 * when generating new packages or installing existing packages in a scratch org.
 */
public with sharing class MetadataSource {
    private String metadataSource;
    private String metadataSourceType;
    private List<Id> artifactIds; // TODO: TO BE TRANSFORMED INTO AN OBJECT WITH ID-TYPE KEY-VALUE PAIRS
    private Id repositoryId;
    private Boolean isPatch;

    public MetadataSource(String source, String sourceType, Id repositoryId) {
        this.metadataSource = source;
        this.metadataSourceType = sourceType;
        this.artifactIds = new List<String>();
        this.repositoryId = repositoryId;
        this.isPatch = false;
    }

    /**
     * @description a setter for the artifactIds private variable.
     *
     * @param artifactIds is a list of artifacts to be installed in the target scratch org.
     */
    public void setArtifactIds(List<Id> artifactIds) {
        this.artifactIds = artifactIds;
    }

    /**
     * @description adds an artifact id to the list of artifacts included in the package installation on the target
     * scratch org.
     *
     * @param artifactId is the new artifact to be added to the list.
     */
    public void addArtifactId(Id artifactId) {
        if(this.artifactIds == null) {
            this.artifactIds = new List<Id>();
        }
        this.artifactIds.add(artifactId);
    }

    /**
     * @description a setter for the metadataSource private variable.
     *
     * @param metadataSource is the name of the source branch from where metadata is to be pulled.
     */
    public void setSource(String metadataSource) {
        this.metadataSource = metadataSource;
    }

    /**
     * @description a getter for the metadataSource private variable.
     *
     * @return the name of the source branch from where metadata is to be pulled for installation.
     */
    public String getSource() {
        return this.metadataSource;
    }

    /**
     * @description a getter for the list of artifact ids to be installed in the target scratch org.
     *
     * @return the list of selected artifact ids.
     */
    public List<Id> getArtifactIds() {
        return this.artifactIds;
    }

    /**
     * @description a setter for the isPatch private variable.
     *
     * @param isPatch determines whether a source branch is a patch of an existing release in git.
     */
    public void setIsPatch(Boolean isPatch) {
        this.isPatch = isPatch;
    }

    /**
     * @description a getter for the isPatch flag.
     *
     * @return a boolean value indicating whether the current source is a patch of an existing release in git.
     */
    public Boolean getIsPatch() {
        return this.isPatch;
    }
}