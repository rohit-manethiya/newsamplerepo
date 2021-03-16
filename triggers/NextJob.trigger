trigger NextJob on Deployment_Job__c(before update, after update) {
    List<Id> deploymentJobIds = new List<Id>();
    final String ON_PROMISE_ID = 'copado-deployer-service-async-id';
    final String PENDING = 'Pending';
    final String IN_PROGRESS = 'In Progress';
    final String SUCCESS = 'Success';
    final String FAILED = 'Failed';
    final String CANCELLED = 'Cancelled';
    final String MANUAL_TASK = 'Manual Task';
    final String COMPLETED = 'Completed';
    final String SF_FLOW = 'Salesforce Flow';
    final String URL_CALLOUT = 'URL Callout';
    final String CCD_VALIDATION = 'CCD Validation';
    final String AUTOMATION = 'Automation';

    Map<Id, String> deploymentId_depJobAsyncJobIdMap = new Map<Id, String>();

    // Since backend is deploying one by one, each time one deployment job is triggered so to be able to collect all information we need to do 2 SOQL, one for to get the deployment Id to get all deployment job under that deployment
    String deploymentId = [SELECT Id, Step__r.Deployment__c FROM Deployment_Job__c WHERE Id IN :Trigger.newMap.keySet() LIMIT 1]
    .Step__r.Deployment__c;

    Map<Id, Deployment_Job__c> deploymentJobsByIds = new Map<Id, Deployment_Job__c>();

    List<Deployment_Job__c> deploymentJobRecordsInOrder = new List<Deployment_Job__c>(
        [
            SELECT
                Id,
                Step__c,
                Status__c,
                Last_Result__c,
                Destination_Org__c,
                Destination_Org__r.Status__c,
                Destination_Org__r.To_Org__c,
                Destination_Org__r.To_Org__r.Environment__r.Org_ID__c,
                Validation_ID__c,
                Async_Job_ID__c,
                Step__r.Type__c,
                Step__r.Status__c,
                Step__r.Order__c,
                Step__r.dataJson__c,
                Step__r.Deployment__c,
                Step__r.Deployment__r.Name,
                Step__r.Deployment__r.Status__c,
                Step__r.Deployment__r.From_Org__c,
                Step__r.Deployment__r.Promotion__c,
                Step__r.Deployment__r.From_Org__r.Environment__r.Org_ID__c,
                Step__r.Name,
                Step__r.CheckOnly__c
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deploymentId
            ORDER BY Destination_Org__c, Step__r.Order__c
        ]
    );

    for (Deployment_Job__c deploymentJobRecord : deploymentJobRecordsInOrder) {
        deploymentJobsByIds.put(deploymentJobRecord.Id, deploymentJobRecord);
    }

    if (Trigger.isAfter) {
        List<Deployment_Job__c> deploymentJobsToUpdate = new List<Deployment_Job__c>();
        List<Deployment_Job__c> automationJobsToUpdate = new List<Deployment_Job__c>();
        Map<String, Deployment_Job__c> deploymentJobsByOrders = new Map<String, Deployment_Job__c>();

        for (Deployment_Job__c depJobItem : deploymentJobsByIds.values()) {
            String key = depJobItem.Destination_Org__c + depJobItem.Status__c + String.valueOf(depJobItem.Step__r.Order__c);
            if (!deploymentJobsByOrders.containsKey(key)) {
                deploymentJobsByOrders.put(key, depJobItem);
            }

            if (
                depJobItem.Step__r.Type__c == AUTOMATION &&
                depJobItem.Status__c == IN_PROGRESS &&
                depJobItem.Last_Result__c == null &&
                String.isNotBlank(depJobItem.Step__r.dataJson__c)
            ) {
                AutomationTemplateExecuter.StepAttachmentDetails existingJson = (AutomationTemplateExecuter.StepAttachmentDetails) JSON.deserialize(
                    depJobItem.Step__r.dataJson__c,
                    AutomationTemplateExecuter.StepAttachmentDetails.class
                );

                // NOTE: there is DML, SOQL and callout inside for loop, but since we run every step one by one, it is kinda ok. It will always run one time.
                List<Result__c> results = AutomationTemplateExecuter.execute(
                    existingJson.automationId,
                    depJobItem.Step__r.Deployment__r.From_Org__c,
                    depJobItem.Destination_Org__r.To_Org__c,
                    true
                );
                if (!results.isEmpty()) {
                    if (String.isNotBlank(results[0].Error_Message__c)) {
                        depJobItem.Status__c = FAILED;
                    }
                    if (String.isNotBlank(results[0].Id)) {
                        depJobItem.Last_Result__c = results[0].Id;
                    }
                    automationJobsToUpdate.add(new Deployment_Job__c(Id = depJobItem.Id, Status__c = FAILED, Last_Result__c = results[0].Id));
                }
            }
        }

        for (Integer i = 0; i < Trigger.newMap.keySet().size(); i++) {
            Deployment_Job__c depJobItem = deploymentJobsByIds.get(Trigger.new[i].Id);
            if (
                depJobItem.Validation_ID__c != ON_PROMISE_ID &&
                depJobItem.Step__r.Order__c == 1 &&
                depJobItem.Step__r.Name == CCD_VALIDATION &&
                String.isNotBlank(Trigger.new[i].Validation_ID__c) &&
                Trigger.old[i].Validation_ID__c != Trigger.new[i].Validation_ID__c &&
                depJobItem.Step__r.Type__c != URL_CALLOUT &&
                !depJobItem.Step__r.CheckOnly__c
            ) {
                depJobItem.Async_Job_ID__c = depJobItem.Validation_ID__c;
                deploymentJobsToUpdate.add(depJobItem);
            }
        }

        List<Deployment__c> updateDeployments = new List<Deployment__c>();
        Map<Id, List<Deployment_Job__c>> deploymenJobsByDeploymentIds = new Map<Id, List<Deployment_Job__c>>();

        for (Deployment_Job__c deploymentJobRecord : Trigger.new) {
            Deployment_Job__c currentJob = deploymentJobsByIds.get(deploymentJobRecord.Id);
            if (
                deploymentJobRecord.Status__c == SUCCESS &&
                Trigger.oldMap.get(deploymentJobRecord.Id).Status__c != SUCCESS ||
                deploymentJobRecord.Status__c == FAILED &&
                Trigger.oldMap.get(deploymentJobRecord.Id).Status__c != FAILED ||
                deploymentJobRecord.Status__c == CANCELLED &&
                Trigger.oldMap.get(deploymentJobRecord.Id).Status__c != CANCELLED
            ) {
                Deployment_Job__c nextDeploymentJob;
                //we DON'T try to deploy all the steps even if some fails
                if (deploymentJobRecord.Status__c == SUCCESS && Trigger.oldMap.get(deploymentJobRecord.Id).Status__c != SUCCESS) {
                    Integer nextOrder = Integer.valueOf(currentJob.Step__r.Order__c) + 1;
                    // First, we try to fire next step if there is another with the same order value than the current one
                    // otherwise we look for the next step with the next order value
                    String currentOrderKey = deploymentJobRecord.Destination_Org__c + PENDING + currentJob.Step__r.Order__c;
                    String nextOrderKey = deploymentJobRecord.Destination_Org__c + PENDING + String.valueOf(nextOrder);
                    if (deploymentJobsByOrders.containsKey(currentOrderKey)) {
                        nextDeploymentJob = deploymentJobsByOrders.get(currentOrderKey);
                    } else if (deploymentJobsByOrders.containsKey(nextOrderKey)) {
                        nextDeploymentJob = deploymentJobsByOrders.get(nextOrderKey);
                    }
                }

                if (nextDeploymentJob != null) {
                    //Prevent Manual Tasks, Salesforce Flow and Automation template from calling backend
                    if (
                        nextDeploymentJob.Step__r.Type__c != MANUAL_TASK &&
                        nextDeploymentJob.Step__r.Type__c != SF_FLOW &&
                        nextDeploymentJob.Step__r.Type__c != AUTOMATION
                    ) {
                        deploymentJobIds.add(nextDeploymentJob.Id);
                    } else {
                        nextDeploymentJob.Status__c = IN_PROGRESS;
                        deploymentJobsToUpdate.add(nextDeploymentJob);
                    }
                }
            }
            //Bulkified
            if (deploymentJobRecord.Status__c == IN_PROGRESS && currentJob.Step__r.Deployment__r.Status__c != IN_PROGRESS) {
                Boolean isPaused = false;
                if (
                    currentJob.Step__r.Order__c == 1 &&
                    currentJob.Step__r.Type__c == MANUAL_TASK &&
                    !currentJob.Step__r.Status__c.containsIgnoreCase(COMPLETED)
                ) {
                    isPaused = true;
                }
                updateDeployments.add(new Deployment__c(Id = currentJob.Step__r.Deployment__c, Status__c = IN_PROGRESS, Paused__c = isPaused));
            }

            Id deploymentId = currentJob.Step__r.Deployment__c;
            if (deploymenJobsByDeploymentIds.containsKey(deploymentId)) {
                List<Deployment_Job__c> tempDeploymentJobs = deploymenJobsByDeploymentIds.get(deploymentId);
                tempDeploymentJobs.add(deploymentJobRecord);
                deploymenJobsByDeploymentIds.put(deploymentId, tempDeploymentJobs);
            } else {
                List<Deployment_Job__c> tempDeploymentJobs = new List<Deployment_Job__c>();
                tempDeploymentJobs.add(deploymentJobRecord);
                deploymenJobsByDeploymentIds.put(deploymentId, tempDeploymentJobs);
            }
        }

        if (!deploymentJobsToUpdate.isEmpty()) {
            Utilities.Secure_DML(deploymentJobsToUpdate, Utilities.DML_Action.UPD, Schema.Sobjecttype.Deployment_Job__c);
        }

        //Bulkified
        //DEFINE THE STATUS OF STEPS, DESTINATION ORGS AND DEPLOYMENT
        Map<Id, String> statuesByDeploymentIds = DeployJobHelper.updateStatus(deploymenJobsByDeploymentIds, deploymentJobRecordsInOrder);

        for (Id deploymentId : statuesByDeploymentIds.keySet()) {
            if (statuesByDeploymentIds.get(deploymentId).startsWith(COMPLETED) && !Test.isRunningTest()) {
                // NOTE: there is callout inside for loop but it require changes on backend side, otherwise we can not refactor this
                DeployAPI.cleanDeploy(deploymentId);
            }
        }

        if (!deploymentJobIds.isEmpty()) {
            // NOTE: there is callout inside for loop but it require changes on backend side, otherwise we can not refactor this
            DeployAPI.deployJob(deploymentJobIds, UserInfo.getSessionId());
        }

        if (!updateDeployments.isEmpty()) {
            Utilities.Secure_DML(updateDeployments, Utilities.DML_Action.UPD, Schema.Sobjecttype.Deployment__c);
        }

        if (!automationJobsToUpdate.isEmpty()) {
            System.enqueueJob(new UpdateDeploymentJobs(automationJobsToUpdate));
        }
    } else {
        List<Deployment_Job__c> deploymentJobsFlowsToExecute = new List<Deployment_Job__c>();
        for (Deployment_Job__c deploymentJob : Trigger.new) {
            Deployment_Job__c deploymentJobWithParentFields = deploymentJobsByIds.get(deploymentJob.Id);
            if (
                deploymentJob.Status__c == IN_PROGRESS &&
                deploymentJob.Status__c != Trigger.oldMap.get(deploymentJob.Id).Status__c &&
                deploymentJobWithParentFields.Step__r.Type__c == SF_FLOW
            ) {
                deploymentJobsFlowsToExecute.add(deploymentJobWithParentFields);
            }
        }

        List<Result__c> results = new List<Result__c>();
        for (Deployment_Job__c job : deploymentJobsFlowsToExecute) {
            results.add(new Result__c(Status__c = 'In Progress', Job_Type__c = job.Step__r.Name, Start_Time__c = System.now()));
        }
        results = Security.stripInaccessible(AccessType.CREATABLE, results).getRecords();
        insert results;

        for (Integer i = 0; i < deploymentJobsFlowsToExecute.size(); i++) {
            Deployment_Job__c job = deploymentJobsFlowsToExecute[i];
            // Last result is assigned in the job record that will go to the queueable process
            // and to the job in the trigger, so this one will realy be updated in the database.
            // First one is needed since otherwise the job, when sent to the queueable, will not contain the
            // updated Last Result assignment
            job.Last_Result__c = results[i].Id;
            Trigger.newMap.get(job.Id).Last_Result__c = results[i].Id;
        }

        if (!deploymentJobsFlowsToExecute.isEmpty()) {
            System.enqueueJob(new ExecuteFlow(deploymentJobsFlowsToExecute));
        }
    }
}