public with sharing class cloneDeploymentExtension{

    public final Deployment__c dep{get;set;}
    public boolean clone_steps {get;set;}
    public boolean clone_destOrgs {get;set;}
    
    public cloneDeploymentExtension(ApexPages.StandardController stdController) {
        dep = [SELECT id,name, from_org__c FROM Deployment__c WHERE id = :stdController.getId()];
        clone_steps = false;
        clone_destOrgs = false;
    }
    public PageReference cancel(){
    	return new PageReference('/'+dep.Id);
    }
    public PageReference doClone(){
        try{
            Set<Id> oldparentIds = new Set<Id>();
            Map<Id,Id> idMap = new Map<Id,Id>();
            Deployment__c clonedDep = dep.clone();
            if(!Schema.SObjectType.Deployment__c.fields.status__c.isCreateable() || !Schema.SObjectType.Deployment__c.fields.Schedule__c.isCreateable() || !Schema.SObjectType.Deployment__c.fields.name.isCreateable() || !Schema.SObjectType.Deployment__c.fields.Deployment_command_sent__c.isCreateable()){
                return null;
            }
            clonedDep.status__c = 'Draft';
            clonedDep.Schedule__c = null;
            clonedDep.name = 'Copy of '+ dep.name;
            clonedDep.Deployment_command_sent__c = null;
            Utilities.Secure_DML(clonedDep, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment__c);
            System.debug('##### INSERTED: '+ clonedDep);
            
            if(clone_steps){
            	System.debug('######## ENTERED CLONE STEPS ######');
	            List<Step__c> newSteps = new List<Step__c>();
	            List<Step__c> oldSteps = Utilities.getStepsByDeploymentId(dep.Id);
	            for(Step__c s : oldSteps){
	            	System.debug('######## LOOOOOPING STEP ######');
					Step__c newStep = s.clone();
                    if(!Schema.SObjectType.Step__c.fields.deployment__c.isCreateable() || !Schema.SObjectType.Step__c.fields.status__c.isCreateable()){
                        return null;
                    }
					newStep.deployment__c = clonedDep.Id;
                    newStep.status__c='Not started';
					newSteps.add(newStep);
					oldparentIds.add(s.Id);
	            }
	            System.debug('######## INSERT STEPS ######');
                Utilities.Secure_DML(newSteps, Utilities.DML_Action.INS, schema.Sobjecttype.Step__c);
	            for(Integer i=0; i < oldSteps.size(); i++){
	            	idMap.put(oldSteps[i].Id, newSteps[i].Id);
	            }
            }
            
            if(clone_destOrgs){
            	System.debug('######## ENTERED CLONE DEST ORGS ######');
            	List<Destination_Org__c> newDestOrgs = new List<Destination_Org__c>();
	            List<Destination_Org__c> oldDestOrgs = Utilities.getDestinationOrgsByDeploymentId(dep.Id);
	            for(Destination_Org__c o : oldDestOrgs){
	            	System.debug('######## LOOOOOPING DEST ORG ######');
	            	Destination_Org__c newDO = o.clone();
                    if(!Schema.SObjectType.Destination_Org__c.fields.deployment__c.isCreateable() || !Schema.SObjectType.Destination_Org__c.fields.status__c.isCreateable()){
                        return null;
                    }
	            	newDO.deployment__c = clonedDep.Id;
                    newDO.status__c='Not started';
	            	newDestOrgs.add(newDO);
	            	oldparentIds.add(o.Id);
	            }
	            System.debug('######## INSERT DEST ORGS ######');
                Utilities.Secure_DML(newDestOrgs, Utilities.DML_Action.INS, schema.Sobjecttype.Destination_Org__c);

            	for(Integer i=0; i < oldDestOrgs.size(); i++){
	            	idMap.put(oldDestOrgs[i].Id, newDestOrgs[i].Id);
	            }
            }
			
            List<Attachment> newAtts = new List<Attachment>();
            List<Attachment> atts = new List<Attachment>();
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()){
                atts = [SELECT Id, Body, Name, ContentType, IsPrivate, ParentId FROM Attachment WHERE ParentId IN :oldparentIds];
            }
            System.debug('######## ATT SIZE: '+atts.size());
            for(Attachment a : atts){
            	System.debug('######## LOOOOOPING ATTACHMENT ######');
                Attachment newAtt = a.clone();
                newAtt.parentId = idMap.get(a.parentId);
                newAtts.add(newAtt);
            }
            System.debug('######## INSERT ATTACHMENTS ######');
            Utilities.Secure_DML(newAtts, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
            return new PageReference('/'+clonedDep.Id);
        }
        catch(Exception ex){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ''+ex));
        	return null;
        }
    }
}