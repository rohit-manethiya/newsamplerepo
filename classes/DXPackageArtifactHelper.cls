/**
 *
 */
public with sharing class DXPackageArtifactHelper {
    public static String prepareProperProjectJson(Id artifactId, String projectJson, Map<String, String> packageAliasesMap, Id packageId, String versionDescription, String versionNumber, String versionName, String packagePath, List<Artifact_Version__c> dependencyArtifactList) {
        if(String.isBlank(projectJson)) {
            throw new CopadoDxException(Label.Initial_project_json_is_required);
        }
        try {
            Artifact_Version__c thisVersion = new Artifact_Version__c(Name = versionName, Version_number__c = versionNumber, Version_Description__c = versionDescription);
            DXProject proItem = (DXProject) JSON.deserialize(projectJson, DXProject.class);
            proItem.setPackageAliases(packageAliasesMap);
            proItem.clearAliasesIfEmpty();
            List<ProjectArtifact> packDirectories = new List<ProjectArtifact>();
            ProjectArtifact mainPackageDirectory = new ProjectArtifact(packagePath, packageId, true, thisVersion);
            for(Artifact_Version__c av : dependencyArtifactList) {
                PackageDependency pd = new PackageDependency(av.Name, av.Version_number__c);
                mainPackageDirectory.addDependency(pd);

                ProjectArtifact dependencyPackageDirectory = new ProjectArtifact(packagePath, packageId, false, av);
                packDirectories.add(dependencyPackageDirectory);
            }
            packDirectories.add(mainPackageDirectory);
            for(ProjectArtifact thisArtifact : packDirectories) {
                thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
            }
            proItem.setPackageDirectories(packDirectories);
            String preparedJson = JSON.serialize(proItem, true);
            return SfdxAPIHelper.orgDefinitionDefaultKeyFixer(preparedJson.replaceAll('"packageName":', '"package":'));
        } catch(Exception ex) {
            throw new CopadoDxException(ex.getMessage());
        }
    }

    public static List<Artifact_Version__c> packageDependencies(Id artifactId) {
        SecureOperations so = new SecureOperations();
        if(!so.isAuthorizedToQuery(Artifact_Dependency__c.getSObjectType())) {
            throw new CopadoDxException(Label.Error_during_artifact_dependency_calculation + ' ' + SObjectType.Attachment.Label + ': ' + Label.Insufficient_Access_Rights);
        }
        Set<Id> versionIds = new Set<Id>();
        for(Artifact_Dependency__c ad : [
                SELECT Id,Dependent_Artifact__c,Depending_Artifact__c,Depending_Artifact_Version__c,
                        Depending_Artifact__r.Artifact_Version__c,Depends_on_the_latest_version__c
                FROM Artifact_Dependency__c
                WHERE Dependent_Artifact__c = :artifactId
        ]) {
            if(ad.Depends_on_the_latest_version__c) {
                versionIds.add(ad.Depending_Artifact__r.Artifact_Version__c);
            } else {
                versionIds.add(ad.Depending_Artifact_Version__c);
            }
        }

        return queryPackageVersionsDetails(versionIds);
    }

    public static List<Artifact_Version__c> queryPackageVersionsDetails(Set<Id> versionIds) {
        return [SELECT Id,Name,Artifact__c,Branch__c,Is_released__c,Tag__c,Version_Description__c,
                Version_number__c, Artifact__r.Name,Subscriber_Version_Id__c
        FROM Artifact_Version__c
        WHERE Id IN :versionIds];
    }

    public class CopadoDxException extends Exception {
    }
}