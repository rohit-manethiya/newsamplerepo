/**
 * Interface to handle requests from CLI
 */

public interface CLIInterface {
    /**
     * It is used the get instance of necessary service class
     *
     * @return
     */
    CLIInterface getInstance();

    /**
     * Runs requested operation under root service
     *
     * @return
     */
    String run(CliProxy.CLIWrapper record);

}