public with sharing class PromotionEditExtension {
    
    public boolean showOtherInformation{get;set;}
    
    public PromotionEditExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(Utilities.getAllFields('Promotion__c').get(Label.FIELDS).split(','));
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Release__r.Name'});
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Source_Environment__r.Name'});
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Destination_Environment__r.Name'});
        
        showOtherInformation = SObjectType.Promotion__c.FieldSets.CustomFields.getFields().size()>0;
    }
}