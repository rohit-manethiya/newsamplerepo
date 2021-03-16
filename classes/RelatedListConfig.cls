/**
 * This class is used as a wrapper by RelatedListController
 */
public with sharing class RelatedListConfig {
    @AuraEnabled
    public String iconName;
    @AuraEnabled
    public String childListName;
    @AuraEnabled
    public String sobjectLabel;
    @AuraEnabled
    public String sobjectLabelPlural;

    // CTOR

    public RelatedListConfig(String parentId, String fromObject, String relationshipField) {
        iconName = getIconName(fromObject);
        childListName = getChildListName(parentId, fromObject, relationshipField);

        Schema.DescribeSObjectResult sobjectDescribe = fflib_SObjectDescribe.getDescribe(fromObject).getDescribe();
        sobjectLabel = sobjectDescribe.getLabel();
        sobjectLabelPlural = sobjectDescribe.getLabelPlural();
    }

    // PRIVATE

    private String getIconName(String sobjectApiName) {
        List<Schema.DescribeTabSetResult> tabSets = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabs = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> icons = new List<Schema.DescribeIconResult>();

        for (Schema.DescribeTabSetResult tabSet : tabSets) {
            tabs.addAll(tabSet.getTabs());
        }

        String namespace = Settings.ns;
        String iconName;

        for (Schema.DescribeTabResult tab : tabs) {
            String tabObjName = tab.getSobjectName();
            Boolean matchTabObjName = (sobjectApiName == tabObjName || namespace + sobjectApiName == tabObjName);
            if (matchTabObjName) {
                if (tab.isCustom()) {
                    icons.addAll(tab.getIcons());
                } else {
                    iconName = 'standard:' + sobjectApiName.toLowerCase();
                }
            }
        }

        for (Schema.DescribeIconResult icon : icons) {
            if (icon.getContentType() == 'image/svg+xml') {
                iconName = 'custom:' + icon.getUrl().substringBetween('custom/', '.svg').substringBefore('_');
                break;
            }
        }

        return iconName;
    }

    /**
     * Returns the name of the relationship for the the child list, for example: 'Contacts' in Account.
     */
    private String getChildListName(Id parentId, String fromObject, String relationshipField) {
        String namespace = Settings.ns;
        Schema.DescribeSObjectResult parentDescribe = parentId.getSObjectType().getDescribe();
        String relationName = relationshipField;

        if (String.isBlank(relationName)) {
            relationName = getDefaultRelationshipField(fromObject, parentDescribe.getName());
        }

        String childListName;

        for (Schema.ChildRelationship childRelation : parentDescribe.getChildRelationships()) {
            String childName = childRelation.getChildSObject().getDescribe().getName();
            Boolean matchObject = (childName == fromObject || childName == namespace + fromObject);
            String filedRelation = childRelation.getField().getDescribe().getName();
            Boolean matchRelation = (filedRelation == relationName || filedRelation == namespace + relationName);

            if (matchObject && matchRelation) {
                childListName = childRelation.getRelationshipName();
                break;
            }
        }

        return childListName;
    }

    private String getDefaultRelationshipField(String fromObject, String parentObject) {
        List<SObjectField> sObjectFields = fflib_SObjectDescribe.getDescribe(fromObject).getFieldsMap().values();

        for (SObjectField field : sObjectFields) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldType = fieldDescribe.getType().name();

            Boolean matchReference =
                fieldType == Schema.DisplayType.Reference.name() &&
                parentObject == fieldDescribe.getReferenceTo()[0].getDescribe().getName();

            if (matchReference) {
                return fieldDescribe.getName();
            }
        }

        throw new InvalidRelationshipException(Label.Invalid_Relationship_Error);
    }

    // INNER

    private class InvalidRelationshipException extends Exception {}
}