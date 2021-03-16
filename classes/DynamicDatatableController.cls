public with sharing class DynamicDatatableController {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<ColumnConfig> fetchColumnsConfig(String objectApiName, String fieldSetName, Boolean hideDefaultColumnsActions) {
        List<ColumnConfig> result = new List<ColumnConfig>();

        try {
            for (FieldSetMember field : getMembers(objectApiName, fieldSetName)) {
                result.add(new ColumnConfig(field, hideDefaultColumnsActions));
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }

    @AuraEnabled
    public static List<SObject> fetchData(DynamicDatatableQueryConfiguration queryConfig) {
        try {
            return Database.query(queryConfig.getFormattedQuery());
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static List<FieldSetMember> getMembers(String type, String fieldSet) {
        return fflib_SObjectDescribe.getDescribe(type).getFieldSets().get(fieldSet).getFields();
    }
}