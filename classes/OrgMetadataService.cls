/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class OrgMetadataService {
    public OrgMetadataService(){}
//public with sharing class OrgMetadataService implements MetadataTypeService {
    /**
     * It is used to load metadata from org
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    /*public void loadMetadata(String jsonValue){
        System.debug('**f**OrgMetadataService : ');
        DXMetadataJsonWrapper.LoadMetadataWrapper jsw = new DXMetadataJsonWrapper.LoadMetadataWrapper();

        if (String.isNotBlank(jsonValue)) {
            jsw = (DXMetadataJsonWrapper.LoadMetadataWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.LoadMetadataWrapper.class);
        } else {
            throw new OrgMetadataServiceException('There is missing value in the call. Please check your data and try again!');
        }

        if(String.isEmpty(jsw.scratchOrgId)) {
            throw new OrgMetadataServiceException(Label.Load_MD_OrgId_Required);
        }

        Map<String, String> attachmentMap = new Map<String, String>();
        if(String.isNotBlank(jsw.projectJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_PROJECT_FILE, SfdxAPIHelper.orgDefinitionDefaultKeyFixer(jsw.projectJSON));
        }
        if(String.isNotBlank(jsw.mdSourcesJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_METADATA_SOURCES, jsw.mdSourcesJSON);
        }
        if(String.isNotBlank(SfdxAPI.convertIgnore)) {
            attachmentMap.put(SfdxAPIHelper.DX_CONVERT_IGNORE, SfdxAPI.convertIgnore);
        }
        if(String.isNotBlank(SfdxAPI.pushIgnore)) {
            attachmentMap.put(SfdxAPIHelper.DX_PUSH_IGNORE, SfdxAPI.pushIgnore);
        }

        String callURL = Settings.server_url + '/json/v1/dx/scratchOrg/' + EncodingUtil.urlEncode(jsw.scratchOrgId, 'UTF-8') + '/metadata?orgId=' + EncodingUtil.urlEncode(jsw.orgId, 'UTF-8');
        if(String.isNotBlank(jsw.dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + EncodingUtil.urlEncode(jsw.dxRepositoryId, 'UTF-8');
        }

        SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachmentMap), false, CopadoNotificationHelper.DX_LOAD_METADATA);
    }*/

    /**
     * It is used to define page variables based on selected metadata type
     */
    /*public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        dxJsonArtifact.showOrgs = true;
        return dxJsonArtifact;
        return null;
    }*/

    /**
     * It is used to generate project json by using the sourceselection
     * @param jsonValue
     * @return
     */
    /*public DXMetadataJsonWrapper.ResponseProjectJSONWrapper generateSfdxProjectJson(String jsonValue) {
        DXMetadataJsonWrapper.ProjectJSONWrapper pjw = new DXMetadataJsonWrapper.ProjectJSONWrapper();

        if (String.isNotBlank(jsonValue)) {
            pjw = (DXMetadataJsonWrapper.ProjectJSONWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.ProjectJSONWrapper.class);
        } else {
            throw new OrgMetadataServiceException('There is missing value in the call. Please check your data and try again!');
        }

        if (String.isBlank(pjw.sourceSelections) || pjw.sourceSelections == '-- None --') {
            throw new OrgMetadataServiceException(Label.Select_Org_Credential_To_Load);
        }

        if(String.isNotBlank(pjw.dxBranchName) && String.isBlank(pjw.sourceSelections)){
            pjw.sourceSelections = pjw.dxBranchName;
        }
        List<ProjectArtifact> artifacts = new List<ProjectArtifact>();
        if(pjw.sourceSelections != null) {
            ProjectArtifact directory = new ProjectArtifact(pjw.sourceSelections ,true );
            artifacts.add(directory);
        }
        for(ProjectArtifact thisArtifact : artifacts) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        rsw.project.packageDirectories = artifacts;
        rsw.project = pjw.project;
        rsw.project.checkIfAliasesAreEmptyAndClearMap();
        rsw.mdSourcesJson = new MetadataSource(pjw.sourceSelections, 'org', pjw.repoId);
        return rsw;
    }*/

    /*public class OrgMetadataServiceException extends Exception {
    }*/
}