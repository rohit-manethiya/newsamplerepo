public without sharing class ComplianceScanResultTriggerHandler implements ITrigger {
    public ComplianceScanResultTriggerHandler() {
    }

    public void bulkBefore() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ComplianceScanResultTriggerHelper.prepareSummaryData(Trigger.new);
        } else if (Trigger.isDelete) {
            ComplianceScanResultTriggerHelper.prepareSummaryData(Trigger.old);
        }
    }

    public void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ComplianceScanResultTriggerHelper.prepareData(Trigger.new);
        } else if (Trigger.isDelete) {
            ComplianceScanResultTriggerHelper.prepareData(Trigger.old);
        }
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        ComplianceScanResultTriggerHelper.updateComplianceScanSummaryFields((Compliance_Scan_Result__c) so);
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        ComplianceScanResultTriggerHelper.updateComplianceFields((Compliance_Scan_Result__c) so);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        ComplianceScanResultTriggerHelper.updateComplianceFields((Compliance_Scan_Result__c) so);
    }

    public void afterDelete(SObject so) {
        ComplianceScanResultTriggerHelper.updateComplianceFields((Compliance_Scan_Result__c) so);
    }

    public void afterUndelete(SObject so) {
    }

    public void andFinally() {
        ComplianceScanResultTriggerHelper.dmlOperationsForAll();
    }
}