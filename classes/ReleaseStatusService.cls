public with sharing class ReleaseStatusService implements CLIInterface {
    /**
    * Empty Constructor
    */
    public ReleaseStatusService() {
    }

    /**
     * Get instance of ReleaseStatusService that implements CLI Interface
     * @return instance of ReleaseStatusService()
     */
    public CLIInterface getInstance() {
        return new ReleaseStatusService();
    }

    public String run(CliProxy.CLIWrapper record) {
        return '';
    }
}