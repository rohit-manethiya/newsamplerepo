public inherited sharing virtual class HttpCallout {
    private String url;
    private String path;
    private HttpRequest request;
    private System.Type apexType;

    /**
     * protected so it is accessible for child classes when overriding parseResponse
     */
    protected HttpResponse response;

    // CTOR

    public HttpCallout(String url, HttpMethod method) {
        request = new HttpRequest();
        this.url = url;
        this.path = '';
        request.setMethod(method.name());
    }

    // PUBLIC

    public HttpCallout path(String path) {
        this.path = path;
        return this;
    }

    public HttpCallout header(String headerKey, String headerValue) {
        request.setHeader(headerKey, headerValue);
        return this;
    }

    public HttpCallout timeout(Integer timeout) {
        request.setTimeout(timeout);
        return this;
    }

    public HttpCallout body(String body) {
        request.setBody(body);
        return this;
    }

    public HttpCallout body(Object payload) {
        body(JSON.serialize(payload));
        return this;
    }

    public HttpCallout request() {
        if (request.getMethod() == HttpMethod.POST.name() && request.getBodyAsBlob() == null) {
            header('Content-Length', '0');
        }
        request.setEndpoint(url + path);
        response = new Http().send(request);
        return this;
    }

    public HttpCallout type(System.Type apexType) {
        this.apexType = apexType;
        return this;
    }

    /**
     * In case the developer wants to handle the response itself
     */
    public HttpResponse response() {
        return response;
    }

    public Object parseResponse() {
        return processResponse();
    }

    // PROTECTED

    /**
     * virtual so child classes can override it, for example, for XML or Blob responses
     */
    protected virtual Object processResponse() {
        return apexType != null ? JSON.deserialize(response.getBody(), apexType) : JSON.deserializeUntyped(response.getBody());
    }
}