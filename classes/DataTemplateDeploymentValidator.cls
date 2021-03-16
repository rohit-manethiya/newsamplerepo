public with sharing class DataTemplateDeploymentValidator {
    private List<Id> dataTemplateIds;
    private Id sourceOrg;
    private List<Id> destinationOrgs;

    private Map<Id, String> objectNameByDataTemplateId {
        get {
            if (objectNameByDataTemplateId == null) {
                objectNameByDataTemplateId = getObjectNames(this.dataTemplateIds);
            }
            return objectNameByDataTemplateId;
        }
        set;
    }
    private Map<Id, String> orgNameByOrgId {
        get {
            if (orgNameByOrgId == null) {
                List<Id> orgIds = new List<Id>();
                orgIds.add(this.sourceOrg);
                orgIds.addAll(this.destinationOrgs);
                orgNameByOrgId = getOrgNames(orgIds);
            }
            return orgNameByOrgId;
        }
        set;
    }
    private Map<Id, List<String>> selectedFieldsByDataTemplateId {
        get {
            if (selectedFieldsByDataTemplateId == null) {
                selectedFieldsByDataTemplateId = getSelectedFields(this.dataTemplateIds);
            }
            return selectedFieldsByDataTemplateId;
        }
        set;
    }

    public DataTemplateDeploymentValidator(Id dataTemplateId, Id sourceOrg, Id destinationOrg) {
        this(new List<Id>{ dataTemplateId }, sourceOrg, new List<Id>{ destinationOrg });
    }

    public DataTemplateDeploymentValidator(List<Id> dataTemplateIds, Id sourceOrg, List<Id> destinationOrgs) {
        this.dataTemplateIds = dataTemplateIds;
        this.sourceOrg = sourceOrg;
        this.destinationOrgs = destinationOrgs;
    }

    public DataTemplateDeploymentValidationResult validate() {
        DataTemplateDeploymentValidationResult result = new DataTemplateDeploymentValidationResult();

        // total callouts = (1 + destinations)
        Map<Id, DescribeSObjectService.DescribeGlobalResponse> globalDescribeByOrgId = getGlobalDescribes();
        // total callouts = (1 + destinations)*data templates
        Map<Id, Map<String, DescribeSObjectService.DescribeResponse>> objectsDescribeByOrgIdAndObjectName = getObjectDescribes();

        DescribeSObjectService.DescribeGlobalResponse sourceOrgGlobalDescribe = globalDescribeByOrgId.get(this.sourceOrg);
        Map<String, DescribeSObjectService.CopadoObject> sourceObjectsByName = getObjectsMap(sourceOrgGlobalDescribe);
        Map<String, DescribeSObjectService.DescribeResponse> sourceOrgObjectsDescribeByObjectName = objectsDescribeByOrgIdAndObjectName.get(
            this.sourceOrg
        );

        for (Id dataTemplateId : this.objectNameByDataTemplateId.keySet()) {
            String objectName = this.objectNameByDataTemplateId.get(dataTemplateId);

            if (!sourceObjectsByName.containsKey(objectName)) {
                result.addError(getOrgName(this.sourceOrg), objectName, 'Object not found');
                continue;
            }

            DescribeSObjectService.CopadoObject sourceObject = sourceObjectsByName.get(objectName);

            DescribeSObjectService.DescribeResponse sourceObjectDescribe = sourceOrgObjectsDescribeByObjectName.get(objectName);
            Map<String, DescribeSObjectService.CopadoField> sourceObjectFieldsByName = getFieldsMap(sourceObjectDescribe);

            for (Id destinationOrg : this.destinationOrgs) {
                DescribeSObjectService.DescribeGlobalResponse destinationOrgGlobalDescribe = globalDescribeByOrgId.get(destinationOrg);
                Map<String, DescribeSObjectService.CopadoObject> destinationObjectsByName = getObjectsMap(destinationOrgGlobalDescribe);
                Map<String, DescribeSObjectService.DescribeResponse> destinationOrgObjectsDescribeByObjectName = objectsDescribeByOrgIdAndObjectName.get(
                    destinationOrg
                );

                if (!destinationObjectsByName.containsKey(objectName)) {
                    result.addError(getOrgName(destinationOrg), objectName, 'Object not found');
                    continue;
                }

                DescribeSObjectService.CopadoObject destinationObject = destinationObjectsByName.get(objectName);

                if (sourceObject.updateable == true && destinationObject.updateable == false) {
                    result.addError(getOrgName(destinationOrg), objectName, 'Object is not updateable');
                }

                DescribeSObjectService.DescribeResponse destinationObjectDescribe = destinationOrgObjectsDescribeByObjectName.get(objectName);
                Map<String, DescribeSObjectService.CopadoField> destinationObjectFieldsByName = getFieldsMap(destinationObjectDescribe);

                List<String> selectedFields = this.selectedFieldsByDataTemplateId.get(dataTemplateId);
                for (String fieldName : selectedFields) {
                    if (!sourceObjectFieldsByName.containsKey(fieldName)) {
                        result.addError(getOrgName(this.sourceOrg), objectName, fieldName + ' field not found');
                        continue;
                    }
                    DescribeSObjectService.CopadoField sourceField = sourceObjectFieldsByName.get(fieldName);

                    if (!destinationObjectFieldsByName.containsKey(fieldName)) {
                        result.addError(getOrgName(destinationOrg), objectName, fieldName + ' field not found');
                        continue;
                    }
                    DescribeSObjectService.CopadoField destinationField = destinationObjectFieldsByName.get(fieldName);

                    if (sourceField.updateable == true && destinationField.updateable == false) {
                        result.addError(getOrgName(destinationOrg), objectName, sourceField.label + ' field is not updateable');
                    }
                }
            }
        }

        return result;
    }

    private Map<Id, DescribeSObjectService.DescribeGlobalResponse> getGlobalDescribes() {
        Map<Id, DescribeSObjectService.DescribeGlobalResponse> globalDescribeByOrgId = new Map<Id, DescribeSObjectService.DescribeGlobalResponse>();

        for (Id orgId : this.orgNameByOrgId.keySet()) {
            DescribeSObjectService.DescribeGlobalResponse globalResponse = new DescribeSObjectService(orgId).getObjects();
            globalDescribeByOrgId.put(orgId, globalResponse);
        }

        return globalDescribeByOrgId;
    }

    private Map<Id, Map<String, DescribeSObjectService.DescribeResponse>> getObjectDescribes() {
        Map<Id, Map<String, DescribeSObjectService.DescribeResponse>> objectsDescribeByOrgIdAndObjectName = new Map<Id, Map<String, DescribeSObjectService.DescribeResponse>>();

        for (Id orgId : this.orgNameByOrgId.keySet()) {
            Map<String, DescribeSObjectService.DescribeResponse> describeByObjectname = new Map<String, DescribeSObjectService.DescribeResponse>();
            for (String objectName : this.objectNameByDataTemplateId.values()) {
                DescribeSObjectService.DescribeResponse response = new DescribeSObjectService(orgId).getFields(objectName);
                describeByObjectname.put(objectName, response);
            }
            objectsDescribeByOrgIdAndObjectName.put(orgId, describeByObjectname);
        }

        return objectsDescribeByOrgIdAndObjectName;
    }

    private String getOrgName(Id orgId) {
        return this.orgNameByOrgId.get(orgId);
    }

    private static Map<Id, String> getObjectNames(List<Id> dataTemplateIds) {
        Map<Id, String> objectNameByDataTemplateId = new Map<Id, String>();

        for (Data_Template__c dataTemplate : new DataTemplatesSelector().byId(dataTemplateIds)) {
            objectNameByDataTemplateId.put(dataTemplate.Id, dataTemplate.Main_Object__c);
        }

        return objectNameByDataTemplateId;
    }

    private static Map<Id, String> getOrgNames(List<Id> orgIds) {
        Map<Id, String> orgNameByOrgId = new Map<Id, String>();

        for (Org__c org : new OrgsSelector().byId(orgIds)) {
            orgNameByOrgId.put(org.Id, org.Name);
        }

        return orgNameByOrgId;
    }

    private static Map<Id, List<String>> getSelectedFields(List<Id> dataTemplateIds) {
        Map<Id, List<String>> selectedFieldsByDataTemplateId = new Map<Id, List<String>>();

        List<Attachment> attachments = new AttachmentsSelector().byParentIdAndName(dataTemplateIds, new List<String>{ DataTemplateDetail.ATTACHMENT_NAME });

        for (Attachment attachment : attachments) {
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
            List<String> fields = new List<String>();
            for (String fieldName : templateDetail.selectableFieldsMap.keySet()) {
                DataTemplateDetail.CopadoSelectedField selectedField = templateDetail.selectableFieldsMap.get(fieldname);
                if (selectedField.isSelected != null && selectedField.isSelected) {
                    fields.add(selectedField.name);
                }
            }
            selectedFieldsByDataTemplateId.put(attachment.ParentId, fields);
        }

        return selectedFieldsByDataTemplateId;
    }

    private static Map<String, DescribeSObjectService.CopadoObject> getObjectsMap(DescribeSObjectService.DescribeGlobalResponse globalDescribe) {
        Map<String, DescribeSObjectService.CopadoObject> objectByObjectName = new Map<String, DescribeSObjectService.CopadoObject>();

        for (DescribeSObjectService.CopadoObject copadoObject : globalDescribe.sobjects) {
            objectByObjectName.put(copadoObject.name, copadoObject);
        }

        return objectByObjectName;
    }

    private static Map<String, DescribeSObjectService.CopadoField> getFieldsMap(DescribeSObjectService.DescribeResponse objectDescribe) {
        Map<String, DescribeSObjectService.CopadoField> fieldsByName = new Map<String, DescribeSObjectService.CopadoField>();

        for (DescribeSObjectService.CopadoField copadoField : objectDescribe.fields) {
            fieldsByName.put(copadoField.name, copadoField);
        }

        return fieldsByName;
    }
}