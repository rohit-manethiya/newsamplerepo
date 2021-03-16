public with sharing class MetadataselectorExtension {
    public User_Story__c userStory { get; set; }
    public ApexPages.StandardController controller { get; set; }
    public Boolean hasOrg { get; set; }
    public Boolean hasError { get; set; }
    public String mode { get; set; }
    public String metadata_url { get; set; }
    public Settings settings { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }

    public static final String[] USERSTORY_FIELDS = new String[]{
            'Id', 'Name', 'Org_Credential__c', 'User_Story_Title__c', 'Project__c', 'Release__c', 'Developer__c', 'Status__c', 'Progress__c'
    };

    public MetadataselectorExtension(ApexPages.StandardController stdController) {
        settings = new Settings();
        hasOrg = false;
        hasError = false;
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        mode = ApexPages.currentPage().getParameters().get('mode');
        mode = (mode == 'ApexTests' || mode == 'Metadata') ? mode : '';
        controller = stdController;
        if(!Test.isRunningTest()) {
            stdController.addFields(USERSTORY_FIELDS);
        }
        this.userStory = (User_Story__c) stdController.getRecord();
        if(userStory.Org_Credential__c != null) {
            Org__c org = Utilities.getOrgById(userStory.Org_Credential__c);

            hasOrg = true;
            String filter = (mode == 'ApexTests') ? '&filter=' + mode : '';
            String urlParameters = '?userStoryId=' + userStory.Id + filter;
            String herokuServer = settings.herokuServer;
            String urlBase = herokuServer + '/json/v1/';
            metadata_url = urlBase + 'metadata/' + EncodingUtil.urlEncode(userStory.Org_Credential__c, 'UTF-8') + urlParameters + '&dates=format&parentId=' + EncodingUtil.urlEncode(userStory.Org_Credential__c, 'UTF-8');
            if(String.isNotBlank(org.Metadata_Types__c)) {
                metadata_url += '&filter=' + EncodingUtil.urlEncode(org.Metadata_Types__c, 'UTF-8');
            }
            if(mode == 'ApexTests') {
                metadata_url = urlBase + 'testClasses/' + EncodingUtil.urlEncode(userStory.Org_Credential__c, 'UTF-8') + urlParameters;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NO_ORG_CREDENTIAL_ON_USER_STORY));
            hasError = true;
        }
    }
    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('selectMetadata')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }

    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public String errorLevel { get; set; }
    public String messageName { get; set; }
    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.WARNING;
        } else {
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
    }

    public PageReference openAddTestClass() {
        PageReference pr = Page.AddTestClasses;
        if(String.isNotBlank(userStory.Id) && String.isNotBlank(userStory.Org_Credential__c)) {
            pr.getParameters().put('id', userStory.Id);
        }
        pr.setRedirect(true);
        return pr;
    }
}