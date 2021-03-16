public without sharing class GitOrgCommitTriggerHelper {
    public static Map<Id, Org__c> orgMap = new Map<Id, Org__c>();
    public static void updateOrgLastCommit(Git_Org_Commit__c goc) {
        Org__c org = new Org__c();
        org.Id = goc.Org__c;
        org.Last_Git_Backup_Datetime__c = goc.CreatedDate;
        org.Last_Git_Backup_Status__c = 'OK';
        orgMap.put(goc.Org__c, org);
    }
    public static void setCommitDate(Git_Org_Commit__c goc) {
        if(goc.Commit_Date__c == null && !String.isBlank(goc.Commit_Id__c)) {
            goc.Commit_Date__c = System.now();
        }
    }

    public static void updateOrgCredentialLastBackup() {
        Utilities.Secure_DML(orgMap.values(), Utilities.DML_Action.UPD, SObjectType.Org__c);
    }
}