/**
 * It is main controller for DW_Target page
 */
public with sharing class DW_TargetExtension extends DeploymentHelper {
    // Non Constants
    @TestVisible
    private Destination_Org__c destinationOrg;

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_TargetExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        destinationOrg = new Destination_Org__c();
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
        checkExistingDestinationOrg();
        populateTargetOrgRecords();
    }

    /**
     * It is used to auto populate destination org if it saved before
     */
    private void checkExistingDestinationOrg() {
        List<Destination_Org__c> destinationOrgList = new List<Destination_Org__c>();
        if (Schema.SObjectType.Destination_Org__c.isAccessible() && Schema.SObjectType.Destination_Org__c.isQueryable()) {
            destinationOrgList = [SELECT Id, Name, Deployment__c, To_Org__c FROM Destination_Org__c WHERE Deployment__c = :deployment.Id LIMIT 1];
        } else {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Destination_Org__c.getLabel() }
            );
            return;
        }

        if (!destinationOrgList.isEmpty()) {
            destinationOrg = destinationOrgList[0];
        }
    }

    /**
     * It is used to populate org credential for target org
     */
    private void populateTargetOrgRecords() {
        sourceList = new List<SourceWrapper>();
        for (Org__c org : getLastViewedOrgs()) {
            Boolean alreadyExist = destinationOrg != null && destinationOrg.To_Org__c != null && destinationOrg.To_Org__c == org.Id;
            sourceList.add(new SourceWrapper(alreadyExist, org, '', '', '', '', '', '', null, null));
        }
        sourceList.sort();
    }

    /**
     * It is used to check if selected org is valid
     * If any org is not selected no need to check for validate org method
     * !Test.isRunningTest() is to prevent async callout issue which can not be caught on try catch
     */
    public PageReference checkIfSelectedOrgIsValid() {
        pageMessagesMap.clear();
        try {
            if (destinationOrg.Deployment__c == null) {
                destinationOrg.Deployment__c = deployment.Id;
            }
            for (SourceWrapper sw : sourceList) {
                if (sw.isSelected) {
                    destinationOrg.To_Org__c = sw.orgRecord.Id;
                    break;
                }
            }

            String selection = ApexPages.currentPage().getParameters().get('selection');
            if (null == destinationOrg.To_Org__c && !String.isEmpty(selection)) {
                destinationOrg.To_Org__c = selection;
            }

            if (destinationOrg.To_Org__c != null && Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
                Org__c destOrg = [SELECT Id, Validated_Status__c FROM Org__c WHERE Id = :destinationOrg.To_Org__c];
                if (destOrg.Validated_Status__c != 'OK' && !Test.isRunningTest()) {
                    DeployAPI.validateOrgAsync(destOrg.Id);
                }
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to upsert destination org
     * To prevent the required field missing error during dml check the detail field is null or not (To_Org__c)
     */
    public void upsertDestinationOrg() {
        if (pageMessagesMap.isEmpty()) {
            // setup the save point for rollback
            Savepoint sp;
            if (!Test.isRunningTest()) {
                sp = Database.setSavepoint();
            }
            try {
                if (destinationOrg.To_Org__c != null) {
                    Utilities.Secure_DML(destinationOrg, Utilities.DML_Action.UPS, schema.SObjectType.Destination_Org__c);
                }
            } catch (Exception excp) {
                // roll everything back in case of error
                Database.rollback(sp);
                pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
                return;
            }
        }
    }

    /**
     * It is used when user click on "Save & Close" button
     * First of all, we will try to upsert destination org record
     * Deployment_Last_Step__c should be populated.
     *
     * @return
     */
    public PageReference saveAndCloseStep() {
        upsertDeployment(false);
        return pageMessagesMap.isEmpty() ? goToDeploymentTab() : null;
    }

    /**
     * It is used when user click on "Confirm Target"
     * First of all, we will try to upsert destination org record
     * Deployment_Last_Step__c should be populated.
     *
     * @see DeploymentHelper
     * @return
     */
    public PageReference confirmAndGoNextStep() {
        if (destinationOrg.To_Org__c == null) {
            pageMessagesMap.put(C_WARNING, new List<Object>{ Label.WorkManager_Alert_NoRecord });
            return null;
        }
        upsertDeployment(true);
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }
}