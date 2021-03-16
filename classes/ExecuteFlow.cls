public with sharing class ExecuteFlow implements Queueable {
    private final String ATTACHMENT_BODY = '[\'{\'"m":"NEW STATUS: {0} on \\"{1}\\"","l":"INFO","t":""\'}\',\'{\'"m": "Comment: {2}","l":"INFO","t":""\'}\']';

    private List<Deployment_Job__c> jobs;

    private Map<Id, Attachment> cachedAttsById;

    private List<Attachment> attachmentResults = new List<Attachment>();

    // CTOR

    public ExecuteFlow(List<Deployment_Job__c> jobs) {
        this.jobs = jobs;
        cachedAttsById = getAttachmentResultsByParentId();
    }

    // PUBLIC

    public void execute(QueueableContext ctx) {
        List<SObject> recordsToUpdate = new List<SObject>();

        for (Deployment_Job__c job : jobs) {
            FlowExecutionResult execResult = triggerFlowExecution(job);
            Boolean continueJob = execResult.continueJob;
            String resultMessage = execResult.resultMessage;

            Boolean success = (resultMessage == Label.FLOW_EXECUTED_SUCCESSFULLY);

            if (!success || continueJob) {
                String status = success ? Status.SUCCESS.name() : Status.FAILED.name();

                recordsToUpdate.add(new Deployment_Job__c(Id = job.Id, Status__c = status));

                Attachment att = getAttachment(job);
                att.Body = Blob.valueOf(String.format(ATTACHMENT_BODY, new List<Object>{ status, String.valueOf(System.now()), resultMessage }));
                attachmentResults.add(att);
            }

            if (!success) {
                recordsToUpdate.add(new Result__c(Id = job.Last_Result__c, Status__c = Status.FAILED.name(), Error_Message__c = resultMessage));
            }
        }

        recordsToUpdate = Security.stripInaccessible(AccessType.UPDATABLE, recordsToUpdate).getRecords();
        update recordsToUpdate;

        // FALSE POSITIVE: Security.stripInaccessible removes parentId
        // causing an error and permissions over Attachment can not be controlled
        upsert attachmentResults;
    }

    // PRIVATE

    private Map<Id, Attachment> getAttachmentResultsByParentId() {
        if (cachedAttsById == null) {
            Set<String> names = new Set<String>();
            Set<String> deploymentIds = new Set<String>();

            for (Deployment_Job__c job : jobs) {
                names.add(job.Id + '.json');
                deploymentIds.add(job.Step__r.Deployment__c);
            }

            cachedAttsById = new Map<Id, Attachment>();

            for (Attachment att : [SELECT Id, Body, Name, ParentId FROM Attachment WHERE Name IN :names AND ParentId IN :deploymentIds]) {
                // If a parent has more than 1 attachment (this should not happen)
                // they will be overriden by the last one, since we only need 1
                cachedAttsById.put(att.ParentId, att);
            }
        }

        return cachedAttsById;
    }

    private FlowExecutionResult triggerFlowExecution(Deployment_Job__c job) {
        Map<String, Object> flow;
        String resultMessage;
        try {
            flow = (Map<String, Object>) JSON.deserializeUntyped(job.Step__r.dataJson__c);
            Map<String, Object> flowParameters = parseFlowParameters((List<Object>) flow.get('flowParameters'));
            flowParameters.put('resultId', job.Last_Result__c);
            flow.put('flowParameters', DynamicVariablesInterpreter.getDynamicVariablesInterpreted(job, flowParameters));
            resultMessage = SalesforceFlowStepController.executeSelectedFlow(flow);
        } catch (Exception e) {
            resultMessage = String.format(Label.ERROR_PARSING_FLOW_INFORMATION, new List<Object>{ e.getMessage() });
        }

        Boolean continueJob = (String) flow?.get('type') == 'continue';
        return new FlowExecutionResult(continueJob, resultMessage);
    }

    private Map<String, Object> parseFlowParameters(List<Object> params) {
        Map<String, Object> result = new Map<String, Object>();
        for (Object attributes : params) {
            List<Object> parsedAttributes = (List<Object>) attributes;
            result.put((String) parsedAttributes[0], parsedAttributes[1]);
        }

        return result;
    }

    private Attachment getAttachment(Deployment_Job__c job) {
        if (cachedAttsById.containsKey(job.Id)) {
            return cachedAttsById.get(job.Id);
        } else {
            return new Attachment(Name = job.Id + '.json', ParentId = job.Step__r.Deployment__c);
        }
    }

    // INNER

    private enum Status {
        SUCCESS,
        FAILED
    }

    private class FlowExecutionResult {
        private Boolean continueJob;
        private String resultMessage;

        //CTOR

        private FlowExecutionResult(Boolean continueJob, String resultMessage) {
            this.continueJob = continueJob;
            this.resultMessage = resultMessage;
        }
    }
}