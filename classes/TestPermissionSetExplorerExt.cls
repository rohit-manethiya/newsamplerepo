@isTest
public class TestPermissionSetExplorerExt {

	@testSetup 
    static void setupData() {
		createPermissionSets();
        insertUser();
	}
    
    @Future
    public static void insertUser() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //removed chatter dependency
        User futureUser = new User(firstname='Future', lastname='User',
            alias = 'future', 
            email = 'test@test.org',
            emailencodingkey = 'UTF-8', 
			languagelocalekey = 'en_US', 
            localesidkey = 'en_US', 
			profileid = prof.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'futureuser777@test-copado.org'
            );
        insert(futureUser);
    }
    
    @Future
    private static void createPermissionSets() {
        List<PermissionSet> permissionSetList = new List<PermissionSet>();
        permissionSetList.add(new PermissionSet( Name = 'UnitTest_A_CopadoTest', Label = 'UnitTest_A_CopadoTest') );
        permissionSetList.add(new PermissionSet( Name = 'UnitTest_B_CopadoTest', Label = 'UnitTest_B_CopadoTest') );
        permissionSetList.add(new PermissionSet( Name = 'UnitTest_C_CopadoTest', Label = 'UnitTest_C_CopadoTest') );
        insert permissionSetList;

        List<FieldPermissions> fieldPermissionList = new List<FieldPermissions>();
        fieldPermissionList.add(new FieldPermissions(Field='Account.Rating',ParentId=permissionSetList[0].Id,PermissionsEdit=false,PermissionsRead=true,SobjectType='Account'));
		fieldPermissionList.add(new FieldPermissions(Field='Account.Rating',ParentId=permissionSetList[1].Id,PermissionsEdit=true,PermissionsRead=true,SobjectType='Account'));
		insert fieldPermissionList;

		List<ObjectPermissions> objectPermissionsList = new List<ObjectPermissions>();
		objectPermissionsList.add(new ObjectPermissions(ParentId=permissionSetList[0].Id,PermissionsCreate=false,PermissionsDelete=false,PermissionsEdit=false,PermissionsModifyAllRecords=false,PermissionsRead=true,PermissionsViewAllRecords=false,SobjectType='Account'));
		objectPermissionsList.add(new ObjectPermissions(ParentId=permissionSetList[1].Id,PermissionsCreate=true,PermissionsDelete=false,PermissionsEdit=true,PermissionsModifyAllRecords=false,PermissionsRead=true,PermissionsViewAllRecords=false,SobjectType='Account'));
		insert objectPermissionsList;
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE username = 'futureuser777@test-copado.org'];
    }
    
    private static Persona__c createPersona(String recordName) {
        Persona__c persona = new Persona__c( Name = recordName );
        insert persona;
        return persona;
    }

    private static List<Persona_Permission__c> createPersonaPermissions(Id personaId, String permissions){
        List<Persona_Permission__c> personaPermissions = new List<Persona_Permission__c>();
        for(String permission : permissions.split(',')){
            personaPermissions.add(new Persona_Permission__c(Persona__c = personaId, Permission_Set_Name__c = permission));
        }
        insert personaPermissions;
        return personaPermissions;
    }

    static testMethod void testExplorer() {
		Persona__c releaseManager = createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissionsList = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        System.assertEquals(3, releaseManagerPermissionsList.size());
        User_Persona_Assignment__c userPersonaAssignment = new User_Persona_Assignment__c( Persona__c = releaseManager.Id, User__c = getTestUser().Id, Status__c = 'Draft');
        insert userPersonaAssignment;

		Test.startTest();
        PermissionSetExplorerExt pse = new PermissionSetExplorerExt();
        PermissionSetExplorerExt.PersonaId = releaseManager.Id;
        List<SelectOption> personas = pse.getPersonas();
		PermissionSetExplorerExt.LoadPermissions();
		Test.stopTest();
    }
    
    static testMethod void updatePersonaPermission() {
		Persona__c releaseManager = createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissionsList = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        System.assertEquals(3, releaseManagerPermissionsList.size());
        User_Persona_Assignment__c userPersonaAssignment = new User_Persona_Assignment__c( Persona__c = releaseManager.Id, User__c = getTestUser().Id, Status__c = 'Draft');
        insert userPersonaAssignment;

        Test.startTest();
        update releaseManagerPermissionsList;
        releaseManagerPermissionsList = [SELECT Id FROM Persona_Permission__c WHERE Persona__c = :releaseManager.Id];
        System.assertEquals(3, releaseManagerPermissionsList.size());
		Test.stopTest();
    }
    
    static testMethod void deletePersonaPermission() {
		Persona__c releaseManager = createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissionsList = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        System.assertEquals(3, releaseManagerPermissionsList.size());
        User_Persona_Assignment__c userPersonaAssignment = new User_Persona_Assignment__c( Persona__c = releaseManager.Id, User__c = getTestUser().Id, Status__c = 'Draft');
        insert userPersonaAssignment;

        Test.startTest();
        delete releaseManagerPermissionsList;
        releaseManagerPermissionsList = [SELECT Id FROM Persona_Permission__c WHERE Persona__c = :releaseManager.Id];
        System.assertEquals(0, releaseManagerPermissionsList.size());
		Test.stopTest();
    }
    
    static testMethod void undeletePersonaPermission() {
		Persona__c releaseManager = createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissionsList = createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        System.assertEquals(3, releaseManagerPermissionsList.size());
        User_Persona_Assignment__c userPersonaAssignment = new User_Persona_Assignment__c( Persona__c = releaseManager.Id, User__c = getTestUser().Id, Status__c = 'Draft');
        insert userPersonaAssignment;

        Test.startTest();
        delete releaseManagerPermissionsList;
        List<Persona_Permission__c> deletedReleaseManagerPermissionsList = [SELECT Id FROM Persona_Permission__c WHERE Persona__c = :releaseManager.Id];
        System.assertEquals(0, deletedReleaseManagerPermissionsList.size());

        undelete releaseManagerPermissionsList;
        releaseManagerPermissionsList = [SELECT Id FROM Persona_Permission__c WHERE Persona__c = :releaseManager.Id];
        System.assertEquals(3, releaseManagerPermissionsList.size());
		Test.stopTest();
	}
}