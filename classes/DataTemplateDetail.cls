public with sharing class DataTemplateDetail {
    public static final String ATTACHMENT_NAME = 'Template Detail';

    public DataTemplateDetails dataTemplate { get; set; }
    public List<RelationTemplateDetails> parentObjectsReferenceList { get; set; }
    public List<RelationTemplateDetails> childrenObjectsReferenceList { get; set; }
    public Map<String, CopadoSelectedField> selectableFieldsMap { get; set; }
    public Map<String, CopadoSelectedChildRelationship> selectableChildRelationsMap { get; set; }
    public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }

    public DataTemplateDetail() {
        this.dataTemplate = new DataTemplateDetails();
        this.parentObjectsReferenceList = new List<RelationTemplateDetails>();
        this.childrenObjectsReferenceList = new List<RelationTemplateDetails>();
        this.selectableFieldsMap = new Map<String, CopadoSelectedField>();
        this.selectableChildRelationsMap = new Map<String, CopadoSelectedChildRelationship>();
        this.queryFilterList = new List<QueryEditor.CriteriaWrapper>();
    }

    public class DataTemplateDetails {
        public String templateId { get; set; }
        public String templateName { get; set; }
        public String templateSourceOrg { get; set; }
        public String templateMainObject { get; set; }
        public Boolean templateMatchOwners { get; set; }
        public Boolean templateMatchRecordTypes { get; set; }
        public String templateContinueOnError { get; set; }
        public Boolean templateActive { get; set; }
        public String templateDescription { get; set; }
        public String templateAttachmentOption { get; set; }
        public String templateFilterLogic { get; set; }
        public Decimal templateBatchSize { get; set; }
        public Decimal templateQueryLimit { get; set; }
        public String templateSelectedAttachmentType { get; set; }
    }

    public class RelationTemplateDetails {
        public String templateId { get; set; }
        public String relationName { get; set; }
        public String childSObject { get; set; }

        public RelationTemplateDetails() {
            this.templateId = '';
            this.relationName = '';
            this.childSObject = '';
        }
    }

    public class CopadoField {
        public Boolean autonumber { get; set; }
        public Boolean calculated { get; set; }
        public Boolean externalId { get; set; }
        public Boolean filterable { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public Boolean nillable { get; set; }
        public String relationshipName { get; set; }
        public List<String> referenceTo { get; set; }
        public String type { get; set; }
        public Boolean unique { get; set; }
        public Double replaceValueNumber { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
        public Date replaceValueDate { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
        public Datetime replaceValueDatetime { get; set; } // TODO this is a known salesforce issue, we can not get the numeric value from map in visualforce page
    }

    public class CopadoSelectedField {
        public Boolean isSelected { get; set; }
        public Boolean useAsExternalId { get; set; }
        public Boolean externalId { get; set; }
        public String label { get; set; }
        public String name { get; set; }
        public String fieldType { get; set; }
        public Map<String, String> parentObjectApiNameMap { get; set; }
        public Map<String, String> contentValueUpdateValues { get; set; }
        public String fieldContentUpdate { get; set; }
        public String replaceValue { get; set; }
        public Double replaceValueNumber { get; set; }
        public Date replaceValueDate { get; set; }
        public Datetime replaceValueDatetime { get; set; }
        public Map<String, String> deploymentTemplateNameMap { get; set; }
        public String deploymentTemplate { get; set; }

        public CopadoSelectedField() {
            this.isSelected = true;
            this.useAsExternalId = false;
            this.externalId = false;
            this.label = '';
            this.name = '';
            this.fieldType = '';
            this.parentObjectApiNameMap = new Map<String, String>();
            this.contentValueUpdateValues = new Map<String, String>();
            this.fieldContentUpdate = '';
            this.replaceValue = '';
            this.replaceValueNumber = 0;
            this.replaceValueDate = System.today();
            this.replaceValueDatetime = null;
            this.deploymentTemplateNameMap = null;
            this.deploymentTemplate = System.Label.Select_Template;
        }
    }

    public class CopadoSelectedChildRelationship {
        public Boolean isSelected { get; set; }
        public String childSObject { get; set; }
        public String field { get; set; }
        public String relationshipName { get; set; }
        public Map<String, String> objectApiNameMap { get; set; }
        public Map<String, String> deploymentTemplateNameMap { get; set; }
        public String deploymentTemplate { get; set; }

        public CopadoSelectedChildRelationship() {
            this.isSelected = false;
            this.childSObject = '';
            this.field = '';
            this.relationshipName = '';
            this.objectApiNameMap = new Map<String, String>();
            this.deploymentTemplateNameMap = null;
            this.deploymentTemplate = System.Label.Select_Template;
        }
    }
}