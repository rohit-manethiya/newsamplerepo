@IsTest
public with sharing class Test_WorkDisplayService {

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

            Sprint__c spr = new Sprint__c();
            spr.Name = 'My Current Sprint';
            insert spr;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environmentList[0].Id;
            us.Project__c = prj.Id;
            us.User_Story_Title__c = 'My User Story Title';
            us.Sprint__c = spr.Id;

            insert us;

            User_Story__c finalUserStory = [SELECT Id, Name, User_Story_Title__c, Status__c, Project__r.Name, Sprint__c, Release__r.Name FROM User_Story__c WHERE Id = :us.Id];

            Test.startTest();
            WorkDisplayService workdisplayInstance = new WorkDisplayService();
            workdisplayInstance.getInstance();

            WorkDisplayService.WorkDisplayWrapper wrks = new WorkDisplayService.WorkDisplayWrapper();
            wrks.criteria = 'Id';
            wrks.value = us.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'display';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();

            WorkDisplayService.WorkDisplayDataWrapper resp = (WorkDisplayService.WorkDisplayDataWrapper) JSON.deserialize(response, WorkDisplayService.WorkDisplayDataWrapper.class);

            System.assertEquals(resp.status, CliSfDataWrapper.StatusResult.OK.name());
            System.assertEquals(resp.message, null);
            System.assertEquals(resp.userStory.Name, finalUserStory.Name);
            System.assertEquals(resp.userStory.User_Story_Title__c, finalUserStory.User_Story_Title__c);
            System.assertEquals(resp.userStory.Status__c, finalUserStory.Status__c);
            System.assertEquals(resp.userStory.Project__r.Name, finalUserStory.Project__r.Name);
            System.assertEquals(resp.userStory.Sprint__c, finalUserStory.Sprint__c);
            System.assertEquals(resp.userStory.Release__r.Name, finalUserStory.Release__r.Name);

            Test.stopTest();
        }
    }
}