/**
 * Extension of New, Edit and view page for External CI Setting object.
 *
 * New, Edit and View pages are overriden by custom visualforce pages.
 * @author Mert YALTI
 * @date 15.06.2017
 * @see EditExternalCISettings
 * @see ViewExternalCISettings
 */
public with sharing class EditExternalCISetting {
    public External_CI_Setting__c externalCISetting { get; set; }
    private String settingId { get; set; }
    public List<External_CI_Job__c> jobs { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public String username { get; set; }
    public String password { get; set; }
    public String apiKey { get; set; }

    public EditExternalCISetting(ApexPages.StandardController std) {
        showOptions = true;
        showError = false;
        username = '';
        password = '';
        apiKey = '';
        isLicenseEnabled();
        External_CI_Setting__c setting = (External_CI_Setting__c) std.getRecord();
        settingId = setting.Id;
        if(std.getId() != null) {
            externalCISetting = Utilities.getCISettingById(std.getId());
        } else {
            externalCISetting = new External_CI_Setting__c();
        }

        if(String.isNotBlank(externalCISetting.Id)) {
            Sensitive_Information__c externalCIConfiguration = Sensitive_Information__c.getValues(externalCISetting.Id);
            if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Username__c)) {
                username = externalCIConfiguration.Username__c;
            }
            if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Password__c)) {
                password = DeployAPI.decryptAPIKey(externalCIConfiguration.Password__c);
            }
            if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.API_Token__c)) {
                apiKey = externalCIConfiguration.API_Token__c;
            }
        }
        getRelated();
    }
    /**
     * This method works as a standard save function
     * @see Utilities
     * @return PageReference
     */

    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditExternalCI')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }
    public PageReference save() {
        if(externalCISetting.Endpoint__c != null) {
            Utilities.Secure_DML(externalCISetting, Utilities.DML_Action.UPS, schema.SObjectType.External_CI_Setting__c);
            settingId = externalCISetting.Id;

            Sensitive_Information__c externalCIConfiguration = Sensitive_Information__c.getValues(settingId);
            if(externalCIConfiguration == null) {
                externalCIConfiguration = new Sensitive_Information__c();
                externalCIConfiguration.Name = settingId;
            }
            if(String.isNotBlank(username)) {
                externalCIConfiguration.Username__c = username;
            }
            if(String.isNotBlank(password)) {
                externalCIConfiguration.Password__c = DeployAPI.encryptAPIKey(password);
            }

            externalCIConfiguration.API_Token__c = apiKey;

            Utilities.Secure_DML(externalCIConfiguration, Utilities.DML_Action.UPS, schema.SObjectType.Sensitive_Information__c);

            return new ApexPages.StandardController(externalCISetting).view();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PLEASE_ENTER_VALID_URL));
            return null;
        }
    }
    public void getRelated() {
        jobs = ExternalCIAPIFactory.queryAllValues('External_CI_Job__c', 'External_CI_Setting__c', externalCISetting.Id, '', '');
    }

    public PageReference validate() {
        return EditExternalCISetting.validateConnection(externalCISetting);
    }
    /**
     * This method validates given credentials against selected CI Tool and its endpoint
     * @param externalCISetting External CI Setting record to validate it's credentials.
     * @see DeployAPI
     * @see ExternalCIAPIFactory
     * @return PageReference
     */
    public static PageReference validateConnection(External_CI_Setting__c externalCISetting) {
        ExternalCIAPIFactory factory = new ExternalCIAPIFactory(externalCISetting.Id);
        /**
         * URL Parameters
         * sid = salesforce session id
         * url = user's API URL
         * uri = External CI system endpoint
         * un = External CI system user name
         * pw = External CI system api token
         */

        String url = DeployAPI.copadoURL + '/json/v1/validateXCI/' + externalCISetting.Id;
        url += '?uri=' + EncodingUtil.urlEncode(externalCISetting.Endpoint__c, 'UTF-8') + '&type=' + EncodingUtil.urlEncode(externalCISetting.CI_Tool__c, 'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        Map<String, String> optionalHeader = new Map<String, String>();
        Sensitive_Information__c externalCIConfiguration = Sensitive_Information__c.getValues(externalCISetting.Id);
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Username__c)) {
            optionalHeader.put('un', externalCIConfiguration.Username__c);
        }
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Password__c)) {
            optionalHeader.put('pw', DeployAPI.decryptAPIKey(externalCIConfiguration.Password__c));
        }
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.API_Token__c)) {
            optionalHeader.put('tk', externalCIConfiguration.API_Token__c);
        }
        HttpResponse res = factory.sendRequest(url, 'GET', optionalHeader, true);

        ExternalCIAPIFactory.Validate isValid = (ExternalCIAPIFactory.Validate) factory.parseResponseBody('Validate', res);

        if(!isValid.success) {
            List<Object> pageMessages = new List<Object>{Label.WRONG_CREDENTIALS, isValid.message, Label.WRONG_CREDENTIALS_ACTION};
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, pageMessages);
        } else {
            try {
                externalCISetting.Credential_Validated__c = true;
                Utilities.Secure_DML(externalCISetting, Utilities.DML_Action.UPD, schema.SObjectType.External_CI_Setting__c);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FAILED));
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.OK_CREDENTIALS));
        }
        return null;
    }
}