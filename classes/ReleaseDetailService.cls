public with sharing class ReleaseDetailService implements CLIInterface {
    /**
    * Empty Constructor
    */
    public ReleaseDetailService() {
    }

    /**
     * Get instance of ReleaseDetailService that implements CLI Interface
     * @return instance of ReleaseDetailService()
     */
    public CLIInterface getInstance() {
        return new ReleaseDetailService();
    }

    public String run(CliProxy.CLIWrapper record) {
        return '';
    }
}