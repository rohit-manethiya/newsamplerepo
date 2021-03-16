/**
 * @description this is a utility class for static DX command names and keywords that are used across the entire
 * Copado DX package.
 */
public with sharing class DXLabel {
    public static final String DX_URL_PATH = Settings.Server_URL + '/json/v1/dx/';
    public static final String PROJECT_BRANCH = 'project/DX-'; //+scratchOrgId (15 chars)
    public static final String DEFINITION_FILE = 'project-scratch-def.json';
    public static final String PROJECT_FILE = 'sfdx-project.json';
    public static final String DEFAULT_PATH = 'force-app';
    public static final String METADATA_SOURCES = 'metadataSources.json';
    public static final String PACKAGE_DETAILS = 'packageDetail.json';
    public static final String CONVERT_IGNORE = 'convertForceIgnore';
    public static final String PUSH_IGNORE = 'pushForceIgnore';
    public static final String OPEN_ORG = 'DxOpenScratchOrgJob';
    public static final String CREATE_ORG = 'DxCreateScratchOrgJob';
    public static final String LIST_REPO_BRANCHES = 'DxListRepositoryBranches';
    public static final String ARTIFACT_GIT_SNAPSHOT = 'DxArtifactGitSnapshot';
    public static final String SOURCE_STATUS = 'DxSourceStatusJob';
    public static final String CREATE_FULL_ORG = 'DxCreateFullScratchOrgJob';
    public static final String LOAD_METADATA = 'DxLoadMetadataJob';
    public static final String DELETE_ORG = 'DxDeleteScratchOrg';
    public static final String ORG_DETAILS = 'DxOrgDetails';
    public static final String ORG_IDE_DETAILS = 'DXOrgIdeDetails';
    public static final String LIST_OF_PACKAGES = 'DxListOrgPackagesJob';
    public static final String CREATE_PROJECT_BRANCH = 'DxCreateProjectBranch';
    public static final String ARTIFACT_MERGE_RELEASE = 'DxArtifactMergeReleaseJob';
    public static final String DELETE_GIT_BRANCHES = 'GitDeleteBranches';
    public static final String METADATA_DEPENDENCIES = 'MetadataDependenciesJob';
    public static final String CREATE_PACKAGE = 'DXCreatePackage';
    public static final String CREATE_PACKAGE_VERSION = 'DXCreatePackageVersion';
    public static final String PACKAGE_UPDATE = 'DXPackageUpdate';
    public static final String PACKAGE_VERSION_UPDATE = 'DXPackageVersionUpdate';
    public static final String PROMOTE_BETA_RELEASED = 'DXPromoteBetaReleased';
    public static final String INSTALLED_PACKAGES = 'DXInstallPackages';
    public static final String ARTIFACT = 'artifact';
    public static final String BRANCH = 'branch';
    public static final String PATCH = 'patch';
    public static final String REPOSITORY_TAG = 'tag';
    public static final String UNLOCKPACKAGE = 'unlocked';
    public static final String SECONDGENERATIONPACKAGE = 'managed';
    public static final String UTF_8 = 'UTF-8';
    public static final String HTTP_GET = 'GET';
    public static final String HTTP_POST = 'POST';
    public static final String HTTP_DELETE = 'DELETE';
    public static final String DEFAULT_SFDC_LOGIN_URL = 'https://login.salesforce.com';
    public static final String DEFAULT_API_VERSION = '45.0';
    public static final String SCRATCH_ORG_URL_PATH = DX_URL_PATH + 'scratchOrg/';
    public static final String PACKAGES_LIST = 'packagesList/';
    public static final String DEFAULT_EDITION = 'Developer';
    public static final String DEFAULT_LANGUAGE = 'en_US';
    public static final String DEFAULT_COUNTRY = 'US';
    public static final String METADATA_API = 'Metadata API';
    public static final String DX_FORMAT = 'DX Format';
}