public without sharing class ComplianceScanResultTriggerHelper {
    public static Map<Id, Compliance_Scan_Result__c> scanResultSeverityByIds;
    public static Map<Id, Compliance_Scan_Result__c> scanResultActionByIds;
    public static Map<Id, Org__c> orgsByIds;
    public static Map<Id, Org__c> orgsToUpdateByIds;
    public static Map<Id, Environment__c> environmentsByIds;
    public static Map<Id, Environment__c> environmentsToUpdateByIds;
    public static Map<Id, User_Story__c> userStoriesByIds;
    public static Map<Id, User_Story__c> userStoriesToUpdateByIds;
    public static Map<Id, Git_Backup__c> gitBackupsByIds;
    public static Map<Id, Git_Backup__c> gitBackupsToUpdateByIds;
    public static Map<Id, Deployment__c> deploymentsByIds;
    public static Map<Id, Deployment__c> deploymentsToUpdateByIds;

    public static void prepareData(List<SObject> records) {
        orgsByIds = new Map<Id, Org__c>();
        orgsToUpdateByIds = new Map<Id, Org__c>();
        environmentsByIds = new Map<Id, Environment__c>();
        environmentsToUpdateByIds = new Map<Id, Environment__c>();
        userStoriesByIds = new Map<Id, User_Story__c>();
        userStoriesToUpdateByIds = new Map<Id, User_Story__c>();
        gitBackupsByIds = new Map<Id, Git_Backup__c>();
        gitBackupsToUpdateByIds = new Map<Id, Git_Backup__c>();
        deploymentsByIds = new Map<Id, Deployment__c>();
        deploymentsToUpdateByIds = new Map<Id, Deployment__c>();

        Set<Id> orgIds = new Set<Id>();
        Set<Id> envIds = new Set<Id>();
        Set<Id> userStoryIds = new Set<Id>();
        Set<Id> gitBackupIds = new Set<Id>();
        Set<Id> deploymentIds = new Set<Id>();
        Set<Id> scanResultIds = new Set<Id>();

        for (SObject sobjectItem : records) {
            Compliance_Scan_Result__c scanResult = (Compliance_Scan_Result__c) sobjectItem;
            scanResultIds.add(scanResult.Id);

            if (scanResult.Org_Credential__c != null) {
                orgIds.add(scanResult.Org_Credential__c);
            }
            if (scanResult.Environment__c != null) {
                envIds.add(scanResult.Environment__c);
            }
            if (scanResult.User_Story__c != null) {
                userStoryIds.add(scanResult.User_Story__c);
            }
            if (scanResult.Git_Snapshot__c != null) {
                gitBackupIds.add(scanResult.Git_Snapshot__c);
            }
            if (scanResult.Deployment__c != null) {
                deploymentIds.add(scanResult.Deployment__c);
            }
        }

        orgsByIds = new Map<Id, Org__c>(
            [
                SELECT
                    Id,
                    Compliance_Status__c,
                    Environment__c,
                    Last_Compliance_Scan_Date__c,
                    (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Org__c
                WHERE Id IN :orgIds
            ]
        );
        for (Org__c org : orgsByIds.values()) {
            envIds.add(org.Environment__c);
        }
        environmentsByIds = new Map<Id, Environment__c>(
            [
                SELECT
                    Id,
                    Compliance_Status__c,
                    Last_Compliance_Scan_Date__c,
                    (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Environment__c
                WHERE Id IN :envIds
            ]
        );
        userStoriesByIds = new Map<Id, User_Story__c>(
            [
                SELECT
                    Id,
                    Compliance_Status__c,
                    Last_Compliance_Scan_Date__c,
                    (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM User_Story__c
                WHERE Id IN :userStoryIds
            ]
        );
        gitBackupsByIds = new Map<Id, Git_Backup__c>(
            [
                SELECT
                    Id,
                    Compliance_Status__c,
                    Last_Compliance_Scan_Date__c,
                    (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Git_Backup__c
                WHERE Id IN :gitBackupIds
            ]
        );
        deploymentsByIds = new Map<Id, Deployment__c>(
            [
                SELECT
                    Id,
                    Compliance_Status__c,
                    Last_Compliance_Scan_Date__c,
                    (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Deployment__c
                WHERE Id IN :deploymentIds
            ]
        );
    }

    public static void prepareSummaryData(List<SObject> records) {
        Set<Id> scanResultIds = new Set<Id>();
        for (SObject so : records) {
            scanResultIds.add(so.Id);
        }

        scanResultSeverityByIds = new Map<Id, Compliance_Scan_Result__c>();
        scanResultActionByIds = new Map<Id, Compliance_Scan_Result__c>();

        scanResultSeverityByIds = new Map<Id, Compliance_Scan_Result__c>(
            [
                SELECT
                    Id,
                    Highest_Severity__c,
                    (SELECT Id, Compliance_Rule__r.Severity__c FROM Compliance_Findings__r ORDER BY Compliance_Rule__r.Severity__c LIMIT 1)
                FROM Compliance_Scan_Result__c
                WHERE Id IN :scanResultIds
            ]
        );
        scanResultActionByIds = new Map<Id, Compliance_Scan_Result__c>(
            [
                SELECT
                    Id,
                    Highest_Rule_Action__c,
                    (SELECT Id, Compliance_Rule__r.Action__c FROM Compliance_Findings__r ORDER BY Compliance_Rule__r.Action__c LIMIT 1)
                FROM Compliance_Scan_Result__c
                WHERE Id IN :scanResultIds
            ]
        );
    }

    public static void updateComplianceFields(Compliance_Scan_Result__c scanResult) {
        // Org Scan Result Process
        Boolean isOrgScanResult =
            scanResult.Org_Credential__c != null && orgsByIds.containsKey(scanResult.Org_Credential__c) &&
            orgsByIds.get(scanResult.Org_Credential__c) != null;

        if (isOrgScanResult) {
            Integer orgScanResultCount = orgsByIds.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r.size();
            Org__c org = orgsByIds.get(scanResult.Org_Credential__c);

            String temporaryScanStatus = orgScanResultCount > 0
                ? orgsByIds.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].Status__c
                : '';
            Datetime temporaryScanDate = orgScanResultCount > 0
                ? orgsByIds.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].CreatedDate
                : null;

            String orgLastScanStatus = !Trigger.isDelete ? scanResult.Status__c : temporaryScanStatus;
            Datetime orgLastScanDate = !Trigger.isDelete ? scanResult.CreatedDate : temporaryScanDate;

            org.Last_Compliance_Scan_Date__c = orgLastScanDate;
            org.Compliance_Status__c = orgLastScanStatus;
            orgsToUpdateByIds.put(org.Id, org);
        }

        // Environment Scan Result Process
        Boolean isEnvironmentScanResult =
            scanResult.Environment__c != null && environmentsByIds.containsKey(scanResult.Environment__c) &&
            environmentsByIds.get(scanResult.Environment__c) != null;

        if (isEnvironmentScanResult) {
            Integer environmentScanResultCount = environmentsByIds.get(scanResult.Environment__c).Compliance_Scan_Results__r.size();
            Environment__c environment = environmentsByIds.get(scanResult.Environment__c);

            String temporaryScanStatus = environmentScanResultCount > 0
                ? environmentsByIds.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].Status__c
                : '';
            Datetime temporaryScanDate = environmentScanResultCount > 0
                ? environmentsByIds.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].CreatedDate
                : null;

            String environmentLastScanStatus = !Trigger.isDelete ? scanResult.Status__c : temporaryScanStatus;
            Datetime environmentLastScanDate = !Trigger.isDelete ? scanResult.CreatedDate : temporaryScanDate;

            environment.Last_Compliance_Scan_Date__c = environmentLastScanDate;
            environment.Compliance_Status__c = environmentLastScanStatus;
            environmentsToUpdateByIds.put(environment.Id, environment);
        }

        // User Story Scan Result Process
        Boolean isUserStoryScanResult =
            scanResult.User_Story__c != null && userStoriesByIds.containsKey(scanResult.User_Story__c) &&
            userStoriesByIds.get(scanResult.User_Story__c) != null;

        if (isUserStoryScanResult) {
            Integer userStoryScanResultCount = userStoriesByIds.get(scanResult.User_Story__c).Compliance_Scan_Results__r.size();
            User_Story__c userStory = userStoriesByIds.get(scanResult.User_Story__c);

            String temporaryScanStatus = userStoryScanResultCount > 0
                ? userStoriesByIds.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].Status__c
                : '';
            Datetime temporaryScanDate = userStoryScanResultCount > 0
                ? userStoriesByIds.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].CreatedDate
                : null;

            String userStoryLastScanStatus = !Trigger.isDelete ? scanResult.Status__c : temporaryScanStatus;
            Datetime userStoryLastScanDate = !Trigger.isDelete ? scanResult.CreatedDate : temporaryScanDate;

            userStory.Last_Compliance_Scan_Date__c = userStoryLastScanDate;
            userStory.Compliance_Status__c = userStoryLastScanStatus;
            userStoriesToUpdateByIds.put(userStory.Id, userStory);
        }

        // Snapshot Scan Result Process
        Boolean isSnapshotScanResult =
            scanResult.Git_Snapshot__c != null && gitBackupsByIds.containsKey(scanResult.Git_Snapshot__c) &&
            gitBackupsByIds.get(scanResult.Git_Snapshot__c) != null;

        if (isSnapshotScanResult) {
            Integer snapshotScanResultCount = gitBackupsByIds.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r.size();
            Git_Backup__c gitBackup = gitBackupsByIds.get(scanResult.Git_Snapshot__c);

            String temporaryScanStatus = snapshotScanResultCount > 0
                ? gitBackupsByIds.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].Status__c
                : '';
            Datetime temporaryScanDate = snapshotScanResultCount > 0
                ? gitBackupsByIds.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].CreatedDate
                : null;

            String gitBackupLastScanStatus = !Trigger.isDelete ? scanResult.Status__c : temporaryScanStatus;
            Datetime gitBackupLastScanDate = !Trigger.isDelete ? scanResult.CreatedDate : temporaryScanDate;

            gitBackup.Last_Compliance_Scan_Date__c = gitBackupLastScanDate;
            gitBackup.Compliance_Status__c = gitBackupLastScanStatus;
            gitBackupsToUpdateByIds.put(gitBackup.Id, gitBackup);
        }

        // Deployment Scan Result Process
        Boolean isDeploymentScanResult =
            scanResult.Deployment__c != null && deploymentsByIds.containsKey(scanResult.Deployment__c) &&
            deploymentsByIds.get(scanResult.Deployment__c) != null;

        if (isDeploymentScanResult) {
            Integer deploymentScanResultCount = deploymentsByIds.get(scanResult.Deployment__c).Compliance_Scan_Results__r.size();
            Deployment__c deployment = deploymentsByIds.get(scanResult.Deployment__c);

            String temporaryScanStatus = deploymentScanResultCount > 0
                ? deploymentsByIds.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].Status__c
                : '';
            Datetime temporaryScanDate = deploymentScanResultCount > 0
                ? deploymentsByIds.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].CreatedDate
                : null;

            String deploymentLastScanStatus = !Trigger.isDelete ? scanResult.Status__c : temporaryScanStatus;
            Datetime deploymentLastScanDate = !Trigger.isDelete ? scanResult.CreatedDate : temporaryScanDate;

            deployment.Last_Compliance_Scan_Date__c = deploymentLastScanDate;
            deployment.Compliance_Status__c = deploymentLastScanStatus;
            deploymentsToUpdateByIds.put(deployment.Id, deployment);
        }
    }

    public static void updateComplianceScanSummaryFields(Compliance_Scan_Result__c scanResult) {
        if (scanResultSeverityByIds.get(scanResult.Id) != null && scanResultSeverityByIds.get(scanResult.Id).Compliance_Findings__r.size() > 0) {
            String highestSeverity = scanResultSeverityByIds.get(scanResult.Id).Compliance_Findings__r[0].Compliance_Rule__r.Severity__c;
            scanResult.Highest_Severity__c = highestSeverity;
        }
        if (scanResultActionByIds.get(scanResult.Id) != null && scanResultActionByIds.get(scanResult.Id).Compliance_Findings__r.size() > 0) {
            String highestRuleAction = scanResultActionByIds.get(scanResult.Id).Compliance_Findings__r[0].Compliance_Rule__r.Action__c;
            scanResult.Highest_Rule_Action__c = highestRuleAction;
        }
    }

    public static void dmlOperationsForAll() {
        if (orgsToUpdateByIds != null && !orgsToUpdateByIds.isEmpty()) {
            Utilities.Secure_DML(orgsToUpdateByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Org__c);
        }

        if (environmentsToUpdateByIds != null && !environmentsToUpdateByIds.isEmpty()) {
            Utilities.Secure_DML(environmentsToUpdateByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Environment__c);
        }

        if (userStoriesToUpdateByIds != null && !userStoriesToUpdateByIds.isEmpty()) {
            Utilities.Secure_DML(userStoriesToUpdateByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        }

        if (gitBackupsToUpdateByIds != null && !gitBackupsToUpdateByIds.isEmpty()) {
            Utilities.Secure_DML(gitBackupsToUpdateByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Git_Backup__c);
        }

        if (deploymentsToUpdateByIds != null && !deploymentsToUpdateByIds.isEmpty()) {
            Utilities.Secure_DML(deploymentsToUpdateByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
        }
    }
}