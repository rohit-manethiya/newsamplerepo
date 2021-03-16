public class SeleniumTestGroupTriggerHelper {
    public static Map<String,String> changedStatuses = null;
    public static Map<Id, Set<Id>> orgMap {get;set;}

    public static void prepareData(){
        // remove the groups from the trigger list that are manually managed
        Map<Id,Selenium_Test_Group__c> groups = ((Map<Id,Selenium_Test_Group__c>)Trigger.newMap).clone();
        for(Id groupId : groups.keySet() )
            if(groups.get(groupId).Manage_Test_Runs_manually__c)
                groups.remove(groupId);
        if(groups.size()==0)
        return;

        // detach ALL test runs from its group, in case an org or suite was removed from the group
        List<Selenium_Test_Run__c> existing = [select Id from Selenium_Test_Run__c where Selenium_Test_Group__c in :Trigger.newmap.keyset() and External_ID__c !=null];
        for(Selenium_Test_Run__c tr:existing)
            tr.Selenium_Test_Group__c = null;
        Utilities.Secure_DML(existing, Utilities.DML_Action.UPD, schema.Sobjecttype.Selenium_Test_Run__c);

        // now create/update every test run for this group.
        List<Selenium_Test_Run__c> current = new List<Selenium_Test_Run__c>();
        for (Selenium_Test_Group__c g:[select Id,Name, Selenium_Settings__c, Selenium_Settings__r.Name, (select Id, Org_Credential__c, Org_Credential__r.Name from Selenium_Group_Org_Credentials__r),
                                       (select Id, Selenium_Test_Suite__c, Selenium_Test_Suite__r.Name from Selenium_Group_Test_Suites__r)
                                       from Selenium_Test_Group__c where Id in:Trigger.newmap.keyset()]){
           	//prepare records to be upserted
			for(Selenium_Group_Org_Credential__c goc: g.Selenium_Group_Org_Credentials__r){
                for(Selenium_Group_Test_Suite__c gts: g.Selenium_Group_Test_Suites__r){
                    Selenium_Test_Run__c tr = new Selenium_Test_Run__c();
                    tr.Name = (g.Name + '-' + goc.Org_Credential__r.Name + '-' + gts.Selenium_Test_Suite__r.Name).left(80);
                    tr.Org_Credential__c = goc.Org_Credential__c;
                    tr.Selenium_Settings__c = g.Selenium_Settings__c;
                    tr.Selenium_Test_Suite__c = gts.Selenium_Test_Suite__c;
                    tr.Selenium_Test_Group__c = g.Id;
                    tr.External_ID__c = g.Id+'_'+gts.Selenium_Test_Suite__c+'_'+goc.Org_Credential__c;
                    current.add(tr);
                }
			}
        }
        SeleniumTestRunTriggerHelper.inTrigger = true;
        Utilities.Secure_DML(current, Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Test_Run__c, schema.sObjectType.Selenium_Test_Run__c.fields.External_ID__c);
    }
    public static void prepareDataBefore() {
        // get all Group Org Credentials
        orgMap = new Map<Id, Set<Id>>(); // SeleniumTestGroup.Id, Set<Environment.Id>
        if(Trigger.newmap != null) {
            for(Selenium_Group_Org_Credential__c sgOC : [SELECT Org_Credential__r.Environment__c, Selenium_Test_Group__c FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c IN :Trigger.newmap.keyset()]) {
                if(sgOC.Org_Credential__r.Environment__c != null) {
                    if(orgMap.get(sgOC.Selenium_Test_Group__c) != null) {
                        if(!orgMap.get(sgOC.Selenium_Test_Group__c).contains(sgOC.Org_Credential__r.Environment__c)) {
                            orgMap.get(sgOC.Selenium_Test_Group__c).add(sgOC.Org_Credential__r.Environment__c);
                        }
                    } else {
                        orgMap.put(sgOC.Selenium_Test_Group__c, new Set<Id>{sgOC.Org_Credential__r.Environment__c});
                    }
                }
            }
        }
    }
    public static void isValidGroupType(Selenium_Test_Group__c stg) {
        System.debug('#stgId: '+stg.Id);
        if(orgMap.get(stg.Id) != null && stg.Environment__c != null) {
            for(Id envId: orgMap.get(stg.Id)) {
                if(envId != stg.Environment__c)stg.addError(Label.ENV_NOT_MATCHING);
            }
        }
    }
    public static void checkStatusChanged(Selenium_Test_Group__c o, Selenium_Test_Group__c n){
        System.debug('*** Name old: ' + o.Name + ' new: ' + n.Name);
        System.debug('*** Id old: ' + o.Id + ' new: ' + n.Id);
        System.debug('*** Status old: ' + o.Status__c + ' new: ' + n.Status__c);
        if(o.Status__c!=n.Status__c){
            if(changedStatuses == null)changedStatuses = new Map<String,String>();
            System.debug('Status changed: ' + n.Id + ' ' + n.Status__c);
            changedStatuses.put(n.Id, n.Status__c);
        }
    }
    public static void sendCalloutsIfAny(){
        if(changedStatuses==null || changedStatuses.size() ==0)return;
        System.debug('Sending callouts: ' + changedStatuses.size());
        sendCallouts(changedStatuses);
    }
    public class JobException extends Exception{}
    @Future(callout=true)
    public static void sendCallouts(Map<String,String> statuses){
        String api_key = DeployAPI.getUserAPIKey();
        if(String.isBlank(api_key)){
            throw new JobException('No API Key for user ' + UserInfo.getUserId() + ' ' + UserInfo.getUserName());
        }
        for(String groupId:statuses.keyset()){
            String status = statuses.get(groupId);
            System.debug('*** groupId: ' + groupId + ' status: ' + status);
            if(!Test.isRunningTest()) {
	            WebhookAPI.setGroupJobStatus(groupId, status , api_key);
            }
        }
    }
}