trigger UserStoryChangeEventTrigger on User_Story__ChangeEvent (after insert) {
    List<User_Story__ChangeEvent> changes = Trigger.new;
    Set<String> usceIds = new Set<String>();
    List<String> recordIds;
    //Get all record Ids for this change and add it to a set for further processing
    String commitUserId;
    for(User_Story__ChangeEvent usce :changes){
        if(usce.Promote_Change__c && !usce.Promote_and_Deploy__c){
            commitUserId = usce.ChangeEventHeader.getCommitUser();
            recordIds = usce.ChangeEventHeader.getRecordIds();
            usceIds.addAll(recordIds);
        }
    }

    if(usceIds.size() > 0){
        UserStoryChangeEventTriggerHandler.ccdCheckConnectionBehaviorAndPromote(usceIds, commitUserId, false, null);
    }
}