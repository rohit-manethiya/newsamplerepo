@IsTest
private class TestExternalCI {
    @TestSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    @IsTest static void successfullValidate() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting handler = new EditExternalCISetting(sc);

        handler.externalCISetting.CI_Tool__c = 'Jenkins';
        handler.apiKey = 'TestAPIToken';
        handler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        handler.password = 'testPW';
        handler.username = 'testUN';

        handler.save();
        System.assertNotEquals(null, handler.externalCISetting.Id);
        String body = '{"ok":"success","message":"test"}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        handler.validate();
        System.assertEquals(true, handler.externalCISetting.Credential_Validated__c);
        Test.stopTest();

    }

    @IsTest static void errorValidate() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting handler = new EditExternalCISetting(sc);

        handler.externalCISetting.CI_Tool__c = 'Jenkins';
        handler.apiKey = 'TestAPIToken';
        handler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        handler.password = 'testPW';
        handler.username = 'testUN';

        handler.save();
        System.assertNotEquals(null, handler.externalCISetting.Id);
        String body = '{"error":"failed","message":"failed"}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        handler.validate();
        System.assertEquals(false, handler.externalCISetting.Credential_Validated__c);
        Test.stopTest();

    }

    @IsTest static void noURL() {
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting handler = new EditExternalCISetting(sc);

        handler.externalCISetting.CI_Tool__c = 'Jenkins';
        handler.apiKey = 'TestAPIToken';
        handler.externalCISetting.Endpoint__c = null;
        handler.password = 'testPW';
        handler.username = 'testUN';

        handler.save();
        System.assertEquals(null, handler.externalCISetting.id);
    }

    @IsTest static void failedDML() {
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting handler = new EditExternalCISetting(sc);
        handler.externalCISetting.Endpoint__c = null;
        handler.username = 'testUN';

        handler.save();
        System.assertEquals(null, handler.externalCISetting.id);
    }

    @IsTest static void retrieveJobs() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Jenkins';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);

        ApexPages.StandardController sc2 = new ApexPages.StandardController(new External_CI_Job__c());
        ExternalCIJobsExtension jobHandler = new ExternalCIJobsExtension(sc2);

        PageReference pageRef = Page.EditExternalCIJob;
        System.Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('setId', settingHandler.externalCISetting.Id);
        jobHandler.externalCIjob.External_CI_Setting__c = settingHandler.externalCISetting.Id;


        String body = '{"jobs":[{"name":"test","url":"http://devops-jenkins.copado.com:8080/job/test/"},{"name":"test-params","url":"http://devops-jenkins.copado.com:8080/job/test-params/"}]}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        jobHandler.retrievejobsList();

        String paramsJSON = '{"parameters": [ {"name":"numParam","value":10}, {"name":"stringParam","value":"xyz"}, {"name":"boolParam","value":true} ] }';
        jobHandler.externalCIjob.Name = 'Test';
        jobHandler.externalCIjob.DataJSON__c = paramsJSON;
        jobHandler.externalCIjob.Job_Api_Name__c = 'Test';
        jobHandler.externalCIjob.Invoke_on__c = 'Before deployment';
        jobHandler.externalCIjob.Order__c = 1;
        jobHandler.externalCIjob.Timeout_in_minutes__c = 10;
        jobHandler.tempJSON = '[["numParam",10],["stringParam","xyz"],["boolParam",true]]';
        jobHandler.saveJob();

        jobHandler.addUrlParam();
        System.assertNotEquals(0, jobHandler.urlParams.size());

        ApexPages.currentPage().getParameters().put('order', '0');
        jobHandler.removeUrlParam();
        System.assertEquals(3, jobHandler.urlParams.size());

        ApexPages.currentPage().getParameters().put('selectedJob', 'testJob');
        jobHandler.jobName = 'testJob';
        jobHandler.selectJob();
        System.assertEquals('testJob', jobHandler.externalCIjob.Job_API_Name__c);

        jobHandler.setSetting();
        System.assertEquals('Jenkins', jobHandler.settingType);
        jobHandler.deleteJob();
        jobHandler.deleteJob();
        Test.stopTest();

    }
    @IsTest static void buildJob() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Jenkins';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);

        ApexPages.StandardController sc2 = new ApexPages.StandardController(new External_CI_Job__c());
        ExternalCIJobsExtension jobHandler = new ExternalCIJobsExtension(sc2);

        String body = '{"copadoJobId":"e19921ea-8c7d-428d-b293-9246ea60b4d3","ok":"Job has started!"}';
        Test.startTest();
        String paramsJSON = '{"parameters": [ {"name":"numParam","value":10}, {"name":"stringParam","value":"xyz"}, {"name":"boolParam","value":true} ] }';
        jobHandler.externalCIjob.Name = 'Test';
        jobHandler.externalCIjob.DataJSON__c = paramsJSON;
        jobHandler.externalCIjob.Job_Api_Name__c = 'Test';
        jobHandler.externalCIjob.Invoke_on__c = 'Before deployment';
        jobHandler.externalCIjob.Order__c = 1;
        jobHandler.externalCIjob.Timeout_in_minutes__c = 10;
        jobHandler.externalCIjob.External_CI_Setting__c = settingHandler.externalCISetting.Id;
        jobHandler.tempJSON = '[["numParam",10],["stringParam","xyz"],["boolParam",true]]';
        jobHandler.saveJob();
        jobHandler.setSetting(settingHandler.externalCISetting.Id);
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        jobHandler.BuildJob();
        ApexPages.StandardController sc3 = new ApexPages.StandardController(jobHandler.externalCIjob);
        ExternalCIJobsExtension jobHandler2 = new ExternalCIJobsExtension(sc3);
        Test.stopTest();
    }
    @IsTest static void unsupportedCIType() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Testkins';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);
        PageReference pageRef = Page.EditExternalCIJob;
        System.Test.setCurrentPage(pageRef);
        ExternalCIAPIFactory factory = new ExternalCIAPIFactory(settingHandler.externalCISetting.Id);
    }
    @IsTest static void sendRequest() {
        testMethodUtilities.upsertOrgwideSettings();
        String body = '{"jobs":[{"name":"test","url":"http://devops-jenkins.copado.com:8080/job/test/"},{"name":"test-params","url":"http://devops-jenkins.copado.com:8080/job/test-params/"}]}';
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Jenkins';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        ExternalCIAPIFactory factory = new ExternalCIAPIFactory(settingHandler.externalCISetting.Id);
        String paramsJSON = '{"parameters": [ {"name":"numParam","value":10}, {"name":"stringParam","value":"xyz"}, {"name":"boolParam","value":true} ] }';
        HttpResponse res = factory.sendRequest(paramsJSON, 'GET', new Map<String, String>());
        System.assertNotEquals(null, res);
        Test.stopTest();
    }

    @IsTest static void queryAllValues() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Jenkins';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);

        List<SObject> temp = ExternalCIAPIFactory.queryAllValues('External_CI_Setting__c', 'Id', settingHandler.externalCISetting.Id, 'AND Name != null', 'LIMIT 1');
        System.assertEquals(1, temp.size());
    }

    @IsTest static void validateTeamCity() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting handler = new EditExternalCISetting(sc);

        handler.externalCISetting.CI_Tool__c = 'Team City';
        handler.apiKey = 'TestAPIToken';
        handler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        handler.password = 'testPW';
        handler.username = 'testUN';

        handler.save();
        System.assertNotEquals(null, handler.externalCISetting.Id);
        String body = '{"ok":"success","message":"test"}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        handler.validate();
        System.assertEquals(true, handler.externalCISetting.Credential_Validated__c);
        Test.stopTest();

    }

    @IsTest static void retrieveTeamCityJobs() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Team City';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);

        ApexPages.StandardController sc2 = new ApexPages.StandardController(new External_CI_Job__c());
        ExternalCIJobsExtension jobHandler = new ExternalCIJobsExtension(sc2);

        PageReference pageRef = Page.EditExternalCIJob;
        System.Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('setId', settingHandler.externalCISetting.Id);
        jobHandler.externalCIjob.External_CI_Setting__c = settingHandler.externalCISetting.Id;


        String body = '{"jobs":[{"name":"test","url":"http://devops-jenkins.copado.com:8080/job/test/"},{"name":"test-params","url":"http://devops-jenkins.copado.com:8080/job/test-params/"}]}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        jobHandler.retrievejobsList();

        String paramsJSON = '{"parameters": [ {"name":"numParam","value":10}, {"name":"stringParam","value":"xyz"}, {"name":"boolParam","value":true} ] }';
        jobHandler.externalCIjob.Name = 'Test';
        jobHandler.externalCIjob.DataJSON__c = paramsJSON;
        jobHandler.externalCIjob.Job_Api_Name__c = 'Test';
        jobHandler.externalCIjob.Invoke_on__c = 'Before deployment';
        jobHandler.externalCIjob.Order__c = 1;
        jobHandler.externalCIjob.Timeout_in_minutes__c = 10;
        jobHandler.tempJSON = '[["numParam",10],["stringParam","xyz"],["boolParam",true]]';
        jobHandler.saveJob();

        jobHandler.addUrlParam();
        System.assertNotEquals(0, jobHandler.urlParams.size());

        ApexPages.currentPage().getParameters().put('order', '0');
        jobHandler.removeUrlParam();
        System.assertEquals(3, jobHandler.urlParams.size());

        ApexPages.currentPage().getParameters().put('selectedJob', 'testJob');
        jobHandler.jobName = 'testJob';
        jobHandler.selectJob();
        System.assertEquals('testJob', jobHandler.externalCIjob.Job_API_Name__c);

        jobHandler.setSetting();
        System.assertEquals('Team City', jobHandler.settingType);
        jobHandler.deleteJob();
        jobHandler.deleteJob();
        Test.stopTest();

    }

    @IsTest static void buildTeamCityJob() {
        testMethodUtilities.upsertOrgwideSettings();
        ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
        EditExternalCISetting settingHandler = new EditExternalCISetting(sc);

        settingHandler.externalCISetting.CI_Tool__c = 'Team City';
        settingHandler.apiKey = 'TestAPIToken';
        settingHandler.externalCISetting.Endpoint__c = 'http://test-copado.copado.com:8080/';
        settingHandler.password = 'testPW';
        settingHandler.username = 'testUN';

        settingHandler.save();
        System.assertNotEquals(null, settingHandler.externalCISetting.Id);
        System.assertEquals('Team City', settingHandler.externalCISetting.CI_Tool__c);

        ApexPages.StandardController sc2 = new ApexPages.StandardController(new External_CI_Job__c());
        ExternalCIJobsExtension jobHandler = new ExternalCIJobsExtension(sc2);

        String body = '{"copadoJobId":"e19921ea-8c7d-428d-b293-9246ea60b4d3","ok":"Job has started!"}';
        Test.startTest();
        String paramsJSON = '{"parameters": [ {"name":"numParam","value":10}, {"name":"stringParam","value":"xyz"}, {"name":"boolParam","value":true} ] }';
        jobHandler.externalCIjob.Name = 'Test';
        jobHandler.externalCIjob.dataJSON__c = paramsJSON;
        jobHandler.externalCIjob.Job_Api_Name__c = 'Test';
        jobHandler.externalCIjob.Invoke_on__c = 'Before deployment';
        jobHandler.externalCIjob.Order__c = 1;
        jobHandler.externalCIjob.Timeout_in_minutes__c = 10;
        jobHandler.externalCIjob.External_CI_Setting__c = settingHandler.externalCISetting.Id;
        jobHandler.tempJSON = '[["numParam",10],["stringParam","xyz"],["boolParam",true]]';
        jobHandler.saveJob();
        jobHandler.setSetting(settingHandler.externalCISetting.Id);
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(body, null));
        jobHandler.BuildJob();
        ApexPages.StandardController sc3 = new ApexPages.StandardController(jobHandler.externalCIjob);
        ExternalCIJobsExtension jobHandler2 = new ExternalCIJobsExtension(sc3);
        Test.stopTest();
    }
}