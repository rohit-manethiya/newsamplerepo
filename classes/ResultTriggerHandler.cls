public with sharing class ResultTriggerHandler implements ITrigger {
    public ResultTriggerHandler() {
    }
    public void bulkBefore() {
        if (Trigger.isUpdate) {
            ResultTriggerHelper.prepareData(Trigger.New);
        }
    }

    public void bulkAfter() {
    }

    private void beforeCommon(SObject oldSo, SObject so) {
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
    }

    public void afterUpdate(SObject oldSo, SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }

    public void andFinally() {
        if (Trigger.isUpdate) {
            ResultTriggerHelper.updateDeploymentJobStatus();
        }
    }
}