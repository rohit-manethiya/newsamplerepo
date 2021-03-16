@IsTest
public with sharing class Test_WorkPushService {
    private static final String GIT_METADATA = 'Git MetaData';
    private static final String METADATA = 'Metadata';
    private static final String ALLOW_SNAPSHOTS_COMMITS = 'Allow Snapshots & Commits';
    private static final String PRODUCTION_DEVELOPER = 'Production/Developer';
    private static final String APEX_CLASS = 'ApexClass';
    private static final String APEX_PAGE = 'ApexPage';
    private static final String ADDED = 'added';
    private static final String UPDATED = 'updated';
    private static final String NAMESPACE = Settings.ns;
    private static final String CALLOUT_DATA_MOCK = '{"response":[{"filePath":"classes/Dummy1.cls","metaData":{"t":"ApexClass","n":"Dummy1"}},{"filePath":"pages/Page1.page","metaData":{"t":"ApexPage","n":"Page1"}}],"hasErrors":false}';
    
    @TestSetup
    public static void setUpData() {
        User sysUs = new User();
        sysUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        sysUs.LastName = 'LastName';
        sysUs.Email = 'test1@test1.com';
        sysUs.Username = 'psysUser000@clitest.com' + System.currentTimeMillis();
        sysUs.CompanyName = 'TEST';
        sysUs.Title = 'title';
        sysUs.Alias = 'alias';
        sysUs.TimeZoneSidKey = 'America/Los_Angeles';
        sysUs.EmailEncodingKey = 'UTF-8';
        sysUs.LanguageLocaleKey = 'en_US';
        sysUs.LocaleSidKey = 'en_US';

        User stdUs = new User();
        stdUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        stdUs.LastName = 'LastName';
        stdUs.Email = 'test2@test2.com';
        stdUs.Username = 'pstdUser002@amamama.com' + System.currentTimeMillis();
        stdUs.CompanyName = 'TEST';
        stdUs.Title = 'title2';
        stdUs.Alias = 'alias2';
        stdUs.TimeZoneSidKey = 'America/Los_Angeles';
        stdUs.EmailEncodingKey = 'UTF-8';
        stdUs.LanguageLocaleKey = 'en_US';
        stdUs.LocaleSidKey = 'en_US';
        insert new List<User>{
                sysUs, stdUs
        };

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 1);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', 2);
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 2);

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = sysUs.Id, PermissionSetId = ps.Id);

    }
    @IsTest
    public static void doPushAttchamentNew() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>();
            List<Environment__c> environmentList = new List<Environment__c>();
            List<Org__c> orgCredList = new List<Org__c>();

            Environment__c env1 = new Environment__c();
            env1.Name = 'Environment 1';
            environmentList.add(env1);

            Environment__c env2 = new Environment__c();
            env2.Name = 'Environment 2';
            environmentList.add(env2);

            insert environmentList;

            Org__c orgCred1 = new Org__c();
            orgCred1.Environment__c = environmentList[0].Id;
            orgCred1.Name = 'Cred1 Env1';
            orgCred1.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred1.Validated_Date__c = System.Date.today();
            orgCred1.Default_Credential__c = true;
            orgCredList.add(orgCred1);

            Org__c orgCred2 = new Org__c();
            orgCred2.Environment__c = environmentList[1].Id;
            orgCred2.Name = 'Cred2 Env2';
            orgCred2.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred2.Validated_Date__c = System.Date.today();
            orgCred2.Default_Credential__c = true;
            orgCredList.add(orgCred2);

            insert orgCredList;

            Git_Repository__c gitRepo = new Git_Repository__c();
            gitRepo.Name = 'My Repo';
            gitRepo.Source_Format__c = METADATA;
            insert gitRepo;

            Git_Backup__c gbck = new Git_Backup__c();
            gbck.Org__c = orgCredList[0].Id;
            gbck.Git_Repository__c = gitRepo.Id;
            gbck.Git_Snapshot_Permissions__c = ALLOW_SNAPSHOTS_COMMITS;
            insert gbck;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            pipeline.Git_Repository__c = gitRepo.Id;
            insert pipeline;

            Deployment_Flow_Step__c pipelineEnv = new Deployment_Flow_Step__c();
            pipelineEnv.Deployment_Flow__c = pipeline.Id;
            pipelineEnv.Branch__c = 'env1';
            pipelineEnv.Source_Environment__c = environmentList[0].Id;
            pipelineEnv.Destination_Environment__c = environmentList[1].Id;
            pipelineEnvList.add(pipelineEnv);

            Deployment_Flow_Step__c pipelineEnv2 = new Deployment_Flow_Step__c();
            pipelineEnv2.Deployment_Flow__c = pipeline.Id;
            pipelineEnv2.Branch__c = 'env2';
            pipelineEnvList.add(pipelineEnv2);

            insert pipelineEnvList;

            Project__c prj = new Project__c();
            prj.Name = 'My Project';
            prj.Deployment_Flow__c = pipeline.Id;
            insert prj;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environmentList[0].Id;
            us.Org_Credential__c = orgCredList[0].Id;
            us.Project__c = prj.Id;
            insert us;

            Test.startTest();
            WorkPushService workpushInstance = new WorkPushService();
            workpushInstance.getInstance();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(CALLOUT_DATA_MOCK, null));

            List<WorkPushService.CommitWrapper> cmWrList = new List<WorkPushService.CommitWrapper>();
            WorkPushService.CommitWrapper cmWr = new WorkPushService.CommitWrapper();
            cmWr.commitId = '0123456';
            cmWr.commitMessage = 'My Commit';
            cmWr.commitDate = String.valueOf(Datetime.now());
            cmWr.commitAuthor = 'Commit Author';
            cmWr.commitFiles = new List<String>{
                    'classes/Dummy1.cls', 'pages/Page1.page'
            };
            cmWrList.add(cmWr);

            WorkPushService.WorkPushWrapper wrks = new WorkPushService.WorkPushWrapper();
            wrks.userStory = us.Id;
            wrks.commitList = cmWrList;

            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'push';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkPushService.WorkPushDataWrapper resp = (WorkPushService.WorkPushDataWrapper) JSON.deserialize(response, WorkPushService.WorkPushDataWrapper.class);
            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());

            List<Attachment> finalUSAttachment = [SELECT Id, Body FROM Attachment WHERE Name = 'Git MetaData' AND ParentId = :us.Id LIMIT 1];
            List<WorkPushService.SfRetrievable> sfrList = (List<WorkPushService.SfRetrievable>) JSON.deserialize(finalUSAttachment[0].Body.toString(), List<WorkPushService.SfRetrievable>.class);
            System.assertEquals(sfrList.size(), 2);

            System.assertEquals(sfrList[0].cb, 'Commit Author');
            System.assertEquals(sfrList[0].cmm, ADDED);
            System.assertEquals(sfrList[0].n, 'Dummy1');
            System.assertEquals(sfrList[0].r, false);
            System.assertEquals(sfrList[0].s, false);
            System.assertEquals(sfrList[0].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[0].t, APEX_CLASS);

            System.assertEquals(sfrList[1].cb, 'Commit Author');
            System.assertEquals(sfrList[1].cmm, ADDED);
            System.assertEquals(sfrList[1].n, 'Page1');
            System.assertEquals(sfrList[1].r, false);
            System.assertEquals(sfrList[1].s, false);
            System.assertEquals(sfrList[1].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[1].t, APEX_PAGE);

            Test.stopTest();
        }
    }

    @IsTest
    public static void doPushAttchamentIncremental() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>();
            List<Environment__c> environmentList = new List<Environment__c>();
            List<Org__c> orgCredList = new List<Org__c>();
            List<WorkPushService.CommitWrapper> cmWrList = new List<WorkPushService.CommitWrapper>();
            List<WorkPushService.SfRetrievable> sfrList = new List<WorkPushService.SfRetrievable>();

            Environment__c env1 = new Environment__c();
            env1.Name = 'Environment 1';
            environmentList.add(env1);

            Environment__c env2 = new Environment__c();
            env2.Name = 'Environment 2';
            environmentList.add(env2);

            insert environmentList;

            Org__c orgCred1 = new Org__c();
            orgCred1.Environment__c = environmentList[0].Id;
            orgCred1.Name = 'Cred1 Env1';
            orgCred1.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred1.Validated_Date__c = System.Date.today();
            orgCred1.Default_Credential__c = true;
            orgCredList.add(orgCred1);

            Org__c orgCred2 = new Org__c();
            orgCred2.Environment__c = environmentList[1].Id;
            orgCred2.Name = 'Cred2 Env2';
            orgCred2.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred2.Validated_Date__c = System.Date.today();
            orgCred2.Default_Credential__c = true;
            orgCredList.add(orgCred2);

            insert orgCredList;

            Git_Repository__c gitRepo = new Git_Repository__c();
            gitRepo.Name = 'My Repo';
            gitRepo.Source_Format__c = METADATA;
            insert gitRepo;

            Git_Backup__c gbck = new Git_Backup__c();
            gbck.Org__c = orgCredList[0].Id;
            gbck.Git_Repository__c = gitRepo.Id;
            gbck.Git_Snapshot_Permissions__c = ALLOW_SNAPSHOTS_COMMITS;

            insert gbck;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            pipeline.Git_Repository__c = gitRepo.Id;
            insert pipeline;

            Deployment_Flow_Step__c pipelineEnv = new Deployment_Flow_Step__c();
            pipelineEnv.Deployment_Flow__c = pipeline.Id;
            pipelineEnv.Branch__c = 'env1';
            pipelineEnv.Source_Environment__c = environmentList[0].Id;
            pipelineEnv.Destination_Environment__c = environmentList[1].Id;
            pipelineEnvList.add(pipelineEnv);

            Deployment_Flow_Step__c pipelineEnv2 = new Deployment_Flow_Step__c();
            pipelineEnv2.Deployment_Flow__c = pipeline.Id;
            pipelineEnv2.Branch__c = 'env2';
            pipelineEnvList.add(pipelineEnv2);

            insert pipelineEnvList;

            Project__c prj = new Project__c();
            prj.Name = 'My Project';
            prj.Deployment_Flow__c = pipeline.Id;
            insert prj;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environmentList[0].Id;
            us.Org_Credential__c = orgCredList[0].Id;
            us.Project__c = prj.Id;
            insert us;

            WorkPushService.CommitWrapper cmWr = new WorkPushService.CommitWrapper();
            cmWr.commitId = '0123456';
            cmWr.commitMessage = 'My Commit';
            cmWr.commitDate = String.valueOf(Datetime.now());
            cmWr.commitAuthor = 'Commit Author';
            cmWr.commitFiles = new List<String>{
                    'classes/Dummy1.cls', 'pages/Page1.page'
            };
            cmWrList.add(cmWr);

            WorkPushService.WorkPushWrapper wrks = new WorkPushService.WorkPushWrapper();
            wrks.userStory = us.Id;
            wrks.commitList = cmWrList;

            WorkPushService.SfRetrievable sfr = new WorkPushService.SfRetrievable();
            sfr.cb = 'Commit Author';
            sfr.cd = String.valueOf(Datetime.now() - 1);
            sfr.cmm = ADDED;
            sfr.n = 'Dummy1';
            sfr.r = false;
            sfr.s = false;
            sfr.snapshotCommitId = '0123456';
            sfr.t = APEX_CLASS;
            sfrList.add(sfr);

            Attachment usAttachment = new Attachment();
            usAttachment.ParentId = us.Id;
            usAttachment.Name = GIT_METADATA;
            usAttachment.Body = Blob.valueOf(JSON.serialize(sfrList, true));
            insert usAttachment;

            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(CALLOUT_DATA_MOCK, null));

            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'push';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkPushService.WorkPushDataWrapper resp = (WorkPushService.WorkPushDataWrapper) JSON.deserialize(response, WorkPushService.WorkPushDataWrapper.class);
            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());

            List<Attachment> finalUSAttachment = [SELECT Id, Body FROM Attachment WHERE Id = :usAttachment.Id];
            List<WorkPushService.SfRetrievable> finalSfrList = (List<WorkPushService.SfRetrievable>) JSON.deserialize(finalUSAttachment[0].Body.toString(), List<WorkPushService.SfRetrievable>.class);
            System.assertEquals(finalSfrList.size(), 2);

            System.assertEquals(finalSfrList[0].cb, 'Commit Author');
            System.assertNotEquals(finalSfrList[0].cd, finalSfrList[0].d);
            System.assertEquals(finalSfrList[0].cmm, UPDATED);
            System.assertEquals(finalSfrList[0].n, 'Dummy1');
            System.assertEquals(finalSfrList[0].r, false);
            System.assertEquals(finalSfrList[0].s, false);
            System.assertEquals(finalSfrList[0].snapshotCommitId, '0123456');
            System.assertEquals(finalSfrList[0].t, APEX_CLASS);

            System.assertEquals(finalSfrList[1].cb, 'Commit Author');
            System.assertEquals(finalSfrList[1].cmm, ADDED);
            System.assertEquals(finalSfrList[1].cd, finalSfrList[1].d);
            System.assertEquals(finalSfrList[1].n, 'Page1');
            System.assertEquals(finalSfrList[1].r, false);
            System.assertEquals(finalSfrList[1].s, false);
            System.assertEquals(finalSfrList[1].snapshotCommitId, '0123456');
            System.assertEquals(finalSfrList[1].t, APEX_PAGE);

            Test.stopTest();
        }
    }
    @IsTest
    public static void doPushExternalCiAttachment() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>();
            List<Environment__c> environmentList = new List<Environment__c>();
            List<Org__c> orgCredList = new List<Org__c>();

            Environment__c env1 = new Environment__c();
            env1.Name = 'Environment 1';
            environmentList.add(env1);

            Environment__c env2 = new Environment__c();
            env2.Name = 'Environment 2';
            environmentList.add(env2);

            insert environmentList;

            Org__c orgCred1 = new Org__c();
            orgCred1.Environment__c = environmentList[0].Id;
            orgCred1.Name = 'Cred1 Env1';
            orgCred1.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred1.Validated_Date__c = System.Date.today();
            orgCred1.Default_Credential__c = true;
            orgCredList.add(orgCred1);

            Org__c orgCred2 = new Org__c();
            orgCred2.Environment__c = environmentList[1].Id;
            orgCred2.Name = 'Cred2 Env2';
            orgCred2.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred2.Validated_Date__c = System.Date.today();
            orgCred2.Default_Credential__c = true;
            orgCredList.add(orgCred2);
            insert orgCredList;

            Git_Repository__c gitRepo = new Git_Repository__c();
            gitRepo.Name = 'My Repo';
            gitRepo.Source_Format__c = METADATA;
            insert gitRepo;

            Git_Backup__c gbck = new Git_Backup__c();
            gbck.Org__c = orgCredList[0].Id;
            gbck.Git_Repository__c = gitRepo.Id;
            gbck.Git_Snapshot_Permissions__c = ALLOW_SNAPSHOTS_COMMITS;
            insert gbck;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            pipeline.Git_Repository__c = gitRepo.Id;
            insert pipeline;

            Deployment_Flow_Step__c pipelineEnv = new Deployment_Flow_Step__c();
            pipelineEnv.Deployment_Flow__c = pipeline.Id;
            pipelineEnv.Branch__c = 'env1';
            pipelineEnv.Source_Environment__c = environmentList[0].Id;
            pipelineEnv.Destination_Environment__c = environmentList[1].Id;
            pipelineEnvList.add(pipelineEnv);

            Deployment_Flow_Step__c pipelineEnv2 = new Deployment_Flow_Step__c();
            pipelineEnv2.Deployment_Flow__c = pipeline.Id;
            pipelineEnv2.Branch__c = 'env2';
            pipelineEnvList.add(pipelineEnv2);
            insert pipelineEnvList;

            Project__c prj = new Project__c();
            prj.Name = 'MyProject';
            prj.Deployment_Flow__c = pipeline.Id;
            prj.Description__c = 'Project Description';
            insert prj;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environmentList[0].Id;
            us.Org_Credential__c = orgCredList[0].Id;
            us.Project__c = prj.Id;
            insert us;

            Test.startTest();
            WorkPushService workpushInstance = new WorkPushService();
            workpushInstance.getInstance();

            List<WorkPushService.CommitWrapper> cmWrList = new List<WorkPushService.CommitWrapper>();
            WorkPushService.CommitWrapper cmWr = new WorkPushService.CommitWrapper();
            cmWr.commitId = '0123456';
            cmWr.commitMessage = 'My Commit';
            cmWr.commitDate = String.valueOf(Datetime.now());
            cmWr.commitAuthor = 'Commit Author';
            cmWr.commitFiles = new List<String>{
                    'classes/Dummy1.js', 'css/WebIndex.css'
            };
            cmWrList.add(cmWr);

            WorkPushService.WorkPushWrapper wrks = new WorkPushService.WorkPushWrapper();
            wrks.userStory = us.Id;
            wrks.commitList = cmWrList;
            wrks.projectTypeField = NAMESPACE + 'Description__c'; //As we use a custom field that is not in the package I will use a standard field.

            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'push';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkPushService.WorkPushDataWrapper resp = (WorkPushService.WorkPushDataWrapper) JSON.deserialize(response, WorkPushService.WorkPushDataWrapper.class);
            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());

            String snapshotCommitId = [SELECT Id FROM Git_Org_Commit__c WHERE Commit_Id__c = '0123456' LIMIT 1].Id;
            List<Attachment> finalUSAttachment = [SELECT Id, Body FROM Attachment WHERE Name = 'Git MetaData' AND ParentId = :us.Id LIMIT 1];
            List<Attachment> snapshotCommitAttachment = [SELECT Id, Body FROM Attachment WHERE Name = 'ExternalMetaData' AND ParentId = :snapshotCommitId LIMIT 1];

            List<WorkPushService.SfRetrievable> sfrList = (List<WorkPushService.SfRetrievable>) JSON.deserialize(finalUSAttachment[0].Body.toString(), List<WorkPushService.SfRetrievable>.class);
            System.assertEquals(sfrList.size(), 2);

            System.assertEquals(sfrList[0].cb, 'Commit Author');
            System.assertEquals(sfrList[0].cmm, ADDED);
            System.assertEquals(sfrList[0].n, 'Dummy1.js');
            System.assertEquals(sfrList[0].r, false);
            System.assertEquals(sfrList[0].s, false);
            System.assertEquals(sfrList[0].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[0].t, prj.Description__c);

            System.assertEquals(sfrList[1].cb, 'Commit Author');
            System.assertEquals(sfrList[1].cmm, ADDED);
            System.assertEquals(sfrList[1].n, 'WebIndex.css');
            System.assertEquals(sfrList[1].r, false);
            System.assertEquals(sfrList[1].s, false);
            System.assertEquals(sfrList[1].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[1].t, prj.Description__c);

            System.assertEquals(snapshotCommitAttachment.size(), 1);

            Test.stopTest();
        }
    }

    // This test case is Salesforce project but in CLI, projecttypefield is set up.
    @IsTest
    public static void doPushAttchamentWithProjectTypeField() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>();
            List<Environment__c> environmentList = new List<Environment__c>();
            List<Org__c> orgCredList = new List<Org__c>();

            Environment__c env1 = new Environment__c();
            env1.Name = 'Environment 1';
            environmentList.add(env1);

            Environment__c env2 = new Environment__c();
            env2.Name = 'Environment 2';
            environmentList.add(env2);

            insert environmentList;

            Org__c orgCred1 = new Org__c();
            orgCred1.Environment__c = environmentList[0].Id;
            orgCred1.Name = 'Cred1 Env1';
            orgCred1.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred1.Validated_Date__c = System.Date.today();
            orgCred1.Default_Credential__c = true;
            orgCredList.add(orgCred1);

            Org__c orgCred2 = new Org__c();
            orgCred2.Environment__c = environmentList[1].Id;
            orgCred2.Name = 'Cred2 Env2';
            orgCred2.Org_Type__c = PRODUCTION_DEVELOPER;
            orgCred2.Validated_Date__c = System.Date.today();
            orgCred2.Default_Credential__c = true;
            orgCredList.add(orgCred2);

            insert orgCredList;

            Git_Repository__c gitRepo = new Git_Repository__c();
            gitRepo.Name = 'My Repo';
            gitRepo.Source_Format__c = METADATA;
            insert gitRepo;

            Git_Backup__c gbck = new Git_Backup__c();
            gbck.Org__c = orgCredList[0].Id;
            gbck.Git_Repository__c = gitRepo.Id;
            gbck.Git_Snapshot_Permissions__c = ALLOW_SNAPSHOTS_COMMITS;
            insert gbck;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            pipeline.Git_Repository__c = gitRepo.Id;
            insert pipeline;

            Deployment_Flow_Step__c pipelineEnv = new Deployment_Flow_Step__c();
            pipelineEnv.Deployment_Flow__c = pipeline.Id;
            pipelineEnv.Branch__c = 'env1';
            pipelineEnv.Source_Environment__c = environmentList[0].Id;
            pipelineEnv.Destination_Environment__c = environmentList[1].Id;
            pipelineEnvList.add(pipelineEnv);

            Deployment_Flow_Step__c pipelineEnv2 = new Deployment_Flow_Step__c();
            pipelineEnv2.Deployment_Flow__c = pipeline.Id;
            pipelineEnv2.Branch__c = 'env2';
            pipelineEnvList.add(pipelineEnv2);

            insert pipelineEnvList;

            Project__c prj = new Project__c();
            prj.Name = 'My Project';
            prj.Deployment_Flow__c = pipeline.Id;
            insert prj;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environmentList[0].Id;
            us.Org_Credential__c = orgCredList[0].Id;
            us.Project__c = prj.Id;
            insert us;

            Test.startTest();
            WorkPushService workpushInstance = new WorkPushService();
            workpushInstance.getInstance();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(CALLOUT_DATA_MOCK, null));

            List<WorkPushService.CommitWrapper> cmWrList = new List<WorkPushService.CommitWrapper>();
            WorkPushService.CommitWrapper cmWr = new WorkPushService.CommitWrapper();
            cmWr.commitId = '0123456';
            cmWr.commitMessage = 'My Commit';
            cmWr.commitDate = String.valueOf(Datetime.now());
            cmWr.commitAuthor = 'Commit Author';
            cmWr.commitFiles = new List<String>{
                    'classes/Dummy1.cls', 'pages/Page1.page'
            };
            cmWrList.add(cmWr);

            WorkPushService.WorkPushWrapper wrks = new WorkPushService.WorkPushWrapper();
            wrks.userStory = us.Id;
            wrks.commitList = cmWrList;
            wrks.projectTypeField = NAMESPACE + 'Description__c'; //As we use a custom field that is not in the package I will use a standard field.

            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'push';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkPushService.WorkPushDataWrapper resp = (WorkPushService.WorkPushDataWrapper) JSON.deserialize(response, WorkPushService.WorkPushDataWrapper.class);
            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());

            List<Attachment> finalUSAttachment = [SELECT Id, Body FROM Attachment WHERE Name = 'Git MetaData' AND ParentId = :us.Id LIMIT 1];
            List<WorkPushService.SfRetrievable> sfrList = (List<WorkPushService.SfRetrievable>) JSON.deserialize(finalUSAttachment[0].Body.toString(), List<WorkPushService.SfRetrievable>.class);
            System.assertEquals(sfrList.size(), 2);

            System.assertEquals(sfrList[0].cb, 'Commit Author');
            System.assertEquals(sfrList[0].cmm, ADDED);
            System.assertEquals(sfrList[0].n, 'Dummy1');
            System.assertEquals(sfrList[0].r, false);
            System.assertEquals(sfrList[0].s, false);
            System.assertEquals(sfrList[0].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[0].t, APEX_CLASS);

            System.assertEquals(sfrList[1].cb, 'Commit Author');
            System.assertEquals(sfrList[1].cmm, ADDED);
            System.assertEquals(sfrList[1].n, 'Page1');
            System.assertEquals(sfrList[1].r, false);
            System.assertEquals(sfrList[1].s, false);
            System.assertEquals(sfrList[1].snapshotCommitId, '0123456');
            System.assertEquals(sfrList[1].t, APEX_PAGE);

            Test.stopTest();
        }
    }
}