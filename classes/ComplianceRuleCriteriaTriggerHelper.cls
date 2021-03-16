public without sharing class ComplianceRuleCriteriaTriggerHelper {
	public static void checkIfRuleStillValid(Map<Id, Compliance_Rule_Criteria__c> oldMap, List<Compliance_Rule_Criteria__c> triggerScope) {
		Set<Id> inValidRules = new Set<Id>();
		if (!Trigger.isDelete) {
			for (Compliance_Rule_Criteria__c crc : triggerScope) {

				if (oldMap != null) {
					if (!inValidRules.contains(crc.Compliance_Rule__c) && (crc.Node__c != oldMap.get(crc.Id).Node__c || crc.Field__c != oldMap.get(crc.Id).Field__c || crc.Operator__c != oldMap.get(crc.Id).Operator__c || crc.Value__c != oldMap.get(crc.Id).Value__c) ) {
						inValidRules.add(crc.Compliance_Rule__c);
					}
				} else {
					inValidRules.add(crc.Compliance_Rule__c);
				}
			}
			System.debug(loggingLevel.Error, '*** inValidRules: ' + inValidRules);
			List<Compliance_Rule__c> rulesList = new List<Compliance_Rule__c>();
			for (Id rId : inValidRules) {
				Compliance_Rule__c rule = new Compliance_Rule__c();
				rule.Id = rId;

				rule.Last_Validation_Status_Message__c = '';
				rule.Last_Validation_Date_time__c = null;
				rule.Is_Valid__c = FALSE;

				rulesList.add(rule);
			}
			System.debug(loggingLevel.Error, '*** rulesList: ' + rulesList);
			Utilities.Secure_DML(rulesList, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Rule__c);
		} else {
			for (Compliance_Rule_Criteria__c crc : triggerScope) {
				inValidRules.add(crc.Compliance_Rule__c);
			}
		}

	}
}