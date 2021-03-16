/**
 * This is the main page for setup wizard to create pipeline
 * It will check "Setup Wizard Steps" custom setting for user and find the last step
 * If there is no value in the custom setting for current user, wizard will start by clicking on "Start" button
 */
public with sharing class SetupWizardStartController extends WizardHelper {
    @TestVisible private Boolean userHasCopadoCredential = false;
    @TestVisible private Boolean userHasLicense = false;

    public SetupWizardStartController() {
        List<Copado_License__c> userLicenseList = doesUserHaveLicense();
        userHasCopadoCredential = hasValidCopadoOrgCredential();
        userHasLicense = !userLicenseList.isEmpty();
    }

    /**
     * When there is at least one pipeline created setup wizard should not show up if I have my initial setup completed.
     * This method will check initial setup and pipelines in order to display correct operation.
     * @return PageReference
     */
    public PageReference goToManager() {
        String redirectedForNew = ApexPages.currentPage().getParameters().get('newPipeline');
        if(!userHasCopadoCredential || !userHasLicense || redirectedForNew == 'true') {
            return null;
        } else if(String.isNotBlank(setupWizardSettings.Last_Step__c) && String.isBlank(redirectedForNew)) {
            return checkLastStepForWizard();
        } else if(Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            try {
                String deploymentFlowQuery = 'SELECT Id, Name, Git_Repository__c,Active__c FROM Deployment_Flow__c WHERE Calculate_Based_on__c = \'User Story\'';
                if(!Test.isRunningTest()) {
                    deploymentFlowQuery += ' ORDER BY LastViewedDate DESC NULLS LAST LIMIT 1 FOR VIEW';
                }
                Deployment_Flow__c currentPipeline = Database.query(deploymentFlowQuery);
                System.debug('*** currentPipeline :' + currentPipeline);
                PageReference pipeline = Page.PipelineManager;
                String mode = currentPipeline.Active__c ? 'manager' : 'diagram';
                pipeline.setRedirect(true);
                pipeline.getParameters().put('Id', currentPipeline.Id);
                pipeline.getParameters().put('mode', mode);
                return pipeline;

            } catch(QueryException ex) {
                System.debug('QueryException ex:::' + ex);
                // If there is no DF that current user can see Setup page should be displayed.
                return null;
            }
        } else {
            handleError(Label.INSUFFICENT_ACCESS, new List<String>{
                    Label.Insufficient_Access_Rights, Label.Related_Object + Schema.SObjectType.Deployment_Flow__c.label
            }, 'currentPage');
            return null;
        }
    }

    /**
     * This method will check the last step for wizard on page load
     *
     * @return based on "Last_Step__c" value of the custom setting
     */
    public PageReference checkLastStepForWizard() {
        if(String.isBlank(setupWizardSettings.Last_Step__c)) {
            return null;
        }

        return goToNextComponent(setupWizardSettings.Last_Step__c);
    }

    /**
     * This method will start the wizard by updating the "Last_Step__c" value of the custom setting
     * First of all, checking the org credential with current user's email.
     * If there is no org credential for package is installed or there is org credential without validation, redirect to the "ProductionOrgAuthenticationWizard" page
     * Otherwise, if user have already license assigned, next step will be "PipelineSettingsWizard", if not "CopadoLicensesWizard" page
     * goToNextComponent() method is finding next step based on "Last_Step__c" field
     *
     * @return ProductionOrgAuthenticationWizard page if user does not have org credential with copado installed or org is not valid
     * @return CopadoLicensesWizard page if user does not has license
     * @return PipelineSettingsWizard page if user has license
     */
    public PageReference startWizard() {
        if(!userHasCopadoCredential) {
            return goToNextComponent();
        } else {
            String wizardOrderValue = !userHasLicense ? String.valueOf(SetupPipelineOrder.CopadoLicensesWizard) : userHasLicense ? String.valueOf(SetupPipelineOrder.PipelineSettingsWizard) : String.valueOf(SetupPipelineOrder.SetupWizardFinish);
            updateSetupWizardCustomSetting(wizardOrderValue, null, null, null, null, null, null);
            return goToNextComponent(wizardOrderValue);
        }
    }
}