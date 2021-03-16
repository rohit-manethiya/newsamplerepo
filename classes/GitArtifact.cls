/**
 * @description this class provides all the available operations for installing an artifact that is created out of a
 * git repository into a Scratch Org.
 * @see AbstractArtifact
 */
public with sharing class GitArtifact extends AbstractArtifact {
    /**
     * @description a setter for the artifactSource private variable.
     *
     * @param sourceSelections is a string containing comma-separated ids of artifacts or the name of a DX branch
     * from where the source is to be pulled for installation.
     */
    public override void setMetadataSource(String sourceSelections) {
        List<Id> artifactIds = sourceSelections.split(',');
        artifactSource = new MetadataSource(sourceSelections, DXLabel.ARTIFACT, null);
        artifactSource.setArtifactIds(artifactIds);
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
        if(String.isBlank(getScratchOrgId())) {
            throw new ArtifactException(Label.Load_MD_OrgId_Required);
        }
        if(getMetadataSource() == null) {
            throw new ArtifactException(Label.Artifact_Selection_Validation);
        }
        sendLoadMetadataCallout();
    }

    /**
     * @description this method sends a callout to the backend that will execute the load metadata command against a
     * selected Scratch Org and install that metadata in it.
     */
    private void sendLoadMetadataCallout() {
        String callURL = Settings.server_url + '/json/v1/dx/scratchOrg/' + encode(getScratchOrgId()) + '/metadata?sendEmail=true';
        if(String.isNotBlank(getDxRepositoryId())) {
            callURL += '&dxRepositoryId=' + encode(getDxRepositoryId());
        }
        Map<String, String> attachmentMap = getDefaultAttachmentMap();
        sendDXRequest(callUrl, DXLabel.HTTP_POST, JSON.serialize(attachmentMap), DXLabel.LOAD_METADATA, false);
    }

    private void throwArtifactException() {
        throw new ArtifactException(Label.Artifact_Selection_Validation);
    }

    /**
     * @description this method will list all the artifact (metadata source) directories belonging to the current
     * DX Project, including artifact dependencies.
     *
     * @return a list of directories to be included in the package installation when loading metadata into a
     * Scratch Org.
     */
    private List<ProjectArtifact> getArtifactDirectories() {
        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        artifactDirectories.add(new ProjectArtifact(DXLabel.DEFAULT_PATH, true));
        List<String> artifactIds = getMetadataSource().getArtifactIds();
        try {
            for(Artifact__c artifacts : [SELECT Name FROM Artifact__c WHERE Id IN :artifactIds WITH SECURITY_ENFORCED]) {
                artifactDirectories.add(new ProjectArtifact(artifacts.Name, false));
            }
        } catch(QueryException queryEx) {
            throw new ArtifactException(queryEx.getMessage());
        }
        for(ProjectArtifact thisArtifact : artifactDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        return artifactDirectories;
    }
}