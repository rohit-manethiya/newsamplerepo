public without sharing class GitRepositoryTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {
    }
    public GitRepositoryTriggerHandler() {
    }

    public void bulkBefore() {
        //prevent any DML for non Copado enabled users
        if(!LicenseHelper.isCopadoEnabled())throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
        if(Trigger.isInsert || Trigger.isUpdate) {
            if(LicenseHelper.isLicensesExceeded()) {
                for(Git_Repository__c st : (List<Git_Repository__c>) Trigger.new) {
                    st.addError(Label.LICENSES_EXCEEDED);
                }

            }
        }
    }

    public void bulkAfter() {
    }

    public void beforeCommon(SObject so) {
        if(!FeatureHelper.isFeatureEnabled('Git Backup'))so.addError(Label.FEATURE_NOT_SUPPORTED + ': Git Backup');
    }

    public void beforeInsert(SObject so) {
        beforeCommon(so);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        beforeCommon(so);
    }
    public void beforeDelete(SObject so) {
        GitRepositoryTriggerHelper.collectRepoIds((Git_Repository__c) so);
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
        GitRepositoryTriggerHelper.deleteSensitiveInformations();
    }
}