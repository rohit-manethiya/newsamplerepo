/**
 * CONSIDERATIONS:
 *
 * -Specifying the Apex datasource as public isn’t respected in managed packages.
 *  If an Apex class is public and part of a managed package,
 *  it can be used as a datasource for custom components in the subscriber org.
 *
 * -Profile access on the Apex class isn’t respected when the Apex class is used as a datasource.
 *  If an admin’s profile doesn’t have access to the Apex class but does have access to the custom component,
 *  the admin sees values provided by the Apex class on the component in the Lightning App Builder.
 */
global with sharing class RelatedListVisualPicklist extends VisualEditor.DynamicPickList {
    @TestVisible
    private static final String RECORD_PAGE = 'RecordPage';

    private VisualEditor.DynamicPickListRows rows;

    @TestVisible
    private RelatedListVisualPicklist(String pageType, String objectName) {
        rows = getRows(pageType, objectName);
    }

    global RelatedListVisualPicklist(VisualEditor.DesignTimePageContext context) {
        rows = getRows(context.pageType, context.entityName);
    }

    private VisualEditor.DynamicPickListRows getRows(String pageType, String objectName) {
        VisualEditor.DynamicPickListRows rows = new VisualEditor.DynamicPickListRows();
        if (pageType == RECORD_PAGE) {
            Map<String, String> relatedLists = getObjectRelatedList(objectName);
            for (String relatedObjectName : relatedLists.keySet()) {
                rows.addRow(new VisualEditor.DataRow(relatedLists.get(relatedObjectName), relatedObjectName));
            }
        }
        return rows;
    }

    private Map<String, String> getObjectRelatedList(String objectName) {
        Map<String, String> relatedObject = new Map<String, String>();
        String[] objectNames = new List<String>{ objectName };
        Schema.DescribeSobjectResult[] objects = Schema.describeSObjects(objectNames);
        Schema.DescribeSobjectResult objectInfo = objects[0];
        for (Schema.ChildRelationship childRelation : objectInfo.getChildRelationships()) {
            Schema.DescribeSobjectResult describedChildObject = childRelation.getChildSObject().getDescribe();
            relatedObject.put(describedChildObject.getName(), describedChildObject.getLabel());
        }
        return relatedObject;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        return rows;
    }
}