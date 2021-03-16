global with sharing class ValidateOrgAction {
    private static final String VALIDATED_STATUS_OK = 'OK';
    private static final String ORG_TYPE_SCRATCH_ORG = 'Scratch Org';

    global with sharing class Request {
        @InvocableVariable(label='Org Id')
        global String orgId;
    }
    global with sharing class Result {
        @InvocableVariable(label='Is Valid Org')
        global Boolean isValidOrg;
    }

    @InvocableMethod(
        label='Validate Org Credential'
        description='Checks if org credential is validated, if not, try to validate and return result'
        category='Org Credential'
    )
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        Map<Id, Org__c> orgsById = getOrgsById(requests);

        for (Request request : requests) {
            Result result = new Result();
            result.isValidOrg = false;

            if (String.isNotBlank(request.orgId)) {
                Id orgId = request.orgId;
                if (orgsById.containsKey(orgId)) {
                    Org__c org = orgsById.get(orgId);
                    result.isValidOrg = isValidOrg(org);
                }
            }

            results.add(result);
        }

        return results;
    }

    public static Boolean execute(Id orgId) {
        Request request = new Request();
        request.orgId = orgId;
        List<Result> results = execute(new List<Request>{ request });
        return !results.isEmpty() ? results.get(0).isValidOrg : false;
    }

    private static Map<Id, Org__c> getOrgsById(List<Request> requests) {
        List<Id> orgIds = new List<Id>();
        for (Request request : requests) {
            if (String.isNotBlank(request.orgId)) {
                orgIds.add(request.orgId);
            }
        }
        Map<Id, Org__c> orgsById = new Map<Id, Org__c>(new OrgsSelector().byId(orgIds));
        return orgsById;
    }

    private static Boolean isValidOrg(Org__c org) {
        if (org.Disable_Validation__c == true) {
            return true;
        }
        if (String.isBlank(org.Oauth_Signature__c)) {
            return false;
        }
        if (String.isNotBlank(org.Org_Type__c) && org.Org_Type__c.startsWithIgnoreCase(ORG_TYPE_SCRATCH_ORG)) {
            return true;
        }
        if (org.Validated_Status__c == VALIDATED_STATUS_OK) {
            return true;
        }
        try {
            return DeployAPI.validateOrg(org.Id);
        } catch (Exception e) {
            return false;
        }
    }
}