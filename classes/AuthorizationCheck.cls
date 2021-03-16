/**
 * @author Mert YALTI
 * @description TODO
 * @since
 * @version 1.0
 * @{code : }
 */
public abstract class AuthorizationCheck implements IAuthorization {

    private DatabaseOperationType dbType;
    private DatabaseOperationType shType;
    public Boolean allOrNone;

    private String SOQL_SHAPE = 'SELECT {0} FROM {1}';

    public abstract List<SObject> executeQuery(String queryString);

    public abstract void databaseInsert(sObject sObj);
    public abstract void databaseUpdate(sObject obj);
    public abstract void databaseDelete(sObject obj);
    public abstract void databaseUpsert(sObject obj, Schema.SObjectField externalId);

    public abstract Database.SaveResult[] databaseInsert(sObject [] sObj, Boolean allOrNone);
    public abstract Database.SaveResult[] databaseUpdate(sObject [] sObj, Boolean allOrNone);
    public abstract Database.DeleteResult[] databaseDelete(sObject [] sObj, Boolean allOrNone);
    public abstract Database.UpsertResult[] databaseUpsert(sObject [] sObj, Boolean allOrNone, Schema.SObjectField externalId);

    public void setupOperation(DatabaseOperationType dbType, DatabaseOperationType shType) {
        if(dbType == null)
            throw new AuthorizationException('DatabaseOperationType must not be null');

        if(dbType == DatabaseOperationType.ALL_OR_NONE || dbType == DatabaseOperationType.OPTIONAL) {
            this.dbType = dbType;
        } else {
            throw new AuthorizationException('Invalid value for DatabaseOperationType');
        }

        allOrNone = this.dbType == DatabaseOperationType.ALL_OR_NONE ? true : false;

        if(shType == null)
            throw new AuthorizationException('DatabaseOperationType for sharing must not be null');

        if(shType == DatabaseOperationType.WITHSHARING || shType == DatabaseOperationType.WITHOUTSHARING) {
            this.shType = shType;
        } else {
            throw new AuthorizationException('Invalid sharing value for DatabaseOperationType');
        }
    }

    public Map<String, Schema.SObjectField> getFieldsMap(SObjectType sObjType) {
        return AuthorizationUtils.sObjectFieldMap(sObjType);
    }

    ///////////////////////// VIEWABLE FIELDS //////////////////////

    public List<Schema.SObjectField> getAccessibleFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        List<Schema.SObjectField> listFields = new List<Schema.SObjectField>{
        };
        for(String f : fieldsMap.keySet()) {
            if(fieldsMap.get(f).getDescribe().isAccessible()) {
                listFields.add(fieldsMap.get(f));
            }
        }
        return listFields;
    }

    public List<Schema.SObjectField> getAccessibleFieldsList(SObjectType sObjectType) {
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(sObjectType);
        return getAccessibleFieldsList(fieldsMap);
    }

    ///////////////////////// UPDATEABLE FIELDS //////////////////////

    public List<Schema.SObjectField> getUpdateableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
        };
        for(String key : fieldsMap.keySet()) {
            if(key == 'Id' || fieldsMap.get(key).getDescribe().isUpdateable()) {
                fields.add(fieldsMap.get(key));
            }
        }
        return fields;
    }

    public List<Schema.SObjectField> getUpdateableFieldsList(SObjectType sObjectType) {
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(sObjectType);
        return getUpdateableFieldsList(fieldsMap);
    }

    ///////////////////////// CREATEABLE FIELDS //////////////////////

    public List<Schema.SObjectField> getCreatableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
        };
        for(String key : fieldsMap.keySet()) {
            if(fieldsMap.get(key).getDescribe().isCreateable()) {
                fields.add(fieldsMap.get(key));
            }
        }
        return fields;
    }

    public List<Schema.SObjectField> getCreatableFieldsList(SObjectType sObjectType) {
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(sObjectType);
        return getCreatableFieldsList(fieldsMap);
    }

    ///////////////////////// UPSERTABLE FIELDS //////////////////////

    public List<Schema.SObjectField> getUpsertableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
        };
        for(String key : fieldsMap.keySet()) {
            if(fieldsMap.get(key).getDescribe().isCreateable() && fieldsMap.get(key).getDescribe().isUpdateable()) {
                fields.add(fieldsMap.get(key));
            }
        }
        return fields;
    }

    public List<Schema.SObjectField> getUpsertableFieldsList(SObjectType sObjectType) {
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(sObjectType);
        return getUpsertableFieldsList(fieldsMap);
    }

    public List<String> generateListFieldNames(List<Schema.SObjectField> fields) {
        List<String> fieldNames = new List<String>{
        };
        for(Schema.SObjectField f : fields) {
            fieldNames.add(f.getDescribe().getName().toLowerCase());
        }
        return fieldNames;
    }
    //To avoid XSS, make sure to escape text before presenting it to the user.
    public String buildSecureBaseQuery(SObjectType sObjectType) {
        Schema.DescribeSObjectResult sObjdesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!sObjdesc.isQueryable()) throw new AuthorizationException(sObjdesc.getName() + ' is not queryable!');

        List<String> accessibleFields = generateListFieldNames(getAccessibleFieldsList(sObjectType));
        System.debug(LoggingLevel.INFO, 'Note : to avoid XSS, make sure to escape text before presenting it to the user.');
        return String.format(SOQL_SHAPE, new String[]{
                String.join(accessibleFields, ' ,'), sObjdesc.getName()
        });
    }

    public String buildSecureBaseQuery(SObjectType sObjectType, Map<String, Schema.SObjectField> fieldsMap) {
        Schema.DescribeSObjectResult sObjdesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!sObjdesc.isQueryable()) throw new AuthorizationException(sObjdesc.getName() + ' is not queryable!');

        List<String> accessibleFields = generateListFieldNames(getAccessibleFieldsList(fieldsMap));
        System.debug(LoggingLevel.INFO, 'Note : to avoid XSS, make sure to escape text before presenting it to the user.');
        return String.format(SOQL_SHAPE, new String[]{
                String.join(accessibleFields, ' ,'), sObjdesc.getName()
        });
    }

    public String buildSecureBaseQuery(String sObjectName) {
        return buildSecureBaseQuery(AuthorizationUtils.sobjectType(sObjectName));
    }

    public Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields) {
        if(!sObjectType.getDescribe().isAccessible()) {
            return false;
        }

        for(Schema.SObjectField f : listFields) {

            if(!f.getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!objDesc.isAccessible()) {
            return false;
        }
        Map<String, Schema.SObjectField> fMap = AuthorizationUtils.sObjectFieldMap(sObjectType);
        for(String f : fieldNames) {

            Schema.SObjectField sObjectFld = fMap.get(f);
            if(sObjectFld == null) {
                throw new AuthorizationException('Invalid field: :' + f + '. Field not found in ' + objDesc.getName() + '!!');
            }
            if(!sObjectFld.getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToView(String sObjectName, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToView(objDesc.getSObjectType(), fieldNames);
    }

    public Boolean isAuthorizedToView(String sObjectName, List<Schema.SObjectField> listFields) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToView(objDesc.getSObjectType(), listFields);
    }

    public Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!objDesc.isUpdateable()) {
            return false;
        }

        for(Schema.SObjectField f : listFields) {
            if(!f.getDescribe().isUpdateable()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!objDesc.isUpdateable()) {
            return false;
        }
        Map<String, Schema.SObjectField> fMap = AuthorizationUtils.sObjectFieldMap(sObjectType);
        for(String f : fieldNames) {
            Schema.SObjectField sObjectFld = fMap.get(f);
            if(sObjectFld == null) {
                throw new AuthorizationException('Invalid field: :' + f + '. Field not found in ' + objDesc.getName() + '!!');
            }
            if(!sObjectFld.getDescribe().isUpdateable()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToUpdate(String sObjectName, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToUpdate(objDesc.getSObjectType(), fieldNames);
    }

    public Boolean isAuthorizedToUpdate(String sObjectName, List<Schema.SObjectField> listFields) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToUpdate(objDesc.getSObjectType(), listFields);
    }

    public Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!objDesc.isCreateable()) {
            return false;
        }
        Map<String, Schema.SObjectField> fMap = AuthorizationUtils.sObjectFieldMap(sObjectType);
        for(String f : fieldNames) {
            Schema.SObjectField sObjectFld = fMap.get(f);
            if(sObjectFld == null) {
                throw new AuthorizationException('Invalid field: :' + f + '. Field not found in ' + objDesc.getName() + '!!');
            }
            if(!sObjectFld.getDescribe().isCreateable()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<Schema.SObjectField> fields) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        if(!objDesc.isCreateable()) {
            return false;
        }

        for(Schema.SObjectField f : fields) {
            if(!f.getDescribe().isCreateable()) {
                return false;
            }
        }
        return true;
    }

    public Boolean isAuthorizedToCreate(String sObjectName, List<String> fieldNames) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToCreate(objDesc.getSObjectType(), fieldNames);
    }

    public Boolean isAuthorizedToCreate(String sObjectName, List<Schema.SObjectField> listFields) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToCreate(objDesc.getSObjectType(), listFields);
    }

    public Boolean isAuthorizedToDelete(Schema.SObjectType sObjectType) {
        return sObjectType.getDescribe().isDeletable();
    }

    public Boolean isAuthorizedToDelete(String sObjectName) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectName);
        return isAuthorizedToDelete(objDesc.getSObjectType());
    }

    public Boolean isAuthorizedToQuery(Schema.SObjectType sObjectType) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        return !objDesc.isQueryable() ? false : true;
    }

    public Boolean isAuthorizedToQuery(String sObjectType) {
        Schema.DescribeSObjectResult objDesc = AuthorizationUtils.sobjectDescribe(sObjectType);
        return !objDesc.isQueryable() ? false : true;
    }

    public sObject doInsertCheck(SObject sObj, List<String> fieldNames) {
        if(sObj == null || fieldNames.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for insert check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(!d.isCreateable()) {
            throw new AuthorizationException(d.getName() + ' is not creatable. Check your OLS setup for create access.');
        }
        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObj.getSObjectType()); // potentially saves a fields call below
        List<String> creatableFieldsList = generateListFieldNames(getCreatableFieldsList(fieldMap));

        sObject emptyObjectInstance = sObj.getSObjectType().newSObject();

        for(String fieldName : fieldNames) {
            fieldName = fieldName.toLowerCase();
            if(creatableFieldsList.isEmpty() || creatableFieldsList.contains(fieldName) == false) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(fieldName + ' not found or there is an access violation during insert check');
                }
            } else {
                if(String.isBlank(String.valueOf(sObj.get(fieldName))) && !fieldMap.get(fieldName).getDescribe().isNillable()) {
                    continue;
                }
                ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(emptyObjectInstance, ((Blob)sObj.get(fieldName)).toString());
                } else {
                    ct.putTo(emptyObjectInstance, String.valueOf(sObj.get(fieldName)));
                }
            }
        }

        try {
            databaseInsert(emptyObjectInstance);
        } catch(Exception e) {
            throw new AuthorizationException('Insert failed for given object. stack trace :' + e.getStackTraceString() + ' message: ' + e.getMessage());
        }
        return emptyObjectInstance;
    }

    public sObject doInsertCheck(SObject sObj, List<Schema.SObjectField> fieldsList) {
        if(sObj == null || fieldsList.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for insert check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(!d.isCreateable()) {
            throw new AuthorizationException(d.getName() + ' is not creatable. Check your OLS setup for create access.');
        }
        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObj.getSObjectType()); // potentially saves a fields call below

        sObject emptyObjectInstance = sObj.getSObjectType().newSObject();

        for(Schema.SObjectField field : fieldsList) {
            if(field.getDescribe().isCreateable() == false) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(field.getDescribe().getName() + ' access violation during insert check');
                }
            } else {
                if(String.isBlank(String.valueOf(sObj.get(field))) & !field.getDescribe().isNillable()) {
                    continue;
                }
                ConvertTypes ct = new ConvertTypes(field);
                if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(emptyObjectInstance, ((Blob)sObj.get(field)).toString());
                } else {
                    ct.putTo(emptyObjectInstance, String.valueOf(sObj.get(field)));
                }
            }
        }

        try {
            databaseInsert(emptyObjectInstance);
        } catch(Exception e) {
            throw new AuthorizationException('Insert failed for given object. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }
        return emptyObjectInstance;
    }

    public sObject [] doInsertCheck(SObject [] sObjectList, List<Schema.SObjectField> fieldNames) {
        if(sObjectList.isEmpty() || fieldNames.isEmpty())
            throw new AuthorizationException('null or empty parameter for insert check');

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isCreateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not creatable. Check your OLS setup for create access.');
        }

        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();

            for(Schema.SObjectField field : fieldNames) {
                if(field.getDescribe().isCreateable() == false) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(field.getDescribe().getName() + ' access violation during insert check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(devObj.get(field))) & !field.getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(field);
                    if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(field)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(field)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.SaveResult [] results = null;
        try {
            results = databaseInsert(clearList, dbType == DatabaseOperationType.ALL_OR_NONE);
        } catch(Exception e) {
            throw new AuthorizationException('Insert failed for given object. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }

        return clearList;
    }

    public sObject [] doInsertCheck(SObject [] sObjectList, List<String> fieldNames) {
        if(sObjectList.isEmpty() || fieldNames.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for insert check');
        }

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isCreateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not creatable. Check your OLS setup for create access.');
        }

        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObjectList.getSObjectType()); // potentially saves a fields call below
        List<String> creatableFieldsList = generateListFieldNames(getCreatableFieldsList(fieldMap));
        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();

            for(String fieldName : fieldNames) {
                if(creatableFieldsList.isEmpty() || creatableFieldsList.contains(fieldName) == false) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(fieldName + ' not found or there is an access violation during insert check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(devObj.get(fieldName))) & !fieldMap.get(fieldName).getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                    if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(fieldName)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(fieldName)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.SaveResult [] results = null;
        try {
            results = databaseInsert(clearList, dbType == DatabaseOperationType.ALL_OR_NONE);
        } catch(Exception e) {
            throw new AuthorizationException('Insert failed for given object. stack trace :' + e.getStackTraceString());
        }
        return clearList;
    }

    public sObject doUpdateCheck(SObject sObj, List<Schema.SObjectField> fieldsList) {
        if(sObj == null || fieldsList == null || fieldsList.size() == 0) {
            throw new AuthorizationException('Null or empty parameter for update check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not updateable. Check your OLS setup for update access.');
        }

        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObj.getSObjectType()); // potentially saves a fields call below
        List<String> updateableFieldsList = generateListFieldNames(getUpdateableFieldsList(fieldMap));

        sObject emptyObjectInstance = sObj.getSObjectType().newSObject();

        for(Schema.SObjectField field : fieldsList) {
            if(field.getDescribe().isUpdateable() == false && field.getDescribe().isCustom()) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(field.getDescribe().getName() + ' access violation during update check');
                }
            } else {
                if(String.isBlank(String.valueOf(sObj.get(field))) & !field.getDescribe().isNillable()) {
                    continue;
                }
                ConvertTypes ct = new ConvertTypes(field);
                if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(emptyObjectInstance, ((Blob)sObj.get(field)).toString());
                } else {
                    ct.putTo(emptyObjectInstance, String.valueOf(sObj.get(field)));
                }
            }
        }

        try {
            databaseUpdate(emptyObjectInstance);
        } catch(Exception e) {
            throw new AuthorizationException('Update failed for given object. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }
        return emptyObjectInstance;
    }

    public sObject doUpdateCheck(SObject sObj, List<String> fieldsList) {
        if(sObj == null || fieldsList == null || fieldsList.size() == 0) {
            throw new AuthorizationException('Null or empty parameter for update check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not updateable. Check your OLS setup for update access.');
        }

        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObj.getSObjectType()); // potentially saves a fields call below
        List<String> updateableFieldsList = generateListFieldNames(getUpdateableFieldsList(fieldMap));

        sObject emptyObjectInstance = sObj.getSObjectType().newSObject();
        for(String fieldName : fieldsList) {
            fieldName = fieldName.toLowerCase();
            if(updateableFieldsList.isEmpty() || updateableFieldsList.contains(fieldName) == false) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(fieldName + ' not found or there is an access violation during update check');
                }
            } else {
                if(String.isBlank(String.valueOf(sObj.get(fieldName))) & !fieldMap.get(fieldName).getDescribe().isNillable()) {
                    continue;
                }

                ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(emptyObjectInstance, ((Blob)sObj.get(fieldName)).toString());
                } else {
                    ct.putTo(emptyObjectInstance, String.valueOf(sObj.get(fieldName)));
                }
            }
        }

        try {
            databaseUpdate(emptyObjectInstance);
        } catch(Exception e) {
            throw new AuthorizationException('Update failed for given object. stack trace :' + e.getStackTraceString());
        }
        return emptyObjectInstance;
    }

    public sObject[] doUpdateCheck(SObject [] sObjectList, List<Schema.SObjectField> fieldsList) {
        if(sObjectList.isEmpty() || fieldsList.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for update check');
        }

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not updateable. Check your OLS setup for update access.');
        }

        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();
            cleansObj.Id = devObj.Id;
            for(Schema.SObjectField field : fieldsList) {
                if(field.getDescribe().isUpdateable() == false && field.getDescribe().isCustom()) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(field.getDescribe().getName() + ' access violation during update check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(cleansObj.get(field))) & !field.getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(field);
                    if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(field)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(field)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.SaveResult [] results = null;
        try {
            results = databaseUpdate(clearList, dbType == DatabaseOperationType.ALL_OR_NONE);
        } catch(Exception e) {
            throw new AuthorizationException('Update failed for given list objects. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }

        return clearList;
    }

    public sObject[] doUpdateCheck(SObject [] sObjectList, List<String> fieldNames) {
        if(sObjectList.isEmpty() || fieldNames.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for update check');
        }

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not updateable. Check your OLS setup for update access.');
        }

        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObjectList.getSObjectType()); // potentially saves a fields call below
        List<String> updateableFieldsList = generateListFieldNames(getUpdateableFieldsList(fieldMap));

        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();
            cleansObj.Id = devObj.Id;
            for(String fieldName : updateableFieldsList) {
                fieldName = fieldName.toLowerCase();
                if(updateableFieldsList.isEmpty() || updateableFieldsList.contains(fieldName) == false) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(fieldName + ' access violation during update check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(cleansObj.get(fieldName))) & !fieldMap.get(fieldName).getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                    if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(fieldName)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(fieldName)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.SaveResult [] results = null;
        try {
            results = databaseUpdate(clearList, dbType == DatabaseOperationType.ALL_OR_NONE);
        } catch(Exception e) {
            throw new AuthorizationException('Update failed for given list objects. stack trace :' + e.getStackTraceString());
        }

        return clearList;
    }

    public void doDeleteCheck(SObject sObj) {
        if(sObj == null) {
            throw new AuthorizationException('null parameter for delete check');
        }
        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();

        if(!d.isDeletable()) {
            throw new AuthorizationException(d.getName() + ' is not deletable. Check your OLS setup for delete access.');
        }

        try {
            databaseDelete(sObj);
        } catch(Exception e) {
            throw new AuthorizationException('Delete failed for given object. stack trace :' + e.getStackTraceString());
        }
    }

    public void doDeleteCheck(SObject[] sObjectList) {
        if(sObjectList == null || sObjectList.size() == 0) {
            throw new AuthorizationException('null parameter for delete check');
        }
        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();

        if(!d.isDeletable()) {
            throw new AuthorizationException(d.getName() + ' is not deletable. Check your OLS setup for delete access.');
        }

        Database.DeleteResult[] results = null;
        try {
            results = databaseDelete(sObjectList, dbType == DatabaseOperationType.ALL_OR_NONE);
        } catch(Exception e) {
            throw new AuthorizationException('Delete failed for given object. stack trace :' + e.getStackTraceString());
        }
    }

    public sObject doUpsertCheck(SObject sObj, List<String> fieldNames, Schema.SObjectField externalId) {
        if(sObj == null || fieldNames.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for upsert check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(!d.isCreateable() || !d.isUpdateable()) {
            throw new AuthorizationException(d.getName() + ' is not upsertable. Check your OLS setup for create and update access.');
        }
        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObj.getSObjectType()); // potentially saves a fields call below
        List<String> updateableFieldsList = generateListFieldNames(getUpdateableFieldsList(sObj.getSObjectType()));
        List<String> creatableFieldsList = generateListFieldNames(getCreatableFieldsList(sObj.getSObjectType()));

        sObject cleansObj = sObj.getSObjectType().newSObject();

        for(String fieldName : fieldNames) {
            fieldName = fieldName.toLowerCase();
            if(!updateableFieldsList.contains(fieldName) || !creatableFieldsList.contains(fieldName)) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(fieldName + ' not found or there is an access violation during upsert check');
                }
            } else {
                if(String.isBlank(String.valueOf(cleansObj.get(fieldName))) & !fieldMap.get(fieldName).getDescribe().isNillable()) {
                    continue;
                }
                ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(cleansObj, ((Blob)sObj.get(fieldName)).toString());
                } else {
                    ct.putTo(cleansObj, String.valueOf(sObj.get(fieldName)));
                }
            }
        }

        try {
            databaseUpsert(cleansObj, externalId);
        } catch(Exception e) {
            throw new AuthorizationException('Upsert failed for given object. stack trace :' + e.getStackTraceString());
        }
        return cleansObj;

    }

    public sObject doUpsertCheck(SObject sObj, List<Schema.SObjectField> fieldsList, Schema.SObjectField externalId) {
        if(sObj == null || fieldsList.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for upsert check');
        }

        Schema.DescribeSObjectResult d = sObj.getSObjectType().getDescribe();
        if(!d.isCreateable() || !d.isUpdateable()) {
            throw new AuthorizationException(d.getName() + ' is not upsertable. Check your OLS setup for create and update access.');
        }

        sObject cleansObj = sObj.getSObjectType().newSObject();

        for(Schema.SObjectField field : fieldsList) {
            if((!field.getDescribe().isCreateable() || !field.getDescribe().isUpdateable()) && field.getDescribe().isCustom()) {
                if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                    throw new AuthorizationException(field + ' not found or there is an access violation during upsert check');
                }
            } else {
                if(String.isBlank(String.valueOf(cleansObj.get(field))) & !field.getDescribe().isNillable()) {
                    continue;
                }
                ConvertTypes ct = new ConvertTypes(field);
                if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                    ct.putTo(cleansObj, ((Blob)sObj.get(field)).toString());
                } else {
                    ct.putTo(cleansObj, String.valueOf(sObj.get(field)));
                }
            }
        }

        try {
            databaseUpsert(cleansObj, externalId);
        } catch(Exception e) {
            throw new AuthorizationException('Upsert failed for given object. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }
        return cleansObj;
    }

    public sObject [] doUpsertCheck(SObject [] sObjectList, List<Schema.SObjectField> fields, Schema.SObjectField externalId) {
        if(sObjectList.isEmpty() || fields.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for upsert check');
        }

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not upsertable. Check your OLS setup for create and update access.');
        }

        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();
            cleansObj.Id = devObj.Id;
            for(Schema.SObjectField field : fields) {
                if((field.getDescribe().isUpdateable() == false || field.getDescribe().isCreateable() == false) && field.getDescribe().isCustom()) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(field.getDescribe().getName() + ' access violation during upsert check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(cleansObj.get(field))) & !field.getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(field);
                    if(field.getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(field)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(field)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.UpsertResult [] results = null;
        try {
            results = databaseUpsert(clearList, dbType == DatabaseOperationType.ALL_OR_NONE, externalId);
        } catch(Exception e) {
            throw new AuthorizationException('Upsert failed for given list objects. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }

        return clearList;
    }

    public sObject [] doUpsertCheck(SObject [] sObjectList, List<String> fieldNames, Schema.SObjectField externalId) {
        if(sObjectList.isEmpty() || fieldNames.isEmpty()) {
            throw new AuthorizationException('null or empty parameter for upsert check');
        }

        Schema.DescribeSObjectResult d = sObjectList.getSObjectType().getDescribe();
        if(d.isUpdateable() == false) {
            throw new AuthorizationException(d.getName() + ' is not upsertable. Check your OLS setup for create and update access.');
        }
        Map<String, Schema.SObjectField> fieldMap = AuthorizationUtils.sObjectFieldMap(sObjectList.getSObjectType());
        List<String> upsertableFieldList = generateListFieldNames(getUpsertableFieldsList(sObjectList.getSObjectType()));
        sObject [] clearList = sObjectList.clone();
        clearList.clear();

        for(sObject devObj : sObjectList) {
            sObject cleansObj = devObj.getSObjectType().newSObject();
            cleansObj.Id = devObj.Id;
            for(String fieldName : fieldNames) {
                if(!upsertableFieldList.contains(fieldName)) {
                    if(dbType == DatabaseOperationType.ALL_OR_NONE) {
                        throw new AuthorizationException(fieldName + ' access violation during upsert check');
                    }
                } else {
                    if(String.isBlank(String.valueOf(cleansObj.get(fieldName))) & !fieldMap.get(fieldName).getDescribe().isNillable()) {
                        continue;
                    }
                    ConvertTypes ct = new ConvertTypes(fieldMap.get(fieldName));
                    if(fieldMap.get(fieldName).getDescribe().getSOAPType() == SoapType.BASE64BINARY){
                        ct.putTo(cleansObj, ((Blob)devObj.get(fieldName)).toString());
                    } else {
                        ct.putTo(cleansObj, String.valueOf(devObj.get(fieldName)));
                    }
                }
            }

            clearList.add(cleansObj);
        }

        Database.UpsertResult [] results = null;
        try {
            results = databaseUpsert(clearList, dbType == DatabaseOperationType.ALL_OR_NONE, externalId);
        } catch(Exception e) {
            throw new AuthorizationException('Upsert failed for given list objects. Error message: ' + e.getMessage() + ' stack trace :' + e.getStackTraceString());
        }

        return clearList;
    }
}