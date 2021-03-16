/**
 * @description Salesforce DX Unlocked Package or Second generation package creation and
 * their version generations are being handled in this class
 * @author Mert YALTI
 * @author Umit Can Uckan
 * @since v12
 * @version 1.0
 * @see SfdxAPI
 * @see SfdxAPIHelper
 */

public with sharing class DXPackageVersionHandler {
    private final String DEFAULT_DX_PATH = 'DX/';
    private AbstractArtifact thisArtifact;
    private Map<String, Attachment> attachmentsByName {
        get {
            if(attachmentsByName == null) {
                attachmentsByName = getAttachmentsByName();
            }
            return attachmentsByName;
        }
        set;
    }
    public static final String ns {
        get {
            if (ns == null) {
                ns = Settings.ns;
            }
            return ns;
        }
        private set;
    }
    public Artifact__c givenPackage { get; set; }
    public Sensitive_Information__c sensitiveInformationCS {
        get {
            if (sensitiveInformationCS == null && previousPackageVersion != null) {
                Sensitive_Information__c thisInformation = Sensitive_Information__c.getValues(previousPackageVersion.Id);
                return thisInformation;
            }
            return sensitiveInformationCS;
        }
        set;
    }
    public Artifact_Version__c previousPackageVersion {
        get {
            if (previousPackageVersion == null) {
                getPreviousVersion();
            }
            return previousPackageVersion;
        }
        set;
    }
    public VersionWrapper versionWrapper {
        get {
            if (versionWrapper == null) {
                versionWrapper = new VersionWrapper('', '', '', '');
            }
            return versionWrapper;
        }
        set;
    }
    public Attachment projectDefinitionAttachment; // project definition is mandatory for packaging operation. Page handles this requirement
    public Boolean hasProjectDefinitionJson { // situation is explained above
        get {
            if (hasProjectDefinitionJson == null) {
                Attachment attachment = attachmentsByName.get(DXLabel.PROJECT_FILE);
                if (attachment != null) {
                    projectDefinitionAttachment = attachment;
                    hasProjectDefinitionJson = true;
                } else {
                    hasProjectDefinitionJson = false;
                }
            }
            return hasProjectDefinitionJson;
        }
        set;
    }
    // Org definition json to handle definition dependencies
    // even tough this one is totally optional we require it to do backend callout
    // however if this is empty SfdxAPIHelper has default org definition creation which
    // we use for the package calls
    public Attachment orgDefinitionAttachment;
    public Boolean hasOrgDefinitionJson {
        get {
            if (hasOrgDefinitionJson == null) {
                Attachment attachment = attachmentsByName.get(DXLabel.DEFINITION_FILE);
                if (attachment != null) {
                    orgDefinitionAttachment = attachment;
                    hasOrgDefinitionJson = true;
                } else {
                    hasOrgDefinitionJson = false;
                }
            }
            return hasOrgDefinitionJson;
        }
        set;
    }

    /**
     * In order to generate version number suggestion options we need to know
     * what version number has been used for the latest version
     * This method finds the latest version and generated the suggestions (getVersionDetails)
     */
    public void getPreviousVersion() {
        if (String.isNotBlank(givenPackage.Artifact_Version__c)) {
            try {
                previousPackageVersion = [
                    SELECT Name, Version_number__c
                    FROM Artifact_Version__c
                    WHERE Id = :givenPackage.Artifact_Version__c
                    WITH SECURITY_ENFORCED
                ];
                getVersionDetails(previousPackageVersion.Version_number__c);
            } catch (System.QueryException e) {
                addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + e.getMessage());
            }
        }
    }

    /**
     * Generates version number suggestions for major, minor, patch and build type of versions
     * @param previousVersionNo latest version number
     */
    public void getVersionDetails(String previousVersionNo) {
        List<String> versionDigits = previousVersionNo.split('\\.');
        versionWrapper = new VersionWrapper(versionDigits);
    }

    /**
     * Not an actual cancellation since no operation took place.
     * This one is kind of go back button
     * @return given package's page reference
     */
    public PageReference cancel() {
        ApexPages.StandardController sc = new ApexPages.StandardController(givenPackage);
        return sc.cancel();
    }

    /**
     * The main operation
     * This method does the backend call for package and version creations
     */
    public void callBackend() {
        ApexPages.getMessages().clear();
        if (requiredParametersMissing()) {
            return;
        }
        if (!initArtifactInstance()) {
            return;
        }

        DXProject thisProject = createDXProject();
        thisArtifact.setArtifactId(givenPackage.Id);
        thisArtifact.setArtifactName(givenPackage.Name);
        thisArtifact.setDevHubOrgId(givenPackage.Target_Dev_Hub_Org__c);

        String packageName = givenPackage.Name;
        if (String.isBlank(givenPackage.Package_Id__c)) {
            thisArtifact.setDXProject(thisProject);
            Boolean noNamespace;
            String description = givenPackage.Description__c;
            String packageType = givenPackage.Package_Type__c;
            switch on givenPackage.Package_Type__c {
                when 'Unlocked' {
                    noNamespace = givenPackage.No_Namespace__c;
                }
                when 'Second-Generation Package' {
                    packageType = 'Managed';
                }
            }
            try {
                setSkipInstallPackageValidation(true);
                ((AbstractPackage) thisArtifact).createPackage(description, packageName, noNamespace, packageType);
                setSkipInstallPackageValidation(false);
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }
        } else {
            String installationKey = ApexPages.currentPage().getParameters().get('nrik');
            if (String.isBlank(installationKey)) {
                installationKey = versionWrapper.installationKey;
            }

            String versionNumber = versionWrapper.newVersion;
            String versionName = versionWrapper.versionName;

            ArtifactVersion latestPackageVersion = createLatestArtifactVersion();
            List<ArtifactVersion> artifactVersions = getArtifactVersions();
            artifactVersions.add(latestPackageVersion);

            ((AbstractPackage) thisArtifact).setPackageId(givenPackage.Package_Id__c);
            ((AbstractPackage) thisArtifact).setPackageVersions(artifactVersions);

            List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
            ProjectArtifact mainArtifact = new ProjectArtifact(
                givenPackage.Name,
                givenPackage.Package_Id__c,
                true,
                latestPackageVersion.getVersion()
            );

            List<PackageDependency> dependencies = getArtifactDependencies();
            mainArtifact.setDependencies(dependencies);

            artifactDirectories.add(mainArtifact);
            for (ProjectArtifact thisArtifact : artifactDirectories) {
                thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
            }
            thisProject.setPackageDirectories(artifactDirectories);

            thisArtifact.setDXProject(thisProject);

            String orgDefJson = hasOrgDefinitionJson ? orgDefinitionAttachment.Body.toString() : null;
            String branch = DEFAULT_DX_PATH + packageName + '-' + versionName.replaceAll(' ', '') + '-' + versionNumber;
            String tag = DEFAULT_DX_PATH + versionNumber;
            try {
                ((AbstractPackage) thisArtifact)
                    .createPackageVersion(orgDefJson, branch, versionWrapper.sourceBranch, installationKey, tag, latestPackageVersion.getVersion());
                if (String.isNotBlank(installationKey)) {
                    Sensitive_Information__c thisSensitiveInformation = createSensitiveInformation(packageName, versionNumber, installationKey);
                    Utilities.Secure_DML(thisSensitiveInformation, Utilities.DML_Action.INS, sObjectType.Sensitive_Information__c);
                }
                updateArtifactProjectJsonAttachment();
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }
        }
    }

    private DXProject createDXProject() {
        DXProject project;
        if (hasProjectDefinitionJson) {
            try {
                project = (DXProject) JSON.deserialize(projectDefinitionAttachment.Body.toString(), DXProject.class);
                project.clearPackageDirectories();
            } catch (JSONException ex) {
                project = createDefaultDXProject();
            }
        } else {
            project = createDefaultDXProject();
        }
        return project;
    }

    private DXProject createDefaultDXProject() {
        String loginUrl = String.isNotBlank(givenPackage.Sfdc_Login_Url__c) ? givenPackage.Sfdc_Login_Url__c : DXLabel.DEFAULT_SFDC_LOGIN_URL;
        String apiVersion = String.isNotBlank(givenPackage.Source_Api_Version__c) ? givenPackage.Source_Api_Version__c : DXLabel.DEFAULT_API_VERSION;
        DXProject project = new DXProject(givenPackage.Package_Namespace__c, loginUrl, apiVersion);
        return project;
    }

    private ArtifactVersion createLatestArtifactVersion() {
        Artifact_Version__c thisNewVersion = new Artifact_Version__c();
        thisNewVersion.Name = versionWrapper.versionName;
        thisNewVersion.Version_number__c = versionWrapper.newVersion;
        thisNewVersion.Version_Description__c = versionWrapper.versionDescription;
        ArtifactVersion newVersion = createArtifactVersion(0, givenPackage.Name, givenPackage.Name, thisNewVersion);
        return newVersion;
    }

    private List<ArtifactVersion> getArtifactVersions() {
        List<ArtifactVersion> artifactVersions = new List<ArtifactVersion>();
        Integer order = 1;
        for (Artifact_Version__c thisVersion : ((AbstractPackage) thisArtifact).getPackageDependencies()) {
            ArtifactVersion version = createArtifactVersion(order, givenPackage.Name, thisVersion.Artifact__r.Name, thisVersion);
            artifactVersions.add(version);
            order++;
        }
        return artifactVersions;
    }

    private List<PackageDependency> getArtifactDependencies() {
        List<PackageDependency> dependencies = new List<PackageDependency>();
        for (Artifact_Version__c thisVersion : ((AbstractPackage) thisArtifact).getPackageDependencies()) {
            PackageDependency dependency = new PackageDependency(thisVersion.Subscriber_Version_Id__c);
            dependencies.add(dependency);
        }
        return dependencies;
    }

    private ArtifactVersion createArtifactVersion(Integer order, String includedBy, String artifactName, Artifact_Version__c thisVersion) {
        ArtifactVersion version = new ArtifactVersion(includedBy, artifactName, thisVersion);
        version.setOrder(order + 1);
        return version;
    }

    /**
     * @description Checks whether all the required parameters are present and if not, displays an error message to the user
     * @return true if any of the required parameters is missing and false otherwise
     */
    private Boolean requiredParametersMissing() {
        Boolean requiredParametersMissing = false;

        Map<String, Boolean> errorMessageMap = new Map<String, Boolean>{
            SObjectType.Artifact__c.Fields.Target_Dev_Hub_Org__c.Label => String.isBlank(givenPackage.Target_Dev_Hub_Org__c),
            SObjectType.Artifact_Version__c.Fields.Name.Label => String.isNotBlank(givenPackage.Package_Id__c) &&
            String.isBlank(versionWrapper.versionName),
            SObjectType.Artifact_Version__c.Fields.Version_number__c.Label => String.isNotBlank(givenPackage.Package_Id__c) &&
            String.isBlank(versionWrapper.newVersion),
            SObjectType.Artifact__c.Fields.Package_Id__c.Label => String.isBlank(givenPackage.Package_Id__c) &&
            (String.isNotBlank(versionWrapper.versionName) || String.isNotBlank(versionWrapper.newVersion)),
            SObjectType.Artifact__c.Fields.Id.Label => givenPackage.Id == null
        };
        for (String message : errorMessageMap.keySet()) {
            Boolean addMessage = errorMessageMap.get(message);
            if (addMessage) {
                requiredParametersMissing = true;
                addPageMessage(ApexPages.Severity.ERROR, Label.Required_Parameters_Missing + ': ' + message);
            }
        }
        return requiredParametersMissing;
    }

    private void setSkipInstallPackageValidation(Boolean enable) {
        if (thisArtifact instanceof UnlockedArtifact) {
            ((UnlockedArtifact) thisArtifact).setSkipPackageVersionValidation(enable);
        } else if (thisArtifact instanceof SecondGenerationManagedArtifact) {
            ((SecondGenerationManagedArtifact) thisArtifact).setSkipPackageVersionValidation(enable);
        }
    }

    private Boolean initArtifactInstance() {
        Boolean success = true;
        switch on givenPackage.Package_Type__c {
            when 'Unlocked' {
                thisArtifact = ArtifactFactory.getInstance(DXLabel.UNLOCKPACKAGE);
            }
            when 'Second-Generation Package' {
                thisArtifact = ArtifactFactory.getInstance(DXLabel.SECONDGENERATIONPACKAGE);
            }
            when else {
                success = false;
                addPageMessage(ApexPages.Severity.ERROR, Label.Unsupported_Metadata_Source);
            }
        }
        return success;
    }

    private Sensitive_Information__c createSensitiveInformation(String packageName, String versionNumber, String installationKey) {
        String thisVersionName = packageName + ' - ' + versionNumber;
        Sensitive_Information__c thisSensitiveInformation = new Sensitive_Information__c(
            Name = thisVersionName,
            Version_Name__c = thisVersionName,
            Password__c = DeployAPI.encryptAPIKey(installationKey)
        );
        return thisSensitiveInformation;
    }

    /**
     * If the backend call for the package version creation fails, call this method to delete the Sensitive_Information__c record that was created,
     * as it no longer is related to any new package versions.
     */
    public void deleteInstallationKeyAfterVersionCreationFailure() {
        String thisVersionName = givenPackage.Name + ' - ' + versionWrapper.newVersion;
        Sensitive_Information__c thisSensitiveInformation = Sensitive_Information__c.getValues(thisVersionName);
        try {
            Utilities.Secure_DML(thisSensitiveInformation, Utilities.DML_Action.DEL, sObjectType.Sensitive_Information__c);
        } catch (Exception ex) {
            addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
        }
    }

    public void updateArtifactProjectJsonAttachment() {
        ((AbstractPackage) thisArtifact).updateProjectJsonAttachment();
    }

    public void updateInstallationKey() {
        if (sensitiveInformationCS != null) {
            versionWrapper.installationKey = DeployAPI.decryptAPIKey(sensitiveInformationCS.Password__c);
        } else {
            versionWrapper.installationKey = '';
        }
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    private Map<String, Attachment> getAttachmentsByName() {
        Map<String, Attachment> result = new Map<String, Attachment>();
        try {
            for (Attachment attachmentItem : [
                SELECT Name, Body
                FROM Attachment
                WHERE (Name = :DXLabel.DEFINITION_FILE OR Name = :DXLabel.PROJECT_FILE) AND ParentId = :givenPackage.Id
                WITH SECURITY_ENFORCED
            ]) {
                result.put(attachmentItem.Name, attachmentItem);
            }
        } catch (System.QueryException e) {
            addPageMessage(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + e.getMessage());
        }
        return result;
    }

    /**
     * Version wrapper that handles version number suggestion options and actual version information
     */
    public class VersionWrapper {
        public String major { get; set; }
        public String minor { get; set; }
        public String patch { get; set; }
        public String build { get; set; }
        public String newVersion { get; set; }
        public String versionDescription { get; set; }
        public String versionName { get; set; }
        public String installationKey { get; set; }
        public String sourceBranch { get; set; }
        /**
         * Constuctor
         * @param major major release number option like 2.0.0.0
         * @param minor minor release number option like 2.1.0.0
         * @param patch patch release number option like 2.0.1.0 (currently not supported by salesforce DX so this option is ignored until future use)
         * @param build build release number option. Mostly used for beta or really minor releases. Like 2.0.0.1
         * @param newVersion actual version number to be created. Has to be in major.minor.patch.build format. There is a validation rule that checks this on Artifact_Version object
         * @param versionDescription the description of the version
         * @param versionName the name of the version. Best practice is Summer 18, Winter 19 kind of version names
         */
        public VersionWrapper(String major, String minor, String patch, String build) {
            this.major = major;
            this.minor = minor;
            this.patch = patch;
            this.build = build;
            this.sourceBranch = 'master';
        }
        public VersionWrapper(List<String> versionDigits) {
            String major, minor, patch, build;
            if (!versionDigits.isEmpty()) {
                major = (Integer.valueOf(versionDigits[0]) + 1) + '.0.0.0';
                minor = Integer.valueOf(versionDigits[0]) + '.' + (Integer.valueOf(versionDigits[1]) + 1) + '.0.0';
                patch =
                    Integer.valueOf(versionDigits[0]) +
                    '.' +
                    Integer.valueOf(versionDigits[1]) +
                    '.' +
                    (Integer.valueOf(versionDigits[2]) + 1) +
                    '.0';
                build =
                    Integer.valueOf(versionDigits[0]) +
                    '.' +
                    Integer.valueOf(versionDigits[1]) +
                    '.' +
                    Integer.valueOf(versionDigits[2]) +
                    '.' +
                    (Integer.valueOf(versionDigits[3]) + 1);
            }
            this.major = major;
            this.minor = minor;
            this.patch = patch;
            this.build = build;
            this.sourceBranch = 'master';
        }
    }
}