public with sharing class Settings {

    public static final String DEFAULT_COPADO_SITE = 'https://copado.secure.force.com';
    public static final String DEFAULT_SERVER_URL = 'https://app-api.copado.com';
    public static final String DEFAULT_NAMESPACE = 'copado__';
    public static final String NONE = 'none';
    public static final String ORGANIZATION_URL = URL.getSalesforceBaseUrl().toExternalForm();
    public static final String USER_ID = UserInfo.getUserId();
    public static final String ORGANIZATION_ID = UserInfo.getOrganizationId();

    /**
     * copado force site for oauth callback
     */
    public static String copado_site;
    /**
     * Heroku server URL
     */
    public static String server_url ;
    /**
     * Copado App Namespace
     */
    public static String ns;

    /**
     * This attribute contains the session Id and the url parameter for heroku api calls
     */
    public static String generic_heroku_params;

    public static Boolean scalable_grid_enabled { get; set; }


    /**
     * Perform all statics initializations here
     */
    static {

        // get custom setting only once.
        Settings__c s = Settings__c.getOrgDefaults();

        // set custom setting or default values
        copado_site = String.isNotBlank(s.Copado_Site__c) ? s.Copado_Site__c : Settings.DEFAULT_COPADO_SITE;
        server_url = String.isNotBlank(s.Server_URL__c) ? s.Server_URL__c : Settings.DEFAULT_SERVER_URL;

        //set default namespace unless it is forced to NONE
        String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1 ? 'copado__' : '';
        ns = namespace;
        //String.isNotBlank(s.Namespace__c) ? (s.Namespace__c != Settings.NONE ? s.Namespace__c : '' ) : Settings.DEFAULT_NAMESPACE;
        scalable_grid_enabled = false;
        try {
            scalable_grid_enabled = [SELECT Id, DeveloperName, MasterLabel, Enabled__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Big_Metadata' LIMIT 1].Enabled__c;
        } catch(Exception e) {
            System.debug(e.getMessage());
        }

        //set the generic parameters to be used in all pages that calls heroku
        //when running on post install script user query will return no records
        String salesforceURL = 'https://login.salesforce.com/services/Soap/u/29.0/00Dxxxxxxxxx';
        List<User> thisUser = new List<User>();
        if(Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
            thisUser = [SELECT API_URL__c FROM User WHERE Id = :UserInfo.getUserId()];
        }
        if(thisUser.size() == 1) {
            salesforceURL = thisUser.get(0).API_URL__c;
        }
        generic_heroku_params = '?nosid=1';
    }

    public String herokuServer { get; set; }
    public String urlParameters { get; set; }
    public String urlBase { get; set; }
    public String namespace { get; set; }
    public Boolean scalableGrid { get; set; }
    public Personal_Settings__c mySettings { get; set; }
    /**
     * This is set only in User Story VF
     */
    public SObject userStoryObj { get; set; }

    /**
     * Helper to serialize the US
     * @return [json]
     */
    public String getUserStoryAsJSON() {
        return JSON.serialize(this.userStoryObj);
    }
    public static String getCurrentUserLicenses() {
        return JSON.serialize(getCurrentUserLicensesObject());
    }
    public static LicenseWrapper getCurrentUserLicensesObject() {
        return new licenseWrapper(LicenseHelper.isCopadoEnabled(), LicenseHelper.isCCMEnabled(), LicenseHelper.isCSTEnabled(), LicenseHelper.isCADEnabled(), LicenseHelper.isCCHEnabled(), LicenseHelper.isMultiLicense());
    }

    public static void getOrgMetdataTypes() {
        Map<String, String> getOrgMetaTypesMap = new Map<String, String>();
        if(ApexPages.currentPage() != null) {
            getOrgMetaTypesMap.putAll(ApexPages.currentPage().getParameters());
        }
        String orgId = getOrgMetaTypesMap.get('orgId');
        if(!String.isBlank(orgId)) {
            Org__c org = Utilities.getOrgById(orgId);
            if(String.isNotBlank(org.Metadata_Types__c)) {
                Settings.generic_heroku_params += '&filter=' + EncodingUtil.urlEncode(org.Metadata_Types__c, 'UTF-8');
            }
        }
    }

    public class LicenseWrapper {
        public Boolean hasCopado { get; set; }
        public Boolean hasCCM { get; set; }
        public Boolean hasCST { get; set; }
        public Boolean hasCAD { get; set; }
        public Boolean hasCCH { get; set; }
        public Boolean hasMultiLicense { get; set; }
        public licenseWrapper(Boolean hasCopado, Boolean hasCCM, Boolean hasCST, Boolean hasCAD, Boolean hasCCH, Boolean hasMultiLicense) {
            this.hasCopado = hasCopado;
            this.hasCCM = hasCCM;
            this.hasCST = hasCST;
            this.hasCAD = hasCAD;
            this.hasCCH = hasCCH;
            this.hasMultiLicense = hasMultiLicense;
        }
    }

    private void constructor() {
        //TODO: move this to external util method in order to use it in other classes
        Settings.getOrgMetdataTypes();
        urlParameters = Settings.generic_heroku_params;
        herokuServer = Settings.server_url;
        urlBase = server_url + '/json/v1/';
        scalableGrid = Settings.scalable_grid_enabled;
        namespace = Settings.ns;
        mySettings = Personal_Settings__c.getInstance();
        if(mySettings == null) {
            mySettings = new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId());
        }
        mySettings.API_Key__c = DeployAPI.decryptAPIKey(mySettings.API_Key__c);
    }

    public Settings(ApexPages.StandardController ext) {
        constructor();
    }

    public Settings(GitCommitLookupController controller) {
        constructor();
    }

    public Settings(GitCommitChangesController controller) {
        constructor();
    }

    public Settings(webhookLookupController controller) {
        constructor();
    }

    public Settings(ScratchOrgStatusCtrl controller) {
        constructor();
    }

    public Settings(ScratchOrgMetadataController contoller) {
        constructor();
    }

    public Settings(ArtifactManageMetadataController contoller) {
        constructor();
    }

    public Settings(ScratchOrgDisplayController contoller) {
        constructor();
    }

    public Settings(ManageGitBranchesController contoller) {
        constructor();
    }

    public Settings(DXOperationController contoller) {
        constructor();
    }

    public Settings(ManageRepositoryBranchesController controller) {
        constructor();
    }

    public Settings(GitCommit_OperationsController controller) {
        constructor();
    }

    public Settings(GitCommit_GridController controller) {
        constructor();
    }

    public Settings(WorkSubmitService controller) {
        constructor();
    }

    public Settings() {
        constructor();
    }
}