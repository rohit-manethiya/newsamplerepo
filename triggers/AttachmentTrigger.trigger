trigger AttachmentTrigger on Attachment (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    try{
		TriggerFactory.createAndExecuteHandler(AttachmentTriggerHandler.class);   
    }
    catch(Exception e){
        System.debug('Error while Attachment Trigger: ' + e.getMessage() +' '+ e.getStackTraceString());
    }
}