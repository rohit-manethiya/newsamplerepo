/**
 * This is the main controller for authentication Main/Production Org Credential which Copado Package is installed
 */
public with sharing class ProductionOrgServiceController extends WizardHelper implements OrgAuthenticationInterface {

    /**
     * This method is used to populate possible actions for environment setup inner step
     *
     * @return null for this case
     */
    public Map<String, String> getActionNames() {
        return null;
    }

    /**
     * It is used to get necessary org credential
     *
     * @return Org Credential record
     */
    public Org__c getOrgCredential(Boolean useCustomSetting) {
        return getUserOrgCredential();
    }

    /**
     * It is used to define inner step in controller.
     * NOTE: It will always return "ORG_AUTHENTICATE", because other step will be completed after Git Repo is created.
     *
     * @return last step that implemented
     */
    public String getStep() {
        return ORG_AUTHENTICATE;
    }

    /**
     * It is used to do necessary changes at current step and move to next step
     *
     * @param jsonValue will store OrgAuthenticationWrapper.SetStepWrapper value in JSON, parse it first
     *
     * @return OrgAuthenticationWrapper.SetStepReturnWrapper return null in this case
     */
    public OrgAuthenticationWrapper.SetStepReturnWrapper setStep(String jsonValue) {
        return null;
    }

    /**
     * It is used to authenticate org credential
     * For org name, first of all check if there is environment for organization id
     * If there is environment, org name will be user alias plus organization name
     * If there is not, org name will be organization name
     * Define URL to be redirected after authentication and pass parameter by using "startURL"
     *
     * @return backend endpoint "/Authorize/sforceLogin"
     */
    public PageReference doOauth() {
        List<Environment__c> envList = new List<Environment__c>();
        if(Schema.SObjectType.Environment__c.isQueryable() && Schema.SObjectType.Environment__c.isAccessible()) {
            envList = [SELECT Id FROM Environment__c WHERE Org_ID__c = :UserInfo.getOrganizationId()];
        } else {
            String errorMessage = Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.label;
            throw new ProductionOrgServiceException(errorMessage);
        }

        User currentUser = getCurrentUser();

        Org__c org = new Org__c();
        String userAlias = !envList.isEmpty() ? currentUser.Alias + '-' : '';
        org.Name = (userAlias + UserInfo.getOrganizationName()).left(80);
        org.Org_Type__c = 'Production/Developer';
        try {
            Utilities.Secure_DML(org, Utilities.DML_Action.INS, schema.SObjectType.Org__c);
        } catch(Exception excp) {
            throw new ProductionOrgServiceException(excp.getMessage());
        }

        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, UTF_8) + '&url=' + EncodingUtil.urlEncode(currentUser.API_URL__c, UTF_8);
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), UTF_8);
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), UTF_8);
        urlParameters += '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), UTF_8);

        String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
        String currentURLHost = Url.getSalesforceBaseUrl().getHost();
        String currentRequestURL = Url.getCurrentRequestUrl().toExternalForm();
        String newComponentName = getNextComponentName(currentRequestURL, false);
        String lightningUrl = UserInfo.getUiThemeDisplayed().startsWithIgnoreCase('Theme4') ? '/one/one.app#/alohaRedirect/' : '';
        String newComponentURL = currentURLProtocol + '://' + currentURLHost + lightningUrl + '/apex/' + namespace + newComponentName;
        urlParameters += '&startURL=' + EncodingUtil.urlEncode(newComponentURL, UTF_8) + '?newPipeline=' + isNewPipeline;

        String herokuServer = Settings.server_url;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        PageReference pr = new PageReference(urlOauth);
        return pr;
    }

    /**
     * It is used to redirect to necessary step on page load
     * If user have already license assigned, next step will be "PipelineSettingsWizard", if not "CopadoLicensesWizard" page
     * goToNextComponent() method is finding next step based on "Last_Step__c" field
     * generateUserAPIKey() will create API key for current user
     *
     * @return CopadoLicensesWizard page if user does not has license
     * @return PipelineSettingsWizard page if user has license
     */
    public PageReference pageRedirectOnLoad() {
        Org__c org = getUserOrgCredential();
        if(org.Id == null) {
            return null;
        }

        generateUserAPIKey();

        List<Copado_License__c> userLicenseList = doesUserHaveLicense();
        Boolean userHasLicense = !userLicenseList.isEmpty();

        if(!userHasLicense) {
            return goToNextComponent();
        } else {
            updateSetupWizardCustomSetting(String.valueOf(SetupPipelineOrder.PipelineSettingsWizard), null, null, null, null, null, null);
            return goToNextComponent(String.valueOf(SetupPipelineOrder.PipelineSettingsWizard));
        }
    }

    /**
     * It is used to run possible action
     */
    public OrgAuthenticationWrapper.ResponseActionPollerWrapper runAction() {
        return null;
    }

    public class ProductionOrgServiceException extends Exception {
    }
}