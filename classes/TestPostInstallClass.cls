@IsTest
private with sharing class TestPostInstallClass {
    private static final String TEST_LEGACY_ENCRYPTED_API_KEY {
        get {
            if (TEST_LEGACY_ENCRYPTED_API_KEY == null) {
                TEST_LEGACY_ENCRYPTED_API_KEY = getTestLegacyEncryptedApiKey();
            }
            return TEST_LEGACY_ENCRYPTED_API_KEY;
        }
        set;
    }

    private static String getTestLegacyEncryptedApiKey() {
        Blob decodedKey = VALID_LEGACY_CRYPTO_KEY;
        Blob testApiKey = Blob.valueOf('testApiKey');
        Blob encryptedApiKey = Crypto.encryptWithManagedIV('AES256', decodedKey, testApiKey);
        String encodedTestApiKey = EncodingUtil.base64Encode(encryptedApiKey);

        return encodedTestApiKey;
    }

    private static final Blob VALID_LEGACY_CRYPTO_KEY {
        get {
            if (VALID_LEGACY_CRYPTO_KEY == null) {
                VALID_LEGACY_CRYPTO_KEY = getValidLegacyCryptoKey();
            }
            return VALID_LEGACY_CRYPTO_KEY;
        }
        set;
    }

    private static Blob getValidLegacyCryptoKey() {
        String legacyCryptoKey = [
            SELECT Id, DeveloperName, Text_Field__c
            FROM Copado_Protected_Settiing__mdt
            WHERE DeveloperName = 'Deprecated_Key'
            LIMIT 1
        ]
        .Text_Field__c;

        return EncodingUtil.base64Decode(legacyCryptoKey);
    }

    private static final String TEST_NEW_ENCRYPTED_API_KEY {
        get {
            if (TEST_NEW_ENCRYPTED_API_KEY == null) {
                TEST_NEW_ENCRYPTED_API_KEY = getTestNewEncryptedApiKey();
            }
            return TEST_NEW_ENCRYPTED_API_KEY;
        }
        set;
    }

    private static String getTestNewEncryptedApiKey() {
        Blob decodedKey = VALID_NEW_CRYPTO_KEY;
        Blob testApiKey = Blob.valueOf('testApiKey');
        Blob encryptedApiKey = Crypto.encryptWithManagedIV('AES256', decodedKey, testApiKey);
        String encodedTestApiKey = EncodingUtil.base64Encode(encryptedApiKey);

        return encodedTestApiKey;
    }

    private static final Blob VALID_NEW_CRYPTO_KEY {
        get {
            if (VALID_NEW_CRYPTO_KEY == null) {
                VALID_NEW_CRYPTO_KEY = Crypto.generateAesKey(256);
            }
            return VALID_NEW_CRYPTO_KEY;
        }
        set;
    }

    @TestSetup
    static void setupTestData() {
        List<User> users = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet copadoPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = copadoPermissionSet.Id);
    }

    // Encrypted as legacy twice
    @IsTest
    static void testUnencryptedApiKeyWithoutNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, 'testApiKey');
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.U_LE);
        }
    }

    // Encrypted as legacy once
    @IsTest
    static void testUnencryptedApiKeyWithoutNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, 'testApiKey');
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.U_LE);
        }
    }

    // Encrypted as new twice
    @IsTest
    static void testUnencryptedApiKeyWithValidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, 'testApiKey');
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.U_NE);
        }
    }

    // Encrypted as new once
    @IsTest
    static void testUnencryptedApiKeyWithValidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, 'testApiKey');
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.U_NE);
        }
    }

    // Should remain unencrypted trying twice
    @IsTest
    static void testUnencryptedApiKeyWithInValidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, 'testApiKey');
            whenInstall(new Version(13, 0), true);
            thenCheck(KEY_RESULT_COMBINATION.U_R);
        }
    }

    // Should remain unencrypted trying once
    @IsTest
    static void testUnencryptedApiKeyWithInValidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, 'testApiKey');
            whenInstall(null, true);
            thenCheck(KEY_RESULT_COMBINATION.U_R);
        }
    }

    // Should have been legacy reencrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithoutNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.LE_LR);
        }
    }

    // Should have been legacy reencrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithoutNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.LE_LR);
        }
    }

    // Should have been new reencrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithValidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.LE_NR);
        }
    }

    // Should have been new reencrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithValidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.LE_NR);
        }
    }

    // Should remain legacy encrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithInvalidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.LE_R);
        }
    }

    // Should remain legacy encrypted
    @IsTest
    static void testLegacyEncryptedApiKeyWithInvalidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, TEST_LEGACY_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.LE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithoutNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithoutNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(null, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithValidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithValidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(true, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithInvalidNewCryptoKeyWithVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(new Version(13, 0), false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    // Should remain new encrypted
    @IsTest
    static void testNewEncryptedApiKeyWithInvalidNewCryptoKeyWithoutVersion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            givenSetup(false, TEST_NEW_ENCRYPTED_API_KEY);
            whenInstall(null, false);
            thenCheck(KEY_RESULT_COMBINATION.NE_R);
        }
    }

    private static void givenSetup(Boolean setValidCryptoKey, String apiKey) {
        // If the argument is null, do not set any crypto key
        if (setValidCryptoKey != null) {
            setCryptoKey(setValidCryptoKey);
        }

        Personal_Settings__c personalSetting = Personal_Settings__c.getOrgDefaults();
        personalSetting.API_Key__c = apiKey;
        upsert personalSetting;
    }

    private static void setCryptoKey(Boolean isValid) {
        if (isValid) {
            upsertDefaultSettingCryptoKey(EncodingUtil.base64Encode(VALID_NEW_CRYPTO_KEY));
        } else {
            upsertDefaultSettingCryptoKey('CryptoKeyTest');
        }
    }

    private static void upsertDefaultSettingCryptoKey(String newCryptoKey) {
        Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
        orgDefaultSetting.CryptoKEY__c = newCryptoKey;
        upsert orgDefaultSetting;
    }

    private static void whenInstall(Version version, Boolean expectException) {
        String mockResponse = '{"ok": "key registered", "isSuccess": true, "isFinished": true}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(mockResponse, null));

        Test.startTest();
        PostInstallClass postInstall = new PostInstallClass();
        if (expectException) {
            try {
                Test.testInstall(postInstall, version);
                System.assert(false, 'Invalid new crypto key should have raised an exception');
            } catch (Exception e) {
                System.assertEquals(
                    'Invalid private key. Must be 32 bytes.',
                    e.getMessage(),
                    'Exception type should be System.InvalidParameterValueException'
                );
            }
        } else {
            Test.testInstall(postInstall, version);
        }
        Test.stopTest();
    }

    /**
     * Enum values notation meaning:
     *                          As a given key:
     *                                  U: Unencrypted
     *                                  LE: Legacy encrypted
     *                                  NE: New encrypted
     *                          As a result:
     *                                  LE: Legacy encrypted (As a result)
     *                                  NE: New encrypted (As a result)
     *                                  LR: Legacy reencrypted
     *                                  NR: New rencrypted
     *                                  R: Remained
     */
    private Enum KEY_RESULT_COMBINATION { U_LE, U_NE, U_R, LE_LR, LE_NR, LE_R, NE_R }

    private static void thenCheck(KEY_RESULT_COMBINATION keyResultCombination) {
        Personal_Settings__c personalSetting = Personal_Settings__c.getOrgDefaults();

        switch on keyResultCombination {
            when U_LE {
                System.assertNotEquals(
                    'testApiKey',
                    personalSetting.API_Key__c,
                    'Personal unencrypted API key should have been replaced by a legacy encrypted one'
                );
                assertValidLegacyDecryption(personalSetting);
            }
            when U_NE {
                System.assertNotEquals(
                    'testApiKey',
                    personalSetting.API_Key__c,
                    'Personal unencrypted API key should have been replaced by a new encrypted one'
                );
                assertValidNewDecryption(personalSetting);
            }
            when U_R {
                System.assertEquals('testApiKey', personalSetting.API_Key__c, 'Personal unencrypted API key should have remained');
            }
            when LE_LR {
                System.assertNotEquals(
                    TEST_LEGACY_ENCRYPTED_API_KEY,
                    personalSetting.API_Key__c,
                    'Personal legacy encrypted API key should have been reencrypted with legacy crypto key'
                );
                assertValidLegacyDecryption(personalSetting);
            }
            when LE_NR {
                System.assertNotEquals(
                    TEST_LEGACY_ENCRYPTED_API_KEY,
                    personalSetting.API_Key__c,
                    'Personal legacy encrypted API key should have been reencrypted with new crypto key'
                );
                assertValidNewDecryption(personalSetting);
            }
            when LE_R {
                System.assertEquals(TEST_LEGACY_ENCRYPTED_API_KEY, personalSetting.API_Key__c, 'Personal legacy encrypted API key should have remained');
                assertValidLegacyDecryption(personalSetting);
            }
            when NE_R {
                System.assertEquals(TEST_NEW_ENCRYPTED_API_KEY, personalSetting.API_Key__c, 'Personal new encrypted API key should have remained');
                assertValidNewDecryption(personalSetting);
            }
        }

        System.assertNotEquals(
            '16.0.0)',
            Settings__c.getOrgDefaults().Current_Copado_Version__c,
            'Default version should be 16.0.0 in text context'
        );
    }

    private static void assertValidLegacyDecryption(Personal_Settings__c personalSetting) {
        try {
            Blob encryptedApiKey = EncodingUtil.base64Decode(personalSetting.API_Key__c);
            Blob decryptedApiKey = Crypto.decryptWithManagedIV('AES256', VALID_LEGACY_CRYPTO_KEY, encryptedApiKey);
            System.assertEquals('testApiKey', decryptedApiKey.toString(), 'Original and decrypted API key do not match');
        } catch (Exception e) {
            System.assert(false, 'Legacy decryption should not have failed');
        }
    }

    private static void assertValidNewDecryption(Personal_Settings__c personalSetting) {
        try {
            Blob encryptedApiKey = EncodingUtil.base64Decode(personalSetting.API_Key__c);
            Blob decryptedApiKey = Crypto.decryptWithManagedIV('AES256', VALID_NEW_CRYPTO_KEY, encryptedApiKey);
            System.assertEquals('testApiKey', decryptedApiKey.toString(), 'Original and decrypted API key do not match');
        } catch (Exception e) {
            System.assert(false, 'New decryption should not have failed');
        }
    }
}