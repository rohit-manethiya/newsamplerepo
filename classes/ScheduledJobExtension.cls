public with sharing class ScheduledJobExtension {
    public CronTrigger ct { get; set; }
    public Scheduled_Job__c job { get; set; }
    private ApexPages.StandardController cont;
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    /**
     * To get all accessibleFields and add them to the Standard controller in order to avoid SOQL without querying exception
     * And also if someone adds a new field to the page they wont worry about adding the field to the controller.
     */
    public List<String> accessibleFields {
        get {
            if(accessibleFields == null) {
                // Get a list (map) of all fields on the object
                Map<String, Schema.SObjectField> fields = Schema.SObjectType.Scheduled_Job__c.fields.getMap();
                // Save only the fields accessible by the current user
                Set<String> availableFieldsSet = new Set<String>();
                for(String str : fields.keySet()) {
                    if(fields.get(str).getDescribe().isAccessible()
                            // Comment out next line to show standard/system fields.(bear in mind FLS of Std fields cannot be removed.)
                            && fields.get(str).getDescribe().isCustom()
                            ) {
                        availableFieldsSet.add(str.toLowerCase());
                    }
                }
                // Convert set to list, save to property. 
                // Even if in the current structure it is not possible, the Set is used to avoid duplicate fields exception just in case for the future enhancements.
                accessibleFields = new List<String>(availableFieldsSet);
            }
            return accessibleFields;
        }
        private set;
    }
    public ScheduledJobExtension(ApexPages.StandardController std) {
        if(!Test.isRunningTest()) {
            std.addFields(accessibleFields);
        } else {
            List<String> fieldNames = new List<String>();
            fieldNames.addAll(accessibleFields);
        }
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        cont = std;
        job = (Scheduled_Job__c) std.getRecord();
        if(String.isNotBlank(job.Apex_Job_ID__c)) {
            List<CronTrigger> ctsList = [SELECT Id, CronExpression, NextFireTime, PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey FROM CronTrigger WHERE Id = :job.Apex_Job_ID__c];
            ct = !ctsList.isEmpty() ? ctsList.get(0) : null;
        }
        if(ct == null) {
            ct = new CronTrigger();
        }
    }

    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditScheduledJob')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CST_Licence)));
            showError = true;
            showOptions = false;
        }
        return;
    }
    public PageReference stop() {
        if(String.isNotBlank(job.Apex_Job_ID__c)) {
            List<CronTrigger> cts = [SELECT Id, CronExpression, NextFireTime, PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey FROM CronTrigger WHERE Id = :job.Apex_Job_ID__c];
            if(!cts.isEmpty()) {
                System.abortJob(job.Apex_Job_ID__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.JOB_UNSCHEDULED_SUCCESSFULLY));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NO_JOB_FOUND));
            }
            job.Apex_Job_ID__c = null;
            Utilities.Secure_DML(job, Utilities.DML_Action.UPD, schema.SObjectType.Scheduled_Job__c);
            ct = new CronTrigger();
            return null;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NOTHING_TO_STOP));
        }
        return null;
    }
    public PageReference delete_job() {
        stop();
        Utilities.Secure_DML(job, Utilities.DML_Action.DEL, schema.SObjectType.Scheduled_Job__c);
        return cont.delete();
    }
    public PageReference schedule_job() {
        PageReference pr = Page.ScheduleCopadoScheduledJob;
        pr.getParameters().put('id', job.Id);
        return pr;
    }
    public PageReference save_job() {
        try {
            stop();
            String cron = job.Cron_Expression__c;
            String jobId = System.schedule(job.Name.left(80), cron, new WebhookSchedulable(job.Id));
            job.Apex_Job_ID__c = jobId;
            Utilities.Secure_DML(job, Utilities.DML_Action.UPD, schema.SObjectType.Scheduled_Job__c);
            return new Apexpages.StandardController(job).view();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.COULD_NOT_SCHEDULE_JOB + ': ' + e.getMessage()));
        }
        return null;
    }
}