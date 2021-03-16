public with sharing class GenerateStaticCodeAnalysisRuleSet {
    private enum ScaSeverity {
        SUCCESS,
        ERROR,
        INFO
    }
    private Static_Code_Analysis_Settings__c staticCodeAnalysisSettings;
    public List<Static_Code_Analysis_Rule__c> apexRulesList { get; set; }
    public Map<String, List<Object>> pageMessagesMap { get; set; }

    public GenerateStaticCodeAnalysisRuleSet(ApexPages.StandardController std) {
        this.staticCodeAnalysisSettings = (Static_Code_Analysis_Settings__c) std.getRecord();
        pageMessagesMap = new Map<String, List<Object>>();
        pageMessagesMap.put(ScaSeverity.INFO.name().toLowerCase(), new List<Object>{ Label.SCA_DoYouWantToContinue });
    }

    /**
     * It is used to make a callout to backend to populate values
     */
    public void generateDefaultRuleSet() {
        String url = Settings.server_url + '/json/v1/code/analysis/static/tool/pmd/rules';
        apexRulesList = new List<Static_Code_Analysis_Rule__c>();
        pageMessagesMap.clear();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'text/json');
            req.setHeader('userId', UserInfo.getUserId());
            req.setHeader('orgId', UserInfo.getOrganizationId());
            req.setHeader('token', DeployAPI.getAuthToken());
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
            List<PMDResponseWrapper> responseList = (List<PMDResponseWrapper>) JSON.deserialize(res.getBody(), List<PMDResponseWrapper>.class);
            for (PMDResponseWrapper pmd : responseList) {
                Static_Code_Analysis_Rule__c rule = new Static_Code_Analysis_Rule__c();
                rule.Static_Code_Analysis_Settings__c = staticCodeAnalysisSettings.Id;
                rule.Rule_Name__c = pmd.name;
                rule.Priority__c = pmd.priority;
                rule.Message__c = pmd.message;
                rule.Rule_Reference__c = pmd.ref;
                apexRulesList.add(rule);
            }
        } catch (Exception excp) {
            pageMessagesMap.put(ScaSeverity.ERROR.name().toLowerCase(), new List<Object>{ excp.getMessage() });
            return;
        }

        Utilities.Secure_DML(
            [SELECT Id FROM Static_Code_Analysis_Rule__c WHERE Static_Code_Analysis_Settings__c = :staticCodeAnalysisSettings.Id],
            Utilities.DML_Action.DEL,
            schema.SObjectType.Static_Code_Analysis_Settings__c
        );
        Utilities.Secure_DML(apexRulesList, Utilities.DML_Action.INS, schema.SObjectType.Static_Code_Analysis_Rule__c);

        Boolean pageMessagesExist = ApexPages.getMessages().isEmpty();
        String pageMessages = Label.DEFAULT_RULESET_GENERATED;
        String severity = ScaSeverity.SUCCESS.name().toLowerCase();
        if (!pageMessagesExist) {
            for (Apexpages.Message msg : ApexPages.getMessages()) {
                pageMessages = msg.getDetail();
                severity = ScaSeverity.ERROR.name().toLowerCase();
            }
        }

        pageMessagesMap.put(severity, new List<Object>{ pageMessages });
    }

    /**
     * It is used to return back to detail page of the Static_Code_Analysis_Settings__c
     *
     * @return
     */
    public PageReference goBack() {
        PageReference pr = new ApexPages.StandardController(staticCodeAnalysisSettings).view();
        pr.setRedirect(true);
        return pr;
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getPageMessageSize() {
        Integer listsize = 0;
        for (String severity : pageMessagesMap.keySet()) {
            listsize += pageMessagesMap.get(severity).size();
        }
        return listsize;
    }

    /**
     * It is used to store PMD values callout response
     */
    public class PMDResponseWrapper {
        public String name { get; set; }
        public String ref { get; set; }
        public String priority { get; set; }
        public String message { get; set; }
    }
}