/**
 * Compliance rule criteria management page.
 * List view like UX applied for users to adapt themselves easily
 * @author Mert YALTI
 * @version 1.0
 */
public with sharing class AddCCHRuleCriteriaExt {
    public String filterLogic { get; set; }
    public Boolean renderDetails { get; set; }
    public Boolean showFilterLogic { get; set; }
    public Boolean isValid { get; set; }
    public Boolean hasCriteria { get; set; }
    public String ruleCategoryType { get; set; }
    public List<SelectOption> categoryTypes { get; set; }
    public List<SelectOption> categoryNodes { get; set; }
    public Map<String, List<SelectOption>> nodeFields { get; set; }
    public Boolean getNodeFieldsisEmpty() {
        return nodeFields.size() == 1;
    }
    public Map<String, String> fieldTypes { get; set; }
    public List<CriteriaWrapper> criteriaList { get; set; }
    public Map<String, Categories> categoryMap { get; set; }
    public static List<SelectOption> operators { get; set; }
    @TestVisible
    public Compliance_Rule__c rule { get; private set; }
    private Map<Integer, CriteriaWrapper> validCriterias { get; set; }
    @TestVisible
    private Map<Integer, Compliance_Rule_Criteria__c> legacyCriterias { get; set; }
    @TestVisible
    private List<Compliance_Rule_Criteria__c> criteriaMemento { get; set; }
    public String logicMessage { get; set; }
    private Map<String, Nodes> selectedCategoryNodes { get; set; }
    private final String NONE = '--None--';
    private final String C_NAME = 'name';
    private final String C_STRING = 'STRING';
    private final String AND_OR = 'AND|OR';

    public void zeroiseRoot() {
        categoryTypes = new List<SelectOption>();
        categoryTypes.add(new SelectOption(NONE, NONE));
        categoryNodes = new List<SelectOption>();
        categoryNodes.add(new SelectOption(NONE, NONE));
        nodeFields = new Map<String, List<SelectOption>>();
        List<SelectOption> temp = new List<SelectOption>();
        temp.add(new SelectOption(NONE, NONE));
        nodeFields.put(NONE, temp);
        setOperators();
        requestComplianceFile();
    }

    public void refresh() {
        rule.Is_Valid__c = false;
        rule.Metadata_Type__c = NONE;
        rule.Matching_Criteria__c = NONE;
        rule.Record_Count__c = null;
        categoryNodes.clear();
        categoryTypes.clear();
        zeroiseRoot();
        getNodePicklist();
        criteriaList.clear();
        for (Integer i = 0; i < 3; i++) {
            //System.debug(LoggingLevel.INFO, '***criteriaList size2:' + criteriaList.size());
            addNewCriteria();
        }
    }

    /**
     * Constructor for the page
     * @param ApexPages.StandardController
     * @return AddCCHRuleCriteriaExt
     * */
    public AddCCHRuleCriteriaExt(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Compliance_Rule__c.fields.getMap().keySet()));
        }
        renderDetails = true;
        if (!FeatureHelper.isComplianceHubEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED));
            renderDetails = false;
        } else if (!LicenseHelper.isCCHEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCH_LICENSE_NOT_ENABLED));
            renderDetails = false;
        } else if (
            !Test.isRunningTest() &&
            (!Schema.SObjectType.Compliance_Rule__c.fields.Metadata_Type__c.isAccessible() ||
            !Schema.SObjectType.Compliance_Rule__c.fields.Filter_Criteria__c.isAccessible() ||
            !Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c.isAccessible())
        ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.COMPLIANCE_RULE_MISSING_FLS));
            renderDetails = false;
            this.rule = (Compliance_Rule__c) stdController.getRecord();
        } else {
            if (!Test.isRunningTest()) {
                stdController.addFields(new List<String>{ 'Metadata_Type__c', 'Filter_Criteria__c', 'Is_Valid__c' });
            }
            this.rule = (Compliance_Rule__c) stdController.getRecord();
            if (rule.Record_Count_Criteria__c == null) {
                rule.Record_Count_Criteria__c = 'Number of groups';
            }
            criteriaMemento = new List<Compliance_Rule_Criteria__c>();
            isValid = rule.Is_Valid__c;
            ruleCategoryType = this.rule.Metadata_Type__c;
            zeroiseRoot();
            criteriaList = new List<CriteriaWrapper>();
            legacyCriterias = new Map<Integer, Compliance_Rule_Criteria__c>();
            filterLogic = (!String.isBlank(rule.Filter_Criteria__c) && rule.Filter_Criteria__c.toLowerCase().contains('or'))
                ? rule.Filter_Criteria__c
                : '';
            showFilterLogic = (!String.isBlank(rule.Filter_Criteria__c) && rule.Filter_Criteria__c.toLowerCase().contains('or')) ? true : false;
            hasCriteria = false;
            // If there are existing criterias associated with the rule following loop will prepare page variables against those criterias by doing following steps
            // Will create CriteriaWrapper variables and fill them to the criteria list so that the page will display proper data
            // Will convert filter criteria (RC-000123 AND RC-000124) to user readable filter logic (1 AND 2)
            setLegacyCriteria();
            // Will read compliance file that requested from backend and populate nodes list with select options
            /**
             * @see getNodePicklist();
             */
            if (!String.isBlank(ruleCategoryType)) {
                getNodePicklist();
            }
        }
    }

    /**
     * This method is used for legacy criterias
     * */
    private void setLegacyCriteria() {
        criteriaList.clear();
        legacyCriterias.clear();
        criteriaMemento.clear();
        if (Schema.SObjectType.Compliance_Rule_Criteria__c.isQueryable() && Schema.SObjectType.Compliance_Rule_Criteria__c.isAccessible()) {
            for (Compliance_Rule_Criteria__c crc : [
                SELECT Id, Node__c, Field__c, Field_Type__c, Operator__c, Value__c, Name, Order__c, Compliance_Rule__c
                FROM Compliance_Rule_Criteria__c
                WHERE Compliance_Rule__c = :rule.Id
                ORDER BY Order__c ASC
            ]) {
                legacyCriterias.put(Integer.valueOf(crc.Order__c), crc);
                hasCriteria = true;
                String nodeName = !String.isBlank(crc.Node__c) ? crc.Node__c : NONE;
                String fieldName = !String.isBlank(crc.Field__c) ? crc.Field__c : NONE;
                String fieldType = !String.isBlank(crc.Field_Type__c) ? crc.Field_Type__c : C_STRING;
                String operator;
                if (null != crc.Operator__c && opetorsToCodes.containsKey(crc.Operator__c.toLowerCase())) {
                    operator = opetorsToCodes.get(crc.Operator__c.toLowerCase());
                }
                String input = 'w' == operator ||
                    'x' == operator
                    ? crc.Value__c.substring(0, crc.Value__c.lastIndexOf(']')).replaceFirst('\\[', '')
                    : crc.Value__c;
                List<SelectOption> temCriteriaOptions = new List<SelectOption>();
                if (type2ops.containsKey(fieldType.toUpperCase())) {
                    for (String opt : type2ops.get(fieldType.toUpperCase())) {
                        if (operatorCodes.containsKey(opt)) {
                            temCriteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                        }
                    }
                }
                if (!String.isBlank(rule.Filter_Criteria__c) && null != crc.Order__c) {
                    filterLogic = filterLogic.replace(crc.Name, String.valueOf(crc.Order__c));
                    criteriaList.add(
                        new CriteriaWrapper(nodeName, fieldName, fieldType, Integer.valueOf(crc.Order__c), operator, temCriteriaOptions, input)
                    );
                } else if (!String.isBlank(rule.Filter_Criteria__c) && null == crc.Order__c) {
                    filterLogic = filterLogic.replace(crc.Name, 'NaN');
                    criteriaMemento.add(crc);
                    legacyCriterias.remove(Integer.valueOf(crc.Order__c));
                }
            }
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    Schema.SObjectType.Compliance_Rule_Criteria__c.label +
                    ': ' +
                    Label.Insufficient_Access_Rights
                )
            );
            return;
        }
        System.debug(LoggingLevel.INFO, '***legacyCriterias size:' + legacyCriterias.size());
        System.debug(LoggingLevel.INFO, '***criteriaList size:' + criteriaList.size());
        //When page is loaded if there is less than 3 existing criterias there will be (3 - existing criteria size) empty criteria display on the page
        //following loop creates those
        Integer pre = 3 - legacyCriterias.keySet().size() > 0 ? 3 - legacyCriterias.keySet().size() : 0;
        for (Integer i = 0; i < pre; i++) {
            //System.debug(LoggingLevel.INFO, '***criteriaList size2:' + criteriaList.size());
            addNewCriteria();
        }
    }
    /**
     * Show or hide filter logic panel on the page
     */
    public void toggleLogic() {
        showFilterLogic = !showFilterLogic;
    }
    /**
     * Validates filter logic by creating an SOQL by using entered filter logic
     * If showFilterLogic is FALSE this method will be ignored during save
     * @return Boolean valid or not
     */
    public Boolean validateFilterLogic() {
        logicMessage = '';
        if (String.isEmpty(filterLogic)) {
            showFilterLogic = false;
            return true;
        }
        String[] items = filterLogic.toUpperCase().trim().split(AND_OR);
        if (items.size() < validCriterias.values().size()) {
            logicMessage = Label.CONDITION_DEFINED_BU_NOT_REF;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, logicMessage));
            return false;
        }
        String whereClause = String.escapeSingleQuotes(String.valueOf(filterLogic));
        Integer[] sortedItems = new List<Integer>();
        for (String item : items) {
            Integer order = Integer.valueOf(item.replace('(', '').replace(')', '').trim());
            sortedItems.add(order);
        }
        sortedItems.sort();
        String testValue = 'test';
        for (Integer order = sortedItems.size(); order > 0; order--) {
            if (!validCriterias.containsKey(Integer.valueOf(order))) {
                logicMessage = Label.CONDITION_NOT_DEFINED_BUT_REF;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, logicMessage));
                return false;
            }
            whereClause = whereClause.replace(String.valueOf(order), ' Name = :testValue');
        }
        // This query may show SOQL injection security issue however that is actually false positive since we need to get where clause from UI in order to build the Compliance Rule.
        String soqlString = 'SELECT Id FROM Compliance_Rule__c WHERE ' + whereClause;
        try {
            if (Schema.SObjectType.Compliance_Rule__c.isQueryable() && Schema.SObjectType.Compliance_Rule__c.isAccessible()) {
                List<SObject> temp = Database.query(soqlString);
            } else {
                //TODO add ui helper method to show error to user when it is back promoted
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        Schema.SObjectType.Compliance_Rule__c.label +
                        ': ' +
                        Label.Insufficient_Access_Rights
                    )
                );
            }
            return true;
        } catch (Exception e) {
            //TODO use ui helper exception handling when it is back promoted
            logicMessage = Label.LOGIC_NOT_VALID + ' - ' + e.getMessage(); // For the next release make sure replacing e.getMessage() with a proper error handling algorith. Requested by Phil.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, logicMessage));
            return false;
        }
    }
    /**
     * Creates complete operators list
     * @see operatorCodes
     */
    private void setOperators() {
        if (null == operators) {
            operators = new List<SelectOption>();
            for (String oc : operatorCodes.keySet()) {
                operators.add(new SelectOption(oc, operatorCodes.get(oc)));
            }
        }
    }
    /**
     * Calls backend for compliance file which contains nodes, fields, field types JSON file
     */
    public void requestComplianceFile() {
        HttpResponse res;
        try {
            String callUrul = Settings.server_url + '/json/v1/complianceMetadata';
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            res = h.send(req);
            String body = res.getBody();
            parseComplianceFile(body);
        } catch (Exception e) {
            System.debug('exception: ' + e.getMessage());
            System.debug('exception line: ' + e.getLineNumber());
            if (!Test.isRunningTest() && res.getStatusCode() == 401) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Connection_Problem));
            }
        }
    }
    /**
     * Parser method for compliance file that retrieved from backend
     * @param jsonStr Backend call Http response body
     */
    private void parseComplianceFile(String jsonStr) {
        List<Object> jsonObject = (List<Object>) JSON.deserializeUntyped(jsonStr);
        categoryMap = new Map<String, Categories>();
        List<SelectOption> categoryTypes2 = new List<SelectOption>();
        for (Object obj : jsonObject) {
            Categories cat = (Categories) JSON.deserialize(JSON.serialize(obj), Categories.class);
            categoryTypes2.add(new SelectOption(cat.categoryType, cat.categoryType));
            categoryMap.put(cat.categoryType, cat);
        }
        categoryTypes.addAll(selectOptionSortByLabel(categoryTypes2));
        jsonObject.clear();
    }

    /**
     * @Param:List of selectOption to be sort.
     * @Return: Sorted list of selectOptions by Label
     */
    public static List<SelectOption> selectOptionSortByLabel(List<SelectOption> selectOptionsToSort) {
        if (selectOptionsToSort == null || selectOptionsToSort.size() <= 1) {
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        Integer pivot = selectOptionsToSort.size() / 2;

        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for (SelectOption so : selectOptionsToSort) {
            if (so.getLabel() <= pivotValue.getLabel()) {
                lessSelectOption.add(so);
            } else if (so.getLabel() > pivotValue.getLabel()) {
                greaterSelectOption.add(so);
            }
        }
        List<SelectOption> sortedSelectOptions = new List<SelectOption>();
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return sortedSelectOptions;
    }
    /**
     * Being invoked when a node is selected against a criteria on the page.
     * When a node other than none and name is selected other nodes are being disabled
     * because currently we can only support number of groups functionality
     *
     * Important Note: When we support Number of files and/or number of properties remove this function from here and from page
     */
    public void selectNode() {
        String selectedNode = '';
        for (CriteriaWrapper cw : criteriaList) {
            if (C_NAME != cw.nodeName && NONE != cw.nodeName) {
                if (String.isBlank(selectedNode)) {
                    selectedNode = cw.nodeName;
                }
            }
        }
        for (SelectOption catNode : categoryNodes) {
            if (!String.isBlank(selectedNode) && selectedNode != catNode.getValue() && C_NAME != catNode.getValue() && NONE != catNode.getValue()) {
                catNode.setDisabled(true);
            } else {
                catNode.setDisabled(false);
            }
        }
    }
    /**
     * Prepares node picklist values and fields list agains each node
     * @see requestComplianceFile
     */
    public void getNodePicklist() {
        if (null != categoryMap && String.isNotBlank(rule.Metadata_Type__c) && categoryMap.containsKey(rule.Metadata_Type__c)) {
            Categories selectedCat = categoryMap.get(rule.Metadata_Type__c);
            selectedCategoryNodes = new Map<String, Nodes>();
            for (Nodes node : selectedCat.nodes) {
                selectedCategoryNodes.put(node.name, node);
            }
            fieldTypes = new Map<String, String>();
            for (Nodes node : selectedCategoryNodes.values()) {
                categoryNodes.add(new SelectOption(node.metadataType, node.name));
                if (nodeFields.containsKey(node.metadataType)) {
                    List<SelectOption> temp = nodeFields.get(node.metadataType);
                    String[] fields = node.fields;
                    for (String fld : fields) {
                        String[] fieldAndType = fld.split(':');
                        temp.add(new SelectOption(fieldAndType[0], fieldAndType[0]));
                        nodeFields.put(node.metadataType, temp);
                        fieldTypes.put(fieldAndType[0], fieldAndType[1]);
                    }
                } else {
                    List<SelectOption> temp = new List<SelectOption>();
                    temp.add(new SelectOption(NONE, NONE));
                    String[] fields = node.fields;
                    for (String fld : fields) {
                        String[] fieldAndType = fld.split(':');
                        temp.add(new SelectOption(fieldAndType[0], fieldAndType[0]));
                        nodeFields.put(node.metadataType, temp);
                        fieldTypes.put(node.metadataType + ':' + fieldAndType[0], fieldAndType[1]);
                    }
                }
            }
            if (null != criteriaList && !criteriaList.isEmpty()) {
                selectNode();
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Compliance_No_Metadata_Selected));
        }
    }
    /**
     * Dummy method for passing input values from page to controller
     * @see https://salesforce.stackexchange.com/question... for definition of the problem
     */
    public void dummy() {
    }
    /**
     * gets list of operators against a selected field by using its type
     */
    public void getFieldOperators() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('cro');
        if (!String.isBlank(criteriaOrder)) {
            Integer listOrder = Integer.valueOf(criteriaOrder) - 1;
            if (!criteriaList.isEmpty() && criteriaList.size() > listOrder) {
                CriteriaWrapper temp = criteriaList[listOrder];
                String criteriaField = temp.fieldName;
                String nodeName = temp.nodeName;
                String typeKey = nodeName + ':' + criteriaField;
                if (fieldTypes.containsKey(typeKey)) {
                    String fType = fieldTypes.get(typeKey).toUpperCase();
                    temp.fieldType = fType;
                    List<SelectOption> criteriaOptions = new List<SelectOption>();
                    if (type2ops.containsKey(fType)) {
                        criteriaOptions.add(new SelectOption(NONE, NONE));
                        for (String opt : type2ops.get(fType)) {
                            if (operatorCodes.containsKey(opt)) {
                                criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                            }
                        }
                        temp.operatorSet = criteriaOptions;
                    } else {
                        for (String opt : type2ops.get(C_STRING)) {
                            if (operatorCodes.containsKey(opt)) {
                                criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                            }
                        }
                        temp.operatorSet = criteriaOptions;
                    }
                }
            }
        }
    }
    /**
     * To call validateRuleCallout from the VF page
     * ActionButtons requires methods that returns PageReference
     * @return PageReference
     */
    public PageReference validateRuleFromPage() {
        isValid = AddCCHRuleCriteriaExt.validateRuleCallout(rule);
        System.debug('is valid: ' + isValid);
        return null;
    }
    /**
     * Validate rule method that sends a call out to backend for the validation
     * @param crule Compliance rule
     * @return Boolean valid or not
     */
    public static Boolean validateRuleCallout(Compliance_Rule__c crule) {
        try {
            String callUrul = Settings.server_url + '/json/v1/validateComplianceRule/' + crule.Id;
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String body = res.getBody();

            Map<String, Object> ruleValidationResult = (Map<String, Object>) JSON.deserializeUntyped(body);
            if (ruleValidationResult.containsKey('error')) {
                String validationErrorMessage = (String) ruleValidationResult.get('error');
                if (
                    !Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Status_Message__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Date_time__c.isUpdateable()
                ) {
                    //TODO add ui helper method when it is back promoted
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            Schema.SObjectType.Compliance_Rule__c.label +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }
                crule.Is_Valid__c = false;
                crule.Last_Validation_Status_Message__c = validationErrorMessage;
                crule.Last_Validation_Date_time__c = Datetime.now();
                Utilities.Secure_DML(crule, Utilities.DML_Action.UPD, Schema.SObjectType.Compliance_Rule__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, validationErrorMessage));
                return false;
            } else {
                String validationSuccessMessage = (String) ruleValidationResult.get('ok');
                if (
                    !Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Status_Message__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Date_time__c.isUpdateable()
                ) {
                    //TODO add ui helper method when it is back promoted
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            Schema.SObjectType.Compliance_Rule__c.label +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }
                crule.Is_Valid__c = true;
                crule.Last_Validation_Status_Message__c = validationSuccessMessage;
                crule.Last_Validation_Date_time__c = Datetime.now();
                Utilities.Secure_DML(crule, Utilities.DML_Action.UPD, Schema.SObjectType.Compliance_Rule__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, validationSuccessMessage));
                return true;
            }
        } catch (Exception e) {
            //TODO add ui helper method when it is back-promoted
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Connection_Problem));
        }
        return null;
    }
    /**
     * Save Operation
     * Saves valid criterias to be saved
     * Deletes removed criterias if they had been saved before
     * Validated criterias and filter logic
     * Translated user readable filter logic (1 AND 2) to backend readable logic (RC-000123 AND RC-000124)
     * @see validateCriterias
     * @see validateFilterLogic
     * @see SavePoint
     * @see Database.rollback()
     * @return PageReference new Compliance Rule view
     */
    public PageReference saveCriterias() {
        Savepoint sp = Database.setSavepoint();
        ApexPages.getMessages().clear();
        validCriterias = new Map<Integer, CriteriaWrapper>();
        validateCriterias();
        if (validCriterias.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.AT_LEAST_ONE_VALID_CRITERIA));
            return null;
        }
        try {
            if (showFilterLogic) {
                Boolean isLogicValid = validateFilterLogic();
                if (!isLogicValid) {
                    return null;
                }
            }
            logicMessage = null;
            Utilities.Secure_DML(criteriaMemento, Utilities.DML_Action.DEL, Schema.SObjectType.Compliance_Rule_Criteria__c);
            hasCriteria = true;
            List<Compliance_Rule_Criteria__c> saveList = new List<Compliance_Rule_Criteria__c>();
            Set<String> existingCriteriaNames = new Set<String>();
            Integer counter = 1;
            filterLogic = !showFilterLogic ? '' : filterLogic;
            System.debug(LoggingLevel.INFO, '***validCriterias :' + validCriterias.values().size());
            for (CriteriaWrapper cw : validCriterias.values()) {
                String formattedInput = String.isNotBlank(cw.input) ? cw.input.trim() : cw.input;
                if ('within' == operatorCodes.get(cw.operator) || 'excludes' == operatorCodes.get(cw.operator)) {
                    formattedInput = '[' + formattedInput + ']';
                }
                String criteriaString =
                    cw.nodeName +
                    '.' +
                    cw.fieldName +
                    '<' +
                    operatorCodes.get(cw.operator).deleteWhitespace().toUpperCase() +
                    '>' +
                    formattedInput;
                Compliance_Rule_Criteria__c temp;
                if (
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Criteria__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Order__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Node__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Field__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Field_Type__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Operator__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Value__c.isUpdateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Compliance_Rule__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Criteria__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Order__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Node__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Field__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Field_Type__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Operator__c.isCreateable() ||
                    !Schema.SObjectType.Compliance_Rule_Criteria__c.fields.Value__c.isCreateable()
                ) {
                    //System.debug(LoggingLevel.INFO, '*** Authorization violation :');
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            Schema.SObjectType.Compliance_Rule_Criteria__c.label +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }
                if (legacyCriterias.containsKey(cw.order)) {
                    temp = legacyCriterias.get(cw.order);
                    if (existingCriteriaNames.contains(temp.Name)) {
                        continue;
                    }
                    existingCriteriaNames.add(temp.Name);
                } else {
                    temp = new Compliance_Rule_Criteria__c();
                }
                if (String.isBlank(temp.Compliance_Rule__c)) {
                    temp.Compliance_Rule__c = rule.Id;
                }
                temp.Criteria__c = criteriaString;
                temp.Order__c = counter;
                temp.Node__c = cw.nodeName;
                temp.Field__c = cw.fieldName;
                temp.Field_Type__c = cw.fieldType;
                temp.Operator__c = operatorCodes.get(cw.operator).capitalize();
                temp.Value__c = formattedInput;
                saveList.add(temp);
                if (!showFilterLogic || (showFilterLogic && String.isBlank(filterLogic))) {
                    filterLogic += filterLogic != '' ? ' AND ' + counter : String.valueOf(counter);
                }
                counter++;
            }
            System.debug(LoggingLevel.INFO, '***saveList :' + saveList);
            if (!saveList.isEmpty()) {
                Utilities.Secure_DML(saveList, Utilities.DML_Action.UPS, Schema.SObjectType.Compliance_Rule_Criteria__c);
                Set<Id> savedIds = new Set<Id>();
                for (Compliance_Rule_Criteria__c scrc : saveList) {
                    savedIds.add(scrc.Id);
                }
                Map<Integer, String> mergeitems = new Map<Integer, String>();
                Map<String, String> itemNames = new Map<String, String>();
                String[] splitLogic = filterLogic.toUpperCase().trim().split(AND_OR);
                Integer[] sortedItems = new List<Integer>();
                for (String sl : splitLogic) {
                    Integer item = Integer.valueOf(sl.replace('(', '').replace(')', '').trim());
                    sortedItems.add(item);
                }
                sortedItems.sort();
                for (Integer si : sortedItems) {
                    mergeitems.put(si, '{' + si + '}');
                }
                if (Schema.SObjectType.Compliance_Rule_Criteria__c.isQueryable()) {
                    for (Compliance_Rule_Criteria__c crc : [SELECT Id, Name, Order__c FROM Compliance_Rule_Criteria__c WHERE Id IN :savedIds]) {
                        if (mergeitems.containsKey(Integer.valueOf(crc.Order__c))) {
                            itemNames.put('{' + crc.Order__c + '}', crc.Name);
                        }
                    }
                } else {
                    //TODO add ui helper method when it is back-promoted
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            Schema.SObjectType.Compliance_Rule_Criteria__c.label +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }

                for (Integer index = sortedItems.size(); index > 0; index--) {
                    String mergeVal = mergeitems.get(index);
                    if (String.isNotBlank(mergeVal)) {
                        filterLogic = filterLogic.replace(String.valueOf(index), mergeVal)
                            .replace('}}', '}')
                            .replace('{{', '{')
                            .replace('}{', '')
                            .replace('}0', '0');
                    }
                }
                for (Integer index = sortedItems.size(); index > 0; index--) {
                    String mergeVal = mergeitems.get(index);
                    if (String.isNotBlank(mergeVal) && itemNames.containsKey(mergeVal)) {
                        filterLogic = filterLogic.replace(mergeVal, itemNames.get(mergeVal));
                    }
                }
                rule.Filter_Criteria__c = filterLogic;
                if (!Schema.SObjectType.Compliance_Rule__c.isAccessible()) {
                    //TODO add ui helper method when it is back-promoted
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            Schema.SObjectType.Compliance_Rule__c.label +
                            ': ' +
                            Label.Insufficient_Access_Rights
                        )
                    );
                    return null;
                }
                Compliance_Rule__c resetState = new Compliance_Rule__c();
                if (Schema.SObjectType.Compliance_Rule_Criteria__c.isQueryable() && String.isNotBlank(rule.Id)) {
                    resetState = [
                        SELECT Is_Valid__c, Last_Validation_Status_Message__c, Last_Validation_Date_time__c
                        FROM Compliance_Rule__c
                        WHERE Id = :rule.Id
                        LIMIT 1
                    ];
                    if (
                        !Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c.isUpdateable() ||
                        !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Status_Message__c.isUpdateable() ||
                        !Schema.SObjectType.Compliance_Rule__c.fields.Last_Validation_Date_time__c.isUpdateable()
                    ) {
                        ApexPages.addMessage(
                            new ApexPages.Message(
                                ApexPages.Severity.ERROR,
                                Schema.SObjectType.Compliance_Rule__c.label +
                                ': ' +
                                Label.Insufficient_Access_Rights
                            )
                        );
                        return null;
                    }
                    rule.Is_Valid__c = resetState.Is_Valid__c;
                    rule.Last_Validation_Status_Message__c = resetState.Last_Validation_Status_Message__c;
                    rule.Last_Validation_Date_time__c = resetState.Last_Validation_Date_time__c;
                    isValid = resetState.Is_Valid__c;
                    Utilities.Secure_DML(rule, Utilities.DML_Action.UPD, Schema.SObjectType.Compliance_Rule__c);
                    setLegacyCriteria();
                }
                return null;
            }
        } catch (Exception excp) {
            Database.rollback(sp);
            System.debug(LoggingLevel.INFO, '***debugging exception e :' + excp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, excp.getMessage()));
            return null;
        }
        return null;
    }
    /**
     * In order to insert a criteria, it requires a node, a field and an operator so this methods check criterias against this rule
     */
    public void validateCriterias() {
        Integer counter = 0;
        System.debug(LoggingLevel.INFO, '***validateCriterias criteriaList:' + criteriaList);
        for (CriteriaWrapper cw : criteriaList) {
            counter++;
            if (
                !String.isBlank(cw.nodeName) &&
                NONE != cw.nodeName &&
                !String.isBlank(cw.fieldName) &&
                NONE != cw.fieldName &&
                !String.isBlank(cw.operator) &&
                NONE != cw.operator
            ) {
                validCriterias.put(counter, cw);
            } else if (legacyCriterias.containsKey(counter) && !showFilterLogic) {
                criteriaMemento.add(legacyCriterias.get(counter));
                legacyCriterias.remove(counter);
            }
        }
        System.debug(LoggingLevel.INFO, '***criteriaMemento :' + criteriaMemento);
    }
    /**
     * Cancels operation and navigates page back to rule detail view
     * @return PageReference new Compliance Rule view
     */
    public PageReference cancelCriterias() {
        return new ApexPages.StandardController(rule).view();
    }
    /**
     * Creates new criteria place holder
     * @see CriteriaWrapper
     * @return PageReference
     */
    public PageReference addNewCriteria() {
        if (null != criteriaList) {
            CriteriaWrapper temp = new CriteriaWrapper();
            setOperators();
            temp.operatorSet = operators;
            temp.order = criteriaList.size() + 1;
            criteriaList.add(temp);
        }
        return null;
    }
    /**
     * Removes criteria from criteria list and also if the criteria has already inserted adds it to criteria memento list to delete during save
     * @see CriteriaWrapper
     * @return PageReference
     */
    public PageReference removeCriteria() {
        //System.debug(LoggingLevel.INFO, '***removeCriteria:::criteriaList :' + criteriaList.size());
        //System.debug(LoggingLevel.INFO, '***removeCriteria:::criteriaMemento :' + criteriaMemento.size());
        if (null != criteriaList && criteriaList.size() > 0) {
            if (legacyCriterias.containsKey(criteriaList.size())) {
                criteriaMemento.add(legacyCriterias.get(criteriaList.size()));
                legacyCriterias.remove(criteriaList.size());
            }
            criteriaList.remove(criteriaList.size() - 1);
        }
        //System.debug(LoggingLevel.INFO, '***removeCriteria:::criteriaList later :' + criteriaList.size());
        //System.debug(LoggingLevel.INFO, '***removeCriteria:::criteriaMemento later :' + criteriaMemento.size());
        return null;
    }
    /**
     * Code to operator map
     */
    private Map<String, String> operatorCodes = new Map<String, String>{
        '' => '--None--',
        'e' => 'equals',
        'n' => 'not equal to',
        's' => 'starts with',
        'c' => 'contains',
        'k' => 'does not contain',
        'l' => 'less than',
        'g' => 'greater than',
        'm' => 'less or equal',
        'h' => 'greater or equal',
        'u' => 'includes',
        'x' => 'excludes',
        'w' => 'within'
    };
    /**
     * operator to code map
     */
    private Map<String, String> opetorsToCodes = new Map<String, String>{
        'equals' => 'e',
        'not equal to' => 'n',
        'starts with' => 's',
        'contains' => 'c',
        'does not contain' => 'k',
        'less than' => 'l',
        'greater than' => 'g',
        'less or equal' => 'm',
        'greater or equal' => 'h',
        'includes' => 'u',
        'excludes' => 'x',
        'within' => 'w'
    };
    /**
     * Field types agains possible operator codes
     */
    private Map<String, String[]> type2ops = new Map<String, String[]>{
        'ANYTYPE' => new List<String>{ 'e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w' },
        'BASE64BINARY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'BOOLEAN' => new List<String>{ 'e', 'n' },
        'DATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'DATETIME' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'DOUBLE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'ID' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'INTEGER' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'INT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'STRING' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i', 'w', 'x' },
        'TIME' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'ADDRESS' => new List<String>{ 'w', 'y' },
        'ADDRESSCOUNTRY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'ADDRESSSTATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'AUTONUMBER' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'BIRTHDAY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'BITVECTOR' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'CONTENT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'CURRENCY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'CURRENCYCODE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'DATACATEGORYGROUPREFERENCE' => new List<String>{ 'e', 'n' },
        'DATEONLY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'DIVISION' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'DUEDATE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'DYNAMICENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'EMAIL' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'ENCRYPTEDTEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'ENTITYID' => new List<String>{ 'e', 'n', 's' },
        'ENUMORID' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'EXTERNALID' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'FAX' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'HTMLMULTILINETEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'HTMLSTRINGPLUSCLOB' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'INETADDRESS' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'LOCATION' => new List<String>{ 'w', 'y' },
        'MULTIENUM' => new List<String>{ 'e', 'n', 'u', 'x' },
        'MULTILINETEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'PERCENT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'PHONE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'RECORDTYPE' => new List<String>{ 'e', 'n' },
        'SFDCENCRYPTEDTEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'SIMPLENAMESPACE' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'STATICENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'STRINGPLUSCLOB' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'TEXT' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'TEXTENUM' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' },
        'TIMEONLY' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h' },
        'URL' => new List<String>{ 'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i' }
    };
    /**
     * Wrapper object to parse Compliance file easily
     */
    public class Categories {
        public String categoryType { get; set; }
        public List<Nodes> nodes { get; set; }
    }
    /**
     * Wrapper object to parse Compliance file easily
     */
    public class Nodes {
        public String name { get; set; }
        public String metadataType { get; set; }
        public String metadataNameField { get; set; }
        public String[] fields { get; set; }
    }
    /**
     * Criteria wrapper class
     */
    public class CriteriaWrapper {
        public String nodeName { get; set; }
        public String fieldName { get; set; }
        public String fieldType { get; set; }
        public Integer order { get; set; }
        public String operator { get; set; }
        public List<SelectOption> operatorSet { get; set; }
        public String input { get; set; }
        public CriteriaWrapper(
            String nodeName,
            String fieldName,
            String fieldType,
            Integer order,
            String operator,
            List<SelectOption> operatorSet,
            String input
        ) {
            this.nodeName = nodeName;
            this.fieldName = fieldName;
            this.fieldType = fieldType;
            this.order = order;
            this.operator = operator;
            this.operatorSet = operatorSet;
            this.input = String.isNotBlank(input) ? input.trim() : input;
        }
        public CriteriaWrapper() {
            this.nodeName = '--None--';
            this.fieldName = '--None--';
            this.fieldType = 'STRING';
            this.operator = '--None--';
            this.operatorSet = new List<SelectOption>();
            this.input = '';
        }
    }
}