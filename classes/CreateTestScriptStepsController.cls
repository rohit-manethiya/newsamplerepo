public with sharing class CreateTestScriptStepsController {
    public Test_Script__c testScript {get;set;}
    public String testScriptId {get;set;}
    public List<stepRow> scriptSteps {get;set;}
    public Integer rowCount {get;set;}
    public Test_Script_Step__c dummyStep {get;set;}
    public Settings settings {get;set;}
    
    public CreateTestScriptStepsController(){
        try{
            testScriptId = ApexPages.currentPage().getParameters().get('tId');
            testScript = CMUtilities.getTestScriptById(testScriptId);
        } catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ''+e.getMessage()));
            return;
        }
        settings = new Settings();
        getSteps();
        dummyStep = new Test_Script_Step__c();
    }
    public PageReference returnToTestScript(){
        addRow();
        return new PageReference('/'+testScriptId);
    }
    public void addRow(){
        if(!String.isBlank(dummyStep.Action_Description__c) || !String.isBlank(dummyStep.Expected_Result__c) || !String.isBlank(dummyStep.Guidance_notes__c)){
            scriptSteps = new List<stepRow>();
            if(!Schema.SObjectType.Test_Script_Step__c.fields.Test_Script__c.isCreateable() || !Schema.SObjectType.Test_Script_Step__c.fields.Order__c.isCreateable()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights));
                return;
            }
            dummyStep.Test_Script__c = testScriptId;
            dummyStep.Order__c = rowCount+1;
            Utilities.Secure_DML(dummyStep, Utilities.DML_Action.INS, schema.SObjectType.Test_Script_Step__c);
            dummyStep = new Test_Script_Step__c();
            scriptSteps = getSteps();
        }
    }
    public List<stepRow> getSteps(){
        scriptSteps = new List<stepRow>();
        rowCount = 0;
        List<Test_Script_Step__c> tmp = new List<Test_Script_Step__c>();
        tmp = CMUtilities.getTestScriptStepsByTest(testScriptId);
        if(tmp == null){
            return null;
        }
        for(Test_Script_Step__c s : tmp){
            scriptSteps.add(new stepRow(s));
            rowCount++;
        }
        return scriptSteps;
    }
        
    public class stepRow {
        public Test_Script_Step__c step {get;set;}
        public stepRow(Test_Script_Step__c s){
            step = s;
        }
        public void saveStep(){
            try{
                Utilities.Secure_DML(step, Utilities.DML_Action.UPD, schema.SObjectType.Test_Script_Step__c);
            }
            catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ''+e.getMessage()));
            }
        }
        public void deleteStep(){
            Utilities.Secure_DML(step, Utilities.DML_Action.DEL, schema.SObjectType.Test_Script_Step__c);
        }
    }
}