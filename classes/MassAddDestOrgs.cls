public with sharing class MassAddDestOrgs {
	public List<Org__c> orgs;
	public Step__c dummy {get;set;}
	public apexpages.standardsetcontroller con;
	public MassAddDestOrgs(apexpages.standardsetcontroller std){
		con = std;
		orgs = (List<Org__c>)std.getSelected();
		dummy = new Step__c();
	}
	public PageReference cancel(){
		return con.cancel();
	}
	public PageReference add(){
		List<Destination_Org__c> dos = new List<Destination_Org__c>(); 
		for (Org__c o: orgs){
			dos.add(new Destination_Org__c(deployment__c = dummy.deployment__c, To_Org__c = o.id));
		}
		if(dos.size()>0){
			Utilities.Secure_DML(dos, Utilities.DML_Action.INS, schema.Sobjecttype.Destination_Org__c);
		}
		else{
			apexpages.addMessage(new Apexpages.Message(apexpages.severity.error, Label.SELECT_AT_LEAST_ONE_RECORD));
			return null;
		}
		return new PageReference('/' + dummy.deployment__c);
	}
}