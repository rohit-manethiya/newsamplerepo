/**
 * @description this class serves as a DTO for the generation of package detail definitions inside a DX Project
 * JSON file.
 */
public with sharing class PackageDetail {
    private String packageId;
    private String subscriberVersionId;
    private String installationKey;
    private String packageName;
    private String packageVersion;

    public PackageDetail(String packageId, String subscriberVersionId, String packageName, String packageVersion) {
        this.packageId = packageId;
        this.subscriberVersionId = subscriberVersionId;
        this.packageName = packageName;
        this.packageVersion = packageVersion;
    }

    /**
     * @description a setter for the installationKey private variable.
     *
     * @param installationKey is an (optional) key (i.e. password) used to install a package in an org.
     */
    public void setInstallationKey(String installationKey) {
        this.installationKey = installationKey;
    }
}