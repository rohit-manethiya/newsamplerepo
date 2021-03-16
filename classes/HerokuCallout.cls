public inherited sharing virtual class HerokuCallout extends HttpCallout {
    // CTOR

    public HerokuCallout(String url, HttpMethod method) {
        super(url, method);
    }

    // PUBLIC

    public HerokuCallout default() {
        header('userId', Settings.USER_ID);
        header('orgId', Settings.ORGANIZATION_ID);
        header('token', authenticationToken());
        header('Accept', 'application/json');
        header('content-type', 'application/json');
        timeout(30000);
        return this;
    }

    // PRIVATE

    private String authenticationToken() {
        String fakeSessionId = '<sessionId might change>';
        String currentDate = Datetime.now().formatGmt('yyyy-MM-dd');
        String dummyData = 'Copado Deployer by Copado Ltd' + Settings.USER_ID + Settings.ORGANIZATION_ID + fakeSessionId + currentDate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(dummyData));
        return EncodingUtil.convertToHex(hash);
    }
}