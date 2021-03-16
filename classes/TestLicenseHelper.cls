@isTest
private class  TestLicenseHelper {
    @testSetup static void setupTestData(){
        TestUtilities.getTestSettingsMultilicense();
        //setup users
        TestUtilities.insertUser('manager-copado-User-11@copado.com','System Administrator');
        User mgr1 = [SELECT Id FROM User where username = 'manager-copado-User-11@copado.com'];
        TestUtilities.insertUser('manager-copado-User-22@copado.com','System Administrator');
        User mgr2 = [SELECT Id FROM User where username = 'manager-copado-User-22@copado.com'];
        TestUtilities.insertUser('anotherCopado-User-11@copado.com','System Administrator');
        User user1 = [SELECT Id FROM User where username = 'anotherCopado-User-11@copado.com'];
        user1.managerId = mgr1.Id;
        update user1;

        TestUtilities.insertUser('anotherCopado-User-22@copado.com','System Administrator');
        User user2 = [SELECT Id FROM User where username = 'anotherCopado-User-22@copado.com'];
        user2.managerId = mgr2.Id;
        update user2;
    }
    static testMethod void runAllTests(){
        System.assert(!LicenseHelper.isCopadoEnabled(),'by default is not enabled');
        System.assert(!LicenseHelper.isCCMEnabled(),'by default is not enabled');
        
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = false;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        insert license;
        
        System.assert(!LicenseHelper.isCopadoEnabled(),'only when multi licenses is enabled and license is disable');
        System.assert(!LicenseHelper.isCCMEnabled(),'only when multi licenses is enabled and license is disable');
        
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = true;
        update license;
        
        System.assert(LicenseHelper.isCopadoEnabled(),'check enabling on multi');
        System.assert(LicenseHelper.isCCMEnabled(),'check enabling on multi');
        
        license.Enable_Copado__c = false;
        license.Enable_CCM__c = false;
        update license;

        //TODO: move this to non multi-license test
        //System.assert(LicenseHelper.isCopadoEnabled(),'even disabled lic on none multi should be enabled');
        //System.assert(LicenseHelper.isCCMEnabled(),'even disabled lic on none multi should be enabled');
    }
    
    static testMethod void testconsutructors(){
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_Copado__c = true;
        license.Enable_CCM__c = false;
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;
        upsert license;
        
        LicenseHelper con = new LicenseHelper();
        system.assertEquals(true, con.copadoEnabled);
        system.assertEquals(true, con.ccmEnabled);

        license.Enable_Copado__c = false;
        license.Enable_CCM__c = true;
        update license;
        
        con = new LicenseHelper();
        system.assertEquals(false, con.copadoEnabled);
        system.assertEquals(true, con.ccmEnabled);
    }


    static testMethod void testLicensesExceeded(){
        LicenseHelper lhcon = new LicenseHelper();
        System.assertEquals(false, lhcon.licensesExceeded);

        User user1 = [SELECT Id, ManagerId FROM User where username = 'anotherCopado-User-11@copado.com'];

        LicenseManagerController con = new LicenseManagerController();
        con.dummyUser = user1;
        con.assignCopado = true;
        con.assignCAD = false;
        con.assignCCH = false;
        con.assignCCM = false;
        con.assignCST = false;
        con.assignADD = false;
        con.addUser();
        System.assert(testMethodUtilities.hasMessage(Label.LICENSE_UPSERT_SUCCESSFUL));

        User user2 = [SELECT Id, ManagerId FROM User where username = 'anotherCopado-User-22@copado.com'];

        LicenseManagerController con2 = new LicenseManagerController();
        con2.dummyUser = user2;
        con2.assignCopado = true;
        con2.assignCAD = false;
        con2.assignCCH = false;
        con2.assignCCM = false;
        con2.assignCST = false;
        con2.assignADD = false;
        con2.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.COPADO_LICENSE_LIMIT_REACHED));

        con2 = new LicenseManagerController();
        con2.dummyUser = user2;
        con2.assignCopado = false;
        con2.assignCAD = true;
        con2.assignCCH = false;
        con2.assignCCM = false;
        con2.assignCST = false;
        con2.assignADD = false;
        con2.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.CAD_LICENSE_LIMIT_REACHED));

        con2 = new LicenseManagerController();
        con2.dummyUser = user2;
        con2.assignCopado = false;
        con2.assignCAD = false;
        con2.assignCCH = true;
        con2.assignCCM = false;
        con2.assignCST = false;
        con2.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.CCH_LICENSE_LIMIT_REACHED));

        con2 = new LicenseManagerController();
        con2.dummyUser = user2;
        con2.assignCopado = false;
        con2.assignCAD = false;
        con2.assignCCH = false;
        con2.assignCCM = false;
        con2.assignADD = false;
        con2.assignCST = true;
        con2.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.CST_LICENSE_LIMIT_REACHED));

        con2 = new LicenseManagerController();
        con2.dummyUser = user2;
        con2.assignCopado = false;
        con2.assignCAD = false;
        con2.assignCCH = false;
        con2.assignCCM = true;
        con2.assignCST = false;
        con2.assignADD = false;
        con2.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.LICENSE_UPSERT_SUCCESSFUL));

        con = new LicenseManagerController();
        con.dummyUser = user1;
        con.assignCopado = false;
        con.assignCAD = false;
        con.assignCCH = false;
        con.assignCCM = true;
        con.assignCST = false;
        con.assignADD = false;
        con.addUser();

        System.assert(testMethodUtilities.hasMessage(Label.CCM_LICENSE_LIMIT_REACHED));
    }


    static testMethod void testCSTFeatureAndLicense(){
        /*
        //TODO: migrate this to a non-multilicense test
        // fails because there is no multilicense
        Settings__c setting = Settings__c.getOrgDefaults();
        setting.Enabled_Multi_Licenses__c = false;
        upsert setting;
        System.assertEquals(Label.SELENIUM_NOT_ENABLED, LicenseHelper.getPossibleCSTErrorMsg());
        */

        // fails because there is multilicense, but not CST feature
        System.assertEquals(Label.SELENIUM_NOT_ENABLED, LicenseHelper.getPossibleCSTErrorMsg());

        /*
        //TODO: move this to a multilicense with CST.
        //System.assertEquals(Label.SELENIUM_NOT_LICENSED, LicenseHelper.getPossibleCSTErrorMsg());

        // Success (returns null), because there are features and license.
        Copado_License__c license = Copado_License__c.getInstance();
        license.Enable_CST__c = true;
        insert license;
        System.assertEquals(null, LicenseHelper.getPossibleCSTErrorMsg());
        */
    }

    static testMethod void testActionIsLicenseEnabled(){
        //Settings__c settings =  TestUtilities.getTestSettingsMultilicense();
        //settings.Copado_Licenses__c = 1;
        //insert settings;

        TestUtilities.insertUser('testActionIsLicenseEnabled@copado.com','System Administrator');
        User user = [SELECT Id FROM User where username = 'testActionIsLicenseEnabled@copado.com'];

        Copado_License__c enabledLicenses = Copado_License__c.getInstance(user.Id);
        enabledLicenses.Enable_Copado__c = true;
        enabledLicenses.Enable_CCM__c  = false;
        enabledLicenses.Enable_CAD__c  = false;
        enabledLicenses.Enable_CCH__c  = false;
        enabledLicenses.Enable_CST__c  = false;

        upsert enabledLicenses;

        system.runAs(user){
            System.assertEquals(LicenseHelper.actionIsLicenseEnabled('requestComplianceScan'),true);
        }
        
    }
}