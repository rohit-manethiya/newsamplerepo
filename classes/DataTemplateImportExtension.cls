/**
 * It is main extension of DataTemplateImport page
 */
public with sharing class DataTemplateImportExtension {
    // Non Constants
    public Data_Template__c template { get; set; }
    public List<Data_Template__c> importedTemplateList { get; set; }
    public List<TemplateInformation> templateInformationList { get; set; }
    public Map<String, List<Object>> pageMessagesMap { get; set; }
    private Settings sttng;
    private List<String> templateIdList;

    // Constants
    private final String C_ERROR = 'error';
    private final String C_WARNING = 'warning';
    private final String UTF_8 = 'UTF-8';
    private final String C_ORGANIZATION = 'organization/';
    private final String C_METADATA = '/metadata/';

    /**
     * The extension constructor initializes the public template member
     *
     * @param stdController
     */
    public DataTemplateImportExtension(ApexPages.StandardSetController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Data_Template__c.fields.getMap().keySet()));
        }
        this.template = (Data_Template__c) stdController.getRecord();
        importedTemplateList = new List<Data_Template__c>();
        templateIdList = new List<String>();
        sttng = new Settings();
        templateInformationList = new List<TemplateInformation>();
        pageMessagesMap = new Map<String, List<Object>>();
    }

    /**
     * It is used to check necessary fields before validation process
     */
    public void checkValidationCondition() {
        pageMessagesMap.clear();
        if (template.Template_Source_Org__c == null) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ Label.Select_Source_Org });
        }
    }

    /**
     * It is used to check necessary fields before validation process
     */
    public void listImportedTemplates() {
        pageMessagesMap.clear();
        String templateIds = ApexPages.currentPage().getParameters().get('templateIds');
        if (String.isNotBlank(templateIds)) {
            List<String> tempIdsList = templateIds.split(',');
            templateIdList.addAll(tempIdsList);

            if (Schema.SObjectType.Data_Template__c.isAccessible() && Schema.SObjectType.Data_Template__c.isQueryable()) {
                importedTemplateList = [SELECT Id, Name, Template_Source_Org__c, Active__c FROM Data_Template__c WHERE Id IN :templateIdList];
            } else {
                pageMessagesMap.put(
                    C_WARNING,
                    new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Data_Template__c.getLabel() }
                );
            }
        }
    }

    /**
     * It is used to parse the response that is imported
     *
     * @param stringValue
     */
    public void parseImportedFile() {
        String stringValue = ApexPages.currentPage().getParameters().get('jsonValue');

        try {
            if (String.isNotBlank(stringValue)) {
                templateInformationList = (List<TemplateInformation>) JSON.deserialize(stringValue, List<TemplateInformation>.class);
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return;
        }
    }

    /**
     * It is used to format the size of template will be inserted
     *
     * @return
     */
    public String getTextMessage() {
        String strValue = String.format(Label.Records_Will_Be_Created, new List<String>{ String.valueOf(templateInformationList.size()) });
        return strValue;
    }

    /**
     * It is used to return endpoint for org describeGlobal callout
     *
     * @return
     */
    public String getOrgCalloutEndpoint() {
        return String.isNotBlank(template.Template_Source_Org__c)
            ? sttng.urlBase + C_ORGANIZATION + EncodingUtil.urlEncode(template.Template_Source_Org__c, UTF_8) + C_METADATA + 'describeGlobal'
            : '';
    }

    /**
     * It is used to return endpoint for object describe callout
     *
     * @return
     */
    public String getObjectDescribeCalloutEndpoint() {
        return String.isNotBlank(template.Template_Source_Org__c)
            ? sttng.urlBase +
                C_ORGANIZATION +
                EncodingUtil.urlEncode(template.Template_Source_Org__c, UTF_8) +
                C_METADATA +
                'copado_objName' +
                '/describe'
            : '';
    }

    /**
     * It is used to return total list item size for all map key values to render spinner on the page
     *
     * @return
     */
    public Integer getPageMessageSize() {
        return messagesSize(pageMessagesMap);
    }

    /**
     * It is used to update data templates and go to the list view of Data Template object
     *
     * @return
     */
    public PageReference finishImportAndClose() {
        try {
            Utilities.Secure_DML(importedTemplateList, Utilities.DML_Action.UPD, schema.SObjectType.Data_Template__c);

            Schema.DescribeSObjectResult result = Data_Template__c.SObjectType.getDescribe();
            PageReference pageRef = new PageReference('/' + result.getKeyPrefix());
            pageRef.setRedirect(true);
            return pageRef;
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
            return null;
        }
    }

    /**
     * It is used to redirect user to relation template in a new tab
     */
    public PageReference openRelationTemplate() {
        String relTemplateId = ApexPages.currentPage().getParameters().get('relTemplateId');
        Id relationTemplateId = null;
        PageReference pReference = null;
        if (String.isNotBlank(relTemplateId)) {
            relationTemplateId = relTemplateId;
            pReference = new ApexPages.StandardController(relationTemplateId.getSobjectType().newSObject(relationTemplateId)).view();
            pReference.setRedirect(true);
        }
        return pReference;
    }

    /**
     * It is used to count total messages size in the map
     *
     * @param messageMap
     *
     * @return
     */
    private Integer messagesSize(Map<String, List<Object>> messageMap) {
        Integer listSize = 0;
        if (messageMap != null) {
            for (String severity : messageMap.keySet()) {
                listSize += messageMap.get(severity).size();
            }
        }
        return listSize;
    }

    /**
     * It is used to show error message during JS callouts and dmls
     */
    public void populateErrorMessages() {
        pageMessagesMap.clear();
        String errorString = ApexPages.currentPage().getParameters().get('errorString');
        pageMessagesMap.put(C_ERROR, new List<Object>{ errorString });
    }

    /**
     * It is used to populate necessary data for org callout
     *
     * @return
     */
    public String getOrgCalloutDataJSON() {
        ObjectCalloutData ocd = new ObjectCalloutData();
        ocd.sourceOrgId = template.Template_Source_Org__c;
        ocd.userId = UserInfo.getUserId();
        ocd.organizationId = UserInfo.getOrganizationId();
        ocd.token = DeployAPI.getAuthToken();
        ocd.orgCalloutEndpoint = getOrgCalloutEndpoint();
        ocd.objectCalloutEndpoint = getObjectDescribeCalloutEndpoint();
        ocd.namespace = Settings.ns;
        ocd.isActiveTemplate = template.Active__c;
        return JSON.serialize(ocd);
    }

    public class TemplateInformation {
        public String templateUUId { get; set; }
        public Values values { get; set; }
    }

    public class Values {
        public DataTemplate dataTemplate { get; set; }
        public Content content { get; set; }
        public List<RelationTemplateDetails> relationList { get; set; }
    }

    public class DataTemplate {
        public String templateName { get; set; }
        public String encodedTemplateName {
            get {
                if (null != templateName) {
                    encodedTemplateName = templateName.replaceAll('[^a-zA-Z0-9]', '');
                }
                return encodedTemplateName;
            }
            set;
        }
        public String templateMainObject { get; set; }
        public String templateDescription { get; set; }
        public Boolean templateMatchOwners { get; set; }
        public Boolean templateMatchRecordTypes { get; set; }
        public String templateAttachmentOption { get; set; }
        public String templateContinueOnError { get; set; }
        public Decimal templateBatchSize { get; set; }
        public Decimal templateQueryLimit { get; set; }
    }

    public class Content {
        public List<ObjectFields> objectFields { get; set; }
        public List<ObjectFields> parentFields { get; set; }
        public List<ChildObjects> childObjects { get; set; }
    }

    public class RelationTemplateDetails {
        public String templateId { get; set; }
        public String relationName { get; set; }
    }

    public class ObjectFields {
        public String name { get; set; }
        public String apiName { get; set; }
    }

    public class ChildObjects {
        public String field { get; set; }
        public String relationshipName { get; set; }
        public String childSObject { get; set; }
        public String childSObjectLabel { get; set; }
    }

    public class ObjectCalloutData {
        public String sourceOrgId { get; set; }
        public String userId { get; set; }
        public String organizationId { get; set; }
        public String token { get; set; }
        public String orgCalloutEndpoint { get; set; }
        public String objectCalloutEndpoint { get; set; }
        public String namespace { get; set; }
        public Boolean isActiveTemplate { get; set; }
    }
}