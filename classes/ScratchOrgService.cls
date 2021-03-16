/**
 * @description this service class provides all the available operations on a Scratch Org that can be executed by
 * backend jobs.
 */
public with sharing class ScratchOrgService extends AbstractDXOrg {
    /**
     * @description executes the deletion command for an existing scratch org.
     */
    public void deleteOrg() {
        validateOrgId();
        String callURL = DXLabel.SCRATCH_ORG_URL_PATH + getOrgId();
        sendDXRequest(callUrl, null, DXLabel.HTTP_DELETE, false, DXLabel.DELETE_ORG);
    }

    /**
     * @description changes the password of a scratch org user.
     */
    public void generatePassword() {
        validateOrgId();
        String callURL = DXLabel.SCRATCH_ORG_URL_PATH + getOrgId() + '/ideDetails';
        sendDXRequest(callURL, null, DXLabel.HTTP_GET, false, DXLabel.ORG_IDE_DETAILS);
    }

    /**
     * @description retrieves basic details of a scratch org instance, such as the org id, connection status, the
     * instance URL, username and password.
     */
    public void getOrgDetails() {
        validateOrgId();
        String callURL = DXLabel.SCRATCH_ORG_URL_PATH + getOrgId() + '/orgDetails';
        sendDXRequest(callURL, null, DXLabel.HTTP_GET, false, DXLabel.ORG_DETAILS);
    }

    /**
     * @description retrieves the last status of the scratch org metadata compared to the target DX Project and
     * git branch.
     *
     * @param repositoryId is the git repository id in Salesforce.
     * @param branch is the branch name to get the metadata from.
     *
     * @return a status response from the backend job indicating the command execution result.
     */
    public String getSourceStatus(Id repositoryId, String branch) {
        validateOrgId();
        String callURL = DXLabel.SCRATCH_ORG_URL_PATH + getOrgId() + '/sourceStatus?repositoryId=' + repositoryId + '&branch=' + encode(branch);
        String responseBody = sendDXRequest(callURL, null, DXLabel.HTTP_GET, false, DXLabel.SOURCE_STATUS);
        return responseBody;
    }

    /**
     * @description retrieves the list of packages of a selected scratch org.
     */
    public void getListOfPackages() {
        validateOrgId();
        String callURL = DXLabel.DX_URL_PATH + DXLabel.PACKAGES_LIST + getOrgId();
        sendDXRequest(callURL, null, DXLabel.HTTP_GET, false, DXLabel.LIST_OF_PACKAGES);
    }
}