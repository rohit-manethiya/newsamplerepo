@isTest
private class TestCheckFeaturesController {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @isTest
    static void testFeaturesEnabled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            CheckFeaturesController.checkFeatures();

            List<Feature__c> featureList = [SELECT Id, Name, Enabled__c, Expiration_Date__c, Quantity__c FROM Feature__c LIMIT 1000];
            // We have 9 default enabled features and 4 custom ("Branch Management", "Change Management", "Selenium Testing" and "Compliance Hub")
            // Note: ADD is not considered in DeployAPI.cls, we should consider it later on
            System.assertEquals(13, featureList.size());

            Integer enabledFeatureCount = 0;
            for (Feature__c feature : featureList) {
                if (feature.Enabled__c) {
                    enabledFeatureCount++;
                }
            }
            System.assertEquals(13, enabledFeatureCount);

            Test.stopTest();
        }
    }

    @isTest
    static void testSetupCompleted() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            Org__c org = new Org__c(
                name = 'test',
                SFDC_Org_ID__c = Userinfo.getOrganizationId() + '_' + Userinfo.getUserId(),
                Validated_Date__c = Datetime.now()
            );
            insert org;

            Boolean setupIsCompleted = CheckFeaturesController.checkSetup();
            System.assertEquals(true, setupIsCompleted);

            Test.stopTest();
        }
    }

    @isTest
    static void testIsApplicationRegistered() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            CheckFeaturesController controller = new CheckFeaturesController();
            String namespace = Settings.ns;
            String returnedNamespace = controller.getNamespace();
            System.assertEquals(returnedNamespace, namespace, 'The namespace returned is does not match the application namespace.');

            Boolean isApplicationRegistered = CheckFeaturesController.isApplicationRegistered();
            System.assertEquals(
                false,
                isApplicationRegistered,
                'The Copado Application shows as registered without having a CryptoKEY assigned in the governance org. Please check this incorrect behavior.'
            );
            System.assertEquals(
                Label.COPADO_REGISTRATION_REQUIRED,
                controller.errorMessage,
                'The Copado Application shows as registered when it is not supposed to be. Please check the CryptoKEY configuration in Custom Settings.'
            );
            Test.stopTest();
        }
    }

    @isTest
    static void testSetupNotCompleted() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            CheckFeaturesController controller = new CheckFeaturesController();
            String namespace = Settings.ns;
            String returnedNamespace = controller.getNamespace();
            System.assertEquals(returnedNamespace, namespace);

            Boolean setupIsCompleted = CheckFeaturesController.checkSetup();
            System.assertEquals(false, setupIsCompleted);
            Test.stopTest();
        }
    }

    @isTest
    static void testLicensesEnabled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            CheckFeaturesController.checkLicenses();

            List<Copado_License__c> copadoLicenseList = [
                SELECT Id, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c
                FROM Copado_License__c
                ORDER BY SetupOwner.Name
            ];
            System.assertEquals(1, copadoLicenseList.size());

            Boolean ccmEnabled = false;
            Boolean cadEnabled = false;
            Boolean cstEnabled = false;
            Boolean copadoEnabled = false;
            Boolean cchEnabled = false;
            Boolean addEnabled = false;

            for (Copado_License__c copadoLicense : copadoLicenseList) {
                ccmEnabled = copadoLicense.Enable_CCM__c;
                cadEnabled = copadoLicense.Enable_CAD__c;
                cstEnabled = copadoLicense.Enable_CST__c;
                copadoEnabled = copadoLicense.Enable_Copado__c;
                cchEnabled = copadoLicense.Enable_CCH__c;
                addEnabled = copadoLicense.Enable_ADD__c;
            }

            System.assertEquals(true, ccmEnabled);
            System.assertEquals(true, cadEnabled);
            System.assertEquals(true, cstEnabled);
            System.assertEquals(true, copadoEnabled);
            System.assertEquals(true, cchEnabled);
            System.assertEquals(true, addEnabled);

            Test.stopTest();
        }
    }

    @isTest
    static void testOnlyCopadoLicensesEnabled() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, false, false, false, false, false);

        System.runAs(sysUser) {
            Test.startTest();
            CheckFeaturesController.checkLicenses();

            List<Copado_License__c> copadoLicenseList = [
                SELECT Id, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c
                FROM Copado_License__c
                ORDER BY SetupOwner.Name
            ];
            System.assertEquals(1, copadoLicenseList.size());

            Boolean ccmEnabled = false;
            Boolean cadEnabled = false;
            Boolean cstEnabled = false;
            Boolean copadoEnabled = false;
            Boolean cchEnabled = false;
            Boolean addEnabled = false;

            for (Copado_License__c copadoLicense : copadoLicenseList) {
                ccmEnabled = copadoLicense.Enable_CCM__c;
                cadEnabled = copadoLicense.Enable_CAD__c;
                cstEnabled = copadoLicense.Enable_CST__c;
                copadoEnabled = copadoLicense.Enable_Copado__c;
                cchEnabled = copadoLicense.Enable_CCH__c;
                addEnabled = copadoLicense.Enable_ADD__c;
            }

            System.assertEquals(false, ccmEnabled);
            System.assertEquals(false, cadEnabled);
            System.assertEquals(false, cstEnabled);
            System.assertEquals(true, copadoEnabled);
            System.assertEquals(false, cchEnabled);
            System.assertEquals(false, addEnabled);

            Test.stopTest();
        }
    }

    /*
     * These tests test the code on the FeatureHelper class.
     * As a test class does not exist for it, we will test the code here and later
     * move it into the new test class so we can push this out to customers.
     */
    @isTest
    static void testGitBackupEnabled_CopadoUser() {
        System.assertEquals(true, FeatureHelper.isFeatureEnabled('Git Backup'));
    }
}