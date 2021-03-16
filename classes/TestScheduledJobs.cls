@isTest
private class TestScheduledJobs {
    @testSetup static void setupTestData(){
        insert TestUtilities.getTestSettings();
    }
    static testMethod void test(){
        Scheduled_Job__c job = new Scheduled_Job__c(name='test job', webhook_url__c= 'https://xyz.com', run_as_user__c = UserInfo.getUserId(), Delete_Runs_after_days__c=1);
        insert job;
        ApexPages.StandardController std = new ApexPages.StandardController(job);
        ScheduledJobExtension ext = new ScheduledJobExtension(std);
        ext.schedule_job();
        ext.job.Cron_Expression__c = '0 0 12 ? * MON *';
        ext.save_job();
        job = [select id,name, apex_job_id__c from Scheduled_Job__c where id = :job.Id];
        System.assert(job.Apex_Job_ID__c!=null);
        ext.stop();
        job = [select id,name, apex_job_id__c from Scheduled_Job__c where id = :job.Id];
        System.assert(job.Apex_Job_ID__c==null);
        System.assert(testMethodUtilities.hasMessage(Label.JOB_UNSCHEDULED_SUCCESSFULLY));
        ext.stop();
        System.assert(testMethodUtilities.hasMessage(Label.NOTHING_TO_STOP));
        
        ext.job.Cron_Expression__c = 'x err 12 ? * exception *';
        ext.save_job();
        System.assert(testMethodUtilities.hasMessage(Label.COULD_NOT_SCHEDULE_JOB));
        
        ext.delete_job();
        System.assertEquals(0,[select count() from Scheduled_Job__c where id = :job.Id]);
    }
    static testMethod void test_invalid_job(){
        Scheduled_Job__c job = new Scheduled_Job__c(name='test job', webhook_url__c= 'https://xyz.com', run_as_user__c = UserInfo.getUserId(), Delete_Runs_after_days__c=1, apex_job_id__c='a0p24000001fABC');
        insert job;
        ApexPages.StandardController std = new ApexPages.StandardController(job);
        ScheduledJobExtension ext = new ScheduledJobExtension(std);
        ext.stop();
        System.assert(testMethodUtilities.hasMessage(Label.NO_JOB_FOUND));
    }
    static testMethod void test_schedulable(){
        Scheduled_Job__c job = new Scheduled_Job__c(name='test job', webhook_url__c= 'https://xyz.com', run_as_user__c = UserInfo.getUserId(), Delete_Runs_after_days__c=1);
        insert job;
        Test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController(job);
        ScheduledJobExtension ext = new ScheduledJobExtension(std);
        ext.schedule_job();
        ext.job.Cron_Expression__c = '0 0 12 ? * MON *';
        ext.save_job();
        job = [select id,name, apex_job_id__c from Scheduled_Job__c where id = :job.Id];
        System.assert(job.Apex_Job_ID__c!=null);
        Test.stopTest();
    }
}