/**
 * Controller for Data Template Object Result page
 */
public with sharing class DataTemplateObjectResultController {
    public String sourceTargetUrlMap { get; set; }
    public String templateName { get; set; }
    public String csvAttachmentId { get; set; }
    public String attachmentName { get; set; }
    public String deploymentId { get; set; }

    public DataTemplateObjectResultController() {
        if(!Schema.SObjectType.Deployment__c.isAccessible() && !Schema.SObjectType.Deployment__c.isQueryable()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment__c.getName());
            return;
        }
        if(!Schema.SObjectType.Destination_Org__c.isAccessible() && !Schema.SObjectType.Destination_Org__c.isQueryable()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Destination_Org__c.getName());
            return;
        }
        Map<String, String> dtoResultsParameters = ApexPages.currentPage().getParameters();

        templateName = dtoResultsParameters.get('templateName');
        deploymentId = dtoResultsParameters.get('deploymentId');
        String stepId = dtoResultsParameters.get('stepId');
        String templateId = dtoResultsParameters.get('templateId');
        String sourceDomain = dtoResultsParameters.get('sourceDomain');
        String targetDomain = dtoResultsParameters.get('targetDomain');

        if(String.isNotBlank(stepId) && String.isNotBlank(templateName) && String.isNotBlank(templateId) && String.isNotBlank(deploymentId)) {
            attachmentName = stepId + '_' + templateName + '_' + templateId;
            List<Attachment> csvAttachmentList = [SELECT Id FROM Attachment WHERE Name =:attachmentName + '.csv'];
            if(!csvAttachmentList.isEmpty()) {
                csvAttachmentId = csvAttachmentList[0].Id;
            }
            sourceTargetUrlMap = resolveSourceTargetDomains(sourceDomain, targetDomain);
        }
    }
    /**
     * Resolves source and target domains depending if source and domains comes null
     * @param sourceDomain
     * @param targetDomain
     *
     * @return map sourceTargetUrlMap
     */
    private String resolveSourceTargetDomains(String sourceDomain, String targetDomain) {
        Map<String, String> sourceTargetUrl = new Map<String, String>();
        String sourceURL = sourceDomain;
        String destinationURL = targetDomain;
        if(String.isBlank(sourceURL) || String.isBlank(destinationURL)) {
            List<Deployment__c> sourceTargetList = [SELECT Id, Name, From_Org__c, From_Org__r.Org_Type__c, From_Org__r.Custom_Domain__c, (SELECT To_Org__c,To_Org__r.Org_Type__c ,To_Org__r.Custom_Domain__c FROM Destination_Orgs__r) FROM Deployment__c WHERE Id = :deploymentId LIMIT 1];
            if(!sourceTargetList.isEmpty()) {
                sourceURL = sourceTargetURL(sourceTargetList[0].From_Org__r.Custom_Domain__c, sourceTargetList[0].From_Org__r.Org_Type__c);
                destinationURL = sourceTargetURL(sourceTargetList[0].Destination_Orgs__r[0].To_Org__r.Custom_Domain__c, sourceTargetList[0].Destination_Orgs__r[0].To_Org__r.Org_Type__c);
            }
        }
        sourceTargetUrl.put('source', sourceURL);
        sourceTargetUrl.put('target', destinationURL);

        return JSON.serialize(sourceTargetUrl);
    }
    /**
     * This method return the pot for source or target environment. If Custom_Domain__c is blank, returns production or test Salesforce base url
     * @param customDomain
     * @param orgType
     *
     * @return pot base url
     */
    private String sourceTargetURL(String customDomain, String orgType) {
        return String.isBlank(customDomain) ? orgType == 'Production/Developer' ? 'https://login.salesforce.com/' : 'https://test.salesforce.com/' : customDomain;
    }
}