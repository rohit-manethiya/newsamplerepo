public with sharing class AttachmentsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Attachment.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Attachment.Id, Attachment.ParentId, Attachment.Name, Attachment.Body, Attachment.LastModifiedDate };
    }

    public List<Attachment> byId(List<Id> recordIds) {
        return byId(new Set<Id>(recordIds));
    }

    public List<Attachment> byId(Set<Id> recordIds) {
        return (List<Attachment>) selectSObjectsById(recordIds);
    }

    public List<Attachment> byParentId(List<Id> parentIds) {
        return byParentId(new Set<Id>(parentIds));
    }

    public List<Attachment> byParentId(Set<Id> parentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ParentId IN :parentIds');
        return (List<Attachment>) Database.query(query.toSOQL());
    }

    public List<Attachment> byParentIdAndName(List<Id> parentIds, List<String> names) {
        return byParentIdAndName(new Set<Id>(parentIds), new Set<String>(names));
    }

    public List<Attachment> byParentIdAndName(Set<Id> parentIds, Set<String> names) {
        fflib_QueryFactory query = newQueryFactory().selectField('Parent.Name').setCondition('ParentId IN :parentIds AND Name IN :names');
        return (List<Attachment>) Database.query(query.toSOQL());
    }
}