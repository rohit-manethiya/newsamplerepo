public without sharing class GitBackupTriggerHelper {
	private static boolean sched = false;
	public static void isScheduled(Git_Backup__c gb){
		if(gb.Frequency__c!=null && gb.Frequency__c!='None'){
			sched = true;
		}
	}
	public static void enforceScheduler(){
		if(sched)BatchHelper.enforceScheduler();
	}
}