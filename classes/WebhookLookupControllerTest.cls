@IsTest
private with sharing class WebhookLookupControllerTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            TestUtilities.setTestSettingsEE();
        }
        testMethodUtilities.upsertOrgwideSettings();
    }

    @IsTest
    private static void fullTest(){
        WebhookLookupController con = new WebhookLookupController();
        System.assert(con.settings != null);
        System.assert(con.lookupAux != null);
    }
}