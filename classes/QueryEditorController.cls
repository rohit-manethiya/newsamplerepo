/**
 * Created by ferhatozsavran on 4/24/18.
 */

public with sharing class QueryEditorController {
    public String compMode { get; set; }
    private final String NONE = '--None--';
    private final String C_REFERENCE = 'REFERENCE';
    private final String C_PERCENT = 'PERCENT';
    private final String C_DOUBLE = 'DOUBLE';
    private final String C_BOOLEAN = 'BOOLEAN';
    private final String C_DATE = 'DATE';
    private final String C_DATETIME = 'DATETIME';
    private final String C_STRING = 'STRING';
    private final String C_PICKLIST = 'PICKLIST';
    private final String C_COMBOBOX = 'COMBOBOX';
    private final String C_ID = 'Id';
    private final String C_NAME = 'Name';
    private final String C_ASC = 'ASC';
    private final String C_DESC = 'DESC';
    private final String C_NULLSFIRST = 'NULLS FIRST';
    private final String C_NULLSLAST = 'NULLS LAST';
    private final String C_COPADO = 'Copado';
    private final String C_ORDER = 'Order';
    public Boolean qEditorInitialized { get; set; } // created this because it got initialized 3 times.

    public QueryEditor qEditor {
        get;
        set {
            qEditor = value;

            if (!qEditorInitialized) {
                initVariables();
                qEditorInitialized = true;
            }
        }
    }

    public QueryEditorController() {
        qEditorInitialized = false;
    }

    /**
     * Initializing 3 empty criteria fields
     */
    public void initVariables() {
        if (compMode != 'Edit') {
            qEditor.queryWrapper.criteriaList = new List<QueryEditor.CriteriaWrapper>();
            qEditor.queryWrapper.summarizeByList = new List<QueryEditor.SummarizeByWrapper>();
            for (Integer i = 0; i < 3; i++) {
                addNewCriteria();
                addNewSummarizeBy();
            }
        }
    }

    /**
     * it is used to create new empty filter criteria line
     */
    public void addNewCriteria() {
        QueryEditor.CriteriaWrapper temp = new QueryEditor.CriteriaWrapper();
        temp.operatorSet = setOperators();
        if (qEditor.queryWrapper.criteriaList == null) {
            qEditor.queryWrapper.criteriaList = new List<QueryEditor.CriteriaWrapper>();
        }
        temp.order = qEditor.queryWrapper.criteriaList.size() + 1;
        qEditor.queryWrapper.criteriaList.add(temp);
    }

    /**
     * removing last filter criteria from list. For now it is removing only last item from list
     */
    public void removeCriteria() {
        if (!qEditor.queryWrapper.criteriaList.isEmpty()) {
            qEditor.queryWrapper.criteriaList.remove(qEditor.queryWrapper.criteriaList.size() - 1);
        }
    }

    /**
     * it is used to create new empty summarize by line
     */
    public void addNewSummarizeBy() {
        QueryEditor.SummarizeByWrapper temp = new QueryEditor.SummarizeByWrapper();
        if (qEditor.queryWrapper.summarizeByList == null) {
            qEditor.queryWrapper.summarizeByList = new List<QueryEditor.SummarizeByWrapper>();
        }
        temp.order = qEditor.queryWrapper.summarizeByList.size() + 1;
        qEditor.queryWrapper.summarizeByList.add(temp);
    }

    /**
     * removing last summarize by from list. For now it is removing only last item from list
     */
    public void removeSummarizeBy() {
        if (!qEditor.queryWrapper.summarizeByList.isEmpty()) {
            qEditor.queryWrapper.summarizeByList.remove(qEditor.queryWrapper.summarizeByList.size() - 1);
        }
    }

    /**
     * loop in the all possible operator code and add them to select option. This list will be updated based on selected field type.
     * @return
     */
    private List<SelectOption> setOperators() {
        List<SelectOption> operators = new List<SelectOption>();
        Map<String, String> operatorCodes = OperatorTypeCodes.getOperatorCodes();
        for (String oc : operatorCodes.keySet()) {
            operators.add(new SelectOption(oc, operatorCodes.get(oc)));
        }
        return operators;
    }

    /**
     * populate operator set field of qEditor.
     * @param listOrder
     */
    private void populateFilterCriteriaFields(Integer listOrder) {
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            QueryEditor.CriteriaWrapper temp = qEditor.queryWrapper.criteriaList[listOrder];
            String criteriaField = temp.fieldName;
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult dsr = convertType.getDescribe();
            Schema.DescribeFieldResult fields = null;
            if (criteriaField != NONE) {
                fields = dsr.fields.getMap().get(criteriaField).getDescribe();
            }
            // checking if the field is defined and field type is included in type operator map. If there is not defined type it will always return STRING
            Map<String, String[]> type2ops = OperatorTypeCodes.getTypeToOps();
            String fType = fields != null && type2ops.containsKey(String.valueOf(fields.getType()).toUpperCase())
                ? String.valueOf(fields.getType()).toUpperCase()
                : C_STRING;
            temp.fieldType = fType;
            List<SelectOption> criteriaOptions = new List<SelectOption>();
            criteriaOptions.add(new SelectOption(NONE, NONE));
            // updating the existing operator set based on selected type on the UI
            Map<String, String> operatorCodes = OperatorTypeCodes.getOperatorCodes();
            for (String opt : type2ops.get(fType)) {
                if (operatorCodes.containsKey(opt)) {
                    criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                }
            }
            temp.operatorSet = criteriaOptions;
        }
    }

    /**
     * returns all options for summarize by operator
     * @return
     */
    public List<SelectOption> getSummarizeByOpeartor() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        for (String name : OperatorTypeCodes.getSummarizeByOperatorSembols().keySet()) {
            apiNamesList.add(new SelectOption(name, name));
        }
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Summarize By Fields.
     *  '--None--' is added to as default value. For now only percent and double type fields are defined in the code. If you want to add new type of field, do not forget to update the all code which is related to this field.
     * @return
     */
    public List<SelectOption> getSummarizeByFields() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();
            apiNamesList.add(new SelectOption(NONE, NONE));
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields. For now only supporting picklist and reference type fields.
                // Note: Combobox is similar to picklist field but you can define new value for it. For example; Subject field of Event object.
                if (
                    fieldDescribe.isAccessible() &&
                    (String.valueOf(fieldDescribe.getType()) == C_PERCENT ||
                    String.valueOf(fieldDescribe.getType()) == C_DOUBLE)
                ) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to check if the entered text is a valid object
     */
    public void objectNameValidation() {
        Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        Boolean objectExist = false;
        for (String name : gdMap.keySet()) {
            DescribeSObjectResult describe = gdMap.get(name).getDescribe();
            if (
                String.isNotBlank(qEditor.queryWrapper.sobjectTypeName) &&
                (qEditor.queryWrapper.sobjectTypeName.toLowerCase() == name ||
                qEditor.queryWrapper.sobjectTypeName.toLowerCase() == describe.getLabel().toLowerCase())
            ) {
                if (qEditor.queryWrapper.sobjectTypeName.toLowerCase() == describe.getLabel().toLowerCase()) {
                    qEditor.queryWrapper.sobjectTypeName = name;
                }
                objectExist = true;
                if (objectExist && (!describe.isAccessible() || !describe.isQueryable())) {
                    qEditor.queryWrapper.sobjectTypeName = '';
                    ApexPages.addMessage(
                        new ApexPages.Message(ApexPages.Severity.WARNING, describe.getLabel() + ': ' + Label.Insufficient_Access_Rights)
                    );
                }
                break;
            }
        }

        if (!objectExist) {
            qEditor.queryWrapper.sobjectTypeName = '';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Enter_Object_API_or_Name));
        }
    }

    /**
     * it is used to populate possible options to show at Kanban Board Header.
     * @return
     */
    public List<SelectOption> getAllFieldsAPINameForHeader() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        apiNamesList.add(new SelectOption(NONE, NONE));
        apiNamesList.addAll(getAllFieldsAPINameMultiSelect());
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Select fields to Display. '--None--' is not added to avoid possible problem
     * @return
     */
    public List<SelectOption> getAllFieldsAPINameMultiSelect() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields.
                if (fieldDescribe.isAccessible()) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Field section of Specify Filter Criteria. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getAllFieldsAPIName() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();
            apiNamesList.add(new SelectOption(NONE, NONE));
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields and only adding filterable fields to the option list
                if (fieldDescribe.isAccessible() && fieldDescribe.isFilterable()) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Order By. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getAllFieldsAPINameOrderBy() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();
            apiNamesList.add(new SelectOption(NONE, NONE));
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields and only adding sortable fields to the option list
                if (fieldDescribe.isAccessible() && fieldDescribe.isSortable()) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Ordered In. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getOrderedInOptions() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        apiNamesList.add(new SelectOption(NONE, NONE));
        apiNamesList.add(new SelectOption(C_ASC, C_ASC));
        apiNamesList.add(new SelectOption(C_DESC, C_DESC));
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Null Values. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getNullValuesOptions() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        apiNamesList.add(new SelectOption(NONE, NONE));
        apiNamesList.add(new SelectOption(C_NULLSFIRST, C_NULLSFIRST));
        apiNamesList.add(new SelectOption(C_NULLSLAST, C_NULLSLAST));
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Select field to Read/Update and Select field to Define Kanban Cards Color .
     * '--None--' is added to as default value. For now only picklist and reference type fields are defined in the code. If you want to add new type of field, do not forget to update the all code which is related to this field.
     * @return
     */
    public List<SelectOption> getAllFieldsAPINameReadUpdate() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();
            apiNamesList.add(new SelectOption(NONE, NONE));
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields. For now only supporting picklist and reference type fields.
                // Note: Combobox is similar to picklist field but you can define new value for it. For example; Subject field of Event object.
                if (
                    fieldDescribe.isAccessible() &&
                    (String.valueOf(fieldDescribe.getType()) == C_PICKLIST ||
                    String.valueOf(fieldDescribe.getType()) == C_COMBOBOX ||
                    String.valueOf(fieldDescribe.getType()) == C_REFERENCE)
                ) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to populate possible options at Select field to User lookup field. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getUserLookupFieldsAPIName() {
        List<SelectOption> apiNamesList = new List<SelectOption>();
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult describeResult = convertType.getDescribe();
            Map<String, Schema.SObjectField> filedMap = new Map<String, Schema.SObjectField>();
            filedMap = describeResult.fields.getMap();

            apiNamesList.add(new SelectOption(NONE, NONE));
            for (String fieldName : filedMap.keySet()) {
                Schema.SObjectField field = filedMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // checking if the current user can see these fields.
                if (
                    fieldDescribe.isAccessible() &&
                    String.valueOf(fieldDescribe.getType()) == C_REFERENCE &&
                    String.valueOf(fieldDescribe.getReferenceTo()).contains('User')
                ) {
                    apiNamesList.add(new SelectOption(fieldDescribe.getName(), fieldDescribe.getLabel()));
                }
            }
            apiNamesList.sort();
        }
        return apiNamesList;
    }

    /**
     * it is used to create query and validate it
     */
    public void queryMaker() {
        QueryEditor.SoqlWrapper qWrap = qEditor.queryWrapper; // It is used for increasing readability of code

        // Id is required for kanban UI. Even if the user do not select Id field, It will be added to the query automatically.
        if (!qWrap.selectedFields.contains(C_ID)) {
            qWrap.selectedFields.add(C_ID);
        }
        // Name is required for kanban UI. Even if the user do not select Name field, It will be added to the query automatically. Some standard objects do not include name field. So there is pre-defined map in Operatortypecode class to use the written field instead of name.
        if (
            !OperatorTypeCodes.getStdObjectsWithoutNameField().containsKey(qWrap.sobjectTypeName.toLowerCase()) &&
            !qWrap.selectedFields.contains(C_NAME)
        ) {
            qWrap.selectedFields.add(C_NAME);
        } else if (
            OperatorTypeCodes.getStdObjectsWithoutNameField().containsKey(qWrap.sobjectTypeName.toLowerCase()) &&
            !qWrap.selectedFields.contains(OperatorTypeCodes.getStdObjectsWithoutNameField().get(qWrap.sobjectTypeName.toLowerCase()))
        ) {
            qWrap.selectedFields.add(OperatorTypeCodes.getStdObjectsWithoutNameField().get(qWrap.sobjectTypeName));
        }
        // User lookup field is used for kanban UI if selected. Even if the user do not select User lookup field in the selected fields, It will be added to the query automatically.
        if (String.isNotBlank(qWrap.userImageField) && qWrap.userImageField != NONE && !qWrap.selectedFields.contains(qWrap.userImageField)) {
            qWrap.selectedFields.add(qWrap.userImageField);
        }
        // headerField is used kanban UI. If it is not defined, Name field will be shown at the header of the kanban board
        if (String.isNotBlank(qWrap.headerField) && qWrap.headerField != NONE && !qWrap.selectedFields.contains(qWrap.headerField)) {
            qWrap.selectedFields.add(qWrap.headerField);
        }
        // colorField is used kanban UI. Even if the user do not select color field in the selected fields, It will be added to the query automatically.
        if (String.isNotBlank(qWrap.colorField) && qWrap.colorField != NONE && !qWrap.selectedFields.contains(qWrap.colorField)) {
            qWrap.selectedFields.add(qWrap.colorField);
        }
        // fieldToReadUpdate is required for kanban UI. If it is not selected user will be see warning over the 'Create Query and Validate' button
        if (String.isNotBlank(qWrap.fieldToReadUpdate) && qWrap.fieldToReadUpdate == NONE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Select_Read_Update_Field));
            return;
        }
        // fieldToReadUpdate is required for kanban UI. Even if the user do not select fieldToReadUpdate field, It will be added to the query automatically.
        if (String.isNotBlank(qWrap.fieldToReadUpdate) && qWrap.fieldToReadUpdate != NONE) {
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qWrap.sobjectTypeName);
            Map<String, SObjectField> fieldMap = convertType.getDescribe().fields.getMap();
            Schema.DescribeFieldResult fieldResult = fieldMap.get(qWrap.fieldToReadUpdate).getDescribe();
            // if type is reference we need to add relation name to query to show name instead of id. For instance; Account__r.name
            //KanbanBoard.fieldsBySObjectsWithoutName
            if (String.valueOf(fieldResult.getType()) == C_REFERENCE) { 
                String referenceTo = String.valueOf(fieldResult.referenceTo[0]).toLowerCase();
                Boolean isSpecialObject = KanbanBoard.fieldsBySObjectsWithoutName.containsKey(referenceTo);
                String fieldRelationshipName = isSpecialObject ?
                        fieldResult.getRelationshipName() + '.' + KanbanBoard.fieldsBySObjectsWithoutName.get(referenceTo) : 
                        fieldResult.getRelationshipName() + '.' + C_NAME;
                if (String.isNotBlank(fieldRelationshipName) && !qWrap.selectedFields.contains(fieldRelationshipName)) {
                    qWrap.selectedFields.add(fieldRelationshipName);
                }
            } else if (!qWrap.selectedFields.contains(qWrap.fieldToReadUpdate)) {
                qWrap.selectedFields.add(qWrap.fieldToReadUpdate);
            }
        }
        // Footer field limit is 2 so check if there are more than 2 fields are selected, show warning
        if (qWrap.selectedFooterFields != null && !qWrap.selectedFooterFields.isEmpty() && qWrap.selectedFooterFields.size() > 2) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Kanban_Card_Footer_Validation));
            return;
        }
        // Checking the footer fields is included in the selected field to prevent SOQL without retrieving error. If they are not added, they will be added automatically
        if (qWrap.selectedFooterFields != null && !qWrap.selectedFooterFields.isEmpty()) {
            for (String footerField : qWrap.selectedFooterFields) {
                if (!qWrap.selectedFields.contains(footerField)) {
                    qWrap.selectedFields.add(footerField);
                }
            }
        }
        // Checking the summarize by fields. Even if the user do not select summarize by fields at displayed fields, they will be added to the query automatically.
        if (qWrap.summarizeByList != null && !qWrap.summarizeByList.isEmpty()) {
            for (QueryEditor.SummarizeByWrapper sbw : qWrap.summarizeByList) {
                if (String.isNotBlank(sbw.fieldName) && sbw.fieldName != NONE && !qWrap.selectedFields.contains(sbw.fieldName)) {
                    qWrap.selectedFields.add(sbw.fieldName);
                }
            }
        }
        String selectedFields = String.join(qWrap.selectedFields, ',');
        // creating the basic soql and where condition will be added in order
        qWrap.wholeSoql = 'SELECT ' + selectedFields + ' FROM ' + qWrap.sobjectTypeName;
        String mainQuery = qWrap.wholeSoql;
        // Checking if filter logic is enabled and filled manually
        if (qWrap.enableFilterLogic && String.isBlank(qWrap.filterLogic)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Enter_Filter_Logic));
            return;
        }
        // whereconditioneditor will create necessary string based on entered filter criteria on UI
        String whereCondition = whereConditionEditor();
        if (String.isNotBlank(whereCondition)) {
            mainQuery += whereCondition;
        }
        // if order by is defined adding to the query
        String orderBy = qWrap.orderByList != null && !qWrap.orderByList.isEmpty() ? String.join(qWrap.orderByList, ',') : '';
        if (String.isNotBlank(orderBy)) {
            mainQuery += ' ORDER BY ' + orderBy;
        }
        // if the ordered in is defined, adding it to query. salesforce's default value is ASC for ordered in. Even if you do not define this parameter, it will work with ASC
        if (String.isNotBlank(qWrap.orderedIn) && qWrap.orderedIn != NONE) {
            mainQuery += ' ' + qWrap.orderedIn + ' ';
        }
        // if the null value is defined, adding it to query
        if (String.isNotBlank(qWrap.nullValues) && qWrap.nullValues != NONE) {
            mainQuery += ' ' + qWrap.nullValues + ' ';
        }
        // if the limit is defined, adding it to query
        if (String.isBlank(qWrap.queryLimit) || Integer.valueOf(qWrap.queryLimit) > 1000) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Collection_Size_Exceeded_Kanban));
            return;
        }
        String limitQuery = qWrap.queryLimit;
        if (String.isNotBlank(limitQuery) && Integer.valueOf(limitQuery) > 0) {
            mainQuery += ' LIMIT ' + limitQuery;
        }
        try {
            qEditor.queryWrapper.wholeSoql = mainQuery;
            // validating the query
            if (!Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName).getDescribe().isAccessible()) {
                ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Insufficient_Access + qEditor.queryWrapper.sobjectTypeName)
                );
                return;
            }
            Database.query(mainQuery);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, ' ' + Label.Query_Validated));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + e.getMessage()));
            return;
        }
    }

    /**
     * loop in the criteria wrapper and create a where condition string
     * @return
     */
    public String whereConditionEditor() {
        String whereCon = '';
        Map<Integer, String> filterMap = new Map<Integer, String>();
        for (QueryEditor.CriteriaWrapper cw : qEditor.queryWrapper.criteriaList) {
            if (cw.fieldName != NONE && cw.operator != null) {
                // if the order is 1 we should add 'WHERE' as first thing
                if (cw.order == 1) {
                    whereCon = ' WHERE ';
                }
                // if the order is greater than 1 and filter logic was not enabled we should add 'AND' to the string
                if (cw.order > 1 && !qEditor.queryWrapper.enableFilterLogic) {
                    whereCon += ' AND ';
                }
                // define the sempol from pre-defined map
                Map<String, String> operatorSembol = OperatorTypeCodes.getOperatorSembols();
                String symbol = String.escapeSingleQuotes(operatorSembol.get(cw.operator));
                // update the input value based on operator
                // For instance; If the selected operator is 'contains', input value will be %input%
                String inputValue = String.escapeSingleQuotes(cw.input);
                switch on cw.operator {
                    when 's' {
                        inputValue += '%';
                    }
                    when 'c', 'k' {
                        inputValue = '%' + inputValue + '%';
                    }
                }
                // update the input based on field type
                inputValue = cw.fieldType == C_PERCENT ||
                    cw.fieldType == C_DOUBLE ||
                    cw.fieldType == C_BOOLEAN
                    ? inputValue
                    : cw.fieldType == C_DATE
                            ? String.valueOf(cw.dateInput)
                            : cw.fieldType == C_DATETIME
                                    ? cw.dateTimeInput.format('yyyy-MM-dd\'T\'HH:mm:ss', UserInfo.getLocale()) + 'Z'
                                    : '\'' + String.escapeSingleQuotes(inputValue) + '\'';
                // if the selected operator is 'not contains', adding the whole input in (NOT input)
                String fieldName = cw.operator == 'k' ? ' ( NOT ' + String.escapeSingleQuotes(cw.fieldName) : String.escapeSingleQuotes(cw.fieldName);
                inputValue = cw.operator == 'k' ? inputValue + ' ) ' : inputValue;
                // if filter logic is not enabled, adding the string to the wherecondition. If the filter logic is enabled collecting the inputs in map to format string.

                if (!qEditor.queryWrapper.enableFilterLogic) {
                    whereCon += fieldName + symbol + inputValue;
                } else {
                    filterMap.put(cw.order, fieldName + symbol + inputValue);
                }
            }
        }

        //if filter logic is enabled and filtermap is populated, numbers will be replaced with the created values in the filtermap
        if (qEditor.queryWrapper.enableFilterLogic) {
            if (!filterMap.isEmpty()) {
                String filterLogicCondition = qEditor.queryWrapper.filterLogic;
                // Frist we need to define new key for our filter logic becuase it was giving error if Id include the value we have in order
                for (Integer i = 1; i <= filterMap.size(); i++) {
                    if (filterLogicCondition.contains(String.valueOf(i))) {
                        String newKey = C_COPADO + i + C_ORDER;
                        filterLogicCondition = filterLogicCondition.replace(String.valueOf(i), newKey);
                    }
                }
                // Real value replacement
                for (Integer i = 1; i <= filterMap.size(); i++) {
                    if (filterLogicCondition.contains(String.valueOf(i))) {
                        String newKey = C_COPADO + i + C_ORDER;
                        filterLogicCondition = filterLogicCondition.replace(newKey, filterMap.get(i));
                    }
                }
                whereCon += filterLogicCondition;
            }
        }
        return whereCon;
    }

    /**
     * it is re-populate the operator based on selected field type
     */
    public void getFieldOperators() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('cro');
        if (!String.isBlank(criteriaOrder)) {
            Integer listOrder = Integer.valueOf(criteriaOrder) - 1;
            if (!qEditor.queryWrapper.criteriaList.isEmpty() && qEditor.queryWrapper.criteriaList.size() > listOrder) {
                populateFilterCriteriaFields(listOrder);
            }
        }
    }

    /**
     * it is used to open/close filter logic
     * @return
     */
    public PageReference toggleLogic() {
        qEditor.queryWrapper.enableFilterLogic = qEditor.queryWrapper.enableFilterLogic == false;
        return null;
    }
}