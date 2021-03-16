public without sharing class StepTriggerHelper {
    public static final String SUFIX = ' step';
    private static final String namespace = Settings.ns;
    private static final List<String> deploymentTaskTypes = new List<String>{
        'Manual Task',
        'Data',
        'Bulk Data',
        'Data Template',
        'Delete Metadata',
        'Custom Settings',
        'Apex',
        'URL Callout',
        'Salesforce Flow'
    };

    private static final Map<String, Schema.RecordTypeInfo> recordTypeInfoByDeveloperName = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();
    private static final String DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME = 'Automation_Template';

    private static Set<Id> deploymentIds = new Set<Id>();
    private static Set<Deployment__c> toUpdateDeployments = new Set<Deployment__c>();
    private static Map<String, Step__c> nextStepMap = new Map<String, Step__c>();
    private static List<Deployment_History__c> history = new List<Deployment_History__c>();

    public static Boolean isFeatureEnabled(Step__c s) {
        Boolean res = true;
        String feature = s.Type__c + StepTriggerHelper.SUFIX;
        Feature__c f = Feature__c.getValues(feature);
        if (f != null && f.Enabled__c == false) {
            res = false;
        }
        return res;
    }

    public static void prepareData(List<Step__c> steps) {
        //Loads a Map with the next Step of the  current Step, based on Deployment Id and Step Order
        for (Step__c step : steps) {
            deploymentIds.add(step.Deployment__c);
        }
        List<Deployment__c> deployments = [
            SELECT
                Id,
                RecordTypeId,
                (
                    SELECT Id, Status__c, Read_Only__c, Deployment__c, Name, Type__c, dataJson__c, Manual_Task_Notified__c
                    FROM Steps__r
                    ORDER BY Order__c ASC
                )
            FROM Deployment__c
            WHERE Id IN :deploymentIds
        ];
        Map<Id, Deployment__c> deploymentsById = new Map<Id, Deployment__c>(deployments);
        // We can fill this map automatically using subquery result
        Map<Id, Integer> depId_stepSizeMap = new Map<Id, Integer>();
        for (Deployment__c deployment : deployments) {
            depId_stepSizeMap.put(deployment.Id, deployment.Steps__r.size());
        }
        // Create map of next steps
        for (Deployment__c deployment : deployments) {
            List<Step__c> deploymentSteps = deployment.Steps__r;
            for (Integer i = 0; i < deploymentSteps.size(); i++) {
                Step__c currentStep = deploymentSteps[i];
                if (i == deploymentSteps.size() - 1) {
                    break;
                } else {
                    nextStepMap.put('' + currentStep.Deployment__c + currentStep.Id, deploymentSteps[i + 1]);
                }
            }
        }
        // To be able set correct order to deployment steps which comes from user story deployment tasks(created by backend)
        // or created in an automation template
        if (Trigger.isInsert) {
            Map<Id, Integer> stepOrderCounterByDeploymentId = new Map<Id, Integer>();
            for (Step__c step : steps) {
                Boolean isEditableDeploymentTaskStep =
                    depId_stepSizeMap.containsKey(step.Deployment__c) &&
                    deploymentTaskTypes.contains(step.Type__c) &&
                    !step.Read_Only__c;

                Boolean isAutomationTemplateStep =
                    deploymentsById.get(step.Deployment__c).RecordTypeId ==
                    recordTypeInfoByDeveloperName.get(DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME).getRecordTypeId();

                if (isEditableDeploymentTaskStep || isAutomationTemplateStep) {
                    if (stepOrderCounterByDeploymentId.containsKey(step.Deployment__c)) {
                        stepOrderCounterByDeploymentId.put(step.Deployment__c, stepOrderCounterByDeploymentId.get(step.Deployment__c) + 1);
                    } else {
                        stepOrderCounterByDeploymentId.put(step.Deployment__c, 1);
                    }

                    Integer numberOfSiblingSteps = depId_stepSizeMap.containsKey(step.Deployment__c) ? depId_stepSizeMap.get(step.Deployment__c) : 0;
                    step.Order__c = numberOfSiblingSteps + stepOrderCounterByDeploymentId.get(step.Deployment__c);
                }
            }
        }
    }

    public static void addHistory(Step__c d, String event) {
        Deployment_History__c h = new Deployment_History__c(
            Deployment_Id__c = d.Deployment__c,
            Deployment__c = d.Deployment__c,
            Date__c = System.now(),
            Event__c = event,
            Object__c = 'Step',
            User__c = UserInfo.getUserId(),
            Field__c = 'Name'
        );
        if (event == 'Created') {
            h.New_Value__c = d.Name;
        }
        if (event == 'Deleted') {
            h.Old_Value__c = d.Name;
        }
        history.add(h);
    }
    public static void addHistory(Step__c oldd, Step__c newd) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Step__c.fields.getMap();
        for (String field : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
            if (dfr.isUpdateable()) {
                if (oldd.get(field) != newd.get(field)) {
                    history.add(
                        new Deployment_History__c(
                            Deployment__c = oldd.Deployment__c,
                            Deployment_Id__c = oldd.Deployment__c,
                            Date__c = System.now(),
                            Event__c = 'Updated',
                            Object__c = 'Step',
                            Field__c = dfr.getLabel(),
                            User__c = UserInfo.getUserId(),
                            New_Value__c = (newd.get(field) != null ? String.valueOf(newd.get(field)).left(255) : null),
                            Old_Value__c = (oldd.get(field) != null ? String.valueOf(oldd.get(field)).left(255) : null)
                        )
                    );
                }
            }
        }
    }
    public static void insertHistory() {
        insert history;
        history.clear();
    }

    public static void notifyTaskOwner(Step__c step) {
        ManualTaskJSONdata taskData = (ManualTaskJSONdata) JSON.deserialize(step.dataJson__c, ManualTaskJSONdata.class);
        String chatterMessage = ' ' + System.Label.MANUAL_TASK_WAITING + ' ' + step.Name;
        if (String.isNotEmpty(taskData.Task_Owner)) {
            if (taskData.Notify_Task_Owner == 'Chatter' && Utilities.isChatterEnabled(namespace + 'Deployment__c')) {
                Utilities.notifyUsingChatterWithAtMention(taskData.Task_Owner, chatterMessage, step.Deployment__c);
            } else if (taskData.Notify_Task_Owner == 'Email') {
                notifyUsingEmail(taskData.Task_Owner, step.Name, step.Deployment__c);
            } else if (taskData.Notify_Task_Owner == 'Chatter and Email') {
                if (Utilities.isChatterEnabled(namespace + 'Deployment__c')) {
                    Utilities.notifyUsingChatterWithAtMention(taskData.Task_Owner, chatterMessage, step.Deployment__c);
                }
                notifyUsingEmail(taskData.Task_Owner, step.Name, step.Deployment__c);
            }
        }
    }

    public static void notifyNextOrCurrentStepOwner(Step__c currentStep) {
        if (currentStep.Status__c == 'Completed Successfully' && !currentStep.Manual_Task_Notified__c) {
            currentStep.Manual_Task_Notified__c = true;
            if (nextStepMap.containsKey((String) currentStep.Deployment__c + currentStep.Id)) {
                Step__c nextStep = nextStepMap.get('' + currentStep.Deployment__c + currentStep.Id);
                if (nextStep.Type__c == 'Manual Task' && nextStep.Status__c == 'Not started') {
                    notifyTaskOwner(nextStep);
                }
            }
        } else if (
            currentStep.Status__c == 'In Progress' &&
            currentStep.Type__c == 'Manual Task' &&
            currentStep.Order__c == 1 &&
            !currentStep.Manual_Task_Notified__c
        ) {
            notifyTaskOwner(currentStep);
        }
    }

    private static void notifyUsingEmail(String userId, String stepName, Id deploymentId) {
        User ownerOfTask = [SELECT Id, Email FROM User WHERE Id = :userId LIMIT 1];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>{ ownerOfTask.Email };
        String htmlBody = System.Label.MANUAL_TASK_WAITING + ' ' + stepName + '<br/>';
        htmlBody += 'Deployment link: ' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + deploymentId;
        message.setHtmlBody(htmlBody);
        message.setSubject(System.Label.MANUAL_TASK_WAITING + ' ' + stepName);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });

        if (!results[0].success) {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }

    public static void checkIfInProgressManualTask(Step__c currentStep, Step__c oldStep) {
        if (currentStep.Status__c == 'Completed Successfully' && currentStep.Status__c != oldStep.Status__c) {
            //default value
            Boolean pauseFlag = false;
            if (nextStepMap.containsKey(String.valueOf(currentStep.Deployment__c) + currentStep.Id)) {
                Step__c nextStep = nextStepMap.get(String.valueOf(currentStep.Deployment__c) + currentStep.Id);
                if (nextStep.Type__c == 'Manual Task' && nextStep.Status__c == 'Not started') {
                    pauseFlag = true;
                    toUpdateDeployments.add(new Deployment__c(Id = nextStep.Deployment__c, Paused__c = true));
                }
            }

            if (currentStep.Type__c == 'Manual Task' && !pauseFlag) {
                toUpdateDeployments.add(new Deployment__c(Id = currentStep.Deployment__c, Paused__c = false));
            }
        }
    }

    public static void togglePauseCheckboxOnDeployment() {
        if (toUpdateDeployments.isEmpty()) {
            return;
        }

        List<Deployment__c> deploymentsToUpdate = new List<Deployment__c>(toUpdateDeployments);
        Utilities.Secure_DML(deploymentsToUpdate, Utilities.DML_Action.UPD, SObjectType.Deployment__c);
        toUpdateDeployments.clear();
    }

    private class ManualTaskJSONdata {
        public Boolean Perform_in_Destination_Org { get; set; }
        public Boolean Perform_in_Source_Org { get; set; }
        public String Task_Description { get; set; }
        public String Task_Owner { get; set; }
        public String Notify_Task_Owner { get; set; }
    }
}