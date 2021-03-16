@IsTest
private with sharing class UsersStepControllerTest {
    @IsTest
    private static void runTest() {
        usersStepController con = new usersStepController();
        system.assert(con.dummy != null);
        Step__c testStep = new Step__c();
        testStep.Name = 'testMethodStep';
        con.dummy = testStep;
        con.setDummy(testStep);
        Step__c s = con.getDummy();
        system.assertEquals('testMethodStep', s.Name);
    }
}