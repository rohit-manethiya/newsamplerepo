public interface IPackageBehavior {
    void createPackage(String description, String packageName, Boolean noNamespace, String packageType);
    void createPackageVersion(String orgDefinitionJSON, String branch, String sourceBranch, String installationKey, String tag, Artifact_Version__c version);
    void promoteBetaPackageToReleased(Id artifactVersionId);
    List<Artifact_Version__c> getPackageDependencies();
}