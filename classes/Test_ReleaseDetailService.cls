@IsTest
public with sharing class Test_ReleaseDetailService {
    @IsTest
    public static void testClassforReleaseDetailService() {
        ReleaseDetailService release = new ReleaseDetailService();
        release.getInstance();
        release.run(new CliProxy.CLIWrapper());
    }
}