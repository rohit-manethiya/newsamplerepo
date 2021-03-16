@IsTest
private with sharing class SeleniumTestCaseViewEditTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
        }
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void testPostRestService() {
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/SeleniumTestCaseViewEdit';
        req.httpMethod = 'POST'; //HTTP Request Type
        RestContext.request = req;
        RestContext.response = res;

        Id newId;
        String newName;
        String newVersion;
        String testCaseSrc;
        String testDataSrc;
        Map<String, Object> info;
        Map<String, Object> tc;
        Map<String, Object> tca;
        Map<String, Object> tda;

        String TestCaseId;
        String TestCaseName;
        String TestCaseVersion;
        ID TestCaseCaseId;
        ID TestCaseDataId;

        testCaseSrc = '{}';
        testDataSrc = null;

        String nullResp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseSaveAll(newId, newVersion, newName, testCaseSrc, testDataSrc));
        System.assertEquals('null', nullResp);

        nullResp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseSaveAll(newId, newVersion, newName, testCaseSrc, testDataSrc));
        System.assertEquals('null', nullResp);

        newId = null;
        newName = 'Test #1';
        newVersion = null;
        testCaseSrc = '{"name": "Test #1", "baseUrl": "http://google.com/", "commands": []}';

        String resp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseSaveAll(newId, newVersion, newName, testCaseSrc, testDataSrc));

        info = (Map<String, Object>) JSON.deserializeUntyped(resp);
        tc = (Map<String, Object>) info.get('tc');
        tca = (Map<String, Object>) info.get('testCase');
        tda = (Map<String, Object>) info.get('testData');
        TestCaseId = (Id) tc.get('Id');
        TestCaseName = (String) tc.get('Name');
        TestCaseVersion = (String) tc.get('Version');
        TestCaseCaseId = (ID) tca.get('Id');

        System.assertNotEquals(null, TestCaseId);
        System.assertEquals(newName, TestCaseName);
        System.assertEquals('1', TestCaseVersion);
        System.assertEquals(null, tda);
        System.assertEquals('Copado.SeleniumTestCase.json', tca.get('Name'));
        System.assertEquals(null, TestCaseDataId); // a testcase without data should not create an attachment for that.

        newId = TestCaseId;

        testCaseSrc = '{"name": "Test #1á", "baseUrl": "http://google.com/á", "commands": []}';
        newName = 'Test #1á';
        newVersion = '30';

        resp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseSaveAll(newId, newVersion, newName, testCaseSrc, testDataSrc));

        info = (Map<String, Object>) JSON.deserializeUntyped(resp);
        tc = (Map<String, Object>) info.get('tc');
        tca = (Map<String, Object>) info.get('testCase');
        tda = (Map<String, Object>) info.get('testData');
        TestCaseId = (Id) tc.get('Id');
        TestCaseName = (String) tc.get('Name');
        TestCaseVersion = (String) tc.get('Version');

        System.assertEquals(newId, TestCaseId);
        System.assertEquals(newName, TestCaseName);
        System.assertEquals(newVersion, TestCaseVersion);
        System.assertEquals(null, tda);
        System.assertEquals((ID) tca.get('Id'), TestCaseCaseId); // no new attachment should be created
        System.assertEquals(null, TestCaseDataId); // a testcase without data should not create an attachment for that.

        testDataSrc = '[{"name": "Dataset #1á", "data": ["dummy"]}]';
        resp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseSaveAll(newId, newVersion, newName, testCaseSrc, testDataSrc));

        info = (Map<String, Object>) JSON.deserializeUntyped(resp);
        tc = (Map<String, Object>) info.get('tc');
        tca = (Map<String, Object>) info.get('testCase');
        tda = (Map<String, Object>) info.get('testData');
        TestCaseId = (Id) tc.get('Id');
        TestCaseName = (String) tc.get('Name');
        TestCaseVersion = (String) tc.get('Version');
        TestCaseCaseId = (ID) tca.get('Id');
        TestCaseDataId = (ID) tda.get('Id');

        System.assertEquals(newId, TestCaseId);
        System.assertEquals(newName, TestCaseName);
        System.assertEquals(newVersion, TestCaseVersion);
        System.assertNotEquals(null, tda); // now we do have data
        System.assertNotEquals(null, tda.get('Id'));

        req.requestURI = '/services/apexrest/SeleniumTestCaseViewEdit?id=' + newId;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        String allResp = JSON.serialize(SeleniumTestCaseViewEdit.testCaseLoadAll());

        String result;
        List<Object> result1;

        ApexPages.currentPage().getParameters().put('q', 'test');
        result = SeleniumTestCaseViewEdit.getLookupTestCases();
        result1 = (List<Object>) JSON.deserializeUntyped(result);
        System.assertEquals(1, result1.size());

        ApexPages.currentPage().getParameters().put('id', newId);
        System.assertNotEquals(null, SeleniumTestCaseViewEdit.getJsonTestCases());

        Selenium_Test_Suite__c s = new Selenium_Test_Suite__c(Name = 'UnitTest');
        insert s;
        Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(
            Selenium_Test_Suite__c = s.Id,
            Selenium_Test_Case__c = newId,
            Test_Dataset_Name__c = 'Dataset #1'
        );
        insert cs;

        ApexPages.currentPage().getParameters().put('id', s.Id);
        String result2 = SeleniumTestCaseViewEdit.getLookupTestCases();
        List<Object> result3 = (List<Object>) JSON.deserializeUntyped(result2);
        System.assertEquals(1, result3.size());
        System.assertEquals('Dataset #1', (String) ((Map<String, Object>) result3.get(0)).get('selectedDataset'));
        List<Object> datasets = (List<Object>) ((Map<String, Object>) result3.get(0)).get('datasets');
        System.assertEquals(1, datasets.size());

        ApexPages.currentPage().getParameters().put('id', s.Id);
        ApexPages.StandardController std = new ApexPages.StandardController(s);
        SeleniumTestCaseViewEdit controller = new SeleniumTestCaseViewEdit(std);
        controller.TestCasesPerSuiteSave = '[["' + newId + '", null]]';
        PageReference nextPage = controller.saveTestCasesPerSuite();
        System.assertNotEquals(null, nextPage);
    }
}