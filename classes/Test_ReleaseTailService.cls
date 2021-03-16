@IsTest
public with sharing class Test_ReleaseTailService {
    @IsTest
    public static void testClassforReleaseTailService() {
        ReleaseTailService release = new ReleaseTailService();
        release.getInstance();
        release.run(new CliProxy.CLIWrapper());
    }
}