/**
 * This controller was created in order to have a Picklist field with its values
 * onto a Visualforce Component, since Component's don't accept standardController
 */
public with sharing class ManualTaskComponentController {

    public Deployment_Task__c task {get;set;}

    public ManualTaskComponentController() {
        task = new Deployment_Task__c();
    }
}