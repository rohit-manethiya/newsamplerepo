@IsTest
private with sharing class ValidateOrgActionTest {
    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            Org__c org = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', null);
            org.Oauth_Signature__c = 'test';
            org.Disable_Validation__c = false;
            insert org;
        }
    }

    @IsTest
    private static void noOauthSignature() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];
            org.Oauth_Signature__c = null;
            update org;

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(false, valid, 'Org should not be valid');
        }
    }

    @IsTest
    private static void disabledValidation() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];
            org.Disable_Validation__c = true;
            update org;

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(true, valid, 'Org should be valid');
        }
    }

    @IsTest
    private static void scratchOrg() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];
            org.Org_Type__c = 'Scratch Org';
            update org;

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(true, valid, 'Org should be valid');
        }
    }

    @IsTest
    private static void alreadyValidated() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];
            org.Validated_Date__c = Datetime.now();
            update org;

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(true, valid, 'Org should be valid');
        }
    }

    @IsTest
    private static void validateOrgOk() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id, sfdc_org_id__c FROM Org__c LIMIT 1];

            ValidateOrgResponse response = successResponse(org.sfdc_org_id__c);
            new HttpMock().get('/json/v1/validateOrg/' + org.Id, response).mock();

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(true, valid, 'Org should be validated');
        }
    }

    @IsTest
    private static void validateOrgError() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            ValidateOrgResponse response = errorResponse();
            new HttpMock().get('/json/v1/validateOrg/' + org.Id, response).mock();

            // Exercise
            Test.startTest();
            Boolean valid = ValidateOrgAction.execute(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(false, valid, 'Org should not be validated');
        }
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }

    private static ValidateOrgResponse successResponse(String sfdcOrgId) {
        ValidateOrgResponse response = new ValidateOrgResponse();
        response.organizationId = sfdcOrgId;
        return response;
    }

    private static ValidateOrgResponse errorResponse() {
        return new ValidateOrgResponse();
    }

    private class ValidateOrgResponse {
        public String organizationId;
    }
}