/**
 * This class can be accessed outside of the manage package that allows users to manage Copado Licenses.
 * @author Mert YALTI
 * @version 1.0
 * @date 18.09.2017
 */
global with sharing class GlobalAPI {
    /**
     * Returns Total Licenses, used licenses and available licenses in a wrapper class as a general license information
     * @see CopadoLicenses
     * @see LicenseManagerController
     * @return CopadoLicenses wrapper
     */
    global CopadoLicenses getLicenseInformation() {
        LicenseManagerController cont = new LicenseManagerController();

        CopadoLicenses licenseInfo = new CopadoLicenses();
        licenseInfo.totalNumberOfCopadoLicenses = cont.copadoLicensesAvailable;
        licenseInfo.totalNumberOfCCMLicenses = cont.ccmLicensesAvailable;
        licenseInfo.totalNumberOfCSTLicenses = cont.cstLicensesAvailable;
        licenseInfo.totalNumberOfCADLicenses = cont.cadLicensesAvailable;
        licenseInfo.totalNumberOfCCHLicenses = cont.cchLicensesAvailable;

        licenseInfo.usedCopadoLicenses = cont.copadoLicensesUsed;
        licenseInfo.usedCCMLicenses = cont.ccmLicensesUsed;
        licenseInfo.usedCSTLicenses = cont.cstLicensesUsed;
        licenseInfo.usedCADLicenses = cont.cadLicensesUsed;
        licenseInfo.usedCCHLicenses = cont.cchLicensesUsed;

        licenseInfo.availableCopadoLicenses = cont.copadoLicensesAvailable - cont.copadoLicensesUsed;
        licenseInfo.availableCCMLicenses = cont.ccmLicensesAvailable - cont.ccmLicensesUsed;
        licenseInfo.availableCSTLicenses = cont.cstLicensesAvailable - cont.cstLicensesUsed;
        licenseInfo.availableCADLicenses = cont.cadLicensesAvailable - cont.cadLicensesUsed;
        licenseInfo.availableCCHLicenses = cont.cchLicensesAvailable - cont.cchLicensesUsed;

        return licenseInfo;
    }
    /**
     * In order to see which users have which licenses enabled.
     * @see Schema
     * @see SObjectField
     * @return Returns list of assigned copado license
     */
    global List<UserLicense> listCopadoLicenses() {
        String sObjectName = 'Copado_License__c';
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
            sObjectName = Settings.ns + sObjectName;
        }
        Map<String, String> dMap = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        List<String> accessiblefields = new List<String>();

        for (Schema.SObjectField field : fields.values()) {
            accessiblefields.add(field.getDescribe().getName());
        }

        String allfields = '';

        for (String fieldname : accessiblefields) {
            allfields += fieldname + ',';
        }

        allfields = allfields.substring(0, allfields.length() - 1);

        dMap.put(Label.OBJECT, sObjectName);
        dMap.put(Label.FIELDS, allfields);

        String soqlString = 'SELECT ' + dMap.get(Label.FIELDS) + ' FROM ' + dMap.get(Label.OBJECT) + ' WHERE IsDeleted = FALSE ORDER BY Name DESC';

        List<UserLicense> licenseList = new List<UserLicense>();
        for (Copado_License__c cl : Database.query(soqlString)) {
            licenseList.add(
                new UserLicense(cl.SetupOwnerId, cl.Enable_CAD__c, cl.Enable_CCH__c, cl.Enable_CCM__c, cl.Enable_Copado__c, cl.Enable_CST__c)
            );
        }
        return licenseList;
    }
    /**
     * If the userID that passed as a License setup owner has already have a license assigned this method updates that license details
     * Otherwise new license record is being created
     * @param  license Copado License
     * @return        Id of affected record (Update/Insert)
     */
    global String upsertCopadoLicense(Id userId, UserLicense licenseDetails) {
        Settings__c sItem = Settings__c.getOrgDefaults();
        String sObjectName = 'Copado_License__c';
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
            sObjectName = Settings.ns + sObjectName;
        }
        Map<String, String> dMap = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        List<String> accessiblefields = new List<String>();

        for (Schema.SObjectField field : fields.values()) {
            accessiblefields.add(field.getDescribe().getName());
        }

        String allfields = '';

        for (String fieldname : accessiblefields) {
            allfields += fieldname + ',';
        }

        allfields = allfields.substring(0, allfields.length() - 1);

        dMap.put(Label.OBJECT, sObjectName);
        dMap.put(Label.FIELDS, allfields);

        String soqlString =
            'SELECT ' +
            dMap.get(Label.FIELDS) +
            ' FROM ' +
            dMap.get(Label.OBJECT) +
            ' WHERE SetupOwnerId = \'' +
            String.escapeSingleQuotes(userId) +
            '\' ORDER BY Name DESC LIMIT 1';
        Copado_License__c systemLicense;
        try {
            systemLicense = Database.query(soqlString);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        try {
            if (systemLicense != null) {
                for (String fItem : dMap.get(Label.FIELDS).split(',')) {
                    if (fields.get(fItem.trim()).getDescribe().isUpdateable()) {
                        Object upsVal = licenseDetails.getField(fItem.trim());
                        if (
                            upsVal != null && upsVal instanceof Boolean &&
                            (Boolean) upsVal &&
                            (Boolean) systemLicense.get(fItem.trim()) != (Boolean) upsVal
                        ) {
                            checkAvailabilityFromField(fItem.trim());
                            systemLicense.put(fItem.trim(), (Boolean) upsVal);
                        } else if (upsVal != null && upsVal instanceof Boolean) {
                            systemLicense.put(fItem.trim(), (Boolean) upsVal);
                        } else if (upsVal != null && upsVal instanceof Id) {
                            systemLicense.put(fItem.trim(), (Id) upsVal);
                        } else if (upsVal != null && upsVal instanceof String) {
                            systemLicense.put(fItem.trim(), (String) upsVal);
                        }
                    }
                }
                Utilities.Secure_DML(systemLicense, Utilities.DML_Action.UPD, schema.SObjectType.Copado_License__c);
                return 'UPDATED';
            } else {
                Copado_License__c license = new Copado_License__c();
                if (!licenseDetails.isCADenabled) {
                    license.Enable_CAD__c = licenseDetails.isCADenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CAD__c');
                    license.Enable_CAD__c = licenseDetails.isCADenabled;
                }
                if (!licenseDetails.isCCHenabled) {
                    license.Enable_CCH__c = licenseDetails.isCCHenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CCH__c');
                    license.Enable_CCH__c = licenseDetails.isCCHenabled;
                }
                if (!licenseDetails.isCCMenabled) {
                    license.Enable_CCM__c = licenseDetails.isCCMenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CCM__c');
                    license.Enable_CCM__c = licenseDetails.isCCMenabled;
                }
                if (!licenseDetails.isCopadoEnabled) {
                    license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_Copado__c');
                    license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
                }
                if (!licenseDetails.isCSTenabled) {
                    license.Enable_CST__c = licenseDetails.isCSTenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CST__c');
                    license.Enable_CST__c = licenseDetails.isCSTenabled;
                }
                license.SetupOwnerId = userId;

                Utilities.Secure_DML(license, Utilities.DML_Action.INS, schema.SObjectType.Copado_License__c);
                return 'INSERTED';
            }
        } catch (Exception ex) {
            throw new CopadoAPIException(ex.getMessage());
        }
    }
    /**
     * If the userID that passed as a License setup owner has already have a license assigned this method updates that license details
     * Otherwise new license record is being created
     * @param  license Copado License
     * @return        LicenseOperationResult object with  operation result details (Update/Insert)
     */
    global LicenseOperationResult upsertCopadoLicense(UserLicense licenseDetails) {
        Settings__c sItem = Settings__c.getOrgDefaults();
        String sObjectName = 'Copado_License__c';
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
            sObjectName = Settings.ns + sObjectName;
        }
        Map<String, String> dMap = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        List<String> accessiblefields = new List<String>();

        for (Schema.SObjectField field : fields.values()) {
            accessiblefields.add(field.getDescribe().getName());
        }

        String allfields = '';

        for (String fieldname : accessiblefields) {
            allfields += fieldname + ',';
        }

        allfields = allfields.substring(0, allfields.length() - 1);

        dMap.put(Label.OBJECT, sObjectName);
        dMap.put(Label.FIELDS, allfields);

        String soqlString =
            'SELECT ' +
            dMap.get(Label.FIELDS) +
            ' FROM ' +
            dMap.get(Label.OBJECT) +
            ' WHERE SetupOwnerId = \'' +
            String.escapeSingleQuotes(licenseDetails.userId) +
            '\' ORDER BY Name DESC LIMIT 1';
        Copado_License__c systemLicense;
        try {
            systemLicense = Database.query(soqlString);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        try {
            if (systemLicense != null) {
                for (String fItem : dMap.get(Label.FIELDS).split(',')) {
                    if (fields.get(fItem.trim()).getDescribe().isUpdateable()) {
                        Object upsVal = licenseDetails.getField(fItem.trim());
                        if (
                            upsVal != null && upsVal instanceof Boolean &&
                            (Boolean) upsVal &&
                            (Boolean) systemLicense.get(fItem.trim()) != (Boolean) upsVal
                        ) {
                            checkAvailabilityFromField(fItem.trim());
                            systemLicense.put(fItem.trim(), (Boolean) upsVal);
                        } else if (upsVal != null && upsVal instanceof Boolean) {
                            systemLicense.put(fItem.trim(), (Boolean) upsVal);
                        } else if (upsVal != null && upsVal instanceof Id) {
                            systemLicense.put(fItem.trim(), (Id) upsVal);
                        } else if (upsVal != null && upsVal instanceof String) {
                            systemLicense.put(fItem.trim(), (String) upsVal);
                        }
                    }
                }
                Utilities.Secure_DML(systemLicense, Utilities.DML_Action.UPD, schema.SObjectType.Copado_License__c);
                return new LicenseOperationResult(true, false, true, '');
            } else {
                Copado_License__c license = new Copado_License__c();
                if (!licenseDetails.isCADenabled) {
                    license.Enable_CAD__c = licenseDetails.isCADenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CAD__c');
                    license.Enable_CAD__c = licenseDetails.isCADenabled;
                }
                if (!licenseDetails.isCCHenabled) {
                    license.Enable_CCH__c = licenseDetails.isCCHenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CCH__c');
                    license.Enable_CCH__c = licenseDetails.isCCHenabled;
                }
                if (!licenseDetails.isCCMenabled) {
                    license.Enable_CCM__c = licenseDetails.isCCMenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CCM__c');
                    license.Enable_CCM__c = licenseDetails.isCCMenabled;
                }
                if (!licenseDetails.isCopadoEnabled) {
                    license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_Copado__c');
                    license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
                }
                if (!licenseDetails.isCSTenabled) {
                    license.Enable_CST__c = licenseDetails.isCSTenabled;
                } else {
                    checkAvailabilityFromField(sItem.Namespace__c + 'Enable_CST__c');
                    license.Enable_CST__c = licenseDetails.isCSTenabled;
                }
                license.SetupOwnerId = licenseDetails.userId;

                Utilities.Secure_DML(license, Utilities.DML_Action.INS, schema.SObjectType.Copado_License__c);
                return new LicenseOperationResult(true, true, false, '');
            }
        } catch (Exception ex) {
            throw new CopadoAPIException(ex.getMessage());
        }
    }
    /**
     * Deletes Copado license from the system by using given licenseId
     * @param  licenseId Copado License Id
     * @return           result boolean
     */
    global Boolean deleteCopadoLicense(Id userId) {
        List<Copado_License__c> license = new List<Copado_License__c>();
        license = [SELECT Id FROM Copado_License__c WHERE SetupOwnerId = :userId];
        try {
            Utilities.Secure_DML(license, Utilities.DML_Action.DEL, schema.SObjectType.Copado_License__c);
            return true;
        } catch (Exception ex) {
            throw new CopadoAPIException(ex.getMessage());
        }
    }
    global with sharing class CopadoAPIException extends Exception {
    }
    /**
     * Wrapper class for general Copado License information
     */
    global with sharing class CopadoLicenses {
        //License totals
        global Integer totalNumberOfCopadoLicenses { get; set; }
        global Integer totalNumberOfCCMLicenses { get; set; }
        global Integer totalNumberOfCSTLicenses { get; set; }
        global Integer totalNumberOfCADLicenses { get; set; }
        global Integer totalNumberOfCCHLicenses { get; set; }
        //Used licenses
        global Integer usedCopadoLicenses { get; set; }
        global Integer usedCCMLicenses { get; set; }
        global Integer usedCSTLicenses { get; set; }
        global Integer usedCADLicenses { get; set; }
        global Integer usedCCHLicenses { get; set; }
        //Available licenses
        global Integer availableCopadoLicenses { get; set; }
        global Integer availableCCMLicenses { get; set; }
        global Integer availableCSTLicenses { get; set; }
        global Integer availableCADLicenses { get; set; }
        global Integer availableCCHLicenses { get; set; }
    }

    // it is not used anywhere, commented out
    /*private Map<String, String> licenseFieldMapping = new Map<String, String> {
        'Enable_CAD__c' => 'isCADenabled',
        'Enable_CCH__c' => 'isCCHenabled',
        'Enable_CCM__c' => 'isCCMenabled',
        'Enable_Copado__c' => 'isCopadoEnabled',
        'Enable_CST__c' => 'isCSTenabled',
        'SetupOwnerId' => 'userId'
    };*/

    private String copadoLicenseLimitReached = Label.COPADO_LICENSE_LIMIT_REACHED;
    private String ccmLicenseLimitReached = Label.CCM_LICENSE_LIMIT_REACHED;
    private String cstLicenseLimitReached = Label.CST_LICENSE_LIMIT_REACHED;
    private String cadLicenseLimitReached = Label.CAD_LICENSE_LIMIT_REACHED; //DP Copado Agile Delivery
    private String cchLicenseLimitReached = Label.CCH_LICENSE_LIMIT_REACHED;

    global with sharing class LicenseOperationResult {
        global Boolean isSuccess { get; set; }
        global Boolean isCreated { get; set; }
        global Boolean isUpdated { get; set; }
        global String errorString { get; set; }
        global LicenseOperationResult(Boolean isSuccessParam, Boolean isCreatedParam, Boolean isUpdatedParam, String errorStringParam) {
            isSuccess = isSuccessParam;
            isCreated = isCreatedParam;
            isUpdated = isUpdatedParam;
            errorString = errorStringParam;
        }
        global LicenseOperationResult(Boolean isSuccessParam, String errorStringParam) {
            isSuccess = isSuccessParam;
            isCreated = false;
            isUpdated = false;
            errorString = errorStringParam;
        }
    }

    global with sharing class UserLicense {
        global Boolean isCADenabled { get; set; }
        global Boolean isCCHenabled { get; set; }
        global Boolean isCCMenabled { get; set; }
        global Boolean isCopadoEnabled { get; set; }
        global Boolean isCSTenabled { get; set; }
        global Id userId { get; set; }

        global UserLicense(
            Id userId,
            Boolean isCADenabled,
            Boolean isCCHenabled,
            Boolean isCCMenabled,
            Boolean isCopadoEnabled,
            Boolean isCSTenabled
        ) {
            this.userId = userId;
            this.isCADenabled = isCADenabled;
            this.isCCHenabled = isCCHenabled;
            this.isCCMenabled = isCCMenabled;
            this.isCopadoEnabled = isCopadoEnabled;
            this.isCSTenabled = isCSTenabled;
        }

        global UserLicense() {
            this.userId = UserInfo.getUserId();
            this.isCADenabled = false;
            this.isCCHenabled = false;
            this.isCCMenabled = false;
            this.isCopadoEnabled = false;
            this.isCSTenabled = false;
        }
        public Object getField(String fieldName) {
            Settings__c sItem = Settings__c.getOrgDefaults();
            if (fieldName == sItem.Namespace__c + 'Enable_CAD__c') {
                return isCADenabled;
            } else if (fieldName == sItem.Namespace__c + 'Enable_CCH__c') {
                return isCCHenabled;
            } else if (fieldName == sItem.Namespace__c + 'Enable_CCM__c') {
                return isCCMenabled;
            } else if (fieldName == sItem.Namespace__c + 'Enable_Copado__c') {
                return isCopadoEnabled;
            } else if (fieldName == sItem.Namespace__c + 'Enable_CST__c') {
                return isCSTenabled;
            } else if (fieldName == 'SetupOwnerId') {
                return userId;
            }
            return null;
        }
    }
    private void checkAvailabilityFromField(String fieldName) {
        Settings__c sItem = Settings__c.getOrgDefaults();
        CopadoLicenses licenseInfo = getLicenseInformation();
        if (fieldName == sItem.Namespace__c + 'Enable_CAD__c') {
            if (licenseInfo.availableCADLicenses <= 0) {
                throw new CopadoAPIException(cadLicenseLimitReached);
            }
        } else if (fieldName == sItem.Namespace__c + 'Enable_CCH__c') {
            if (licenseInfo.availableCCHLicenses <= 0) {
                throw new CopadoAPIException(cchLicenseLimitReached);
            }
        } else if (fieldName == sItem.Namespace__c + 'Enable_CCM__c') {
            if (licenseInfo.availableCCMLicenses <= 0) {
                throw new CopadoAPIException(ccmLicenseLimitReached);
            }
        } else if (fieldName == sItem.Namespace__c + 'Enable_Copado__c') {
            if (licenseInfo.availableCopadoLicenses <= 0) {
                throw new CopadoAPIException(copadoLicenseLimitReached);
            }
        } else if (fieldName == sItem.Namespace__c + 'Enable_CST__c') {
            if (licenseInfo.availableCSTLicenses <= 0) {
                throw new CopadoAPIException(cstLicenseLimitReached);
            }
        }
    }

    /**
     * Create or reset user API key for Copado API access
     * @return Strin apiKey
     */
    global String createUserAPIKey() {
        try {
            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            String requestedKey = DeployAPI.createAPIKeys();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(requestedKey);
            String raw_key = (String) responseMap.get('api_key');
            String encryptedKey = DeployAPI.encryptAPIKey(raw_key);
            ps.API_Key__c = encryptedKey;
            Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.SObjectType.Personal_Settings__c);
            return raw_key;
        } catch (Exception ex) {
            // Couldn't create the custom label for this since it will be patched.
            // It will be used by 3rd party so custom label is nice to have anyway
            return 'ERROR during api key registration. Error message:' + ex.getMessage();
        }
    }

    /**
     * Create sensitive information for git repository
     */
    global static void authenticateGitRepository(Id gitRepositoryId, String username, String password) {
        Sensitive_Information__c sensitiveInformationForGitRepository = Sensitive_Information__c.getValues(gitRepositoryId);

        if (null == sensitiveInformationForGitRepository) {
            sensitiveInformationForGitRepository = new Sensitive_Information__c();
            sensitiveInformationForGitRepository.Name = gitRepositoryId;
        }

        sensitiveInformationForGitRepository.Username__c = username;
        sensitiveInformationForGitRepository.Password__c = DeployAPI.encryptAPIKey(password);

        upsert sensitiveInformationForGitRepository;
    }
}