@isTest
public class TestPersonaAssignmentTrigger {
    @testSetup 
    static void setupData() {
		createPermissionSets();
        insertUser();
	}
    
    static testMethod void runAssignmentTest(){
        Persona__c releaseManager =  createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissions = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        
        User_Persona_Assignment__c ppa = new User_Persona_Assignment__c(Persona__c=releaseManager.Id, User__c=getTestUser().Id, Status__c='Draft');
        insert ppa;
        
        Test.startTest();
        
        System.runAs(getTestUser()){
            ppa.Status__c = 'Approved';
        	update ppa;
        }
        Test.stopTest();
        
        List<PermissionSet> perms = [select Id, Name from PermissionSet where name like 'UnitTest_%' and createddate = today];
        Map<Id, PermissionSet> permMap = new Map<Id, PermissionSet>();
        for(PermissionSet p : perms){ 
            permMap.put(p.Id, p); 
        }
        List<PermissionSetAssignment> result = [select Id, PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permMap.keySet()];
        system.assertEquals(3, result.size());
    }
    
    static testMethod void runRevokalTest(){
        Persona__c releaseManager =  createPersona('Test2 Release Manager');
        List<Persona_Permission__c> releaseManagerPermissions = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        
        User_Persona_Assignment__c ppa = new User_Persona_Assignment__c(Persona__c=releaseManager.Id, User__c=getTestUser().Id, Status__c='Approved');
        insert ppa;
        
        Test.startTest();
        
        System.runAs(getTestUser()){
            ppa.Status__c = 'Revoked';
        	update ppa;
        }
        Test.stopTest();
        
        List<PermissionSet> perms = [select Id, Name from PermissionSet where name like 'UnitTest_%' and createddate = today];
        Map<Id, PermissionSet> permMap = new Map<Id, PermissionSet>();
        for(PermissionSet p : perms){ 
            permMap.put(p.Id, p); 
        }
        List<PermissionSetAssignment> result = [select Id, PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permMap.keySet()];
        system.assertEquals(0, result.size());
    }
    static testMethod void runRevokalByDeletionTest(){
        Persona__c releaseManager =  createPersona('Test2 Release Manager');
        List<Persona_Permission__c> releaseManagerPermissions = createPersonaPermissions(releaseManager.Id, 'DUnitTest_A_CopadoTest,DUnitTest_B_CopadoTest,DUnitTest_C_CopadoTest');
        
        User_Persona_Assignment__c ppa = new User_Persona_Assignment__c(Persona__c=releaseManager.Id, User__c=getTestUser().Id, Status__c='Approved');
        insert ppa;
        Test.startTest();
        
        System.runAs(getTestUser()){
            ppa.Status__c = 'Approved';
        	update ppa;
        }
        delete releaseManager;
        Test.stopTest();
        
        List<PermissionSet> perms = [select Id, Name from PermissionSet where name like 'DUnitTest_%' and createddate = today];
        Map<Id, PermissionSet> permMap = new Map<Id, PermissionSet>();
        for(PermissionSet p : perms){ 
            permMap.put(p.Id, p); 
        }
        List<PermissionSetAssignment> result = [select Id, PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permMap.keySet()];
        system.assertEquals(0, result.size());
    }
    static testMethod void runAssignmentTestTemporary(){
        Persona__c releaseManager =  createPersona('Test Release Manager 3');
        List<Persona_Permission__c> releaseManagerPermissions = createPersonaPermissions(releaseManager.Id, 'CUnitTest_A_CopadoTest,CUnitTest_B_CopadoTest,CUnitTest_C_CopadoTest');
        
        User_Persona_Assignment__c ppa = new User_Persona_Assignment__c(Persona__c=releaseManager.Id, User__c=getTestUser().Id, Status__c='Draft', Type__c='Temporary', Start_Time__c=Datetime.now()+1, End_Time__c=Datetime.now()+2);
        insert ppa;
        
        Test.startTest();
        
        System.runAs(getTestUser()){
            ppa.Status__c = 'Approved';
        	update ppa;
        }
        Test.stopTest();
        
        List<PermissionSet> perms = [select Id, Name from PermissionSet where name like 'CUnitTest_%' and createddate = today];
        Map<Id, PermissionSet> permMap = new Map<Id, PermissionSet>();
        for(PermissionSet p : perms){ 
            permMap.put(p.Id, p); 
        }
        List<PermissionSetAssignment> result = [select Id, PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permMap.keySet()];
        system.assertEquals(0, result.size());
        
        ppa = [select start_schedule_id__c, end_schedule_id__c from User_Persona_Assignment__c where id=:ppa.id];
        system.assert(ppa.start_schedule_id__c!=null);
        system.assert(ppa.end_schedule_id__c!=null);
    }
    
    private static User getTestUser(){
        return [select Id from User where username ='futureuser777@test-copado.org'];
    }
    @Future
    public static void insertUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //removed chatter dependency
        User futureUser = new User(firstname = 'Future', lastname = 'User',
            alias = 'future', 
            email = 'test@test.org',
            emailencodingkey = 'UTF-8', 
			languagelocalekey='en_US', 
            localesidkey='en_US', 
			profileid = p.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'futureuser777@test-copado.org'
            );
        insert(futureUser);
    }
    
    @Future
    private static void createPermissionSets(){
        List<PermissionSet> perms = new List<PermissionSet>();
        perms.add(new PermissionSet(Name='UnitTest_A_CopadoTest', Label='UnitTest_A_CopadoTest'));
        perms.add(new PermissionSet(Name='UnitTest_B_CopadoTest', Label='UnitTest_B_CopadoTest'));
        perms.add(new PermissionSet(Name='UnitTest_C_CopadoTest', Label='UnitTest_C_CopadoTest'));
        System.debug('inserting Permission sets: ' + perms);
        insert perms;
    }
    private static Persona__c createPersona(String n){
        Persona__c x = new Persona__c(Name=n);
        insert x;
        return x;
    }
    private static List<Persona_Permission__c> createPersonaPermissions(Id personaId, String perms){
        List<Persona_Permission__c> pps = new List<Persona_Permission__c>();
        for(String s : perms.split(',')){
            pps.add(new Persona_Permission__c(Persona__c=personaId, Permission_Set_Name__c=s));
        }
        insert pps;
        return pps;
    }
}