public with sharing class DW_OverrideFiltersExtension extends DeploymentHelper {
    
    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_OverrideFiltersExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
    }
}