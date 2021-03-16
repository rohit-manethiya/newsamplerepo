trigger DeploymentFlowStepTrigger on Deployment_Flow_Step__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(DeploymentFlowStepTriggerHandler.class);
}