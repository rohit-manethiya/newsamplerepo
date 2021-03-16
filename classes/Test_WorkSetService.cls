@IsTest
public with sharing class Test_WorkSetService {
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
    public static void workSetSearchUS() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>();
            List<Environment__c> environmentList = new List<Environment__c>();

            Environment__c env1 = new Environment__c();
            env1.Name = 'Environment 1';
            environmentList.add(env1);

            Environment__c env2 = new Environment__c();
            env2.Name = 'Environment 2';
            environmentList.add(env2);

            insert environmentList;


            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
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
            us.Project__c = prj.Id;

            insert us;

            User_Story__c finalUserStory = [SELECT Environment__c, Id, Project__c, Name FROM User_Story__c WHERE Id = :us.Id];

            Test.startTest();
            WorkSetService worksetInstance = new WorkSetService();
            worksetInstance.getInstance();


            WorkSetService.WorkSetWrapper wrks = new WorkSetService.WorkSetWrapper();
            wrks.criteria = 'Id';
            wrks.value = us.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'set';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkSetService.WorkSetDataWrapper resp = (WorkSetService.WorkSetDataWrapper) JSON.deserialize(response, WorkSetService.WorkSetDataWrapper.class);

            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());
            System.assertEquals(resp.environmentBranch, 'env1');
            System.assertEquals(resp.message, null);
            System.assertEquals(resp.userStory.Name, finalUserStory.Name);
            System.assertEquals(resp.userStory.Environment__c, finalUserStory.Environment__c);
            System.assertEquals(resp.userStory.Project__c, finalUserStory.Project__c);

            Test.stopTest();
        }
    }

    @IsTest
    public static void workSetUsWithoutEnvironment() {
        User u = [SELECT Id,Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            User_Story__c us = new User_Story__c();
            insert us;

            Test.startTest();
            WorkSetService worksetInstance = new WorkSetService();
            worksetInstance.getInstance();

            WorkSetService.WorkSetWrapper wrks = new WorkSetService.WorkSetWrapper();
            wrks.criteria = 'Id';
            wrks.value = us.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'set';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            CliSfDataWrapper resp = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);

            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.ERROR.name());
            System.assertEquals(resp.message, Label.USER_STORY_COMMIT_NO_ENVIRONMENT);

            Test.stopTest();
        }
    }
}