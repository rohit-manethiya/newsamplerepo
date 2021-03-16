public inherited sharing class SalesforceAPIProxyCallout extends HerokuCallout {
    // CTOR

    public SalesforceAPIProxyCallout() {
        super(Settings.server_url + '/json/v1/proxyOrgRequest/', HttpMethod.POST);
    }
}