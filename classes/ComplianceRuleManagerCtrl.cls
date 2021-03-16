public with sharing class ComplianceRuleManagerCtrl {
    // PUBLIC

    @AuraEnabled
    public static String getComplianceFileFromBackend() {
        HttpRequest request = new HttpRequest();
        DeployAPI.setAuthHeaders(request);
        request.setTimeout(30000);
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(Settings.server_url + '/json/v1/complianceMetadata');
        request.setMethod('GET');

        HttpResponse result = new Http().send(request);
        return result.getBody();
    }

    @AuraEnabled
    public static void deleteCriterias(List<Compliance_Rule_Criteria__c> criterias) {
        try {
            Utilities.Secure_DML(criterias, Utilities.DML_Action.DEL, Schema.SObjectType.Compliance_Rule_Criteria__c);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveCriterias(List<Compliance_Rule_Criteria__c> criteria, String criteriaLogic, String metadataType) {
        try {
            Savepoint sp = Database.setSavepoint();
            if (!criteria.isEmpty()) {
                Utilities.Secure_DML(criteria, Utilities.DML_Action.UPS, Schema.SObjectType.Compliance_Rule_Criteria__c);

                Id ruleId = criteria.get(0).Compliance_Rule__c;

                Compliance_Rule__c rule = new ComplianceRulesSelector().byId(new Set<Id>{ ruleId }).get(0);
                rule.Metadata_Type__c = metadataType;
                rule.Filter_Criteria__c = parseLogic(criteriaLogic, ruleId);
                // @TODO: Add validations in US-0019285
                rule.Is_Valid__c = true;
                // @TODO: To be removed when backend deletes it
                rule.Record_Count_Criteria__c = 'Number of groups';
                rule.Matching_Criteria__c = 'Greater or Equal';
                rule.Record_Count__c = 1;

                Utilities.Secure_DML(rule, Utilities.DML_Action.UPD, Schema.SObjectType.Compliance_Rule__c);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Compliance_Rule_Criteria__c> criteriasOfRule(Id ruleId) {
        return new ComplianceRuleCriteriaSelector().byComplianceRuleId(new Set<Id>{ ruleId });
    }

    @AuraEnabled
    public static Boolean hasComplianceRuleFLS() {
        Set<DescribeFieldResult> fields = new Set<DescribeFieldResult>{
            Schema.SObjectType.Compliance_Rule__c.fields.Metadata_Type__c,
            Schema.SObjectType.Compliance_Rule__c.fields.Filter_Criteria__c,
            Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c
        };

        try {
            return isAccessible(fields);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // PRIVATE

    private static String parseLogic(String criteriaLogic, Id ruleId) {
        String result = criteriaLogic;    

        Integer criteriaCount = criteriaLogic.split('AND|OR').size();
        Map<Decimal, Compliance_Rule_Criteria__c> criteriaByOrder = getCriteriaByOrder(criteriasOfRule(ruleId));

        for (Integer i = 1; i <= criteriaCount; i++) {
            result = result.replaceFirst(String.valueOf(i), '<' + String.valueOf(i) + '>');
        }

        for (Integer i = 1; i <= criteriaCount; i++) {
            result = result.replaceFirst('<' + String.valueOf(i) + '>', criteriaByOrder.get(i).Name);
        }

        return result;
    }

    private static Map<Decimal, Compliance_Rule_Criteria__c> getCriteriaByOrder(List<Compliance_Rule_Criteria__c> criteriaList) {
        Map<Decimal, Compliance_Rule_Criteria__c> result = new Map<Decimal, Compliance_Rule_Criteria__c>();

        for (Compliance_Rule_Criteria__c criteria : criteriaList) {
            result.put(criteria.Order__c, criteria);
        }

        return result;
    }

    private static Boolean isAccessible(Set<DescribeFieldResult> fields) {
        Boolean result = true;

        for (DescribeFieldResult field : fields) {
            if (!field.isAccessible()) {
                result = false;
                break;
            }
        }

        return result;
    }
}