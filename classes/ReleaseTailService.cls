public with sharing class ReleaseTailService implements CLIInterface {
    /**
    * Empty Constructor
    */
    public ReleaseTailService() {
    }

    /**
     * Get instance of ReleaseTailService that implements CLI Interface
     * @return instance of ReleaseTailService()
     */
    public CLIInterface getInstance() {
        return new ReleaseTailService();
    }

    public String run(CliProxy.CLIWrapper record) {
        return '';
    }
}