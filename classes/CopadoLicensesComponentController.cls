/**
 * This is the controller for CopadoLicenses component
 * It will check the user licenses
 * If there is no licenses assigned to the user, it will stay in the component to assign licenses
 * If there is licenses assigned to the user, it will redirect to the next step by updating the "Last_Step__c" field at custom setting
 */
public with sharing class CopadoLicensesComponentController extends WizardHelper {
    public Integer copadoEnterpriseLicencesUsed { get; set; }
    public Integer copadoEnterpriseLicencesAvailable { get; set; }
    public Integer copadoCCMLicencesUsed { get; set; }
    public Integer copadoCCMLicencesAvailable { get; set; }
    public Boolean hasLicenseLimitReached { get; set; }
    public String isReleaseManager { get; set; }

    public CopadoLicensesComponentController() {
        hasLicenseLimitReached = false;
        getLicenseAvailability();
        if(copadoEnterpriseLicencesAvailable == 0){
            handleError(Label.COPADO_LICENSE_LIMIT_REACHED, new List<String> { Label.Pipeline_No_License_Provisioned }, null);
        }
    }

    /**
     * This method is used to check user licenses on component load function
     * If there is licenses assigned, update the "Last_Step__c" field of the custom setting with "PipelineSettings" value
     *
     * @return null if no licenses assigned to user
     * @return PipelineSettingWizard page if licenses assigned to user
     */
    public PageReference checkUserLicense() {
        List<Copado_License__c> userHasLicense = doesUserHaveLicense();
        if(!userHasLicense.isEmpty()) {
            if(userHasLicense[0].Enable_Copado__c && (!checkPipelines() || isNewPipeline == 'true') ) {
                return goToNextComponent();
            } else {
                return goToFinalStep();
            }
        }
        return null;
    }

    /**
    * This method is used to check available & used licence numbers for licence types of Enterprise and CCM
    * @return void
    *
    * Handle Errors requires three parameters: (String errorMsg, List<String> stepsToFix, String actionName)
    * */
    public void getLicenseAvailability() {
        copadoEnterpriseLicencesAvailable = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        copadoCCMLicencesAvailable = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        copadoEnterpriseLicencesUsed = 0;
        copadoCCMLicencesUsed = 0;
        List<Copado_License__c> licenses = [
                SELECT Id, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_Copado__c
                FROM Copado_License__c
                ORDER BY SetupOwner.Name
        ];
        if(!licenses.isEmpty()) {
            for(Copado_License__c license : licenses) {
                if(license.Enable_Copado__c) {
                    copadoEnterpriseLicencesUsed++;
                }
                if(license.Enable_CCM__c) {
                    copadoCCMLicencesUsed++;
                }
            }
        }
        if(copadoEnterpriseLicencesAvailable <= copadoEnterpriseLicencesUsed && copadoCCMLicencesAvailable <= copadoCCMLicencesUsed) {
            hasLicenseLimitReached = true;
        }
    }

    public void updateLicenseToAssign() {
        System.debug('Selected license updated... ' + isReleaseManager);
    }

    /**
     * This method will assign selected license to user
     * Update the "Last_Step__c" value of the custom setting, next step will be "PipelineSettings" component
     *
     * @return PipelineSettingWizard page
     */
    public PageReference assignLicense() {
        if(String.isBlank(isReleaseManager)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Pipeline_Need_To_Select_Answer);
            return null;
        }
        //check if limits reached
        System.debug('Getting latest license availability...' + isReleaseManager);
        getLicenseAvailability();
        Boolean licenseLimitReached = false;
        if(isReleaseManager == 'yes' && (copadoEnterpriseLicencesUsed >= copadoEnterpriseLicencesAvailable)) {
            handleError(Label.COPADO_LICENSE_LIMIT_REACHED, new List<String> { Label.Pipeline_Unassign_License }, null);

            licenseLimitReached = true;
        } else if(isReleaseManager == 'no' && (copadoCCMLicencesUsed >= copadoCCMLicencesAvailable)) {
            handleError(Label.CCM_LICENSE_LIMIT_REACHED, new List<String> { Label.Pipeline_Unassign_License }, null);
            licenseLimitReached = true;
        }
        System.debug('Is limit reached? ' + licenseLimitReached);
        if(licenseLimitReached) {
            return null;
        }

        //create license record
        Copado_License__c license = Copado_License__c.getInstance(UserInfo.getUserId());
        if(license == null) {
            license = new Copado_License__c();
        }
        license.SetupOwnerId = UserInfo.getUserId();
        if(isReleaseManager == 'yes') {
            license.Enable_Copado__c = true;
        } else if(isReleaseManager == 'no') {
            license.Enable_CCM__c = true;
        }

        try {
            Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.SObjectType.Copado_License__c);
        } catch(Exception excp) {
            handleException(excp);
            return null;
        }
        System.debug('License saved... Updating last step');
        //update last step and return
        if(license.Enable_Copado__c == true) {
            if(checkPipelines() && isNewPipeline != 'true' ) {
                return goToFinalStep();
            } else {
                return goToNextComponent();
            }
        } else if(license.Enable_CCM__c == true) {
            return goToFinalStep();
        } else {
            return null;
        }
    }
    private PageReference goToFinalStep() {
        updateSetupWizardCustomSetting(String.valueOf(SetupPipelineOrder.SetupWizardFinish), null, null, null, null, null, null);
        return goToNextComponent(String.valueOf(SetupPipelineOrder.SetupWizardFinish));
    }

    private Boolean checkPipelines() {
        if(Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                List<Deployment_Flow__c> currentPipelines = [
                    SELECT Id, Name, Git_Repository__c,Active__c
                    FROM Deployment_Flow__c
                    LIMIT 1
                ];

                return currentPipelines.isEmpty() ? false : true;
        } //we dont need a else here because if they don't have permission that mean they will go to end
        return false;
    }
}