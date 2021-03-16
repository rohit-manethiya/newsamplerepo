public without sharing class ApexTestResultTriggerHelper {
	public static Map<Id, Org__c> orgMap = new Map<Id, Org__c>();
	public static void updateOrgLastTestStatus(Apex_Test_Result__c atr){
		Org__c org = new Org__c();
        org.id = atr.Org__c;
        org.Last_Apex_Tests_Datetime__c = atr.createdDate; 
        org.Last_Apex_Tests_Status__c = (atr.Status__c == 'Success')?'OK':'Error';
        orgMap.put(atr.Org__c, org);
	}
}