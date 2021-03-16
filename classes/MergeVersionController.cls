/**
 * Created by ferhatozsavran on 3/15/18.
 */

public with sharing class MergeVersionController {
    private final Artifact_Version__c artifactVersion;

    public MergeVersionController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()){
            stdController.addFields(new List<String>{Settings.ns + 'Artifact__c',Settings.ns + 'Release__c'});
        }
        this.artifactVersion = (Artifact_Version__c)stdController.getRecord();
    }

    public void udpdateVersion(){
        try{
            System.debug('**f**artifactVersion.Artifact__c : ' + artifactVersion.Artifact__c);
            System.debug('**f**artifactVersion.Release__c : ' + artifactVersion.Release__c);
            SfdxAPI.mergeReleases(artifactVersion.Artifact__c, artifactVersion.Release__c);
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');
        System.debug('**f**jobType : ' + jobType);
        System.debug('**f**jobSuccess : ' + jobSuccess);
        System.debug('**f**jobFinished : ' + jobFinished);
        System.debug('**f**CopadoNotificationHelper.DX_ARTIFACT_MERGE_RELEASE : ' + CopadoNotificationHelper.DX_ARTIFACT_MERGE_RELEASE);
        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == CopadoNotificationHelper.DX_ARTIFACT_MERGE_RELEASE) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Merge_Version_Completed));
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }
}