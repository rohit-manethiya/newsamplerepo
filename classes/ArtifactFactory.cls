/**
 * @description a static factory class for creating artifact-oriented entities.
 */
public with sharing class ArtifactFactory {
    /**
     * @description whether a user needs to work with Unlocked, Second Generation or Git Artifacts, there are always
     * certain operations and attributes that are unique to each artifact type. This method ensures that a user
     * is getting the correct set of artifact services based on the type of installation he/she wants to carry out.
     *
     * @param type is the type of artifact a user is working with.
     *
     * @return an abstract artifact entity instance that exposes all the necessary services for working with the
     * selected artifact type.
     */
    public static AbstractArtifact getInstance(String type) {
        switch on type {
            when 'artifact' {
                return new GitArtifact();
            } when 'managed' {
                return new SecondGenerationManagedArtifact();
            } when 'unlocked' {
                return new UnlockedArtifact();
            } when 'branch' {
                return new BranchArtifact();
            } when 'patch' {
                return new PatchArtifact();
            } when else {
                throw new UnsupportedOperationException('Unsupported artifact type.');
            }
        }
    }
}