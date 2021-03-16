@IsTest
public class ScratchOrgMetadataController_t {
    public ScratchOrgMetadataController controller { get; private set; }

    public ScratchOrgMetadataController_t() {
        this.controller = new ScratchOrgMetadataController();
    }

    public ScratchOrgMetadataController_t setSelectedOrgIdFromDxOperation(Id scratchOrgId) {
        this.controller.setSelectedOrgIdFromDxOperation(scratchOrgId);
        return this;
    }

    public ScratchOrgMetadataController_t setArtifactType(String artifactType) {
        this.controller.typeName = artifactType;
        return this;
    }

    public ScratchOrgMetadataController_t selectType() {
        this.controller.selectType();
        return this;
    }

    public ScratchOrgMetadataController_t setSelectedOrgId(Id selectedOrgId) {
        this.controller.setSelectedOrgId(selectedOrgId);
        return this;
    }

    public ScratchOrgMetadataController_t getOrgArtifacts() {
        this.controller.getOrgArtifacts();
        return this;
    }

    public ScratchOrgMetadataController_t setSelectedArtifactIds(List<Id> selectedArtifactIds) {
        this.controller.selectedArtifactIds = selectedArtifactIds;
        return this;
    }

    public ScratchOrgMetadataController_t setSelectedArtifactId(Id selectedArtifactId) {
        this.controller.selectedArtifactId = selectedArtifactId;
        return this;
    }

    public ScratchOrgMetadataController_t populateArtifactVersions() {
        this.controller.populateArtifactVersions();
        return this;
    }

    public ScratchOrgMetadataController_t updateSourceSelections() {
        this.controller.updateSourceSelections();
        return this;
    }

    public ScratchOrgMetadataController_t setSelectedVersionId(Id selectedVersionId) {
        this.controller.selectedVersionId = selectedVersionId;
        return this;
    }

    public ScratchOrgMetadataController_t addValuesToSelectedPackages() {
        this.controller.addValuesToSelectedPackages();
        return this;
    }

    public ScratchOrgMetadataController_t removePackage() {
        this.controller.removePackage();
        return this;
    }

    public List<SelectOption> getArtifactOptions() {
        System.assert(!this.controller.artifactOptions.isEmpty(), 'The selected source org has at least 1 artifact available.');
        return this.controller.artifactOptions;
    }

    public List<SelectOption> getArtifactVersionOptions() {
        System.assert(!this.controller.artifactVersionOptions.isEmpty(), 'The selected artifact has at least 1 artifact version available.');
        return this.controller.artifactVersionOptions;
    }

    public PageReference loadMetadata() {
        return this.controller.loadMetadata();
    }

    public List<SelectOption> getApiVersions() {
        return this.controller.getVersions();
    }

    public List<SelectOption> getMetadataFormatOptions() {
        return this.controller.metadataFormatOptions;
    }

    public Id getSelectedVersionId() {
        return this.controller.selectedVersionId;
    }
}