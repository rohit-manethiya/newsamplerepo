/**
 * Created by ferhatozsavran on 5/31/18.
 */

global with sharing class BurnDownItemScheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx){
        BurnDownItemBatchClass batch = new BurnDownItemBatchClass();
        Database.executebatch(batch, 200);
    }

    /**
     * Call this from Anonymous Apex to schedule at the default regularity
     * E.G.: run every night at 10:21pm
     * copado__BurnDownItemScheduler.scheduleIt('BurnDownItemScheduler create graph for user stories', '0 21 22 * * ?');
     * @param jobName  // job name must not contain empty space at the end and front
     * @param CRON_EXPR
     * @return
     */
    global static String scheduleIt(String jobName, String CRON_EXPR) {
        BurnDownItemScheduler job = new BurnDownItemScheduler();
        return System.schedule(jobName, CRON_EXPR, job);
    }
}