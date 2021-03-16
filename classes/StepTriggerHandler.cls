public without sharing class StepTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {
    }
    public StepTriggerHandler() {
    }

    public void bulkBefore() {
        //prevent any DML for non Copado enabled users
        if(!LicenseHelper.isCopadoEnabled() && !LicenseHelper.isCCMEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        if(Trigger.isInsert || Trigger.isUpdate) {
            if(LicenseHelper.isLicensesExceeded()) {
                for(Step__c st : (List<Step__c>) Trigger.New) {
                    st.addError(Label.LICENSES_EXCEEDED);
                }

            }
        }
        if(Trigger.isUpdate || Trigger.isInsert) {
            StepTriggerHelper.prepareData(Trigger.new);
        }
    }

    public void bulkAfter() {

    }

    public void beforeCommon(SObject so) {
        if(!StepTriggerHelper.isFeatureEnabled((Step__c) so))so.addError(Label.STEP_NOT_SUPPORTED);
    }

    public void beforeInsert(SObject so) {
        beforeCommon(so);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        beforeCommon(so);
        StepTriggerHelper.notifyNextOrCurrentStepOwner((Step__c) so);
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        StepTriggerHelper.addHistory((Step__c) so, 'created');
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        StepTriggerHelper.addHistory((Step__c) oldSo, (Step__c) so);
        StepTriggerHelper.checkIfInProgressManualTask((Step__c) so, (Step__c) oldSo);
    }

    public void afterDelete(SObject so) {
        StepTriggerHelper.addHistory((Step__c) so, 'deleted');
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        StepTriggerHelper.insertHistory();
        if(Trigger.isAfter) {
            StepTriggerHelper.togglePauseCheckboxOnDeployment();
        }
    }
}