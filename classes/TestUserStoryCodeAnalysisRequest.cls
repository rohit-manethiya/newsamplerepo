@IsTest
private class TestUserStoryCodeAnalysisRequest {
    private static final String TEST_STRING = 'test';
    @TestSetup static void setupData() {
        TestUtilities.getAllMultilicense();
    }
    static void setupDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        TestUtilities.insertUser('user1-TestUserStoryCodeAnalysisRequest@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense('user1-TestUserStoryCodeAnalysisRequest@test-copado.org', false, false, false, true, false);
    }
    static testMethod void testPMDusRequest() {
        setupDataDML();
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        Utilities.Secure_DML(scas, Utilities.DML_Action.INS, schema.SObjectType.Static_Code_Analysis_Settings__c);

        Static_Code_Analysis_Rule__c rule = new Static_Code_Analysis_Rule__c();
        rule.Static_Code_Analysis_Settings__c = scas.Id;
        rule.Rule_Name__c = 'IfElseStmtsMustUseBraces ';
        rule.Priority__c = '3';
        rule.Message__c = 'IfElseStmtsMustUseBraces ';
        Utilities.Secure_DML(rule, Utilities.DML_Action.INS, schema.SObjectType.Static_Code_Analysis_Rule__c);

        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);
        Feature__c f2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        Utilities.Secure_DML(f2, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);
        Feature__c f3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        Utilities.Secure_DML(f3, Utilities.DML_Action.INS, schema.SObjectType.Feature__c);

        Git_Repository__c gr = new Git_Repository__c(Name = TEST_STRING);
        Utilities.Secure_DML(gr, Utilities.DML_Action.INS, schema.SObjectType.Git_Repository__c);

        Deployment_Flow__c df = new Deployment_Flow__c(Name = TEST_STRING, Active__c = true, Main_Branch__c = 'master', Git_Repository__c = gr.Id, Static_Code_Analysis_Settings__c = scas.Id);
        Utilities.Secure_DML(df, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow__c);

        Project__c p = new Project__c(Name = 'Test Project', Deployment_Flow__c = df.Id);
        Utilities.Secure_DML(p, Utilities.DML_Action.INS, schema.SObjectType.Project__c);

        List<Environment__c> Le = new List<Environment__c>();
        for(Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        Utilities.Secure_DML(Le, Utilities.DML_Action.INS, schema.SObjectType.Environment__c);

        List<Org__c> Lo = new List<Org__c>();
        for(Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        Utilities.Secure_DML(Lo, Utilities.DML_Action.INS, schema.SObjectType.Org__c);

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        Utilities.Secure_DML(us, Utilities.DML_Action.INS, schema.SObjectType.User_Story__c);

        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        Attachment testAttachment = createAttachment(us.Id, 'MetaData', attBody);
        Utilities.Secure_DML(testAttachment, Utilities.DML_Action.INS, schema.SObjectType.Attachment);

        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Git MetaData', attBody);
        Utilities.Secure_DML(testAttachment, Utilities.DML_Action.INS, schema.SObjectType.Attachment);

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Delete MetaData', attBody);
        Utilities.Secure_DML(testAttachment, Utilities.DML_Action.INS, schema.SObjectType.Attachment);

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev1', Source_Environment__c = Le[0].Id, Destination_Environment__c = Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev2', Source_Environment__c = Le[1].Id, Destination_Environment__c = Le[2].Id));
        Utilities.Secure_DML(inserts, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();
        UserStoryCodeAnalysisRequestController uscarc = new UserStoryCodeAnalysisRequestController(new ApexPages.StandardController(us));
        uscarc.requestCodeScan();
        System.assert(testMethodUtilities.hasMessage(Label.USER_STORY_ANALYSIS_REQUESTED));
        Test.stopTest();
    }

    static testMethod void testPMDusRequestErrors() {
        setupDataDML();
        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        insert feature;
        Feature__c feature2 = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        insert feature2;
        Feature__c feature3 = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        insert feature3;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = TEST_STRING);
        insert gitRepo;

        Deployment_Flow__c flow = new Deployment_Flow__c(Name = TEST_STRING, Active__c = true, Main_Branch__c = 'master', Git_Repository__c = gitRepo.Id, Static_Code_Analysis_Settings__c = scas.Id);
        insert flow;

        Project__c project = new Project__c(Name = 'Test Project', Deployment_Flow__c = flow.Id);
        insert project;

        List<Environment__c> Le = new List<Environment__c>();
        for(Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for(Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = project.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestUserStoryCodeAnalysisRequest@test-copado.org'];
        System.runAs(user) {
            Test.startTest();
            UserStoryCodeAnalysisRequestController uscarc = new UserStoryCodeAnalysisRequestController(new ApexPages.StandardController(us));
            uscarc.requestCodeScan();
            System.assert(testMethodUtilities.hasMessage(Label.CCM_License_Restriction));
            Test.stopTest();
        }
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(ParentId = parentId, Name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }
}