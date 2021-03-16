public with sharing class RelatedListController {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static RelatedListConfig fetchRelatedListConfig(String parentId, String fromObject, String relationshipField) {
        try {
            return new RelatedListConfig(parentId, fromObject, relationshipField);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}