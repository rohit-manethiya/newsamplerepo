public with sharing class NewApexTestResultEmailController {
    private static final Integer MAX_BODY_LENGTH = 200000;
    private static Boolean getResult = true;

    public static String statusMessage { get; set; }
    public static String statusMessageTestResult { get; set; }
    public static String apexTestResultId { get; set; }
    public static Apex_Test_Result__c apexTestResult {
        get {
            // Needed since, when passing the entire SObject record as a paramenter to the component,
            // we only get "one bite at the cherry", not including custom fields
            if (apexTestResult == null) {
                if (String.isNotBlank(apexTestResultId)) {
                    try {
                        apexTestResult = [
                            SELECT
                                Name,
                                Status__c,
                                Total_time__c,
                                Tests_run__c,
                                Failures__c,
                                Successes__c,
                                Org__r.Name,
                                Org__r.Environment__r.Name,
                                Org__r.Environment__r.Minimum_Apex_Test_Coverage__c
                            FROM Apex_Test_Result__c
                            WHERE Id = :apexTestResultId
                            WITH SECURITY_ENFORCED
                        ];
                    } catch (final Exception e) {
                        statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                    }
                    statusMessage = '';
                } else {
                    statusMessage = Label.RECORD_NOT_FOUND;
                }
            }
            return apexTestResult;
        }
        set;
    }
    public static Decimal totalLines {
        get {
            if (getResult) {
                getTestResult();
            }
            return totalLines;
        }
        set;
    }
    public static Decimal notCoveredLines {
        get {
            if (getResult) {
                getTestResult();
            }
            return notCoveredLines;
        }
        set;
    }

    public static String getRecordUrl() {
        return Settings.ORGANIZATION_URL + '/' + apexTestResultId;
    }

    public static String getResultsUrl() {
        final Boolean orgExists = apexTestResult != null && apexTestResult.Org__r != null;
        return orgExists
            ? Settings.ORGANIZATION_URL + '/apex/' + Settings.ns + 'OrgApexTestResultsSummary?id=' + apexTestResult.Org__r.Id
            : null;
    }

    private static void getTestResult() {
        totalLines = 0;
        notCoveredLines = 0;
        if (String.isNotBlank(apexTestResultId)) {
            getResult = false;
            statusMessage = '';
            statusMessageTestResult = '';
            final List<Attachment> attachments;
            try {
                attachments = [
                    SELECT Body, BodyLength
                    FROM Attachment
                    WHERE Name = 'ApexTestResult' AND ParentId = :apexTestResultId
                    WITH SECURITY_ENFORCED
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];
            } catch (final Exception e) {
                statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
            }
            if (!attachments.isEmpty()) {
                final Attachment attachmentRecord = attachments[0];
                if (attachmentRecord.BodyLength <= MAX_BODY_LENGTH) {
                    try {
                        final Map<String, Object> testResultsByEntity = (Map<String, Object>) JSON.deserializeUntyped(
                            attachmentRecord.Body.toString()
                        );

                        final Map<String, Object> classCoverageResultsByClassName = (Map<String, Object>) testResultsByEntity.get(
                            'classCoverageResults'
                        );
                        if (classCoverageResultsByClassName != null && !classCoverageResultsByClassName.isEmpty()) {
                            for (String className : (Set<String>) classCoverageResultsByClassName.keySet()) {
                                final Map<String, Object> classObject = (Map<String, Object>) classCoverageResultsByClassName.get(
                                    className
                                );
                                totalLines += (Integer) classObject.get('numLocations');
                                notCoveredLines += (Integer) classObject.get('numLocationsNotCovered');
                            }
                        }

                        final Map<String, Object> triggerCoverageResultsByTriggerName = (Map<String, Object>) testResultsByEntity.get(
                            'triggerCoverageResults'
                        );
                        if (
                            triggerCoverageResultsByTriggerName != null &&
                            !triggerCoverageResultsByTriggerName.isEmpty()
                        ) {
                            for (String triggerName : (Set<String>) triggerCoverageResultsByTriggerName.keySet()) {
                                final Map<String, Object> triggerObject = (Map<String, Object>) triggerCoverageResultsByTriggerName.get(
                                    triggerName
                                );
                                totalLines += (Integer) triggerObject.get('numLocations');
                                notCoveredLines += (Integer) triggerObject.get('numLocationsNotCovered');
                            }
                        }
                    } catch (final Exception e) {
                        statusMessageTestResult = Label.ERROR_PARSING_JSON + ' ' + e.getMessage();
                    }
                } else {
                    statusMessageTestResult = Label.MAX_FILE_SIZE_EXCEEDED;
                }
            } else {
                statusMessageTestResult = Label.NO_ERROR_ATTACHMENT_FOUND;
            }
        } else {
            statusMessage = Label.RECORD_NOT_FOUND;
        }
    }

    public static Decimal getMinCoverage() {
        final Boolean coverageExists =
            apexTestResult != null &&
            apexTestResult.Org__r != null &&
            apexTestResult.Org__r.Environment__r != null &&
            apexTestResult.Org__r.Environment__r.Minimum_Apex_Test_Coverage__c != null;
        return coverageExists ? apexTestResult.Org__r.Environment__r.Minimum_Apex_Test_Coverage__c : 75.00;
    }
}