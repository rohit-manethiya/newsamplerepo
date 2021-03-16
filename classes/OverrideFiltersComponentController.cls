public with sharing class OverrideFiltersComponentController extends DeploymentHelper {
    // Non Constants
    public List<QueryEditor.CriteriaWrapper> temporaryCriteriaWrappers { get; set; }
    @TestVisible
    private List<QueryEditor.CriteriaWrapper> mainCriteriaWrappers;
    private List<Step__c> steps;
    private List<Deployment_Task__c> tasks;
    private StepAttachmentDetails existingJson;
    public Boolean enableADD { get; set; }
    private Boolean deploymentIdInitialized; // created this because it got initialized 3 times.
    public DescribeResponse desResponse { get; set; }
    public String temporaryFilterLogic { get; set; }
    public String mainFilterLogic { get; set; }
    public String stepId { get; set; }
    public String taskId { get; set; }
    public String deploymentId {
        get;
        set {
            deploymentId = value;
            if (!deploymentIdInitialized) {
                initializeNecessaryData();
                deploymentIdInitialized = true;
            }
        }
    }

    // Constants
    private final String QUERY_FILTER_LIST = 'queryFilterList';
    private final String DATA_TEMPLATE = 'dataTemplate';
    private final String TEMPLATE_DETAIL = 'Template Detail';
    private final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';
    private final String NONE = '--None--';
    private final String C_STRING = 'STRING';
    private final String C_ADDRESS = 'address';
    private final String C_GEOLOCATION = 'location';
    private final String C_PERCENT = 'PERCENT';
    private final String C_DOUBLE = 'DOUBLE';
    private final String C_BOOLEAN = 'BOOLEAN';
    private final String C_INTEGER = 'INTEGER';
    private final String C_PHONE = 'PHONE';
    private final String C_EMAIL = 'EMAIL';
    private final String C_TEXT = 'TEXT';
    private final String C_TEXTAREA = 'TEXTAREA';
    private final String C_CURRENCY = 'CURRENCY';
    private final String C_INT = 'INT';
    private final String C_DATE = 'DATE';
    private final String C_DATETIME = 'DATETIME';
    private final String CUSTOM_DATE = 'customDate';
    private final String CUSTOM_FILTER = 'Custom Filter';
    private final String CUSTOM_N_DATE_NUMBER = ':n';

    /**
     * The controller constructor initializes the public deployment member
     */
    public OverrideFiltersComponentController() {
        mainCriteriaWrappers = new List<QueryEditor.CriteriaWrapper>();
        temporaryCriteriaWrappers = new List<QueryEditor.CriteriaWrapper>();
        steps = new List<Step__c>();
        tasks = new List<Deployment_Task__c>();
        existingJson = new StepAttachmentDetails();
        desResponse = new DescribeResponse();
        Copado_License__c copadoLicense = Copado_License__c.getInstance(UserInfo.getUserId());
        enableADD = copadoLicense.Enable_ADD__c;
        deploymentIdInitialized = false;
        temporaryFilterLogic = '1';
        mainFilterLogic = '1';
        stepId = ApexPages.currentPage().getParameters().get('stepId');
        taskId = ApexPages.currentPage().getParameters().get('taskId');
        if (taskId != null) {
            tasks = returnDeploymentTasks(taskId);
            if (!tasks.isEmpty()) {
                existingJson = returnParsedValueOfDataJSONFieldOfTask(tasks[0]);
                getDataTemplateDetailAttachment();
                getFiltersFromDataJsonField();
                if (temporaryCriteriaWrappers.isEmpty()) {
                    temporaryCriteriaWrappers.addAll(mainCriteriaWrappers);
                    temporaryFilterLogic = mainFilterLogic;
                }
            }
        }
    }

    /**
     * It is used to populate all necessary data after deploymentId attribute set
     */
    private void initializeNecessaryData() {
        if (String.isNotBlank(deploymentId)) {
            this.deployment = populateDeploymentRecord();
            initializeServiceClasses();
            populateStepsList();
            populatePagesList();

            steps = returnDateTemplateStep(stepId);
            if (!steps.isEmpty()) {
                existingJson = returnParsedValueOfDataJSONField(steps[0]);
            }
            getDataTemplateDetailAttachment();
            getFiltersFromDataJsonField();
            if (temporaryCriteriaWrappers.isEmpty()) {
                temporaryCriteriaWrappers.addAll(mainCriteriaWrappers);
                temporaryFilterLogic = mainFilterLogic;
            }
        }
    }

    /**
     * It is used to return deployment task record
     */
    private List<Deployment_Task__c> returnDeploymentTasks(String taskId) {
        try {
            List<Deployment_Task__c> deploymentTasks = new List<Deployment_Task__c>();
            if (String.isNotBlank(taskId)) {
                deploymentTasks = [
                    SELECT Id, dataJson__c
                    FROM Deployment_Task__c
                    WHERE Id = :taskId
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            return deploymentTasks;
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Deployment_Task__c.getLabel()
                }
            );
        }
        return new List<Deployment_Task__c>();
    }

    /**
     * It is used to return parsed value of the data_json__c field of deployment task object
     */
    private StepAttachmentDetails returnParsedValueOfDataJSONFieldOfTask(Deployment_Task__c task) {
        try {
            StepAttachmentDetails existingJson = (StepAttachmentDetails) JSON.deserialize(task.dataJson__c, StepAttachmentDetails.class);
            return existingJson;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to get already saved filter values from data_json__c field of step or deployment task object
     * Those filter values will be stored in temporaryCriteriaWrappers
     * Checking existingJson.queryFilterList != null, because old version do not include that parameter, It should not break the page for existing customer
     */
    private void getFiltersFromDataJsonField() {
        if (existingJson.queryFilterList != null) {
            temporaryCriteriaWrappers.addAll(existingJson.queryFilterList);
            temporaryFilterLogic = existingJson.filterLogic;

            // We can not serialize selectoption to json so we cleared them before. We have to call a function to auto populate possible actions based on selected type at the filter criteria
            if (!temporaryCriteriaWrappers.isEmpty()) {
                for (Integer i = 0; i < temporaryCriteriaWrappers.size(); i++) {
                    populateFilterCriteriaFields(i, false, temporaryCriteriaWrappers);
                }
            }
        }
    }

    /**
     * It is used to retrieve Data template attachments from given deployment id
     * First we will find the created step and from step we will get the template id
     * With the template id we will get the related attachment and populate filter values
     */
    private void getDataTemplateDetailAttachment() {
        try {
            for (Attachment att : [
                SELECT Name, ParentId, Body
                FROM Attachment
                WHERE ParentId = :existingJson.dataTemplateId AND (Name = :TEMPLATE_DETAIL OR Name = :ADD_DESCRIBE_SOBJECT)
                WITH SECURITY_ENFORCED
            ]) {
                if (att.Name == TEMPLATE_DETAIL) {
                    String attachmentBody = EncodingUtil.base64Decode(EncodingUtil.base64Encode(att.Body)).toString();
                    Map<String, Object> dataTemplateDetails = (Map<String, Object>) JSON.deserializeUntyped(attachmentBody);

                    if (dataTemplateDetails.containskey(QUERY_FILTER_LIST)) {
                        List<Object> filters = (List<Object>) dataTemplateDetails.get(QUERY_FILTER_LIST);

                        for (Object criteria : filters) {
                            Map<String, Object> criteriaItems = (Map<String, Object>) criteria;
                            QueryEditor.CriteriaWrapper tempCriteria = new QueryEditor.CriteriaWrapper();
                            tempCriteria.fieldName = (String) criteriaItems.get('fieldName');
                            tempCriteria.fieldType = (String) criteriaItems.get('fieldType');
                            tempCriteria.operator = (String) criteriaItems.get('operator');
                            tempCriteria.operatorSet = (List<System.SelectOption>) criteriaItems.get('operatorSet');
                            tempCriteria.input = (String) criteriaItems.get('input');
                            tempCriteria.numberInput = (Double) criteriaItems.get('numberInput');
                            String dateInput = (String) criteriaItems.get('dateInput');
                            tempCriteria.dateInput = String.isNotBlank(dateInput) ? Date.valueOf(dateInput) : null;
                            String dateTimeInput = (String) criteriaItems.get('dateTimeInput');
                            dateTimeInput = String.isNotBlank(dateTimeInput) ? dateTimeInput.replace('T', ' ').replace('Z', ' ') : '';
                            tempCriteria.dateTimeInput = String.isNotBlank(dateTimeInput) ? DateTime.valueOf(dateTimeInput) : null;
                            tempCriteria.finalValue = (String) criteriaItems.get('finalValue');
                            tempCriteria.order = (Integer) criteriaItems.get('order');

                            mainCriteriaWrappers.add(tempCriteria);
                        }
                    }

                    if (dataTemplateDetails.containskey(DATA_TEMPLATE)) {
                        Map<String, Object> templateDetails = (Map<String, Object>) dataTemplateDetails.get(DATA_TEMPLATE);
                        mainFilterLogic = (String) templateDetails.get('templateFilterLogic');
                    }
                } else if (att.Name == ADD_DESCRIBE_SOBJECT) {
                    String body = att.Body.toString();
                    desResponse = (DescribeResponse) JSON.deserialize(body, DescribeResponse.class);
                }
            }

            // We can not serialize selectoption to json so we cleared them before. We have to call a function to auto populate possible actions based on selected type at the filter criteria
            if (!mainCriteriaWrappers.isEmpty()) {
                for (Integer i = 0; i < mainCriteriaWrappers.size(); i++) {
                    populateFilterCriteriaFields(i, false, mainCriteriaWrappers);
                }
            }
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Attachment.getLabel()
                }
            );
        }
    }

    /**
     * It is used to populate deployment record by given "deploymentId" attribute on the component
     */
    private Deployment__c populateDeploymentRecord() {
        List<Deployment__c> deployments = new List<Deployment__c>();
        try {
            deployments = [
                SELECT
                    Id,
                    Name,
                    Promotion__c,
                    From_Org__c,
                    Status__c,
                    Source_Environment__c,
                    RecordtypeId,
                    Deployment_Last_Step__c,
                    Deployment_Source_Type__c
                FROM Deployment__c
                WHERE Id = :deploymentId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (System.QueryException exceptions) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{
                    exceptions.getMessage(),
                    Label.Insufficient_Access_Rights,
                    Label.Related_Object +
                    ' ' +
                    Schema.SObjectType.Deployment__c.getLabel()
                }
            );
        }
        return !deployments.isEmpty() ? deployments[0] : new Deployment__c();
    }

    /**
     * it is used to create new empty filter criteria line
     */
    public void addNewCriteria() {
        QueryEditor.CriteriaWrapper tempCriteria = new QueryEditor.CriteriaWrapper();
        tempCriteria.setOperatorSet(setOperators());
        Integer indexValue = temporaryCriteriaWrappers != null ? temporaryCriteriaWrappers.size() + 1 : 1;
        tempCriteria.setOrder(indexValue);

        if (temporaryCriteriaWrappers == null) {
            temporaryCriteriaWrappers = new List<QueryEditor.CriteriaWrapper>();
        }

        temporaryCriteriaWrappers.add(tempCriteria);

        if (temporaryCriteriaWrappers.size() > 1) {
            temporaryFilterLogic += ' AND ' + tempCriteria.getOrder();
        }
    }

    /**
     * it is used to remove the criteria line
     */
    public void removeCriteria() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('criteriaOrder');
        if (String.isNotBlank(criteriaOrder)) {
            Integer orderToRemove = Integer.valueOf(criteriaOrder) - 1;
            temporaryCriteriaWrappers.remove(orderToRemove);
        }

        if (temporaryCriteriaWrappers.isEmpty()) {
            addNewCriteria();
        }

        for (Integer i = 0; i < temporaryCriteriaWrappers.size(); i++) {
            temporaryCriteriaWrappers[i].order = i + 1;
        }
    }

    /**
     * it is used to populate possible options at Field section of Specify Filter Criteria. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getAllFieldsAPIName() {
        List<SelectOption> apiNames = new List<SelectOption>();
        if (desResponse != null && desResponse.fields != null) {
            apiNames.add(new SelectOption(NONE, NONE));
            for (CopadoField copadoFld : desResponse.fields) {
                // checking if the current user can see these fields and only adding filterable fields to the option list
                if (copadoFld.filterable && copadoFld.type != null && copadoFld.type != C_ADDRESS && copadoFld.type != C_GEOLOCATION) {
                    apiNames.add(new SelectOption(copadoFld.label + '-' + copadoFld.name, copadoFld.label + ' (' + copadoFld.name + ')'));
                }
            }
            apiNames.sort();
            apiNames.add(1, new SelectOption(CUSTOM_FILTER, CUSTOM_FILTER));
        }
        return apiNames;
    }

    /**
     * it is re-populate the operator based on selected field type
     */
    public void getFieldOperators() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('cro');
        if (!String.isBlank(criteriaOrder)) {
            Integer listOrder = Integer.valueOf(criteriaOrder) - 1;
            if (!temporaryCriteriaWrappers.isEmpty() && temporaryCriteriaWrappers.size() > listOrder) {
                populateFilterCriteriaFields(listOrder, true, temporaryCriteriaWrappers);
            }
        }
    }

    /**
     * populate operator set field of qEditor.
     * @param listOrder
     */
    private void populateFilterCriteriaFields(Integer listOrder, Boolean clearFields, List<QueryEditor.CriteriaWrapper> criterias) {
        if (desResponse != null && desResponse.fields != null) {
            QueryEditor.CriteriaWrapper tempCriteria = criterias[listOrder];
            String criteriaField = tempCriteria.getFieldName();
            String fieldType = '';

            if (criteriaField != CUSTOM_FILTER) {
                for (CopadoField copadoFld : desResponse.fields) {
                    String criteriaKey = copadoFld.label + '-' + copadoFld.name;
                    if (criteriaField == criteriaKey) {
                        fieldType = copadoFld.type;
                        break;
                    }
                }
            }

            // checking if the field is defined and field type is included in type operator map. If there is not defined type it will always return STRING
            Map<String, String[]> type2ops = OperatorTypeCodes.getTypeToOps();
            String fType = String.isNotBlank(fieldType) && type2ops.containsKey(fieldType.toUpperCase()) ? fieldType.toUpperCase() : C_STRING;
            tempCriteria.setFieldType(fType);
            if (clearFields) {
                tempCriteria.setInput('');
                tempCriteria.setDateInput(null);
                tempCriteria.setDateTimeInput(null);
                tempCriteria.setNumberInput(0);
            }
            List<SelectOption> criteriaOptions = new List<SelectOption>();
            criteriaOptions.add(new SelectOption(NONE, NONE));
            if (criteriaField != CUSTOM_FILTER) {
                // updating the existing operator set based on selected type on the UI
                Map<String, String> operatorCodes = OperatorTypeCodes.getOperatorCodes();
                for (String opt : type2ops.get(fType)) {
                    if (operatorCodes.containsKey(opt)) {
                        criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                    }
                }
            }
            tempCriteria.setOperatorSet(criteriaOptions);
            if (tempCriteria.operator == null) {
                tempCriteria.setOperator('e');
            }
        }
    }

    /**
     * loop in the all possible operator code and add them to select option. This list will be updated based on selected field type.
     * @return
     */
    @TestVisible
    private List<SelectOption> setOperators() {
        List<SelectOption> operators = new List<SelectOption>();
        Map<String, String> operatorCodes = OperatorTypeCodes.getOperatorCodes();
        for (String operatorCode : operatorCodes.keySet()) {
            operators.add(new SelectOption(operatorCode, operatorCodes.get(operatorCode)));
        }
        return operators;
    }

    /**
     * loop in the criteria wrapper and create a where condition string
     * @return
     */
    private void getWhereCondition() {
        Map<String, String> symbolsByOperators = OperatorTypeCodes.getOperatorSembols();
        for (QueryEditor.CriteriaWrapper criteriaItem : temporaryCriteriaWrappers) {
            String operator = criteriaItem.getOperator();
            String fieldType = criteriaItem.getFieldType();
            String fieldName = criteriaItem.getFieldName();
            String input = criteriaItem.getInput();
            Integer order = criteriaItem.getOrder();
            Date dateInput = criteriaItem.getDateInput();
            Datetime dateTimeInput = criteriaItem.getDateTimeInput();
            Decimal numberInput = criteriaItem.getNumberInput();
            String finalValue = criteriaItem.getFinalValue();
            finalValue = (fieldName != NONE && fieldName == CUSTOM_FILTER) ? input : finalValue;
            if (fieldName != NONE && fieldName != CUSTOM_FILTER && operator != null) {
                // define the symbol from pre-defined map
                String symbol = symbolsByOperators.get(operator);
                // update the input value based on operator
                // For instance; If the selected operator is 'contains', input value will be %input%
                String inputValue = String.escapeSingleQuotes(input);
                switch on operator {
                    when 's' {
                        inputValue += '%';
                    }
                    when 'c', 'k' {
                        inputValue = '%' + inputValue + '%';
                    }
                }
                // update the input based on field type
                Boolean isNumberInput =
                    fieldType == C_INTEGER ||
                    fieldType == C_DOUBLE ||
                    fieldType == C_INT ||
                    fieldType == C_PERCENT ||
                    fieldType == C_CURRENCY;
                Boolean isDateInput = fieldType == C_DATE && String.isNotBlank(input) && input == CUSTOM_DATE;
                Boolean isDateTimeInput = fieldType == C_DATETIME && String.isNotBlank(input) && input == CUSTOM_DATE;
                Boolean isCustomNDateAndTime =
                    (fieldType == C_DATE ||
                    fieldType == C_DATETIME) &&
                    String.isNotBlank(input) &&
                    input.contains(CUSTOM_N_DATE_NUMBER);
                Boolean isCustomStringDateAndTime =
                    (fieldType == C_DATE ||
                    fieldType == C_DATETIME) &&
                    String.isNotBlank(input) &&
                    !input.contains(CUSTOM_N_DATE_NUMBER);
                Boolean isBoolean = fieldType == C_BOOLEAN;
                Boolean isIntegerInput = fieldType == C_INTEGER || fieldType == C_DOUBLE || fieldType == C_INT;
                String newNumberInput = isCustomNDateAndTime || isIntegerInput
                    ? String.valueOf(Integer.valueOf(numberInput))
                    : String.valueOf(numberInput);
                String newDateTimeInput = isDateTimeInput ? dateTimeInput.format('yyyy-MM-dd\'T\'HH:mm:ss', UserInfo.getLocale()) + 'Z' : '';
                String newDateInput = isDateInput ? String.valueOf(dateInput) : '';
                String newStringValue = isCustomNDateAndTime ? inputValue.replace(CUSTOM_N_DATE_NUMBER, ':' + newNumberInput) : inputValue;
                newStringValue = isCustomStringDateAndTime || isCustomNDateAndTime || isBoolean ? newStringValue : '\'' + newStringValue + '\'';
                // input value convert to string
                newStringValue = isNumberInput ? newNumberInput : isDateInput ? newDateInput : isDateTimeInput ? newDateTimeInput : newStringValue;
                // if the selected operator is 'not contains', adding the whole input in (NOT input)
                String fieldNames = operator == 'k' ? ' ( NOT ' + fieldName : fieldName;
                newStringValue = operator == 'k' ? newStringValue + ' ) ' : newStringValue;
                // if filter logic is not enabled, adding the string to the where condition. If the filter logic is enabled collecting the inputs in map to format string.
                finalValue = fieldNames.split('-')[1] + symbol + newStringValue;
            }
            criteriaItem.setFinalValue(finalValue);
            criteriaItem.setOperatorSet(null);
        }
    }

    /**
     * It is used to save current filters and go to deployment tab
     * First we will check the temporaryCriteriaWrappers and mainCriteriaWrappers conditions to find if there is changes
     * If there is changes we will store new filter criteria at step field "data_json__c"
     * If there is no changes we will just go to deployment tab without saving filters
     *
     * @return
     */
    public PageReference saveFiltersAndClose() {
        upsertOperations();
        return pageMessagesMap.isEmpty() ? goToDeploymentTab() : null;
    }

    /**
     * It is used to save current filters and go to related record
     * First we will check the temporaryCriteriaWrappers and mainCriteriaWrappers conditions to find if there is changes
     * If there is changes we will store new filter criteria at step field "data_json__c"
     * If there is no changes we will just go to related record without saving filters
     *
     * @return
     */
    public PageReference saveFiltersAndGoToRecord() {
        String buttonAction = ApexPages.currentPage().getParameters().get('action');
        if (String.isNotBlank(buttonAction) && buttonAction == 'saveAndGo') {
            upsertOperations();
        }
        return pageMessagesMap.isEmpty() ? goToRelatedRecord() : null;
    }

    /**
     * It is used to define which object to redirect
     */
    public PageReference goToRelatedRecord() {
        return String.isNotBlank(taskId) ? goToDeploymentTask() : goToDeployment();
    }

    /**
     * It is used to redirect to the advanced deployment page
     *
     * @return
     */
    public PageReference goToDeploymentTask() {
        PageReference pageReference = Page.ViewDeploymentTasks;
        pageReference.getParameters().put(C_ID, taskId);
        pageReference.setRedirect(true);
        return pageReference;
    }

    /**
     * It is used to upsert step before leaving the page
     */
    private void upsertOperations() {
        pageMessagesMap.clear();
        Boolean updateDataJsonField = false;

        // First off all we will remove empty rows to make comparision better
        removeEmptyFilterRows();

        // if list size is different, there are changes on filter so save new filter values
        // if list size equal we will check one by one to find if there is changes on existing filter values
        if (temporaryCriteriaWrappers.size() != mainCriteriaWrappers.size()) {
            updateDataJsonField = true;
        } else {
            updateDataJsonField = isFilterValueChanged();
        }

        existingJson.filterOverride = updateDataJsonField;
        if (updateDataJsonField) {
            getWhereCondition();
            if (String.isNotBlank(taskId)) {
                upsertFiltersForTask();
            } else {
                upsertFiltersForStep();
            }
        }
    }

    /**
     * It is used when user click on "Confirm Data Filters"
     * First of all, we will try to upsert step
     * Second, we will update Deployment_Last_Step__c field to redirect correct page
     *
     * @see DeploymentHelper
     * @return
     */
    public PageReference confirmAndGoOverview() {
        upsertOperations();
        upsertDeployment(true);
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }

    /**
     * It is used to remove empty rows from temporaryCriteriaWrappers to avoid deployment error.
     * If field name and operator NONE, we will remove from list
     * Method is recursive until all empty rows are removed
     */
    private void removeEmptyFilterRows() {
        Boolean thereIsEmptyRow = false;
        for (QueryEditor.CriteriaWrapper criteriaItem : temporaryCriteriaWrappers) {
            String operator = criteriaItem.getOperator();
            String fieldName = criteriaItem.getFieldName();
            Integer order = criteriaItem.getOrder();
            if (fieldName == null || fieldName == NONE || operator == null || (operator == NONE && fieldName != CUSTOM_FILTER)) {
                Integer orderToRemove = Integer.valueOf(order) - 1;
                temporaryCriteriaWrappers.remove(orderToRemove);
                thereIsEmptyRow = true;
                break;
            }
        }

        if (thereIsEmptyRow) {
            for (Integer i = 0; i < temporaryCriteriaWrappers.size(); i++) {
                temporaryCriteriaWrappers[i].order = i + 1;
            }
            removeEmptyFilterRows();
        }
    }

    /**
     * It is used to populate existingJson values with the changes before upsertting to the related record
     */
    private void populateExistingJsonForUpsert() {
        existingJson.filterLogic = temporaryFilterLogic;
        existingJson.queryFilterList = temporaryCriteriaWrappers;

        if (temporaryCriteriaWrappers.isEmpty()) {
            existingJson.filterOverride = false;
        }
    }

    /**
     * It is used to upsert new filter values to the data_json__c field of step object
     */
    private void upsertFiltersForStep() {
        if (!steps.isEmpty()) {
            populateExistingJsonForUpsert();
            steps[0].dataJson__c = JSON.serialize(existingJson);
        }

        // Strip fields that are not upsertable
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, steps);

        //DML
        try {
            upsert decision.getRecords();
        } catch (NoAccessException ex) {
            pageMessagesMap.put(C_WARNING, new List<Object>{ ex.getMessage() });
        }
    }

    /**
     * It is used to upsert new filter values to the data_json__c field of task object
     */
    private void upsertFiltersForTask() {
        if (!tasks.isEmpty()) {
            populateExistingJsonForUpsert();
            tasks[0].dataJson__c = JSON.serialize(existingJson);
        }

        // Strip fields that are not upsertable
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, tasks);

        //DML
        try {
            upsert decision.getRecords();
        } catch (NoAccessException ex) {
            pageMessagesMap.put(C_WARNING, new List<Object>{ ex.getMessage() });
        }
    }

    /**
     * It is used to find if there is a changes on main template filters.
     */
    private Boolean isFilterValueChanged() {
        Boolean filterValuesChanged = false;
        for (QueryEditor.CriteriaWrapper temporaryCriteria : temporaryCriteriaWrappers) {
            for (QueryEditor.CriteriaWrapper mainCriteria : mainCriteriaWrappers) {
                if (temporaryCriteria.order == mainCriteria.order) {
                    Boolean fieldNameChanged = temporaryCriteria.fieldName == mainCriteria.fieldName;
                    Boolean fieldTypeChanged = temporaryCriteria.fieldType == mainCriteria.fieldType;
                    Boolean operatorChanged = temporaryCriteria.operator == mainCriteria.operator;
                    Boolean inputChanged = temporaryCriteria.input == mainCriteria.input;
                    Boolean numberInputChanged = temporaryCriteria.numberInput == mainCriteria.numberInput;
                    Boolean dateInputChanged = temporaryCriteria.dateInput == mainCriteria.dateInput;
                    Boolean dateTimeInputChanged = temporaryCriteria.dateTimeInput == mainCriteria.dateTimeInput;

                    if (
                        fieldNameChanged ||
                        fieldTypeChanged ||
                        operatorChanged ||
                        inputChanged ||
                        numberInputChanged ||
                        dateInputChanged ||
                        dateTimeInputChanged
                    ) {
                        filterValuesChanged = true;
                        break;
                    }
                }
            }
        }

        return filterValuesChanged;
    }

    /**
     * It is used to clear all overrided filters and get the default filters from data template.
     */
    public void resetFilterValues() {
        temporaryCriteriaWrappers.clear();
        temporaryCriteriaWrappers.addAll(mainCriteriaWrappers);
        temporaryFilterLogic = mainFilterLogic;
    }

    /**
     * It is used to render commandbutton for different pages
     * If the page is DSW, "back", "save and close" and "confirm filter" button will apear
     * If the page is override filter and step id is given, "close" and "save" will appear, after save it will go to deployment record
     */
    public Boolean getURLParameters() {
        // if we do not check url here again, it returns null always.
        stepId = ApexPages.currentPage().getParameters().get('stepId');
        Boolean parametersNotNull = String.isNotBlank(taskId) ? true : String.isNotBlank(stepId) ? true : false;
        return parametersNotNull;
    }

    public class DescribeResponse {
        public List<CopadoField> fields { get; set; }
    }

    public class CopadoField {
        public Boolean filterable { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public String type { get; set; }
    }
}