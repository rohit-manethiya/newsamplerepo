public with sharing class BuildTaskTriggerHelper {
	public static Map<Id, List<Continuous_Integration_Permission__c>> ciPermissions = new Map<Id, List<Continuous_Integration_Permission__c>>();

	public static List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
	public static EmailTemplate emailTemplate;
	public static Map<Id, User> userMap = new Map<Id, User>();
	public static Set<Id> ciIds = new Set<Id>();
	public static Map<Id, Continuous_Integration__c> ciMap = new Map<Id, Continuous_Integration__c>();
	public static Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
    public static Set<Id> calloutIds = new Set<Id>();
    
	public static void prepareData(List<SObject> records){
		emails = new List<Messaging.SingleEmailMessage>();
		userMap = new Map<Id, User>();
		ciIds = new Set<Id>();
		ciMap = new Map<Id, Continuous_Integration__c>();
        emailTemplateMap = new Map<String, EmailTemplate>();
		Set<Id> uIds = new Set<Id>();
		for(SObject so : records){
			Build_Task__c bt = (Build_Task__c)so;
			ciIds.add(bt.Continuous_Integration__c);
		}
		List<Continuous_Integration_Permission__c> cips = [select Id, User__c, Email_Notification__c, Email_Template_Name__c, Continuous_Integration__c from Continuous_Integration_Permission__c where Continuous_Integration__c IN:ciIds];
		
		system.debug('### cips: '+cips.size());
        Set<String> tmpEmailNames = new Set<String>();
		for(Continuous_Integration_Permission__c cip : cips){
			system.debug('### Iterating CIPS ....: '+cip+' Email_Notification__c:'+cip.Email_Notification__c);
            tmpEmailNames.add(cip.Email_Template_Name__c);
            emailTemplateMap.put(cip.Email_Template_Name__c, new EmailTemplate());
			List<Continuous_Integration_Permission__c> tmp = ciPermissions.get(cip.Continuous_Integration__c);
			if(tmp==null)tmp = new List<Continuous_Integration_Permission__c>();
			tmp.add(cip);
			system.debug('### tmp ....: '+tmp.size()+' just added:'+cip.Id);
			ciPermissions.put(cip.Continuous_Integration__c, tmp);
			uIds.add(cip.User__c);
		}

		userMap = new Map<Id, User>([select Id, Email from User where Id IN:uIds]); 
        for(EmailTemplate et : [select Id, Name from EmailTemplate where Name IN :tmpEmailNames]){
            emailTemplateMap.put(et.Name, et);
        }
		
		system.debug('############################');
		system.debug('### userMap: '+userMap);
		system.debug('### Email templates: '+emailTemplateMap.keySet());
		system.debug('### ciPermissions: '+ ciPermissions);
	}
	public static void setLatestInformationOn_CI(Build_Task__c oldBt, Build_Task__c bt){
		if(Trigger.isBefore){
			if(bt.Status__c == 'In Progress' && (oldBt==null || oldBt.Status__c !='In Progress')){
			bt.Start_Time__c = System.now();
			}
			if(oldBt!=null && (bt.Status__c == 'Failed' || bt.Status__c == 'Success') && oldBt.Status__c =='In Progress'){
				bt.Duration__c = (System.now().getTime() - (bt.Start_Time__c!=null?bt.Start_Time__c:bt.createdDate).getTime())/1000;
			}
		}
		ciMap.put(bt.Continuous_Integration__c, new Continuous_Integration__c(Id = bt.Continuous_Integration__c, Last_Build_Task_Duration__c = bt.Duration__c, Status__c = bt.Status__c));
	}
	public static void addUserToEmailList(Build_Task__c oldBt, Build_Task__c bt){
		system.debug('### Before-After Status: '+oldBt.Status__c+'-'+bt.Status__c);
		if(oldBt.Status__c==bt.Status__c)return;
		system.debug('Entering addUserToEmailList: '+bt);
		List<Continuous_Integration_Permission__c> cips = ciPermissions.get(bt.Continuous_Integration__c);
		Set<Id> userIds = new Set<Id>();
		for(Continuous_Integration_Permission__c cip : cips){
			boolean notifyUser = notifyUser(bt, cip);
			system.debug('### notifyUser: '+ notifyUser);
			if(notifyUser && !userIds.contains(cip.User__c)){
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				//email.setToAddresses(new String[] { userMap.get(cip.User__c).Email });
			    email.setTargetObjectId(cip.User__c);
			    email.setWhatId(bt.Id);
			    email.setTemplateId(emailTemplateMap.get(cip.Email_Template_Name__c).Id);
			    email.setSaveAsActivity(false);
			    emails.add(email);
			    userIds.add(cip.User__c);
			    System.debug('**** ADD EMAIL: ' + bt.Status__c + ' - ' + bt.Type__c + ' - ' + cip.Email_Notification__c + ' - size: ' + emails.size());
			}
		}
	}
	public static void sendEmails(){
		system.debug('### Emails about to send: '+emails.size());
		try{
			Messaging.sendEmail(emails);
		}
		catch(EmailException ee){
			system.debug(LoggingLevel.ERROR, ''+ee.getMessage());
		}
	}
	private static boolean notifyUser(Build_Task__c bt, Continuous_Integration_Permission__c cip){
		if(cip.Email_Notification__c==null)return false;
		system.debug('### btType:'+ bt.Type__c+' bt.Status__c:'+bt.Status__c+' cip.Email_Notification__c:'+cip.Email_Notification__c);
		if(bt.Type__c=='Validate'){
			if(bt.Status__c=='Failed' && cip.Email_Notification__c.contains('On Build Failure'))return true;
			if(bt.Status__c=='Success' && cip.Email_Notification__c.contains('On Build Success'))return true;
		}
		if(bt.Type__c=='Deploy'){
			if(bt.Status__c=='Failed' && cip.Email_Notification__c.contains('On Deploy Failure'))return true;
			if(bt.Status__c=='Success' && cip.Email_Notification__c.contains('On Deploy Success'))return true;
		}
		return false;
	}
    public static void prepareBuildTaskCallouts(List<SObject> records){
        List<Build_Task__c> bts = new List<Build_Task__c>();
        for(Build_Task__c bt:[select Id, Status__c, Continuous_Integration__c from Build_Task__c where
                              Continuous_Integration__c in :ciIds and Status__c in('Queued','In Progress') and
                             LastModifiedDate >= yesterday and 
                              (Continuous_Integration__r.Pre_Deployment_Jobs__c!=null or
                              Continuous_Integration__r.Post_Success_Deployment_Jobs__c!=null or
                              Continuous_Integration__r.Post_Failed_Deployment_Jobs__c!=null)
                              ORDER BY Name limit 500]){ //JG: Name is incremental(AutoNumber), CreatedDate will be the same if elements are inserted in bulk
            bts.add(bt);
        }
        Set<Id> CIinProgress = new Set<Id>();
        for(Build_Task__c bt:bts){
            if(bt.Status__c=='In Progress')CIinProgress.add(bt.Continuous_Integration__c);
        }
        System.debug('@test-queue. CIinProgress: ' + CIinProgress);
        Set<Id> CItoBeStarted = new Set<Id>();
        calloutIds = new Set<Id>();
        for(Build_Task__c bt:bts){
            if(bt.Status__c=='Queued' && !CItoBeStarted.contains(bt.Continuous_Integration__c)
              && !CIinProgress.contains(bt.Continuous_Integration__c)){
                CItoBeStarted.add(bt.Continuous_Integration__c);
                calloutIds.add(bt.Id);
                System.debug('@test-queue. CItoBeStarted: ' + CItoBeStarted);
                System.debug('@test-queue. calloutIds: ' + calloutIds);
            }
        }
    }
    public static void doBuildTaskCallouts(){
        if(calloutIds.size()>0){
            System.debug('@test-queue. deploying: ' + calloutIds);
            if(!Test.isRunningTest())DeployAPI.deployBuildTask(calloutIds, UserInfo.getSessionId());
        }
    }
}