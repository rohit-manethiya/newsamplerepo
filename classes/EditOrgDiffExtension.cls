public with sharing class EditOrgDiffExtension {
    private final String ORG_DIFFERENCE = 'Org Difference';
    private OrgDiff__c orgdiff;
    private List<String> metadataTypes;
    public List<SelectOption> types;
    public List<SelectOption> selectedTypes { get; set; }
    public List<String> sel { get; set; }
    public Boolean isDiffEnabled { get; set; }
    public String previuosFilterConfig = '';

    public EditOrgDiffExtension(ApexPages.StandardController stdController) {
        try {
            orgdiff = (OrgDiff__c) stdController.getRecord();
            prepareSelectedContext(orgdiff.Metadata_Types__c);
            //save previous filter conbinations in order to know if will be need remove cache when diff is saved
            previuosFilterConfig = makeFilterConfig(orgdiff);
            isDiffEnabled = true;
            if(!FeatureHelper.isFeatureEnabled(ORG_DIFFERENCE)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED + ' ' + ORG_DIFFERENCE));
                isDiffEnabled = false;
            }
            if(LicenseHelper.isLicensesExceeded()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LICENSES_EXCEEDED));
                isDiffEnabled = false;
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
        }
    }
    /**
     * This method is a helper in order to refresh el fromOrgID when the record is new
     * Is a helper for javascript refresh call
     */
    public PageReference fromOrgChanged() {
        try {
            //get the new ID
            String fromOrgId = ApexPages.currentPage().getParameters().get('fromOrgId');
            //save to controller record
            orgdiff.From_Org__c = fromOrgId;
            //refresh MetadataTypes using the new Id
            getMetadataTypes();
            copySelectedMetadataTypesFromOrg(fromOrgId);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
        }
        return null;
    }

    public void copySelectedMetadataTypesFromOrg(String fromOrgId) {
        orgdiff.Metadata_Types__c = MetadataTypesHelper.getMetadataTypesFromOrg(fromOrgId);
        prepareSelectedContext(orgdiff.Metadata_Types__c);
    }

    public List<String> getMetadataTypes() {
        return MetadataTypesHelper.getMetadataTypesByOrgId(orgdiff.From_Org__c);
    }

    public List<SelectOption> getTypes() {
        return MetadataTypesHelper.getTypeOptionsByOrgId(orgdiff.From_Org__c, sel);
    }

    public void setTypes(List<SelectOption> typesList) {
        types = typesList;
    }

    public void prepareSelectedContext(String orgSelectedTypes) {
        selectedTypes = new List<SelectOption>();
        sel = new List<String>();
        if(String.isNotBlank(orgSelectedTypes)) {
            for(String typeStr : orgSelectedTypes.split(',')) {
                selectedTypes.add(new SelectOption(typeStr, typeStr));
                sel.add(typeStr);
            }
        }
        sel.sort();
    }

    public void checkFiltersAndForceCache(OrgDiff__c od) {
        if(makeFilterConfig(od) != previuosFilterConfig) {
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                Utilities.Secure_DML([SELECT Id FROM Attachment WHERE ParentId = :od.Id], Utilities.DML_Action.DEL, Schema.SObjectType.Attachment);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights));
            }
        }
    }

    public String makeFilterConfig(OrgDiff__c od) {
        String res = String.isBlank(od.Metadata_Types__c) ? '' : od.Metadata_Types__c;
        res += String.isBlank(od.From_Org__c) ? '' : od.From_Org__c;
        res += od.To_Date__c == null ? '' : String.valueOf(od.To_Date__c);
        res += od.From_Date__c == null ? '' : String.valueOf(od.From_Date__c);
        res += String.isBlank(od.Last_Modified_By_Name__c) ? '' : od.Last_Modified_By_Name__c;

        return res ;
    }

    public PageReference save() {
        if(!FeatureHelper.isFeatureEnabled(ORG_DIFFERENCE)) {
            ApexPages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ': ' + ORG_DIFFERENCE));
            return null;
        }

        if(!LicenseHelper.isCopadoEnabled()) {
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED + ': ' + ORG_DIFFERENCE));
            return null;
        }
        if(LicenseHelper.isLicensesExceeded()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LICENSES_EXCEEDED));
            return null;
        }

        orgdiff.Metadata_Types__c = MetadataTypesHelper.joinOptions(selectedTypes);

        //TODO: if new selected types are not in org from it should trigger and error. 

        //TODO: this logic should be moved to trigger on new version
        checkFiltersAndForceCache(orgdiff);
        Utilities.Secure_DML(orgdiff, Utilities.DML_Action.UPS, Schema.SObjectType.OrgDiff__c);
        return new Apexpages.StandardController(orgdiff).view();
    }
}