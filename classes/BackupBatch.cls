global with sharing class BackupBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
	
	global BackupBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([select id, Name, frequency__c from Git_Backup__c where frequency__c in ('Daily','Weekly','Monthly')]);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for(sObject os:scope){
			Git_Backup__c b = (Git_Backup__c)os;
			BatchHelper.doBackup(b);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}