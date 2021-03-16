public with sharing class ADD_DependencyHandler {
    public static Integer counter = 0;
    public static List<RelationshipDiagramWrapper> relationshipDiagramWrappers { get; set; }
    public static RelationshipDiagramResultWrapper relationshipDiagramResultWrappers { get; set; }

    /**
     * Checking the namespace of context
     * @return String value of namespace
     */
    @AuraEnabled
    public static String getNamespace() {
        return ADD_DependencyHandler.class.getName().substringBefore('ADD_DependencyHandler').removeEnd('.').toLowerCase();
    }

    /**
     * Getting attachment for main template and finding the relations. The method works recursive until there is no child or parent relations left
     * The maximum limit of relation is 15. So it will not hit the too many SOQL
     * @param templateIdsList first iteration only contains the main template id, then relation template ids
     * @return JSON value of populated RelationshipDiagramResultWrapper
     * @see RelationshipDiagramResultWrapper
     */
    @AuraEnabled
    public static String getMainTemplateAttachment(List<String> templateIdsList) {
        try {
            if (relationshipDiagramResultWrappers == null) {
                relationshipDiagramResultWrappers = new RelationshipDiagramResultWrapper();
            }
            if (relationshipDiagramWrappers == null) {
                relationshipDiagramWrappers = new List<RelationshipDiagramWrapper>();
            }

            List<Attachment> templateAttachments = new List<Attachment>();
            templateAttachments = [
                SELECT Id, Name, Body
                FROM Attachment
                WHERE ParentId = :templateIdsList AND Name = 'Template Detail'
                WITH SECURITY_ENFORCED
            ];

            List<String> relatedTemplateIds = new List<String>();

            if (!templateAttachments.isEmpty()) {
                for (Attachment att : templateAttachments) {
                    String body = att.Body.toString();
                    TemplateObjectWrapper dummyWrapper = (TemplateObjectWrapper) JSON.deserialize(body, TemplateObjectWrapper.class);
                    RelationshipDiagramWrapper rdw = new RelationshipDiagramWrapper();
                    rdw.dataTemplateId = dummyWrapper.dataTemplate.templateId;
                    rdw.dataTemplateName = dummyWrapper.dataTemplate.templateName;
                    rdw.templateMainObject = dummyWrapper.dataTemplate.templateMainObject;
                    rdw.templateAttachmentOption = dummyWrapper.dataTemplate.templateAttachmentOption;
                    rdw.queryFilterList = dummyWrapper.queryFilterList;
                    rdw.isMainTemplate = counter == 0;

                    List<EdgesWrapper> edgeWrappers = new List<EdgesWrapper>();

                    if (!dummyWrapper.parentObjectsReferenceList.isEmpty()) {
                        for (RelationTemplateDetails std : dummyWrapper.parentObjectsReferenceList) {
                            EdgesWrapper ew = new EdgesWrapper();
                            ew.fromTemplateId = dummyWrapper.dataTemplate.templateId;
                            ew.toTemplateId = std.templateId;
                            ew.relationshipType = 'parent';

                            edgeWrappers.add(ew);

                            relatedTemplateIds.add(std.templateId);
                        }
                    }

                    if (!dummyWrapper.childrenObjectsReferenceList.isEmpty()) {
                        for (RelationTemplateDetails std : dummyWrapper.childrenObjectsReferenceList) {
                            EdgesWrapper ew = new EdgesWrapper();
                            ew.fromTemplateId = dummyWrapper.dataTemplate.templateId;
                            ew.toTemplateId = std.templateId;
                            ew.relationshipType = 'child';

                            edgeWrappers.add(ew);

                            relatedTemplateIds.add(std.templateId);
                        }
                    }

                    rdw.edges = edgeWrappers;
                    relationshipDiagramWrappers.add(rdw);
                }

                if (!relatedTemplateIds.isEmpty()) {
                    counter++;
                    getMainTemplateAttachment(relatedTemplateIds);
                }
            }
        } catch (System.QueryException exceptions) {
            return populateResultWrapperParameter('Error', exceptions.getMessage());
        } catch (Exception exceptions) {
            return populateResultWrapperParameter('Error', exceptions.getMessage());
        }

        return populateResultWrapperParameter('Success', '');
    }

    /**
     * @see getMainTemplateAttachment
     */
    private static String populateResultWrapperParameter(String status, String message) {
        relationshipDiagramResultWrappers.processStatus = status;
        relationshipDiagramResultWrappers.processMessage = message;
        relationshipDiagramResultWrappers.relationshipDiagramWrappers = relationshipDiagramWrappers;
        return JSON.serialize(relationshipDiagramResultWrappers);
    }

    /**
     * It is used to store all information to return values to the LWC
     */
    public class RelationshipDiagramResultWrapper {
        @AuraEnabled
        public String processStatus { get; set; }
        @AuraEnabled
        public String processMessage { get; set; }
        @AuraEnabled
        public List<RelationshipDiagramWrapper> relationshipDiagramWrappers { get; set; }
    }

    /**
     * It is used to store all information related to relationship diagram
     */
    public class RelationshipDiagramWrapper {
        @AuraEnabled
        public String dataTemplateId { get; set; }
        @AuraEnabled
        public String dataTemplateName { get; set; }
        @AuraEnabled
        public String templateMainObject { get; set; }
        @AuraEnabled
        public Boolean isMainTemplate { get; set; }
        @AuraEnabled
        public List<EdgesWrapper> edges { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
        @AuraEnabled
        public String templateAttachmentOption { get; set; }
        @AuraEnabled
        public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }
    }

    /**
     * It is used to store all information related to edges between relationship diagram
     */
    public class EdgesWrapper {
        @AuraEnabled
        public String fromTemplateId { get; set; }
        @AuraEnabled
        public String toTemplateId { get; set; }
        @AuraEnabled
        public String relationshipType { get; set; }
    }

    /**
     * It is used to store all information related to template
     */
    public class TemplateObjectWrapper {
        @AuraEnabled
        public DataTemplateDetails dataTemplate { get; set; }
        @AuraEnabled
        public List<RelationTemplateDetails> parentObjectsReferenceList { get; set; }
        @AuraEnabled
        public List<RelationTemplateDetails> childrenObjectsReferenceList { get; set; }
        @AuraEnabled
        public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }
    }

    /**
     * If we create a new field on Data Template object, we need to create a parameter to store that value for export and reload
     */
    public class DataTemplateDetails {
        @AuraEnabled
        public String templateId { get; set; }
        @AuraEnabled
        public String templateName { get; set; }
        @AuraEnabled
        public String templateMainObject { get; set; }
        @AuraEnabled
        public String templateAttachmentOption { get; set; }
    }

    public class RelationTemplateDetails {
        @AuraEnabled
        public String templateId { get; set; }
    }
}