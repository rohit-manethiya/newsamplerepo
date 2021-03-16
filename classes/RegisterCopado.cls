global inherited sharing class RegisterCopado {

    private static final String DEFAULT_COPADO_NAMESPACE = 'copado__';
    private static final Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();


    global RegisterCopado() {
        throw new InvalidInstantiationException();
    }

    /**
     * The parameter is given to be able to extend the settings usage in the future since global methods cannot change their parameters
     * copadoSettings is a general name but for now we are only getting ServerUrl
     */
    global static void setDefaultSettings(final String copadoSettings) {
        populateDefaultSettings(copadoSettings);
    }

    /**
     * This logic will only affect Trial Orgs for now, where PostInstallClass is not executed by default
     * since for Copado normal installations, default Settings__c record is created with its default values in PostInstallClass
     * TODO: remove default field values for Settings__c default record
     */
    public static void populateDefaultSettings(final String serverUrl) {
        Boolean shouldUpsert = false;

        if (String.isBlank(orgDefaultSetting.Namespace__c)) {
            orgDefaultSetting.Namespace__c = DEFAULT_COPADO_NAMESPACE;
            shouldUpsert = true;
        }
        if (String.isBlank(orgDefaultSetting.Server_URL__c)) {
            orgDefaultSetting.Server_URL__c = serverUrl;
            shouldUpsert = true;
        }

        if (shouldUpsert) {
            upsert orgDefaultSetting;
        }
    }

    global static void setUpCopadoRegistration() {
        // We call the registerDefaultCryptoKey from here instead of making it global since
        // otherwise we could not change it in the future if for example, we need to add a parameter
        registerDefaultCryptoKeyAndVersion(null);
    }

    /**
     * This method is being called from PostInstallClass class to update currentversion in the bacekdend by doing a callout
     */
    @Future(Callout=true)
    public static void updatePackageVersion(String version) {
        registerDefaultCryptoKeyAndVersion(version);
    }

    /**
     * Crypto key is retrieved, or generated and saved to send it to the backend server in order to
     * be used when storing and reading sensitive information like github passwords
     */

    private static void registerDefaultCryptoKeyAndVersion(final String version) {

        final String key = getKey();
        final Map<String, Object> parsedResponse = doCallout(key, version);
        if (isResponseSuccessful(parsedResponse)) {
            upsertDefaultCryptoKey(key);
        } else {
            addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected response: ' + parsedResponse));
        }
    }

    private static String getKey() {
        return String.isBlank(orgDefaultSetting.CryptoKEY__c)
            ? EncodingUtil.base64Encode(Crypto.generateAesKey(256))
            : orgDefaultSetting.CryptoKEY__c;
    }


    private static Map<String, Object> doCallout(final String key, final String version) {
        final String endpoint = getRequestEndpoint(orgDefaultSetting.Server_URL__c);
        final String currentCopadoVersion = version != null ? version : orgDefaultSetting.Current_Copado_Version__c;
        final LogKey logKeyInstance = new LogKey(key, currentCopadoVersion);

        return (Map<String, Object>) new HerokuCallout(endpoint, HttpMethod.POST)
            .default()
            .body(logKeyInstance)
            .request()
            .parseResponse();

    }

    private static String getRequestEndpoint(final String serverUrl) {
        return serverUrl + '/json/v1/registerKey';
    }

    private static Boolean isResponseSuccessful(final Map<String, Object> parsedResponse) {
            final Boolean isSuccess = Boolean.valueOf(parsedResponse.get('isSuccess'));
            final Boolean isFinished = Boolean.valueOf(parsedResponse.get('isFinished'));
            return isSuccess && isFinished;
    }

    private static void upsertDefaultCryptoKey(final String key) {
            if (String.isBlank(orgDefaultSetting.CryptoKEY__c)) {
                orgDefaultSetting.CryptoKEY__c = key;
                upsert orgDefaultSetting;
            }
            addPageMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Copado_Application_Registered_Successfully));
    }

    private static void addPageMessage(final ApexPages.Message message) {
        if (ApexPages.currentPage() != null) {
            ApexPages.addMessage(message);
        }
    }

    private class LogKey {
        private final String key;
        private final String copadoVersion;

        public LogKey(String key, String copadoVersion) {
            this.key = key;
            this.copadoVersion = copadoVersion;
        }
    }

    private class InvalidInstantiationException extends Exception {}
}