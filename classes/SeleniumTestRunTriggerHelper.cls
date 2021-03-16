public without sharing class SeleniumTestRunTriggerHelper {
    public static boolean inTrigger = false;

    public static void updateGroups() {
        // check trigger flag to prevent concurrent updates with SeleniumTestGroupTriggerHelper.
        if (inTrigger)
            return;

        Set<Id> groupIds = new Set<Id>();
        if (Trigger.new != null)
            for (SObject so : Trigger.new) {
                Selenium_Test_Run__c tr = (Selenium_Test_Run__c) so;
                if (tr.Selenium_Test_Group__c != null)
                    groupIds.add(tr.Selenium_Test_Group__c);
            }
        if (Trigger.old != null)
            for (SObject so : Trigger.old) {
                Selenium_Test_Run__c tr = (Selenium_Test_Run__c) so;
                if (tr.Selenium_Test_Group__c != null)
                    groupIds.add(tr.Selenium_Test_Group__c);
            }
        Map<Id, String> existingGroupStatus = new Map<Id, String>();
        for (Selenium_Test_Group__c tg : [SELECT Id, Status__c FROM Selenium_Test_Group__c WHERE Id IN :groupIds])
            existingGroupStatus.put(tg.Id, tg.Status__c);

        Map<Id, String> newGroupStatus = new Map<Id, String>();
        for (Selenium_Test_Run__c tr : [
            SELECT Id, Last_Status__c, Selenium_Test_Group__c
            FROM Selenium_Test_Run__c
            WHERE Selenium_Test_Group__c IN :groupIds
        ]) {
            String id = tr.Selenium_Test_Group__c;
            String s = getGroupStatus(tr.Last_Status__c);
            if (newGroupStatus.get(id) == null) {
                newGroupStatus.put(id, s);
                continue;
            }
            if (s == 'In Progress')
                newGroupStatus.put(id, 'In Progress');
            if (newGroupStatus.get(id) == 'In Progress')
                continue;
            if (newGroupStatus.get(id) == 'Completed Successfully' && s == 'Completed with Errors')
                newGroupStatus.put(id, s);
        }
        List<Selenium_Test_Group__c> tobeUpdated = new List<Selenium_Test_Group__c>();
        for (Id id : newGroupStatus.keySet()) {
            if (newGroupStatus.get(id) != existingGroupStatus.get(id))
                tobeUpdated.add(new Selenium_Test_Group__c(Id = id, Status__c = newGroupStatus.get(id), Status_Date__c = System.now()));
        }
        // Try to update, but if there is a concurrency error ( UNABLE_TO_LOCK_ROW ), just ignore the change
        try {
            update tobeUpdated;
        } catch (System.DmlException dmlEx) {
            if (!dmlEx.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                throw dmlEx;
        }
        SeleniumTestGroupTriggerHelper.changedStatuses = new Map<String, String>();
        for (Selenium_Test_Group__c g : tobeUpdated) {
            SeleniumTestGroupTriggerHelper.changedStatuses.put(g.Id, g.Status__c);
        }
        SeleniumTestGroupTriggerHelper.sendCalloutsIfAny();

        inTrigger = false;
    }
    private static String getGroupStatus(String runStatus) {
        if (runStatus == 'Starting' || runStatus == 'Queued')
            return 'In Progress';
        if (runStatus == 'Provider Failure')
            return 'Completed with Errors';
        return runStatus;
    }
}