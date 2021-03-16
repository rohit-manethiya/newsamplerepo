@IsTest
private with sharing class RefreshRecentChangesTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();

        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];
        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);

            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setSObjectRelation(
                    Org__c.SObjectType,
                    Environment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Org__c.Environment__c => 1 }
                )
                .setDataSize(Org__c.SObjectType, 1)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    private static void refreshRecentChanges() {
        // Setup
        Org__c org = [SELECT Id FROM Org__c];

        insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

        String fixedResponse = '{' +
            '"statusCode" : 200,' +
            '"content" : "{' +
                '\\"records\\" : [' +
                '{' +
                        '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                        '\\"CreatedBy\\": {' +
                            '\\"Name\\": \\"User User\\"' +
                        '},' +
                        '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                        '\\"LastModifiedBy\\": {' +
                            '\\"Name\\": \\"User User\\"' +
                        '},' +
                        '\\"IsNameObsolete\\": false,' +
                        '\\"MemberName\\": \\"asdfas\\",' +
                        '\\"MemberType\\": \\"Profile\\"' +
                    '}' +
                ']' +
            '}"' +
        '}';

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', fixedResponse, null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Exercise
        Test.startTest();
        List<Object> recentChanges = new RefreshRecentChanges(org.Id).execute();
        Test.stopTest();

        // Verify
        String content = (String) ((Map<String, Object>) JSON.deserializeUntyped(fixedResponse)).get('content');
        List<Object> expectedRecords = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(content)).get('records');
        System.assertEquals(expectedRecords.size(), recentChanges.size(), 'Recent changes result should match');
    }
}