/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class PatchMetadataService {
    public PatchMetadataService(){}
//public with sharing class PatchMetadataService implements MetadataTypeService {
    /**
     * It is used to load metadata from patch
     * * BranchMetadataService.loadMetadata method is used. Because both are using same methods.
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    /*public void loadMetadata(String jsonValue){
        System.debug('**f**PatchMetadataService : ');
        BranchMetadataService bms = new BranchMetadataService();
        bms.loadMetadata(jsonValue);
    }*/

    /**
     * It is used to define page variables based on selected metadata type
     */
    /*public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        //dxJsonArtifact.showPatchOptions = true;
        return dxJsonArtifact;
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
            throw new PatchServiceException('There is missing value in the call. Please check your data and try again!');
        }
        
        if(String.isNotBlank(pjw.dxBranchName) && String.isBlank(pjw.sourceSelections)){
            pjw.sourceSelections = pjw.dxBranchName;
        }

        if (String.isBlank(pjw.sourceSelections)) {
            throw new PatchServiceException(Label.Select_Patch_To_Load);
        }

        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        rsw.project = pjw.project;
        ProjectArtifact directory;
        directory = new ProjectArtifact(pjw.sourceSelections != null ? pjw.sourceSelections : SfdxAPIHelper.DX_DEFAULT_PATH, true);
        rsw.project.packageDirectories = new List<ProjectArtifact>{
                directory
        };

        rsw.mdSourcesJson = new MetadataSource(pjw.sourceSelections, 'tag', pjw.repoId);
        rsw.mdSourcesJson.isPatch = true;
        return rsw;
    }*/

    /*public class PatchServiceException extends Exception {
    }*/
}