public class ComplianceRuleCriteriaTriggerHandler implements ITrigger{
    public ComplianceRuleCriteriaTriggerHandler() {}

    public void bulkBefore() {
        if(Trigger.isDelete) {
            ComplianceRuleCriteriaTriggerHelper.checkIfRuleStillValid((Map<Id,Compliance_Rule_Criteria__c>)Trigger.oldMap,(List<Compliance_Rule_Criteria__c>)Trigger.old);
        } 
    }

    public void bulkAfter() {        
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            ComplianceRuleCriteriaTriggerHelper.checkIfRuleStillValid((Map<Id,Compliance_Rule_Criteria__c>)Trigger.oldMap,(List<Compliance_Rule_Criteria__c>)Trigger.new);
        } 
    }

    public void beforeInsert(SObject so) {}

    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {}

    public void afterUpdate(SObject oldSo, SObject so) {}

    public void afterDelete(SObject so) {}

    public void afterUndelete(SObject so) {}

    public void andFinally() {}
}