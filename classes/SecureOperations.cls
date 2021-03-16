/**
 * Created by mertyalti on 18/05/2018.
 */

public class SecureOperations {
    @TestVisible private AuthorizationWithSharing authWithSharing;
    @TestVisible private AuthorizationWithoutSharing authWithoutSharing;
    private DatabaseOperationType operationType;
    private DatabaseOperationType sharingType;

    public SecureOperations() {
        this.sharingType = DatabaseOperationType.WITHSHARING;
        authWithSharing = new AuthorizationWithSharing();
        //authWithoutSharing = new AuthorizationWithoutSharing();

        authWithSharing.setupOperation(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHSHARING);
        //authWithoutSharing.setupOperation(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHOUTSHARING);
    }

    public SecureOperations(DatabaseOperationType operationType, DatabaseOperationType sharingType) {
        this.sharingType = sharingType;
        this.operationType = operationType;
        if (DatabaseOperationType.WITHSHARING == sharingType) {
            authWithSharing = new AuthorizationWithSharing();
            authWithSharing.setupOperation(operationType, sharingType);
        } else {
            authWithoutSharing = new AuthorizationWithoutSharing();
            authWithoutSharing.setupOperation(DatabaseOperationType.ALL_OR_NONE, DatabaseOperationType.WITHSHARING);
        }
    }

    public IAuthorization getProperAuthorization() {
        if (sharingType == DatabaseOperationType.WITHSHARING) {
            return authWithSharing;
        } else if (sharingType == DatabaseOperationType.WITHOUTSHARING) {
            return authWithoutSharing;
        } else {
            return authWithSharing;
        }
    }

    public Map<String, Schema.SObjectField> getFieldsMap(SObjectType sObjType) {
        return getProperAuthorization().getFieldsMap(sObjType);
    }

    public List<Schema.SObjectField> getAccessibleFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        return getProperAuthorization().getAccessibleFieldsList(fieldsMap);
    }

    public List<Schema.SObjectField> getAccessibleFieldsList(SObjectType sObjectType) {
        return getProperAuthorization().getAccessibleFieldsList(sObjectType);
    }

    public List<Schema.SObjectField> getUpdateableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        return getProperAuthorization().getUpdateableFieldsList(fieldsMap);
    }

    public List<Schema.SObjectField> getUpdateableFieldsList(SObjectType sObjectType) {
        return getProperAuthorization().getUpdateableFieldsList(sObjectType);
    }

    public List<Schema.SObjectField> getCreatableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        return getProperAuthorization().getCreatableFieldsList(fieldsMap);
    }

    public List<Schema.SObjectField> getCreatableFieldsList(SObjectType sObjectType) {
        return getProperAuthorization().getCreatableFieldsList(sObjectType);
    }

    public List<Schema.SObjectField> getUpsertableFieldsList(Map<String, Schema.SObjectField> fieldsMap) {
        return getProperAuthorization().getUpsertableFieldsList(fieldsMap);
    }

    public List<Schema.SObjectField> getUpsertableFieldsList(SObjectType sObjectType) {
        return getProperAuthorization().getUpsertableFieldsList(sObjectType);
    }

    public List<String> generateListFieldNames(List<Schema.SObjectField> fields) {
        return getProperAuthorization().generateListFieldNames(fields);
    }

    public String buildSecureBaseQuery(SObjectType sObjectType) {
        return getProperAuthorization().buildSecureBaseQuery(sObjectType);
    }

    public String buildSecureBaseQuery(SObjectType sObjectType, Map<String, Schema.SObjectField> fieldsMap) {
        return getProperAuthorization().buildSecureBaseQuery(sObjectType, fieldsMap);
    }

    public String buildSecureBaseQuery(String sObjectName) {
        return getProperAuthorization().buildSecureBaseQuery(sObjectName);
    }

    public Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToView(sObjectType, fieldNames);
    }
    public Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToView(sObjectType, listFields);
    }
    public Boolean isAuthorizedToView(String sObjectName, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToView(sObjectName, fieldNames);
    }
    public Boolean isAuthorizedToView(String sObjectName, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToView(sObjectName, listFields);
    }

    public Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToCreate(sObjectType, listFields);
    }
    public Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToCreate(sObjectType, fieldNames);
    }
    public Boolean isAuthorizedToCreate(String sObjectName, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToCreate(sObjectName, fieldNames);
    }
    public Boolean isAuthorizedToCreate(String sObjectName, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToCreate(sObjectName, listFields);
    }

    public Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToUpdate(sObjectType, listFields);
    }
    public Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToUpdate(sObjectType, fieldNames);
    }
    public Boolean isAuthorizedToUpdate(String sObjectName, List<String> fieldNames) {
        return getProperAuthorization().isAuthorizedToUpdate(sObjectName, fieldNames);
    }
    public Boolean isAuthorizedToUpdate(String sObjectName, List<Schema.SObjectField> listFields) {
        return getProperAuthorization().isAuthorizedToUpdate(sObjectName, listFields);
    }

    public Boolean isAuthorizedToDelete(Schema.SObjectType sObjectType) {
        return getProperAuthorization().isAuthorizedToDelete(sObjectType);
    }
    public Boolean isAuthorizedToDelete(String sObjectName) {
        return getProperAuthorization().isAuthorizedToDelete(sObjectName);
    }
    public Boolean isAuthorizedToQuery(Schema.SObjectType sObjectType) {
        return getProperAuthorization().isAuthorizedToQuery(sObjectType);
    }
    public Boolean isAuthorizedToQuery(String sObjectName) {
        return getProperAuthorization().isAuthorizedToQuery(sObjectName);
    }

    public SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sob, getCreatableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sob, getUpdateableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sob);
            return null;
        } else if (action == DML_Action.UPS) {
            return getProperAuthorization().doUpsertCheck(sob,getUpsertableFieldsList(stype.getSObjectType()),null);
        }
        return null;
    }

    public SObject Secure_DML(SObject sob, DML_Action action) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sob, getCreatableFieldsList(sob.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sob, getUpdateableFieldsList(sob.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sob);
            return null;
        } else if (action == DML_Action.UPS) {
            return getProperAuthorization().doUpsertCheck(sob,getUpsertableFieldsList(sob.getSObjectType()),null);
        }
        return null;
    }

    public SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype, Schema.Describefieldresult externalIDField) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sob, getCreatableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sob, getUpdateableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sob);
            return null;
        } else if (action == DML_Action.UPS) {
            getProperAuthorization().doUpsertCheck(sob,getUpsertableFieldsList(sob.getSObjectType()), externalIDField.getSobjectField());
        }
        return null;
    }

    public List<SObject> Secure_DML(List<SObject> sobjects, DML_Action action) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sobjects, getCreatableFieldsList(sobjects.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sobjects, getUpdateableFieldsList(sobjects.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sobjects);
            return null;
        } else if (action == DML_Action.UPS) {
            getProperAuthorization().doUpsertCheck(sobjects,getUpsertableFieldsList(sobjects.getSObjectType()),null);
        }
        return null;
    }

    public List<SObject> Secure_DML(List<SObject> sobjects, DML_Action action, Schema.DescribeSObjectResult stype) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sobjects, getCreatableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sobjects, getUpdateableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sobjects);
            return null;
        } else if (action == DML_Action.UPS) {
            getProperAuthorization().doUpsertCheck(sobjects,getUpsertableFieldsList(stype.getSObjectType()),null);
        }
        return null;
    }

    public List<SObject> Secure_DML(List<SObject> sObjectList, DML_Action action, Schema.DescribeSObjectResult stype, Schema.Describefieldresult externalIDField) {
        if (action == DML_Action.INS) {
            return getProperAuthorization().doInsertCheck(sObjectList, getCreatableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.UPD) {
            return getProperAuthorization().doUpdateCheck(sObjectList, getUpdateableFieldsList(stype.getSObjectType()));
        } else if (action == DML_Action.DEL) {
            getProperAuthorization().doDeleteCheck(sObjectList);
            return null;
        } else if (action == DML_Action.UPS) {
            getProperAuthorization().doUpsertCheck(sObjectList,getUpsertableFieldsList(stype.getSObjectType()),externalIDField.getSobjectField());
        }
        return null;
    }
}