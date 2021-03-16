public without sharing class ProjectTriggerHandler  implements ITrigger
{
    public ProjectTriggerHandler(){
    }
 
    public void bulkBefore(){
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
      
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        ProjectTriggerHelper.checkIndexMedadataChanged((Project__c)oldSo, (Project__c)so);        
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){    
        if(ProjectTriggerHelper.indexMedadataChangedFlag){
            ProjectTriggerHelper.runIndexMetadataJob();
        }   
    }
}