@isTest
private class TestLicenseManagerController {
	@testSetup static void setupTestData(){
        TestUtilities.enableLicenses(1,1,1,1,1);

    }

	static testMethod void test_licenseTypeList_optionList() {
		LicenseManagerController con = new LicenseManagerController();
		List<SelectOption> options = con.getLicenseTypes();
		system.assertEquals(3, options.size());
	}
	static testMethod void test_init_multiLicense() {
		Test.startTest();
		LicenseManagerController con = new LicenseManagerController();

		String copadoLicenses = '1';
		String ccmLicenses = '1';
        String cstLicenses = '1';
        String cadLicenses = '1';
        String cchLicenses = '1';
		String multiLicenses = 'true';
		String b = '{"customerOrg":{"Name":"Copado Development Org","orgId":"00D24000000aZrZEAU","autoRecharge":false,"credits":99818,"userId":"005240000012JyBAAU","copadoLicenses":'+copadoLicenses+',"ccmLicenses":'+ccmLicenses+',"cstLicenses":'+cstLicenses+',"cadLicenses":'+cadLicenses+',"multiLicenses":'+multiLicenses+',"id":73011},"userInfo":{"accessibilityMode__is_set":true}}';
    	Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		system.assertEquals(Integer.valueOf(copadoLicenses), Integer.valueOf(con.copadoLicensesAvailable));
		system.assertEquals(Integer.valueOf(ccmLicenses), Integer.valueOf(con.ccmLicensesAvailable));
		system.assertEquals(Integer.valueOf(cstLicenses), Integer.valueOf(con.cstLicensesAvailable));
		system.assertEquals(Boolean.valueOf(multiLicenses), con.enableMultiLicenses);
		system.assertEquals(0, con.copadoLicensesUsed);
		system.assertEquals(0, con.ccmLicensesUsed);
		system.assertEquals(0, con.cstLicensesUsed);
		system.assertEquals(0, con.cadLicensesUsed);
		TestUtilities.insertAdminUsers(new List<String>{'user1-TestLicenseManager@test-copado.org', 'user2-TestLicenseManager@test-copado.org'});
		List<User> users = [Select Id, Name From User Where Username = 'user1-TestLicenseManager@test-copado.org' OR Username = 'user2-TestLicenseManager@test-copado.org' Limit 2];
		if(users.size()==2){

			con.dummyUser.ManagerId = null;
			con.addUser();
			system.assert(testMethodUtilities.hasMessage(Label.MUST_SELECT_USER));

			// Add 'Phil' as Copado 
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = true;
			con.assignCCM = false;
            con.assignCST = true;
            con.assignCAD = false;
            con.assignCCH = false;
            con.assignADD = true;
			con.addUser();
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());
            system.assertEquals(1, con.cstLicensesUsed);
            system.assertEquals(1, con.cstUsage.size());
			system.assertEquals(1, con.addLicensesUsed);
			system.assertEquals(1, con.addUsage.size());

			// Add 'Fede' as Copado = Copado expect license reached
			con.dummyUser.ManagerId = users[1].Id;
			con.assignCopado = true;
			con.assignCCM = false;
			con.addUser();
			system.assert(testMethodUtilities.hasMessage(Label.COPADO_LICENSE_LIMIT_REACHED));
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());

            // Add 'Fede' as CST = Copado expect license reached
			con.dummyUser.ManagerId = users[1].Id;
			con.assignCopado = false;
			con.assignCCM = false;
            con.assignCST = true;
            con.assignCCH =false;
			con.addUser();
			system.assert(testMethodUtilities.hasMessage(Label.CST_LICENSE_LIMIT_REACHED));
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());
			system.assertEquals(1, con.cstLicensesUsed);
			system.assertEquals(1, con.cstUsage.size());
            
			// Add 'Fede' as CCM 
			con.dummyUser.ManagerId = users[1].Id;
			con.assignCopado = false;
			con.assignCCM = true;
            con.assignCST = false;
			con.addUser();
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(1, con.ccmLicensesUsed);
			system.assertEquals(1, con.ccmUsage.size());

			// Add 'Phil' as CCM = CCM expect license reached
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = false;
			con.assignCCM = true;
            con.assignCST = false;
			con.addUser();
			system.assert(testMethodUtilities.hasMessage(Label.CCM_LICENSE_LIMIT_REACHED));
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(1, con.ccmLicensesUsed);
			system.assertEquals(1, con.ccmUsage.size());

			// Add 'Fede' as Copado = Copado expect license reached
			con.dummyUser.ManagerId = users[1].Id;
			con.assignCopado = true;
			con.assignCCM = false;
            con.assignCST = false;
			con.addUser();
			system.assert(testMethodUtilities.hasMessage(Label.COPADO_LICENSE_LIMIT_REACHED));
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(1, con.ccmLicensesUsed);
			system.assertEquals(1, con.ccmUsage.size());

			// Now test removal of license
			system.assertEquals(1, con.ccmLicensesUsed);
			con.ccmUsage[0].removeAssignment();

			// Now remove 'Phil'
			con.copadoUsage[0].removeAssignment();
			system.assertEquals(0, con.copadoLicensesUsed);

            // Now remove 'Phil' as CST user
			con.cstUsage[0].removeAssignment();
			system.assertEquals(0, con.cstLicensesUsed);

			// Add 'Phil' as Copado only = expect success
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = false;
			con.assignCCM = true;
            con.assignCST = false;
			con.addUser();
			system.assertEquals(0, con.copadoLicensesUsed);
			system.assertEquals(0, con.copadoUsage.size());
			system.assertEquals(1, con.ccmLicensesUsed);
			system.assertEquals(1, con.ccmUsage.size());

			// Add 'Phil' as CCM also = expect success
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = true;
			con.assignCCM = true;
            con.assignCST = false;
			con.addUser();
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(1, con.ccmLicensesUsed);
			system.assertEquals(1, con.ccmUsage.size());

			// Remove 'Phil' expect success
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = true;
			con.assignCCM = false;
            con.assignCST = false;
			con.addUser();
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());

			// Retrieve existing licenses for selected user
			con.dummyUser.ManagerId = users[0].Id;
			con.retrieveCopadoLicenses();
			system.assertEquals(1, con.copadoLicensesUsed);
			system.assertEquals(1, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());

			// Remove 'Phil' expect success
			con.dummyUser.ManagerId = users[0].Id;
			con.assignCopado = false;
			con.assignCCM = false;
            con.assignCST = false;
			con.addUser();
			system.assertEquals(0, con.copadoLicensesUsed);
			system.assertEquals(0, con.copadoUsage.size());
			system.assertEquals(0, con.ccmLicensesUsed);
			system.assertEquals(0, con.ccmUsage.size());

			//test exception on method
			system.assert(con.licenseCountExceeded('badValue'));
			Test.stopTest();

		}
	}
}