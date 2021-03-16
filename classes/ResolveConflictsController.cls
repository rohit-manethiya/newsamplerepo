/**
 * Resolve Conflicts Controller
 * Allows users to mark conflicted files in a promotion as AUTO RESOLVED or RESOLVED
 * When marked as AUTO RESOLVED, the Copado backend will auto resolve the component.
 * When marked as RESOLVED, the Copado backend will merge the file as it was saved by the user.
 * @see ResolveConflicts.page
 * @version 1.0
 * @author David VENEGAS
 *
 */
public with sharing class ResolveConflictsController {
    public String preDefinedAttSource { get; set; }
    public String preDefinedAttTarget { get; set; }
    public Promotion__c promotion { get; set; }
    public List<Attachment> attachments = new List<Attachment>();
    public Attachment attachmentToResolve { get; set; }
    public Boolean goToPromotion { get; set; }
    public Boolean showHeader { get; set; }
    public Boolean disableAutoResolve {
        get {
            Personal_Settings__c settings = Personal_Settings__c.getInstance();
            return settings != null ? settings.Disable_Auto_Resolve__c : false;
        }
    }
    public String namespace { get; set; }
    public List<String> outOfPromotionMetadataAttachmentIds { get; set; }
    public String excludedMetadataAttachmentIds {
        get {
            if (String.isBlank(excludedMetadataAttachmentIds) && null != outOfPromotionMetadataAttachmentIds) {
                excludedMetadataAttachmentIds = String.join(outOfPromotionMetadataAttachmentIds, ',');
            }
            return excludedMetadataAttachmentIds;
        }
        set;
    }

    /**
     * constructor
     * @return [description]
     */
    public ResolveConflictsController() {
        attachments = new List<Attachment>();
        attachmentToResolve = null;
        goToPromotion = false;
        namespace = Settings.ns;
        outOfPromotionMetadataAttachmentIds = new List<String>();

        // Get URL promotionId parameter
        String promotionId = ApexPages.currentPage().getParameters().get('promotionId');
        if (String.isBlank(promotionId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_NO_PROMOTION));
            return;
        }
        // get promotion values
        try {
            String query = 'SELECT ';
            for (Schema.FieldSetMember field : this.getHeaderFields()) {
                String fieldPath = field.getFieldPath();
                if (fieldPath != 'Name') {
                    query += fieldPath + ', ';
                }
            }
            query += ' Name FROM Promotion__c WHERE Id =:promotionId WITH SECURITY_ENFORCED LIMIT 1';
            promotion = Database.query(query);
        } catch (Exception excp) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, excp.getMessage()));
        }
    }

    public List<Schema.FieldSetMember> getHeaderFields() {
        List<Schema.FieldSetMember> fields = SObjectType.Promotion__c.FieldSets.Copado_Header_Fields.getFields();
        return fields;
    }

    /**
     *  Called by an apex:repeat in the page.
     */
    public List<Attachment> getAttachments() {
        if (promotion == null || !attachments.isEmpty()) {
            return attachments;
        }
        try {
            attachments = [
                SELECT Id, Name, ParentId
                FROM Attachment
                WHERE ParentId = :promotion.Id AND (Name LIKE 'AUTO RESOLVED%' OR Name LIKE 'RESOLVED%' OR NAME LIKE 'US-%')
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate
                LIMIT 1000
            ];
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }
        promotionMetadataProcess();
        return attachments;
    }

    /*
     *  Selects an attachment from the list and saves it in the attachmentToResolve variable
     *  The attachmentToResolve variable is used by the CodeMirror text editor
     */
    public void openAttachment() {
        String attIndex = Apexpages.currentPage().getParameters().get('attIndex');
        if (attIndex != null && attachments[Integer.valueOf(attIndex)] != null) {
            attachmentToResolve = attachments[Integer.valueOf(attIndex)];
        }
    }

    /**
     * Getting user story metadatas included in the promotion record to find which attachments are related to promotion
     */
    private void promotionMetadataProcess() {
        Set<String> metadataNames = getUserStoryMetadatas();
        List<Attachment> promotionMetadataAttachments = new List<Attachment>();
        List<Attachment> outOfPromotionMetadataAttachments = new List<Attachment>();
        Set<Id> promotionMetadataAttachmentIds = new Set<Id>();
        for (String metadataItem : metadataNames) {
            String metadataName = metadataItem.substring(metadataItem.indexOf('.') + 1);
            for (Integer i = 0; i < attachments.size(); i++) {
                if (attachments[i].Name.toLowerCase().contains(metadataName.toLowerCase()) && !promotionMetadataAttachmentIds.contains(attachments[i].Id)) {
                    promotionMetadataAttachments.add(attachments[i]);
                    promotionMetadataAttachmentIds.add(attachments[i].Id);
                }
            }
        }

        for (Integer i = 0; i < attachments.size(); i++) {
            if (!promotionMetadataAttachmentIds.contains(attachments[i].Id)) {
                populateAttachmentName(i);
                outOfPromotionMetadataAttachments.add(attachments[i]);
                outOfPromotionMetadataAttachmentIds.add(attachments[i].Id);
            }
        }

        attachments.clear();
        if (!promotionMetadataAttachments.isEmpty()) {
            attachments.addAll(promotionMetadataAttachments);
        }

        if (!outOfPromotionMetadataAttachments.isEmpty()) {
            attachments.addAll(outOfPromotionMetadataAttachments);
        }
    }

    /**
     * Populate attachment name after resolve and auto resolve
     */
    private Attachment populateAttachmentName(Integer attachmentIndex) {
        Attachment attachmentRecord = attachments[attachmentIndex];

        if (attachmentRecord.Name.startsWith('RESOLVED')) {
            attachmentRecord.Name = attachmentRecord.Name.replace('RESOLVED', 'AUTO RESOLVED');
        } else if (!attachmentRecord.Name.startsWith('AUTO RESOLVED')) {
            attachmentRecord.Name = 'AUTO RESOLVED ' + attachmentRecord.Name;
        }
        if (!Schema.sObjectType.Attachment.fields.Name.isUpdateable() || !Schema.sObjectType.Attachment.fields.Name.isCreateable()) {
            return null;
        }
        attachments.set(attachmentIndex, attachmentRecord);
        return attachmentRecord;
    }

    /**
     * Update attachments
     */
    private void updateAttachments(List<Attachment> updatedAttachments) {
        Utilities.Secure_DML(updatedAttachments, Utilities.DML_Action.UPS, Schema.Sobjecttype.Attachment);
    }

    /**
     *  Updates the attachment name to start with "AUTO RESOLVED"
     */
    public void saveAutoResolveAttachment() {
        String attachmentIndex = Apexpages.currentPage().getParameters().get('attIndex');
        Boolean isResolved = true;

        if (attachmentIndex != null && Integer.valueOf(attachmentIndex) != null) {
            Attachment updatedAttachment = populateAttachmentName(Integer.valueOf(attachmentIndex));
            if (updatedAttachment != null) {
                updateAttachments(new List<Attachment>{ updatedAttachment });
                for (Attachment attachmentRecord : attachments) {
                    if (attachmentRecord.Name.startsWith('US-')) {
                        isResolved = false;
                        break;
                    }
                }
                if (isResolved) {
                    updatePromotionAsResolved();
                }
            }
        }
    }

    public void updatePromotionAsResolved() {
        promotion.Status__c = 'Conflicts Resolved';
        Utilities.Secure_DML(promotion, Utilities.DML_Action.UPD, schema.Sobjecttype.Promotion__c);
    }

    /**
     *  Updates the attachment name to start with "RESOLVED"
     */
    public void saveResolvedAttachment() {
        Integer index = 0;
        Boolean isResolved = true;
        if (attachmentToResolve != null) {
            for (Attachment attachmentRecord : attachments) {
                if (attachmentRecord.Id == attachmentToResolve.Id) {
                    if (attachmentRecord.Name.startsWith('AUTO RESOLVED')) {
                        attachmentRecord.Name = attachmentRecord.Name.replace('AUTO RESOLVED', 'RESOLVED');
                    } else if (!attachmentRecord.Name.startsWith('RESOLVED')) {
                        attachmentRecord.Name = 'RESOLVED ' + attachmentRecord.Name;
                    }

                    attachments.set(index, attachmentRecord); // The attachment is upserted via Javascript
                    //break;
                }
                if (attachmentRecord.Name.startsWith('US-')) {
                    isResolved = false;
                    //break; commented out to prevent attachment items to not to show up as resolved if not started to resolve with the first attachment
                }
                index = index + 1;
            }
            if (isResolved) {
                updatePromotionAsResolved();
            }
        }
    }

    /**
     *  Checks that all attachments are marked as RESOLVED or AUTO RESOLVED.
     *  If True the user is redirected to the Promotion page.
     */
    public void createDeployment() {
        List<Attachment> updatedAttachments = new List<Attachment>();
        for (Attachment attachmentRecord : attachments) {
            if (outOfPromotionMetadataAttachmentIds.contains(attachmentRecord.Id)) {
                updatedAttachments.add(attachmentRecord);
            }
            if (!attachmentRecord.Name.startsWith('RESOLVED') && !attachmentRecord.Name.startsWith('AUTO RESOLVED')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_PENDING));
                return;
            }
        }
        if (!updatedAttachments.isEmpty()) {
            updateAttachments(updatedAttachments);
        }
        goToPromotion = true;
    }

    /**
     * Returns all metadata names in the promotion to check if conflicts are in the promotion or not
     */
    public Set<String> getUserStoryMetadatas() {
        Set<Id> userStoryIds = new Set<Id>();
        Set<String> userStoryMetadataAPINames = new Set<String>();
        try {
            String promotedUserStoryQuery =
                'SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = \'' +
                String.escapeSingleQuotes(promotion.Id) +
                '\' WITH SECURITY_ENFORCED';
            for (Promoted_User_Story__c promotedUSerStory : Database.query(promotedUserStoryQuery)) {
                userStoryIds.add(promotedUSerStory.User_Story__c);
            }
            if (!userStoryIds.isEmpty()) {
                String userStoryMetadataQuery = 'SELECT Id, Metadata_API_Name__c FROM User_Story_Metadata__c WHERE User_Story__c IN :userStoryIds WITH SECURITY_ENFORCED ORDER BY Last_Commit_Date__c DESC LIMIT 1000';
                for (User_Story_Metadata__c usMetadata : Database.query(userStoryMetadataQuery)) {
                    if (!userStoryMetadataAPINames.contains(usMetadata.Metadata_API_Name__c)) {
                        userStoryMetadataAPINames.add(usMetadata.Metadata_API_Name__c);
                    }
                }
            }
        } catch (Exception excp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, excp.getMessage()));
        }
        return userStoryMetadataAPINames;
    }
}