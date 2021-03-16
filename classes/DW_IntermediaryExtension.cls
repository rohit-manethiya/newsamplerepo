/**
 * It is main controller for DW_Intermediary page
 */
public with sharing class DW_IntermediaryExtension extends DeploymentHelper {
    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_IntermediaryExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        initializeServiceClasses();
    }

    /**
     * It is used to redirect to last step of deployment
     *
     * @return
     */
    public PageReference goToCorrespondingDeploymentPage() {
        if (
            String.isBlank(deployment.RecordTypeId) ||
            (String.isNotBlank(deployment.RecordTypeId) && deployment.RecordTypeId == advancedDeploymentRecordTypeId)
        ) {
            return goToDeployment();
        }

        deploymentWillBeRedirected = deployment;
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }
}