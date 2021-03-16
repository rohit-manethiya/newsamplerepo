public class PersonaPermissionTriggerHandler implements ITrigger{
    
    public PersonaPermissionTriggerHandler() {}
 
    public void bulkBefore() {
      PersonaPermissionTriggerHelper.prepareData();
    }
 
    public void bulkAfter() {}
 
    public void beforeInsert(SObject so) {}
 
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
 
    public void afterInsert(SObject so) {
        PersonaPermissionTriggerHelper.setAffected(so);
    }
 
    public void afterUpdate(SObject oldSo, SObject so) {
        PersonaPermissionTriggerHelper.setAffected(so);
    }
 
    public void afterDelete(SObject so) {
        PersonaPermissionTriggerHelper.setAffected(so);
    }

    public void afterUndelete(SObject so) {
        PersonaPermissionTriggerHelper.setAffected(so);
    }
    
    public void andFinally() {
        PersonaPermissionTriggerHelper.callBatchRecalculation();
    }
}