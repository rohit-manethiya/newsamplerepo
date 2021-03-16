@isTest
private class TestJobsManager {

    @isTest static void test_ReplacementStatusManager_simple() {

        Org__c testOrg = new Org__c(Name='Test Org');
        insert testOrg;
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOrg);
        JobsManager controller = new JobsManager(stdController);

        System.assertNotEquals(null, controller.namespace);

        // verify if there are running job(s)
        controller.possibleRunningJobs = ',DUMMY-JOB-TYPE,,true;,DUMMY-JOB-TYPE3,00Db0000000YN5REAW,false';

        controller.jsRunningJobsMatching();
        System.assertEquals(0, controller.runningJobsMatching.size());
        System.assertEquals('null', controller.jsLatestRunningJobsMatching);

        // create a job with a DIFFERENT type, refresh the list, and it should be empty
        controller.matchingKey = '';
        controller.apiType = 'DUMMY-JOB-TYPE2';
        controller.parentId = null;
        controller.status = 'check';

        controller.jsCreateRunningJob();
        controller.latestRunningJobsMatching = null;
        controller.jsRunningJobsMatching();
        System.assertEquals('null', controller.jsLatestRunningJobsMatching);
        System.assertEquals(0, controller.runningJobsMatching.size());

        // create a job with a MATCHING type
        controller.matchingKey = '';
        controller.apiType = 'DUMMY-JOB-TYPE';
        controller.parentId = null;
        controller.status = 'check';

        controller.jsCreateRunningJob();
        controller.latestRunningJobsMatching = null;
        controller.jsRunningJobsMatching();
        System.assertNotEquals('null', controller.jsLatestRunningJobsMatching);
        System.assertEquals(1, controller.runningJobsMatching.size());

        // Now finish the job and check it does not show up anymore
        for(JobsManager.Copado_Notification_Wrapper w : controller.runningJobsMatching) {
            Copado_Notification__c c = new Copado_Notification__c(Id=w.Id);
            c.isFinished__c = True;
            update c;
        }
        controller.latestRunningJobsMatching = null;
        controller.jsRunningJobsMatching();
        System.assertEquals(0, controller.runningJobsMatching.size());
        System.assertEquals('null', controller.jsLatestRunningJobsMatching);

        // listen to other types of jobs, not owned by me even
        controller.possibleRunningJobs = 'DUMMY-MATCHING-KEY,DUMMY-JOB-TYPE4,,false';
        // create a job with a MATCHING key
        controller.matchingKey = 'DUMMY-MATCHING-KEY';
        controller.apiType = 'DUMMY-JOB-TYPE4';
        controller.parentId = null;
        controller.status = 'check';

        controller.jsCreateRunningJob();
        System.assertEquals(1, controller.runningJobsMatching.size());
    }

    @isTest static void test_JobsManager() {

        Org__c testOrg = new Org__c(Name='Test Org');
        insert testOrg;
        JobsManager controller = new JobsManager();

        controller.loadTasks(); // just ensure that without parameters everything works.
        controller.getFormattedDatetime(); // call a visual helper to have the current date time in VF.

        // verify if there are running job(s), none.
        controller.matchingKeysString = 'GIT-00Db0000000YN5REAW-XXX;GIT-00Db0000000YN5REAW-YYY';
        System.assertEquals('GIT-00Db0000000YN5REAW-XXX;GIT-00Db0000000YN5REAW-YYY', controller.matchingKeysString);
        controller.loadTasks();
        System.assertEquals(0, controller.getRunningTasks().size());
        System.assertEquals(0, controller.getTasks().size());
        System.assertEquals(false, controller.getHasRunningTasks());
    }

}