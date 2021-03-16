public with sharing class snapshotDifferenceExtension {


    public static final Settings settings {
        get {
            if(settings == null) {
                settings = new Settings();
            }
            return settings;
        }
        private set;
    }

    public static final String[] SNAPSHOT_FIELDS = new List<String>{
        'Id',
        'Name',
        'Last_Run__c',
        'Source_Option__c',
        'Destination_Option__c',
        'Source_Git_Commit__c',
        'Destination_Git_Commit__c',
        'Source_Org_Credential__c',
        'Destination_Org_Credential__c'

    };
    private final String INDEX_FILENAME = 'index.json';
    private final String SNAPSHOT_DIFFERENCE = 'Snapshot Difference';
    private final String GIT_COMMIT = 'Git Commit';
    private final String SALESFORCE_ORG = 'Salesforce Org';


    public Boolean isEdit { get; set; }
    public Snapshot_Difference__c snapshot { get; set; }
    public ApexPages.StandardController controller { get; set; }
    public String keyPrefix { 
        get {
            return Git_Org_Commit__c.SObjectType.getDescribe().getKeyPrefix();
        }
    }
    public Boolean isSnapshotEnabled {
        get {
            if(isSnapshotEnabled == null) {
                isSnapshotEnabled = true;
                if (LicenseHelper.isLicensesExceeded()) {
                    isSnapshotEnabled = false;
                    addPageMessage(Apexpages.Severity.ERROR, Label.LICENSES_EXCEEDED);
                } else if(!FeatureHelper.isFeatureEnabled(SNAPSHOT_DIFFERENCE)) {
                    isSnapshotEnabled = false;
                    addPageMessage(Apexpages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED + ' ' + SNAPSHOT_DIFFERENCE);
                }
            }
            return isSnapshotEnabled;
        }
        private set;
    }
    public Boolean isShareable { 
        get {
            return Schema.getGlobalDescribe().containsKey('Snapshot_Difference__Share');
        }
    }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public Id usId { get; set; }
    public User_Story_Task__c us4Lookup {
        get {


            if (us4Lookup == null) {
                us4Lookup = new User_Story_Task__c();
            }
            return us4Lookup;

        }
        set;
    }

    public snapshotDifferenceExtension(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(SNAPSHOT_FIELDS);

            stdController.addFields(new List<String>{ 'Source_Org_Credential__r.Environment__c' });

        }

        showOptions = true;
        showError = false;
        isLicenseEnabled();
        controller = stdController;
        this.snapshot = (Snapshot_Difference__c) stdController.getRecord();

        isEdit = true;
        
        if (String.isNotBlank(this.snapshot.Id)) {
            this.snapshot.Last_Run__c = getLastRunDate();
            isEdit = false;
        }
    }

    private Datetime getLastRunDate() {
        Datetime lastRunDate = getLastModifiedDateFromFile();
        if(lastRunDate == null) {
            lastRunDate = getLastModifiedDateFromAttachment();
        }
        return lastRunDate;
    }

    private Datetime getLastModifiedDateFromFile() {
        Datetime lastModifiedDate;
        try {
            Set<Id> documentIds = new Set<Id>();
            for(ContentDocumentLink link : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :this.snapshot.Id WITH SECURITY_ENFORCED]) {
                documentIds.add(link.ContentDocumentId);
            }
            if(!documentIds.isEmpty()) {
                lastModifiedDate = [SELECT LastModifiedDate FROM ContentVersion WHERE PathOnClient = :INDEX_FILENAME AND ContentDocumentId IN :documentIds AND IsLatest = true LIMIT 1]?.LastModifiedDate;
            }
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights + ': ' + ex.getMessage());
        }
        return lastModifiedDate;
    }

    private Datetime getLastModifiedDateFromAttachment() {
        Datetime lastModifiedDate;


        try {
            lastModifiedDate = [SELECT LastModifiedDate FROM Attachment WHERE ParentId = :this.snapshot.Id AND Name = :INDEX_FILENAME WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 1]?.LastModifiedDate;
        } catch(Exception ex) {
            addPageMessage(ApexPages.Severity.WARNING, ex.getMessage());

        }
        return lastModifiedDate;
    }

    
    public void doRerender() {
        if (snapshot.Destination_Option__c == null) {
            snapshot.Destination_Org_Credential__c = null;
            snapshot.Destination_Git_Commit__c = null;
        }
        if (snapshot.Destination_Option__c == GIT_COMMIT) {
            snapshot.Destination_Org_Credential__c = null;
        }
        if (snapshot.Destination_Option__c == SALESFORCE_ORG) {
            snapshot.Destination_Git_Commit__c = null;
        }
        if (snapshot.Source_Option__c == null) {
            snapshot.Source_Org_Credential__c = null;
            snapshot.Source_Git_Commit__c = null;
        }
        if (snapshot.Source_Option__c == GIT_COMMIT) {
            snapshot.Source_Org_Credential__c = null;
            snapshot.Partial_Selection__c = false;
        }
        if (snapshot.Source_Option__c == SALESFORCE_ORG) {
            snapshot.Source_Git_Commit__c = null;
            snapshot.Partial_Selection__c = false;
        }
    }

    public void edit() {
        isEdit = true;
    }

    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditSnapshotDifferences')) {
            addPageMessage(ApexPages.Severity.WARNING, Label.CCM_License_Restriction);
            showError = true;
            showOptions = false;
        }
        return;
    }

    public PageReference cancel() {
        return controller.cancel();
    }

    public PageReference save() {
        Boolean error = false;
        if (snapshot.Source_Option__c == null || snapshot.Destination_Option__c == null) {
            error = true;
        }
        if ((snapshot.Source_Option__c == SALESFORCE_ORG && snapshot.Source_Org_Credential__c == null) ||
            (snapshot.Destination_Option__c == SALESFORCE_ORG && snapshot.Destination_Org_Credential__c == null)) {
            error = true;


        }
        if ((snapshot.Source_Option__c == GIT_COMMIT && snapshot.Source_Git_Commit__c == null) ||
            (snapshot.Destination_Option__c == GIT_COMMIT && snapshot.Destination_Git_Commit__c == null)) {
            error = true;

        }
        if (error) {
            snapshot.addError(Label.Source_Destination_validation_for_commit);
            return null;
        }

        return controller.save();
    }

    public void checkEnvironment() {
        showError = false;
        Id usOrgId = getUserStoryEnvironmentId();
        if (this.snapshot.Source_Org_Credential__c != null && this.snapshot.Source_Org_Credential__r.Environment__c != usOrgId) {
            showError = true;
            addPageMessage(ApexPages.Severity.WARNING, Label.Environment_selected_US_same_Environment);

        }
    }

    private Id getUserStoryEnvironmentId() {
        Id environmentId;
        try {
            environmentId = [SELECT Environment__c FROM User_Story__c WHERE Id = :us4Lookup.User_Story__c WITH SECURITY_ENFORCED]?.Environment__c;
        } catch(Exception ex) {
            showError = true;
            addPageMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights + ': ' + ex.getMessage());
        }
        return environmentId;
    }


    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}