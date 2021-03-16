@IsTest
public with sharing class Test_ReleaseStatusService {
    @IsTest
    public static void testClassforReleaseStatus() {
        ReleaseStatusService release = new ReleaseStatusService();
        release.getInstance();
        release.run(new CliProxy.CLIWrapper());
    }
}