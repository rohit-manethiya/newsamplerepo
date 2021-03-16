/**
 * @description this service class provides all the available operations on a Dev Hub Org that can be executed by
 * backend jobs.
 */
public with sharing class DevHubService extends AbstractDXOrg {
    private AbstractArtifact packageArtifact;

    /**
     * @description a setter for the packageArtifact private variable.
     *
     * @param packageArtifact is the selected source artifact from which metadata will be pulled into a newly created
     * Scratch Org.
     */
    public void setArtifact(AbstractArtifact packageArtifact) {
        this.packageArtifact = packageArtifact;
    }

    /**
     * @description this method will create a brand new Scratch Org that will get automatically added to an existing
     * pipeline selected by the user. Optionally, a user can load metadata from a selected source right after the
     * org is created.
     *
     * @param durationDays is the Scratch Org's lifespan, measured in days.
     * @param flowId is the Pipeline id of the selected Copado pipeline.
     * @param targetEnv is the destination environment to which the new Scratch Org will point in the pipeline.
     * @param permSets are any (optional) permissions sets that can be loaded into the new Scratch Org after creation.
     * @param userStoryId is the User Story id (if any) from which preselected metadata can be loaded into the new
     * Scratch Org once created.
     */
    public void createFullScratchOrg(Integer durationDays, Id flowId, Id targetEnv, String permSets, Id userStoryId) {
        validateOrgId();
        String metadataSourceParameters = '';
        if (packageArtifact != null) {
            List<Id> artifactIds = packageArtifact.getMetadataSource().getArtifactIds();
            if (!artifactIds.isEmpty()) {
                metadataSourceParameters = '&artifactIds=' + encode(String.join(artifactIds, ','));
            } else {
                if (packageArtifact instanceof BranchArtifact) {
                    metadataSourceParameters += '&branch=' + encode(((BranchArtifact) packageArtifact).getBranchName());
                } else if (packageArtifact instanceof PatchArtifact) {
                    metadataSourceParameters += '&branch=' + encode(((PatchArtifact) packageArtifact).getBranchName());
                }
            }
            String dxRepositoryId = packageArtifact.getDxRepositoryId();
            if (String.isNotBlank(dxRepositoryId)) {
                metadataSourceParameters += '&dxRepositoryId=' + dxRepositoryId;
            }
            if (packageArtifact instanceof BranchArtifact) { 
                metadataSourceParameters += '&convertSource=' + ((BranchArtifact) packageArtifact).getConvertSource();
            } else if (packageArtifact instanceof PatchArtifact) {
                metadataSourceParameters += '&convertSource=' + ((PatchArtifact) packageArtifact).getConvertSource();
            }
        }
        if (String.isNotBlank(flowId)) {
            metadataSourceParameters += '&flowId=' + flowId;
            if (String.isNotBlank(targetEnv)) {
                metadataSourceParameters += '&targetEnv=' + targetEnv;
            }
        }
        if (String.isNotBlank(userStoryId)) {
            metadataSourceParameters += '&userStoryId=' + userStoryId;
        }
        if (String.isNotBlank(permSets)) {
            metadataSourceParameters += '&permSets=' + encode(permSets);
        }
        String callURL =
            Settings.Server_URL +
            '/json/v1/dx/fullScratchOrg/?devHubOrgId=' +
            getOrgId() +
            '&sendEmail=true&durationDays=' +
            durationDays +
            '&orgName=' +
            encode(getScratchOrgName());
        if (String.isNotBlank(metadataSourceParameters)) {
            callURL += metadataSourceParameters;
        }

        Map<String, String> attachments = new Map<String, String>();
        if (String.isNotBlank(getOrgDefinitionJSON())) {
            attachments.put(DXLabel.DEFINITION_FILE, getOrgDefinitionJSON());
        } else {
            throw new OrgException('Scratch Org Definition is required');
        }
        if (packageArtifact != null) {
            attachments.putAll(packageArtifact.getDefaultAttachmentMap());
            if (packageArtifact instanceof AbstractPackage) {
                String packageDetailsJson = ((AbstractPackage) packageArtifact).generatePackageDetailsJson();
                if (String.isNotBlank(packageDetailsJson)) {
                    attachments.put(DXLabel.PACKAGE_DETAILS, packageDetailsJson);
                }
            }
        }
        sendDXRequest(callURL, JSON.serialize(attachments), DXLabel.HTTP_POST, true, DXLabel.CREATE_FULL_ORG);
    }

    /**
     * @description this method will create a brand new Scratch Org that will get automatically added to an existing
     * pipeline selected by the user. Optionally, a user can load metadata from a selected source right after the
     * org is created.
     *
     * @param branch is the source branch from where metadata is to be pulled and installed in the new Scratch Org once
     * created.
     * @param projectJson is the DX Project (sfdx-project.json) file holding information about the artifacts that need
     * to be installed once the Scratch Org is created.
     * @param mdSourcesJson is the Metadata Sources (metadataSources.json) file describing all the metadata selected for
     * installation.
     */
    public void createFullScratchOrg(String branch, String projectJson, String mdSourcesJson) {
        validateOrgId();
        String callURL =
            Settings.Server_URL + 
            '/json/v1/dx/fullScratchOrg/?devHubOrgId=' +
            getOrgId() +
            '&sendEmail=true&durationDays=1&orgName=' +
            encode(getScratchOrgName()) +
            '&convertSource=false';
        if (String.isNotBlank(branch)) {
            callURL += '&branch=' + encode(branch);
        }

        Map<String, String> attachments = new Map<String, String>();
        if (String.isNotBlank(getOrgDefinitionJSON())) {
            attachments.put(DXLabel.DEFINITION_FILE, getOrgDefinitionJSON());
        } else {
            throw new OrgException('Scratch Org Definition is required');
        }

        if (String.isNotBlank(projectJson)) {
            attachments.put(DXLabel.PROJECT_FILE, projectJson);
        }
        if (String.isNotBlank(mdSourcesJson)) {
            attachments.put(DXLabel.METADATA_SOURCES, mdSourcesJson);
        }
        sendDXRequest(callURL, JSON.serialize(attachments), DXLabel.HTTP_POST, true, DXLabel.CREATE_FULL_ORG);
    }

    /**
     * @description this method creates a brand new Scratch Org with the most basic setup and (optionally) adds it to
     * an existing Copado pipeline selected by the user.
     *
     * @param durationDays is the Scratch Org's lifespan, measured in days.
     * @param flowId is the Pipeline id of the selected Copado pipeline.
     * @param targetEnv is the destination environment to which the new Scratch Org will point in the pipeline.
     * @param userStoryId is the User Story id (if any) from which preselected metadata can be loaded into the new
     * Scratch Org once created.
     */
    public void createScratchOrg(Integer durationDays, Id flowId, Id targetEnv, Id userStoryId) {
        validateOrgId();
        durationDays = durationDays == null || durationDays == 0 ? 7 : durationDays;
        String callURL =
            Settings.Server_URL +
            '/json/v1/dx/scratchOrg?devHubOrgId=' +
            getOrgId() +
            '&orgName=' +
            encode(getScratchOrgName()) +
            '&durationDays=' +
            durationDays;
        if (String.isNotBlank(flowId)) {
            callURL += '&flowId=' + flowId;
            if (String.isNotBlank(targetEnv)) {
                callURL += '&targetEnv=' + targetEnv;
            }
        }
        if (String.isNotBlank(userStoryId)) {
            callURL += '&userStoryId=' + userStoryId;
        }
        Map<String, String> attachments = new Map<String, String>();
        attachments.put(DXLabel.DEFINITION_FILE, getOrgDefinitionJSON());

        sendDXRequest(callURL, JSON.serialize(attachments), DXLabel.HTTP_POST, true, DXLabel.CREATE_ORG);
    }
}