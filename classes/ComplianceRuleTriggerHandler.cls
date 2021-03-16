public without sharing class ComplianceRuleTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {}
   
    public ComplianceRuleTriggerHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.isInsert || Trigger.isUpdate){
            if(LicenseHelper.isLicensesExceeded()){
                for(Compliance_Rule__c rule : (List<Compliance_Rule__c>)Trigger.New){
                    rule.addError(Label.LICENSES_EXCEEDED);
                }
                
            }
        }
        if(!FeatureHelper.isComplianceHubEnabled()) {
            for(Compliance_Rule__c rule : (List<Compliance_Rule__c>)Trigger.New) {
                rule.addError(Label.FEATURE_NOT_SUPPORTED + ': Compliance Hub');
            }
        }
        if(!LicenseHelper.isCCHEnabled()) {
            for(Compliance_Rule__c rule : (List<Compliance_Rule__c>)Trigger.New)
            rule.addError(Label.CCH_LICENSE_NOT_ENABLED);
        }
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }

    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }

    public void andFinally(){
    }
}