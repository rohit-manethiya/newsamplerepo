public class DeploymentTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {
    }
    public DeploymentTriggerHandler() {
    }

    public void bulkBefore() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (LicenseHelper.isLicensesExceeded()) {
                for (Deployment__c st : (List<Deployment__c>) Trigger.New) {
                    st.addError(Label.LICENSES_EXCEEDED);
                }
            }
            DeploymentTriggerHelper.updateDeploymentPausedStatus(Trigger.new);
        }
        DeploymentTriggerHelper.prepareData();
    }

    public void bulkAfter() {
        if (Trigger.isAfter && Trigger.new != null) {
            DeploymentTriggerHelper.getValidateOnlyDeployments(Trigger.newMap.keyset());
            DeploymentTriggerHelper.updateEnvironmentStatus(Trigger.new, (Map<Id, Deployment__c>) Trigger.oldMap);
        }
    }

    public void beforeCommon(SObject so) {
        //prevent any DML for non Copado enabled users or non CCM users if it is a Promotion Deployment
        DeploymentTriggerHelper.canDeployThis((Deployment__c) so);
    }

    public void beforeInsert(SObject so) {
        beforeCommon(so);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        beforeCommon(so);
    }
    public void beforeDelete(SObject so) {
        if (!LicenseHelper.isCopadoEnabled()) {
            throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        }
    }

    public void afterInsert(SObject so) {
        DeploymentTriggerHelper.addHistory((Deployment__c) so, 'created');
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        DeploymentTriggerHelper.checkPromotionCompleteness((Deployment__c) oldSo, (Deployment__c) so);
        DeploymentTriggerHelper.checkBuildTaskCompleteness((Deployment__c) oldSo, (Deployment__c) so);
        DeploymentTriggerHelper.addHistory((Deployment__c) oldSo, (Deployment__c) so);
        DeploymentTriggerHelper.cleanManualTaskNotifications((Deployment__c) oldSo, (Deployment__c) so);
        DeploymentTriggerHelper.updateDeploymentLookupOnUS((Deployment__c) so);
    }

    public void afterDelete(SObject so) {
        DeploymentTriggerHelper.addHistory((Deployment__c) so, 'deleted');
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        DeploymentTriggerHelper.updateBuildTasks();
        DeploymentTriggerHelper.completePromotions();
        DeploymentTriggerHelper.insertHistory();
        DeploymentTriggerHelper.updateSteps();
        DeploymentTriggerHelper.updateUSs();
        DeploymentTriggerHelper.updateEnvironment();
    }
}