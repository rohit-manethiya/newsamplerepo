public with sharing class UserStoryApexTestResultsExtension {

    private final User_Story__c userStory;
    public String attId { get; set; }
    public Boolean hasAttachment { get; set; }
    public static final String[] USERSTORY_FIELDS = new String[]{
            'Id', 'Name', 'Org_Credential__c', 'Org_Credential__r.Error__c', 'Org_Credential__r.Validated_Date__c', 'Minimum_Apex_Code_Coverage__c', 'Has_Apex_Code__c',
            'User_Story_Title__c', 'Project__c', 'Release__c', 'Developer__c', 'Status__c', 'Progress__c'
    };

    public UserStoryApexTestResultsExtension(ApexPages.StandardController stdController) { 
        hasAttachment = false;
        if (!Test.isRunningTest()) {
            stdController.addFields(USERSTORY_FIELDS);
        }
        this.userStory = (User_Story__c) stdController.getRecord();

        if (userStory.Org_Credential__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.User_Story_Do_Not_Have_Org_Credential));
            return;
        }

        getAttachment();

        if (String.isNotBlank(userStory.Org_Credential__r.Error__c) || userStory.Org_Credential__r.Validated_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.Org_Is_Not_Valid));
        }
        if (!hasAttachment) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ' ' + Label.User_Story_Has_No_Apex_Test_Result));
        }
    }

    public void getAttachment() {
        List<Apex_Test_Result__c> res = new List<Apex_Test_Result__c>();
        if(Schema.SObjectType.Apex_Test_Result__c.isQueryable() && Schema.SObjectType.Apex_Test_Result__c.isAccessible()) {
            res = [SELECT Id FROM Apex_Test_Result__c WHERE Org__c = :userStory.Org_Credential__c ORDER BY CreatedDate DESC LIMIT 1];
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Apex_Test_Result__c.getName() +': ' + Label.Insufficient_Access_Rights));
            return;
        }
        if (!res.isEmpty()) {
            List<Attachment> atts = new List<Attachment>();
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                atts = [SELECT Id FROM Attachment WHERE Name = 'ApexTestResult' AND ParentId = :res.get(0).Id ORDER BY LastModifiedDate DESC];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Attachment.getName() +': ' + Label.Insufficient_Access_Rights));
                return;
            }
            if (!atts.isEmpty()) {
                this.hasAttachment = true;
                attId = atts.get(0).Id;
            }
        }
    }

    /**
     * It is used to redirect to the user story waiting for page
     * Note: it will only work for user story for now
     * @return
     */
    public PageReference goToWaitingForPage(){
        String testClassList = ApexPages.currentPage().getParameters().get('testClassList');
        String testClassNS = ApexPages.currentPage().getParameters().get('testClassNamespace');
        PageReference preference = Page.UserStoryPageWaitingFor;
        preference.getParameters().put('id',userStory.Id);
        preference.getParameters().put('type','co_apexTestRun');
        preference.getParameters().put('testClassNamespace',testClassNS);
        preference.getParameters().put('testClassList',testClassList);
        preference.setRedirect(true);
        return preference;
    }
}