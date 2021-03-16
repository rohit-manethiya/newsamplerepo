/**
 * @description this class provides all the available operations for installing an artifact that is created out of a
 * release patch into a Scratch Org.
 * @see AbstractArtifact
 */
public with sharing class PatchArtifact extends AbstractArtifact {
    private Id repositoryId;
    private String branchName;
    private Boolean convertSource;

    /**
     * @description a setter for the repositoryId private variable.
     *
     * @param repositoryId is the target repository id from where the artifact metadata will be retrieved.
     */
    public void setRepositoryId(Id repositoryId) {
        this.repositoryId = repositoryId;
    }

    /**
     * @description a getter for the repositoryId private variable.
     *
     * @return the target repository id from where metadata will be loaded into a selected Scratch Org.
     */
    public Id getRepositoryId() {
        return this.repositoryId;
    }

    /**
     * @description a setter for the branchName private variable.
     *
     * @param branchName is the name of the source branch from where metadata is to be pulled.
     */
    public void setBranchName(String branchName) {
        this.branchName = branchName;
    }

    /**
     * @description a getter for the branchName private variable.
     *
     * @return the name of the source branch from where metadata is to be pulled for installation.
     */
    public String getBranchName() {
        return this.branchName;
    }

    /**
     * @description a setter for the convertSource private variable.
     *
     * @param convertSource is a flag indicating whether the source should be converted into DX format or left in
     * metadata format.
     */
    public void setConvertSource(String metadataFormat) {
        this.convertSource = metadataFormat == DXLabel.METADATA_API;
    }

    /**
     * @description a getter for the convertSource private variable.
     *
     * @return a flag indicating the metadata format in which files will be pulled from a repository.
     */
    public Boolean getConvertSource() {
        return this.convertSource;
    }

    /**
     * @description a setter for the artifactSource private variable.
     *
     * @param sourceSelections is a string containing comma-separated ids of artifacts or the name of a DX branch
     * from where the source is to be pulled for installation.
     */
    public override void setMetadataSource(String sourceSelections) {
        artifactSource = new MetadataSource(sourceSelections, DXLabel.REPOSITORY_TAG, this.repositoryId);
        artifactSource.setIsPatch(true);
    }

    /**
     * @description is a getter for the artifactSource private variable.
     *
     * @return a MetadataSource object with the source artifact and/or git repository information from where all sources
     * will be installed into a Scratch Org.
     */
    public override MetadataSource getMetadataSource() {
        return artifactSource;
    }

    /**
     * @description this method calls the backend job that pulls the metadata from the designated source and loads it
     * into a Scratch Org.
     */
    public override void loadMetadata() {
        if(String.isEmpty(getScratchOrgId())) {
            throw new ArtifactException(Label.Load_MD_OrgId_Required);
        }
        sendLoadMetadataCallout();
    }

    /**
     * @description this method sends a callout to the backend that will execute the load metadata command against a
     * selected Scratch Org and install that metadata in it.
     */
    private void sendLoadMetadataCallout() {
        String callURL = Settings.server_url + '/json/v1/dx/scratchOrg/' + encode(getScratchOrgId()) 
                + '/metadata?repositoryId=' + encode(this.repositoryId) 
                + '&sendEmail=true&convertSource=' + this.convertSource;
        if(String.isNotBlank(getDxRepositoryId())) {
            callURL += '&dxRepositoryId=' + encode(getDxRepositoryId());
            callURL += '&branch=' + encode(this.branchName);
        }
        Map<String, String> attachmentMap = getDefaultAttachmentMap();
        sendDXRequest(callUrl, DXLabel.HTTP_POST, JSON.serialize(attachmentMap), DXLabel.LOAD_METADATA, false);
    }

    /**
     * TODO: REFACTOR THIS METHOD
     */
    private void throwArtifactException() {
        throw new ArtifactException(Label.Select_a_Branch);
    }

    /**
     * @description this method will list all the artifact (metadata source) directories belonging to the current
     * DX Project, including artifact dependencies.
     *
     * @return a list of directories to be included in the package installation when loading metadata into a
     * Scratch Org.
     */
    private List<ProjectArtifact> getArtifactDirectories() {
        String sourceSelections = getMetadataSource().getSource();
        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        artifactDirectories.add(new ProjectArtifact(sourceSelections, true));
        for(ProjectArtifact thisArtifact : artifactDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        return artifactDirectories;
    }

    /**
     * @description this method will send a callout to the backend that will retrieve all the available branches from
     * a selected DX repository.
     */
    public String retrieveBranchesFromRepository() {
        if(String.isBlank(getDxRepositoryId())) {
            throw new ArtifactException(Label.RepoId_Required);
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/gitBranches/' + encode(getDxRepositoryId());
        String responseBody = sendDXRequest(callURL, DXLabel.HTTP_GET, null, DXLabel.LIST_REPO_BRANCHES, false);
        return responseBody;
    }
}