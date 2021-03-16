/**
 * Created by ferhatozsavran on 3/14/18.
 */

public with sharing class DXTestOrgIntermediaryController {

    private final Test_Run__c testRun;

    public DXTestOrgIntermediaryController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
        this.testRun = (Test_Run__c)stdController.getRecord();
    }

    public PageReference redirectPage(){
        if(String.isNotBlank(testRun.Name)){
            String orgName = testRun.Name + ' Scratch Org';
            List<Org__c> orgList = new List<Org__c>();
            if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
                orgList = [SELECT Id FROM Org__c WHERE Name = :orgName AND Org_Type__c = 'Scratch Org - Test Only' AND Scratch_Org_Status__c = 'Active' ORDER BY CreatedDate DESC LIMIT 1];
            }

            if(!orgList.isEmpty()){
                PageReference pRef = Page.DXOperation;
                pRef.getParameters().put('id',orgList.get(0).Id);
                pRef.setRedirect(true);
                return pRef;
            } else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Test_Run_Error));
                return null;
            }
        } else{
            return null;
        }
    }
}