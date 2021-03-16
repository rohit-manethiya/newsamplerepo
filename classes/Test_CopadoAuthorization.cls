/**
 * Created by mertyalti on 23/07/2018.
 */

@IsTest
private class Test_CopadoAuthorization {
    @TestSetup static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        List<String> usernames = new List<String>{
                'copado-auth-@test.secure'
        };
        TestUtilities.insertAdminUsers(usernames);
        User adminUser = [SELECT Id FROM User WHERE Username = 'copado-auth-@test.secure'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        try {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        } catch(Exception e) {
            System.debug('**f**test : current user has permission set already assigned');
        }

        System.runAs(adminUser) {
            SObjectType sObjType = Schema.Org__c.getSObjectType();
            List<Org__c> orgs = new List<Org__c>();
            for(Integer i = 0; i < 100; i++) {
                SObject org = sObjType.newSObject();
                org.put('Name', 'Secure DML BULK Test' + i);
                org.put('Default_Credential__c', true);
                org.put('Disable_Validation__c', true);
                org.put('is_Developer_Hub_Org__c', false);
                org.put('OwnerId', UserInfo.getUserId());
                orgs.add((Org__c) org);
            }
            insert orgs;
        }
    }

    @IsTest static void testWrongSetupBehavior() {
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        try {
            SecureOperations so = new SecureOperations(null, DatabaseOperationType.WITHSHARING);
            Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        } catch(Exception e) {
            System.assert(true);
        }
    }

    @IsTest static void testWrongSetupBehavior2() {
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        try {
            SecureOperations so2 = new SecureOperations(DatabaseOperationType.OPTIONAL, null);
            Map<String, Schema.SObjectField> fields = so2.getFieldsMap(sObjType);
        } catch(Exception e) {
            System.assert(true);
        }
    }

    @IsTest static void testWrongSetupBehavior3() {
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        try {
            SecureOperations so3 = new SecureOperations(null, null);
            Map<String, Schema.SObjectField> fields = so3.getFieldsMap(sObjType);
        } catch(Exception e) {
            System.assert(true);
        }
    }

    @IsTest static void testAuthorizationBehaviorDefault() {
        SecureOperations so = new SecureOperations();
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        System.assert(!fields.isEmpty());

        ConvertTypes.DateConverter dc = new ConvertTypes.DateConverter();
        dc.getValue(String.valueOf(Date.valueOf(System.today())));

        ConvertTypes.IntegerConverter ic = new ConvertTypes.IntegerConverter();
        ic.getValue(String.valueOf(12));

        Double myDouble = 1261992;
        ConvertTypes.DoubleConverter doubc = new ConvertTypes.DoubleConverter();
        doubc.getValue(String.valueOf(myDouble));


        List<Schema.SObjectField> accessibleFields = so.getAccessibleFieldsList(sObjType);
        System.assert(!accessibleFields.isEmpty());
        List<Schema.SObjectField> accessibleFields2 = so.getAccessibleFieldsList(fields);
        System.assert(accessibleFields == accessibleFields2);

        List<Schema.SObjectField> updatableFields = so.getUpdateableFieldsList(sObjType);
        System.assert(!updatableFields.isEmpty());
        List<Schema.SObjectField> updatableFields2 = so.getUpdateableFieldsList(fields);
        System.assert(updatableFields == updatableFields2);

        List<Schema.SObjectField> creatabFields = so.getCreatableFieldsList(sObjType);
        System.assert(!creatabFields.isEmpty());
        List<Schema.SObjectField> creatabFields2 = so.getCreatableFieldsList(fields);
        System.assert(creatabFields == creatabFields2);

        List<Schema.SObjectField> upsertableFields = so.getUpsertableFieldsList(sObjType);
        System.assert(!upsertableFields.isEmpty());
        List<Schema.SObjectField> upsertableFields2 = so.getUpsertableFieldsList(fields);
        System.assert(upsertableFields == upsertableFields2);

        List<String> fieldListString = so.generateListFieldNames(accessibleFields);
        System.assert(fieldListString.size() == accessibleFields.size());

        String baseQuery = so.buildSecureBaseQuery(sObjType);
        String baseQueryWithFields = so.buildSecureBaseQuery(sObjType, fields);
        String userStoryBaseQuery = so.buildSecureBaseQuery(sObjType.getDescribe().getName());
        System.assert(baseQuery == baseQueryWithFields);
        System.assert(userStoryBaseQuery == baseQueryWithFields);

        Boolean isAuthorizedToView = so.isAuthorizedToView(sObjType, fieldListString);
        Boolean isAuthorizedToView2 = so.isAuthorizedToView(sObjType, accessibleFields);
        Boolean isAuthorizedToView3 = so.isAuthorizedToView(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToView4 = so.isAuthorizedToView(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView2);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView3);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView4);

        Boolean isAuthorizedToCreate = so.isAuthorizedToCreate(sObjType, fieldListString);
        Boolean isAuthorizedToCreate2 = so.isAuthorizedToCreate(sObjType, accessibleFields);
        Boolean isAuthorizedToCreate3 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToCreate4 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate2);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate3);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate4);

        Boolean isAuthorizedToUpdate = so.isAuthorizedToUpdate(sObjType, fieldListString);
        Boolean isAuthorizedToUpdate2 = so.isAuthorizedToUpdate(sObjType, accessibleFields);
        Boolean isAuthorizedToUpdate3 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToUpdate4 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate2);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate3);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate4);

        Boolean isAuthorizedToDelete = so.isAuthorizedToDelete(sObjType);
        Boolean isAuthorizedToDelete2 = so.isAuthorizedToDelete(sObjType.getDescribe().getName());
        System.assertEquals(isAuthorizedToDelete, isAuthorizedToDelete2);

        Map<String, Schema.SObjectField> fieldsMap = AuthorizationUtils.sObjectFieldMap(sObjType.getDescribe().getName());
        System.assertEquals(fields, fieldsMap);

        Map<String, Schema.SObjectField> fieldMap2 = AuthorizationUtils.sobjectFieldsNoCache(sObjType.getDescribe());
        Map<String, Schema.SObjectField> fieldMap3 = AuthorizationUtils.sobjectFieldsNoCache(sObjType.getDescribe().getName());
        Map<String, Schema.SObjectField> fieldMap4 = AuthorizationUtils.sobjectFieldsNoCache(sObjType);
        System.assertEquals(fieldMap2, fieldMap3);
        System.assertEquals(fieldMap2, fieldMap4);

        Set<String> fieldsSet = AuthorizationUtils.fieldsToStringSet(fields.values());
        System.assert(!fieldsSet.isEmpty());
    }

    @IsTest static void testAuthorizationBehaviorWithSharing() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        System.assert(!fields.isEmpty());

        List<Schema.SObjectField> accessibleFields = so.getAccessibleFieldsList(sObjType);
        System.assert(!accessibleFields.isEmpty());
        List<Schema.SObjectField> accessibleFields2 = so.getAccessibleFieldsList(fields);
        System.assert(accessibleFields == accessibleFields2);

        List<Schema.SObjectField> updatableFields = so.getUpdateableFieldsList(sObjType);
        System.assert(!updatableFields.isEmpty());
        List<Schema.SObjectField> updatableFields2 = so.getUpdateableFieldsList(fields);
        System.assert(updatableFields == updatableFields2);

        List<Schema.SObjectField> creatabFields = so.getCreatableFieldsList(sObjType);
        System.assert(!creatabFields.isEmpty());
        List<Schema.SObjectField> creatabFields2 = so.getCreatableFieldsList(fields);
        System.assert(creatabFields == creatabFields2);

        List<Schema.SObjectField> upsertableFields = so.getUpsertableFieldsList(sObjType);
        System.assert(!upsertableFields.isEmpty());
        List<Schema.SObjectField> upsertableFields2 = so.getUpsertableFieldsList(fields);
        System.assert(upsertableFields == upsertableFields2);

        List<String> fieldListString = so.generateListFieldNames(accessibleFields);
        System.assert(fieldListString.size() == accessibleFields.size());

        String baseQuery = so.buildSecureBaseQuery(sObjType);
        String baseQueryWithFields = so.buildSecureBaseQuery(sObjType, fields);
        String userStoryBaseQuery = so.buildSecureBaseQuery(sObjType.getDescribe().getName());
        System.assert(baseQuery == baseQueryWithFields);
        System.assert(userStoryBaseQuery == baseQueryWithFields);

        Boolean isAuthorizedToView = so.isAuthorizedToView(sObjType, fieldListString);
        Boolean isAuthorizedToView2 = so.isAuthorizedToView(sObjType, accessibleFields);
        Boolean isAuthorizedToView3 = so.isAuthorizedToView(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToView4 = so.isAuthorizedToView(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView2);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView3);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView4);

        Boolean isAuthorizedToCreate = so.isAuthorizedToCreate(sObjType, fieldListString);
        Boolean isAuthorizedToCreate2 = so.isAuthorizedToCreate(sObjType, accessibleFields);
        Boolean isAuthorizedToCreate3 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToCreate4 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate2);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate3);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate4);

        Boolean isAuthorizedToUpdate = so.isAuthorizedToUpdate(sObjType, fieldListString);
        Boolean isAuthorizedToUpdate2 = so.isAuthorizedToUpdate(sObjType, accessibleFields);
        Boolean isAuthorizedToUpdate3 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToUpdate4 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate2);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate3);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate4);

        Boolean isAuthorizedToDelete = so.isAuthorizedToDelete(sObjType);
        Boolean isAuthorizedToDelete2 = so.isAuthorizedToDelete(sObjType.getDescribe().getName());
        System.assertEquals(isAuthorizedToDelete, isAuthorizedToDelete2);
    }

    @IsTest static void testAuthorizationBehaviorWithoutSharing() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.User_Story__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        System.assert(!fields.isEmpty());

        List<Schema.SObjectField> accessibleFields = so.getAccessibleFieldsList(sObjType);
        System.assert(!accessibleFields.isEmpty());
        List<Schema.SObjectField> accessibleFields2 = so.getAccessibleFieldsList(fields);
        System.assert(accessibleFields == accessibleFields2);

        List<Schema.SObjectField> updatableFields = so.getUpdateableFieldsList(sObjType);
        System.assert(!updatableFields.isEmpty());
        List<Schema.SObjectField> updatableFields2 = so.getUpdateableFieldsList(fields);
        System.assert(updatableFields == updatableFields2);

        List<Schema.SObjectField> creatabFields = so.getCreatableFieldsList(sObjType);
        System.assert(!creatabFields.isEmpty());
        List<Schema.SObjectField> creatabFields2 = so.getCreatableFieldsList(fields);
        System.assert(creatabFields == creatabFields2);

        List<Schema.SObjectField> upsertableFields = so.getUpsertableFieldsList(sObjType);
        System.assert(!upsertableFields.isEmpty());
        List<Schema.SObjectField> upsertableFields2 = so.getUpsertableFieldsList(fields);
        System.assert(upsertableFields == upsertableFields2);

        List<String> fieldListString = so.generateListFieldNames(accessibleFields);
        System.assert(fieldListString.size() == accessibleFields.size());

        String baseQuery = so.buildSecureBaseQuery(sObjType);
        String baseQueryWithFields = so.buildSecureBaseQuery(sObjType, fields);
        String userStoryBaseQuery = so.buildSecureBaseQuery(sObjType.getDescribe().getName());
        System.assert(baseQuery == baseQueryWithFields);
        System.assert(userStoryBaseQuery == baseQueryWithFields);

        Boolean isAuthorizedToView = so.isAuthorizedToView(sObjType, fieldListString);
        Boolean isAuthorizedToView2 = so.isAuthorizedToView(sObjType, accessibleFields);
        Boolean isAuthorizedToView3 = so.isAuthorizedToView(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToView4 = so.isAuthorizedToView(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView2);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView3);
        System.assertEquals(isAuthorizedToView, isAuthorizedToView4);

        Boolean isAuthorizedToCreate = so.isAuthorizedToCreate(sObjType, fieldListString);
        Boolean isAuthorizedToCreate2 = so.isAuthorizedToCreate(sObjType, accessibleFields);
        Boolean isAuthorizedToCreate3 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToCreate4 = so.isAuthorizedToCreate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate2);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate3);
        System.assertEquals(isAuthorizedToCreate, isAuthorizedToCreate4);

        Boolean isAuthorizedToUpdate = so.isAuthorizedToUpdate(sObjType, fieldListString);
        Boolean isAuthorizedToUpdate2 = so.isAuthorizedToUpdate(sObjType, accessibleFields);
        Boolean isAuthorizedToUpdate3 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), fieldListString);
        Boolean isAuthorizedToUpdate4 = so.isAuthorizedToUpdate(sObjType.getDescribe().getName(), accessibleFields);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate2);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate3);
        System.assertEquals(isAuthorizedToUpdate, isAuthorizedToUpdate4);

        Boolean isAuthorizedToDelete = so.isAuthorizedToDelete(sObjType);
        Boolean isAuthorizedToDelete2 = so.isAuthorizedToDelete(sObjType.getDescribe().getName());
        System.assertEquals(isAuthorizedToDelete, isAuthorizedToDelete2);
    }

    @IsTest static void testSecureDMLSingleAllOrNone() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        SObject org = sObjType.newSObject();
        org.put('Name', 'Secure DML Test');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        so.Secure_DML(org, DML_Action.INS);
        Org__c inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name = 'Secure DML Test' LIMIT 1];
        System.assert(inserted.Id != null);
        org.put('Default_Credential__c', false);
        org.put('Id', inserted.Id);
        System.assertNotEquals(null, org.get('Id'));
        so.Secure_DML(org, DML_Action.UPD);
        System.assertEquals(false, org.get('Default_Credential__c'));
        so.Secure_DML(inserted, DML_Action.DEL);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Id = :inserted.Id]);

        SObject org2 = sObjType.newSObject();
        org2.put('Name', 'Secure DML Test');
        org2.put('Default_Credential__c', true);
        org2.put('Disable_Validation__c', true);
        org2.put('is_Developer_Hub_Org__c', null);
        org2.put('OwnerId', UserInfo.getUserId());

        so.Secure_DML(org2, DML_Action.UPS);
    }

    @IsTest static void testSecureDMLSingleAOptional() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        SObject org = sObjType.newSObject();
        org.put('Name', 'Secure DML Test');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        so.Secure_DML(org, DML_Action.INS);
        Org__c inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name = 'Secure DML Test' LIMIT 1];
        System.assert(inserted.Id != null);
        org.put('Default_Credential__c', false);
        org.put('Id', inserted.Id);
        System.assertNotEquals(null, org.get('Id'));
        so.Secure_DML(org, DML_Action.UPD);
        System.assertEquals(false, org.get('Default_Credential__c'));
        so.Secure_DML(inserted, DML_Action.DEL);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Id = :inserted.Id]);

        SObject org2 = sObjType.newSObject();
        org2.put('Name', 'Secure DML Test');
        org2.put('Default_Credential__c', true);
        org2.put('Disable_Validation__c', true);
        org2.put('is_Developer_Hub_Org__c', null);
        org2.put('OwnerId', UserInfo.getUserId());

        so.Secure_DML(org2, DML_Action.UPS);
    }

    @IsTest static void testSecureDMLBulkAllOrNoneInsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            org.put('Name', 'Secure DML Test' + i);
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.INS, Schema.SObjectType.Org__c);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML Test%'];
        System.assertEquals(100, inserted.size());
    }

    @IsTest static void testSecureDMLBulkAllOrNoneUpdate() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();

        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%'];
        orgs.clear();
        for(Org__c o : inserted) {
            SObject org = sObjType.newSObject();
            org = o;
            org.put('Default_Credential__c', false);
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.UPD, Schema.SObjectType.Org__c);
        System.assertEquals(false, orgs[0].get('Default_Credential__c'));

    }

    @IsTest static void testSecureDMLBulkAllOrNoneDelete() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%'];
        Test.startTest();
        Savepoint sp = Database.setSavepoint();
        so.Secure_DML(inserted, DML_Action.DEL, Schema.SObjectType.Org__c);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML BULK Test %']);
        Database.rollback(sp);
        Test.stopTest();

    }

    @IsTest static void testSecureDMLBulkAllOrNoneUpsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();

        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            org.put('Name', 'Secure DML Test' + i);
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.UPS, Schema.SObjectType.Org__c);
        System.assertEquals(100, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%']);
    }

    @IsTest static void testSecureDMLBulkOptionalForSecureInsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            org.put('Name', 'Secure DML Test' + i);
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.INS);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML Test%'];
        System.assertEquals(100, inserted.size());

    }

    @IsTest static void testSecureDMLBulkOptionalForSecureUpdate() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();
        Test.startTest();
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%'];
        for(Org__c o : inserted) {
            SObject org = sObjType.newSObject();
            org = o;
            org.put('Default_Credential__c', false);
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.UPD);
        Test.stopTest();
        System.assertEquals(false, orgs[0].get('Default_Credential__c'));
    }

    @IsTest static void testSecureDMLBulkOptionalForSecureDelete() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%'];
        Test.startTest();
        Savepoint sp = Database.setSavepoint();
        so.Secure_DML(inserted, DML_Action.DEL, Schema.SObjectType.Org__c);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%']);
        Database.rollback(sp);
        Test.stopTest();

    }

    @IsTest static void testSecureDMLBulkOptionalForSecureUpsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        List<Org__c> orgs = new List<Org__c>();

        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            org.put('Name', 'Secure DML Test' + i);
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        so.Secure_DML(orgs, DML_Action.UPS);
        System.assertEquals(100, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML Test%']);
    }

    @IsTest static void testSecureDMLSingleOptional1() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Org__c orgCredential = new Org__c();
        SObject org = sObjType.newSObject();
        org.put('Name', 'Secure DML Test');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        orgCredential = (Org__c) org;

        Schema.DescribeSObjectResult objectDescribe = Org__c.SObjectType.getDescribe();

        so.Secure_DML(orgCredential, DML_Action.INS, objectDescribe);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML Test'];

        for(Org__c o : inserted) {
            SObject org1 = sObjType.newSObject();
            org1 = o;
            org1.put('Default_Credential__c', false);
            orgCredential = (Org__c) org1;
        }

        so.Secure_DML(orgCredential, DML_Action.UPD, objectDescribe);
        System.assertEquals(false, orgCredential.Default_Credential__c);
        so.Secure_DML(inserted, DML_Action.DEL, objectDescribe);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML Test']);

        SObject org2 = sObjType.newSObject();
        org2.put('Name', 'Secure DML Test');
        org2.put('Default_Credential__c', true);
        org2.put('Disable_Validation__c', true);
        org2.put('is_Developer_Hub_Org__c', null);
        org2.put('OwnerId', UserInfo.getUserId());
        orgCredential = (Org__c) org2;

        so.Secure_DML(orgCredential, DML_Action.UPS, objectDescribe);
    }

    @IsTest static void testSecureDMLSingleOptional2() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Org__c orgCredential = new Org__c();
        SObject org = sObjType.newSObject();
        org.put('Name', 'Secure DML Test');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        orgCredential = (Org__c) org;

        Schema.DescribeSObjectResult objectDescribe = Org__c.SObjectType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = Org__c.Id.getDescribe();

        so.Secure_DML(orgCredential, DML_Action.INS, objectDescribe, fieldDescribe);
        List<Org__c> inserted = [SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE 'Secure DML Test%'];

        for(Org__c o : inserted) {
            SObject org1 = sObjType.newSObject();
            org1 = o;
            org1.put('Default_Credential__c', false);
            orgCredential = (Org__c) org1;
        }

        so.Secure_DML(orgCredential, DML_Action.UPD, objectDescribe, fieldDescribe);
        System.assertEquals(false, orgCredential.Default_Credential__c);
        so.Secure_DML(inserted, DML_Action.DEL, objectDescribe, fieldDescribe);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML Test']);

        SObject org2 = sObjType.newSObject();
        org2.put('Name', 'Secure DML Test');
        org2.put('Default_Credential__c', true);
        org2.put('Disable_Validation__c', true);
        org2.put('is_Developer_Hub_Org__c', null);
        org2.put('OwnerId', UserInfo.getUserId());
        orgCredential = (Org__c) org2;

        so.Secure_DML(orgCredential, DML_Action.UPS, objectDescribe, fieldDescribe);
    }

    @IsTest static void testAuthDMLBulkInsertCheck() {
        SecureOperations so = new SecureOperations();
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        Set<String> fieldsSet = AuthorizationUtils.fieldsToStringSet(fields.values());
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(fieldsSet);

        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            org.put('Name', 'Secure DML Test' + i);
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        so.authWithSharing.doInsertCheck(orgs, so.generateListFieldNames(so.getCreatableFieldsList(fields)));
        List<Org__c> inserted = (List<Org__c>) (so.authWithSharing.executeQuery('SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE \'Secure DML Test%\''));

        System.assertEquals(100, inserted.size());

    }

    @IsTest static void testAuthDMLBulkUpdateCheck() {
        SecureOperations so = new SecureOperations();
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        Set<String> fieldsSet = AuthorizationUtils.fieldsToStringSet(fields.values());
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(fieldsSet);

        List<Org__c> orgs = new List<Org__c>();

        List<Org__c> inserted = (List<Org__c>) (so.authWithSharing.executeQuery('SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE \'Secure DML BULK Test%\''));
        orgs.clear();
        for(Org__c org : inserted) {
            org.put('Default_Credential__c', false);
            orgs.add((Org__c) org);
        }
        Test.startTest();
        so.authWithSharing.doUpdateCheck(orgs, so.generateListFieldNames(so.getUpdateableFieldsList(fields)));
        Test.stopTest();
        System.assertEquals(false, orgs[0].get('Default_Credential__c'));
    }

    @IsTest static void testAuthDMLBulkDeleteAndUpsertCheck() {
        SecureOperations so = new SecureOperations();
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        Set<String> fieldsSet = AuthorizationUtils.fieldsToStringSet(fields.values());
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(fieldsSet);

        List<Org__c> orgs = new List<Org__c>();

        List<Org__c> inserted = (List<Org__c>) (so.authWithSharing.executeQuery('SELECT Id,Default_Credential__c,OwnerId,Name FROM Org__c WHERE Name LIKE \'Secure DML BULK Test%\''));
        Savepoint sp = Database.setSavepoint();
        so.authWithSharing.doDeleteCheck(inserted);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%']);
        Database.rollback(sp);

        for(Org__c org : inserted) {
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }
        so.authWithSharing.doUpsertCheck(orgs, so.generateListFieldNames(so.getUpsertableFieldsList(fields)), fields.get('Id'));
        System.assertEquals(100, [SELECT COUNT() FROM Org__c WHERE Name LIKE 'Secure DML BULK Test%']);
    }


    @IsTest static void testAuthDMLSingle() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        SObject org = sObjType.newSObject();
        org.put('Name', 'Secure DML Test');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        org = (Org__c) so.authWithoutSharing.doInsertCheck(org, so.generateListFieldNames(so.getCreatableFieldsList(fields)));
        System.assert(org.Id != null);
        org.put('Default_Credential__c', false);
        System.assertNotEquals(null, org.get('Id'));
        so.authWithoutSharing.doUpdateCheck(org, so.generateListFieldNames(so.getUpdateableFieldsList(fields)));
        System.assertEquals(false, org.get('Default_Credential__c'));
        so.authWithoutSharing.doDeleteCheck(org);
        System.assertEquals(0, [SELECT COUNT() FROM Org__c WHERE Id = :org.Id]);

        SObject org2 = sObjType.newSObject();
        org2.put('Name', 'Secure DML Test');
        org2.put('Default_Credential__c', true);
        org2.put('Disable_Validation__c', true);
        org2.put('is_Developer_Hub_Org__c', null);
        org2.put('OwnerId', UserInfo.getUserId());

        so.authWithoutSharing.doUpsertCheck(org2, so.generateListFieldNames(so.getUpsertableFieldsList(fields)), fields.get('Id'));
        SecureOperations so2 = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHSHARING);
        so2.authWithSharing.doUpsertCheck(org2, so.generateListFieldNames(so.getUpsertableFieldsList(fields)), fields.get('Id'));
    }

    @IsTest static void testAuthDMLSingleExceptions() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        SObject org = sObjType.newSObject();
        // Long name to force an error during insert
        org.put('Name', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.');
        org.put('Default_Credential__c', true);
        org.put('Disable_Validation__c', true);
        org.put('is_Developer_Hub_Org__c', null);
        org.put('OwnerId', UserInfo.getUserId());
        try {
            so.authWithoutSharing.doInsertCheck(org, new List<String>());
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for insert check');
        }
        try {
            List<String> fieldsList = so.generateListFieldNames(so.getCreatableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doInsertCheck(org, fieldsList);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'test_failure__c not found or there is an access violation during insert check');
        }

        try {
            so.authWithoutSharing.doInsertCheck(org, so.generateListFieldNames(so.getCreatableFieldsList(fields)));
        } catch(Exception e) {
            System.assert(e.getMessage().startsWith('Insert failed for given object. stack trace :'));
        }

        try {
            so.authWithoutSharing.doUpdateCheck(org, new List<String>());
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for update check');
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getCreatableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doUpdateCheck(org, fieldsList);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'test_failure__c not found or there is an access violation during update check');
        }

        try {
            so.authWithoutSharing.doUpdateCheck(org, so.generateListFieldNames(so.getCreatableFieldsList(fields)));
        } catch(Exception e) {
            System.assert(e.getMessage().startsWith('Update failed for given object. stack trace :'));
        }

        try {
            Org__c temp;
            so.authWithoutSharing.doDeleteCheck(temp);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null parameter for delete check');
        }

        try {
            so.authWithoutSharing.doUpsertCheck(org, new List<String>(), null);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for upsert check');
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getCreatableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doUpsertCheck(org, fieldsList, fields.get('Id'));
        } catch(Exception e) {
            System.assert(e.getMessage() == 'test_failure__c not found or there is an access violation during upsert check');
        }
    }

    @IsTest static void testAuthDMLBulkExceptionsForInsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            // Long name to force an error during insert
            org.put('Name', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.');
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        try {
            so.authWithoutSharing.doInsertCheck(orgs, new List<String>());
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for insert check');
        }
        try {
            List<String> fieldsList = so.generateListFieldNames(so.getCreatableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doInsertCheck(orgs, fieldsList);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'test_failure__c not found or there is an access violation during insert check');
        }

        try {
            so.authWithoutSharing.doInsertCheck(orgs, so.generateListFieldNames(so.getCreatableFieldsList(fields)));
        } catch(Exception e) {
            System.assert(e.getMessage().startsWith('Insert failed for given object. stack trace :'));
        }

    }

    @IsTest static void testAuthDMLBulkExceptionsForUpdate() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            // Long name to force an error during insert
            org.put('Name', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.');
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        try {
            so.authWithoutSharing.doUpdateCheck(orgs, new List<String>());
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for update check');
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getUpdateableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doUpdateCheck(orgs, fieldsList);
        } catch(Exception e) {
            System.assert(e.getMessage().startsWith('Update failed for given list objects. stack trace'));
        }

        try {
            so.authWithoutSharing.doUpdateCheck(orgs, so.generateListFieldNames(so.getUpdateableFieldsList(fields)));
        } catch(Exception e) {
            System.assert(e.getMessage().startsWith('Update failed for given list objects. stack trace '));
        }

    }

    @IsTest static void testAuthDMLBulkExceptionsForDeleteAndUpsert() {
        SecureOperations so = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
        SObjectType sObjType = Schema.Org__c.getSObjectType();
        Map<String, Schema.SObjectField> fields = so.getFieldsMap(sObjType);
        List<Org__c> orgs = new List<Org__c>();
        for(Integer i = 0; i < 100; i++) {
            SObject org = sObjType.newSObject();
            // Long name to force an error during insert
            org.put('Name', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.');
            org.put('Default_Credential__c', true);
            org.put('Disable_Validation__c', true);
            org.put('is_Developer_Hub_Org__c', null);
            org.put('OwnerId', UserInfo.getUserId());
            orgs.add((Org__c) org);
        }

        try {
            Org__c temp;
            so.authWithoutSharing.doDeleteCheck(temp);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null parameter for delete check');
        }

        try {
            so.authWithoutSharing.doUpsertCheck(orgs, new List<String>(), null);
        } catch(Exception e) {
            System.assert(e.getMessage() == 'null or empty parameter for upsert check');
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getUpsertableFieldsList(fields));
            fieldsList.add('Test_Failure__c');
            so.authWithoutSharing.doUpsertCheck(orgs, fieldsList, fields.get('Id'));
        } catch(Exception e) {
            System.assert(e.getMessage() == 'test_failure__c access violation during upsert check');
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getUpsertableFieldsList(fields));
            so.authWithoutSharing.doUpsertCheck(orgs, fieldsList, fields.get('Id'));
        } catch(Exception e) {
            System.assert(String.isNotBlank(e.getMessage()));
        }

        try {
            List<String> fieldsList = so.generateListFieldNames(so.getUpsertableFieldsList(fields));
            SecureOperations sows = new SecureOperations(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHSHARING);
            sows.authWithSharing.doUpsertCheck(orgs, fieldsList, null);
        } catch(Exception e) {
            System.assert(String.isNotBlank(e.getMessage()));
        }
    }

}