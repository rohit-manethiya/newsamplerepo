public class PersonaPermissionTriggerHelper {
	private static Set<Id> affectedPersonas = new Set<Id>();
    
    public static void prepareData(){
        affectedPersonas = new Set<Id>();
    }
    public static void setAffected(SObject so){
        Persona_Permission__c pp = (Persona_Permission__c)so;
        affectedPersonas.add(pp.Persona__c);
    }
    public static void callBatchRecalculation(){
        List<User_Persona_Assignment__c> upas = [select id, type__c from User_Persona_Assignment__c where status__c ='Permissions Assigned' and Persona__c in :affectedPersonas];
        for(User_Persona_Assignment__c upa:upas){
            upa.Status__c = 'Approved';
            if(upa.type__c == 'Temporary'){
                upa.Apply_Schedule__c = true;
            }
        }
        update upas;
    }
}