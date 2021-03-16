/**
 * @description this interface serves as a contract to ensure that all existing artifact entities offer the essential
 * set of operations that a user can perform when working with DX Projects.
 */
public interface IDXProjectBehavior {
    /**
     * @description this method exposes a way of loading selected metadata into a target org by sending a request to
     * the backend and executing the proper DX CLI commands against that org.
     */
    void loadMetadata();
    /**
     * @description this method provides all implementing entities with the ability to generate a Metadata Source
     * (metadataSources.json) file for a DX Project definition.
     *
     * @return the metadataSources.json file in String format.
     */
    String generateMetadataSourcesJson();
    /**
     * @description this method provides all implementing entities with the ability to generate a DX Project
     * (sfdx-project.json) file to describe a new or existing DX Project that a user is working with.
     *
     * @return the sfdx-project.json file in String format.
     */
    String generateProjectJson();
}