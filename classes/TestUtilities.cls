@IsTest
/**
 * Starting with 28.0 API version describe will have namespace included in the map key
 * so changing this class api version to one above 27 will cause current usages of getNamespace method to fail
 */
public class TestUtilities {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(10, 10, 10, 10, 10, 100);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }
    public static String getTestNameSpace() {
        String namespace = CopadoSetupController.class.getName().substringBefore('CopadoSetupController').removeEnd('.').toLowerCase();
        return namespace == 'copado' ? 'copado__' : 'none';
    }
    public static void setTestSettingsEE() {
        enableLicenses(1, 0, 0, 0, 0, 0);
    }
    public static Settings__c getTestSettings() {
        Blob key = Crypto.generateAesKey(256);
        Settings__c s = new Settings__c(
            Namespace__c = getTestNameSpace(),
            Server_URL__c = 'test.com',
            Enabled_Multi_Licenses__c = false,
            CryptoKEY__c = EncodingUtil.base64Encode(key)
        );
        return s;
    }
    public static void getTestSettingsMultilicense() {
        enableLicenses(1, 1, 0, 0, 0, 0);
    }
    public static void getAllMultilicense() {
        enableLicenses(10, 10, 10, 10, 10, 10);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst) {
        enableLicenses(copado, ccm, cst, 0, 0, 0);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst, Integer cad, Integer cch) {
        enableLicenses(copado, ccm, cst, cad, cch, 0);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst, Integer cad, Integer cch, Integer cbmBranches) {
        //ucu added this based on US-0003624 to prevent test classes to fail on their sandboxs
        try {
            FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', copado);
            FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', ccm);
            FeatureManagement.setPackageIntegerValue('CST_Licenses_Enabled', cst);
            FeatureManagement.setPackageIntegerValue('CAD_Licenses_Enabled', cad);
            FeatureManagement.setPackageIntegerValue('CCH_Licenses_Enabled', cch);
            FeatureManagement.setPackageIntegerValue('CBM_Branches', cbmBranches);
        } catch (DmlException exc) {
            System.debug('Exception is the following====> ' + exc.getMessage());
        }
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst, Integer cad, Integer cch, Integer cbmBranches, Integer add) {
        try {
            FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', copado);
            FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', ccm);
            FeatureManagement.setPackageIntegerValue('CST_Licenses_Enabled', cst);
            FeatureManagement.setPackageIntegerValue('CAD_Licenses_Enabled', cad);
            FeatureManagement.setPackageIntegerValue('CCH_Licenses_Enabled', cch);
            FeatureManagement.setPackageIntegerValue('CBM_Branches', cbmBranches);
            FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', add);
        } catch (DmlException exc) {
            System.debug('Exception is the following====> ' + exc.getMessage());
        }
    }
    public static void exceedCopadoLicenses() {
        LicenseManagerController con = new LicenseManagerController();

        String copadoLicenses = '2';
        String ccmLicenses = '2';
        String cstLicenses = '2';
        String cadLicenses = '2';
        String cchLicenses = '2';
        String multiLicenses = 'true';
        String b =
            '{"customerOrg":{"Name":"Copado Development Org","orgId":"00D24000000aZrZEAU","autoRecharge":false,"credits":99818,"userId":"005240000012JyBAAU","copadoLicenses":' +
            copadoLicenses +
            ',"ccmLicenses":' +
            ccmLicenses +
            ',"cstLicenses":' +
            cstLicenses +
            ',"cadLicenses":' +
            cadLicenses +
            ',"multiLicenses":' +
            multiLicenses +
            ',"id":73011},"userInfo":{"accessibilityMode__is_set":true}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        insertAdminUsers(new List<String>{ 'user1-TestUtilities@test-copado.org', 'user2-TestUtilities@test-copado.org' });
        List<User> users = [
            SELECT Id, Name
            FROM User
            WHERE Username = 'user1-TestUtilities@test-copado.org' OR Username = 'user2-TestUtilities@test-copado.org'
            LIMIT 2
        ];
        System.debug(users);
        if (users.size() == 2) {
            // Add User1 as Copado
            con.dummyUser.ManagerId = users[0].Id;
            con.assignCopado = true;
            con.assignCCM = false;
            con.assignCST = true;
            con.assignCAD = false;
            con.assignCCH = false;
            con.addUser();

            // Add User1 as Copado
            con.dummyUser.ManagerId = users[1].Id;
            con.assignCopado = true;
            con.assignCCM = true;
            con.addUser();

            // Exceed the Copado Licenses by reducing the available licenses to 1.
            //CANNOT UPDATE PROVISIONING
            //enableLicenses(1, 2, 2, 2, 2);
        }
    }
    public static void assignLicense(String username, Boolean copadoEnabled, Boolean ccmEnabled, Boolean cstEnabled) {
        User u = [SELECT Id FROM User WHERE Username = :username];
        Copado_License__c license = new Copado_License__c();
        license.Enable_Copado__c = copadoEnabled;
        license.Enable_CCM__c = ccmEnabled;
        license.Enable_CST__c = cstEnabled;
        license.SetupOwnerId = u.Id;
        Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.SObjectType.Copado_License__c);
    }
    public static void assignLicense(
        String username,
        Boolean copadoEnabled,
        Boolean ccmEnabled,
        Boolean cstEnabled,
        Boolean cadEnabled,
        Boolean cchEnabled
    ) {
        User u = [SELECT Id FROM User WHERE Username = :username];
        Copado_License__c license = Copado_License__c.getInstance(u.Id);
        license.Enable_Copado__c = copadoEnabled;
        license.Enable_CCM__c = ccmEnabled;
        license.Enable_CST__c = cstEnabled;
        license.Enable_CAD__c = cadEnabled;
        license.Enable_CCH__c = cchEnabled;
        Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.SObjectType.Copado_License__c);
    }
    public static void assignLicense(
        String username,
        Boolean copadoEnabled,
        Boolean ccmEnabled,
        Boolean cstEnabled,
        Boolean cadEnabled,
        Boolean cchEnabled,
        Boolean addEnabled
    ) {
        User u = [SELECT Id FROM User WHERE Username = :username];
        Copado_License__c license = Copado_License__c.getInstance(u.Id);
        license.Enable_Copado__c = copadoEnabled;
        license.Enable_CCM__c = ccmEnabled;
        license.Enable_CST__c = cstEnabled;
        license.Enable_CAD__c = cadEnabled;
        license.Enable_CCH__c = cchEnabled;
        license.Enable_ADD__c = addEnabled;
        Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.SObjectType.Copado_License__c);
    }
    public static void insertUser(String username, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        User futureUser = new User(
            FirstName = 'Future',
            LastName = 'User',
            Alias = 'future',
            Email = 'test@test.org',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = username
        );
        Utilities.Secure_DML(futureUser, Utilities.DML_Action.UPS, schema.SObjectType.User);
    }
    public static void insertAdminUsers(List<String> usernames) {
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        for (String username : usernames) {
            User futureUser = new User(
                FirstName = 'Future',
                LastName = 'User',
                Alias = 'future',
                Email = 'test@test.org',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = username
            );
            users.add(futureUser);
        }
        Utilities.Secure_DML(users, Utilities.DML_Action.UPS, schema.SObjectType.User);
    }
    static testMethod void runAllTests() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Org__c testFromOrg = testMethodUtilities.createOrg('a', 'b', 'd', 'e', 'f', System.now());
            insert testFromOrg;
            Deployment__c testDeployment = testMethodUtilities.create('a', System.now(), System.now(), testFromOrg.Id, 'c', 'd');
            insert testDeployment;
            Step__c testStep = testMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'e', 'f');
            insert testStep;
            Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'b', testFromOrg.Id);
            insert testDestOrg;
            Deployment_Job__c testJob = testMethodUtilities.create(0, testDestOrg.Id, 'b', 'c', testStep.Id);
            insert testJob;
            Test.startTest();
            Utilities con = new Utilities();
            Utilities.resetStatuses(testDeployment.Id, true);
            System.assertEquals('In progress', Utilities.getStepsByDeploymentId(testDeployment.Id)[0].Status__c);
            System.assertEquals(
                'Pending',
                [SELECT Id, Status__c, Step__r.Deployment__c FROM Deployment_Job__c WHERE Step__r.Deployment__c = :testDeployment.Id][0]
                .Status__c
            );
            System.assertEquals(
                'Pending',
                [
                    SELECT Id, Early_Completion_Status__c, Step__r.Deployment__c
                    FROM Deployment_Job__c
                    WHERE Step__r.Deployment__c = :testDeployment.Id
                ][0]
                .Early_Completion_Status__c
            );

            String strFields = Utilities.describeFields('WRONGOBJECT');
            System.assertEquals(null, strFields);
            strFields = Utilities.describeFields('Account');
            System.debug(strFields);
            System.assert(strFields.contains('Name'));
            Blob myBlob = Blob.valueOf(strFields);
            Utilities.insertAttachment(myBlob, 'att name', 'text', testDeployment.Id);

            Boolean isValid = false;
            Org__c[] allorgs = Utilities.getAllOrgs();
            for (Org__c o : Utilities.getAllOrgs()) {
                if (o.Id == testFromOrg.Id) {
                    isValid = true;
                }
            }
            System.assert(isValid);

            Org__c org = Utilities.getOrgById(testFromOrg.Id);
            Utilities.doOauth(org);
            System.assert(org != null);

            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('1', 'test1'));
            options.add(new SelectOption('2', 'test2'));
            options.add(new SelectOption('3', 'test3'));
            options = Utilities.selectOptionSortByLabel(options);

            Deployment__c dep = Utilities.getDeploymentById(testDeployment.Id);
            System.assert(dep != null);

            isValid = false;
            for (Step__c s : Utilities.getStepsByDeploymentId(testDeployment.Id)) {
                if (s.Id == testStep.Id) {
                    isValid = true;
                }
            }
            System.assert(isValid);

            Step__c s = Utilities.getStepById(testStep.Id);
            System.assert(s != null);

            isValid = false;
            for (Destination_Org__c x : Utilities.getDestinationOrgsByDeploymentId(testDeployment.Id)) {
                if (x.Id == testDestOrg.Id) {
                    isValid = true;
                }
            }
            System.assert(isValid);

            Destination_Org__c dest = Utilities.getDestinationOrgsById(testDestOrg.Id);
            System.assert(dest != null);

            con.httpGet('www.herokuUrl.com/forCopado');
            for (Integer i = 0; i < 20; i++) {
                System.assert(Utilities.randomInteger(0, 4) <= 4);
                System.assert(Utilities.randomInteger(0, 4) >= 0);
            }
            for (Integer i = 0; i < 100; i++) {
                System.assert(Utilities.randomInteger(0, 59) <= 59);
                System.assert(Utilities.randomInteger(0, 59) >= 0);
            }

            Utilities.getCopadoLicenses('testUsername');
            Utilities.getPermissionSetById(dest.Id);

            Git_Repository__c gitRepo = new Git_Repository__c(Name = 'test');
            Git_Repository__c gitRepo2 = new Git_Repository__c(Name = 'test');
            insert new List<Git_Repository__c>{ gitRepo, gitRepo2 };
            System.assertNotEquals(null, gitRepo.Id);
            System.assertEquals(gitRepo.Id, Utilities.getGitById(gitRepo.Id).Id);
            upsert gitRepo;
            delete gitRepo;

            Release__c release = new Release__c(Name = 'Winter Release');
            insert release;
            System.assertEquals(release.Id, Utilities.getReleaseById(release.Id).Id);

            Environment__c env1 = new Environment__c(Name = 'UAT Environment', Type__c = 'Production');
            Environment__c env2 = new Environment__c(Name = 'PROD Environment', Type__c = 'Production');
            insert new List<Environment__c>{ env1, env2 };
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, System.now(), env2.Id);
            Org__c testOrgDMLs = new Org__c(Name = 'Test Secure DMLs Org', SFDC_Org_ID__c = 'FAKEORGIDTESTDML');
            insert new List<Org__c>{ testOrg1, testOrg2, testOrgDMLs };
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Utilities.getEnvsAndBranchesOfDeploymentFlow(flow.Id);
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;
            Utilities.getStepDetailsOfDeploymentFlow(dfs.Id);
            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            insert testPromotion;
            User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
            insert testUserStory;

            Promotion__c promotion = Utilities.getPromotionById(testPromotion.Id);
            System.assert(promotion != null);

            User_Story__c userStory = Utilities.getUserStoryById(testUserStory.Id);
            System.assert(userStory != null);

            String namespace = Settings.ns;
            Utilities.sendEmail('test@test.com', 'test', 'test');
            Utilities.getPicklistValues(namespace + 'User_Story__c', namespace + 'Status__c');
            Utilities.isChatterEnabled(namespace + 'Deployment__c');
            Utilities.getClassicSessionId();

            Git_Backup__c snap = new Git_Backup__c(Name = 'TestUtils Test', Git_Repository__c = gitRepo2.Id, Org__c = testOrgDMLs.Id);
            insert snap;
            System.assertEquals(snap.Id, Utilities.getGitBackupById(snap.Id).Id);

            //Test Secure DMLs missing
            Utilities.Secure_DML(testOrgDMLs, Utilities.DML_Action.UPD, schema.SObjectType.Org__c);
            Utilities.Secure_DML(testOrgDMLs, Utilities.DML_Action.DEL, schema.SObjectType.Org__c, null);

            External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name = 'Jenkins Test', CI_Tool__c = 'Jenkins');
            External_CI_Setting__c externalCISetting2 = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
            insert new List<External_CI_Setting__c>{ externalCISetting, externalCISetting2 };
            System.assertEquals(externalCISetting.Id, Utilities.getCISettingById(externalCISetting.Id).Id);

            External_CI_Job__c externalCIJob = new External_CI_Job__c(Name = 'Jenkins Test', External_CI_Setting__c = externalCISetting.Id);
            External_CI_Job__c externalCIJob2 = new External_CI_Job__c(
                Name = 'Job1',
                User_Story__c = testUserStory.Id,
                External_CI_Setting__c = externalCISetting2.Id
            );
            insert new List<External_CI_Job__c>{ externalCIJob, externalCIJob2 };
            System.assertEquals(externalCIJob.Id, Utilities.getCIJobById(externalCIJob.Id).Id);

            External_CI_Job__c eCIjob2 = Utilities.getCIJobById(externalCIJob2.Id);
            System.assert(eCIjob2 != null);
            Deployment_Flow__c df2 = Utilities.getDeploymentFlowById(flow.Id);
            System.assert(df2 != null);

            String sId = Utilities.getClassicSessionId();
            System.assert(sId != null);

            Test.stopTest();
        }
    }

    public static void createTestDataForStandardPipeline(User adminUser) {
        List<Environment__c> environmentList = new List<Environment__c>();
        List<Org__c> orgCredList = new List<Org__c>();
        List<Git_Repository__c> gitRepoList = new List<Git_Repository__c>();
        List<Deployment_Flow__c> deploymentFlowList = new List<Deployment_Flow__c>();
        List<Deployment_Flow_Step__c> deploymentFlowStepList = new List<Deployment_Flow_Step__c>();
        List<Project__c> projectList = new List<Project__c>();
        List<Release__c> releaseList = new List<Release__c>();
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        List<Promotion__c> promotionList = new List<Promotion__c>();
        List<Promoted_User_Story__c> promotesusList = new List<Promoted_User_Story__c>();

        //Environment creation
        Environment__c envProd = new Environment__c();
        envProd.Name = 'Production env';
        envProd.Index_Back_Promotion_metadata__c = true;
        envProd.Type__c = 'Production/Developer';
        environmentList.add(envProd);

        Environment__c envUat = new Environment__c();
        envUat.Name = 'UAT env';
        envUat.Index_Back_Promotion_metadata__c = true;
        envUat.Type__c = 'Production/Developer';
        environmentList.add(envUat);

        Environment__c envUat2 = new Environment__c();
        envUat2.Name = 'UAT2 env';
        envUat2.Index_Back_Promotion_metadata__c = true;
        envUat2.Type__c = 'Production/Developer';
        environmentList.add(envUat2);

        Environment__c envDev1 = new Environment__c();
        envDev1.Name = 'Dev1 env';
        envDev1.Index_Back_Promotion_metadata__c = true;
        envDev1.Type__c = 'Production/Developer';
        environmentList.add(envDev1);

        Environment__c envDev2 = new Environment__c();
        envDev2.Name = 'Dev2 env';
        envDev2.Index_Back_Promotion_metadata__c = true;
        envDev2.Type__c = 'Production/Developer';
        environmentList.add(envDev2);

        Environment__c envDev21 = new Environment__c();
        envDev21.Name = 'Dev21 env';
        envDev21.Index_Back_Promotion_metadata__c = true;
        envDev21.Type__c = 'Production/Developer';
        environmentList.add(envDev21);

        Environment__c envDev22 = new Environment__c();
        envDev22.Name = 'Dev22 env';
        envDev22.Index_Back_Promotion_metadata__c = true;
        envDev22.Type__c = 'Production/Developer';
        environmentList.add(envDev22);

        Utilities.Secure_DML(environmentList, Utilities.DML_Action.INS, Schema.SObjectType.Environment__c);

        // Org Credential creation
        Org__c adminCred = new Org__c();
        adminCred.Name = UserInfo.getOrganizationName().left(80);
        adminCred.Org_Type__c = 'Production/Developer';
        adminCred.Username__c = adminUser.Id;
        adminCred.Environment__c = environmentList[0].Id;
        orgCredList.add(adminCred);

        Org__c uatCred = new Org__c();
        uatCred.Name = 'Uat';
        uatCred.Org_Type__c = 'Production/Developer';
        uatCred.Oauth_Signature__c = 'signature';
        uatCred.Username__c = ('Integration' + adminUser.Username);
        uatCred.Environment__c = environmentList[1].Id;
        orgCredList.add(uatCred);

        Org__c uatCred2 = new Org__c();
        uatCred2.Name = 'Uat2';
        uatCred2.Org_Type__c = 'Production/Developer';
        uatCred2.Oauth_Signature__c = 'signature';
        uatCred2.Username__c = ('Integration 2' + adminUser.Username);
        uatCred2.Environment__c = environmentList[2].Id;
        orgCredList.add(uatCred2);

        Org__c Dev1Cred = new Org__c();
        Dev1Cred.Name = 'Dev1';
        Dev1Cred.Org_Type__c = 'Production/Developer';
        Dev1Cred.Oauth_Signature__c = 'signature';
        Dev1Cred.Username__c = ('Dev1' + adminUser.Username);
        Dev1Cred.Environment__c = environmentList[3].Id;
        orgCredList.add(Dev1Cred);

        Org__c Dev2Cred = new Org__c();
        Dev2Cred.Name = 'Dev2';
        Dev2Cred.Org_Type__c = 'Production/Developer';
        Dev2Cred.Oauth_Signature__c = 'signature';
        Dev2Cred.Username__c = ('Dev2' + adminUser.Username);
        Dev2Cred.Environment__c = environmentList[4].Id;
        orgCredList.add(Dev2Cred);

        Org__c Dev21Cred = new Org__c();
        Dev21Cred.Name = 'Dev21';
        Dev21Cred.Org_Type__c = 'Production/Developer';
        Dev21Cred.Oauth_Signature__c = 'signature';
        Dev21Cred.Username__c = ('Dev21' + adminUser.Username);
        Dev21Cred.Environment__c = environmentList[5].Id;
        orgCredList.add(Dev21Cred);

        Org__c Dev22Cred = new Org__c();
        Dev22Cred.Name = 'Dev22';
        Dev22Cred.Org_Type__c = 'Production/Developer';
        Dev22Cred.Oauth_Signature__c = 'signature';
        Dev22Cred.Username__c = ('Dev22' + adminUser.Username);
        Dev22Cred.Environment__c = environmentList[6].Id;
        orgCredList.add(Dev22Cred);

        Utilities.Secure_DML(orgCredList, Utilities.DML_Action.INS, Schema.SObjectType.Org__c);

        // Create git repository for DF 1 (Test 1)
        Git_Repository__c df1 = new Git_Repository__c();
        df1.Name = 'Test pipeline manager DF1';
        df1.URI__c = 'git@gitlab.com:copadodev/devtest1.git';
        gitRepoList.add(df1);

        // Create git repository for DF 2 (Test 2)
        Git_Repository__c df2 = new Git_Repository__c();
        df1.Name = 'Test pipeline manager DF2';
        df1.URI__c = 'git@gitlab.com:copadodev/devtest2.git';
        gitRepoList.add(df2);

        Utilities.Secure_DML(gitRepoList, Utilities.DML_Action.INS, Schema.SObjectType.Git_Repository__c);

        // Create deployment flow 1 Test 1
        Deployment_Flow__c dpf1 = new Deployment_Flow__c();
        dpf1.Name = 'test 1';
        dpf1.Active__c = true;
        dpf1.Main_Branch__c = 'master';
        dpf1.Calculate_Based_on__c = 'User Story';
        dpf1.Git_Repository__c = gitRepoList[0].Id;
        deploymentFlowList.add(dpf1);

        // Create deployment flow step for DF2 (Test 2)
        Deployment_Flow__c dpf2 = new Deployment_Flow__c();
        dpf2.Name = 'test 2';
        dpf2.Active__c = false;
        dpf2.Main_Branch__c = 'master';
        dpf2.Calculate_Based_on__c = 'User Story';
        dpf2.Git_Repository__c = gitRepoList[1].Id;
        deploymentFlowList.add(dpf2);

        Utilities.Secure_DML(deploymentFlowList, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow__c);

        //DeploymentFlowSteps for deployment flows created before
        Deployment_Flow_Step__c dfstepProd = new Deployment_Flow_Step__c();
        dfstepProd.Branch__c = 'uat';
        dfstepProd.Destination_Branch__c = 'master';
        dfstepProd.Deployment_Flow__c = deploymentFlowList[0].Id;
        dfstepProd.Source_Environment__c = orgCredList[1].Environment__c;
        dfstepProd.Destination_Environment__c = orgCredList[0].Environment__c;
        deploymentFlowStepList.add(dfstepProd);

        Deployment_Flow_Step__c dfstepDev1 = new Deployment_Flow_Step__c();
        dfstepDev1.Branch__c = 'dev1';
        dfstepDev1.Destination_Branch__c = 'uat';
        dfstepDev1.Deployment_Flow__c = deploymentFlowList[0].Id;
        dfstepDev1.Source_Environment__c = orgCredList[3].Environment__c;
        dfstepDev1.Destination_Environment__c = orgCredList[1].Environment__c;
        deploymentFlowStepList.add(dfstepDev1);

        Deployment_Flow_Step__c dfstepDev2 = new Deployment_Flow_Step__c();
        dfstepDev2.Branch__c = 'dev2';
        dfstepDev2.Destination_Branch__c = 'uat';
        dfstepDev2.Deployment_Flow__c = deploymentFlowList[0].Id;
        dfstepDev2.Source_Environment__c = orgCredList[4].Environment__c;
        dfstepDev2.Destination_Environment__c = orgCredList[1].Environment__c;
        deploymentFlowStepList.add(dfstepDev2);

        Deployment_Flow_Step__c dfstepProd2 = new Deployment_Flow_Step__c();
        dfstepProd2.Branch__c = 'uat2';
        dfstepProd2.Destination_Branch__c = 'master';
        dfstepProd2.Deployment_Flow__c = deploymentFlowList[1].Id;
        dfstepProd2.Source_Environment__c = orgCredList[2].Environment__c;
        dfstepProd2.Destination_Environment__c = orgCredList[0].Environment__c;
        deploymentFlowStepList.add(dfstepProd2);

        Deployment_Flow_Step__c dfstepDev21 = new Deployment_Flow_Step__c();
        dfstepDev21.Branch__c = 'dev21';
        dfstepDev21.Destination_Branch__c = 'uat2';
        dfstepDev21.Deployment_Flow__c = deploymentFlowList[1].Id;
        dfstepDev21.Source_Environment__c = orgCredList[5].Environment__c;
        dfstepDev21.Destination_Environment__c = orgCredList[2].Environment__c;
        deploymentFlowStepList.add(dfstepDev21);

        Deployment_Flow_Step__c dfstepDev22 = new Deployment_Flow_Step__c();
        dfstepDev22.Branch__c = 'dev22';
        dfstepDev22.Destination_Branch__c = 'uat2';
        dfstepDev22.Deployment_Flow__c = deploymentFlowList[1].Id;
        dfstepDev22.Source_Environment__c = orgCredList[6].Environment__c;
        dfstepDev22.Destination_Environment__c = orgCredList[2].Environment__c;
        deploymentFlowStepList.add(dfstepDev22);

        Utilities.Secure_DML(deploymentFlowStepList, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow_Step__c);

        //Projects Creation
        Project__c pr1 = new Project__c();
        pr1.Name = 'Project 1';
        pr1.Deployment_Flow__c = deploymentFlowList[0].Id;
        pr1.Index_Metadata__c = true;
        pr1.Status__c = 'In progress';
        pr1.Start_Date__c = System.Date.today() - 1;
        projectList.add(pr1);

        Project__c pr2 = new Project__c();
        pr2.Name = 'Project 2';
        pr2.Deployment_Flow__c = deploymentFlowList[0].Id;
        pr2.Index_Metadata__c = true;
        pr2.Status__c = 'In progress';
        pr2.Start_Date__c = System.Date.today() - 1;
        projectList.add(pr2);

        Project__c pr3 = new Project__c();
        pr3.Name = 'Project 3';
        pr3.Deployment_Flow__c = deploymentFlowList[1].Id;
        pr3.Index_Metadata__c = true;
        pr3.Status__c = 'In progress';
        pr3.Start_Date__c = System.Date.today() - 1;
        projectList.add(pr3);

        Utilities.Secure_DML(projectList, Utilities.DML_Action.INS, Schema.SObjectType.Project__c);

        Release__c rel1 = new Release__c();
        rel1.Name = 'Release 1';
        rel1.Status__c = 'Planned';
        rel1.Project__c = projectList[0].Id;
        rel1.Version__c = '1.0';
        releaseList.add(rel1);

        Release__c rel2 = new Release__c();
        rel2.Name = 'Release 2';
        rel2.Status__c = 'Planned';
        rel2.Project__c = projectList[0].Id;
        rel2.Version__c = '2.0';
        releaseList.add(rel2);

        Utilities.Secure_DML(releaseList, Utilities.DML_Action.INS, Schema.SObjectType.Release__c);

        //User Story Creation for promotion
        User_Story__c us1 = new User_Story__c();
        us1.User_Story_Title__c = 'Us 1';
        us1.Project__c = projectList[0].Id;
        us1.Release__c = releaseList[0].Id;
        us1.Org_Credential__c = orgCredList[3].Id;
        us1.Promote_Change__c = true;
        us1.Has_Apex_Code__c = true;
        userStoryList.add(us1);

        User_Story__c us2 = new User_Story__c();
        us2.User_Story_Title__c = 'Us 2';
        us2.Project__c = projectList[1].Id;
        us2.Org_Credential__c = orgCredList[3].Id;
        us2.Promote_Change__c = true;
        userStoryList.add(us2);

        User_Story__c us3 = new User_Story__c();
        us3.User_Story_Title__c = 'Us 3';
        us3.Project__c = projectList[1].Id;
        us3.Org_Credential__c = orgCredList[4].Id;
        us3.Promote_Change__c = true;
        userStoryList.add(us3);

        User_Story__c us4 = new User_Story__c();
        us4.User_Story_Title__c = 'Us 4';
        us4.Project__c = projectList[0].Id;
        us4.Release__c = releaseList[0].Id;
        us4.Org_Credential__c = orgCredList[3].Id;
        us4.Promote_Change__c = true;
        us4.Has_Apex_Code__c = true;
        userStoryList.add(us4);

        //User Story Creation for backpromotion
        User_Story__c usback1 = new User_Story__c();
        usback1.User_Story_Title__c = 'Us back 1';
        usback1.Project__c = projectList[0].Id;
        usback1.Org_Credential__c = orgCredList[1].Id;
        usback1.Promote_Change__c = true;
        usback1.Has_Apex_Code__c = true;
        userStoryList.add(usback1);

        //User Story In Progress Creation
        User_Story__c usInProgress = new User_Story__c();
        usInProgress.User_Story_Title__c = 'Us in progress';
        usInProgress.Project__c = projectList[0].Id;
        usInProgress.Org_Credential__c = orgCredList[1].Id;
        usInProgress.Has_Apex_Code__c = true;
        usInProgress.Status__c = 'In Progress';
        userStoryList.add(usInProgress);

        Utilities.Secure_DML(userStoryList, Utilities.DML_Action.INS, Schema.SObjectType.User_Story__c);

        // Approval process for previous user story
        /*Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(userStoryList[4].Id);
        Approval.ProcessResult result = Approval.process(app);*/

        //Promotion creation from dev1 to uat
        Promotion__c pr = new Promotion__c();
        pr.Project__c = projectList[0].Id;
        pr.Source_Org_Credential__c = orgCredList[3].Id;
        pr.Source_Environment__c = environmentList[3].Id;
        pr.Destination_Org_Credential__c = orgCredList[1].Id;
        pr.Destination_Environment__c = environmentList[1].Id;
        pr.Status__c = 'Completed';
        promotionList.add(pr);

        Utilities.Secure_DML(promotionList, Utilities.DML_Action.INS, Schema.SObjectType.Promotion__c);

        Promoted_User_Story__c prmus = new Promoted_User_Story__c();
        prmus.User_Story__c = userStoryList[4].Id;
        prmus.Promotion__c = promotionList[0].Id;
        promotesusList.add(prmus);

        Utilities.Secure_DML(promotesusList, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);
    }
    public static testMethod Metadata_Group__c createMetadataGroup() {
        Metadata_Group__c thisGroup = new Metadata_Group__c();
        thisGroup.Name = 'Test Group';
        thisGroup.Description__c = 'Some description';
        return thisGroup;
    }

    public static void createAllDXTestData() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c dev1 = new Environment__c();
        dev1.Name = 'Dev1';
        envList.add(dev1);
        Environment__c env1 = new Environment__c();
        env1.Name = 'Scratch Org';
        envList.add(env1);
        Environment__c env2 = new Environment__c();
        env2.Name = 'Dev Hub';
        envList.add(env2);
        Environment__c env3 = new Environment__c();
        env3.Name = 'Scratch Org 1';
        envList.add(env3);
        insert envList;

        // Dev Hub has to be inserted before to link scratchOrgs afterwards.
        Org__c org1 = testMethodUtilities.createOrg('Dev Hub 1', 'Production/Developer', 'orgId1', 'token1', 'test1@test1.com', System.now());
        org1.is_Developer_Hub_Org__c = true;
        org1.Environment__c = env2.Id;
        insert org1;

        List<Org__c> orgCredentialList = new List<Org__c>();
        Org__c sOrg = testMethodUtilities.createOrg(
            'Scratch Org 2 For Branch',
            'Scratch Org',
            'org23Id',
            'token23',
            'test23@test23.com',
            System.now()
        );
        sOrg.Environment__c = env1.Id;
        sOrg.Developer_Hub_Org__c = org1.Id;
        orgCredentialList.add(sOrg);
        Org__c s1Org = testMethodUtilities.createOrg('Scratch Org 2 For Org', 'Scratch Org', 'org25Id', 'token25', 'test25@test25.com', System.now());
        s1Org.Environment__c = env1.Id;
        s1Org.Developer_Hub_Org__c = org1.Id;
        orgCredentialList.add(s1Org);
        Org__c orgBranch = testMethodUtilities.createOrg(
            'Scratch Org Branch',
            'Scratch Org Branch',
            'orgId12',
            'token12',
            'test12@test12.com',
            System.now()
        );
        orgBranch.Environment__c = env1.Id;
        orgBranch.Developer_Hub_Org__c = org1.Id;
        orgCredentialList.add(orgBranch);
        Org__c orgBranch1 = testMethodUtilities.createOrg(
            'Scratch Org Branch 1',
            'Scratch Org',
            'orgId123',
            'token123',
            'test123@test123.com',
            System.now()
        );
        orgBranch1.Environment__c = env1.Id;
        orgBranch1.Developer_Hub_Org__c = org1.Id;
        orgCredentialList.add(orgBranch1);
        Org__c org = testMethodUtilities.createOrg('Scratch Org 1', 'Scratch Org', 'orgId', 'token', 'test@test.com', System.now());
        org.Environment__c = env1.Id;
        org.Developer_Hub_Org__c = org1.Id;
        orgCredentialList.add(org);  

        Org__c devOrg1 = testMethodUtilities.createOrg('Dev1', 'Production/Developer', 'devorgId1', 'token1', 'dev1@test1.com', System.now());
        devOrg1.Environment__c = dev1.Id;
        orgCredentialList.add(devOrg1);  
        insert orgCredentialList;

        Git_Repository__c gitRepo = testMethodUtilities.createGitRepository('git 1', 'https://git.com');
        insert gitRepo;

        Git_Backup__c gitSnapshot = testMethodUtilities.create('my first git snapshot', 'master', '', gitRepo, Date.today(), org);
        insert gitSnapshot;

        Git_Org_Commit__c gitCommit = new Git_Org_Commit__c();
        gitCommit.Commit_Message__c = 'My Commit message';
        gitCommit.Status__c = 'Complete';
        gitCommit.Git_Operation__c = 'Commit Files';
        gitCommit.Git_Backup__c = gitSnapshot.Id;
        gitCommit.Org__c = org.Id;
        insert gitCommit;

        List<Artifact__c> artifactList = new List<Artifact__c>();
        Artifact__c art = new Artifact__c();
        art.Name = 'StaticResources';
        art.Org_Credential__c = org.Id;
        art.Artifact_Repository__c = gitRepo.Id;
        artifactList.add(art);

        Artifact__c art1 = new Artifact__c();
        art1.Name = 'StaticResources2';
        art1.Org_Credential__c = org1.Id;
        art1.Artifact_Repository__c = gitRepo.Id;
        artifactList.add(art1);

        Artifact__c gitPackage = new Artifact__c();
        gitPackage.RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Git Package').getRecordTypeId();
        gitPackage.Name = 'GitArtifact';
        gitPackage.Org_Credential__c = org1.Id;
        gitPackage.Artifact_Repository__c = gitRepo.Id;
        artifactList.add(gitPackage);

        Artifact__c unlockedPackageOne = new Artifact__c();
        unlockedPackageOne.RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Salesforce Package').getRecordTypeId();
        unlockedPackageOne.Name = 'Unlocked1';
        unlockedPackageOne.Org_Credential__c = org1.Id;
        unlockedPackageOne.Artifact_Repository__c = gitRepo.Id;
        unlockedPackageOne.Package_Type__c = 'Unlocked';
        unlockedPackageOne.Package_Id__c = '0Ho3X0000008OTNSA2';
        artifactList.add(unlockedPackageOne);
        insert artifactList;

        Artifact_Version__c unlockedVersionOne = new Artifact_Version__c();
        unlockedVersionOne.Artifact__c = artifactList[2].Id;
        unlockedVersionOne.Name = 'Version one';
        unlockedVersionOne.Subscriber_Version_Id__c = '04t6g000005jixsAAA';
        insert unlockedVersionOne;

        List<Attachment> attachmentList = new List<Attachment>();
        Attachment att = new Attachment();
        att.Body = Blob.valueOf(
            '{"selectedArtifactIDs" : [ "' +
            art.Id +
            '" ],"metadataSourceType" : "artifact","metadataSource" : "' +
            art.Id +
            '"}'
        );
        att.Name = 'metadataSources.json';
        att.ParentId = org.Id;
        attachmentList.add(att);

        Attachment att1 = new Attachment();
        att1.Body = Blob.valueOf(
            '{"selectedArtifactIDs" : [ "123456789012345678" ],"metadataSourceType" : "branch","metadataSource" : "123456789012345678"}'
        );
        att1.Name = 'metadataSources.json';
        att1.ParentId = orgBranch1.Id;
        attachmentList.add(att1);

        Attachment att2 = new Attachment();
        att2.Body = Blob.valueOf(
            DeployAPI.encryptAPIKey(
                '{"username":"test-qqqnyhaskzxn@example.com","accessToken":"00D5E0000000sg3!ARgAQMa4MbUzMRzR7LnXQ1e6iLe1YjQIGvtgRnylltDmcQSk7B1L2mMBTLDpqu96ICgJCnHoJFynRXKQ2nUIM2VQuzo0sjT9","instanceUrl":"https://ruby-efficiency-5897-dev-ed.cs84.my.salesforce.com","expirationDate":"2018-03-13","devHubId":"my@copado.devhub","id":"00D5E0000000sg3UAA","createdBy":"my@copado.devhub","createdDate":"2018-03-06T10:55:37.000+0000","status":"Active","edition":"Developer","orgName":"FO 6 mart","alias":"a0T0Y0000035dqP"}'
            )
        );
        att2.Name = 'OrgDetails';
        att2.ParentId = orgBranch1.Id;
        attachmentList.add(att2);

        Attachment att3 = new Attachment();
        att3.Body = Blob.valueOf(DeployAPI.encryptAPIKey('{"password":"1G!f8x6Is("}'));
        att3.Name = 'IdeDetails';
        att3.ParentId = orgBranch1.Id;
        attachmentList.add(att3);

        Attachment att4 = new Attachment();
        att4.Body = Blob.valueOf('');
        att4.Name = 'DxLoadMetadataError';
        att4.ParentId = orgBranch1.Id;
        attachmentList.add(att4);
        insert attachmentList;

        Scratch_Org_Definition__c sod = new Scratch_Org_Definition__c();
        sod.Name = 'Scratch Org Definition';
        sod.Scratch_Org_Definition_JSON__c = '{"username" : null,"orgPreferences" : {"enabled" : [ "AsyncSaveEnabled", "ChatterEnabled", "DisableParallelApexTesting", "EnhancedEmailEnabled", "EventLogWaveIntegEnabled","LoginForensicsEnabled" ],"disabled" : [ "AnalyticsSharingEnable" ]},"orgName" : null,"language" : "de","hasSampleData" : false,"features" : ["Communities", "ContractApprovals" ],"edition" : "Developer","description" : "test","country" : "TR","adminEmail" : "ferhat@copado.com"}';
        sod.Developer_Hub_Org__c = org1.Id;
        insert sod;

        Scratch_Org_Project_Template__c sopt = new Scratch_Org_Project_Template__c();
        sopt.Name = 'Test';
        sopt.Developer_Hub_Org__c = org1.Id;
        sopt.Source_Metadata_Type__c = 'artifact';
        sopt.Source_Org_Credential__c = org.Id;
        sopt.Project_JSON__c =
            '{"sourceApiVersion" : "41.0","sfdcLoginUrl" : "https://login.salesforce.com","selectedArtifactIDs" : [ "' +
            art.Id +
            '" ],"packageDirectories" : [ {"path" : "Artifact2","defaultArtifact" : true}, {"path" : "MyFirstArtifactJG","defaultArtifact" : false} ],"namespace" : "","metadataSourceName" : null,"metadataSource" : null}';
        insert sopt;

        List<Org__c> orgCredential2List = new List<Org__c>();
        Org__c orgActiveScratch = testMethodUtilities.createOrg('Scratch Org 2', 'Scratch Org', 'orgId3', 'token3', 'test3@test3.com', System.now());
        orgActiveScratch.Scratch_Org_Status__c = 'Active';
        orgActiveScratch.Developer_Hub_Org__c = org1.Id;
        orgCredential2List.add(orgActiveScratch);
        Org__c orgDeletedScratch = testMethodUtilities.createOrg('Scratch Org 3', 'Scratch Org', 'orgId2', 'token2', 'test2@test2.com', System.now());
        orgDeletedScratch.Scratch_Org_Status__c = 'Deleted';
        orgDeletedScratch.Developer_Hub_Org__c = org1.Id;
        orgCredential2List.add(orgDeletedScratch);
        insert orgCredential2List;

        Attachment att5 = new Attachment();
        att5.Body = Blob.valueOf(
            '{"status":0,"result":{"username":"dev4@copado.com","id":"00D58000000pQecEAE","connectedStatus":"Connected","accessToken":"00D58000000pQec!AQgAQC4A2E0Cklo.S_h8e.egeG1sPXNc0h_2rzJ3QEXGtbYHoSfUdWb4tk0yu6T75ltyEsdYKa6HJiQNcCkkykv5Vu.KxOGx","instanceUrl":"https://eu6.salesforce.com","clientId":"SalesforceDevelopmentExperience"}}'
        );
        att5.Name = 'ScratchOrgDisplay.json';
        att5.ParentId = orgActiveScratch.Id;
        insert att5;

        List<Deployment_Flow__c> dfList = new List<Deployment_Flow__c>();
        Deployment_Flow__c df = new Deployment_Flow__c();
        df.Name = 'Deployment Flow';
        df.Active__c = true;
        df.Git_Repository__c = gitRepo.Id;
        df.Main_Branch__c = 'master';
        df.Enable_Copado_DX__c = true;
        df.Copado_DX_Mode__c = 'Git Package';
        dfList.add(df);

        Deployment_Flow__c df1 = new Deployment_Flow__c();
        df1.Name = 'Deployment Flow 1';
        df1.Active__c = true;
        df1.Git_Repository__c = gitRepo.Id;
        df1.Main_Branch__c = 'master';
        df1.Enable_Copado_DX__c = true;
        df1.Copado_DX_Mode__c = 'Git Package';
        dfList.add(df1);
        insert dfList;

        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        Deployment_Flow_Step__c dfs = new Deployment_Flow_Step__c();
        dfs.Deployment_Flow__c = df.Id;
        dfs.Destination_Environment__c = env2.Id;
        dfs.Source_Environment__c = env1.Id;
        dfs.Branch__c = 'Project';
        dfsList.add(dfs);

        Deployment_Flow_Step__c dfs1 = new Deployment_Flow_Step__c();
        dfs1.Deployment_Flow__c = df1.Id;
        dfs1.Destination_Environment__c = env2.Id;
        dfs1.Source_Environment__c = env1.Id;
        dfs1.Branch__c = 'Project';
        dfs1.Enable_as_Scratch_Org_Destination__c = 'Default DX Target';
        dfsList.add(dfs1);

        Deployment_Flow_Step__c dfs2 = new Deployment_Flow_Step__c();
        dfs2.Deployment_Flow__c = df1.Id;
        dfs2.Destination_Environment__c = env2.Id;
        dfs2.Source_Environment__c = env3.Id;
        dfs2.Branch__c = 'Project 1';
        dfs2.Enable_as_Scratch_Org_Destination__c = 'DX Target';
        dfsList.add(dfs2);
        insert dfsList;

        List<Project__c> prList = new List<Project__c>();
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.Deployment_Flow__c = df.Id;
        prList.add(project);

        Project__c project1 = new Project__c();
        project1.Name = 'Test Project 1';
        project1.Deployment_Flow__c = df1.Id;
        prList.add(project1);
        insert prList;

        List<User_Story__c> usList = new List<User_Story__c>();
        User_Story__c us = new User_Story__c();
        us.User_Story_Title__c = 'Error on dx operation';
        usList.add(us);

        User_Story__c us1 = new User_Story__c();
        us1.User_Story_Title__c = 'Error on dx operation 1';
        us1.Project__c = project.Id;
        usList.add(us1);

        User_Story__c us2 = new User_Story__c();
        us2.User_Story_Title__c = 'Error on dx operation 2';
        us2.Project__c = project1.Id;
        us2.Org_Credential__c = orgBranch.Id;
        usList.add(us2);

        User_Story__c us3 = new User_Story__c();
        us3.User_Story_Title__c = 'Error on dx operation 3';
        us3.Project__c = project1.Id;
        us3.Org_Credential__c = orgBranch1.Id;
        usList.add(us3);

        User_Story__c testUserStory = new User_Story__c();
        testUserStory.User_Story_Title__c = 'Test User Story';
        testUserStory.Project__c = project1.Id;
        usList.add(testUserStory);

        insert usList;

        Deployment__c deployment = testMethodUtilities.create('Deployment', System.now(), System.now(), s1Org.Id, '', 'Draft');
        deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByName().get('Advanced (multi-step)').getRecordTypeId();
        insert deployment;

        Step__c step = testMethodUtilities.create('Test step', '', '', deployment.Id, 0, 'Draft', 'ApexClass');
        insert step;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Draft', org.Id);
        insert destinationOrg;

        List<Release__c> releaseList = new List<Release__c>();
        Release__c release = new Release__c();
        release.Name = 'Release 1';
        releaseList.add(release);
        Release__c release1 = new Release__c();
        release1.Name = 'Release 2';
        release1.Project__c = project.Id;
        releaseList.add(release1);
        insert releaseList;
    }

    //  COPADO DATA FACTORY
    private String ERR_NOT_FOUND_SOBJECT = Label.Unable_Find_Sobject;
    private String ERR_FIELD_NOT_EXIST = Label.Err_Field_Not_Exist;
    private Map<String, List<SObject>> objectCache = new Map<String, List<SObject>>();
    private String namespace;
    private Boolean namespaceQuery = false;
    private Boolean isRunnedOnce = false;
    private String tempNamespace = '';

    private String getNameSpace(String stype) {
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(stype);
        Schema.DescribeSObjectResult dsr = convertType.getDescribe();
        return dsr.isCustom() ? returnNameSpace() : '';
    }

    public String returnNameSpace() {
        if (String.isBlank(namespace)) {
            namespaceQuery = false;
        }

        if (!namespaceQuery) {
            namespace = getNameSpaceQuery();
            namespaceQuery = true;
        }
        return namespace;
    }

    private String getNameSpaceQuery() {
        if (String.isBlank(tempNamespace) && !isRunnedOnce) {
            String namespace = CopadoSetupController.class.getName().substringBefore('CopadoSetupController').removeEnd('.').toLowerCase();
            tempNamespace = namespace == 'copado' ? 'copado__' : '';
            isRunnedOnce = true;
        }
        return tempNamespace;
    }

    public SObject item(String stype, Integer index) {
        namespace = getNameSpace(stype);
        return objectCache.get(namespace + stype).get(index);
    }

    // create but not insert the a number of sobjects.
    public List<SObject> createSObjects(String stype, Integer numRecords, Map<String, Object> fieldsMap) {
        namespace = getNameSpace(stype);
        List<SObject> records = new List<SObject>();
        for (Integer i = 0; i < numRecords; i++) {
            records.add(fetchFileds(namespace + stype, fieldsMap));
        }
        if (!objectCache.containsKey(namespace + stype)) {
            objectCache.put(namespace + stype, records);
        } else {
            objectCache.get(namespace + stype).addAll(records);
        }
        return records;
    }

    // create and upsert the a number of sobjects.
    public List<SObject> insertSObjects(String stype, Integer numRecords, Map<String, Object> fieldsMap) {
        List<SObject> records = this.createSObjects(stype, numRecords, fieldsMap);
        Utilities.Secure_DML(
            records,
            Utilities.DML_Action.INS,
            ((SObject) Type.forName(namespace, stype).newInstance()).getSObjectType().getDescribe()
        );
        return records;
    }

    public SObject createSObject(String stype, Map<String, Object> fieldsMap) {
        return this.createSObjects(stype, 1, fieldsMap).get(0);
    }

    public SObject insertSObject(String stype, Map<String, Object> fieldsMap) {
        return this.insertSObjects(stype, 1, fieldsMap).get(0);
    }

    private SObject fetchFileds(String stype, Map<String, Object> fieldsMap) {
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(stype);
        if (sobjectType == null) {
            throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_SOBJECT, new List<String>{ stype }, ''));
        }

        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(stype).getDescribe().fields.getMap();
        SObject obj = sobjectType.newSObject();

        for (String fieldName : fieldsMap.keySet()) {
            try {
                String fieldWithNS = fieldName.contains('__') ? namespace + fieldName : fieldName;
                obj.put(objectFields.get(fieldWithNS), fieldsMap.get(fieldName));
            } catch (Exception e) {
                throw new TestDataFactoryException(formatErrorMessage(ERR_FIELD_NOT_EXIST, new List<String>{ fieldName, stype }, e.getMessage()));
            }
        }

        return obj;
    }

    public String formatErrorMessage(String message, List<String> mergeValues, String originalMessage) {
        String errorMessage = String.format(message, mergeValues);
        // if originalMessage is passed as param it will be include in the errorMessage
        if (!String.isBlank(originalMessage))
            errorMessage += '\n' + ' ' + Label.Original_Error_Message + ' : ' + originalMessage;
        return errorMessage;
    }

    public class TestDataFactoryException extends Exception {
    }
}