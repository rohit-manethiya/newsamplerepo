public with sharing class ADD_RecordMatchingFormulaOperations {
    private static final String OPTION_LABEL = 'label';
    private static final String OPTION_VALUE = 'value';
    private static final String OPTION_NONE = '--None--';

    /**
     * It is doing callout to get field details of given org and object
     * @param orgId organization id to get field details from
     * @param mainObject object name to get field details from
     * @return JSON value of populated FilterableFields
     * @see FilterableFields
     */
    @AuraEnabled
    public static String getPickListValues(String orgId, String mainObject) {
        FilterableFields result = new FilterableFields();

        try {
            DescribeSObjectService.DescribeResponse describeResponse = new DescribeSObjectService(orgId).getFields(mainObject);

            if (!describeResponse.fields.isEmpty()) {
                // sort fields by field label
                describeResponse.fields.sort();
                // add none option
                result.options.add(createOption(OPTION_NONE, OPTION_NONE));
                // filter valid fields
                for (DescribeSObjectService.CopadoField field : describeResponse.fields) {
                    if (isValidField(field)) {
                        result.options.add(createOption(field.label + ' (' + field.name + ')', field.name));
                        result.fieldTypesByNames.put(field.name, field.type);
                        if (field.isReference()) {
                            result.referenceObjectsByReferenceFields.put(field.name, field.referenceTo);
                        }
                    }
                }
            }
        } catch (Exception e) {
            result.errors.add(e.getMessage());
        }

        return JSON.serialize(result);
    }

    /**
     * It is used to populate options by given values
     */
    private static Map<String, String> createOption(String optionLabel, String optionValue) {
        return new Map<String, String>{ OPTION_LABEL => optionLabel, OPTION_VALUE => optionValue };
    }

    private static Boolean isValidField(DescribeSObjectService.CopadoField field) {
        return field.filterable != null && field.filterable && !field.isCompound();
    }

    @AuraEnabled
    public static List<Record_Matching_Formula__c> getRecordMatchingFormulas(String recordId) {
        return [
            SELECT Id, Name, Configuration_Source_Org__c, Object__c, Hash_Formula__c, Field_1__c, Field_2__c, Field_3__c
            FROM Record_Matching_Formula__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    /**
     * It is doing callout to get all objects of given org
     * @param orgId organization id to get objects from
     * @return JSON value of populated GlobalDescribe
     * @see GlobalDescribe
     */
    @AuraEnabled
    public static String getOrgObjects(String orgId) {
        GlobalDescribe result = new GlobalDescribe();

        try {
            DescribeSObjectService.DescribeGlobalResponse describeGlobalResponse = new DescribeSObjectService(orgId).getObjects();

            if (!describeGlobalResponse.sobjects.isEmpty()) {
                // sort objects by field label
                describeGlobalResponse.sobjects.sort();

                // filter invalid objects
                for (DescribeSObjectService.CopadoObject globalSObject : describeGlobalResponse.sobjects) {
                    if (isValidObject(globalSObject)) {
                        result.options.add(createOption(globalSObject.label + ' (' + globalSObject.name + ')', globalSObject.name));
                    }
                }
            }
        } catch (Exception e) {
            result.errors.add(e.getMessage());
        }

        return JSON.serialize(result);
    }

    private static Boolean isValidObject(DescribeSObjectService.CopadoObject globalSObject) {
        return globalSObject.triggerable && !globalSObject.isDisabled() && !globalSObject.isCustomMetadataType() && !objectIsUnwanted(globalSObject);
    }

    private static Boolean objectIsUnwanted(DescribeSObjectService.CopadoObject globalSObject) {
        return globalSObject.name.endsWith('History') ||
            globalSObject.name.endsWith('Tag') ||
            globalSObject.name.endsWith('Share') ||
            globalSObject.name.endsWith('Feed') ||
            globalSObject.name.endsWith('ChangeEvent');
    }

    /**
     * The reason that we are returning List<Map<String, String>>, SelectOptions are not serializable
     */
    public with sharing class FilterableFields {
        @AuraEnabled
        public List<String> errors;
        @AuraEnabled
        public Map<String, String> fieldTypesByNames;
        @AuraEnabled
        public List<Map<String, String>> options;
        @AuraEnabled
        public Map<String, List<String>> referenceObjectsByReferenceFields;

        public FilterableFields() {
            this.errors = new List<String>();
            this.options = new List<Map<String, String>>();
            this.fieldTypesByNames = new Map<String, String>();
            this.referenceObjectsByReferenceFields = new Map<String, List<String>>();
        }
    }

    /**
     * The reason that we are returning List<Map<String, String>>, SelectOptions are not serializable
     */
    public with sharing class GlobalDescribe {
        @AuraEnabled
        public List<String> errors;
        @AuraEnabled
        public List<Map<String, String>> options;

        public GlobalDescribe() {
            this.errors = new List<String>();
            this.options = new List<Map<String, String>>();
        }
    }

}