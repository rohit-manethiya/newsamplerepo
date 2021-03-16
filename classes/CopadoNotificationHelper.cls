/**
 * Created by gaviriajesus on 22/01/2018.
 * This class is a helper for Copado Notification Object which
 * will be normally used by creating a record of Copado Notification With a predefined Type
 */

public with sharing class CopadoNotificationHelper {

    public static final String PROGRESS_STATUS_COPADO = 'PROGRESS_STATUS_COPADO';
    public static final String NEW_COPADO_NOTIFICATION = 'Copado Notification Created';
    public static final String STATUS_DEFAULT_VALUE = 'Loading...';

    //DX
    public static final String DX_OPEN_ORG = 'DxOpenScratchOrgJob';
    public static final String DX_CREATE_ORG = 'DxCreateScratchOrgJob';
    public static final String DX_CREATE_APP = 'DxCreateConnectedAppJob';
    public static final String DX_LIST_REPO_BRANCHES = 'DxListRepositoryBranches';
    public static final String DX_ARTIFACT_GIT_SNAPSHOT = 'DxArtifactGitSnapshot';
    public static final String DX_SOURCE_STATUS = 'DxSourceStatusJob';
    public static final String DX_CREATE_FULL_ORG = 'DxCreateFullScratchOrgJob';
    public static final String DX_LOAD_METADATA = 'DxLoadMeatadataJob';
    public static final String DX_DELETE_ORG = 'DxDeleteScratchOrg';
    public static final String DX_ORG_DETAILS = 'DxOrgDetails';
    public static final String DX_ORG_IDE_DETAILS = 'DXOrgIdeDetails';
    public static final String DX_LIST_OF_PACKAGES = 'DxListOrgPackagesJob';
    public static final String DX_CREATE_PROJECT_BRANCH = 'DxCreateProjectBranch';
    public static final String DX_ARTIFACT_MERGE_RELEASE = 'DxArtifactMergeReleaseJob';
    public static final String DELETE_GIT_BRANCHES = 'GitDeleteBranches';
    public static final String METADATA_DEPENDENCIES = 'MetadataDependenciesJob';

    public static final String DX_CREATE_PACKAGE = 'DXCreatePackage';
    public static final String DX_CREATE_PACKAGE_VERSION = 'DXCreatePackageVersion';
    public static final String DX_PACKAGE_UPDATE = 'DXPackageUpdate';
    public static final String DX_PACKAGE_VERSION_UPDATE = 'DXPackageVersionUpdate';
    public static final String DX_PROMOTE_BETA_RELEASED = 'DXPromoteBetaReleased';
    public static final String DX_INSTALLED_PACKAGES = 'DXInstallPackages';


    public static Copado_Notification__c instCopadoNotification(String name, String parentId , String jobType, String copadoJobId){
        Copado_Notification__c cn = new Copado_Notification__c();
        cn.Name = name;
        cn.ParentId__c = parentId;
        cn.Type__c = jobType;
        cn.Matching_Key__c = copadoJobId;
        cn.status__c = NEW_COPADO_NOTIFICATION;
        return cn;
    }

    public static Copado_Notification__c qCopadoNotificationBycopadoJobId(String copadoJobId){
        List<Copado_Notification__c> cnList = [SELECT Id, isFinished__c, Matching_Key__c, Message__c, ParentId__c, status__c, isSuccess__c, Type__c
                                               FROM Copado_Notification__c
                                               WHERE Matching_Key__c =: copadoJobId
                                               LIMIT 1];
        if(cnList.size()>0){
            return cnList[0];
        }else{
            return null;
        }
    }
    //Given a copado notification type get the last not finished job
    public static Copado_Notification__c qInProgressCopadoNotification(String jobType, String parentId){
        List<Copado_Notification__c> cnList = [SELECT Id, isFinished__c, Matching_Key__c, Message__c, ParentId__c, status__c, isSuccess__c, Type__c
                                                FROM Copado_Notification__c
                                                WHERE Type__c =: jobType
                                                AND OwnerId =: UserInfo.getUserId()
                                                AND isFinished__c = false
                                                AND ParentId__c =: parentId
                                                ORDER BY CreatedDate DESC
                                                LIMIT 1];
        if(cnList.size()>0){
            return cnList[0];
        }else{
            return null;
        }
    }

    public class copadoFrontAPIreponse{
        public String copadoJobId;
        public String ok;
        public String status;
        public String error;
    }


}