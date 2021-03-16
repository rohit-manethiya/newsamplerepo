public class PersonaTriggerHelper {
	private static Set<Id> affectedPersonas = new Set<Id>();
    
    public static void prepareData(){
        affectedPersonas = new Set<Id>();
    }
    public static void setAffected(SObject so){
        affectedPersonas.add(so.Id);
    }
    public static void callBatchDelete(){
        Utilities.Secure_DML([select id from Persona_Permission__c where Persona__c in :affectedPersonas], Utilities.DML_Action.DEL, schema.Sobjecttype.Persona_Permission__c);
    }
}