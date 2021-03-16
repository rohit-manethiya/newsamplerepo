/**
 * @description this class provides all the available operations for installing a second-generation managed artifact
 * in a Scratch Org.
 * @see AbstractPackage
 */
public with sharing class SecondGenerationManagedArtifact extends AbstractPackage {
  /**
   * @description a setter for the artifactSource private variable.
   *
   * @param sourceSelections is a string containing comma-separated ids of artifacts or the name of a DX branch
   * from where the source is to be pulled for installation.
   */
  public override void setMetadataSource(String sourceSelections) {
    artifactSource = new MetadataSource(sourceSelections, DXLabel.SECONDGENERATIONPACKAGE, null);
    if(String.isNotBlank(sourceSelections)) {
      artifactSource.setArtifactIds(sourceSelections.split(','));
    }
  }

  /**
   * @description a getter for the artifactSource private variable.
   *
   * @return a MetadataSource object with the source artifact and/or git repository information from where all sources
   * will be installed into a Scratch Org.
   */
  public override MetadataSource getMetadataSource() {
    return artifactSource;
  }

  private void throwArtifactException() {
    if (!skipPackageVersionValidation) {
      throw new ArtifactException(Label.Select_package_to_install);
    }
  }
}