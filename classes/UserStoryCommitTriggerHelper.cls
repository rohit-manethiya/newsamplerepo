public without sharing class UserStoryCommitTriggerHelper {
    public static Map<String, String> cmMap = new Map<String, String>();
    public static Map<String, String> usMap = new Map<String, String>();
    public static Map<Id, Git_Org_Commit__c> completedOrgCommits = new Map<Id, Git_Org_Commit__c>();
    public static Map<Id, User_Story__c> usToUpdate = new Map<Id, User_Story__c>();
    public static Map<Id, User_Story__c> committedUs = new Map<Id, User_Story__c>();

    public static void prepareData() {
        if(Trigger.isInsert) {
            for(SObject so : Trigger.new) {
                User_Story_Commit__c uc = (User_Story_Commit__c) so;
                cmMap.put(uc.Snapshot_Commit__c, null);
                usMap.put(uc.User_Story__c, null);
            }
            for(Git_Org_Commit__c goc : [SELECT Id,Commit_Id__c,Status__c,Commit_Date__c FROM Git_Org_Commit__c WHERE Id IN:cmMap.keySet()]) {
                cmMap.put(goc.Id, goc.Commit_Id__c);
                completedOrgCommits.put(goc.Id, goc); //Completed commits
            }
            for(User_Story__c us : [SELECT Id,Name,Latest_Commit_Date__c FROM User_Story__c WHERE Id IN:usMap.keySet()]) {
                usMap.put(us.Id, us.Name);
                committedUs.put(us.Id, us);
            }
        }
    }

    public static void setNewDefaults(User_Story_Commit__c usc) {
        if(!(usMap.get(usc.User_Story__c) != null && cmMap.get(usc.Snapshot_Commit__c) != null && cmMap.get(usc.Snapshot_Commit__c).length() > 30)) {
            return;
        }
        usc.Name = usMap.get(usc.User_Story__c) + ' ' + cmMap.get(usc.Snapshot_Commit__c).substring(0, 7);
        usc.External_Id__c = usc.User_Story__c + '_' + cmMap.get(usc.Snapshot_Commit__c);
    }

    /**
     * Populate or override Latest commit date on the US layout.
     * @param newsObject Map<Id,SObject>
     */
    public static void prepareLatestCommitDateData(Map<Id, SObject> newsObject) {
        for(SObject usc : newsObject.values()) {
            if(completedOrgCommits.containsKey(((User_Story_Commit__c) usc).Snapshot_Commit__c)) {
                Git_Org_Commit__c goc = completedOrgCommits.get(((User_Story_Commit__c) usc).Snapshot_Commit__c);
                if(String.isNotBlank(goc.Status__c) && goc.Status__c == 'Complete') {
                    Datetime commitDate = goc.Commit_Date__c;
                    for(User_Story__c us : committedUs.values()) {
                        if(us.Latest_Commit_Date__c == null || us.Latest_Commit_Date__c < commitDate) {
                            us.Latest_Commit_Date__c = commitDate;
                            usToUpdate.put(us.Id, us);
                        }
                    }
                }
            }
        }
    }

    /**
     * DML operation will done under this method
     */
    public static void dmlOperations() {
        if(usToUpdate != null && !usToUpdate.values().isEmpty()) {
            Utilities.Secure_DML(usToUpdate.values(), Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        }
    }
}