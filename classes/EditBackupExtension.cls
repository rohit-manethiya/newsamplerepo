public with sharing class EditBackupExtension {
    public final String STATIC_RESOURCE = 'StaticResource';

    private List<String> metadataTypes;
    public List<SelectOption> types;
    public List<SelectOption> selectedTypes { get; set; }
    public Git_Backup__c backup { get; set; }
    public List<String> sel { get; set; }
    public boolean showOtherInformation { get; set; }

    public Boolean isStaticResourcesSelected { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public Settings settings { get; set; }

    public EditBackupExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        // NOTE: this will fail i viewGitBackup, since it has the BackupNow.cls loading first)
        try {
            if (!Test.isRunningTest())
                stdController.addFields(new List<String>(Schema.SObjectType.Git_Backup__c.fields.getMap().keySet()));
        } catch (Exception e) {
        }
        settings = new Settings();
        showOptions = true;
        showError = false;
        isStaticResourcesSelected = false;
        selectedTypes = new List<SelectOption>();
        sel = new List<String>();
        isLicenseEnabled();
        if (stdController.getId() != null) {
            backup = Utilities.getGitBackupById(stdController.getId());

            if (backup.Metadata_Types__c != null) {
                for (String t : backup.Metadata_Types__c.split(',')) {
                    selectedTypes.add(new SelectOption(t, t));
                    sel.add(t);

                    if (t == STATIC_RESOURCE) {
                        isStaticResourcesSelected = true;
                    }
                }
            } else {
                isStaticResourcesSelected = true;
            }
            sel.sort();
        } else {
            backup = new Git_Backup__c();
        }
        showOtherInformation = SObjectType.Git_Backup__c.FieldSets.CustomFields.getFields().size() > 0;
    }
    public void init() {
    }
    public void reRender() {
    }
    public List<String> getMetadataTypes() {
        return MetadataTypesHelper.getMetadataTypesByOrgId(backup.Org__c);
    }
    public List<SelectOption> getFrequencyOptions() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Git_Backup__c.Frequency__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    public List<SelectOption> getTypes() {
        return MetadataTypesHelper.getTypeOptionsByOrgId(backup.Org__c, sel);
    }

    public void setTypes(List<SelectOption> l) {
        types = l;
    }

    public PageReference save() {
        try {
            Copado_License__c enabledLicenses = Copado_License__c.getInstance(UserInfo.getUserId());
            if (enabledLicenses.Enable_Copado__c == false && enabledLicenses.Enable_CCM__c == true) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.ONLY_COPADO_ADMIN_GIT_SNAPSHOTS)); //TODO Add to label if releasing
                return null;
            }
            if (
                String.isNotBlank(backup.Frequency__c) &&
                backup.Frequency__c != 'None' &&
                backup.Git_Snapshot_Permissions__c == 'Allow Commits Only'
            ) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.COMMIT_ONLY_SNAPSHOTS_CANNOT_BE_SCHEDULED));
                return null;
            }
            if (LicenseHelper.isLicensesExceeded()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, Label.LICENSES_EXCEEDED));
                return null;
            }
            backup.Metadata_Types__c = MetadataTypesHelper.joinOptions(selectedTypes);
            Utilities.Secure_DML(backup, Utilities.DML_Action.UPS, schema.Sobjecttype.Git_Backup__c);
            if (backup.Id != null) {
                return new Apexpages.StandardController(backup).view();
            }
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, e.getMessage()));
        }
        return null;
    }
    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditGitSnapshot')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }
    /**
     * This method is a helper which refresh the OrgId when the record is new
     * Is a helper for javascript refresh call
     */
    public PageReference orgChanged() {
        //get the new ID
        String OrgId = Apexpages.currentPage().getParameters().get('OrgId');
        //save to controller record
        backup.Org__c = OrgId;
        //refresh MetadataTypes using the new Id
        getMetadataTypes();
        return null;
    }

    public PageReference deleteGitSnapshot() {
        if (String.isNotBlank(backup.Id)) {
            try {
                Utilities.Secure_DML(backup, Utilities.DML_Action.DEL, SObjectType.Git_Backup__c);
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
            DescribeSObjectResult result = Git_Backup__c.SObjectType.getDescribe();
            PageReference snapshotListView = new PageReference('/' + result.getKeyPrefix());
            snapshotListView.setRedirect(true);
            return snapshotListView;
        }
        return null;
    }
}