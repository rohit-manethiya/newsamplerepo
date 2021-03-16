/**
 * It is main extension of DataTemplateSetup page
 */
public with sharing class DataTemplateSetupExtension {
    // Non Constants
    public Data_Template__c template { get; set; }
    public List<QueryEditor.CriteriaWrapper> criteriaWrapperList { get; set; }
    public Map<String, List<Object>> pageMessagesMap { get; set; }
    public Map<String, List<Object>> generalMessagesMap { get; set; }
    public Map<String, CopadoSelectedField> selectableFieldsMap { get; set; }
    public Map<String, CopadoSelectedChildRelationship> selectableChildRelationsMap { get; set; }
    public DescribeResponse desResponse { get; set; }
    public DescribeSObjectService.DescribeResponse allFieldsDescribeResponse { get; set; }
    public Data_Template__c relationTemplate { get; set; }
    public List<Account> sObjectList { get; set; }
    public Map<String, String> fieldLabelList { get; set; }
    public Boolean enableADD { get; set; }
    public Boolean quickCreate { get; set; }
    public String currentNamespace { get; set; }
    public String selectedAttachmentType { get; set; }
    private String referenceKey;
    // This variable should be transient to avoid view state issue. It is only doing callout if there is no attachment under org credential.
    @TestVisible
    private transient CopadoDescribeGlobalResponse describeGlobalResponse {
        get {
            try {
                if (describeGlobalResponse == null) {
                    Attachment existingDescribeGlobalAttachment = checkGlobalDescribeResult(template);
                    if (existingDescribeGlobalAttachment == null) {
                        if (pageMessagesMap.isEmpty()) {
                            DescribeSObjectService.DescribeGlobalResponse describerResponse = new DescribeSObjectService(
                                    template.Template_Source_Org__c
                                )
                                .getObjects();
                            // convert to existing wrapper class for compatibility reasons
                            describeGlobalResponse = (CopadoDescribeGlobalResponse) JSON.deserialize(
                                JSON.serialize(describerResponse),
                                CopadoDescribeGlobalResponse.class
                            );
                            if (!describeGlobalResponse.success) {
                                pageMessagesMap.put(C_ERROR, new List<Object>{ describeGlobalResponse.error });
                            }
                        }
                    } else {
                        describeGlobalResponse = (CopadoDescribeGlobalResponse) JSON.deserialize(
                            existingDescribeGlobalAttachment.Body.toString(),
                            CopadoDescribeGlobalResponse.class
                        );
                    }
                }
                return describeGlobalResponse;
            } catch (Exception excp) {
                pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
                return new CopadoDescribeGlobalResponse();
            }
        }
        set {
            describeGlobalResponse = value;
        }
    }

    // Constants
    private final String NONE = '--None--';
    private final String TEMPLATE_DETAIL = 'Template Detail';
    private final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';
    private final String ADD_DESCRIBE_GLOBAL = 'ADD_Describe_Global_Result';
    private final String C_STRING = 'STRING';
    private final String C_ERROR = 'error';
    private final String C_WARNING = 'warning';
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
    private final String C_ADDRESS = 'address';
    private final String C_GEOLOCATION = 'location';
    private final String UTF_8 = 'UTF-8';
    private final String C_ORGANIZATION = 'organization/';
    private final String C_METADATA = '/metadata/';
    private final String C_ID = 'Id';
    private final String C_OWNER_ID = 'OwnerId';
    private final String EMPTY_STRING = '';
    private final String BLANK_SPACE = ' ';
    private final String CUSTOM_FILTER = 'Custom Filter';
    private final String RECORD_MATCHING = 'recordMatching';

    /**
     * The extension constructor initializes the public template member
     *
     * @param stdController
     */
    public DataTemplateSetupExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Data_Template__c.fields.getMap().keySet()));
        }
        this.template = (Data_Template__c) stdController.getRecord();

        // currentNamespace is holding the namespace "copado__" and it is used in javascript to open relational diagram lwc
        currentNamespace = DataTemplateSetupExtension.class.getName().substringBefore('DataTemplateSetupExtension').removeEnd('.').toLowerCase();
        pageMessagesMap = new Map<String, List<Object>>();
        generalMessagesMap = new Map<String, List<Object>>();
        selectedAttachmentType = EMPTY_STRING;
        if (template.Id != null) {
            readAttachment();
        } else {
            template.Filter_Logic__c = '1';
            template.Batch_Size__c = 200;
            resetTemplate();
        }
        checkTemplateConditions();
        relationTemplate = new Data_Template__c();
        referenceKey = EMPTY_STRING;
        quickCreate = false;

        // make sure both maps (desResponse.fields and selectableFieldsMap) have same fields, otherwise apex:repeat in VF page will fail
        ensureSelectableFieldsContainsDescribeFields();
    }

    /**
     * It is used to read attachment tied to Data_Template__c record to populate all information on page load
     */
    private void readAttachment() {
        try {
            List<Attachment> attachments = new List<Attachment>();
            Set<String> attachmentNames = new Set<String>{ TEMPLATE_DETAIL, ADD_DESCRIBE_SOBJECT };
            attachments = getAttachments(template.Id, attachmentNames);
            if (!attachments.isEmpty()) {
                for (Attachment att : attachments) {
                    if (att.Name == TEMPLATE_DETAIL) {
                        String body = att.Body.toString();
                        TemplateObjectWrapper dummyWrapper = (TemplateObjectWrapper) JSON.deserialize(body, TemplateObjectWrapper.class);
                        criteriaWrapperList = dummyWrapper.queryFilterList;
                        selectableFieldsMap = dummyWrapper.selectableFieldsMap;
                        selectableChildRelationsMap = dummyWrapper.selectableChildRelationsMap;
                        if (dummyWrapper.dataTemplate != null) {
                            template.Id = dummyWrapper.dataTemplate.templateId;
                            template.Name = dummyWrapper.dataTemplate.templateName;
                            template.Template_Source_Org__c = dummyWrapper.dataTemplate.templateSourceOrg;
                            template.Main_Object__c = dummyWrapper.dataTemplate.templateMainObject;
                            template.Match_Owners__c = dummyWrapper.dataTemplate.templateMatchOwners;
                            template.Match_Record_Type__c = dummyWrapper.dataTemplate.templateMatchRecordTypes;
                            template.Continue_on_Error__c = dummyWrapper.dataTemplate.templateContinueOnError;
                            template.Active__c = dummyWrapper.dataTemplate.templateActive;
                            template.Description__c = dummyWrapper.dataTemplate.templateDescription;
                            template.Attachment_Options__c = dummyWrapper.dataTemplate.templateAttachmentOption;
                            template.Filter_Logic__c = dummyWrapper.dataTemplate.templateFilterLogic;
                            template.Batch_Size__c = dummyWrapper.dataTemplate.templateBatchSize;
                            template.Max_Record_Limit__c = dummyWrapper.dataTemplate.templateQueryLimit;
                        }

                        // checking templateSelectedAttachmentType, becuase old version attahcments do not contain this parameter.
                        Boolean attachmentTypeParameterExist = dummyWrapper.dataTemplate.templateSelectedAttachmentType != null;
                        selectedAttachmentType = attachmentTypeParameterExist
                            ? dummyWrapper.dataTemplate.templateSelectedAttachmentType
                            : EMPTY_STRING;
                    }

                    if (att.Name == ADD_DESCRIBE_SOBJECT) {
                        String body = att.Body.toString();
                        DescribeResponse dummyWrapper = (DescribeResponse) JSON.deserialize(body, DescribeResponse.class);
                        desResponse = dummyWrapper;
                    }
                }
                adjustDescribeResultField();
                populateTemplatePicklist(null, template);

                // We can not serialize selectoption to json so we cleared them before. We have to call a function to auto populate possible actions based on selected type at the filter criteria
                if (!criteriaWrapperList.isEmpty()) {
                    for (Integer i = 0; i < criteriaWrapperList.size(); i++) {
                        populateFilterCriteriaFields(i, false);
                    }
                }
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    private void adjustDescribeResultField() {
        List<CopadoField> tempDescribeFields = new List<CopadoField>();
        String invalidFieldsForTemplate = getInvalidFieldsForTemplate();
        List<String> invalidFieldsForTemplates = invalidFieldsForTemplate.toLowerCase().split(',');

        if (desResponse != null && desResponse.fields != null) {
            for (CopadoField copadoFld : desResponse.fields) {
                if (
                    copadoFld.name.toLowerCase() == C_OWNER_ID.toLowerCase() ||
                    copadoFld.name.toLowerCase() == C_ID.toLowerCase() ||
                    !invalidFieldsForTemplates.contains(copadoFld.name.toLowerCase())
                ) {
                    tempDescribeFields.add(copadoFld);
                }
            }
            desResponse.fields.clear();
            desResponse.fields.addAll(tempDescribeFields);
        }
        tempDescribeFields.clear();
    }

    /**
     * It is used to populate template picklist for parent and child objects
     * This method also will call "populateFieldContentUpdateForFields" method to pre-populate fieldcontent update for each object fields
     */
    private void populateTemplatePicklist(String mainObj, Data_Template__c tempTemplate) {
        if (describeGlobalResponse != null && describeGlobalResponse.sobjects != null) {
            Map<String, String> objectLabelsByObjectName = new Map<String, String>();
            for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                objectLabelsByObjectName.put(desObj.name, desObj.label);
            }
            Map<String, Map<String, String>> deploymentTemplateNameMap = getDataTemplates(objectLabelsByObjectName, tempTemplate);
            Map<String, String> tempDeploymentTemplateNameMap = new Map<String, String>();
            if (desResponse != null && desResponse.fields != null) {
                for (CopadoField copadoFld : desResponse.fields) {
                    if (selectableFieldsMap != null && selectableFieldsMap.containsKey(copadoFld.name)) {
                        CopadoSelectedField copadoSelectedFieldItem = selectableFieldsMap.get(copadoFld.name);
                        if (copadoFld.referenceTo != null) {
                            for (String refTo : copadoFld.referenceTo) {
                                tempDeploymentTemplateNameMap = copadoSelectedFieldItem.deploymentTemplateNameMap;
                                copadoSelectedFieldItem.deploymentTemplateNameMap = new Map<String, String>();
                                if (deploymentTemplateNameMap.containsKey(refTo)) {
                                    copadoSelectedFieldItem.deploymentTemplateNameMap.putAll(deploymentTemplateNameMap.get(refTo));

                                    if (mainObj != null && mainObj == refTo && String.isNotBlank(referenceKey) && referenceKey == copadoFld.name) {
                                        copadoSelectedFieldItem.deploymentTemplate = tempTemplate.Name;
                                        copadoSelectedFieldItem.deploymentTemplateNameMap.put(tempTemplate.Id, tempTemplate.Name);
                                    }
                                }

                                // If template name is updated in a new tab, this line will catch it but it wont be updated unless they click on save template button
                                if (
                                    copadoSelectedFieldItem.deploymentTemplate != null &&
                                    copadoSelectedFieldItem.deploymentTemplate != Label.Select_Template
                                ) {
                                    for (String templateId : tempDeploymentTemplateNameMap.keySet()) {
                                        Boolean nameIsChanged =
                                            copadoSelectedFieldItem.deploymentTemplateNameMap.containsKey(templateId) &&
                                            copadoSelectedFieldItem.deploymentTemplateNameMap.get(templateId) !=
                                            copadoSelectedFieldItem.deploymentTemplate;
                                        if (
                                            tempDeploymentTemplateNameMap.get(templateId) == copadoSelectedFieldItem.deploymentTemplate &&
                                            nameIsChanged
                                        ) {
                                            copadoSelectedFieldItem.deploymentTemplate = copadoSelectedFieldItem.deploymentTemplateNameMap.get(
                                                templateId
                                            );
                                            break;
                                        }
                                    }
                                }
                            }
                        } else {
                            populateFieldContentUpdateForFields(copadoFld, copadoSelectedFieldItem);
                        }
                    }
                }
            }

            if (desResponse != null && desResponse.childRelationshipsList != null) {
                for (Integer i = 0; i < desResponse.childRelationshipsList.size(); i++) {
                    for (CopadoChildRelationship childItem : desResponse.childRelationshipsList[i]) {
                        if (
                            selectableChildRelationsMap != null &&
                            selectableChildRelationsMap.containsKey(childItem.field + '-' + childItem.relationshipName)
                        ) {
                            CopadoSelectedChildRelationship selectedChildItem = selectableChildRelationsMap.get(
                                childItem.field +
                                '-' +
                                childItem.relationshipName
                            );

                            tempDeploymentTemplateNameMap = selectedChildItem.deploymentTemplateNameMap;
                            selectedChildItem.deploymentTemplateNameMap = new Map<String, String>();
                            if (deploymentTemplateNameMap.containsKey(selectedChildItem.childSObject)) {
                                selectedChildItem.deploymentTemplateNameMap.putAll(deploymentTemplateNameMap.get(selectedChildItem.childSObject));
                                if (
                                    mainObj != null &&
                                    mainObj == selectedChildItem.childSObject &&
                                    String.isNotBlank(referenceKey) &&
                                    referenceKey == selectedChildItem.relationshipName
                                ) {
                                    selectedChildItem.deploymentTemplate = tempTemplate.Name;
                                    selectedChildItem.deploymentTemplateNameMap.put(tempTemplate.Id, tempTemplate.Name);
                                }
                            }

                            // If template name is updated in a new tab, this line will catch it but it wont be updated unless they click on save template button
                            if (selectedChildItem.deploymentTemplate != null && selectedChildItem.deploymentTemplate != Label.Select_Template) {
                                for (String templateId : tempDeploymentTemplateNameMap.keySet()) {
                                    Boolean nameIsChanged =
                                        selectedChildItem.deploymentTemplateNameMap.containsKey(templateId) &&
                                        selectedChildItem.deploymentTemplateNameMap.get(templateId) != selectedChildItem.deploymentTemplate;
                                    if (tempDeploymentTemplateNameMap.get(templateId) == selectedChildItem.deploymentTemplate && nameIsChanged) {
                                        selectedChildItem.deploymentTemplate = selectedChildItem.deploymentTemplateNameMap.get(templateId);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            objectLabelsByObjectName.clear();
        }
    }

    /**
     * It is used to reset all wrapper class lists
     * NOTE: If we decide to create another package for ADD, QueryEditor should be duplicated!!!
     *
     * @see QueryEditor
     */
    private void resetTemplate() {
        pageMessagesMap.clear();
        desResponse = new DescribeResponse();
        selectableFieldsMap = new Map<String, CopadoSelectedField>();
        selectableChildRelationsMap = new Map<String, CopadoSelectedChildRelationship>();
        criteriaWrapperList = new List<QueryEditor.CriteriaWrapper>();
        template.Match_Owners__c = false;
        template.Match_Record_Type__c = false;
        addNewCriteria();
    }

    /**
     * It is used to reset previous data template record
     *
     */
    public void resetRelationTemplate() {
        String newObjName = ApexPages.currentPage().getParameters().get('newObjName');
        referenceKey = ApexPages.currentPage().getParameters().get('fldApiName');
        relationTemplate = new Data_Template__c();
        relationTemplate.Name = populateTemplateName(newObjName);
        relationTemplate.Template_Source_Org__c = template.Template_Source_Org__c;
        relationTemplate.Main_Object__c = newObjName;
        relationTemplate.Active__c = true;
        relationTemplate.Continue_on_Error__c = 'Continue deployment until blocker issue';
        quickCreate = true;
    }

    /**
     * It is used to populate template name
     *
     * @param objectName
     *
     * @return
     */
    @TestVisible
    private String populateTemplateName(String objectName) {
        return returnSelectedObjectLabel(objectName) + BLANK_SPACE + Label.Template;
    }

    /**
     * It is used to return object label name by checking given object api name
     */

    private String returnSelectedObjectLabel(String objectName) {
        String selectedObjectLabel = EMPTY_STRING;
        if (describeGlobalResponse != null && describeGlobalResponse.sobjects != null) {
            for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                if (desObj.name == objectName) {
                    selectedObjectLabel = desObj.label;
                    break;
                }
            }
        }
        return selectedObjectLabel;
    }

    /**
     * It is used to check if given template name is already exist
     */
    private void duplicateTemplateNameChecker(Data_Template__c givenTemplate) {
        Map<String, String> objectLabelsByObjectName = new Map<String, String>();
        for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
            objectLabelsByObjectName.put(desObj.name, desObj.label);
        }

        Map<String, Map<String, String>> deploymentTemplateNameMap = getDataTemplates(objectLabelsByObjectName, givenTemplate, false);
        pageMessagesMap.clear();
        if (
            givenTemplate.Name != null &&
            givenTemplate.Main_Object__c != null &&
            deploymentTemplateNameMap.containsKey(givenTemplate.Main_Object__c)
        ) {
            deploymentTemplateNameMap.get(givenTemplate.Main_Object__c).remove(givenTemplate.Id);
            if (deploymentTemplateNameMap.get(givenTemplate.Main_Object__c).values().contains(givenTemplate.Name)) {
                String message = String.format(Label.Duplicate_Template_Name, new List<String>{ givenTemplate.name });
                pageMessagesMap.put(C_ERROR, new List<Object>{ message });
                return;
            }
        }
    }

    /**
     * It is used to create a new data template for selected relation object
     *
     * @return
     */
    public void createNewDataTemplateAndGo() {
        try {
            TempCopadoResult tempCopadoResult = populateSelectedObjectFields(relationTemplate);
            DescribeResponse relationDesResponse = tempCopadoResult.desResponse;

            if (relationDesResponse == null && !pageMessagesMap.isEmpty()) {
                return;
            }

            duplicateTemplateNameChecker(relationTemplate);
            // In previous line we did duplicate name check, So if the map is not null we will retun and show message.
            if (!pageMessagesMap.isEmpty()) {
                return;
            }

            if (relationTemplate.Name == null && relationTemplate.Main_Object__c != null) {
                relationTemplate.Name = populateTemplateName(relationTemplate.Main_Object__c);
            }

            Utilities.Secure_DML(relationTemplate, Utilities.DML_Action.UPS, schema.SObjectType.Data_Template__c);
            DataTemplateDetails templateDetail = new DataTemplateDetails();
            templateDetail.templateId = relationTemplate.Id;
            templateDetail.templateName = relationTemplate.Name;
            templateDetail.templateSourceOrg = relationTemplate.Template_Source_Org__c;
            templateDetail.templateMainObject = relationTemplate.Main_Object__c;
            templateDetail.templateMatchOwners = relationTemplate.Match_Owners__c;
            templateDetail.templateMatchRecordTypes = relationTemplate.Match_Record_Type__c;
            templateDetail.templateContinueOnError = relationTemplate.Continue_on_Error__c;
            templateDetail.templateActive = relationTemplate.Active__c;
            templateDetail.templateDescription = EMPTY_STRING;
            templateDetail.templateAttachmentOption = template.Attachment_Options__c;
            templateDetail.templateFilterLogic = '1';
            templateDetail.templateBatchSize = template.Batch_Size__c;
            templateDetail.templateQueryLimit = template.Max_Record_Limit__c;
            templateDetail.templateSelectedAttachmentType = EMPTY_STRING; // it is parent or child so, the value will be empty

            TemplateObjectWrapper templateObject = new TemplateObjectWrapper();
            templateObject.dataTemplate = templateDetail;
            templateObject.parentObjectsReferenceList = new List<RelationTemplateDetails>();
            templateObject.childrenObjectsReferenceList = new List<RelationTemplateDetails>();
            templateObject.queryFilterList = new List<QueryEditor.CriteriaWrapper>();
            templateObject.selectableFieldsMap = tempCopadoResult.selectableFieldsMap;
            templateObject.selectableChildRelationsMap = tempCopadoResult.selectableChildRelationsMap;

            List<Attachment> attachments = new List<Attachment>();
            Attachment attachment = createAttachments(null, TEMPLATE_DETAIL, relationTemplate.Id, JSON.serialize(templateObject));
            attachments.add(attachment);

            Attachment describeSobjectAttachment = createAttachments(
                null,
                ADD_DESCRIBE_SOBJECT,
                relationTemplate.Id,
                JSON.serialize(relationDesResponse)
            );
            attachments.add(describeSobjectAttachment);

            // Describe global will be stored at org credential
            Attachment existingDescribeGlobalAttachment = checkGlobalDescribeResult(relationTemplate);
            if (existingDescribeGlobalAttachment == null) {
                Attachment describeGlobalAttachment = createAttachments(
                    null,
                    ADD_DESCRIBE_GLOBAL,
                    relationTemplate.Template_Source_Org__c,
                    JSON.serialize(describeGlobalResponse)
                );
                attachments.add(describeGlobalAttachment);
            }

            Utilities.Secure_DML(attachments, Utilities.DML_Action.INS, schema.SObjectType.Attachment);

            populateTemplatePicklist(relationTemplate.Main_Object__c, relationTemplate);
            quickCreate = false;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    /**
     * It is used to populate all objects in selected org
     * Only triggerable objects should be selected
     * Exclude custom metadata type "__mdt"
     * Exclude platform events "__e"
     * Exclude some default objects such as; "history", "tag", "share", "feed", "changeevent"
     * Exclude some specific object that defined at Data_Template_Setup__mdt.Disabled_Main_Objects
     *
     * @return
     */
    public List<SelectOption> getAllObjects() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(NONE, NONE));
        if (describeGlobalResponse != null && describeGlobalResponse.sobjects != null) {
            String disabledMainObjects = getDisabledObjects('Disabled_Main_Objects');
            List<String> disabledMainObjectList = disabledMainObjects.split(',');
            for (Integer i = 0; i < describeGlobalResponse.sobjects.size(); i++) {
                // Exclude all the unwanted Sobjects e.g. History, Share etc..
                Boolean isUnwantedSobjects =
                    describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('history') ||
                    describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('tag') ||
                    describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('share') ||
                    describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('feed') ||
                    describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('changeevent');
                //Exclude all custom metadata types
                Boolean isCustomMetadataTypes = describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('__mdt');
                // Exclude all platform events
                Boolean isPlatformEvents = describeGlobalResponse.sobjects[i].name.endsWithIgnoreCase('__e');
                Boolean disabledObject = disabledMainObjectList.isEmpty()
                    ? false
                    : disabledMainObjectList.contains(describeGlobalResponse.sobjects[i].name) ? true : false;
                Boolean isObjectTriggerable = describeGlobalResponse.sobjects[i].triggerable;
                if (!isUnwantedSobjects && !isCustomMetadataTypes && !isPlatformEvents && isObjectTriggerable && !disabledObject) {
                    options.add(
                        new SelectOption(
                            describeGlobalResponse.sobjects[i].name,
                            describeGlobalResponse.sobjects[i].label +
                            ' (' +
                            describeGlobalResponse.sobjects[i].name +
                            ')'
                        )
                    );
                }
            }
        }
        return options;
    }

    /**
     * It is used to populate pagemessages map by given details
     */
    private void addMessageToPageMessages(String severity, String message) {
        if (!generalMessagesMap.containsKey(severity)) {
            generalMessagesMap.put(severity, new List<Object>{ message });
        } else {
            generalMessagesMap.get(severity).add(message);
        }
    }

    /**
     * It is used to check the status of the current template and populate warnings and errors if exist
     */
    private void checkTemplateConditions() {
        String userId = UserInfo.getUserId();
        Copado_License__c copadoLicense = Copado_License__c.getInstance(userId);
        enableADD = copadoLicense.Enable_ADD__c;

        if (!enableADD) {
            addMessageToPageMessages(C_WARNING, Label.ADD_License_Required);
        }

        Boolean recordMatchingFormulaNotDefined = false;
        List<Record_Matching_Formula__c> recordMatchings = getRecordMatchingFormula();
        for (Record_Matching_Formula__c recordMatchingFormulaRecord : recordMatchings) {
            Boolean firstFieldEmpty = recordMatchingFormulaRecord.Field_1__c == null;
            Boolean secondFieldEmpty = recordMatchingFormulaRecord.Field_2__c == null;
            Boolean thirdFieldEmpty = recordMatchingFormulaRecord.Field_3__c == null;

            if (firstFieldEmpty && secondFieldEmpty && thirdFieldEmpty) {
                recordMatchingFormulaNotDefined = true;
            }
        }
        Boolean recordMatchingFormulaNotCreated = recordMatchings.isEmpty();

        if (desResponse != null && desResponse.fields != null) {
            String invalidFieldsForTemplate = getInvalidFieldsForTemplate();
            Map<String, String> invalidFieldsByFieldNames = new Map<String, String>();
            List<String> invalidFieldsForTemplates = invalidFieldsForTemplate.split(',');
            for (String fieldName : invalidFieldsForTemplates) {
                invalidFieldsByFieldNames.put(fieldName.toLowerCase(), fieldName.toLowerCase());
            }

            String notValidParentObjects = getNotValidParent();
            Set<String> describeFieldsNameSet = new Set<String>();
            Set<String> childObjectNameSet = new Set<String>();
            Boolean newFields = false;

            for (CopadoField copadoFld : desResponse.fields) {
                describeFieldsNameSet.add(copadoFld.name);
                String message = EMPTY_STRING;
                if (selectableFieldsMap != null && selectableFieldsMap.containsKey(copadoFld.name)) {
                    CopadoSelectedField copadoSelectedFieldItem = selectableFieldsMap.get(copadoFld.name);
                    Boolean fieldContentUpdateRFecordMatching = copadoSelectedFieldItem.fieldContentUpdate == RECORD_MATCHING;
                    if (
                        (recordMatchingFormulaNotDefined && fieldContentUpdateRFecordMatching) ||
                        (recordMatchingFormulaNotCreated && fieldContentUpdateRFecordMatching)
                    ) {
                        addMessageToPageMessages(C_ERROR, Label.Record_Matching_Not_Configured);
                    }

                    if (
                        !copadoSelectedFieldItem.isSelected &&
                        !copadoFld.nillable &&
                        !invalidFieldsByFieldNames.containsKey(copadoFld.name.toLowerCase())
                    ) {
                        message = String.format(Label.ADD_Object_Warning, new List<String>{ copadoFld.label });
                        addMessageToPageMessages(C_WARNING, message);
                    } else if (
                        copadoSelectedFieldItem.isSelected &&
                        copadoFld.referenceTo != null &&
                        (String.isBlank(copadoSelectedFieldItem.deploymentTemplate) ||
                        copadoSelectedFieldItem.deploymentTemplate == Label.Select_Template)
                    ) {
                        for (String refTo : copadoFld.referenceTo) {
                            if (!notValidParentObjects.contains(refTo) && refTo != 'User') {
                                message = String.format(Label.ADD_Parent_Object_Warning, new List<String>{ copadoFld.label });
                                addMessageToPageMessages(C_ERROR, message);
                            }
                        }
                    }
                } else if (
                    selectableFieldsMap != null &&
                    !selectableFieldsMap.containsKey(copadoFld.name) &&
                    !invalidFieldsForTemplate.contains(copadoFld.name)
                ) {
                    Boolean isParent = copadoFld.referenceTo != null;
                    String generalMessage = isParent ? Label.New_Parent_Object : Label.New_Field_Source_Org;
                    message = String.format(generalMessage, new List<String>{ copadoFld.label, template.Main_Object__c });
                    addMessageToPageMessages(C_WARNING, message);
                    newFields = true;
                }
            }

            for (String fldName : selectableFieldsMap.keySet()) {
                if (!describeFieldsNameSet.isEmpty() && !describeFieldsNameSet.contains(fldName) && selectableFieldsMap.get(fldName).isSelected) {
                    newFields = true;
                    String message = String.format(Label.Removed_Field_Source_Org, new List<String>{ fldName, template.Main_Object__c });
                    addMessageToPageMessages(C_ERROR, message);
                }
            }

            if (newFields) {
                createCopadoSelectedField(template, desResponse, selectableFieldsMap, true);
            }

            if (desResponse.childRelationshipsList != null) {
                for (Integer i = 0; i < desResponse.childRelationshipsList.size(); i++) {
                    for (CopadoChildRelationship childItem : desResponse.childRelationshipsList[i]) {
                        childObjectNameSet.add(childItem.childSObject);
                        String message = EMPTY_STRING;
                        if (
                            selectableChildRelationsMap != null &&
                            childItem.relationshipName != null &&
                            selectableChildRelationsMap.containsKey(childItem.field + '-' + childItem.relationshipName)
                        ) {
                            CopadoSelectedChildRelationship selectedChildItem = selectableChildRelationsMap.get(
                                childItem.field +
                                '-' +
                                childItem.relationshipName
                            );
                            if (
                                selectedChildItem.isSelected &&
                                (selectedChildItem.deploymentTemplate == null ||
                                selectedChildItem.deploymentTemplate == Label.Select_Template ||
                                selectedChildItem.deploymentTemplate == EMPTY_STRING)
                            ) {
                                message = String.format(
                                    Label.ADD_Child_Object_Warning,
                                    new List<String>{ selectedChildItem.objectApiNameMap.get(childItem.childSObject) }
                                );
                                addMessageToPageMessages(C_ERROR, message);
                            }
                        } else if (
                            selectableChildRelationsMap != null &&
                            childItem.relationshipName != null &&
                            !selectableChildRelationsMap.containsKey(childItem.field + '-' + childItem.relationshipName)
                        ) {
                            Map<String, String> objectLabelsByObjectName = new Map<String, String>();
                            for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                                objectLabelsByObjectName.put(desObj.name, desObj.label);
                            }
                            Map<String, Map<String, String>> deploymentTemplateNameMap = getDataTemplates(objectLabelsByObjectName, template);
                            if (!pageMessagesMap.isEmpty()) {
                                return;
                            }

                            CopadoSelectedChildRelationship selectedChildItem = new CopadoSelectedChildRelationship();
                            selectedChildItem.childSObject = childItem.childSObject;
                            selectedChildItem.field = childItem.field;
                            selectedChildItem.relationshipName = childItem.relationshipName;

                            if (
                                objectLabelsByObjectName.containsKey(childItem.childSObject) &&
                                objectLabelsByObjectName.get(childItem.childSObject) != null
                            ) {
                                selectedChildItem.objectApiNameMap.put(childItem.childSObject, objectLabelsByObjectName.get(childItem.childSObject));
                            }

                            selectedChildItem.deploymentTemplateNameMap = new Map<String, String>();
                            if (deploymentTemplateNameMap.containsKey(childItem.childSObject)) {
                                selectedChildItem.deploymentTemplateNameMap.putAll(deploymentTemplateNameMap.get(childItem.childSObject));
                            }

                            selectableChildRelationsMap.put(childItem.field + '-' + childItem.relationshipName, selectedChildItem);

                            message = String.format(Label.New_Child_Object, new List<String>{ childItem.childSObject, template.Main_Object__c });
                            addMessageToPageMessages(C_WARNING, message);
                        }
                    }
                }
            }

            for (String fld : selectableChildRelationsMap.keySet()) {
                if (
                    !childObjectNameSet.isEmpty() &&
                    !childObjectNameSet.contains(selectableChildRelationsMap.get(fld).childSObject) &&
                    selectableChildRelationsMap.get(fld).isSelected
                ) {
                    String message = String.format(
                        Label.Removed_Field_Source_Org,
                        new List<String>{ selectableChildRelationsMap.get(fld).childSObject, template.Main_Object__c }
                    );
                    addMessageToPageMessages(C_ERROR, message);
                }
            }
        }
    }

    @TestVisible
    private void ensureSelectableFieldsContainsDescribeFields() {
        if (desResponse?.fields != null && selectableFieldsMap != null) {
            Boolean fieldMissing = false;
            for (CopadoField copadoFld : desResponse.fields) {
                if (!selectableFieldsMap.containsKey(copadoFld.name)) {
                    fieldMissing = true;
                    Boolean isParent = copadoFld.referenceTo != null;
                    String generalMessage = isParent ? Label.New_Parent_Object : Label.New_Field_Source_Org;
                    String message = String.format(generalMessage, new List<String>{ copadoFld.label, template.Main_Object__c });
                    addMessageToPageMessages(C_WARNING, message);
                }
            }
            if (fieldMissing) {
                createCopadoSelectedField(template, desResponse, selectableFieldsMap, true);
            }
        }
    }

    /**
     * It is used to populate selected objects fields for "Object Fields" tab. It is called from VF page
     */
    public void populateSelectedObjectFields() {
        resetTemplate();
        TempCopadoResult tempCopadoResult = populateSelectedObjectFields(template);
        if (pageMessagesMap.isEmpty() && tempCopadoResult != null) {
            desResponse = tempCopadoResult.desResponse;
            adjustDescribeResultField();
            selectableFieldsMap = tempCopadoResult.selectableFieldsMap;
            selectableChildRelationsMap = tempCopadoResult.selectableChildRelationsMap;
        }
    }

    /**
     * It is used to populate CopadoSelectedField object map that given in the parameter.
     *
     * @param dataTemplate
     * @param dResponse
     * @param tempSelectableFieldsMap
     */
    private void createCopadoSelectedField(
        Data_Template__c dataTemplate,
        DescribeResponse dResponse,
        Map<String, CopadoSelectedField> tempSelectableFieldsMap,
        Boolean isRefreshed
    ) {
        Map<String, String> objectLabelsByObjectName = new Map<String, String>();
        for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
            objectLabelsByObjectName.put(desObj.name, desObj.label);
        }
        Map<String, Map<String, String>> deploymentTemplateNameMap = getDataTemplates(objectLabelsByObjectName, dataTemplate);
        if (!pageMessagesMap.isEmpty()) {
            return;
        }

        Set<String> fieldNameSet = new Set<String>();
        Boolean firstExternalIdField = false;
        String invalidFieldsForTemplate = getInvalidFieldsForTemplate();
        Map<String, String> invalidFieldsByFieldNames = new Map<String, String>();
        List<String> invalidFieldsForTemplates = invalidFieldsForTemplate.split(',');
        for (String fieldName : invalidFieldsForTemplates) {
            invalidFieldsByFieldNames.put(fieldName.toLowerCase(), fieldName.toLowerCase());
        }

        for (CopadoField copadoFld : dResponse.fields) {
            fieldNameSet.add(copadoFld.name);
            Boolean isIdField = (copadoFld.name != null && copadoFld.name == C_ID);
            Boolean validFieldAndNotRefreshed = (!invalidFieldsByFieldNames.containsKey(copadoFld.name.toLowerCase()) && !isRefreshed);
            Boolean isRefreshedAndSelectableMapNotContains = (isRefreshed &&
            !tempSelectableFieldsMap.isEmpty() &&
            !tempSelectableFieldsMap.containsKey(copadoFld.name));

            if (isIdField || validFieldAndNotRefreshed || isRefreshedAndSelectableMapNotContains) {
                CopadoSelectedField copadoSelectedFieldItem = new CopadoSelectedField();
                copadoSelectedFieldItem.label = copadoFld.label;
                copadoSelectedFieldItem.name = copadoFld.name;
                copadoSelectedFieldItem.fieldType = copadoFld.type;
                copadoSelectedFieldItem.externalId = copadoFld.externalId;

                Boolean standardFieldsToUnSelect = copadoFld.name != C_ID.toLowerCase() && invalidFieldsByFieldNames.containsKey(copadoFld.name);
                // all object fields will be default selected unless they are listed above
                copadoSelectedFieldItem.isSelected = !standardFieldsToUnSelect;

                // first external id field will be auto selected
                if (!firstExternalIdField && copadoFld.externalId) {
                    copadoSelectedFieldItem.useAsExternalId = true;
                    firstExternalIdField = true;
                }

                if (copadoFld.referenceTo != null) {
                    for (String refTo : copadoFld.referenceTo) {
                        if (objectLabelsByObjectName.containsKey(refTo) && objectLabelsByObjectName.get(refTo) != null) {
                            copadoSelectedFieldItem.parentObjectApiNameMap.put(refTo, objectLabelsByObjectName.get(refTo));
                        }

                        copadoSelectedFieldItem.deploymentTemplateNameMap = new Map<String, String>();
                        if (deploymentTemplateNameMap.containsKey(refTo)) {
                            copadoSelectedFieldItem.deploymentTemplateNameMap.putAll(deploymentTemplateNameMap.get(refTo));
                        }

                        // not required parent object will not be selected by default
                        if (copadoFld.nillable || (quickCreate != null && quickCreate)) {
                            copadoSelectedFieldItem.isSelected = false;
                        }
                    }
                }
                populateFieldContentUpdateForFields(copadoFld, copadoSelectedFieldItem);
                tempSelectableFieldsMap.put(copadoFld.name, copadoSelectedFieldItem);
            }
        }

        if (!tempSelectableFieldsMap.isEmpty() && isRefreshed) {
            for (String fldName : tempSelectableFieldsMap.keySet()) {
                if (!fieldNameSet.isEmpty() && !fieldNameSet.contains(fldName)) {
                    tempSelectableFieldsMap.remove(fldName);
                }
            }
        }
    }

    /**
     * It is used to populate field content update picklist field based on the field type
     */
    private void populateFieldContentUpdateForFields(CopadoField copadoFld, CopadoSelectedField copadoSelectedFieldItem) {
        // first of all we will clear all value, because old attachments still include different value for external id
        copadoSelectedFieldItem.contentValueUpdateValues = new Map<String, String>();

        if (!copadoFld.externalId) {
            // populating the field content update values
            // this value will be activated in future releases so do not delete this line
            copadoSelectedFieldItem.contentValueUpdateValues.put(Label.Replace_Value, 'replace');

            Set<String> scrambleValuesSet = new Set<String>{
                C_TEXTAREA.toLowerCase(),
                C_TEXT.toLowerCase(),
                C_CURRENCY.toLowerCase(),
                C_DOUBLE.toLowerCase(),
                C_PERCENT.toLowerCase(),
                C_STRING.toLowerCase(),
                C_INT.toLowerCase()
            };

            if (scrambleValuesSet.contains(copadoFld.type)) {
                copadoSelectedFieldItem.contentValueUpdateValues.put(Label.Scramble_Value, 'scramble');
            }

            Set<String> scrambleWithFormatValuesSet = new Set<String>{
                C_TEXTAREA.toLowerCase(),
                C_TEXT.toLowerCase(),
                C_CURRENCY.toLowerCase(),
                C_DOUBLE.toLowerCase(),
                C_PERCENT.toLowerCase(),
                C_PHONE.toLowerCase(),
                C_EMAIL.toLowerCase(),
                C_STRING.toLowerCase(),
                C_INT.toLowerCase()
            };

            if (scrambleWithFormatValuesSet.contains(copadoFld.type)) {
                copadoSelectedFieldItem.contentValueUpdateValues.put(Label.Scramble_With_Format, 'scrambleWithFormat');
            }
        } else {
            copadoSelectedFieldItem.contentValueUpdateValues.put(Label.Copado_Record_Matching, RECORD_MATCHING);
        }
    }

    /**
     * It is used to populate selected objects fields for "Object Fields" tab.
     * Auto number, formula fields and reference fields will not be considered for "Object Fields" tab
     * Scramble options will not be populated for "richtext", "longtext", "number", "email", "boolean", "phone" and "url"
     *
     * @see ObjectFieldsWrapper
     */
    private TempCopadoResult populateSelectedObjectFields(Data_Template__c dataTemplate) {
        TempCopadoResult tempCopadoResult = new TempCopadoResult();
        if (dataTemplate.Main_Object__c != null && dataTemplate.Main_Object__c != NONE) {
            DescribeResponse dResponse = new DescribeResponse();
            Map<String, CopadoSelectedField> tempSelectableFieldsMap = new Map<String, CopadoSelectedField>();
            Map<String, CopadoSelectedChildRelationship> tempSelectableChildRelationsMap = new Map<String, CopadoSelectedChildRelationship>();
            if (pageMessagesMap.isEmpty()) {
                try {
                    DescribeSObjectService.DescribeResponse describerResponse = new DescribeSObjectService(dataTemplate.Template_Source_Org__c)
                        .getCreateableUpdateableFields(dataTemplate.Main_Object__c);
                    // get all fields and store to use in Main Object Filter criterias
                    allFieldsDescribeResponse = new DescribeSObjectService(template.Template_Source_Org__c).getFields(template.Main_Object__c);
                    // convert to existing wrapper class for compatibility reasons (attachments)
                    dResponse = (DescribeResponse) JSON.deserialize(JSON.serialize(describerResponse), DescribeResponse.class);
                } catch (Exception excp) {
                    pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
                    return null;
                }
                if (!dResponse.success) {
                    pageMessagesMap.put(C_ERROR, new List<Object>{ dResponse.error });
                    return null;
                }
            }

            if (dResponse != null && dResponse.fields != null) {
                createCopadoSelectedField(dataTemplate, dResponse, tempSelectableFieldsMap, false);

                Map<String, String> objectLabelsByObjectName = new Map<String, String>();
                for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                    objectLabelsByObjectName.put(desObj.name, desObj.label);
                }

                Map<String, Map<String, String>> deploymentTemplateNameMap = getDataTemplates(objectLabelsByObjectName, dataTemplate);
                if (!pageMessagesMap.isEmpty()) {
                    return null;
                }

                List<List<CopadoChildRelationship>> childRelationshipsList = new List<List<CopadoChildRelationship>>();
                List<CopadoChildRelationship> childRelationships = new List<CopadoChildRelationship>();
                Integer counter = 0;
                if (dResponse.childRelationships != null) {
                    String notValidChildRelations = getNotValidChild();
                    for (CopadoChildRelationship childObj : dResponse.childRelationships) {
                        if (childObj.relationshipName != null && !notValidChildRelations.contains(childObj.relationshipName)) {
                            CopadoSelectedChildRelationship selectedChildItem = new CopadoSelectedChildRelationship();
                            selectedChildItem.childSObject = childObj.childSObject;
                            selectedChildItem.field = childObj.field;
                            selectedChildItem.relationshipName = childObj.relationshipName;

                            if (
                                objectLabelsByObjectName.containsKey(childObj.childSObject) &&
                                objectLabelsByObjectName.get(childObj.childSObject) != null
                            ) {
                                selectedChildItem.objectApiNameMap.put(childObj.childSObject, objectLabelsByObjectName.get(childObj.childSObject));
                            }

                            selectedChildItem.deploymentTemplateNameMap = new Map<String, String>();
                            if (deploymentTemplateNameMap.containsKey(childObj.childSObject)) {
                                selectedChildItem.deploymentTemplateNameMap.putAll(deploymentTemplateNameMap.get(childObj.childSObject));
                            }
                            childRelationships.add(childObj);
                            counter++;
                            if (childRelationships.size() == 1000) {
                                childRelationshipsList.add(childRelationships);
                                childRelationships = new List<CopadoChildRelationship>();
                                counter = 0;
                            }

                            tempSelectableChildRelationsMap.put(childObj.field + '-' + childObj.relationshipName, selectedChildItem);
                        }
                    }
                    childRelationshipsList.add(childRelationships);
                }
                childRelationships = new List<CopadoChildRelationship>();
                dResponse.childRelationshipsList = childRelationshipsList;
                childRelationshipsList = new List<List<CopadoChildRelationship>>();
                objectLabelsByObjectName.clear();
            }
            dResponse.childRelationships = null;
            tempCopadoResult.desResponse = dResponse;
            adjustDescribeResultField();
            tempCopadoResult.selectableFieldsMap = tempSelectableFieldsMap;
            tempCopadoResult.selectableChildRelationsMap = tempSelectableChildRelationsMap;
        }
        return tempCopadoResult;
    }

    /**
     * It is used to make a callout to the backend for given url
     *
     * @param calloutURL
     *
     * @return
     */
    private HttpResponse doCallout(String calloutURL) {
        try {
            HttpRequest req = new HttpRequest();
            String url = calloutURL;
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('userId', UserInfo.getUserId());
            req.setHeader('orgId', UserInfo.getOrganizationId());
            req.setHeader('token', DeployAPI.getAuthToken());
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
            return res;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }
    }

    /**
     * @see getDataTemplates
     */
    private Map<String, Map<String, String>> getDataTemplates(Map<String, String> objectLabelsByObjectName, Data_Template__c dataTemplate) {
        return getDataTemplates(objectLabelsByObjectName, dataTemplate, true);
    }

    /**
     * It is used to return active data templates for given main objects
     *
     * @param objectLabelsByObjectName
     *
     * @return
     */
    private Map<String, Map<String, String>> getDataTemplates(
        Map<String, String> objectLabelsByObjectName,
        Data_Template__c dataTemplate,
        Boolean checkForActiveBoolean
    ) {
        Map<String, Map<String, String>> deploymentTemplateNameMap = new Map<String, Map<String, String>>();
        if (!objectLabelsByObjectName.isEmpty()) {
            try {
                for (Data_Template__c dt : [
                    SELECT Id, Name, Main_Object__c, Active__c
                    FROM Data_Template__c
                    WHERE
                        Main_Object__c IN :objectLabelsByObjectName.keySet()
                        AND Template_Source_Org__c = :dataTemplate.Template_Source_Org__c
                        AND Id != :template.Id
                    WITH SECURITY_ENFORCED
                ]) {
                    if ((checkForActiveBoolean && dt.Active__c) || !checkForActiveBoolean) {
                        Map<String, String> innerDeploymentTemplateNameMap = new Map<String, String>();
                        innerDeploymentTemplateNameMap.put(dt.Id, dt.Name);
                        if (!deploymentTemplateNameMap.containsKey(dt.Main_Object__c)) {
                            deploymentTemplateNameMap.put(dt.Main_Object__c, innerDeploymentTemplateNameMap);
                        } else {
                            deploymentTemplateNameMap.get(dt.Main_Object__c).putAll(innerDeploymentTemplateNameMap);
                        }
                    }
                }
            } catch (Exception excp) {
                pageMessagesMap.put(
                    C_WARNING,
                    new List<Object>{
                        Label.Insufficient_Access_Rights,
                        Label.Related_Object +
                        BLANK_SPACE +
                        Schema.SObjectType.Data_Template__c.getLabel()
                    }
                );
            }
        }
        return deploymentTemplateNameMap;
    }

    /**
     * It is used to render valid parent fields at parent objects tab
     * NOTE: in the first version we will not support "User" and "Group"
     *
     * @return
     */
    public String getNotValidParent() {
        String invalidFieldsForTemplate = EMPTY_STRING;
        /*Set<String> fieldNameSet = new Set<String>();
        if (desResponse != null && desResponse.fields != null) {
            for (CopadoField copadoFld : desResponse.fields) {
                if (copadoFld.referenceTo != null && selectableFieldsMap != null && selectableFieldsMap.containsKey(copadoFld.name)) {
                    CopadoSelectedField copadoSelectedFieldItem = selectableFieldsMap.get(copadoFld.name);
                    for (String refTo : copadoFld.referenceTo) {
                        if (
                            copadoSelectedFieldItem.parentObjectApiNameMap != null &&
                            !copadoSelectedFieldItem.parentObjectApiNameMap.containsKey(refTo) &&
                            !fieldNameSet.contains(refTo)
                        ) {
                            invalidFieldsForTemplate += refTo + ', ';
                            fieldNameSet.add(refTo);
                        }
                    }
                }
            }
        }
        invalidFieldsForTemplate += getDisabledObjects('Disabled_Parent_Objects');*/
        return invalidFieldsForTemplate;
    }

    /**
     * It is used to render valid child object at child objects tab
     *
     * @return
     */
    public String getNotValidChild() {
        return getDisabledObjects('Disabled_Child_Objects');
    }

    /**
     * It is used to render valid fields for selected object
     *
     * @return
     */
    public String getInvalidFieldsForTemplate() {
        return getDisabledObjects('Disabled_Fields');
    }

    /**
     * It is used to retrieve disabled parent / child objects by using custom metadata type
     * (Data_Template_Setup__mdt => Manage Records) = (Disabled_Parent_Objects / Disabled_Child_Objects)
     *
     * @return
     */
    private String getDisabledObjects(String developerName) {
        String disabledFields = EMPTY_STRING;
        for (Data_Template_Setup__mdt cs : [SELECT Id, API_Names__c FROM Data_Template_Setup__mdt WHERE DeveloperName = :developerName LIMIT 1]) {
            disabledFields = cs.API_Names__c;
        }
        return disabledFields;
    }

    /**
     * it is used to create new empty filter criteria line
     */
    public void addNewCriteria() {
        QueryEditor.CriteriaWrapper temp = new QueryEditor.CriteriaWrapper();
        temp.setOperatorSet(setOperators());
        Integer indexValue = criteriaWrapperList != null ? criteriaWrapperList.size() + 1 : 1;
        temp.setOrder(indexValue);

        if (criteriaWrapperList == null) {
            criteriaWrapperList = new List<QueryEditor.CriteriaWrapper>();
        }
        criteriaWrapperList.add(temp);

        if (criteriaWrapperList.size() > 1) {
            template.Filter_Logic__c = String.isBlank(template.Filter_Logic__c) ? '1' : template.Filter_Logic__c;
            template.Filter_Logic__c += ' AND ' + temp.getOrder();
        }
    }

    /**
     * it is used to remove the criteria line
     */
    public void removeCriteria() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('criteriaOrder');
        if (String.isNotBlank(criteriaOrder)) {
            Integer orderToRemove = Integer.valueOf(criteriaOrder) - 1;
            criteriaWrapperList.remove(orderToRemove);
        }

        if (criteriaWrapperList.isEmpty()) {
            addNewCriteria();
        }

        for (Integer i = 0; i < criteriaWrapperList.size(); i++) {
            criteriaWrapperList[i].order = i + 1;
        }
    }

    /**
     * it is used to populate possible options at Field section of Specify Filter Criteria. '--None--' is added to as default value
     * @return
     */
    public List<SelectOption> getAllFieldsAPIName() {
        List<SelectOption> allFieldsAPIName = new List<SelectOption>();
        if(allFieldsDescribeResponse == null && !String.isBlank(template.Template_Source_Org__c) && !String.isBlank(template.Main_Object__c)){
            try {
                // get all fields and store to use in Main Object Filter criterias
                allFieldsDescribeResponse = new DescribeSObjectService(template.Template_Source_Org__c).getFields(template.Main_Object__c);
            } catch (Exception excp) {
                pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
                return allFieldsAPIName;
            }
        }
        if (allFieldsDescribeResponse != null && allFieldsDescribeResponse.fields != null) {
            allFieldsAPIName.add(new SelectOption(NONE, NONE));
            for (DescribeSObjectService.CopadoField copadoFld : allFieldsDescribeResponse.fields) {
                // checking if the current user can see these fields and only adding filterable fields to the option list
                if (copadoFld.filterable && !copadoFld.isCompound()) {
                    allFieldsAPIName.add(new SelectOption(copadoFld.label + '-' + copadoFld.name, copadoFld.label + ' (' + copadoFld.name + ')'));
                }
            }
            allFieldsAPIName.sort();
            allFieldsAPIName.add(1, new SelectOption(CUSTOM_FILTER, CUSTOM_FILTER));
        }
        return allFieldsAPIName;
    }

    /**
     * it is used to populate possible options for attachment type
     * @return
     */
    public List<SelectOption> getAttachmentTypes() {
        List<SelectOption> attachmentTypes = new List<SelectOption>();
        attachmentTypes.add(new SelectOption('files', Label.Files_Lightning));
        attachmentTypes.add(new SelectOption('attachments', Label.Attachments_Classic));
        return attachmentTypes;
    }

    /**
     * it is re-populate the operator based on selected field type
     */
    public void getFieldOperators() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('cro');
        if (!String.isBlank(criteriaOrder)) {
            Integer listOrder = Integer.valueOf(criteriaOrder) - 1;
            if (!criteriaWrapperList.isEmpty() && criteriaWrapperList.size() > listOrder) {
                populateFilterCriteriaFields(listOrder, true);
            }
        }
    }

    /**
     * populate operator set field of qEditor.
     * @param listOrder
     */
    private void populateFilterCriteriaFields(Integer listOrder, Boolean clearFields) {
        if (desResponse != null && desResponse.fields != null) {
            QueryEditor.CriteriaWrapper temp = criteriaWrapperList[listOrder];
            String criteriaField = temp.getFieldName();
            String fieldType = EMPTY_STRING;

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
            Map<String, String[]> operatorByTypes = OperatorTypeCodes.getTypeToOps();
            String fType = String.isNotBlank(fieldType) && operatorByTypes.containsKey(fieldType.toUpperCase()) ? fieldType.toUpperCase() : C_STRING;
            temp.setFieldType(fType);
            if (clearFields) {
                temp.setInput(EMPTY_STRING);
                temp.setDateInput(null);
                temp.setDateTimeInput(null);
                temp.setNumberInput(0);
            }
            List<SelectOption> criteriaOptions = new List<SelectOption>();
            criteriaOptions.add(new SelectOption(NONE, NONE));
            if (criteriaField != CUSTOM_FILTER) {
                // updating the existing operator set based on selected type on the UI
                Map<String, String> codeByOperators = OperatorTypeCodes.getOperatorCodes();
                for (String operator : operatorByTypes.get(fType)) {
                    if (codeByOperators.containsKey(operator)) {
                        criteriaOptions.add(new SelectOption(operator, codeByOperators.get(operator)));
                    }
                }
            }
            temp.setOperatorSet(criteriaOptions);
            if (temp.operator == null) {
                temp.setOperator('e');
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
        Map<String, String> codesByOperators = OperatorTypeCodes.getOperatorCodes();
        for (String code : codesByOperators.keySet()) {
            operators.add(new SelectOption(code, codesByOperators.get(code)));
        }
        return operators;
    }

    /**
     * It is used to validate query and retrieve only 5 records to show
     */
    public void generateSample() {
        /*sObjectList = new List<Account>();
        if(Schema.getGlobalDescribe().get(template.Main_Object__c).getDescribe().isAccessible() && Schema.getGlobalDescribe().get(template.Main_Object__c).getDescribe().isQueryable()) {
            sObjectList = Database.query(buildQuery());
        } else {
            pageMessagesMap.put(C_WARNING, new List<Object>{
                    Label.Insufficient_Access_Rights, Label.Related_Object + BLANK_SPACE + Schema.getGlobalDescribe().get(template.Main_Object__c).getDescribe().getLabel()
            });
        }

        String obj = 'Account';

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(obj);
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        List<String> fieldNameList = new List<String>();
        fieldLabelList = new Map<String, String>();

        for(Schema.SObjectField fld : fieldsMap.values()) {
            Schema.DescribeFieldResult dfr = fld.getDescribe();
            fieldNameList.add(dfr.name);
            fieldLabelList.put(dfr.name, dfr.label);
        }
        String query = 'SELECT ' + String.join(fieldNameList, ',') + ' FROM ' + obj + ' Limit 5';
        sObjectList = Database.query(query);*/
    }

    /**
     * loop in the criteria wrapper and create a where condition string
     * @return
     */
    private void whereConditionEditor() {
        Map<String, String> symbolsByOperators = OperatorTypeCodes.getOperatorSembols();
        for (QueryEditor.CriteriaWrapper criteriaItem : criteriaWrapperList) {
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
                Boolean isCustomNDateAndTime = (fieldType == C_DATE || fieldType == C_DATETIME) && String.isNotBlank(input) && input.contains(':n');
                Boolean isCustomStringDateAndTime =
                    (fieldType == C_DATE ||
                    fieldType == C_DATETIME) &&
                    String.isNotBlank(input) &&
                    !input.contains(':n');
                Boolean isBoolean = fieldType == C_BOOLEAN;
                Boolean isIntegerInput = fieldType == C_INTEGER || fieldType == C_DOUBLE || fieldType == C_INT;
                String newNumberInput = isCustomNDateAndTime || isIntegerInput
                    ? String.valueOf(Integer.valueOf(numberInput))
                    : String.valueOf(numberInput);
                String newDateTimeInput = isDateTimeInput
                    ? dateTimeInput.format('yyyy-MM-dd\'T\'HH:mm:ss', UserInfo.getLocale()) + 'Z'
                    : EMPTY_STRING;
                String newDateInput = isDateInput ? String.valueOf(dateInput) : EMPTY_STRING;
                String newStringValue = isCustomNDateAndTime ? inputValue.replace(':n', ':' + newNumberInput) : inputValue;
                newStringValue = isCustomStringDateAndTime || isCustomNDateAndTime || isBoolean ? newStringValue : '\'' + newStringValue + '\'';
                // input value convert to string
                newStringValue = isNumberInput ? newNumberInput : isDateInput ? newDateInput : isDateTimeInput ? newDateTimeInput : newStringValue;
                // if the selected operator is 'not contains', adding the whole input in (NOT input)
                String fieldNames = fieldName.split('-')[1];
                fieldNames = operator == 'k' ? ' (NOT ' + fieldNames : fieldNames;
                newStringValue = operator == 'k' ? newStringValue + ') ' : newStringValue;
                // if filter logic is not enabled, adding the string to the where condition. If the filter logic is enabled collecting the inputs in map to format string.
                finalValue = fieldNames + symbol + newStringValue;
            }
            criteriaItem.setFinalValue(finalValue);
        }
    }

    /**
     * It is used to save main template when user click on Save Template button from visualforce page
     *
     * @return
     */
    public PageReference saveMainTemplate() {
        duplicateTemplateNameChecker(template);
        // In previous line we did duplicate name check, So if the map is not null we will retun and show message.
        if (!pageMessagesMap.isEmpty()) {
            return null;
        }
        return saveTemplateAndGo(template);
    }

    /**
     * It is used to save clone template when user click on Clone Template button from visualforce page
     *
     * @return
     */
    public PageReference saveCloneTemplate() {
        Data_Template__c cloneTemplate = template.clone(false, true, false, false);
        cloneTemplate.Name = Label.Clone_of + BLANK_SPACE + cloneTemplate.Name;

        duplicateTemplateNameChecker(cloneTemplate);
        // In previous line we did duplicate name check, So if the map is not null we will retun and show message.
        if (!pageMessagesMap.isEmpty()) {
            return null;
        }

        return saveTemplateAndGo(cloneTemplate);
    }

    /**
     * It is used to remove disabled fields from selected fields for existing attachment values
     */
    private void updateSelectedFieldsByDisabledFields() {
        String invalidFieldsForTemplate = getInvalidFieldsForTemplate();
        List<String> invalidFieldsForTemplates = invalidFieldsForTemplate.split(',');
        for (String fieldApiName : selectableFieldsMap.keySet()) {
            for (String fieldName : invalidFieldsForTemplates) {
                if (fieldApiName.toLowerCase() == fieldName.toLowerCase() && fieldApiName.toLowerCase() != C_ID.toLowerCase()) {
                    selectableFieldsMap.remove(fieldApiName);
                }
            }
        }
    }

    /**
     * It is used to save template in any case
     *
     * @return
     */
    private PageReference saveTemplateAndGo(Data_Template__c referenceTemplate) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (
                referenceTemplate.Main_Object__c != null &&
                (referenceTemplate.Main_Object__c == EMPTY_STRING ||
                referenceTemplate.Main_Object__c == NONE)
            ) {
                pageMessagesMap.put(C_ERROR, new List<Object>{ Label.Select_Main_Object });
                return null;
            }

            if (referenceTemplate.Name == null && referenceTemplate.Main_Object__c != null) {
                referenceTemplate.Name = populateTemplateName(referenceTemplate.Main_Object__c);
            }

            Utilities.Secure_DML(referenceTemplate, Utilities.DML_Action.UPS, schema.SObjectType.Data_Template__c);
            if (criteriaWrapperList != null && !criteriaWrapperList.isEmpty()) {
                for (QueryEditor.CriteriaWrapper criteriaItem : criteriaWrapperList) {
                    criteriaItem.setOperatorSet(null);
                }
            }
            List<RelationTemplateDetails> parentTemplateIdList = new List<RelationTemplateDetails>();
            List<RelationTemplateDetails> childTemplateIdList = new List<RelationTemplateDetails>();
            List<CopadoChildRelationship> tempChildRelationList = new List<CopadoChildRelationship>();
            if (desResponse != null && desResponse.fields != null) {
                for (CopadoField copadoFld : desResponse.fields) {
                    if (selectableFieldsMap.containsKey(copadoFld.name)) {
                        CopadoSelectedField selectedField = selectableFieldsMap.get(copadoFld.name);
                        selectedField.replaceValueDate = copadoFld.replaceValueDate;
                        selectedField.replaceValueDatetime = copadoFld.replaceValueDatetime;
                        selectedField.replaceValueNumber = copadoFld.replaceValueNumber;
                        selectedField.fieldType = copadoFld.type;
                        Boolean isDeploymentTemplatePopulated =
                            selectedField.deploymentTemplate != null && String.isNotBlank(selectedField.deploymentTemplate);
                        if (copadoFld.referenceTo != null && selectedField.isSelected && isDeploymentTemplatePopulated) {
                            for (String tempId : selectedField.deploymentTemplateNameMap.keySet()) {
                                if (selectedField.deploymentTemplateNameMap.get(tempId) == selectedField.deploymentTemplate) {
                                    RelationTemplateDetails relationDetail = new RelationTemplateDetails();
                                    relationDetail.templateId = tempId;
                                    relationDetail.relationName = copadoFld.name;
                                    parentTemplateIdList.add(relationDetail);
                                }
                            }
                        }
                    }
                }
                if (desResponse.childRelationshipsList != null) {
                    for (Integer i = 0; i < desResponse.childRelationshipsList.size(); i++) {
                        for (CopadoChildRelationship childItem : desResponse.childRelationshipsList[i]) {
                            if (selectableChildRelationsMap.containsKey(childItem.field + '-' + childItem.relationshipName)) {
                                CopadoSelectedChildRelationship selectedChildItem = selectableChildRelationsMap.get(
                                    childItem.field +
                                    '-' +
                                    childItem.relationshipName
                                );
                                Boolean isDeploymentTemplatePopulated =
                                    selectedChildItem.deploymentTemplate != null && String.isNotBlank(selectedChildItem.deploymentTemplate);
                                if (selectedChildItem.isSelected && isDeploymentTemplatePopulated) {
                                    tempChildRelationList.add(childItem);
                                }
                            }
                        }
                    }
                    for (CopadoChildRelationship childItem : tempChildRelationList) {
                        if (selectableChildRelationsMap.containsKey(childItem.field + '-' + childItem.relationshipName)) {
                            CopadoSelectedChildRelationship selectedChildItem = selectableChildRelationsMap.get(
                                childItem.field +
                                '-' +
                                childItem.relationshipName
                            );
                            for (String tempId : selectedChildItem.deploymentTemplateNameMap.keySet()) {
                                if (selectedChildItem.deploymentTemplateNameMap.get(tempId) == selectedChildItem.deploymentTemplate) {
                                    RelationTemplateDetails relationObjectDetail = new RelationTemplateDetails();
                                    relationObjectDetail.templateId = tempId;
                                    relationObjectDetail.relationName = childItem.relationshipName;
                                    relationObjectDetail.childSObject = childItem.childSObject;
                                    childTemplateIdList.add(relationObjectDetail);
                                }
                            }
                        }
                    }
                }

                whereConditionEditor();
                DataTemplateDetails templateDetail = new DataTemplateDetails();
                templateDetail.templateId = referenceTemplate.Id;
                templateDetail.templateName = referenceTemplate.Name;
                templateDetail.templateSourceOrg = referenceTemplate.Template_Source_Org__c;
                templateDetail.templateMainObject = referenceTemplate.Main_Object__c;
                templateDetail.templateMatchOwners = referenceTemplate.Match_Owners__c;
                templateDetail.templateMatchRecordTypes = referenceTemplate.Match_Record_Type__c;
                templateDetail.templateContinueOnError = referenceTemplate.Continue_on_Error__c;
                templateDetail.templateActive = referenceTemplate.Active__c;
                templateDetail.templateDescription = referenceTemplate.Description__c;
                templateDetail.templateAttachmentOption = referenceTemplate.Attachment_Options__c;
                templateDetail.templateFilterLogic = referenceTemplate.Filter_Logic__c;
                templateDetail.templateBatchSize = referenceTemplate.Batch_Size__c;
                templateDetail.templateQueryLimit = referenceTemplate.Max_Record_Limit__c;
                templateDetail.templateSelectedAttachmentType = selectedAttachmentType;

                TemplateObjectWrapper tow = new TemplateObjectWrapper();
                tow.dataTemplate = templateDetail;
                tow.parentObjectsReferenceList = parentTemplateIdList;
                tow.childrenObjectsReferenceList = childTemplateIdList;
                tow.queryFilterList = criteriaWrapperList;
                updateSelectedFieldsByDisabledFields();
                tow.selectableFieldsMap = selectableFieldsMap;
                tow.selectableChildRelationsMap = selectableChildRelationsMap;

                List<Attachment> templateDetailAttachments = getAttachments(referenceTemplate.Id, new Set<String>{ TEMPLATE_DETAIL });
                if (!pageMessagesMap.isEmpty() && templateDetailAttachments.isEmpty()) {
                    Database.rollback(sp);
                    return null;
                }

                List<Attachment> attachmentsToBeInserted = new List<Attachment>();
                Attachment attachment = new Attachment();
                if (!templateDetailAttachments.isEmpty()) {
                    attachment = createAttachments(templateDetailAttachments[0], TEMPLATE_DETAIL, referenceTemplate.Id, JSON.serialize(tow));
                    Utilities.Secure_DML(attachment, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
                    return goToDataTemplate(referenceTemplate);
                }
                attachment = createAttachments(null, TEMPLATE_DETAIL, referenceTemplate.Id, JSON.serialize(tow));
                attachmentsToBeInserted.add(attachment);

                if (desResponse != null) {
                    Attachment describeSobjectAttachment = createAttachments(
                        null,
                        ADD_DESCRIBE_SOBJECT,
                        referenceTemplate.Id,
                        JSON.serialize(desResponse)
                    );
                    attachmentsToBeInserted.add(describeSobjectAttachment);
                }

                // Describe global will be stored at org credential
                Attachment existingDescribeGlobalAttachment = checkGlobalDescribeResult(referenceTemplate);
                if (existingDescribeGlobalAttachment == null) {
                    Attachment describeGlobalAttachment = createAttachments(
                        null,
                        ADD_DESCRIBE_GLOBAL,
                        referenceTemplate.Template_Source_Org__c,
                        JSON.serialize(describeGlobalResponse)
                    );
                    attachmentsToBeInserted.add(describeGlobalAttachment);
                }

                Utilities.Secure_DML(attachmentsToBeInserted, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
            }
            return goToDataTemplate(referenceTemplate);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage(), excp.getLineNumber() });
            Database.rollback(sp);
            return null;
        }
    }

    /**
     * It is checking if global describe already exist for org credential
     *
     * @param dataTemplate
     *
     * @return
     */
    private Attachment checkGlobalDescribeResult(Data_Template__c dataTemplate) {
        List<Attachment> describeGlobalAttachments = getAttachments(dataTemplate.Template_Source_Org__c, new Set<String>{ ADD_DESCRIBE_GLOBAL });
        return !describeGlobalAttachments.isEmpty() ? describeGlobalAttachments[0] : null;
    }

    /**
     * It is used to refresh global describe
     *
     * @return
     */
    public PageReference refreshGlobalDescribe() {
        try {
            CopadoDescribeGlobalResponse tempDescribeResult = new CopadoDescribeGlobalResponse();
            if (pageMessagesMap.isEmpty()) {
                DescribeSObjectService.DescribeGlobalResponse describerResponse = new DescribeSObjectService(template.Template_Source_Org__c)
                    .getObjects();
                // convert to existing wrapper class for compatibility reasons
                tempDescribeResult = (CopadoDescribeGlobalResponse) JSON.deserialize(
                    JSON.serialize(describerResponse),
                    CopadoDescribeGlobalResponse.class
                );
                if (!tempDescribeResult.success) {
                    pageMessagesMap.put(C_ERROR, new List<Object>{ tempDescribeResult.error });
                    return null;
                }
            }

            List<Attachment> describeGlobalAttachments = getAttachments(template.Template_Source_Org__c, new Set<String>{ ADD_DESCRIBE_GLOBAL });

            if (!describeGlobalAttachments.isEmpty()) {
                Attachment attachment = createAttachments(
                    describeGlobalAttachments[0],
                    ADD_DESCRIBE_GLOBAL,
                    template.Template_Source_Org__c,
                    JSON.serialize(tempDescribeResult)
                );
                Utilities.Secure_DML(attachment, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to retrieve any attachment under data temple either org credential
     */
    private List<Attachment> getAttachments(String parentId, Set<String> attachmentNames) {
        List<Attachment> attachments = new List<Attachment>();
        try {
            attachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :parentId AND Name IN :attachmentNames WITH SECURITY_ENFORCED];
        } catch (Exception excp) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + BLANK_SPACE + Schema.SObjectType.Attachment.getLabel() }
            );
        }
        return attachments;
    }

    /**
     * It is used to refresh global sobject
     *
     * @return
     */
    public PageReference refreshGlobalSObject() {
        try {
            if (template.Main_Object__c != null && template.Main_Object__c != EMPTY_STRING) {
                TempCopadoResult tempCopadoResult = populateSelectedObjectFields(template);
                DescribeResponse relationDesResponse = tempCopadoResult.desResponse;

                if (relationDesResponse == null && !pageMessagesMap.isEmpty()) {
                    return null;
                }

                List<Attachment> describeResultAttachments = getAttachments(template.Id, new Set<String>{ ADD_DESCRIBE_SOBJECT });

                if (!describeResultAttachments.isEmpty()) {
                    Attachment attachment = createAttachments(
                        describeResultAttachments[0],
                        ADD_DESCRIBE_SOBJECT,
                        relationTemplate.Id,
                        JSON.serialize(relationDesResponse)
                    );
                    Utilities.Secure_DML(attachment, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
                }
            }
            return pageMessagesMap.isEmpty() ? goToDataTemplate(template) : null;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to create or update the attachment for data template
     *
     * @return
     */
    private Attachment createAttachments(Attachment attachment, String attachmentName, String parentId, String bodyValue) {
        Attachment att = attachment == null ? new Attachment() : attachment;
        if (attachment == null) {
            att.ParentId = parentId;
        }
        att.Body = Blob.valueOf(bodyValue);
        att.Name = attachmentName;
        return att;
    }

    /**
     * It is used to redirect to the data template record after operations
     *
     * @return
     */
    private PageReference goToDataTemplate(Data_Template__c referenceTemplate) {
        PageReference pReference = Page.DataTemplateSetup;
        pReference.getParameters().put(C_ID.toLowerCase(), referenceTemplate.Id);
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getPageMessageSize() {
        return messagesSize(pageMessagesMap);
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getGeneralMessageSize() {
        return messagesSize(generalMessagesMap);
    }

    /**
     * It is used to return necessary severity to the visualforce page
     *
     * @return
     */
    public String getGeneralMessageSeverity() {
        String severity = (generalMessagesMap != null && generalMessagesMap.keySet().contains(C_ERROR)) ? C_ERROR : C_WARNING;
        return severity;
    }

    /**
     * It is used to count total messages size in the map
     *
     * @param messageMap
     *
     * @return
     */
    private Integer messagesSize(Map<String, List<Object>> messageMap) {
        Integer listSize = 0;
        if (messageMap != null) {
            for (String severity : messageMap.keySet()) {
                listSize += messageMap.get(severity).size();
            }
        }
        return listSize;
    }

    /**
     * It is used to redirect user to relation template in a new tab
     */
    public PageReference openRelationTemplate() {
        String relTemplateId = ApexPages.currentPage().getParameters().get('relTemplateId');
        Id relationTemplateId = null;
        PageReference pReference = null;
        if (String.isNotBlank(relTemplateId)) {
            relationTemplateId = relTemplateId;
            pReference = new ApexPages.StandardController(relationTemplateId.getSobjectType().newSObject(relationTemplateId)).view();
            pReference.setRedirect(true);
        }
        return pReference;
    }

    /**
     * It is used to disable OwnerId field on the Template creation, if there is no OwnerId field
     *
     * @return
     */
    public Boolean getOwnerIdField() {
        Boolean ownerIdFieldExist = checkIfFieldExistInDescribeResult('OwnerId');
        return ownerIdFieldExist;
    }

    /**
     * It is used to disable RecordTypeId field on the Template creation, if there is no RecordTypeId field
     *
     * @return
     */
    public Boolean getRecordTypeIdField() {
        Boolean recordTypeIdFieldExist = checkIfFieldExistInDescribeResult('RecordTypeId');
        return recordTypeIdFieldExist;
    }

    /**
     * It is used to find given field name in describe result
     *
     * @return
     */
    private Boolean checkIfFieldExistInDescribeResult(String objectName) {
        Boolean fieldExist = false;
        if (desResponse != null && desResponse.fields != null) {
            for (CopadoField copadoFld : desResponse.fields) {
                if (copadoFld.name.toLowerCase() == objectName.toLowerCase()) {
                    fieldExist = true;
                    break;
                }
            }
        }
        return fieldExist;
    }

    /**
     * It is used to populate description help text for record matching formula modal when user select the Field content update for external id fields
     */
    public String getRecordMatchingFormulaModalDescription() {
        String helpText = '';
        String objectLabel = '';
        String description = '';
        if (describeGlobalResponse != null && describeGlobalResponse.sobjects != null) {
            for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                if (template.Main_Object__c == desObj.name) {
                    objectLabel = desObj.label;
                    break;
                }
            }

            description = getRecordMatchingFormulasForTemplateObject()
                ? Label.Copado_Record_Matching_Formula_Description_With_Records
                : Label.Copado_Record_Matching_Formula_Description;

            helpText = String.format(description, new List<String>{ objectLabel });
        }

        return helpText;
    }

    /**
     * It is used to return boolean value of recordMatchings size to render buttons and modal body at record matching formula modal
     */
    public Boolean getRecordMatchingFormulasForTemplateObject() {
        List<Record_Matching_Formula__c> recordMatchings = new List<Record_Matching_Formula__c>();
        recordMatchings = getRecordMatchingFormula();
        return recordMatchings.size() > 0;
    }

    /**
     * It is used to return all record matching formula records for template object and org
     */
    public List<Record_Matching_Formula__c> getRecordMatchingFormula() {
        List<Record_Matching_Formula__c> recordMatchings = new List<Record_Matching_Formula__c>();
        try {
            recordMatchings = [
                SELECT Id, Field_1__c, Field_2__c, Field_3__c
                FROM Record_Matching_Formula__c
                WHERE Object__c = :template.Main_Object__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (Exception excp) {
            addInsufficientAccessMessage(Schema.SObjectType.Record_Matching_Formula__c.getLabel());
        }
        return recordMatchings;
    }

    /**
     * It is used to create Record Matching Formula and redirect to record
     */
    public PageReference createRecordMatchingFormulaAndRedirect() {
        if (!Schema.SObjectType.Record_Matching_Formula__c.isCreateable()) {
            addInsufficientAccessMessage(Schema.SObjectType.Record_Matching_Formula__c.getLabel());
            return null;
        }

        Record_Matching_Formula__c recordMatchingFormula = new Record_Matching_Formula__c();
        try {
            recordMatchingFormula.Name = returnSelectedObjectLabel(template.Main_Object__c) + BLANK_SPACE + Label.Formula;
            recordMatchingFormula.Configuration_Source_Org__c = template.Template_Source_Org__c;
            recordMatchingFormula.Object__c = template.Main_Object__c;
            Utilities.Secure_DML(recordMatchingFormula, Utilities.DML_Action.INS, schema.SObjectType.Record_Matching_Formula__c);
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }

        return goToRecordMatchingRecord(recordMatchingFormula);
    }

    /**
     * It is used to redirect user to the record matching formula record page. It is standard record page replaced with LWC, lightning app
     */
    public PageReference goToRecordMatchingRecord(Record_Matching_Formula__c recordMatchingFormula) {
        PageReference pReference = new ApexPages.StandardController(recordMatchingFormula).view();
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It works when user click on edit formula button at record matching formula modal
     */
    public PageReference editCurrentRecordMatchingFormula() {
        Record_Matching_Formula__c recordMatchingFormula = getRecordMatchingFormula()[0];
        return goToRecordMatchingRecord(recordMatchingFormula);
    }

    /**
     * It is used to populate pageMessagesMap to show a warning to user for object access issues
     */
    private void addInsufficientAccessMessage(String objectLabel) {
        pageMessagesMap.put(C_WARNING, new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + BLANK_SPACE + objectLabel });
    }

    /**
     * It is used to store all information related to template
     */
    public class TemplateObjectWrapper {
        public DataTemplateDetails dataTemplate { get; set; }
        public List<RelationTemplateDetails> parentObjectsReferenceList { get; set; }
        public List<RelationTemplateDetails> childrenObjectsReferenceList { get; set; }
        public Map<String, CopadoSelectedField> selectableFieldsMap { get; set; }
        public Map<String, CopadoSelectedChildRelationship> selectableChildRelationsMap { get; set; }
        public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }

        public TemplateObjectWrapper() {
            this.dataTemplate = new DataTemplateDetails();
            this.parentObjectsReferenceList = new List<RelationTemplateDetails>();
            this.childrenObjectsReferenceList = new List<RelationTemplateDetails>();
            this.selectableFieldsMap = new Map<String, CopadoSelectedField>();
            this.selectableChildRelationsMap = new Map<String, CopadoSelectedChildRelationship>();
            this.queryFilterList = new List<QueryEditor.CriteriaWrapper>();
        }
    }

    /**
     * If we create a new field on Data Template object, we need to create a parameter to store that value for export and reload
     */
    public class DataTemplateDetails {
        public String templateId { get; set; }
        public String templateName { get; set; }
        public String templateSourceOrg { get; set; }
        public String templateMainObject { get; set; }
        public Boolean templateMatchOwners { get; set; }
        public Boolean templateMatchRecordTypes { get; set; }
        public String templateContinueOnError { get; set; }
        public Boolean templateActive { get; set; }
        public String templateDescription { get; set; }
        public String templateAttachmentOption { get; set; }
        public String templateFilterLogic { get; set; }
        public Decimal templateBatchSize { get; set; }
        public Decimal templateQueryLimit { get; set; }
        public String templateSelectedAttachmentType { get; set; }
    }

    public class RelationTemplateDetails {
        public String templateId { get; set; }
        public String relationName { get; set; }
        public String childSObject { get; set; }

        public RelationTemplateDetails() {
            this.templateId = '';
            this.relationName = '';
            this.childSObject = '';
        }
    }

    public class CopadoDescribeGlobalResponse {
        public Boolean success { get; set; }
        public Boolean retryOnError { get; set; }
        public String error { get; set; }
        public String encoding { get; set; }
        public Integer maxBatchSize { get; set; }
        public List<CopadoDescribeGlobalSObjectResult> sobjects { get; set; }
    }

    public class CopadoDescribeGlobalSObjectResult {
        public Boolean custom { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public Boolean triggerable { get; set; }
        public Boolean updateable { get; set; }
    }

    /**
     * childRelationships is mandatory parameter because backend is sending response with this parameter.
     * in the controller we are looping values and populating childRelationshipsList parameter.
     * after everything we will empty the childRelationships parameter to decrease attachment size
     */
    public class DescribeResponse {
        public Boolean success { get; set; }
        public String error { get; set; }
        public List<CopadoChildRelationship> childRelationships { get; set; }
        public List<List<CopadoChildRelationship>> childRelationshipsList { get; set; }
        public List<CopadoField> fields { get; set; }
        public Boolean custom { get; set; }
        public String label { get; set; }
    }

    public class CopadoChildRelationship {
        public String childSObject { get; set; }
        public String field { get; set; }
        public String relationshipName { get; set; }
    }

    public class CopadoSelectedChildRelationship {
        public Boolean isSelected { get; set; }
        public String childSObject { get; set; }
        public String field { get; set; }
        public String relationshipName { get; set; }
        public Map<String, String> objectApiNameMap { get; set; }
        public Map<String, String> deploymentTemplateNameMap { get; set; }
        public String deploymentTemplate { get; set; }

        public CopadoSelectedChildRelationship() {
            this.isSelected = false;
            this.childSObject = '';
            this.field = '';
            this.relationshipName = '';
            this.objectApiNameMap = new Map<String, String>();
            this.deploymentTemplateNameMap = null;
            this.deploymentTemplate = System.Label.Select_Template;
        }
    }

    /**
     * replaceValueNumber, replaceValueDate and replaceValueDatetime are duplicated in CopadoSelectedField class, because we can not use map values in apex:input numeric type
     *
     * @see CopadoSelectedField
     */
    public class CopadoField {
        public Boolean autonumber { get; set; }
        public Boolean calculated { get; set; }
        public Boolean externalId { get; set; }
        public Boolean filterable { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public Boolean nillable { get; set; }
        public String relationshipName { get; set; }
        public List<String> referenceTo { get; set; }
        public String type { get; set; }
        public Boolean unique { get; set; }
        public Double replaceValueNumber { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
        public Date replaceValueDate { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
        public Datetime replaceValueDatetime { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
    }

    public class CopadoSelectedField {
        public Boolean isSelected { get; set; }
        public Boolean useAsExternalId { get; set; }
        public Boolean externalId { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public String fieldType { get; set; }
        public Map<String, String> parentObjectApiNameMap { get; set; }
        public Map<String, String> contentValueUpdateValues { get; set; }
        public String fieldContentUpdate { get; set; }
        public String replaceValue { get; set; }
        public Double replaceValueNumber { get; set; }
        public Date replaceValueDate { get; set; }
        public Datetime replaceValueDatetime { get; set; }
        public Map<String, String> deploymentTemplateNameMap { get; set; }
        public String deploymentTemplate { get; set; }

        public CopadoSelectedField() {
            this.isSelected = true;
            this.useAsExternalId = false;
            this.externalId = false;
            this.label = '';
            this.name = '';
            this.fieldType = '';
            this.parentObjectApiNameMap = new Map<String, String>();
            this.contentValueUpdateValues = new Map<String, String>();
            this.fieldContentUpdate = '';
            this.replaceValue = '';
            this.replaceValueNumber = 0;
            this.replaceValueDate = System.today();
            this.replaceValueDatetime = null;
            this.deploymentTemplateNameMap = null;
            this.deploymentTemplate = System.Label.Select_Template;
        }
    }

    public class TempCopadoResult {
        public DescribeResponse desResponse { get; set; }
        public Map<String, CopadoSelectedField> selectableFieldsMap { get; set; }
        public Map<String, CopadoSelectedChildRelationship> selectableChildRelationsMap { get; set; }
    }
}