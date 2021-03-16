global with sharing class TestBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
	
	
	global TestBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([select id, Name,Test_Frequency__c from Org__c where Test_Frequency__c in('Daily','Weekly','Monthly')]);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for(sObject os:scope){
			Org__c o = (Org__c)os;
			BatchHelper.doTest(o);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}