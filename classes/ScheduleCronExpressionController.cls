public with sharing class ScheduleCronExpressionController {
    private static final String NAMESPACE = Settings.ns;
    public Id thisRecordId;
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public String thisCronExpression { get; set; }
    private String thisPromotionType;
    private IScheduledJob thisJob;
    public ScheduleCronExpressionController() {
        thisPromotionType = ApexPages.currentPage().getParameters().get('promotionType');
        showError = false;
        showOptions = true;
    }
    /**
     * @description a setter for the thisRecordId attribute.
     *
     * @param recordId the value to be set on the thisRecordId variable.
     */
    public void setThisRecordId(Id recordId) {
        thisRecordId = recordId;
        if(String.isBlank(thisRecordId)) {
            addErrorMessage(Label.No_Record_Found);
            return;
        }
        initJobInstance();
    }
    /**
     * @description a getter for the thisRecordId attribute.
     *
     * @return the current value of the thisRecordId variable.
     */
    public Id getThisRecordId() {
        return thisRecordId;
    }
    /**
     * @description instantiates a new IScheduledJob object using the factory pattern that is based on the record id
     * coming from the parent Visualforce Page. Preconfigures the new instance, validates any possible errors and
     * retrieves the SObject record using SOQL,
     */
    private void initJobInstance() {
        ScheduledJobFactory thisFactory = new ScheduledJobFactory();
        thisJob = thisFactory.getScheduledJob(thisRecordId);
        if(thisJob instanceof CopadoScheduledJob) {
            if(!((CopadoScheduledJob)thisJob).isLicenseEnabled()) {
                addErrorMessage(Label.CE_License_Restriction.replace('__License__', Label.CST_Licence));
            }
        } else if(thisJob instanceof ConnectionBehavior) {
            ((ConnectionBehavior)thisJob).setPromotionType(thisPromotionType);
        }
        if(thisJob.getJobRecord() == null) {
            addErrorMessage(Label.No_Record_Found);
        }
    }
    /**
     * @description a generic method for adding page error messages and hiding page options when an error occurs.
     *
     * @param errorMessage the error message string to be displayed to the user.
     */
    private void addErrorMessage(String errorMessage) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        showError = true;
        showOptions = false;
    }
    /**
     * @description checks if all required fields are filled before saving the record to the database, sets the new
     * cron expression value on the current record and updates it.
     *
     * @return a new page reference redirection to the record detail page.
     */
    public PageReference saveJob() {
        if(requiredFieldsAreEmpty()) {
            return null;
        }
        thisJob.setCronExpression(thisCronExpression);
        try {
            if(thisJob instanceof CopadoScheduledJob) {
                ((CopadoScheduledJob)thisJob).scheduleJob();
            }
            thisJob.updateRecord();
        } catch(Exception ex) {
            return null;
        }
        return goBackToRecordDetail();
    }
    /**
     * @description checks if the thisCronExpression variable is empty and displays an error message to warn the user
     * accordingly.
     *
     * @return a value indicating if at least one required field is empty.
     */
    private Boolean requiredFieldsAreEmpty() {
        ApexPages.getMessages().clear();
        Boolean requiredFieldsAreEmpty = false;
        if(String.isBlank(thisCronExpression)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cron_Expression_Required));
            requiredFieldsAreEmpty = true;
        }
        return requiredFieldsAreEmpty;
    }
    /**
     * @description redirects the user back to the record detail page.
     *
     * @return a new page reference redirection to the record detail page.
     */
    public PageReference goBackToRecordDetail() {
        return thisJob.getRecordDetailPage();
    }
    /**
     * @description sets the new cron expression value on the thisCronExpression variable and saves the changes.
     *
     * @return a new page reference redirection to the record detail page.
     */
    public PageReference setCronExpressionValue() {
        thisCronExpression = ApexPages.CurrentPage().getParameters().get('newCronExpression');
        return saveJob();
    }
    /**
     * @description a class implementing the IScheduledJob interface that represents the Scheduled_Job__c object.
     */
    private with sharing class CopadoScheduledJob implements IScheduledJob {
        private Id recordId;
        private Scheduled_Job__c thisRecord;
        public CopadoScheduledJob(Id thisRecordId) {
            recordId = thisRecordId;
        }
        /**
         * @description retrieves a Scheduled_Job__c record based on the recordId parameter.
         *
         * @return the Scheduled_Job__c record.
         */
        public SObject getJobRecord() {
            if(thisRecord == null) {
                List<Scheduled_Job__c> scheduledJobs = [SELECT Name, Apex_Job_ID__c, Cron_Expression__c FROM Scheduled_Job__c WHERE Id = :recordId];
                if(!scheduledJobs.isEmpty()) {
                    thisRecord = scheduledJobs[0];
                }
            }
            return thisRecord;
        }
        /**
         * @description checks if the corresponding license is enabled for editing Scheduled_Job__c records.
         *
         * @return a flag indicating if the permission is enabled or not.
         */
        private Boolean isLicenseEnabled() {
            return LicenseHelper.actionIsLicenseEnabled('viewEditScheduledJob');
        }
        /**
         * @description schedules a new job tied to the current Scheduled_Job__c record with the newly set cron expression.
         */
        public void scheduleJob() {
            try {
                stopJob();
                WebhookSchedulable thisWebhookSchedulable = new WebhookSchedulable(recordId);
                String jobId = System.schedule(thisRecord.Name.left(80), thisRecord.Cron_Expression__c, thisWebhookSchedulable);
                thisRecord.Apex_Job_ID__c = jobId;
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.COULD_NOT_SCHEDULE_JOB + ': ' + ex.getMessage()));
            }
        }
        /**
         * @description if a job related to the current Scheduled_Job__c record already exists, the method still stop it
         * and reschedule a new job.
         */
        private void stopJob() {
            String jobId = thisRecord.Apex_Job_ID__c;
            if(String.isNotBlank(jobId)) {
                abortCurrentJob(jobId);
                thisRecord.Apex_Job_ID__c = null;
                Utilities.Secure_DML(thisRecord, Utilities.DML_Action.UPD, SObjectType.Scheduled_Job__c);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NOTHING_TO_STOP));
            }
        }
        /**
         * @description aborts the current job before schedule a new one.
         *
         * @param jobId the id of the job to be aborted.
         */
        private void abortCurrentJob(String jobId) {
            List<CronTrigger> cts = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
            if(!cts.isEmpty()) {
                System.abortJob(jobId);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.JOB_UNSCHEDULED_SUCCESSFULLY));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NO_JOB_FOUND));
            }
        }
        /**
         * @description sets the new cron expression value on the record.
         *
         * @param thisCronExpression the new cron expression value to be set.
         */
        public void setCronExpression(String thisCronExpression) {
            thisRecord.Cron_Expression__c = thisCronExpression;
        }
        /**
         * @description updates the current record to save the new cron expression value.
         */
        public void updateRecord() {
            try {
                Utilities.Secure_DML(thisRecord, Utilities.DML_Action.UPD, SObjectType.Scheduled_Job__c);
            } catch(DmlException dmlEx) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlEx.getDmlMessage(0)));
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
        }
        /**
         * @description redirects the user back to the record detail page.
         *
         * @return a new page reference redirection to the record detail page.
         */
        public PageReference getRecordDetailPage() {
            return new ApexPages.StandardController(thisRecord).view();
        }
    }
    /**
     * @description a class implementing the IScheduledJob interface that represents the Connection_Behavior__c object.
     */
    private with sharing class ConnectionBehavior implements IScheduledJob {
        private Id recordId;
        private String promotionType;
        private Connection_Behavior__c thisRecord;
        public ConnectionBehavior(Id thisRecordId) {
            recordId = thisRecordId;
        }
        /**
         * @description retrieves a Connection_Behavior__c record based on the recordId and promotionType parameters.
         *
         * @return the Connection_Behavior__c record.
         */
        public SObject getJobRecord() {
            if(String.isBlank(promotionType)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Promotion_Type_Specificed));
                return null;
            }
            if(thisRecord == null) {
                try {
                    String queryString = 'SELECT ' + String.escapeSingleQuotes(promotionType) + '_Schedule__c FROM Connection_Behavior__c WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';
                    List<Connection_Behavior__c> connectionBehaviors = (List<Connection_Behavior__c>) Database.query(queryString);
                    if(!connectionBehaviors.isEmpty()) {
                        thisRecord = connectionBehaviors[0];
                    }
                } catch(QueryException ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                }
            }
            return thisRecord;
        }
        /**
         * @description sets the promotionType variable value based on the incoming URL parameter.
         *
         * @param thisPromotionType the URL parameter coming from the parent Visualforce Page.
         */
        private void setPromotionType(String thisPromotionType) {
            promotionType = thisPromotionType;
        }
        /**
         * @description sets the new cron expression value on the record based on the promotion type.
         *
         * @param thisCronExpression the new cron expression value to be set.
         */
        public void setCronExpression(String thisCronExpression) {
            if(promotionType == 'Promotion') {
                thisRecord.Promotion_Schedule__c = thisCronExpression;
            } else if(promotionType == 'Back_Promotion') {
                thisRecord.Back_Promotion_Schedule__c = thisCronExpression;
            }
        }
        /**
         * @description updates the current record to save the new cron expression value.
         */
        public void updateRecord() {
            try {
                Utilities.Secure_DML(thisRecord, Utilities.DML_Action.UPD, SObjectType.Connection_Behavior__c);
            } catch(DmlException dmlEx) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlEx.getDmlMessage(0)));
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
        }
        /**
         * @description redirects the user back to the record detail page.
         *
         * @return a new page reference redirection to the record detail page.
         */
        public PageReference getRecordDetailPage() {
            return new ApexPages.StandardController(thisRecord).view();
        }
    }
    /**
     * @description a factory class used for getting and instantiating different job class instances implementing the
     * IScheduledJob interface.
     */
    private with sharing class ScheduledJobFactory {
        /**
         * @description gets the IScheduledJob instance based on the record id provided.
         *
         * @param recordId the record id parameter coming from the parent Visualforce Page.
         *
         * @return a new instance of IScheduledJob for the target SObject.
         */
        public IScheduledJob getScheduledJob(Id recordId) {
            try {
                if(isObjectType(ScheduleCronExpressionController.NAMESPACE + 'Scheduled_Job__c', recordId)) {
                    return new CopadoScheduledJob(recordId);
                } else if(isObjectType(ScheduleCronExpressionController.NAMESPACE + 'Connection_Behavior__c', recordId)) {
                    return new ConnectionBehavior(recordId);
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Object_Not_Supported));
                }
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            return null;
        }
        /**
         * @description checks if a record id belongs to a given SObject type.
         *
         * @param thisObjectType the name of the SObject to be matched against.
         * @param recordId the id of the record being evaluated.
         *
         * @return a flag indicating if the record id corresponds to the given SObject type.
         */
        private Boolean isObjectType(String thisObjectType, Id recordId) {
            if(String.isBlank(recordId)) {
                return false;
            }
            String sObjectType = recordId.getSObjectType().getDescribe().getName();
            return sObjectType == thisObjectType;
        }
    }
    /**
     * @description an interface used for implementing the factory pattern on this component.
     */
    private interface IScheduledJob {
        /**
         * @description this method is intended to retrieve an SObject record using SOQL.
         *
         * @return the record that was retrieved by the query. The SObject type is dynamic.
         */
        SObject getJobRecord();
        /**
         * @description this method is intented to set a new cron expression value on the record belonging to the
         * implementing class.
         *
         * @param thisCronExpression the new cron expression value that is set on the record.
         */
        void setCronExpression(String thisCronExpression);
        /**
         * @description this method is intended to update the record belonging to the
         * implementing class.
         */
        void updateRecord();
        /**
         * @description this method is intended to redirect the user to the detail page of the record belonging to the
         * implementing class.
         *
         * @return a new page reference redirection to the record detail page.
         */
        PageReference getRecordDetailPage();
    }
}