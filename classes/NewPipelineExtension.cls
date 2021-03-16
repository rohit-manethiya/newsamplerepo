/**
 * Copado pipeline setup only allows 1 setup in progress
 * This class catches if there is an in progress setup for current user and asks the user to continue
 * Otherwise it auto re-directs to setup wizard
 */

public with sharing class NewPipelineExtension {
    public Boolean inProgress { get; set; }
    public Deployment_Flow__c currentPipeline { get; set; }

    /**
     * Constructor
     *
     * @param stdController standard Controller
     */
    public NewPipelineExtension(ApexPages.StandardController stdController) {
        inProgress = false;
    }
    /**
     * Checks Setup_Wizard_Steps__c custom setting for current user to identify on going setup process if there is any
     * @return Page Reference
     */
    public PageReference setupDecisioner() {
        Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        System.debug('setupWizardSettings::::' + setupWizardSettings);
        if(String.isNotBlank(setupWizardSettings.Pipeline_Id__c)) {
            if(Schema.SObjectType.Deployment_Flow__c.isAccessible() && Schema.SObjectType.Deployment_Flow__c.isQueryable()) {
                List<Deployment_Flow__c> currentPipelines = [SELECT Id, Name FROM Deployment_Flow__c WHERE Id = :setupWizardSettings.Pipeline_Id__c];
                if(!currentPipelines.isEmpty()) {
                    currentPipeline = currentPipelines[0];
                    inProgress = true;
                } else {
                    Utilities.Secure_DML(setupWizardSettings, Utilities.DML_Action.DEL, schema.SObjectType.Setup_Wizard_Steps__c);
                }
            } else {
                //TODO: add toast to page
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow__c.getLabel());
            }
            return null;
        } else {
            return goToSetup();
        }
    }
    /**
     * Start new setup by ignoring the existing one.
     * @see goToSetup
     * @return PageReference
     */
    public PageReference startNew() {
        Setup_Wizard_Steps__c setupWizardSettings = Setup_Wizard_Steps__c.getInstance(UserInfo.getUserId());
        delete setupWizardSettings;
        return goToSetup();
    }

    public PageReference goToSetup() {
        PageReference pipelineSetup = Page.SetupWizardStart;
        pipelineSetup.getParameters().put('newPipeline', 'true');
        pipelineSetup.setRedirect(true);
        return pipelineSetup;
    }
}