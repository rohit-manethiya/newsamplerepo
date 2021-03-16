/**
 * Custom component controller class. This class generates lightning like related lists by using given attributes.
 * @author Mert YALTI
 * @date 26.06.2017
 */
public with sharing class LightningReadyRelatedListController {
    public sObject[] objectList {get; set;}
    public Integer initialSize {get; set;}
    public String fSetName {get; set;}
    public String objectAPI {get; set;}
    public String parentAPI {get; set;}
    public String relName {get; set;}
    public String pId {get; set;}
    Map<String, Schema.SObjectType> globalDescribeMap {get; set;}
    private String SOQL_STRING = 'SELECT Id, (SELECT {0} FROM {1}) FROM {2} WHERE Id =: pId';
    private String namespace = Settings.ns;
    
    public LightningReadyRelatedListController() {
        objectList = new List<sObject>();
        globalDescribeMap = Schema.getGlobalDescribe();
    }

    /**
     * Finds and returns the field set by using field set name attribute
     * @return List<Schema.FieldSetMember>
     */
    public List<Schema.FieldSetMember> fieldSet {
        get {
            if(!String.isBlank(objectName) && !String.isBlank(fSetName)) {
                fSetName = !fSetName.startsWith(namespace) ?  namespace + fSetName : fSetName;
                Schema.SObjectType SObjectTypeObj = globalDescribeMap.get(objectName);
                Schema.DescribeSObjectResult describeSObjectResultObj = SObjectTypeObj.getDescribe();
                Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fSetName);
                return fieldSetObj != null ? fieldSetObj.getFields() : null;
            }
            return null;
        }
    }

    public String getNameSpace(){
        return namespace;
    }

    
    public List<sObject> getdataset() {
        if(dataList == null) {
            populateNecessaryVariables();
        }
        return dataList;
    }

    public List<sObject> dataList {
        get {
            if(objectList != null && !objectList.isEmpty()) {
                dataList = objectList;
            } else {
                if(dataList == null) {
                    populateNecessaryVariables();
                }
            }
            return dataList;
        }
        set;
    }

    private void populateNecessaryVariables() {
        relName = !relName.startsWith(namespace) && relName.endsWith('__r') ? namespace + relName : relName;
        parentAPI = !parentAPI.startsWith(namespace) && parentAPI.endsWith('__c') ?  namespace + parentAPI : parentAPI;
        dataList = new List<sObject>();
        Map<String, String> fields = Utilities.getAllFields(objectAPI);
        if(fields != null && fields.containsKey(Label.FIELDS)) {
            String soql = String.format(SOQL_STRING, new String[] {fields.get(Label.FIELDS), relName, parentAPI});

            for(sObject ps : database.query(soql)) {
                List<sObject> relatedSobjects = (List<sObject>)ps.getSObjects(relName);
                if(relatedSobjects != null)
                    dataList.addAll(relatedSObjects);
            }
            if(!dataList.isEmpty()) {
                objectPrefix = dataList[0].getSObjectType().getDescribe().getKeyPrefix();
                objectName = dataList[0].getSObjectType().getDescribe().getName();
                objectLabel = dataList[0].getSObjectType().getDescribe().getLabel();
            }
        }
    }

    public String getViewAllURL() {
        relName = !relName.startsWith(namespace) && relName.endsWith('__r') ? namespace + relName : relName;
        return '/' + objectPrefix + '?rlapiid=' + relName + '&Id=' + pId;
    }

    /**
     * Finds and returns sObject's API NAME.
     * In the component this is being passed as a attribute
     * @return String sObject api name
     */
    public String objectName {
        get {
            Boolean objectListIsNotEmpty = objectList != null && !objectList.isEmpty();
            Boolean objectNameEmpty = String.isBlank(objectName);
            return objectListIsNotEmpty ? objectList[0].getSObjectType().getDescribe().getName() : objectNameEmpty ? '' : objectName;
        }
        set;
    }

    /**
     * Finds and returns sObject's prefix.
     * In the component this is being passed as a attribute
     * @return String sObject prefix
     */
    public String objectPrefix {
        get {
            Boolean objectListIsNotEmpty = objectList != null && !objectList.isEmpty();
            Boolean objectPrefixEmpty = String.isBlank(objectPrefix);
            return objectListIsNotEmpty ? objectList[0].getSObjectType().getDescribe().getKeyPrefix() : objectPrefixEmpty ? '' : objectPrefix;
        }
        set;
    }

    /**
     * Finds and returns sObject's Label.
     * In the component sObject is being passed as a attribute
     * @return String sObject label
     */
    public String objectLabel {
        get {
            Boolean objectListIsNotEmpty = objectList != null && !objectList.isEmpty();
            Boolean objectLabelEmpty = String.isBlank(objectLabel);
            return objectListIsNotEmpty ? objectList[0].getSObjectType().getDescribe().getLabel() : objectLabelEmpty ? '' : objectLabel;
        }
        set;
    }
}