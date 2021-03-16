public with sharing class OrgDiffExtension {
    public String diff_url { get; set; }
    public String deploy_url { get; set; }
    private OrgDiff__c orgdiff;
    public Boolean withCreate { get; set; }
    public Boolean withUpdate { get; set; }
    public Boolean withDelete { get; set; }
    public String errorLevel { get; set; }
    public String messageName { get; set; }
    public Boolean isShareable { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    private Boolean isValidatedToOrg { get; set; }
    private Boolean isValidatedFromOrg { get; set; }
    private final String TRUE_STRING = 'true';
    private final String WITH_CREATE = 'withCreate';
    private final String WITH_UPDATE = 'withUpdate';
    private final String WITH_DELETE = 'withDelete';

    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.WARNING;
        } else if(errorLevel == 'CONFIRM') {
            level = ApexPages.Severity.CONFIRM;
        }
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
    }

    public OrgDiffExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.OrgDiff__c.fields.getMap().keySet()));
        }
        showOptions = true;
        showError = false;
        isValidatedToOrg = false;
        isValidatedFromOrg = false;
        orgdiff = (OrgDiff__c) stdController.getRecord();
        setUrls();
        Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        isShareable = gdMap.containsKey('OrgDiff__Share');
        isLicenseEnabled();
        fillValidateVariables();
    }

    public void setUrls() {
        //TODO: move this to external util method in order to use it in other classes 
        String urlParameters = '?nosid=1';
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';
        diff_url = urlBase + 'diff/' + EncodingUtil.urlEncode(orgdiff.Id, 'UTF-8') + urlParameters;
        if(orgdiff.Metadata_Types__c != null && orgdiff.Metadata_Types__c != '')diff_url += '&filter=' + EncodingUtil.urlEncode(orgdiff.Metadata_Types__c, 'UTF-8');

        withCreate = ApexPages.currentPage().getParameters().get(WITH_CREATE) + '' == TRUE_STRING;
        withUpdate = ApexPages.currentPage().getParameters().get(WITH_UPDATE) + '' == TRUE_STRING;
        withDelete = ApexPages.currentPage().getParameters().get(WITH_DELETE) + '' == TRUE_STRING;
        deploy_url = urlBase + 'diffDeployment/' + EncodingUtil.urlEncode(orgdiff.Id, 'UTF-8') + urlParameters + '&withCreate=' + withCreate + '&withUpdate=' + withUpdate + '&withDelete=' + withDelete;
    }
    public PageReference validateOrgs() {
        if(!isValidatedFromOrg) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.OrgDiff__c.fields.From_Org__c.getDescribe().getLabel() + ': ' + Label.WRONG_CREDENTIALS));
        }
        if(!isValidatedToOrg) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.OrgDiff__c.fields.To_Org__c.getDescribe().getLabel() + ': ' + Label.WRONG_CREDENTIALS));
        }
        return null;
    }
    public PageReference deploy() {
        if(LicenseHelper.isLicensesExceeded()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LICENSES_EXCEEDED));
            return null;
        }
        if(!withCreate && !withUpdate && !withDelete) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.SELECT_AT_LEAST_ONE_RECORD));
            return null;
        }
        if(!isValidatedFromOrg) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.OrgDiff__c.fields.From_Org__c.getDescribe().getLabel() + ': ' + Label.WRONG_CREDENTIALS));
            return null;
        }
        if(!isValidatedToOrg) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Schema.OrgDiff__c.fields.To_Org__c.getDescribe().getLabel() + ': ' + Label.WRONG_CREDENTIALS));
            return null;
        }
        PageReference pr = Page.OrgDiffDeployment;
        pr.setRedirect(true);
        pr.getParameters().put('Id', orgdiff.Id);
        pr.getParameters().put(WITH_CREATE, withCreate + '');
        pr.getParameters().put(WITH_UPDATE, withUpdate + '');
        pr.getParameters().put(WITH_DELETE, withDelete + '');
        return pr;
    }
    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditOrgDifferences')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('or __License__', '')));
            showError = true;
            showOptions = false;
        }
        return;
    }
    private void fillValidateVariables(){
        isValidatedFromOrg = DeployAPI.validateOrg(orgdiff.From_Org__c);
        isValidatedToOrg = DeployAPI.validateOrg(orgdiff.To_Org__c);
    }
}