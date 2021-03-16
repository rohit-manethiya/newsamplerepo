public with sharing class ValidateOrgExtension {
    public string orgId;
    public ValidateOrgExtension(apexpages.standardController std){
        orgId = std.getId();
    }
    public PageReference validateOrg(){
    	DeployAPI.validateOrg(orgId);
        return new PageReference('/'+orgId);
    }
}