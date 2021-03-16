/**
 * @description a static factory class for creating org service-oriented entities.
 */
public with sharing class DXOrgFactory {
    /**
     * @description whether a user needs to work with Dev Hub orgs, Sandboxes, or Scratch orgs, there are always
     * certain operations that are unique to each org type. This method ensures that a user is getting the
     * correct set of org services based on the operation he/she wants to carry out.
     *
     * @param orgType is the type of org a user is working with.
     *
     * @return an abstract org entity instance that exposes all the necessary services for the selected org type.
     */
    public static AbstractDXOrg getInstance(String orgType) {
        switch on orgType {
            when 'ScratchOrgService' {
                return new ScratchOrgService();
            } when 'DevHubService' {
                return new DevHubService();
            } when else {
                throw new UnsupportedOperationException('Unsupported org service type.');
            }
        }
    }
}