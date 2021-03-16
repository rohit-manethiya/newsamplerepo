public without sharing class ConnectionBehaviorTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {
    }

    public ConnectionBehaviorTriggerHandler() {
    }

    public void bulkBefore() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ConnectionBehaviorTriggerHelper.validateUserStoryCriterias(Trigger.new);
            ConnectionBehaviorTriggerHelper.schedulePromotionsForConnectionBehavior(Trigger.new, Trigger.old);
        }
        if (Trigger.isDelete) {
            ConnectionBehaviorTriggerHelper.deepDelete(Trigger.oldMap);
        }
    }

    public void bulkAfter() {
    }

    public void beforeCommon(SObject so) {
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
    }
}