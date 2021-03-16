public with sharing class CMUtilities {

    public static Test_Script__c getTestScriptById(String recordId){
        if(Schema.SObjectType.Test_Script__c.isQueryable() && Schema.SObjectType.Test_Script__c.isAccessible()) {
            return [SELECT CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Introduction__c, LastModifiedById, LastModifiedDate, Overall_Outcome__c, OwnerId, Peer_Reviewer__c, Prerequisites__c, Project__c, Id, Sprint__c, Status__c, SystemModstamp, Test_Description__c, Name, Test_Title__c, User_Story__c FROM Test_Script__c WHERE Id = :recordId limit 1];
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForTestScript));
            return new Test_Script__c();
        }
    }
    public static List<Test_Script__c> getTestScripts(Set<Id> thisSet) {
        if(Schema.SObjectType.Test_Script__c.isQueryable() && Schema.SObjectType.Test_Script__c.isAccessible()) {
            return [SELECT CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Introduction__c, LastModifiedById, LastModifiedDate, Overall_Outcome__c, OwnerId, Peer_Reviewer__c, Prerequisites__c, Project__c, Id, Sprint__c, Status__c, SystemModstamp, Test_Description__c, Name, Test_Title__c, User_Story__c, (SELECT Action_Description__c, CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Guidance_notes__c, LastModifiedById, LastModifiedDate, Order__c, Id, Result__c, Name, Step_Title__c, SystemModstamp, Test_Script__c FROM Script_Steps__r) FROM Test_Script__c WHERE Id = :thisSet limit 1];
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForTestScript));
            return new List<Test_Script__c>();
        }
    }
    public static List<Test_Script_Step__c> getTestScriptStepsByTest(String testScriptId){
        if(Schema.SObjectType.Test_Script_Step__c.isQueryable() && Schema.SObjectType.Test_Script_Step__c.isAccessible()) {
            return [SELECT Action_Description__c, CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Guidance_notes__c, LastModifiedById, LastModifiedDate, Order__c, Id, Result__c, Name, Step_Title__c, SystemModstamp, Test_Script__c FROM Test_Script_Step__c WHERE Test_Script__c = :testScriptId order by Order__c ASC];
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForTestScriptStep));
            return new List<Test_Script_Step__c>();
        }
    }
    public static List<Test_Run__c> getTestRuns(Set<Id> thisSet){
        if(Schema.SObjectType.Test_Run__c.isQueryable() && Schema.SObjectType.Test_Run__c.isAccessible()) {
            return [SELECT Id, Name, Test_Script__c FROM Test_Run__c WHERE Id IN:thisSet];
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForTestRun));
            return new List<Test_Run__c>();
        }
    }
    public static List<Test_Run_Step__c> getTestRunStepsByTestRun(String testRunId){
        if(Schema.SObjectType.Test_Run_Step__c.isQueryable() && Schema.SObjectType.Test_Run_Step__c.isAccessible()){
            return Database.query('SELECT ' + checkDuplicateAndReturnQuery(SObjectType.Test_Run_Step__c.FieldSets.TestRunExecutionFieldSet.getFields(), 'Actual_Result__c,Action_Description__c,Expected_Result__c,Guidance_notes__c,Script_Step__c,Status__c,Test_Run__c') + ',Id, Name, Script_Step__r.Order__c, SystemModstamp, LastModifiedById, LastModifiedDate, CreatedById, CreatedDate, IsDeleted FROM Test_Run_Step__c WHERE Test_Run__c =:testRunId order by Script_Step__r.Order__c ASC');
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForTestRunStep));
            return new List<Test_Run_Step__c>();
        }
    }
    public static List<Deployment_Flow_Step__c> getFlowStepsByFlow(String parentId){
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            return [SELECT Id, Name, Source_Environment__c, Destination_Environment__c, Deployment_Flow__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :parentId];
        }
        else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.PermissionForDeploymentFlowStep));
            return new List<Deployment_Flow_Step__c>();
        }
    }

    public static String checkDuplicateAndReturnQuery(List<Schema.FieldSetMember> fieldSetMembers, String commaSeperatedStaticField){
        String ns = Settings.ns;
        Set<String> allFields = new Set<String>();
        for(Schema.FieldSetMember f : fieldSetMembers) {
            allFields.add(f.getFieldPath().toLowerCase());
        }
        for(String cStr:commaSeperatedStaticField.split(',')){
            allFields.add((ns + cStr).toLowerCase());
        }
        return String.join(new List<String>(allFields),',');
    }
}