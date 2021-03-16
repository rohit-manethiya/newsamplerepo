/**
 * @AUTHOR Mert YALTI
 * @description Interface class to handle methods that we need to use to handle secure operations
 * @version 1.0
 * @since 2018-05-25
 */
public interface IAuthorization {
    /**
     * Execute any SOQL Query within given authorization
     * @param query
     * @return List
     */
    List<SObject> executeQuery(String query);
    /**
     * Retrieve sObjectFields as a map from given sObject
     * @return Map<String, Schema.SObjectField>
     * @see AuthorizationCheck
     */
    Map<String, Schema.SObjectField> getFieldsMap(SObjectType sObjType);

    /**
     * Retrieve only accessible sObjectFields as a map from given sObject
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getAccessibleFieldsList(SObjectType sObjectType);
    /**
     * Retrieve only accessible sObjectFields as a map from sObjectFields map. This method will filter fields by theire accessibility
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getAccessibleFieldsList(Map<String, Schema.SObjectField> fieldsMap);
    /**
     * Retrieve only updatable sObjectFields as a map from given sObject
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getUpdateableFieldsList(SObjectType sObjectType);
    /**
     * Retrieve only updatable sObjectFields as a map from sObjectFields map. This method will filter fields by theire updatability
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getUpdateableFieldsList(Map<String, Schema.SObjectField> fieldsMap);
    /**
     * Retrieve only creatable sObjectFields as a map from given sObject
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getCreatableFieldsList(SObjectType sObjectType);
    /**
     * Retrieve only createable sObjectFields as a map from sObjectFields map. This method will filter fields by theire createability
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getCreatableFieldsList(Map<String, Schema.SObjectField> fieldsMap);
    /**
     * Retrieve only createable and updatable sObjectFields as a map from given sObject
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getUpsertableFieldsList(SObjectType sObjectType);
    /**
     * Retrieve only createable and updatable sObjectFields as a map from sObjectFields map. This method will filter fields by theire createability
     * @return List<Schema.SObjectField>
     * @see AuthorizationCheck
     */
    List<Schema.SObjectField> getUpsertableFieldsList(Map<String, Schema.SObjectField> fieldsMap);
    /**
     * Converts list sObjectField to List (string) field name
     * @return List<String>
     * @see AuthorizationCheck
     */
    List<String> generateListFieldNames(List<Schema.SObjectField> fields);
    /**
     * Builds basic base query with all accessible fields for given object by usin Select {0} FROM {1} model
     * @return String
     * @see AuthorizationCheck
     */
    String buildSecureBaseQuery(SObjectType sObjectType);
    /**
     * Builds basic base query with accessible fields that are retrieved from given field map for given object by usin Select {0} FROM {1} model
     * @return String
     * @see AuthorizationCheck
     */
    String buildSecureBaseQuery(SObjectType sObjectType, Map<String, Schema.SObjectField> fieldsMap);
    /**
     * Builds basic base query with all accessible fields for given object name by usin Select {0} FROM {1} model
     * @return String
     * @see AuthorizationCheck
     */
    String buildSecureBaseQuery(String sObjectName);
    /**
     * checks if the given object and fields are accessible or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<String> fieldNames);
    /**
     * checks if the given object and fields are accessible or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToView(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are accessible or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToView(String sObjectName, List<String> fieldNames);
    /**
     * checks if the given object and fields are accessible or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToView(String sObjectName, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are creatable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are creatable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToCreate(Schema.SObjectType sObjectType, List<String> fieldNames);
    /**
     * checks if the given object and fields are creatable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToCreate(String sObjectName, List<String> fieldNames);
    /**
     * checks if the given object and fields are creatable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToCreate(String sObjectName, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are updateable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are updateable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToUpdate(Schema.SObjectType sObjectType, List<String> fieldNames);
    /**
     * checks if the given object and fields are updateable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToUpdate(String sObjectName, List<String> fieldNames);
    /**
     * checks if the given object and fields are updateable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToUpdate(String sObjectName, List<Schema.SObjectField> listFields);
    /**
     * checks if the given object and fields are deleteable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToDelete(Schema.SObjectType SObjectType);
    /**
     * checks if the given object and fields are deleteable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToDelete(String sObjectName);
    /**
     * checks if the given object is queryable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToQuery(Schema.SObjectType sObjectType);
    /**
     * checks if the given object is queryable or not
     * @return Boolean
     * @see AuthorizationCheck
     */
    Boolean isAuthorizedToQuery(String sObjectName);

    sObject doInsertCheck(SObject sObj, List<String> fieldNames); // secure insert operation
    sObject doInsertCheck(SObject sObj, List<Schema.SObjectField> fieldsList); // secure insert operation
    sObject [] doInsertCheck(SObject [] sObjectList, List<Schema.SObjectField> fieldsToSet); // secure insert operation
    sObject [] doInsertCheck(SObject [] sObjectList, List<String> fieldNames); // secure insert operation

    sObject doUpdateCheck(SObject sObj, List<String> fieldNames); // secure update operation
    sObject doUpdateCheck(SObject sObj, List<Schema.SObjectField> fieldsList); // secure update operation
    sObject [] doUpdateCheck(SObject [] sObjectList, List<Schema.SObjectField> fieldsToSet); // secure update operation
    sObject [] doUpdateCheck(SObject [] sObjectList, List<String> fieldNames); // secure update operation

    void doDeleteCheck(SObject sObj); // secure delete operation
    void doDeleteCheck(SObject [] sObjectList); // secure delete operation

    sObject doUpsertCheck(SObject sObj, List<String> fieldNames, Schema.SObjectField externalId); // secure upsert operation
    sObject doUpsertCheck(SObject sObj, List<Schema.SObjectField> fieldsList, Schema.SObjectField externalId); // secure upsert operation
    sObject [] doUpsertCheck(SObject [] sObjectList, List<Schema.SObjectField> fieldsToSet,Schema.SObjectField externalId); // secure upsert operation
    //sObject [] doUpsertCheck(SObject [] sObjectList, List<String> fieldNames); // secure upsert operation*/

}