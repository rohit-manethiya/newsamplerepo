public with sharing class ContinuousIntegrationPermTrgHandler implements ITrigger{
 
    public ContinuousIntegrationPermTrgHandler(){
    }
 
    public void bulkBefore(){
        if(Trigger.new !=null)ContinuousIntegrationPermTrgHelper.prepareData(Trigger.new);
        if(Trigger.old !=null && Trigger.isDelete)ContinuousIntegrationPermTrgHelper.prepareData(Trigger.old);
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
        ContinuousIntegrationPermTrgHelper.checkIfInsertAllowed((Continuous_Integration_Permission__c)so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        ContinuousIntegrationPermTrgHelper.checkIfUpdateAllowed((Continuous_Integration_Permission__c)oldSo, (Continuous_Integration_Permission__c)so);
    }
    public void beforeDelete(SObject so){
        ContinuousIntegrationPermTrgHelper.checkIfDeleteAllowed((Continuous_Integration_Permission__c)so);
    }
 
    public void afterInsert(SObject so){
    	ContinuousIntegrationPermTrgHelper.createSharing((Continuous_Integration_Permission__c)so, false);
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    	ContinuousIntegrationPermTrgHelper.updateSharing((Continuous_Integration_Permission__c)oldSo, (Continuous_Integration_Permission__c)so);
    }
 
    public void afterDelete(SObject so){
    	ContinuousIntegrationPermTrgHelper.deleteSharing((Continuous_Integration_Permission__c)so);
    }

    public void afterUndelete(SObject so){
        //ContinuousIntegrationPermTrgHelper.undeleteSharing((Continuous_Integration_Permission__c)so);
    }
    public void andFinally(){
    	if(ContinuousIntegrationPermTrgHelper.sharing_deletions!=null)delete ContinuousIntegrationPermTrgHelper.sharing_deletions;
        if(ContinuousIntegrationPermTrgHelper.sharing_inserts!=null)upsert ContinuousIntegrationPermTrgHelper.sharing_inserts;
    	if(ContinuousIntegrationPermTrgHelper.sharing_updates!=null)update ContinuousIntegrationPermTrgHelper.sharing_updates;
        //if(ContinuousIntegrationPermTrgHelper.sharing_undeletions!=null)undelete ContinuousIntegrationPermTrgHelper.sharing_undeletions;
    }
}