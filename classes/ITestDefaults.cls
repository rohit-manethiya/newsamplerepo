public interface ITestDefaults {
    // Use this interface to set up values you want to default in for all objects.
    ITestDefaults includeDefaults(Type childDefaults);
    ITestDefaults setFieldDefaults();
    ITestDefaults setIncrementalFields(Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFields);
    ITestDefaults setFieldValue(Schema.SObjectType objectType, Schema.SObjectField objectField, Object fieldValue);
    ITestDefaults setDataSize(Schema.SObjectType objectType,Integer size);
    ITestDefaults setSObjectRelation(Schema.SObjectType objectType, Schema.SObjectType parentObjectType, Map<Schema.SObjectField, Integer> fieldChunkSizeMap);
    ITestDefaults generateDefaults();
    ITestDefaults createRunAsUsers(); 
    ITestDefaults executeDML();

    Map<String, List<User>> getRunAsUsers();
    List<SObject> getTestData(Schema.SObjectType objecType);
    Map<Schema.SObjectType,Map<Schema.SObjectField, Object>> getTestDataFieldDefaultsByObject();
}