global with sharing class JsRemotingController {
    /*
    The purpose of this class is to encapsulate various methods of Apex controller
    and make these available via Javascript Remoting.
    */
    @RemoteAction
    global static String createAPIKey() {
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        if(String.isBlank(mySettings.API_Key__c)) {
            DeployAPI.createAPIKey();
        }
        return DeployAPI.getUserAPIKey();
    }
    /**
     * Gets the list of
     * @return [description]
     */
    @RemoteAction
    global static List<String> getMetadataTypes(String orgId) {
        try {
            System.debug('getMetadataTypes===> '+orgId);
            return MetadataTypesHelper.getMetadataTypesByOrgId(orgId);
        } catch(Exception e) {
            return null;
        }

    }

    @RemoteAction
    global static void getVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        System.debug('userStoryId===> ' + userStoryId);
        System.debug('jsonSelectedMetadata===> ' + jsonSelectedMetadata);
        DeployAPI.retrieveVlocityDependencies(userStoryId, jsonSelectedMetadata);
    }

    @RemoteAction
    global static Boolean selectBranch(Id sObjectId, String fieldName, String branchName) {
        try {
            SObjectType stype = sObjectId.getSobjectType();
            SObject obj = stype.newSObject(sObjectId);
            obj.put(fieldName, branchName);
            Utilities.Secure_DML(obj, Utilities.DML_Action.UPD, stype.getDescribe());
            return true;
        } catch(Exception e) {
            return false;
        }
    }

    /**
     * constructor methods.
     */

    public JsRemotingController() {
    }
    public JsRemotingController(ApexPages.StandardController sc) {
    }
    public JsRemotingController(GitCommitChangesController sc) {
    }
    public JsRemotingController(GitCommit_GridController sc) {
    }
}