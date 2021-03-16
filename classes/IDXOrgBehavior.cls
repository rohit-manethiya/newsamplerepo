public interface IDXOrgBehavior {
    List<Git_Org_Commit__c> getCommitHistory();
    void deployOrgExtension();
    void setOrgId(String orgId);
}