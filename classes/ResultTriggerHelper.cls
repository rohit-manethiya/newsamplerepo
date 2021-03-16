public with sharing class ResultTriggerHelper {
    private static Map<Id, String> statusByResultIds { get; set; }
    public ResultTriggerHelper() {
    }

    public static void prepareData(List<SObject> records) {
        statusByResultIds = new Map<Id, String>();
        for (SObject so : records) {
            Result__c resultRecord = (Result__c) so;
            if (resultRecord.Status__c == 'Success' || resultRecord.Status__c == 'Failed') {
                statusByResultIds.put(resultRecord.Id, resultRecord.Status__c);
            }
        }
    }

    public static void updateDeploymentJobStatus() {
        List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>(
            [
                SELECT Id, Step__c, Status__c, Last_Result__c
                FROM Deployment_Job__c
                WHERE Last_Result__c IN :statusByResultIds.keyset()
                WITH SECURITY_ENFORCED
            ]
        );

        if (!deploymentJobs.isEmpty()) {
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                deploymentJob.Status__c = statusByResultIds.get(deploymentJob.Last_Result__c);
            }

            Utilities.Secure_DML(deploymentJobs, Utilities.DML_Action.UPD, Schema.Sobjecttype.Deployment_Job__c);
        }
    }
}