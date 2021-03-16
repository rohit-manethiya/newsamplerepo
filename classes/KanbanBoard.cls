public with sharing class KanbanBoard {
    // Non Constants
    public static Boolean isReference { get; set; }
    public static Set<String> referenceFields {
        get {
            if (null == referenceFields) {
                referenceFields = new Set<String>();
            }
            return referenceFields;
        }
        set;
    }
    public Map<String, String> dataTypeByFields {
        get {
            if (null == dataTypeByFields) {
                dataTypeByFields = new Map<String, String>();
            }
            return dataTypeByFields;
        }
        set;
    }
    public Map<String, String> picklistValuesMap { get; set; }
    public Map<Integer, String> columnOrderMap { get; set; }
    public Map<String, List<SObject>> allRecordsMap { get; set; }
    public Map<String, Set<String>> cardDetailsMap { get; set; }
    public Map<Id, String> profileImageMap { get; set; }
    public Map<String, String> colorValueMap { get; set; }
    public Map<String, Integer> numberOfItemMap { get; set; }
    public Map<String, List<String>> newSummarizeByOperatorMap { get; set; }
    public Map<String, Map<String, Decimal>> summarizeInformationMap { get; set; }
    public static Map<String, String> fieldsBySObjectsWithoutName {
        get {
            if(null == fieldsBySObjectsWithoutName) {
                fieldsBySObjectsWithoutName = OperatorTypeCodes.getStdObjectsWithoutNameField();
            }
            return fieldsBySObjectsWithoutName;
        }
        set;
    }
    public static Map<String, String> referenceTo {
        get {
            if(null == referenceTo) {
                referenceTo = new Map<String,String>();
            }
            return referenceTo;
        }
        set;
    }
    public Map<String, QueryEditor.ColumnFilter> columnFilterMap { get; set; }

    public String nameReplacement { get; set; }
    public String userImageField { get; set; }
    public String cardColorField { get; set; }
    public String objectLabel { get; set; }
    public String sObjectName { get; set; }
    public String kbViewId { get; set; }
    public String selectedKanbanView { get; set; }
    public String queryEditorMode { get; set; }
    public String kanbanDescription { get; set; }
    public String fieldToReadUpdate { get; set; }
    public String namespace { get; set; }

    public List<String> footerFieldList { get; set; }

    public Schema.SObjectType sObjectType;
    public Schema.SObjectField theField { get; set; }
    public QueryEditor qEditor { get; set; }

    public Boolean showQueryEditor { get; set; }

    // Constants
    private final Kanban_Board__c kBoard;
    private static final String NAME_FIELDAPI = 'Name';
    private static final String REFERENCE_TYPE = 'REFERENCE';
    private static final String COMBOBOX_TYPE = 'COMBOBOX';
    private static final String PICKLIST_TYPE = 'PICKLIST';
    private static final String CUSTOM_FIELD_APPENDIX = '__c';
    private static final String CUSTOM_RELATION_APPENDIX = '__r';
    private static final String CUSTOM_RELATION_APPENDIX_ADDITION = '__r.';
    private static final String CUSTOM_FIELD_NAME_APPENDIX = '__r.name';
    private static final String SELECT_KEYWORD = ' SELECT ';
    private static final String FROM_KEYWORD = ' FROM ';
    private static final String COMMA = ',';

    public static String RECORDS_MOVED = Label.Records_Moved;
    private final String NONE = '--None--';
    private final String C_NAME = 'Name';
    private final String C_SUM = 'Sum';
    private final String C_MIN = 'Min';
    private final String C_MAX = 'Max';
    private final String C_AVERAGE = 'Average';
    private final String C_DEFAULT = 'default';
    private final String C_KBVIEWID = 'kbViewId';
    private final String C_EDIT = 'Edit';
    private final String C_ID = 'id';

    public KanbanBoard(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Kanban_Board__c.fields.getMap().keySet()));
        }
        // Getting the kanban record id from url
        this.kBoard = (Kanban_Board__c) stdController.getRecord();

        namespace = Settings.ns;

        // 'showQueryEditor' is used to hide and show query editor component in a modal
        showQueryEditor = false;

        if (String.isNotBlank(kBoard.Id)) {
            // Getting the kanban view record id from url. It is related to main kanban record. Each kanban can have many different sub view.
            kbViewId = ApexPages.currentPage().getParameters().get(C_KBVIEWID);

            // 'selectedKanbanView' is holding the current view id to render the values.
            selectedKanbanView = String.isNotBlank(kbViewId) ? kbViewId : C_DEFAULT;

            String mainQuery = '';
            String status = '';
            colorValueMap = new Map<String, String>();
            newSummarizeByOperatorMap = new Map<String, List<String>>();

            QueryEditor dummyQEditor = new QueryEditor();
            QueryEditor.SoqlWrapper dummySoqlJsonWrapper = new QueryEditor.SoqlWrapper();
            dummyQEditor.queryWrapper = dummySoqlJsonWrapper;

            populateDisplayTypeMaps();

            // If kanban view record is not empty, populating the kanban fields from kanban view otherwise getting the necessary values from real kanban record
            if (String.isNotBlank(kbViewId)) {
                if (Schema.SObjectType.Kanban_Board_View__c.isAccessible() && Schema.SObjectType.Kanban_Board_View__c.isQueryable()) {
                    Kanban_Board_View__c kbw = [SELECT Id, Name, SOQL_Json__c FROM Kanban_Board_View__c WHERE Id = :kbViewId];
                    if (String.isNotBlank(kbw.SOQL_Json__c)) {
                        jsonParser(dummyQEditor, kbw.SOQL_Json__c);
                        populateFieldsFromJson(dummyQEditor);
                        // Field_to_read_update__c field on kanban record is designed as 'Object API Name + . + Field API Name'
                        status = dummyQEditor.queryWrapper.sobjectTypeName + '.' + dummyQEditor.queryWrapper.fieldToReadUpdate;
                        mainQuery = String.isNotBlank(dummyQEditor.queryWrapper.wholeSoql) ? dummyQEditor.queryWrapper.wholeSoql : '';
                        kanbanDescription = String.isNotBlank(dummyQEditor.queryWrapper.kanbanDescription)
                            ? dummyQEditor.queryWrapper.kanbanDescription
                            : '';
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                    return;
                }
            } else {
                if (Schema.SObjectType.Kanban_Board__c.isAccessible() && Schema.SObjectType.Kanban_Board__c.isQueryable()) {
                    Kanban_Board__c kb = [
                        SELECT Id, Name, SOQL_Query__c, Field_to_read_update__c, JSON_Settings__c, Columns_SOQL__c, Description__c
                        FROM Kanban_Board__c
                        WHERE Id = :kBoard.Id
                    ];
                    mainQuery = kb.SOQL_Query__c;
                    status = kb.Field_to_read_update__c;
                    kanbanDescription = kb.Description__c;

                    if (String.isNotBlank(kb.JSON_Settings__c)) {
                        jsonParser(dummyQEditor, kb.JSON_Settings__c);
                        populateFieldsFromJson(dummyQEditor);
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                    return;
                }
            }

            columnFilterMap = dummyQEditor.queryWrapper.columnMap != null && !dummyQEditor.queryWrapper.columnMap.isEmpty()
                ? dummyQEditor.queryWrapper.columnMap
                : new Map<String, QueryEditor.ColumnFilter>();

            if (String.isNotBlank(mainQuery) && String.isNotBlank(dummyQEditor.queryWrapper.sobjectTypeName)) {
                mainQuery = preventDuplicateFields(mainQuery);
                // returning all values for kanban UI
                List<SObject> sObjectList = new List<SObject>();
                if (
                    Schema.getGlobalDescribe().get(dummyQEditor.queryWrapper.sobjectTypeName).getDescribe().isAccessible() &&
                    Schema.getGlobalDescribe().get(dummyQEditor.queryWrapper.sobjectTypeName).getDescribe().isQueryable()
                ) {
                    sObjectList = Database.query(mainQuery);
                }

                if (!sObjectList.isEmpty()) {
                    Set<String> userIdSet = new Set<String>();
                    Set<String> colorFieldValueSet = new Set<String>();
                    profileImageMap = new Map<Id, String>();

                    for (SObject sObj : sObjectList) {
                        // Collecting the user lookup field in a set to populate image of the owner
                        if (
                            String.isNotBlank(userImageField) &&
                            mainQuery.contains(userImageField) &&
                            userImageField != NONE &&
                            String.valueOf(sObj.get(userImageField)) != null
                        ) {
                            userIdSet.add(String.valueOf(sObj.get(userImageField)));
                        }
                        // Collecting the value for the selected color field for kanban cards
                        if (
                            String.isNotBlank(cardColorField) &&
                            mainQuery.contains(cardColorField) &&
                            cardColorField != NONE &&
                            String.valueOf(sObj.get(cardColorField)) != null
                        ) {
                            colorFieldValueSet.add(String.valueOf(sObj.get(cardColorField)));
                        }
                    }
                    
                    if (!userIdSet.isEmpty() && Schema.SObjectType.User.isAccessible() && Schema.SObjectType.User.isQueryable()) {
                        // Populating owner image
                        for (User userRecord : [SELECT Id, SmallPhotoUrl FROM User WHERE Id IN :userIdSet]) {
                            if (!profileImageMap.containsKey(userRecord.Id)) {
                                profileImageMap.put(userRecord.Id, userRecord.SmallPhotoUrl);
                            }
                        }
                    }
                    if (!colorFieldValueSet.isEmpty()) {
                        // Populating dynamic color code for owner of the each record
                        colorValueMap = userColorAssignment(colorFieldValueSet);
                    }

                    // get the SObjectType
                    sObjectType = sObjectList.getSObjectType();
                    sObjectName = sObjectType.getDescribe().getName();

                    // Some standard salesforce object do not have Name field so checking the existing map and returning the defined fields for those object
                    nameReplacement = fieldsBySObjectsWithoutName.containsKey(sObjectName.toLowerCase())
                        ? fieldsBySObjectsWithoutName.get(sObjectName.toLowerCase())
                        : nameReplacement;

                    nameReplacement = nameReplacement.toLowerCase();

                    // this can accept list of strings, we describe only one object here
                    List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(
                        new List<String>{ String.valueOf(sObjectType) }
                    );
                    if (!describeSobjectsResult.isEmpty()) {
                        // Defining the sobject label
                        objectLabel = describeSobjectsResult[0].getLabel();
                    }
                    // get the fields on the object
                    Map<String, SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

                    if (String.isNotBlank(status)) {
                        // Field to Read/Update defined with '.' so we have to split and take the second item to define field
                        theField = !status.split('\\.').isEmpty() ? fieldMap.get(status.split('\\.')[1]) : null;
                        if (theField != null) {
                            Schema.DescribeFieldResult fieldResult = theField.getDescribe();
                            fieldToReadUpdate = fieldResult.getName();
                            // Get new instance of maps
                            getNewInstanceOfMaps();
                            isReference = false;
                            // Note: Combobox is similar to picklist field but you can define new value for it. For example; Subject field of Event object.
                            if (String.valueOf(fieldResult.getType()) == PICKLIST_TYPE || String.valueOf(fieldResult.getType()) == COMBOBOX_TYPE) {
                                List<Schema.PicklistEntry> recordsPicklistValues = fieldResult.getPicklistValues();
                                fetchRecords(sObjectList, recordsPicklistValues);
                            } else if (String.valueOf(fieldResult.getType()) == REFERENCE_TYPE) {
                                isReference = true;
                                fieldResult.getPicklistValues();
                                fetchRecords(sObjectList, theField);
                            }

                            if (dummyQEditor.queryWrapper.columnMap != null && !dummyQEditor.queryWrapper.columnMap.isEmpty()) {
                                updateColumnOrderMap(dummyQEditor.queryWrapper.columnMap.values());
                            }
                        }
                    }
                }
            }
        }
    }
    /**
     * query modifier for look up fields
     * @param mainQuery
     * @return mainQuery
     */
    private static String preventDuplicateFields(String mainQuery) {
        List<String> queryParts = mainQuery.split(FROM_KEYWORD);
        String querySelectPart = queryParts[0].toLowerCase();
        for (String referenceField : referenceFields) {
            String replacementTarget = returnReplacementTarget(referenceTo.get(referenceField));
            if (referenceField.contains(CUSTOM_FIELD_APPENDIX)) {
                querySelectPart = querySelectPart.replaceFirst(
                    referenceField, 
                    referenceField.replace(CUSTOM_FIELD_APPENDIX, replacementTarget) +
                    COMMA +
                    referenceField
                );
            }
        }
        Set<String> queryField = new Set<String>(querySelectPart.toLowerCase().split(COMMA));
        return String.join(new List<String>(queryField), COMMA) + FROM_KEYWORD.toLowerCase() + queryParts[1];
    }

    /**
     * populates dataTypeByFields and referenceFields variables to use on the page
     */
    private void populateDisplayTypeMaps() {
        //Test.isRunning test is in place to prevent code crash because of stdController.addFields on constructor
        if (!Test.isRunningTest() && String.isNotBlank(this.kBoard.Field_to_read_update__c)) {
            String objectName = this.kBoard.Field_to_read_update__c.split('\\.')[0];
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            for (String fieldName : fieldMap.keySet()) {
                DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
                String fieldType = String.valueOf(fieldResult.getType());
                dataTypeByFields.put(fieldName, fieldType);
                if (fieldType == REFERENCE_TYPE) {
                    referenceTo.put(fieldName, String.valueOf(fieldResult.getReferenceTo()[0]).toLowerCase());
                    referenceFields.add(fieldName);
                }
            }
        }
    }

    /**
     * generic json parser for qeditor wrapper class
     * @param dummyQEditor
     * @param jsonString
     */
    private void jsonParser(QueryEditor dummyQEditor, String jsonString) {
        if (String.isNotBlank(jsonString)) {
            // Parse entire JSON response.
            JSONParser parser = JSON.createParser(jsonString);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    while (parser.nextToken() != null) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            dummyQEditor.queryWrapper = (QueryEditor.SoqlWrapper) parser.readValueAs(QueryEditor.SoqlWrapper.class);
                            parser.skipChildren();
                        }
                    }
                }
            }
        }
    }

    /**
     * after parsing the json populating the qEditor wrapper class fields
     * @param dummyQEditor
     */
    private void populateFieldsFromJson(QueryEditor dummyQEditor) {
        if (dummyQEditor.queryWrapper.summarizeByList != null && !dummyQEditor.queryWrapper.summarizeByList.isEmpty()) {
            for (QueryEditor.SummarizeByWrapper sbw : dummyQEditor.queryWrapper.summarizeByList) {
                if (String.isNotBlank(sbw.fieldName) && sbw.fieldName != NONE && String.isNotBlank(sbw.operatorName) && sbw.operatorName != NONE) {
                    if (!newSummarizeByOperatorMap.containsKey(sbw.fieldName)) {
                        List<String> oprList = new List<String>{ sbw.operatorName };
                        newSummarizeByOperatorMap.put(sbw.fieldName, oprList);
                    } else {
                        newSummarizeByOperatorMap.get(sbw.fieldName).add(sbw.operatorName);
                    }
                }
            }
        }
        String headerField = dummyQEditor.queryWrapper.headerField;
        String uImageField = dummyQEditor.queryWrapper.userImageField;
        String colorField = dummyQEditor.queryWrapper.colorField;
        String footerFields = String.valueOf(dummyQEditor.queryWrapper.selectedFooterFields);
        //lowerCase is crucial here for below fields since mainQuery has its all fields lowercased before to compare
        nameReplacement = String.isNotBlank(headerField) && headerField != NONE ? headerField.toLowerCase() : C_NAME;
        userImageField = String.isNotBlank(uImageField) && uImageField != NONE ? uImageField.toLowerCase() : '';
        cardColorField = String.isNotBlank(colorField) && colorField != NONE ? colorField.toLowerCase() : '';
        footerFieldList = String.isNotBlank(footerFields) && footerFields != '()'
            ? footerFields.toLowerCase().replace('(', '').replace(' ', '').replace(')', '').split(',')
            : new List<String>();
    }

    /**
     * it is used to get new instance of maps
     */
    private void getNewInstanceOfMaps() {
        allRecordsMap = new Map<String, List<SObject>>();
        cardDetailsMap = new Map<String, Set<String>>();
        picklistValuesMap = new Map<String, String>();
        columnOrderMap = new Map<Integer, String>();
        numberOfItemMap = new Map<String, Integer>();
    }

    /**
     * fetching the records based on reference type fields
     * @param sObjectsList
     * @param theField
     */
    private void fetchRecords(List<SObject> sObjectsList, Schema.SObjectField theField) {
        Integer columnOrderNumber = 0;

        for (SObject so : sObjectsList) {
            if (String.valueOf(so.getSObject(theField)) != null && String.valueOf(so.getSObject(theField).get(C_NAME)) != null) {
                allRecordsMap.put(String.valueOf(so.getSObject(theField).get(C_NAME)), new List<SObject>());
                picklistValuesMap.put(String.valueOf(so.getSObject(theField).get(C_NAME)), String.valueOf(so.getSObject(theField).get('Id')));
                if (!columnFilterMap.containsKey(String.valueOf(so.getSObject(theField).get(C_NAME)))) {
                    columnFilterMap.put(
                        String.valueOf(so.getSObject(theField).get(C_NAME)),
                        new QueryEditor.ColumnFilter(String.valueOf(so.getSObject(theField).get(C_NAME)), columnOrderNumber)
                    );
                    columnOrderMap.put(columnOrderNumber, String.valueOf(so.getSObject(theField).get(C_NAME)));
                    columnOrderNumber++;
                }
            }
        }

        for (SObject so : sObjectsList) {
            if (String.valueOf(so.getSObject(theField)) != null && String.valueOf(so.getSObject(theField).get(C_NAME)) != null) {
                if (!allRecordsMap.containsKey(String.valueOf(so.getSObject(theField).get(C_NAME)))) {
                    allRecordsMap.put(String.valueOf(so.getSObject(theField).get(C_NAME)), new List<SObject>{ so });
                } else {
                    allRecordsMap.get(String.valueOf(so.getSObject(theField).get(C_NAME))).add(so);
                }
            }
        }
        fillCardDetails();
    }

    /**
     * fetching the records based on picklist type fields
     * @param sObjectsList
     * @param recordsPicklistValues
     */
    private void fetchRecords(List<SObject> sObjectsList, List<Schema.PicklistEntry> recordsPicklistValues) {
        Integer columnOrderNumber = 0;
        for (Schema.PicklistEntry ple : recordsPicklistValues) {
            allRecordsMap.put(ple.value, new List<SObject>());
            picklistValuesMap.put(ple.value, ple.label);
            if (!columnFilterMap.containsKey(ple.value)) {
                columnFilterMap.put(ple.value, new QueryEditor.ColumnFilter(ple.value, columnOrderNumber));
                columnOrderMap.put(columnOrderNumber, ple.value);
                columnOrderNumber++;
            }
        }

        for (SObject so : sObjectsList) {
            if (!allRecordsMap.containsKey(String.valueOf(so.get(theField)))) {
                allRecordsMap.put(String.valueOf(so.get(theField)), new List<SObject>{ so });
            } else {
                allRecordsMap.get(String.valueOf(so.get(theField))).add(so);
            }
        }
        fillCardDetails();
    }

    /**
     * adjusting the field to show in the kanban board card body. If field is used in the footer and summarize removing from the body.
     */
    private void fillCardDetails() {
        Map<String, SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
        for (String keyValue : allRecordsMap.keySet()) {
            numberOfItemMap.put(keyValue, allRecordsMap.get(keyValue).size());
            for (Integer i = 0; i < allRecordsMap.get(keyValue).size(); i++) {
                Set<String> populatedFieldsSet = new Set<String>();
                for (String fieldName : allRecordsMap.get(keyValue)[i].getPopulatedFieldsAsMap().keySet()) {
                    if (fieldMap.containsKey(fieldName) && !footerFieldList.contains(fieldName)) {
                        populatedFieldsSet.add(fieldName);
                    }
                }
                cardDetailsMap.put(allRecordsMap.get(keyValue)[i].Id, populatedFieldsSet);
            }
        }
        if (!newSummarizeByOperatorMap.isEmpty()) {
            calculateSummarizeFieldValues();
        }
    }

    /**
     * Calculating summarize infromation for selected fields.
     */
    private void calculateSummarizeFieldValues() {
        summarizeInformationMap = new Map<String, Map<String, Decimal>>();
        for (String statusValue : picklistValuesMap.keySet()) {
            Map<String, Decimal> informationMap = new Map<String, Decimal>();
            for (Integer i = 0; i < allRecordsMap.get(statusValue).size(); i++) {
                for (String fieldApiName : newSummarizeByOperatorMap.keySet()) {
                    for (String opr : newSummarizeByOperatorMap.get(fieldApiName)) {
                        Decimal decimalNumber = allRecordsMap.get(statusValue)[i].get(fieldApiName) != null
                            ? (Decimal) allRecordsMap.get(statusValue)[i].get(fieldApiName)
                            : 0;
                        String summarizeKey = opr + fieldApiName;
                        if (!informationMap.containsKey(summarizeKey) && opr == C_SUM) {
                            informationMap.put(summarizeKey, decimalNumber.setScale(2));
                        } else if (informationMap.containsKey(summarizeKey) && opr == C_SUM) {
                            Decimal existingSum = informationMap.get(summarizeKey);
                            informationMap.put(summarizeKey, (decimalNumber + existingSum).setScale(2));
                        } else if (!informationMap.containsKey(summarizeKey) && opr == C_MIN) {
                            informationMap.put(summarizeKey, decimalNumber.setScale(2));
                        } else if (informationMap.containsKey(summarizeKey) && opr == C_MIN) {
                            Decimal existingMinValue = informationMap.get(summarizeKey);
                            Decimal newMinValue = decimalNumber > existingMinValue ? existingMinValue : decimalNumber;
                            informationMap.put(summarizeKey, newMinValue.setScale(2));
                        } else if (!informationMap.containsKey(summarizeKey) && opr == C_MAX) {
                            informationMap.put(summarizeKey, decimalNumber.setScale(2));
                        } else if (informationMap.containsKey(summarizeKey) && opr == C_MAX) {
                            Decimal existingMaxValue = informationMap.get(summarizeKey);
                            Decimal newMaxValue = decimalNumber < existingMaxValue ? existingMaxValue : decimalNumber;
                            informationMap.put(summarizeKey, newMaxValue.setScale(2));
                        } else if (!informationMap.containsKey(summarizeKey) && opr == C_AVERAGE) {
                            Decimal existingValue = decimalNumber;
                            informationMap.put(
                                summarizeKey,
                                existingValue != 0 ? (existingValue / allRecordsMap.get(statusValue).size()).setScale(2) : 0
                            );
                        } else if (informationMap.containsKey(summarizeKey) && opr == C_AVERAGE) {
                            Decimal existingAverageValue = informationMap.get(summarizeKey);
                            Decimal newValue = decimalNumber;
                            Decimal newAverageValue = newValue != 0 ? (newValue / allRecordsMap.get(statusValue).size()) : 0;
                            informationMap.put(summarizeKey, (existingAverageValue + newAverageValue).setScale(2));
                        }
                    }
                }
            }
            summarizeInformationMap.put(statusValue, informationMap);
        }
    }

    /**
     *  Wrapper class to override error message
     */
    public class UpdateStatus {
        public Boolean isSuccess;
        public String message;
    }

    @RemoteAction
    public static UpdateStatus updateRecordsPicklistValue(Id recordId, String newPicklistValue, String fieldToUpdate, String nameReplacementField) {
        DescribeSObjectResult describeResult = recordId.getSobjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        DescribeFieldResult updateFieldDescribe = fieldMap.get(fieldToUpdate).getDescribe(),
            headerFieldDescribe = fieldMap.get(nameReplacementField).getDescribe();
        String fieldReference,
            headerReference,
            replacementTarget,
            query = SELECT_KEYWORD + String.join(fieldNames, COMMA) + FROM_KEYWORD + describeResult.getName() + ' WHERE Id = :recordId LIMIT 1';

        Boolean isHeaderReference = String.valueOf(headerFieldDescribe.getType()) == REFERENCE_TYPE;
        isReference = String.valueOf(updateFieldDescribe.getType()) == REFERENCE_TYPE;
        fieldToUpdate = fieldToUpdate.toLowerCase();
        //add name reference to the query for kanban header field
        if (isReference) {
            fieldReference = String.valueOf(updateFieldDescribe.getReferenceTo()[0]).toLowerCase();
            replacementTarget = returnReplacementTarget(fieldReference);
            query = query.replaceFirst(
                fieldToUpdate,
                fieldToUpdate.replace(CUSTOM_FIELD_APPENDIX.toLowerCase(), replacementTarget) +
                COMMA +
                fieldToUpdate
            );
        }
        //add name reference to the query for card header field
        if (isHeaderReference) {
            headerReference = String.valueOf(headerFieldDescribe.getReferenceTo()[0]).toLowerCase();
            replacementTarget = returnReplacementTarget(headerReference);
            query = query.replaceFirst(
                nameReplacementField,
                nameReplacementField.replace(CUSTOM_FIELD_APPENDIX.toLowerCase(), replacementTarget) +
                COMMA +
                nameReplacementField
            );
        }
        // return generic list of sobjects or typecast to expected type
        List<SObject> records = new List<SObject>();
        if (Schema.getGlobalDescribe().get(describeResult.getName()).getDescribe().isQueryable()) {
            records = Database.query(preventDuplicateFields(query));
        }

        UpdateStatus updatedUSDetails = new UpdateStatus();
        if (!records.isEmpty()) {
            try {
                String referenceName = newPicklistValue;
                if (isReference) {
                    String lookupFieldObjectName = updateFieldDescribe.getReferenceTo()[0].getDescribe().getName();
                    newPicklistValue = Database.query(
                            'SELECT Id, Name FROM ' +
                            String.escapeSingleQuotes(lookupFieldObjectName) +
                            ' WHERE Name =: newPicklistValue LIMIT 1 '
                        )
                        .Id;
                }
                records[0].put(fieldToUpdate, newPicklistValue);
                Utilities.Secure_DML(records, Utilities.DML_Action.UPD, describeResult);

                updatedUSDetails.isSuccess = true;
                updatedUSDetails.message = String.format(
                    RECORDS_MOVED,
                    new List<String>{
                        String.valueOf(
                            isHeaderReference
                                ? records[0]
                                      .getSObject(nameReplacementField.replace(CUSTOM_FIELD_APPENDIX, CUSTOM_RELATION_APPENDIX))
                                      .get(NAME_FIELDAPI)
                                : records[0].get(nameReplacementField)
                        ),
                        referenceName
                    }
                );
            } catch (Exception e) {
                updatedUSDetails.isSuccess = false;
                updatedUSDetails.message = e.getMessage();
            }
        }
        return updatedUSDetails;
    }

    /**
     * to retrieve available kanban views based on main kanban board
     * @return
     */
    public List<SelectOption> getKanbanViews() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(C_DEFAULT, 'Default'));
        if (Schema.SObjectType.Kanban_Board_View__c.isAccessible() && Schema.SObjectType.Kanban_Board_View__c.isQueryable()) {
            for (Kanban_Board_View__c kbw : [SELECT Id, Name FROM Kanban_Board_View__c WHERE Kanban_Board__c = :kBoard.Id]) {
                options.add(new SelectOption(kbw.Id, kbw.Name));
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
            return null;
        }
        return options;
    }

    /**
     * it is used at Editing the kanban board json
     * @return
     */
    public PageReference applyChanges() {
        PageReference pReference = Page.KanbanBoardView;
        if (String.isNotBlank(kBoard.Id)) {
            pReference.getParameters().put('id', kBoard.Id);
        }
        pReference.setRedirect(true);
        validations();
        try {
            Database.query(qEditor.queryWrapper.wholeSoql);
            if (String.isNotBlank(kbViewId)) {
                Kanban_Board_View__c kbw = new Kanban_Board_View__c();
                for (QueryEditor.CriteriaWrapper cw : qEditor.queryWrapper.criteriaList) {
                    cw.operatorSet = null;
                }
                if (Schema.SObjectType.Kanban_Board_View__c.isAccessible() && Schema.SObjectType.Kanban_Board_View__c.isQueryable()) {
                    kbw = [SELECT Id, Name, Kanban_Board__c, SOQL_Json__c FROM Kanban_Board_View__c WHERE Id = :kbViewId];
                    if (
                        !Schema.SObjectType.Kanban_Board_View__c.fields.Name.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board_View__c.fields.SOQL_Json__c.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board_View__c.fields.Kanban_Board__c.isUpdateable()
                    ) {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                        return null;
                    }
                    kbw.Name = String.isNotBlank(qEditor.queryWrapper.viewName) ? qEditor.queryWrapper.viewName : Label.New_Kanban_View;
                    kbw.SOQL_Json__c = JSON.serialize(qEditor);
                    kbw.Kanban_Board__c = kBoard.Id;
                    Utilities.Secure_DML(kbw, Utilities.DML_Action.UPD, schema.SObjectType.Kanban_Board_View__c);
                    if (String.isNotBlank(kbw.Id)) {
                        pReference.getParameters().put(C_KBVIEWID, kbw.Id);
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                    return null;
                }
                return pReference;
            } else {
                if (Schema.SObjectType.Kanban_Board__c.isAccessible() && Schema.SObjectType.Kanban_Board__c.isQueryable()) {
                    // updating new kanban record
                    Kanban_Board__c kb = [
                        SELECT Id, Name, SOQL_Query__c, Description__c, Field_to_read_update__c, JSON_Settings__c
                        FROM Kanban_Board__c
                        WHERE Id = :kBoard.Id
                    ];
                    if (
                        !Schema.SObjectType.Kanban_Board__c.fields.Name.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board__c.fields.SOQL_Query__c.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board__c.fields.Description__c.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board__c.fields.Field_to_read_update__c.isUpdateable() &&
                        !Schema.SObjectType.Kanban_Board__c.fields.JSON_Settings__c.isUpdateable()
                    ) {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                        return null;
                    }
                    kb.Name = String.isNotBlank(qEditor.queryWrapper.viewName) ? qEditor.queryWrapper.viewName : Label.New_Kanban_View;
                    kb.SOQL_Query__c = String.isNotBlank(qEditor.queryWrapper.wholeSoql) ? qEditor.queryWrapper.wholeSoql : '';
                    kb.Description__c = String.isNotBlank(qEditor.queryWrapper.kanbanDescription) ? qEditor.queryWrapper.kanbanDescription : '';
                    String fieldReadUpdate = qEditor.queryWrapper.sobjectTypeName + '.' + qEditor.queryWrapper.fieldToReadUpdate;
                    kb.Field_to_read_update__c = fieldReadUpdate;
                    for (QueryEditor.CriteriaWrapper cw : qEditor.queryWrapper.criteriaList) {
                        cw.operatorSet = null;
                    }
                    kb.JSON_Settings__c = JSON.serialize(qEditor);
                    Utilities.Secure_DML(kb, Utilities.DML_Action.UPD, schema.SObjectType.Kanban_Board__c);
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                    return null;
                }
                return pReference;
            }
        } catch (Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
        return null;
    }

    /**
     * necessary validations to avoid possible errors on the VF page
     */
    private void validations() {
        if (
            String.isBlank(qEditor.queryWrapper.fieldToReadUpdate) ||
            (String.isNotBlank(qEditor.queryWrapper.fieldToReadUpdate) && qEditor.queryWrapper.fieldToReadUpdate == NONE)
        ) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Select_Read_Update_Field);
            return;
        }
        if (
            qEditor.queryWrapper.selectedFooterFields != null && !qEditor.queryWrapper.selectedFooterFields.isEmpty() &&
            qEditor.queryWrapper.selectedFooterFields.size() > 2
        ) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Kanban_Card_Footer_Validation);
            return;
        }
        if (qEditor.queryWrapper.enableFilterLogic && String.isBlank(qEditor.queryWrapper.filterLogic)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Enter_Filter_Logic);
            return;
        }
    }

    /**
     * it is used to create new view
     * @return
     */
    public PageReference saveAsNew() {
        PageReference pReference = Page.KanbanBoardView;
        if (String.isNotBlank(kBoard.Id)) {
            pReference.getParameters().put(C_ID, kBoard.Id);
        }
        pReference.setRedirect(true);
        validations();
        try {
            Database.query(qEditor.queryWrapper.wholeSoql);
            Kanban_Board_View__c kbw = new Kanban_Board_View__c();
            for (QueryEditor.CriteriaWrapper cw : qEditor.queryWrapper.criteriaList) {
                cw.operatorSet = null;
            }
            if (
                !Schema.SObjectType.Kanban_Board_View__c.fields.Name.isCreateable() &&
                !Schema.SObjectType.Kanban_Board_View__c.fields.SOQL_Json__c.isCreateable() &&
                !Schema.SObjectType.Kanban_Board_View__c.fields.Kanban_Board__c.isCreateable()
            ) {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                return null;
            }
            kbw.Name = String.isNotBlank(qEditor.queryWrapper.viewName) ? qEditor.queryWrapper.viewName : Label.New_Kanban_View;
            kbw.SOQL_Json__c = JSON.serialize(qEditor);
            kbw.Kanban_Board__c = kBoard.Id;
            Utilities.Secure_DML(kbw, Utilities.DML_Action.INS, schema.SObjectType.Kanban_Board_View__c);
            if (String.isNotBlank(kbw.Id)) {
                pReference.getParameters().put(C_KBVIEWID, kbw.Id);
            }
            return pReference;
        } catch (Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
        return null;
    }

    /**
     * it is used to populate the wrapper class to open editor component correctly
     */
    public void kanbanViewsActions() {
        qEditor = new QueryEditor();
        QueryEditor.SoqlWrapper soqlJsonWrapper = new QueryEditor.SoqlWrapper();
        qEditor.queryWrapper = soqlJsonWrapper;
        qEditor.queryWrapper.sobjectTypeName = sObjectName;
        qEditor.queryJson = '';

        queryEditorMode = ApexPages.currentPage().getParameters().get('kanbanView');

        String jsonToParse = '';

        // if component mode is equal to edit and kanban view id is not null it will parse the json to auto populate query editor
        if (queryEditorMode == C_EDIT && String.isNotBlank(kbViewId)) {
            if (Schema.SObjectType.Kanban_Board_View__c.isAccessible() && Schema.SObjectType.Kanban_Board_View__c.isQueryable()) {
                jsonToParse = [SELECT Id, SOQL_Json__c FROM Kanban_Board_View__c WHERE Id = :kbViewId].SOQL_Json__c;
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                return;
            }
        } else if (queryEditorMode == C_EDIT && String.isBlank(kbViewId) && String.isNotBlank(kBoard.Id)) {
            // retrieve the kanban record to populate fields
            if (Schema.SObjectType.Kanban_Board__c.isAccessible() && Schema.SObjectType.Kanban_Board__c.isQueryable()) {
                jsonToParse = [SELECT Id, JSON_Settings__c FROM Kanban_Board__c WHERE Id = :kBoard.Id].JSON_Settings__c;
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                return;
            }
        }

        if (String.isNotBlank(jsonToParse)) {
            jsonParser(qEditor, jsonToParse);
        }
        // We can not serialize selectoption to json so we cleared them before. We have to call a function to auto populate possible actions based on selected type at the filter criteria
        if (qEditor.queryWrapper.criteriaList != null) {
            for (Integer i = 0; i < qEditor.queryWrapper.criteriaList.size(); i++) {
                populateFilterCriteriaFields(i);
            }
        }
        // If summarize by list is empty, get new instance to prevent null point error in the query editor component
        if (qEditor.queryWrapper.summarizeByList == null) {
            qEditor.queryWrapper.summarizeByList = new List<QueryEditor.SummarizeByWrapper>();
        }
        showQueryEditor = true;
    }

    /**
     * populate operator set field of qEditor.
     * @param listOrder
     */
    private void populateFilterCriteriaFields(Integer listOrder) {
        if (String.isNotBlank(qEditor.queryWrapper.sobjectTypeName)) {
            String criteriaField = qEditor.queryWrapper.criteriaList[listOrder].fieldName;
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(qEditor.queryWrapper.sobjectTypeName);
            Schema.DescribeSObjectResult dsr = convertType.getDescribe();
            Schema.DescribeFieldResult fields = null;
            if (String.isNotBlank(criteriaField) && criteriaField != NONE) {
                try {
                    fields = dsr.fields.getMap().get(criteriaField).getDescribe();
                } catch (Exception exc) {
                    UIDesignHelper.genericWarningMessage(
                        ApexPages.Severity.WARNING,
                        ' (' +
                        criteriaField +
                        ') ' +
                        Label.Unsupported_Value_In_Filter_Criteria
                    );
                }
            }
            // checking if the field is defined and field type is included in type operator map. If there is not defined type it will always return STRING
            Map<String, String[]> type2ops = OperatorTypeCodes.getTypeToOps();
            String fType = fields != null && type2ops.containsKey(String.valueOf(fields.getType()).toUpperCase())
                ? String.valueOf(fields.getType()).toUpperCase()
                : 'STRING';
            qEditor.queryWrapper.criteriaList[listOrder].fieldType = fType;
            List<SelectOption> criteriaOptions = new List<SelectOption>();
            criteriaOptions.add(new SelectOption(NONE, NONE));
            // updating the existing operator set based on selected type on the UI
            Map<String, String> operatorCodes = OperatorTypeCodes.getOperatorCodes();
            for (String opt : type2ops.get(fType)) {
                if (operatorCodes.containsKey(opt)) {
                    criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                }
            }
            qEditor.queryWrapper.criteriaList[listOrder].operatorSet = criteriaOptions;
        }
    }

    /**
     * it is used to load selected view
     * @return
     */
    public PageReference changeView() {
        PageReference pReference = Page.KanbanBoardView;
        if (String.isNotBlank(kBoard.Id)) {
            pReference.getParameters().put(C_ID, kBoard.Id);
        }
        if (String.isNotBlank(selectedKanbanView) && selectedKanbanView != C_DEFAULT) {
            pReference.getParameters().put(C_KBVIEWID, selectedKanbanView);
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * it is used to delete view
     * @return
     */
    public PageReference deleteView() {
        if (
            String.isNotBlank(selectedKanbanView) &&
            selectedKanbanView != C_DEFAULT &&
            Schema.SObjectType.Kanban_Board_View__c.isAccessible() &&
            Schema.SObjectType.Kanban_Board_View__c.isQueryable()
        ) {
            Kanban_Board_View__c kbw = [SELECT Id FROM Kanban_Board_View__c WHERE Id = :selectedKanbanView];
            Utilities.Secure_DML(kbw, Utilities.DML_Action.DEL, schema.SObjectType.Kanban_Board_View__c);
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
            return null;
        }

        PageReference pReference = Page.KanbanBoardView;
        if (String.isNotBlank(kBoard.Id)) {
            pReference.getParameters().put(C_ID, kBoard.Id);
        }
        pReference.setRedirect(true);
        return pReference;
    }
    /**
     * defines api name of the name field based on the selected look up field's referenceTo object
     * @param fieldName
     * @return 
     */
    private static String returnReplacementTarget(String fieldName) {
        return fieldsBySObjectsWithoutName.containsKey(fieldName) ? 
                    CUSTOM_RELATION_APPENDIX_ADDITION + fieldsBySObjectsWithoutName.get(fieldName) : 
                    CUSTOM_FIELD_NAME_APPENDIX.toLowerCase();
    }

    /**
     * it is used to generate random color for selected fields
     * @param colors
     * @return
     */
    private String generateCustomHexColor(Set<String> colors) {
        String letters = '0123456789ABCDEF';
        String colorCode = '#';
        for (Integer i = 0; i < 6; i++) {
            colorCode += letters.mid(Integer.valueOf(Math.floor(Math.random() * 16)), 1);
        }
        return !colors.contains(colorCode) ? colorCode : generateCustomHexColor(colors);
    }

    private Map<String, String> userColorAssignment(Set<String> colorValueSet) {
        Map<String, String> assignments = new Map<String, String>();
        Set<String> colorCodes = new Set<String>();
        for (String val : colorValueSet) {
            String colorCode = generateCustomHexColor(colorCodes);
            assignments.put(val, colorCode);
        }
        return assignments;
    }

    /**
     * It is used to update columnOrderMap with existing values in stored json.
     *
     * @param filterValue stored json values
     */
    private void updateColumnOrderMap(List<QueryEditor.ColumnFilter> filterValue) {
        Integer newOrderForOldData = 0;
        for (QueryEditor.ColumnFilter columnFilter : filterValue) {
            if (columnFilter.orderNumber != null) {
                columnOrderMap.put(columnFilter.orderNumber, columnFilter.columnValue);
            } else {
                columnOrderMap.put(newOrderForOldData, columnFilter.columnValue);
                newOrderForOldData++;
            }
        }
        initMaps(columnOrderMap);
    }

    /**
     * In use to init repeat maps to prevent page crash on look up filters
     *
     * @param columnOrderMap possible Kanban column order, values pairs
     */
    private void initMaps(Map<Integer, String> columnOrderMap) {
        for (String recordsMapKey : columnOrderMap.values()) {
            if (!allRecordsMap.containsKey(recordsMapKey)) {
                allRecordsMap.put(recordsMapKey, new List<SObject>());
            }
            if (!numberOfItemMap.containsKey(recordsMapKey)) {
                numberOfItemMap.put(recordsMapKey, 0);
            }
        }
    }

    /**
     * it is used to add selected column values to the existing json of kanban view
     */
    public void updateJsonToHideColum() {
        String headerReference = ApexPages.currentPage().getParameters().get('isReference');
        if (String.isNotBlank(headerReference)) {
            isReference = Boolean.valueOf(headerReference);
        }
        QueryEditor dummyQEditor = new QueryEditor();
        QueryEditor.SoqlWrapper dummySoqlJsonWrapper = new QueryEditor.SoqlWrapper();
        dummyQEditor.queryWrapper = dummySoqlJsonWrapper;

        Set<Integer> orderNumberSet = new Set<Integer>();
        for (QueryEditor.ColumnFilter columnFilter : columnFilterMap.values()) {
            if (columnFilter.orderNumber != null) {
                if (!orderNumberSet.contains(columnFilter.orderNumber)) {
                    orderNumberSet.add(columnFilter.orderNumber);
                } else {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Not_Enter_Same_Order);
                    return;
                }

                if (columnFilter.orderNumber < 0) {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Not_Enter_Negative_Order);
                    return;
                }
            }
        }

        if (String.isNotBlank(kbViewId)) {
            if (Schema.SObjectType.Kanban_Board_View__c.isAccessible() && Schema.SObjectType.Kanban_Board_View__c.isQueryable()) {
                List<Kanban_Board_View__c> kbwList = [SELECT Id, SOQL_Json__c FROM Kanban_Board_View__c WHERE Id = :kbViewId LIMIT 1];
                if (!Schema.SObjectType.Kanban_Board_View__c.fields.SOQL_Json__c.isUpdateable()) {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                    return;
                }
                if (!kbwList.isEmpty()) {
                    jsonParser(dummyQEditor, kbwList[0].SOQL_Json__c);
                    dummyQEditor.queryWrapper.columnMap = columnFilterMap;
                    kbwList[0].SOQL_Json__c = JSON.serialize(dummyQEditor);
                    Utilities.Secure_DML(kbwList, Utilities.DML_Action.UPD, schema.SObjectType.Kanban_Board_View__c);
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board_View__c.getLabel());
                return;
            }
        } else if (String.isBlank(kbViewId) && String.isNotBlank(kBoard.Id)) {
            if (Schema.SObjectType.Kanban_Board__c.isAccessible() && Schema.SObjectType.Kanban_Board__c.isQueryable()) {
                List<Kanban_Board__c> kbList = [SELECT Id, JSON_Settings__c FROM Kanban_Board__c WHERE Id = :kBoard.Id LIMIT 1];
                if (!Schema.SObjectType.Kanban_Board__c.fields.JSON_Settings__c.isUpdateable()) {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                    return;
                }
                if (!kbList.isEmpty()) {
                    jsonParser(dummyQEditor, kbList[0].JSON_Settings__c);
                    dummyQEditor.queryWrapper.columnMap = columnFilterMap;
                    kbList[0].JSON_Settings__c = JSON.serialize(dummyQEditor);
                    Utilities.Secure_DML(kbList, Utilities.DML_Action.UPD, schema.SObjectType.Kanban_Board__c);
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
                return;
            }
        }

        columnOrderMap = new Map<Integer, String>();
        if (!dummyQEditor.queryWrapper.columnMap.isEmpty()) {
            updateColumnOrderMap(dummyQEditor.queryWrapper.columnMap.values());
        }
    }
}