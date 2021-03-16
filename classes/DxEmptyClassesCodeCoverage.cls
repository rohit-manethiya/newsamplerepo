@IsTest
private class DxEmptyClassesCodeCoverage {
    @IsTest
    private static void coverDxEmptyClasses () {
        UnmanagedPackageMetadataService unmanaged = new UnmanagedPackageMetadataService();
        ArtifactMetadataService artifact = new ArtifactMetadataService();
        BranchMetadataService branch = new BranchMetadataService();
        OrgMetadataService org = new OrgMetadataService();
        PatchMetadataService patch = new PatchMetadataService();
        UnlockPackageService unlock = new UnlockPackageService();
        SecondGenerationPackageService second = new SecondGenerationPackageService();
        DXMetadataJsonWrapper dxjsonwrapper = new DXMetadataJsonWrapper();
    }
}