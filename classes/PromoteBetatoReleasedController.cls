/**
 * @description Package versions are being created as beta. So in order to
 * use released version of packages we need to promote them. This call handles
 * the promotion process
 * @author Umit Can Uckan
 */
public with sharing class PromoteBetatoReleasedController {
    public Artifact_Version__c currentRecord { get; set; }
    /**
     * Executes promote action for the given package version
     * @return null page reference since this method is executed from its page and the actual result is handled by DXPackageAsyncJobHandler
     */
    public PageReference promoteAction() {
        SecureOperations so = new SecureOperations();
        String attBodyStr;
        if(so.isAuthorizedToQuery(Attachment.SObjectType)) {
            attBodyStr = [SELECT Id, Body FROM Attachment WHERE Name = :DXLabel.PROJECT_FILE AND ParentId = :currentRecord.Artifact__c LIMIT 1].Body.toString();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Attachment.label + ': ' + Label.Insufficient_Access_Rights));
            return null;
        }

        Id subscriberId = currentRecord.Subscriber_Version_Id__c;
        Id versionId = currentRecord.Id;
        Id devHubId = currentRecord.Artifact__r.Target_Dev_Hub_Org__c;
        Id artifactId = currentRecord.Artifact__c;
        Map<String, String> packageAliasesMap = new Map<String, String>();
        Artifact__c parentArtifact;
        // Try to retrieve parent package and throw page message as exception if there is none.
        //Parent package is required in order to promote a version.
        try {
            if(so.isAuthorizedToQuery(Attachment.SObjectType)) {
                parentArtifact = [SELECT Name,Package_Id__c FROM Artifact__c WHERE Id = :currentRecord.Artifact__c];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Artifact__c.label + ': ' + Label.Insufficient_Access_Rights));
                return null;
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Parent_SF_Package_Not_Found));
            return null;
        }
        List<Artifact_Version__c> dependencyArtifactList = new List<Artifact_Version__c>();
        dependencyArtifactList = DXPackageArtifactHelper.packageDependencies(artifactId);

        packageAliasesMap.put(parentArtifact.Name, parentArtifact.Package_Id__c);
        packageAliasesMap.put(currentRecord.Name, currentRecord.Subscriber_Version_Id__c);

        for(Artifact_Version__c av : dependencyArtifactList) {
            packageAliasesMap.put(av.Artifact__r.Name, av.Artifact__c);
        }

        // Re-create project json to handle package alisases and package directories properly
        String afterSerialize = DXPackageArtifactHelper.prepareProperProjectJson(artifactId, attBodyStr, packageAliasesMap, parentArtifact.Package_Id__c, currentRecord.Version_Description__c, currentRecord.Version_number__c, currentRecord.Name, parentArtifact.Name, dependencyArtifactList);
        // Do call out to backend to execute promotion process.
        SfdxAPI.promoteBetaPackagetoReleased(afterSerialize, subscriberId, devHubId, artifactId, versionId);
        return null;
    }
    /**
     * Cancel the operation and go back to the version page.
     * @return PageReference to Package version page layout
     */
    public PageReference cancel() {
        ApexPages.StandardController sc = new ApexPages.StandardController(currentRecord);
        return sc.cancel();
    }
}