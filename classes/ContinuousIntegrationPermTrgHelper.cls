public with sharing class ContinuousIntegrationPermTrgHelper {

    public static List<Continuous_Integration_Permission__c> existingPermissions = new List<Continuous_Integration_Permission__c>();
    public static Map<Id,Set<String>> dupeChecker = new Map<Id,Set<String>>();

    public static List<Continuous_Integration__Share> sharing_inserts = new List<Continuous_Integration__Share>();
    public static List<Continuous_Integration__Share> sharing_updates = new List<Continuous_Integration__Share>();
    public static List<Continuous_Integration__Share> sharing_deletions = new List<Continuous_Integration__Share>();
    public static List<Continuous_Integration__Share> sharing_undeletions = new List<Continuous_Integration__Share>();

    public static Map<Id, Continuous_Integration__Share> sharingByUserId = new Map<Id, Continuous_Integration__Share>();
    public static Set<Id> ciIdSet = new Set<Id>();
    public static Map<Id,Continuous_Integration__c> ciMap = new Map<Id,Continuous_Integration__c>();
    

    public static void prepareData(List<SObject> records){
        sharing_inserts = new List<Continuous_Integration__Share>();
        sharing_updates = new List<Continuous_Integration__Share>();
        sharing_deletions = new List<Continuous_Integration__Share>();
        sharing_undeletions = new List<Continuous_Integration__Share>();
        sharingByUserId = new Map<Id, Continuous_Integration__Share>();
        ciMap = new Map<Id,Continuous_Integration__c>();
        ciIdSet = new Set<Id>();

        for(SObject o : records){
            Continuous_Integration_Permission__c cip = (Continuous_Integration_Permission__c)o;
            ciIdSet.add(cip.Continuous_Integration__c);
        }
        ciMap = new Map<Id,Continuous_Integration__c>([select Id, OwnerId from Continuous_Integration__c where Id IN:ciIdSet]);
        existingPermissions = [select Id, User__c, Continuous_Integration__c from Continuous_Integration_Permission__c where Continuous_Integration__c IN:ciIdSet];
        for(Continuous_Integration_Permission__c cip : existingPermissions){
            if(dupeChecker.get(cip.Continuous_Integration__c) == null)dupeChecker.put(cip.Continuous_Integration__c,new Set<String>());
            dupeChecker.get(cip.Continuous_Integration__c).add(cip.User__c);
        }
        List<Continuous_Integration__Share> sharings = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Continuous_Integration__Share WHERE ParentId IN:ciIdSet and RowCause!=:Schema.Continuous_Integration__Share.RowCause.Owner];
        for(Continuous_Integration__Share cis : sharings){
            sharingByUserId.put(cis.UserOrGroupId, cis);
        }
    }
    public static void createSharing(Continuous_Integration_Permission__c cip, boolean isUndelete){
        if(ciMap.containsKey(cip.Continuous_Integration__c) && ciMap.get(cip.Continuous_Integration__c).OwnerId==cip.User__c)return;
        Continuous_Integration__Share thisShare = new Continuous_Integration__Share();
        thisShare.AccessLevel = (cip.Access__c=='Read Only')?'Read':'Edit';
        thisShare.ParentId = cip.Continuous_Integration__c;
        thisShare.RowCause = Schema.Continuous_Integration__Share.RowCause.ContinuousIntegrationPermission__c;
        thisShare.UserOrGroupId = cip.User__c;
        sharing_inserts.add(thisShare);
    }
    public static void checkIfInsertAllowed(Continuous_Integration_Permission__c cip){
        if(dupeChecker.containsKey(cip.Continuous_Integration__c) && 
            dupeChecker.get(cip.Continuous_Integration__c).contains(cip.User__c)){
            cip.addError('You cannot create a duplicate permission. You must edit an existing one.');
        }
    }
    public static void checkIfUpdateAllowed(Continuous_Integration_Permission__c ocip, Continuous_Integration_Permission__c ncip){
        if(ocip.Access__c==ncip.Access__c)return;
        if(ciMap.get(ncip.Continuous_Integration__c).OwnerId==ocip.User__c&&ncip.Access__c!='Run Continuous Integration'){
            ncip.Access__c.addError('You cannot revoke permissions from the Continuous Integration record owner.');
        }
    }
    public static void checkIfDeleteAllowed(Continuous_Integration_Permission__c cip){
        if(ciMap.get(cip.Continuous_Integration__c).OwnerId==cip.User__c){
            cip.addError('The owner of the Continuous Integration record cannot be removed from the permissions list.');
        }
    }
    public static void updateSharing(Continuous_Integration_Permission__c ocip, Continuous_Integration_Permission__c ncip){
        if(ocip.Access__c==ncip.Access__c)return;
        ContinuousIntegrationPermTrgHelper.createSharing(ncip, false);
        ContinuousIntegrationPermTrgHelper.deleteSharing(ocip);
    }
    public static void deleteSharing(Continuous_Integration_Permission__c cip){
        Continuous_Integration__Share thisShare = sharingByUserId.get(cip.User__c);
        if(thisShare==null) return;
        for(Continuous_Integration__Share sh:sharing_deletions)if(sh.Id == thisShare.Id)return;
        sharing_deletions.add(thisShare);
    }
    public static void undeleteSharing(Continuous_Integration_Permission__c cip){
        createSharing(cip, true);
    }
}