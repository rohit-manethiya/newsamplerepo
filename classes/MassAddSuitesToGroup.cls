public with sharing class MassAddSuitesToGroup {
	public List<Selenium_Test_Suite__c> suites;
	public AuxiliaryObject__c dummy {get;set;}
	public apexpages.standardsetcontroller con;
	public MassAddSuitesToGroup(apexpages.standardsetcontroller std){
		con = std;
		suites = (List<Selenium_Test_Suite__c>)std.getSelected();
		dummy = new AuxiliaryObject__c ();
	}
	public PageReference cancel(){
		return con.cancel();
	}
	public PageReference add(){
		List<Selenium_Group_Test_Suite__c> dos = new List<Selenium_Group_Test_Suite__c>();
        if(!Schema.sObjectType.Selenium_Group_Test_Suite__c.fields.Selenium_Test_Group__c.isCreateable() && !Schema.sObjectType.Selenium_Group_Test_Suite__c.fields.Selenium_Test_Suite__c.isCreateable()){
            return null;
        }
		for (Selenium_Test_Suite__c o: suites){
			dos.add(new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = dummy.Selenium_Test_Group__c, Selenium_Test_Suite__c = o.id));
		}
		if(dos.size()>0){
			Database.SaveResult[] res = null;
			if(Schema.sObjectType.Selenium_Group_Test_Suite__c.isCreateable()){
				res = Database.insert(dos, false);
			}
            boolean err = false;
            for(Database.SaveResult r:res){
                if(!r.isSuccess()){
                    err = true;
                    apexpages.addMessage(new Apexpages.Message(apexpages.severity.error, r.getErrors()[0].getMessage()));
                }
            }
            if(err)return null;
		}
		else{
			apexpages.addMessage(new Apexpages.Message(apexpages.severity.error, Label.SELECT_AT_LEAST_ONE_RECORD));
			return null;
		}
		return new PageReference('/' + dummy.Selenium_Test_Group__c);
	}
}