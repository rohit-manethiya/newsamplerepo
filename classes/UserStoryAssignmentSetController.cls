public with sharing class UserStoryAssignmentSetController {
	public List<User_Story__c> records {get;set;}
	public User_Story__c dummy {get;set;}
	public apexpages.standardsetcontroller con;
	
	public UserStoryAssignmentSetController(apexpages.standardsetcontroller std){
		con = std;
		records = (List<User_Story__c>)std.getSelected();
		dummy = new User_Story__c();
	}
	public PageReference cancel(){
		return con.cancel();
	}
	public PageReference assign(){
		List<User_Story__c> updates = new List<User_Story__c>(); 
		for (User_Story__c us : records){
			us.Release__c=dummy.Release__c;
			updates.add(us);
		}
		if(updates.size()>0){
			Utilities.Secure_DML(updates, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
		}
		else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one record'));//Label.SELECT_AT_LEAST_ONE_RECORD
			return null;
		}
		return new PageReference('/' + dummy.Release__c);
	}
}