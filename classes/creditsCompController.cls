/**
 * This class is used to retrieve available credit for org
 */
public with sharing class creditsCompController {
    // Not constants
    public String buyCreditsUrl { get; set; }
    public String manageSubscriptionUrl { get; set; }
    public String autoRechargeUrl { get; set; }
    public String creditBalance { get; set; }
    public String minutesBalance { get; set; }
    public Boolean isValid { get; set; }
    public Boolean autoRechargeEnabled { get; set; }
    public Boolean showError { get; set; }
    public String errorMessage { get; set; }

    // Constants
    private final String USERID = '&userId=';
    private final String C_ORGID = '&orgId=';

    /**
     * Construction
     */
    public creditsCompController() {
        showError = false;
        autoRechargeEnabled = false;
        errorMessage = '';
        isValid = true;
        getCredits();
    }

    /**
     * This is used to get available credits by doing callout to backend
     * Note: If user didn't complete the setup process, it should never run
     */
    public void getCredits() {
        List<Org__c> validatedOrgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        if(Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
            validatedOrgList = [SELECT Id FROM Org__c WHERE Validated_Date__c != NULL AND SFDC_Org_ID__c = :orgId LIMIT 1];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Org__c.getLabel());
            return;
        }

        // else is not needed because message is added on component by using javascript
        if(!validatedOrgList.isEmpty()) {
            try {
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                DeployAPI.setAuthHeaders(req); // to authenticate against heroku servers
                req.setEndpoint(Settings.server_url);
                req.setMethod('GET');
                HttpResponse res = h.send(req);
                if(res.getStatusCode() == 200) {
                    Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> orgMap = (Map<String, Object>) fullMap.get('customerOrg');
                    creditBalance = '' + (Integer) orgMap.get('credits');
                    minutesBalance = '' + (Integer) orgMap.get('minutes');
                    autoRechargeEnabled = (Boolean) orgMap.get('autoRecharge');
                    buyCreditsUrl = Settings.copado_site + '/buyCredits?lang=' + UserInfo.getLanguage() + USERID + UserInfo.getUserId() + C_ORGID + UserInfo.getOrganizationId();
                    autoRechargeUrl = Settings.copado_site + '/autoRecharge?lang=' + UserInfo.getLanguage() + USERID + UserInfo.getUserId() + C_ORGID + UserInfo.getOrganizationId();
                    manageSubscriptionUrl = Settings.server_url + '/subscription/manage';
                } else if(res.getStatusCode() != 500) {
                    // 500 is internal server error. Customer do not want to see only "Error 500" message at credit component
                    showError = true;
                    errorMessage = res.getStatusCode() + (res.getStatus() != null ? + ' - ' + res.getStatus() : '');
                }
            } catch(Exception ex) {
                showError = true;
                errorMessage = '' + ex;
            }
        }
    }

    /**
     * This is used to return user to LicenseManager page
     *
     * @return Pagereference
     */
    public PageReference getLicenseManagerReference() {
        PageReference redirectPage = Page.LicenseManager;
        redirectPage.setRedirect(true);
        return redirectPage;
    }
}