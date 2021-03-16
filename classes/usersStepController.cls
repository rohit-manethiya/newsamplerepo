public with sharing class usersStepController {
    public Step__c dummy;

    public Step__c getDummy(){ return dummy;}
    public void setDummy(Step__c e){}

    public usersStepController(){
        dummy = new Step__c();
    }
}