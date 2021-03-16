/**
 * Created by jgaviria@copado.com
 * This will be executed in the Post Install Script
 * And will be refreshing the ScratchOrg Status and Cleaning the Attachments that are not needed
 */

    global class SfdxSchedulable implements Schedulable {


    public static String JOB_NAME = 'Copado DX Schedulable';
    // Every Day at 1am
    public static String CRON_EXP = String.valueOf(Datetime.now().second()) + ' ' + String.valueOf(Datetime.now().minute() + 2) + ' ' + String.valueOf(Datetime.now().hour()) + ' * * ?';

    global void execute(SchedulableContext ctx) {
        System.debug('Schedulign job');
        SfdxAPI.refreshStatus();
    }
}