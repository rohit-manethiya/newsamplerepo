public with sharing class ConnectionBehaviorUsageInfoController {
    public Integer totalRelation { get; private set; }

    public ConnectionBehaviorUsageInfoController(ApexPages.StandardController stdController) {
        if(String.isNotBlank(stdController.getId())) {
            Id recordId = stdController.getId();
            SecureOperations so = new SecureOperations(DatabaseOperationType.OPTIONAL, DatabaseOperationType.WITHOUTSHARING);
            List<AggregateResult> environments = (List<AggregateResult>) so.getProperAuthorization().executeQuery('SELECT count(Id) envCount FROM Environment__c WHERE Connection_Behavior__c = \'' + recordId + '\'');
            List<AggregateResult> flowStepList = (List<AggregateResult>) so.getProperAuthorization().executeQuery('SELECT count(Id) dfsCount FROM Deployment_Flow_Step__c WHERE Connection_Behavior_Override__c = \'' + recordId + '\'');
            totalRelation = ((Integer) environments.get(0).get('envCount')) + ((Integer) flowStepList.get(0).get('dfsCount'));
        }
    }
}