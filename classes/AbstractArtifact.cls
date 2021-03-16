public with sharing abstract class AbstractArtifact implements IDXProjectBehavior {
    private String artifactName;
    private Id artifactId;
    private Id dxRepositoryId;
    private Id devHubOrgId;
    private Id scratchOrgId;
    private DXProject artifactProject;
    protected MetadataSource artifactSource;

    public abstract void loadMetadata();
    public abstract void setMetadataSource(String sourceSelections);
    public abstract MetadataSource getMetadataSource(); 
    abstract void throwArtifactException();
    abstract List<ProjectArtifact> getArtifactDirectories();

    public void setArtifactName(String artifactName) {
        this.artifactName = artifactName;
    }

    public String getArtifactName() {
        return this.artifactName;
    }

    public void setArtifactId(Id artifactId) {
        this.artifactId = artifactId;
    }

    public Id getArtifactId() {
        return this.artifactId;
    }

    public void setDxRepositoryId(Id dxRepositoryId) {
        this.dxRepositoryId = dxRepositoryId;
    }

    public Id getDxRepositoryId() {
        return this.dxRepositoryId;
    }

    public void setScratchOrgId(Id scratchOrgId) {
        this.scratchOrgId = scratchOrgId;
    }

    public Id getScratchOrgId() {
        return this.scratchOrgId;
    }

    public void setDevHubOrgId(Id devHubOrgId) {
        this.devHubOrgId = devHubOrgId;
    }

    public Id getDevHubOrgId() {
        return this.devHubOrgId;
    }

    public void setDXProject(DXProject project) {
        this.artifactProject = project;
    }

    public DXProject getDXProject() {
        return this.artifactProject;
    }

    public String takeSnapshot() {
        if(String.isEmpty(this.artifactId)) {
            throw new ArtifactException(Label.ArtifactId_Required);
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/artifactSnapshot/' + encode(this.artifactId);
        HttpResponse res = SfdxAPIHelper.callDxJob(DXLabel.HTTP_POST, callURL, null, false);
        return res.getBody();
    }

    public virtual String generateMetadataSourcesJson() {
        if(getMetadataSource() == null) {
            throwArtifactException();
        }
        return getFormattedMetadataSourcesJson();
    }

    protected String getFormattedMetadataSourcesJson() {
        MetadataSource metadataSource = getMetadataSource();
        return JSON.serializePretty(metadataSource, true);
    }

    public virtual String generateProjectJson() {
        if(getMetadataSource() == null) {
            throwArtifactException();
        }

        DXProject project = getDXProject();
        project.clearAliasesIfEmpty();
        if(project.getPackageDirectories().isEmpty()) {
            project.setPackageDirectories(getArtifactDirectories());
        }
        for(ProjectArtifact thisArtifact : project.getPackageDirectories()) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        return getFormattedProjectJson(project);
    }

    protected String getFormattedProjectJson(DXProject project) {
        String projectJson = JSON.serialize(project,true);
        projectJson = projectJson.replaceAll('"packageName":', '"package":'); 
        projectJson = projectJson.replaceAll('"defaultArtifact":', '"default":');
        return projectJson;
    }

    public Map<String, String> getDefaultAttachmentMap() {
        Map<String, String> attachmentMap = new Map<String, String>();
        String projectJson = generateProjectJson();
        String metadataSourcesJson = generateMetadataSourcesJson();
        if(String.isNotBlank(projectJson)) {
            attachmentMap.put(DXLabel.PROJECT_FILE, projectJson);
        }
        if(String.isNotBlank(metadataSourcesJson)) {
            attachmentMap.put(DXLabel.METADATA_SOURCES, metadataSourcesJson);
        }
        return attachmentMap;
    }

    protected Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        return hasAccess;
    }

    protected String encode(String urlParameter) {
        if(String.isNotBlank(urlParameter)) {
            urlParameter = EncodingUtil.urlEncode(urlParameter, DXLabel.UTF_8);
        }
        return urlParameter; 
    }

    protected String sendDXRequest(String url, String requestType, String messageBody, String notificationType, Boolean bodyRequired) {
        HttpResponse response = SfdxAPIHelper.callDxJob(requestType, url, messageBody, bodyRequired);
        String responseBody = response.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse frontAPIResponse = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(responseBody, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(frontAPIResponse.copadoJobId)) {
            JobsManager.createRunningJob(frontAPIResponse.copadoJobId, notificationType, null, Label.Starting);
        }
        return responseBody;
    }

    public class ArtifactException extends Exception {}
}