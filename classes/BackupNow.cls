public with sharing class BackupNow {
    public Git_Backup__c backup;
    public String validation;
    public Boolean isValid { get; set; }
    public Boolean hideMessages;
    public Boolean testOK;
    public Boolean isBackupEnabled { get; set; }
    public Boolean showOtherInformation { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public Boolean complianceScanRequestAccess { get; set; }
    public Boolean complianceScanResultAccess { get; set; }
    public Boolean pageHasErrors {
        get {
            return ApexPages.hasMessages(ApexPages.Severity.ERROR);
        }
    }
    private final String GIT_BACKUP = 'Git Backup';
    private final String COMPLIANCE_HUB = 'Compliance Hub';

    public BackupNow(ApexPages.StandardController stdController) {
        this.backup = (Git_Backup__c) stdController.getRecord();
        if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            this.backup = [SELECT Git_Repository__c, Org__c, CreatedById, Org__r.OwnerId, Git_Snapshot_Permissions__c FROM Git_Backup__c WHERE Id = :THIS.backup.Id];
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Git_Backup__c.label + ' ' + Label.Insufficient_Access_Rights));
        }
        hideMessages = false;
        testOK = false;
        showOptions = true;
        showError = false;
        complianceScanRequestAccess = LicenseHelper.actionIsLicenseEnabled('requestComplianceScan');
        complianceScanResultAccess = FeatureAccessHelper.isComplianceScanResultAccessible();
        //check validations in order to disable functionality
        getValidation();
        isLicenseEnabled();
        isBackupEnabled = true;
        Boolean isGitBackupFeatureEnabled = FeatureHelper.isFeatureEnabled(GIT_BACKUP);
        Boolean isLicensesExceeded = LicenseHelper.isLicensesExceeded();
        if(!isGitBackupFeatureEnabled || isLicensesExceeded) {
            if(isLicensesExceeded) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LICENSES_EXCEEDED));
            }
            if(!isGitBackupFeatureEnabled) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ' ' + GIT_BACKUP));
            }
            isBackupEnabled = false;
        }
        showOtherInformation = SObjectType.Git_Backup__c.fieldSets.CustomFields.getFields().size() > 0;
    }

    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditGitSnapshot')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCH_or_CCM_License)));
            showError = true;
            showOptions = false;
        }
        return;
    }

    public void doBackup() {
        String commitComment = ApexPages.currentPage().getParameters().get('commitComment');
        Boolean applyEnvVars = Boolean.valueOf(ApexPages.currentPage().getParameters().get('applyEnvVars'));
        Boolean applyYAML = Boolean.valueOf(ApexPages.currentPage().getParameters().get('applyYAML'));
        hideMessages = true;
        if(!testConnections()) {
            return;
        }
        if(!FeatureHelper.isFeatureEnabled(GIT_BACKUP)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ' ' + GIT_BACKUP));
            isBackupEnabled = false;
            return;
        }
        try {
            DeployAPI.backupNow(this.backup.Id, commitComment, applyEnvVars, applyYAML);
            ApexPages.getMessages().clear();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.BACKUP_STARTED));
        } catch(Exception e) {
            System.debug('line exception: ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        hideMessages = false;
    }
    public Boolean testConnections() {
        if(testOK) {
            return true;
        }
        System.debug('testing connections');
        Id gitId = this.backup.Git_Repository__c;
        Id orgId = this.backup.Org__c;
        DeployAPI.validateGitResult validation = DeployAPI.validateGit(gitId);
        if(!validation.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Git_Repository__c.SObjectType.getDescribe().getLabel() + ' ' + validation.message));
            System.debug('git not validated');
            return false;
        }
        System.debug('git validated, hideMessages=' + hideMessages);

        if(!DeployAPI.validateOrg(orgId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ' ' + Label.WRONG_CREDENTIALS));
            System.debug('org not validated');
            return false;
        }
        System.debug('org validated, hideMessages=' + hideMessages);
        System.debug('copado org validated, hideMessages=' + hideMessages);
        testOK = true;
        System.debug('testOK=' + testOK);
        return true;
    }

    public String getValidation() {
        System.debug('start getValidation -> testOK=' + testOK);
        isValid = this.testConnections();
        validation = isValid ? Label.OK : Label.ERROR_TEST_GIT_CONNECTIONS;
        System.debug('end getValidation -> testOK=' + testOK);
        return validation;
    }

    public void doTestConnections() {
        this.testConnections();
    }
    public void getCommits() {
        hideMessages = true;
        if(!testConnections()) {
            return;
        }
        try {
            DeployAPI.getCommits(this.backup.Id);
            ApexPages.getMessages().clear();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.COMMITS_BEING_RETRIEVED));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        hideMessages = false;
    }
    /**
     * Fake getter to create the Heroku get Metadata url 
     * @return [url]
     */
    public String getMetadata_url() {
        Id orgId = this.backup.Org__c;
        String urlParameters = '?nosid=1';
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';

        if(orgId == null) {
            return null;
        }
        return urlBase + 'metadata/' + EncodingUtil.urlEncode(orgId, 'UTF-8') + urlParameters + '&dates=format';
    }

    /**
     * Fake getter to create the Heroku get Zip files url 
     * @return [url]
     */
    public String getQuery_url() {
        Id orgId = this.backup.Org__c;
        String urlParameters = '?nosid=1';
        String herokuServer = Settings.server_url;
        String urlBase = herokuServer + '/json/v1/';

        if(orgId == null) {
            return null;
        }
        return urlBase + 'query/' + EncodingUtil.urlEncode(orgId, 'UTF-8') + urlParameters + '&dates=format';
    }

    public PageReference gitBackupComplianceScan() {
        hideMessages = true;
        if(!testConnections()) {
            return null;
        }

        if(!FeatureHelper.isFeatureEnabled(COMPLIANCE_HUB)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ': ' + COMPLIANCE_HUB));
            return null;
        }

        if(!LicenseHelper.isCCHEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CCH_LICENSE_NOT_ENABLED));
            return null;
        }

        try {
            DeployAPI.gitBackupComplianceScan(backup.Id);
            ApexPages.getMessages().clear();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.COMPLIANCE_SCAN_REQUESTED));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /**
     * It is used to redirect to the git commit page
     *
     * @return
     */
    public PageReference goToGitCommitPage() {
        if(String.isNotBlank(backup.Git_Snapshot_Permissions__c) && backup.Git_Snapshot_Permissions__c == 'Allow Snapshots Only') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.COMMIT_FILES_NOT_ALLOWED));
            return null;
        }
        PageReference pReference = Page.GitCommitMain;
        pReference.getParameters().put('snapshotId', backup.Id);
        pReference.getParameters().put('variant', 'GitSnapshotCommit');
        pReference.setRedirect(true);
        return pReference;
    }
}