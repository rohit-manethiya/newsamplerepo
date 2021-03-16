@IsTest
private class TestManageEnvVarsExt {
    @TestSetup static void setupTestData(){
        TestUtilities.getAllMultilicense();
    }
    static void setupTestDataDML(){
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        testMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void testEnvironmentalVars() {
        setupTestDataDML();
        Git_Repository__c gr = new Git_Repository__c(Name = 'Manage Env Vars Test');
        insert gr;
        
        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name = 'Manage Env Vars Test', Active__c = true, Main_Branch__c = 'master', Git_Repository__c = gr.Id);
        insert df;
        
        List<Deployment_Flow_Step__c> Ldfs = new List<Deployment_Flow_Step__c>();
        
        for (Integer i=1;i<5;i++) {
            Deployment_Flow_Step__c dfs = new Deployment_Flow_Step__c(
                Deployment_Flow__c = df.Id, 
                Branch__c = 'Env' + String.valueOf(i-1),
            	Source_Environment__c = Le[i-1].Id,
                Destination_Environment__c = Le[i].Id
            );
       		Ldfs.add(dfs);
        }
        insert Ldfs;
        
        Continuous_Integration__c ci = new Continuous_Integration__c(
        									Name = 'CI Env Vars Test',
            								Branch__c = 'Env0',
            								Git_Repository__c = gr.Id,
            								Destination_Org_Credential__c = Lo[5].Id
        									);
            
		insert ci; 
        
        Environmental_Variable__c ev = new Environmental_Variable__c(Name = 'Constructor test', Environment__c = Le[0].Id);
        ev.Value__c = 'testValue';
        insert ev;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(df);
        ManageEnvVarsExt meve = new ManageEnvVarsExt(sc);
        meve.createMissingVars();
        List<Environmental_Variable__c> Lev = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name FROM Environmental_Variable__c WHERE Name = 'Constructor test'];
        System.assertEquals(1, Lev.size());
        List<ManageEnvVarsExt.ManagedEnvVars> Lmev = meve.getEnvVars(Lev);
        System.assertEquals(1, Lmev.size());
        System.assertEquals(1, Lmev[0].managedEnvVarList.size());
        meve.newEnvVarName = 'NEW_VAR_TEXT';
        meve.newVar();
        Lmev = meve.getEnvVars(Lev);
        System.assertEquals(1, Lmev.size());
        System.assertEquals(1, Lmev[0].managedEnvVarList.size());
        meve.newEnvVarName = 'NEW_VAR_TEXT';
        meve.newVar();
        meve.deleteVarName = 'NEW_VAR_TEXT';
        meve.doDelete();
        Lmev = meve.getEnvVars(Lev);
        System.assertEquals(1, Lmev.size());
        System.assertEquals(1, Lmev[0].managedEnvVarList.size());
        Lmev[0].managedEnvVarList[0].Value__c = 'FAKE_VAL';
        meve.save();
		List<String> LenvNames = meve.getEnvNames();
		System.assertEquals(7, LenvNames.size());
		meve.cancel();
        meve.editModeOn();
        Test.stopTest();
        
    }
}