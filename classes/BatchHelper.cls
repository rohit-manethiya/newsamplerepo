public class BatchHelper {
	public static boolean isCopadoScheduled(){
		return [select id from CronJobDetail where Name ='Copado' and JobType='7' limit 1].size()>0;
	}
	public static void scheduleCopado(){
		String sch = '0 '+Utilities.randomInteger(0,59)+' '+Utilities.randomInteger(0,4)+' 1/1 * ? *';
		Scheduler t = new Scheduler();
		system.schedule('Copado', sch, t);
	}
	public static boolean abortCopadoScheduled(){
		Id jid=null;
		try{
			Id did = [select id from CronJobDetail where Name ='Copado' and JobType='7' limit 1].Id;
			jid = [select id from CronTrigger where CronJobDetailId = :did].Id;
			System.abortJob(jid);
			return true;
		} 
		catch(Exception e){
			System.debug('*** could not abortJob '+ jid);
		}
		return false;
	}
	public static void doTest(Org__c org){
		try{
			if(org.Test_Frequency__c=='Daily')DeployAPI.testNow(org.Id);
			if(org.Test_Frequency__c=='Weekly' && Datetime.now().format('E').contains('Mon'))DeployAPI.testNow(org.Id);
			if(org.Test_Frequency__c=='Monthly' && Datetime.now().format('d')=='1')DeployAPI.testNow(org.Id);	
		}
		catch(Exception e){
			String subject = '[Copado] Scheduled Apex Test failure';
			String body = 'Apex Test for Org "'+org.Name+'" failed with message: ' + e.getMessage();
			Utilities.sendEmail(UserInfo.getUserEmail(), subject, body);
		}
	}
	public static void doBackup(Git_Backup__c bkup){
		try{
			if(bkup.Frequency__c=='Daily')DeployAPI.backupNow(bkup.Id);
			if(bkup.Frequency__c=='Weekly' && Datetime.now().format('E').contains('Mon'))DeployAPI.backupNow(bkup.Id);
			if(bkup.Frequency__c=='Monthly' && Datetime.now().format('d')=='1')DeployAPI.backupNow(bkup.Id);
		}
		catch(Exception e){
			String subject = '[Copado] Scheduled Git Backup failure';
			String body = 'Git Backup "'+bkup.Name+'" failed with message: '+e.getMessage();
			Utilities.sendEmail(UserInfo.getUserEmail(), subject, body);
		}
	}
	public static void enforceScheduler(){
		if(!isCopadoScheduled())scheduleCopado();
	}
}