/**
 * Created by mertyalti on 17/05/2018.
 */

public with sharing class AuthorizationUtils {
    static Map<String, Map<String, Schema.SObjectField>> storedFieldCache = new Map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, Schema.SObjectField> sObjectFieldMap(Schema.SObjectType objectType) {
        Schema.DescribeSObjectResult objectDescribe = sobjectDescribe(objectType);
        return sObjectFieldMap(objectDescribe);
    }

    public static Map<String, Schema.SObjectField> sObjectFieldMap(String objectName) {
        return sObjectFieldMap(sobjectType(objectName));
    }

    public static Map<String, Schema.SObjectField> sObjectFieldMap(Schema.DescribeSObjectResult objectDescribe) {
        Map<String, Schema.SObjectField> fieldMap = null;
        String sobjName = objectDescribe.getName();
        if (storedFieldCache.containsKey(sobjName)) {
            fieldMap = storedFieldCache.get(sobjName);
        } else {
            fieldMap = objectDescribe.fields.getMap();
            storedFieldCache.put(sobjName, fieldMap);
        }
        return fieldMap;
    }

    public static Schema.DescribeSObjectResult sobjectDescribe(Schema.SObjectType objectType) {
        return objectType.getDescribe();
    }

    public static Schema.DescribeSObjectResult sobjectDescribe(String objectName) {
        return sobjectType(objectName).getDescribe();
    }

    public static Schema.SObjectType sobjectType(String objectName) {
        return Schema.getGlobalDescribe().get(objectName);
    }

    public static Map<String, Schema.SObjectField> sobjectFieldsNoCache (Schema.DescribeSObjectResult objectDescribe) {
        return objectDescribe.fields.getMap();
    }

    public static Map<String, Schema.SObjectField> sobjectFieldsNoCache (String objectName) {
        return sobjectType(objectName).getDescribe().fields.getMap();
    }

    public static Map<String, Schema.SObjectField> sobjectFieldsNoCache (Schema.SObjectType objectType) {
        return objectType.getDescribe().fields.getMap();
    }

    public static Set<String> fieldsToStringSet(List<Schema.SObjectField> fields) {
        Set<String> fieldNames = new Set<String>{};
        for (Schema.SObjectField f:fields) {
            fieldNames.add(f.getDescribe().getName().toLowerCase());
        }
        return fieldNames;
    }
}