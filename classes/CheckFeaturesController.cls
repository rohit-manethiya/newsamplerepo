global with sharing class CheckFeaturesController {
    public String errorMessage {
        get {
            String message = '';
            if (!isApplicationRegistered()) {
                message = Label.COPADO_REGISTRATION_REQUIRED;
            } else {
                if (!checkSetup()) {
                    message = Label.SETUP_ACTION_REQUIRED_MSG.replace('__USERNAME__', UserInfo.getUserName());
                }
            }
            return message;
        }
    }

    @RemoteAction
    global static Boolean isApplicationRegistered() {
        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        return String.isNotBlank(orgDefaultSetting.CryptoKEY__c);
    }

    /**
     * returns the static namespacevi
     * @return [description]
     */
    public String getNamespace() {
        return Settings.ns;
    }

    /**
     * Async call to update features in custom settings if needed
     */
    @RemoteAction
    global static void checkFeatures() {
        DeployAPI.checkSyncFeatures();
    }

    /**
     * Async call to check setup Org
     */
    @RemoteAction
    global static Boolean checkSetup() {
        String orgId = Userinfo.getOrganizationId() + '_' + Userinfo.getUserId();
        Org__c[] org = [SELECT ID FROM Org__c WHERE Validated_Date__c != NULL AND SFDC_Org_ID__c = :orgId LIMIT 1];
        return !org.isEmpty();
    }

    /**
     * Async call to update features in custom settings if needed
     */
    @RemoteAction
    global static void checkLicenses() {
        DeployAPI.checkSyncLicenses();
    }
}