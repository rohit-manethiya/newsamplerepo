public interface OrgAuthenticationInterface {
    Map<String, String> getActionNames();
    Org__c getOrgCredential(Boolean useCustomSetting);
    String getStep();
    OrgAuthenticationWrapper.SetStepReturnWrapper setStep(String jsonValue);
    PageReference doOauth();
    PageReference pageRedirectOnLoad();
    OrgAuthenticationWrapper.ResponseActionPollerWrapper runAction();
}