public class webhookLookupController {
	public AuxiliaryObject__c lookupAux {get;set;}
    public Settings settings {get;set;}
    public String branch {get;set;}

    public webhookLookupController(){
        lookupAux = new AuxiliaryObject__c();
        settings = new Settings();
    }
}