/**
 * @description this class serves as a DTO for holding package dependency information about selected artifacts that
 * need to be loaded into an org. This includes both artifacts that depend on the main package and artifacts on which
 * the main package depends.
 */
public with sharing class PackageDependency {
    private String packageName;
    private String versionNumber;

    public PackageDependency(String packageName, String versionNumber) {
        this.packageName = packageName;
        this.versionNumber = versionNumber;
    }

    public PackageDependency(String packageName) {
        this.packageName = packageName;
    }

    /**
     * @description a setter for the packageName private variable.
     *
     * @param packageName is the name of the package that is part of the dependency chain.
     */
    public void setPackageName(String packageName) {
        this.packageName = packageName;
    }

    /**
     * @description a getter for the packageName private variable.
     *
     * @return the name of the package that is part of a dependency chain.
     */
    public String getPackageName() {
        return this.packageName;
    }

    /**
     * @description a setter for the versionNumber private variable.
     *
     * @param versionNumber is the version of the package that is part of the dependency chain.
     */
    public void setVersionNumber(String versionNumber) {
        this.versionNumber = versionNumber;
    }

    /**
     * @description a getter for the versionNumber private variable.
     *
     * @return the version of the package that is part of the dependency chain.
     */
    public String getVersionNumber() {
        return this.versionNumber;
    }
}