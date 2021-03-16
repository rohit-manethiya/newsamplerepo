public with sharing abstract class AbstractDXOrg implements IDXOrgBehavior {
    private Id orgId;
    private String orgDefinitionJSON;
    private String scratchOrgName;

    public virtual void setOrgId(Id orgId) {
        this.orgId = orgId;
    }

    protected Id getOrgId() {
        return this.orgId;
    }

    public void setOrgDefinitionJSON(String orgDefinitionJSON) {
        this.orgDefinitionJSON = sfdxApiHelper.returnJsonAfterCorrection(orgDefinitionJSON);
    }

    protected String getOrgDefinitionJSON() {
        return this.orgDefinitionJSON;
    }

    public void setScratchOrgName(String scratchOrgName) {
        this.scratchOrgName = scratchOrgName;
    }

    protected String getScratchOrgName() {
        return this.scratchOrgName;
    }

    public List<Git_Org_Commit__c> getCommitHistory() {
        return null;
    }

    public void deployOrgExtension() {

    }

    protected String sendDXRequest(String url, String messageBody, String requestType, Boolean bodyRequired, String notificationType) {
        HttpResponse response = SfdxAPIHelper.callDxJob(requestType, url, messageBody, bodyRequired);
        String responseBody = response.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse frontAPIResponse = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(responseBody, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(frontAPIResponse.copadoJobId)) {
            JobsManager.createRunningJob(frontAPIResponse.copadoJobId, notificationType, null, Label.Starting);
        }
        return responseBody;
    }

    protected void validateOrgId() {
        if(String.isBlank(orgId)) {
            throw new OrgException(Label.Org_Display_Username_Required);
        }
    }

    protected String encode(String urlParameter) {
        if(String.isNotBlank(urlParameter)) {
            urlParameter = EncodingUtil.urlEncode(urlParameter, DXLabel.UTF_8);
        }
        return urlParameter;
    }

    public class OrgException extends Exception {}
}