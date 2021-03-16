/**
 * Created by ferhatozsavran on 5/28/18.
 */

public with sharing class KanbanBoardEditController {
    private final Kanban_Board__c kBoard;
    private final String NONE = '--None--';
    public QueryEditor qEditor { get; set; }

    public KanbanBoardEditController(ApexPages.StandardController stdController) {
        // new instance of Query Editor to send values to component and edit in the component.
        this.kBoard = (Kanban_Board__c)stdController.getRecord();
        qEditor = new QueryEditor();
        QueryEditor.SoqlWrapper soqlJsonWrapper = new QueryEditor.SoqlWrapper();
        qEditor.queryWrapper = soqlJsonWrapper;
        qEditor.queryJson = '';
    }

    /**
     * it is used to create kanban record
     * @return
     */
    public PageReference createKanban(){
        ApexPages.getMessages().clear();
        // checking if the column field is selected or not
        if(String.isNotBlank(qEditor.queryWrapper.fieldToReadUpdate) && qEditor.queryWrapper.fieldToReadUpdate == NONE){
            ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, ' ' + Label.Select_Read_Update_Field));
            return null;
        }

        // Footer field limit is 2 so check if there are more than 2 fields are selected, show warning
        if(qEditor.queryWrapper.selectedFooterFields != null && !qEditor.queryWrapper.selectedFooterFields.isEmpty() && qEditor.queryWrapper.selectedFooterFields.size() > 2){
            ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, ' ' + Label.Kanban_Card_Footer_Validation));
            return null;
        }

        // Checking if filter logic is enabled and filled manually
        if(qEditor.queryWrapper.enableFilterLogic && String.isBlank(qEditor.queryWrapper.filterLogic)){
            ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, ' ' + Label.Enter_Filter_Logic));
            return null;
        }

        // checking again if the query is created or validated
        if(String.isNotBlank(qEditor.queryWrapper.wholeSoql)){
            try{
                if(Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName).getDescribe().isQueryable()){
                    Database.query(qEditor.queryWrapper.wholeSoql);
                }
            } catch (Exception e){
                ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, ' ' + Label.Query_is_not_Valid));
                return null;
            }
        }

        // inserting new kanban record
        Kanban_Board__c kb = new Kanban_Board__c();

        // FLS and CRUD
        if(!Schema.SObjectType.Kanban_Board__c.fields.Name.isCreateable() || !Schema.SObjectType.Kanban_Board__c.fields.SOQL_Query__c.isCreateable() || !Schema.SObjectType.Kanban_Board__c.fields.Description__c.isCreateable() || !Schema.SObjectType.Kanban_Board__c.fields.Field_to_read_update__c.isCreateable() || !Schema.SObjectType.Kanban_Board__c.fields.JSON_Settings__c.isCreateable()){
            return null;
        }

        kb.Name = String.isNotBlank(qEditor.queryWrapper.viewName) ? qEditor.queryWrapper.viewName : Label.New_Kanban_View;
        kb.SOQL_Query__c = String.isNotBlank(qEditor.queryWrapper.wholeSoql) ? qEditor.queryWrapper.wholeSoql : '';
        kb.Description__c = String.isNotBlank(qEditor.queryWrapper.kanbanDescription) ? qEditor.queryWrapper.kanbanDescription : '';
        String fieldReadUpdate = qEditor.queryWrapper.sobjectTypeName + '.' + qEditor.queryWrapper.fieldToReadUpdate;
        kb.Field_to_read_update__c = fieldReadUpdate;
        for(QueryEditor.CriteriaWrapper cw : qEditor.queryWrapper.criteriaList){
            cw.operatorSet = null;
        }
        kb.JSON_Settings__c = JSON.serialize(qEditor);

        Utilities.Secure_DML(kb, Utilities.DML_Action.INS, schema.SObjectType.Kanban_Board__c);

        // redirect to the related kanban by adding id to parameter
        PageReference pReference = Page.KanbanBoardView;
        if(String.isNotBlank(kb.Id)){
            pReference.getParameters().put('id',kb.Id);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * it is used to check if the entered text is a valid object
     */
    public void objectNameValidation() {
        ApexPages.getMessages().clear();
        Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        Boolean objectExist = false;
        for(String name : gdMap.keySet()){
            DescribeSObjectResult describe = gdMap.get(name).getDescribe();
            if(String.isNotBlank(qEditor.queryWrapper.sobjectTypeName) && (qEditor.queryWrapper.sobjectTypeName.toLowerCase() == name || qEditor.queryWrapper.sobjectTypeName.toLowerCase() == describe.getLabel().toLowerCase())) {
                if(qEditor.queryWrapper.sobjectTypeName.toLowerCase() == describe.getLabel().toLowerCase()) {
                    qEditor.queryWrapper.sobjectTypeName = name;
                }
                objectExist = true;
                if(objectExist && (!describe.isAccessible() || !describe.isQueryable())) {
                    qEditor.queryWrapper.sobjectTypeName = '';
                    ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, describe.getLabel() +': ' + Label.Insufficient_Access_Rights));
                }
                break;
            }
        }

        if(!objectExist) {
            qEditor.queryWrapper.sobjectTypeName = '';
            ApexPages.addMessage(new apexpages.Message(apexpages.Severity.WARNING, Label.Enter_Object_API_or_Name));
        }
    }
}