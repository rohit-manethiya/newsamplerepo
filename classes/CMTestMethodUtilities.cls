public with sharing class CMTestMethodUtilities {
	public static Project__c createProject(String s){
		Project__c x = new Project__c();
		x.Name = s;
		return x;
	}
	public static Sprint__c createSprint(String s){
		Sprint__c x = new Sprint__c();
		x.Name = s;
		return x;
	}
	public static User_Story__c createUserStory(String s){
		User_Story__c x = new User_Story__c();
		x.User_Story_Title__c = s;
		return x;
	}
	public static Test_Script__c createTestScript(String title){
		Test_Script__c x = new Test_Script__c();
		x.Test_Title__c = title;
		return x;
	}
	public static Test_Script_Step__c createTestScriptStep(Id scriptId, String title){
		Test_Script_Step__c x = new Test_Script_Step__c();
		x.Test_Script__c = scriptId;
		x.Step_Title__c = title;
		return x;
	}
	public static Test_Run__c createTestRun(Id scriptId){
		Test_Run__c x = new Test_Run__c();
		x.Test_Script__c = scriptId;
		return x;	
	}
	public static Test_Run_Step__c createTestRunStep(Id runId, Id stepId){
		Test_Run_Step__c x = new Test_Run_Step__c();
		x.Test_Run__c = runId;
		x.Script_Step__c = stepId;
		return x;	
	}
	public static Release__c createRelease(String s){
		Release__c x = new Release__c();
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createFlow(String s){
		Deployment_Flow__c x = new Deployment_Flow__c();
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createCCMFlow(String s, Boolean a){
		Deployment_Flow__c x = new Deployment_Flow__c();
        x.Active__c = a;
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createCBMFlow(String s, Boolean a, Id repoId, String b){
		Deployment_Flow__c x = new Deployment_Flow__c();
        x.Active__c = a;
        x.Git_Repository__c = repoId;
        x.Main_Branch__c = b;
		x.Name = s;
		return x;
	}
	public static Deployment_Flow_Step__c createFlowStep(Id sourceEnvId, Id destEnvId, Id flowId){
		Deployment_Flow_Step__c x = new Deployment_Flow_Step__c();
        x.Source_Environment__c = sourceEnvId;
        x.Destination_Environment__c = destEnvId;
		x.Deployment_Flow__c = flowId;
		return x;
	}
	public static Promotion__c createPromotion(Id projectId, Id sourceEnvId){
		Promotion__c x = new Promotion__c();
		x.Project__c = projectId;
        x.Source_Environment__c = sourceEnvId;
		return x;
	}
	public static Promotion__c createBackPromotion(Id projectId, Id destinationEnvId){
		Promotion__c x = new Promotion__c();
		x.Project__c = projectId;
        x.Destination_Environment__c = destinationEnvId;
        x.Back_Promotion__c = true;
		return x;
	}
    public static Environment__c createEnvironment(String name, String orgId){
        Environment__c x = new Environment__c();
        x.Name = name;
        x.org_id__c = orgId;
        return x;
    }
	public static boolean hasMessage(String s){
        boolean b = false;
        for(ApexPages.Message msg : ApexPages.getMessages()){
            if(msg.getDetail().contains(s)) b = true;
        }
        return b;
    }
	public static Org__c createOrg(String name, String orgType, String sfdcorgid, String token, String un, DateTime vd, Id envId){
		Org__c x = new Org__c();
		x.name = name;
		x.Org_Type__c = orgType;
		x.SFDC_Org_ID__c = sfdcorgid;
		x.Token__c = token;
		x.Username__c = un;
		x.Validated_Date__c = vd;
		x.Environment__c = envId;
		return x;
	}

    public static Connection_Behavior__c createConnectionBehavior(String connectionBehavior, String promotionSchedule){
        return createConnectionBehavior(connectionBehavior, promotionSchedule, null);
    }

	public static Connection_Behavior__c createConnectionBehavior(String connectionBehavior, String promotionSchedule, String staticCodeAnalysisId){
		Connection_Behavior__c testCCD = new Connection_Behavior__c(
				Name = 'CCD',
				Promotion_Behavior__c = connectionBehavior,
				Back_Promotion_Behavior__c = connectionBehavior
		);
		if(String.isNotBlank(promotionSchedule)){
			testCCD.Promotion_Schedule__c = promotionSchedule;
			testCCD.Back_Promotion_Schedule__c = promotionSchedule;
		}
		insert testCCD;

        Metadata_Group__c mgApex = new Metadata_Group__c(
                Name = 'apex test'
        );

        Metadata_Group__c mgCompliance = new Metadata_Group__c(
                Name = 'compliance'
        );

        Metadata_Group__c mgSelenium = new Metadata_Group__c(
                Name = 'selenium test'
        );

        Metadata_Group__c mgStatic = new Metadata_Group__c(
                Name = 'static analysis'
        );

        List<Metadata_Group__c> mgList = new List<Metadata_Group__c>{
                mgApex,
                mgCompliance,
                mgSelenium,
                mgStatic
        };
        insert mgList;

        Metadata_Group_Item__c mgiApex1 = new Metadata_Group_Item__c(
                Type__c = 'ApexClass',
                Operator__c = 'All',
                Value__c = '',
                Metadata_Group__c = mgApex.Id
        );

        Metadata_Group_Item__c mgiCompliance1 = new Metadata_Group_Item__c(
                Type__c = 'ApexClass',
                Operator__c = 'Contains',
                Value__c = 'Delete',
                Metadata_Group__c = mgCompliance.Id
        );

        Metadata_Group_Item__c mgiCompliance2 = new Metadata_Group_Item__c(
                Type__c = 'ApexTrigger',
                Operator__c = 'Contains',
                Value__c = 'Promotion',
                Metadata_Group__c = mgCompliance.Id
        );

        Metadata_Group_Item__c mgiSelenium1 = new Metadata_Group_Item__c(
                Type__c = 'ApexClass',
                Operator__c = 'All',
                Value__c = '',
                Metadata_Group__c = mgSelenium.Id
        );

        Metadata_Group_Item__c mgiStatic1 = new Metadata_Group_Item__c(
                Type__c = 'ApexClass',
                Operator__c = 'All',
                Value__c = '',
                Metadata_Group__c = mgStatic.Id
        );

        List<Metadata_Group_Item__c> mgiList = new List<Metadata_Group_Item__c>{
                mgiApex1,
                mgiCompliance1,
                mgiCompliance2,
                mgiSelenium1,
                mgiStatic1
        };
        insert mgiList;

		Quality_Gate__c qgApex = new Quality_Gate__c(
				Name = 'apex test',
				Type__c = 'Apex Test with Validation',
				Connection_Behavior__c = testCCD.Id,
                Test_Level__c = 'No Test Run',
                Metadata_Group__c = mgApex.Id
		);

		Quality_Gate__c qgCompliance = new Quality_Gate__c(
				Name = 'compliance',
				Type__c = 'Compliance Check',
				Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgCompliance.Id
		);

		Quality_Gate__c qgSeleniumTest = new Quality_Gate__c(
				Name = 'selenium Test',
				Type__c = 'Selenium Test',
				Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgSelenium.Id
		);

		Quality_Gate__c qgStaticAnalysis = new Quality_Gate__c(
				Name = 'static Analysis',
				Type__c = 'Static Code Analysis',
				Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgStatic.Id
		);

        Quality_Gate__c qgURLCallout = new Quality_Gate__c(
                Name = 'URL Callout',
                Type__c = 'URL Callout',
                Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgStatic.Id
        );

        if(null != staticCodeAnalysisId){
            qgStaticAnalysis.Static_Code_Analysis_Settings__c = staticCodeAnalysisId;
        }

        Quality_Gate__c qgManualApproval = new Quality_Gate__c(
                Name = 'static Analysis',
                Type__c = 'Manual Approval',
                Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgStatic.Id
        );

        Quality_Gate__c qgPullRequest = new Quality_Gate__c(
                Name = 'static Analysis',
                Type__c = 'Pull Request',
                Connection_Behavior__c = testCCD.Id,
                Metadata_Group__c = mgStatic.Id
        );

		List<Quality_Gate__c> qaList = new List<Quality_Gate__c>{
				qgApex,
				qgCompliance,
				qgSeleniumTest,
				qgStaticAnalysis,
                qgManualApproval,
                qgPullRequest,
                qgURLCallout
		};
		insert qaList;



		return testCCD;
	}
    public static void enableSelenium(){
        try{
            testMethodUtilities.enableSelenium();
        }catch(DMLexception e) {
            System.debug('Avoid UNABLE_TO_LOCK_ROW exceptions, due to concurrent updates to custom settings');
        }
    }
    public static void addNamespaceSetting(String value) {
    	List<Settings__c> settings = [SELECT Namespace__c FROM Settings__c Where Namespace__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Namespace__c != value) {
					s.Namespace__c = value;
					Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
				}
			}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Namespace__c = value), Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
    	}
    }
    public static void addServerURLSetting(String value) {
    	List<Settings__c> settings = [SELECT Server_URL__c FROM Settings__c Where Server_URL__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Server_URL__c != value) {
	    			s.Server_Url__c = value;
	    			Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
	    		}
	    	}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Server_URL__c = value), Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
    	}
    }
    public static void enabledMultiLicenses(Boolean value) {
    	List<Settings__c> settings = [SELECT Enabled_Multi_Licenses__c FROM Settings__c Where Enabled_Multi_Licenses__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Enabled_Multi_Licenses__c != value) {
	    			s.Enabled_Multi_Licenses__c = value;
	    			Utilities.Secure_DML(s, Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
	    		}
	    	}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Enabled_Multi_Licenses__c = value), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
    	}
    }
}