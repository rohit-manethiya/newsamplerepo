/**
 * Copado SFDX client api. In this class salesforce dx related callout and common operation methods are being handled.
 */
public with sharing class SfdxAPI extends SfdxAPIHelper {
    public static String convertIgnore { get; set; }
    public static String pushIgnore { get; set; }
    private static String STARTING = 'Starting...';
    public static void promoteBetaPackagetoReleased(String projectJson, Id packageId, Id devHubOrgCredentialId, Id artifactId, Id artifactVersionId) {
        if(String.isBlank(projectJson) && packageId == null && devHubOrgCredentialId == null && artifactVersionId == null) {
            throw new CopadoDxException('Required parameter or parameters are missing for promoting this beta version!!!'); //TODO : Custom Label
        }
        String callURL = Settings.server_url + '/json/v1/promoteToReleased?packageId=' + packageId + '&artifactId=' + artifactId + '&devHubOrgId=' + devHubOrgCredentialId + '&artifactVersionId=' + artifactVersionId;
        try {
            Map<String, String> attachments = new Map<String, String>();
            attachments.put(DXLabel.PROJECT_FILE, projectJSON);
            HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), true);
            String body = res.getBody();//success response example
            // Sample response String body = '{"status":0,"result":{"id":"04tf2000000oFUwAAM","success":true,"errors":[]}}';

            if(String.isNotBlank(body)) {
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.class);
                if(String.isNotBlank(r.copadoJobId)) {
                    JobsManager.createRunningJob(r.copadoJobId, CopadoNotificationHelper.DX_PROMOTE_BETA_RELEASED, null, STARTING);
                }
            }

            SfdxAPIHelper.PackageCreateResponse respObj = (SfdxAPIHelper.PackageCreateResponse) JSON.deserialize(body.replace('\n', '\\n'), SfdxAPIHelper.PackageCreateResponse.class);
            System.debug('respObj==> ' + respObj);
        } catch(Exception ex) {
            throw new CopadoDxException('An error has been occurred during artifact version promotion.' + ex.getMessage());
        }
    }

    public static String orgOpen(String orgId) {
        if(String.isEmpty(orgId)) {
            throw new CopadoDxException(Label.Org_Open_OrgId_Required);
        }
        String callURL = Settings.Server_URL + '/json/v1/org/' + EncodingUtil.urlEncode(orgId, 'UTF-8') + '/accessUrl';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_open body: ' + body);
        return body;
    }

    @Future(callout=true)
    public static void refreshStatus() {
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrgsStatus';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
    }

    public static String retrieveBranchesFromRepository(String repoId) {
        if(String.isEmpty(repoId)) {
            throw new CopadoDxException(Label.RepoId_Required);
        }
        repoId = repoId != null ? repoId : '';
        String callURL = Settings.Server_URL + '/json/v1/dx/gitBranches/' + EncodingUtil.urlEncode(repoId, 'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId, 'DxListRepositoryBranches', null, STARTING);
        }
        return body;
    }

    public static String artifactSnapshot(String artifactId) {
        if(String.isEmpty(artifactId)) {
            throw new CopadoDxException(Label.ArtifactId_Required);
        }
        //repoId = repoId != null ? repoId : '';
        String callURL = Settings.Server_URL + '/json/v1/dx/artifactSnapshot/' + EncodingUtil.urlEncode(artifactId, 'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
        return body;
    }

    public static void mergeReleases(String artifactId, String releaseId) {
        if(String.isEmpty(artifactId) || String.isEmpty(releaseId)) {
            throw new CopadoDxException('Artifact Id and Release Id are required to merge releases'); //TODO: custom label
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/artifact/' + artifactId + '/mergeRelease?releaseId=' + releaseId;
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId, CopadoNotificationHelper.DX_ARTIFACT_MERGE_RELEASE, null, STARTING);
        }
    }

    public static void createProjectBranch(String orgId, String dxRepoId) {
        if(String.isEmpty(orgId)) {
            throw new CopadoDxException('Scratch Org Id is required');//TODO: custom label
        } else if(String.isEmpty(dxRepoId)) {
            throw new CopadoDxException('Repository Id where Project branch will be created is required.');//TODO: custom label
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/' + orgId + '/projectBranch?dxRepositoryId=' + dxRepoId;
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(body, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId, CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH, null, STARTING);
        }
    }

    /**
     * Calls backend job to create necesary information to authorize the scratchorg
     */
    @Future(callout=true)
    public static void authorizeExternalScratchOrg(String orgCredentialId, String authUrl) {
        String callURL = Settings.Server_URL + '/dx/scratchorg/external/' + orgCredentialId + '/register';
        String body = JSON.serialize(new Map<String, String>{'sfdxAuthUrl' => authUrl});
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, body, false);
        String response = res.getBody();

        System.debug(loggingLevel.INFO, '*** externalScratchOrg body: ' + response);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(response, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId, 'registerExternalScratchOrg', orgCredentialId, STARTING);
        }
    }

    public class CopadoDxException extends Exception {}
}