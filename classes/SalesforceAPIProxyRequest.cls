public inherited sharing class SalesforceAPIProxyRequest {
    private String logLabelIdentifier;
    private String requestType;
    private String endPointUrlService;
    private String orgCredentialId;
    /**
     * This only applies for POST requestType
     */
    private String requestPayload;

    // CTOR

    public SalesforceAPIProxyRequest(String endPointUrlService, String orgCredentialId) {
        requestType = HttpMethod.GET.name();
        this.endPointUrlService = endPointUrlService;
        this.orgCredentialId = orgCredentialId;
    }

    // PUBLIC

    public SalesforceAPIProxyRequest logLabelIdentifier(String logLabelIdentifier) {
        this.logLabelIdentifier = logLabelIdentifier;
        return this;
    }

    public SalesforceAPIProxyRequest requestType(String requestType) {
        this.requestType = requestType;
        return this;
    }

    public SalesforceAPIProxyRequest requestPayload(String requestPayload) {
        this.requestPayload = requestPayload;
        return this;
    }
}