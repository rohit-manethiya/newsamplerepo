/**
 * Custom component controller class. This class find display type of the field which passed as an attribute to the component and renders proper lightning design system ready panel for the field.
 * @author Mert YALTI
 * @date 18.06.2017
 * @see LightningReadyInputFields.component
 * @see LightningReadyOutputFields.component
 */
public with sharing class LightningReadyFieldsController {
    public SObject subjectedObject { get; set; }
    public String fName { get; set; }

    /**
     * returns the static namespacevi
     * @return [description]
     */
    public String getNamespace(){
        return Settings.ns; 
    }

    public LightningReadyFieldsController() {
    }
    /**
     * Finds sObjectField from the component attribute field
     * In the component field is a string value so by using that string below code block can call [sobject].getSObjectType().getDescribe().fields.getMap().get(fName)
     * @return SObjectField
     */
    public SObjectField getSobjectField() {
        fName = fName != null && !fName.startsWith(Settings.ns) && fName.endsWith('__c') ? Settings.ns + fName : fName;
        if (subjectedObject != null){
            return subjectedObject.getSObjectType().getDescribe().fields.getMap().get(fName);
        } else {
            return null;
        }
    }
    /**
     * By using getSObjectField method below method returns Field Description for the requested field
     * @return DescribeFieldResult
     */
    public DescribeFieldResult getFieldDescribe() { 
        SObjectField sf = getSobjectField();
        if (sf != null){
            return sf.getDescribe();
        } else {
            return null;
        }
    }
    /**
     * Finds and returns sObject's Label.
     * In the component sObject is being passed as a attribute
     * @return String sObject label
     */
    public String objectName { 
        get {
            if (subjectedObject != null){
                return subjectedObject.getSObjectType().getDescribe().getName();
            } else {
                return '';
            }
        }
    }
    /**
     * If the field is Nillable this method returns false since the field is not required.
     */
    public Boolean isRequiredField { 
        get {
            DescribeFieldResult thisDescribe = getFieldDescribe();
            if(thisDescribe != null) {
                return !thisDescribe.isNillable();
            } else {
                return false;
            }
        }
    }
    /**
     * If the record has already been created this method checks if the subjected field is updatable or not otherwise it checks if the field is createablility.
     * so if the field either not updatable or not createable it means the field is read only.
     */
    public Boolean isReadOnlyField {
        get {
            DescribeFieldResult thisDescribe = getFieldDescribe();
            if(subjectedObject != null && thisDescribe != null) {
                if(subjectedObject.Id != null) {
                    return !thisDescribe.isUpdateable();
                } else {
                    return !thisDescribe.isCreateable();
                }
            } else {
                return true;
            }
        }
    }
    
    /**
     * If subjected fields display type is String,Currency,Email,Double,Integer,Percent,URL or Phone, this means the field is an standard input field according to HTML structure.
     */
    public Boolean isInputField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.String ||
                dispType == Schema.DisplayType.Currency ||
                dispType == Schema.DisplayType.Email ||
                dispType == Schema.DisplayType.Double ||
                dispType == Schema.DisplayType.Integer ||
                dispType == Schema.DisplayType.Percent ||
                dispType == Schema.DisplayType.URL ||
                dispType == Schema.DisplayType.Phone){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is TextArea returns true
     */
    public Boolean isTextareaField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.TextArea){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is picklist returns true
     */
    public Boolean isPicklistField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.Picklist){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is dependent picklist returns true
     */
    public Boolean isDependentPicklistField {
        get {
            return getFieldDescribe().isDependentPicklist();
        }
    }

    /**
     * If the field's display type is multi picklist returns true
     */
    public Boolean isMultiPicklistField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.MultiPicklist){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is checkbox returns true
     */
    public Boolean isCheckboxField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.Boolean){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is date or datetime returns true
     */
    public Boolean isDatetimeField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.Date ||
                dispType == Schema.DisplayType.Datetime){
                return true;
            } else{
                return false;
            }
        }
    }
    /**
     * If the field's display type is lookup returns true
     */
    public Boolean isLookupField {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.reference){
                return true;
            } else{
                return false;
            }
        }
    }
        
}