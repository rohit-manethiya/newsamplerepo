public with sharing class CustomLookupComponentHelper {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<SObject> findRecords(CustomLookupQueryConfiguration queryConfig) {
        try {
            return Database.query(queryConfig.getFormattedQuery());
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}