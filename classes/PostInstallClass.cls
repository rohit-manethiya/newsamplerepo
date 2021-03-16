/**
 * TODO: If all Copado customers have vesion 10 or above, logic around it can be removed
 * The post install script is invoked after tests have been run, and is subject to default governor limits.
 * It runs as a special system user that represents your package, so all operations performed by the script appear to be done by your package.
 * You can access this user by using UserInfo. You will only see this user at runtime, not while running tests.
 * The post install script has the following additional properties.
    -It can initiate batch, scheduled, and future jobs.
    -It can’t access Session IDs.
    -It can only perform callouts using an async operation. The callout occurs after the script is run and the install is complete and committed.
    -It can’t call another Apex class in the package if that Apex class uses the with sharing keyword.
    -This keyword can prevent the package from successfully installing. See the Apex Developer Guide to learn more.
 * */
global class PostInstallClass implements InstallHandler {
    private static Blob cryptoKey {
        get {
            if (!String.isEmpty(Settings__c.getOrgDefaults().CryptoKEY__c)) {
                return EncodingUtil.base64Decode(Settings__c.getOrgDefaults().CryptoKEY__c);
            } else {
                String metaKey = [
                    SELECT Id, DeveloperName, Text_Field__c
                    FROM Copado_Protected_Settiing__mdt
                    WHERE DeveloperName = 'Deprecated_Key'
                    LIMIT 1
                ]
                .Text_Field__c;
                return EncodingUtil.base64Decode(metaKey);
            }
        }
        set;
    }

    global void onInstall(InstallContext context) {
        // with v15.1 we are releasing a new feature parameter which is "NumberOfProductionEnvironment", so we need to update that parameter with following line.
        if (context != null && (context.previousVersion() == null)) {
            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();
        }

        String currentVersion;
        try {
            // This method is not suposed to work after v45
            UserInfo.isCurrentUserLicensed('copado'); // This will throw System.TypeException when executed outside of managed context
            Version versionInstalled = System.requestVersion(); // This will throw System.ProcedureException: Method is not supported from an unmanaged namespace when executed outside of managed context, however, this exception is not catchable
            Integer major = versionInstalled.major();
            Integer minor = versionInstalled.minor() != null ? versionInstalled.minor() : 0;
            Integer patch = versionInstalled.patch() != null ? versionInstalled.patch() : 0;
            currentVersion = major + '.' + minor + '.' + patch;
        } catch (System.TypeException ex) {
            // Request version is not supported by unit test classes so hard coded version will move the test forward
            if (Test.isRunningTest()) {
                currentVersion = '16.0.0';
            }
        }
        String userId = context.installerId() != null ? context.installerId() : UserInfo.getUserId() != null ? UserInfo.getUserId() : 'UnknownUser';
        String orgId = context.organizationId() != null ? context.organizationId() : UserInfo.getOrganizationId();
        if (
            Schema.getGlobalDescribe().containsKey('PushTopic') &&
            Schema.getGlobalDescribe().get('PushTopic').getDescribe().isDeletable() &&
            Schema.getGlobalDescribe().get('PushTopic').getDescribe().isQueryable()
        ) {
            String queryString = 'SELECT Id, Name FROM PushTopic WHERE Name = \'CopadoNotifications\'';
            List<SObject> pushTopics = Database.query(queryString);
            if (!pushTopics.isEmpty()) {
                delete pushTopics;
            }
        }
        if (
            context != null &&
            (context.previousVersion() == null || (context.previousVersion() != null && context.previousVersion().compareTo(new Version(10, 0)) < 0))
        ) {
            if (String.isBlank(orgId)) {
                throw new CopadoInstallationException('Could not identify organization Id.');
            }
        } else {
            List<Personal_Settings__c> allSettings = [SELECT Id, API_Key__c FROM Personal_Settings__c WHERE API_Key__c != null];
            for (Personal_Settings__c ps : allSettings) {
                if (ps.API_Key__c != null && ps.API_Key__c.length() < 40) {
                    ps.API_Key__c = encryptAPIKey(ps.API_Key__c);
                }
            }
            update allSettings;
        }

        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        orgDefaultSetting.Current_Copado_Version__c = currentVersion;
        try {
            upsert orgDefaultSetting;
        } catch (Exception e) {
            throw new CopadoInstallationException('Could not upsert Settings.');
        }

        // This is needed from v16.1 onwards since logic was moved to RegisterCopado
        // This also assures that it is an upgrade, since orgDefaultSetting.CryptoKEY__c
        // is never populated in installations yet
        if (String.isNotBlank(orgDefaultSetting.CryptoKEY__c)) {
            RegisterCopado.updatePackageVersion(currentVersion);
        }

        // Encrypting api keys for all version customer
        // This method has not so much sense here now, since Crypto_Key on first installation will always be empty (at least the first time. maybe not when updating the package)
        // and so that Personal Settings API KEY will always be encrypted with DEPRECATED KEY. Maybe this method should be moved to RegisterCopado.cls
        // Also, if we already have an encrypted API KEY with the CRYPTO KEY (already having it too) and this method is called again, it will throw an exception because
        // it will try to decrypt the already existent API KEY with the deprecated key when it was encrypted with the crypto one (altough this is expected and silently catched)
        // Same will happen if we have unencrypted API KEY, and the CRYPTO KEY already, since the API KEY may be encrypted first with the CRYPTO KEY in line 66
        // and then tried to be decrypted with the DEPRECATED KEY (expected and silently catched too)
        // Basically these scenarios were functionally impossible before and that is why it was not failing
        PostInstallClass.encryptAPIKey();
    }

    private static String encryptAPIKey(String clearAPIKey) {
        if (String.isBlank(clearAPIKey)) {
            return null;
        }
        Blob data = Blob.valueOf(clearAPIKey);
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', PostInstallClass.cryptoKey, data));
    }

    private static void encryptAPIKey() {
        /**
         * Old deprecated crypto key
         * In order to decrypt legacy data we need this key
         * and then by using this decrypted data we can encrypt them with a new crypto key that
         * generated per Copado org.
         */
        String metaKey = [SELECT Id, DeveloperName, Text_Field__c FROM Copado_Protected_Settiing__mdt WHERE DeveloperName = 'Deprecated_Key' LIMIT 1]
        .Text_Field__c;
        Blob deprecatedCryptoKey = EncodingUtil.base64Decode(metaKey);
        List<Personal_Settings__c> allSettings;
        //encrypt existing api key if any.
        allSettings = [SELECT Id, API_Key__c FROM Personal_Settings__c WHERE API_Key__c != null];
        // To encode legacy Personal_Settings__c data with the new org specific encryption key.
        for (Personal_Settings__c ps : allSettings) {
            if (ps.API_Key__c != null && ps.API_Key__c.length() < 40) {
                // an api key of less than 40 chars, we assume it is UNENCRYPTED, so we save it encrypthed
                ps.API_Key__c = PostInstallClass.encryptAPIKey(ps.API_Key__c);
            } else {
                // let's try to decrypt it with the LEGACY encryption, and save it with the new one
                try {
                    Blob encryptedKey = EncodingUtil.base64Decode(ps.API_Key__c);
                    String tempAPI = Crypto.decryptWithManagedIV('AES256', deprecatedCryptoKey, encryptedKey).toString();
                    ps.API_Key__c = PostInstallClass.encryptAPIKey(tempAPI);
                } catch (Exception e) {
                    // if this fails, we assume it was encrypted with the NEW one already, do nothing.
                    // if it fails, it can also be due to the fact that when encrypting the crypto key is invalid
                    System.debug('Personal_Settings__c decrypt - encrypt exception: ' + e.getMessage());
                }
            }
        }
        try {
            if (!allSettings.isEmpty()) {
                update allSettings;
            }
        } catch (Exception ex) {
            // Do nothing
            System.debug(ex.getMessage());
        }
    }

    private class CopadoInstallationException extends Exception {}
}