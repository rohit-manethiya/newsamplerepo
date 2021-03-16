global with sharing class PermissionSchedulable implements Schedulable{
    private Id upaId;
    private String status;
    public PermissionSchedulable(Id pUpaId, String pStatus){
        this.upaId = pUpaId;
        this.status = pStatus;
    }
    global void execute(SchedulableContext sc) {
        System.debug('Scheduling ' + upaId + ' Status: ' + status);
        User_Persona_Assignment__c upa = new User_Persona_Assignment__c(Id=this.upaId, Status__c=status, Apply_Schedule__c =true);
        Utilities.Secure_DML(upa, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Persona_Assignment__c);
    }
}