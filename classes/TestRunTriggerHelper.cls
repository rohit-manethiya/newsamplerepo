public without sharing class TestRunTriggerHelper {
    public static Set<Id> testScriptIds;
    public static Map<Id, Test_Script__c> testScriptMap;
    
    public static void prepareData(List<SObject> records){
        testScriptIds = new Set<Id>();
        for(SObject o : records){
			Test_Run__c tr = (Test_Run__c)o;
			testScriptIds.add(tr.Test_Script__c);
		}
        testScriptMap = new Map<Id, Test_Script__c>([select Id, Project__c, Sprint__c, User_Story__c, User_Story__r.Project__c, User_Story__r.Sprint__c from Test_Script__c where Id IN :testScriptIds]);
    }
    
	public static void insertTestRunSteps(){
        if(Trigger.isInsert){
            List<Test_Run_Step__c> testRunSteps = new List<Test_Run_Step__c>();
            List<Test_Run__c> testRuns = CMUtilities.getTestRuns(Trigger.newMap.keySet());
            List<Test_Script__c> testScripts = CMUtilities.getTestScripts(testScriptIds);
            Map<Id, List<Test_Script_Step__c>> mapSteps = new Map<Id, List<Test_Script_Step__c>>();
            for(Test_Script__c ts : testScripts){
                mapSteps.put(ts.Id, ts.Script_Steps__r);
            }
            
            for(Test_Run__c tr : testRuns){
                List<Test_Script_Step__c> tmp = mapSteps.get(tr.Test_Script__c);
                if(tmp!=null){
                    for(Test_Script_Step__c r : tmp){
                        Test_Run_Step__c trs = new Test_Run_Step__c();
                        trs.Script_Step__c = r.Id;
                        trs.Test_Run__c = tr.Id;
                        testRunSteps.add(trs);
                    }
                }
            }
            Utilities.Secure_DML(testRunSteps, Utilities.DML_Action.INS, schema.Sobjecttype.Test_Run_Step__c);
        }
	}
    public static void updateTestRunInformation(SObject so){
        if(testScriptMap.size() > 0){
            Test_Run__c tr = (Test_Run__c)so;
            Test_Script__c ts = testScriptMap.get(tr.Test_Script__c);
            if(tr.User_Story__c == null)tr.User_Story__c = ts.User_Story__c;
            if(tr.Project__c == null)tr.Project__c = ts.User_Story__r.Project__c;
            if(tr.Sprint__c == null)tr.Sprint__c = ts.User_Story__r.Sprint__c;
        }
    }
}