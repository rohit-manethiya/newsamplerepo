public with sharing class CCD_CreateMetadataGroupItemExtension {
    public Metadata_Group_Item__c thisItem { get; set; }
    public String selectedMetadataItemName { get; set; }
    public List<SelectOption> itemTypeOptions {
        get {
            if(itemTypeOptions == null) {
                itemTypeOptions = new List<SelectOption>();
                List<Schema.PicklistEntry> picklistValues = Metadata_Group_Item__c.Type__c.getDescribe().getPicklistValues();
                for(PicklistEntry thisValue : picklistValues) {
                    SelectOption thisOption = new SelectOption(thisValue.getValue(), thisValue.getLabel());
                    itemTypeOptions.add(thisOption);
                }
            }
            return itemTypeOptions;
        }
        private set;
    }
    public List<SelectOption> itemOperatorOptions {
        get {
            if(itemOperatorOptions == null) {
                itemOperatorOptions = new List<SelectOption>();
                List<Schema.PicklistEntry> picklistValues = Metadata_Group_Item__c.Operator__c.getDescribe().getPicklistValues();
                for(PicklistEntry thisValue : picklistValues) {
                    if(thisValue.getValue() == Label.ALL) {
                        continue;
                    }
                    SelectOption thisOption = new SelectOption(thisValue.getValue(), thisValue.getLabel());
                    itemOperatorOptions.add(thisOption);
                }
            }
            return itemOperatorOptions;
        }
        private set;
    }

    public CCD_CreateMetadataGroupItemExtension(ApexPages.StandardController thisStdController) {
        if(!Test.isRunningTest()) {
            thisStdController.addFields(new List<String>(Schema.SObjectType.Metadata_Group_Item__c.fields.getMap().keySet()));
        }
        thisItem = (Metadata_Group_Item__c) thisStdController.getRecord();
        selectedMetadataItemName = Label.ALL;
        if(String.isNotBlank(thisItem.Operator__c)) {
            selectedMetadataItemName = thisItem.Operator__c == Label.ALL ? Label.ALL : Label.Advanced_Metadata_Name;
        }
    }

    public List<SelectOption> getMetadataNames() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(Label.ALL, Label.ALL));
        options.add(new SelectOption(Label.Advanced_Metadata_Name, Label.Advanced_Metadata_Name));
        return options;
    }

    /**
     * @description saves the new Metadata Group Item record to the database. Validates the fields and displays an error
     * if the validatio fails.
     * 
     * @return a new page reference redirection to the record detail page.
     */
    public PageReference save() {
        ApexPages.getMessages().clear();

        if(selectedMetadataItemName == Label.ALL) {
            thisItem.Operator__c = Label.ALL;
            thisItem.Value__c = null;
        } else {
            if(String.isBlank(thisItem.Value__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Missing_Metadata_Item_Value));
                return null;
            }
        }

        try {
            Utilities.Secure_DML(thisItem, Utilities.DML_Action.UPS, SObjectType.Metadata_Group_Item__c);
        } catch(Exception ex) {
            return null;
        }

        PageReference detailPage = new ApexPages.StandardController(thisItem).view();
        return detailPage;
    }
}