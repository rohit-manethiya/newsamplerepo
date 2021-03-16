/**
 * Created by fede on 27/12/2017.
 */

@IsTest
private class TestDeploymentWizardFailures {
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(1, 1, 0);
    }
    static void setupDataDML() {
        TestUtilities.insertUser('user1-TestDeploymentWizard@test-copado.org','System Administrator');
        TestUtilities.assignLicense('user1-TestDeploymentWizard@test-copado.org', false, true, false);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false);
        testMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void testPromotionDeploymentCCMUser_failure_messages(){
        setupDataDML();
        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
        insert f;

        Git_Repository__c g = new Git_Repository__c(name = 'g');
        insert g;
        Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
        insert flow;
        Deployment_Flow__c flowActive = CMTestMethodUtilities.createCCMFlow('active flow', true);
        insert flowActive;

        Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowActive.Id);
        insert dfs2;

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowActive.Id;
        insert testProject;
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        insert testPromotion;

        Test.startTest();
        Deployment__c testDeployment = testMethodUtilities.create('a',System.now(), System.now(),testOrg1.Id,'c','d');
        insert testDeployment;
        System.assert([select Id from deployment__c where Id = :testDeployment.Id].size() == 1);
        Deployment__c testDeploymentWithPromotion = testMethodUtilities.create('a',System.now(), System.now(),testOrg1.Id,'c','d');
        testDeploymentWithPromotion.Promotion__c = testPromotion.Id;
        insert testDeploymentWithPromotion;

        Step__c testStep1 = testMethodUtilities.create('Apex','b','{"testLevel":"NoTestRun","replacements":[]}',testDeployment.Id,1,'Draft','Apex');
        insert testStep1;
        Step__c testStep2 = testMethodUtilities.create('Apex','b','{"testLevel":"NoTestRun","replacements":[]}',testDeploymentWithPromotion.Id,1,'Draft','Apex');
        insert testStep2;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testOrg2.Id);
        insert testDestOrg;
        Destination_Org__c testDestOrg2 = testMethodUtilities.create(testDeploymentWithPromotion.Id,'Draft',testOrg2.Id);
        insert testDestOrg2;

        // Run test as a CCM User
        User user = [SELECT Id FROM User WHERE Username ='user1-TestDeploymentWizard@test-copado.org'];

        System.runAs(user) {
            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id',testDeployment.id);
            pref.getParameters().put('gotoStep','deployNow');
            Test.setCurrentPage(pref);

            DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
            System.assert(testMethodUtilities.hasMessage(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED));

            PageReference pref2 = Page.DeploymentWizard;
            pref2.getParameters().put('id',testDeploymentWithPromotion.id);
            pref2.getParameters().put('gotoStep','deployNow');
            Test.setCurrentPage(pref2);

            DeploymentWizardExtension ext2 = new DeploymentWizardExtension(new ApexPages.StandardController(testDeploymentWithPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.CCM_DESTINATION_ORG_INVALID));

            env2.Type__c = 'Sandbox';
            update env2;
            testOrg2.Org_Type__c = 'Sandbox';
            update testOrg2;

            DeploymentWizardExtension ext3 = new DeploymentWizardExtension(new ApexPages.StandardController(testDeploymentWithPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));

            testProject.Deployment_Flow__c = flow.Id;
            update testProject;

            DeploymentWizardExtension ext4 = new DeploymentWizardExtension(new ApexPages.StandardController(testDeploymentWithPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
        }
        Test.stopTest();
    }
    static testMethod void testGotoDeployNowPage_failure_messages(){
        setupDataDML();
        Org__c testFromOrg = testMethodUtilities.createOrg('a','b','c','d','e', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create('a',System.now(), System.now(),testFromOrg.Id,'c','d');
        insert testDeployment;
        System.assert([select Id from deployment__c where Id = :testDeployment.Id].size() == 1);
        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id',testDeployment.id);
        pref.getParameters().put('gotoStep','deployNow');
        Test.setCurrentPage(pref);

        test.startTest();
        DeploymentWizardExtension ext = new DeploymentWizardExtension(new ApexPages.StandardController(testDeployment));
        test.stopTest();
        System.debug('ApexPages messages: '+ApexPages.getMessages());
        System.assertEquals(false, ext.step_setupSchedule);
        System.assert(testMethodUtilities.hasMessage(Label.MISSING_DEST_ORGS_MESSAGE));
        System.assert(testMethodUtilities.hasMessage(Label.MISSING_STEPS_MESSAGE));
    }
}