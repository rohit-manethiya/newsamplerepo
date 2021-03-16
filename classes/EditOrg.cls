public with sharing class EditOrg {
    public Org__c org { get; set; }
    public String metadata_url { get; set; }

    public List<String> sel { get; set; }
    public List<SelectOption> selectedTypes { get; set; }
    public List<SelectOption> orgTypes {
        get {
            if (orgTypes == null) {
                orgTypes = new List<SelectOption>();
                List<PicklistEntry> picklistValues = Org__c.SObjectType.getDescribe()
                    .fields.getMap()
                    .get(namespace + 'Org_Type__c')
                    .getDescribe()
                    .getPicklistValues();
                for (PicklistEntry entry : picklistValues) {
                    String value = entry.getValue();
                    Boolean isDisabled = value == SCRATCH_ORG || value == SCRATCH_ORG_TEST_ONLY;
                    orgTypes.add(new SelectOption(value, entry.getLabel(), isDisabled));
                }
                orgTypes.add(new SelectOption(SCRATCH_ORG_PATCH, SCRATCH_ORG_PATCH, true));
                orgTypes.add(new SelectOption(CUSTOM_DOMAIN, CUSTOM_DOMAIN));
            }
            return orgTypes;
        }
        private set;
    }

    public Boolean hasTestResultAttachment { get; set; }
    public String resAttId { get; set; }
    public Boolean isShareable { get; set; }
    public Boolean scaAccess { get; set; }
    public Boolean complianceScanResultAccess { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public Boolean complianceScanRequestAccess { get; set; }
    public Boolean isScratchOrg { get; set; }
    public Id currentId;

    private String namespace = Settings.ns;
    private final String APEX_TEST = 'Apex Test';
    private final String COMPLIANCE_HUB = 'Compliance Hub';
    private final String STATIC_CODE_ANALYSIS = 'Static Code Analysis';
    private final String CUSTOM_DOMAIN = 'Custom Domain';
    private final String SCRATCH_ORG = 'Scratch Org';
    private final String SCRATCH_ORG_TEST_ONLY = 'Scratch Org - Test only';
    private final String SCRATCH_ORG_PATCH = 'Scratch Org - Patch';

    public EditOrg(ApexPages.StandardController std) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            std.addFields(new List<String>(Schema.SObjectType.Org__c.fields.getMap().keySet()));
            std.addFields(new List<String>{ namespace + 'Environment__r.Name', namespace + 'is_Developer_Hub_Org__c' });
        }
        showOptions = true;
        showError = false;
        scaAccess = FeatureAccessHelper.isSCAFeatureAccessible();
        complianceScanRequestAccess = LicenseHelper.actionIsLicenseEnabled('requestComplianceScan');
        complianceScanResultAccess = FeatureAccessHelper.isComplianceScanResultAccessible();
        hasTestResultAttachment = false;
        isLicenseEnabled();
        if (std.getId() != null) {
            org = Utilities.getOrgById(std.getId());
            currentId = org.Id;
        } else {
            org = new Org__c();
        }
        setUrls();

        isScratchOrg = String.isNotBlank(org.Org_Type__c) && org.Org_Type__c.startsWithIgnoreCase('Scratch Org');

        //****** selected types
        selectedTypes = new List<SelectOption>();
        sel = new List<String>();
        if (org.Metadata_Types__c != null) {
            for (String t : org.Metadata_Types__c.split(',')) {
                selectedTypes.add(new SelectOption(t, t));
                sel.add(t);
            }
        }
        sel.sort();

        //check apex test feature
        if (org.Test_Frequency__c != null && org.Test_Frequency__c != 'None' && !FeatureHelper.isFeatureEnabled(APEX_TEST)) {
            org.Test_Frequency__c.addError(Label.FEATURE_NOT_SUPPORTED + ': Apex Test');
        }

        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        isShareable = tokens.containsKey('Org__Share');

        getTestResultAttachment();
    }

    public void getTestResultAttachment() {
        List<Apex_Test_Result__c> res = new List<Apex_Test_Result__c>();
        if (Schema.SObjectType.Apex_Test_Result__c.isQueryable() && Schema.SObjectType.Apex_Test_Result__c.isAccessible()) {
            res = [SELECT Id FROM Apex_Test_Result__c WHERE Org__c = :org.Id ORDER BY CreatedDate DESC LIMIT 1];
        }

        if (!res.isEmpty() && Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
            List<Attachment> atts = [SELECT Id FROM Attachment WHERE Name = 'ApexTestResult' AND ParentId = :res.get(0).Id];
            if (!atts.isEmpty()) {
                this.hasTestResultAttachment = true;
                resAttId = atts.get(0).Id;
            }
        }
    }

    public List<String> getMetadataTypes() {
        return MetadataTypesHelper.getMetadataTypesByOrgId(org.Id);
    }

    public List<SelectOption> getTypes() {
        return MetadataTypesHelper.getTypeOptionsByOrgId(org.Id, sel);
    }

    public PageReference save() {
        //check apex test feature
        if (org.Test_Frequency__c != null && org.Test_Frequency__c != 'None' && !FeatureHelper.isFeatureEnabled(APEX_TEST)) {
            org.Test_Frequency__c.addError(Label.FEATURE_NOT_SUPPORTED + ': Apex Test');
            return null;
        }

        if (null != currentId && !Utilities.HasEditAccess(currentId)) {
            org.addError(Label.InSuffPriv);
            return null;
        }

        //recover metadata types to save
        org.Metadata_Types__c = MetadataTypesHelper.joinOptions(selectedTypes);
        Utilities.Secure_DML(org, Utilities.DML_Action.UPS, schema.SObjectType.Org__c);
        return new ApexPages.StandardController(org).view();
    }

    public PageReference doOauth() {
        String apiURL = '';
        if (Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
            apiURL = EncodingUtil.urlEncode([SELECT API_URL__c FROM User WHERE Id = :UserInfo.getUserId()].API_URL__c, 'UTF-8');
        }
        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, 'UTF-8') + '&url=' + apiURL;
        if (org.Org_Type__c == 'Sandbox' || (String.isNotBlank(org.Org_Type__c) && org.Org_Type__c.startsWithIgnoreCase('Scratch Org'))) {
            urlParameters += '&sandbox=true';
        }
        if (org.Org_Type__c == 'Custom Domain') {
            urlParameters += '&domain=' + EncodingUtil.urlEncode(org.Custom_Domain__c, 'UTF-8');
        }
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), 'UTF-8');
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), 'UTF-8');
        urlParameters +=
            '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), 'UTF-8');
        String herokuServer = Settings.server_url;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        PageReference pr = new PageReference(urlOauth);
        return pr;
    }

    public void setUrls() {
        //TODO: move this to external util method in order to use it in other classes
        String urlParameters = '';
        if (String.isNotBlank(org.Metadata_Types__c)) {
            urlParameters += '&filter=' + EncodingUtil.urlEncode(org.Metadata_Types__c, 'UTF-8');
        }
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';
        if (org.Id == null) {
            return;
        }
        metadata_url = urlBase + 'metadata/' + EncodingUtil.urlEncode(org.Id, 'UTF-8') + '?dates=format' + urlParameters;
    }

    public PageReference validate() {
        if (OrgTriggerHelper.isScheduled(org) && !FeatureHelper.isFeatureEnabled('Apex Test')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ': Apex Test'));
            return null;
        }

        if (org.Id != null && !org.Disable_Validation__c && !isScratchOrg) {
            org = Utilities.getOrgById(org.Id);
            if (org.Oauth_Signature__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ADD_AUTHENTICATION));
                return null;
            } else {
                if (!DeployAPI.validateOrg(org.Id)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.WRONG_CREDENTIALS));
                    return null;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.OK_CREDENTIALS));
                }
            }
            if (org.Test_Frequency__c != null && org.Test_Frequency__c != 'None') {
                Org__c copadoOrg = DeployAPI.getCustomerOrg();
                if (copadoOrg == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CUSTOMER_ORG_NOT_EXISTS));
                    return null;
                }
                if (!DeployAPI.validateOrg(copadoOrg.Id)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CUSTOMER_ORG_NOT_VALIDATED));
                }
            }
        }
        return null;
    }

    public PageReference runAllTest() {
        return ordCredentialFeaturesRun(APEX_TEST, Label.TEST_REQUESTED);
    }

    public PageReference orgCodeAnalysis() {
        return ordCredentialFeaturesRun(STATIC_CODE_ANALYSIS, Label.STATIC_CODE_ANALYSIS_REQUESTED);
    }

    public PageReference orgComplianceScan() {
        if (!LicenseHelper.isCCHEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CCH_LICENSE_NOT_ENABLED));
            return null;
        }
        return ordCredentialFeaturesRun(COMPLIANCE_HUB, Label.COMPLIANCE_SCAN_REQUESTED);
    }

    private PageReference ordCredentialFeaturesRun(String featureName, String successMessage) {
        if (!FeatureHelper.isFeatureEnabled(featureName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ': ' + featureName));
            return null;
        }

        if (!DeployAPI.validateOrg(org.Id)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.WRONG_CREDENTIALS));
            return null;
        }

        try {
            if (featureName == APEX_TEST) {
                DeployAPI.testNow(org.Id);
            } else if (featureName == STATIC_CODE_ANALYSIS) {
                DeployAPI.orgCodeAnalysis(org.Id);
            } else if (featureName == COMPLIANCE_HUB) {
                DeployAPI.orgComplianceScan(org.Id);
            }
            ApexPages.getMessages().clear();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
        } catch (Exception exc) {
            System.debug('**f**exc.getMessage() : ' + exc.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + exc.getMessage()));
        }
        return null;
    }

    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditOrgCredential')) {
            // NOTE: actionIsLicenseEnabled('viewEditOrgCredential' returns true always, this code block is unreachable statement, it require investigating and fix
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            //showError = true;
            //showOptions = false;
        }
    }

    public PageReference gotoDxOperations() {
        PageReference pRef = Page.DXOperation;
        if (String.isNotBlank(org.Id)) {
            pRef.getParameters().put('id', org.Id);
        }
        pRef.setRedirect(true);
        return pRef;
    }

    public PageReference deleteOrgCredential() {
        if (String.isNotBlank(org.Id)) {
            try {
                Utilities.Secure_DML(org, Utilities.DML_Action.DEL, SObjectType.Org__c);
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
            DescribeSObjectResult result = Org__c.SObjectType.getDescribe();
            PageReference orgListView = new PageReference('/' + result.getKeyPrefix());
            orgListView.setRedirect(true);
            return orgListView;
        }
        return null;
    }
}