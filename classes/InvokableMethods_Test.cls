@isTest
private class InvokableMethods_Test {
    @testSetup static void testSetup() {
        TestUtilities.getAllMultilicense();
    }

    private static void createAPIkey() {
        insert TestUtilities.getTestSettings();

        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if(String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('143sadfwet2341434');
            upsert ps;
        }
    }

    @isTest static void refreshOrgMetadataCacheTest() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RefreshOrgMetadataCache.InvocableVariables> variableList = new List<RefreshOrgMetadataCache.InvocableVariables>();
        RefreshOrgMetadataCache.InvocableVariables firstSet = new RefreshOrgMetadataCache.InvocableVariables();
        firstSet.orgId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RefreshOrgMetadataCache.execute(variableList);
        Test.stopTest();
    }
    @isTest static void calculateSnapshotDifferencesTest() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<CalculateSnapshotDifferences.InvocableVariables> variableList = new List<CalculateSnapshotDifferences.InvocableVariables>();
        CalculateSnapshotDifferences.InvocableVariables firstSet = new CalculateSnapshotDifferences.InvocableVariables();
        firstSet.snapshotDiffId = UserInfo.getUserId(); // mocking the id param
        firstSet.deploy = FALSE;
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        CalculateSnapshotDifferences.execute(variableList);
        Test.stopTest();
    }
    @isTest static void recalculateDeploymentFlowBranchStatuses() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RecalculateDeploymentFlowBranchStatuses.InvocableVariables> variableList = new List<RecalculateDeploymentFlowBranchStatuses.InvocableVariables>();
        RecalculateDeploymentFlowBranchStatuses.InvocableVariables firstSet = new RecalculateDeploymentFlowBranchStatuses.InvocableVariables();
        firstSet.flowId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RecalculateDeploymentFlowBranchStatuses.execute(variableList);
        Test.stopTest();
    }
    @isTest static void executeDeployment() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<ExecuteDeployment.InvocableVariables> variableList = new List<ExecuteDeployment.InvocableVariables>();
        ExecuteDeployment.InvocableVariables firstSet = new ExecuteDeployment.InvocableVariables();
        firstSet.depId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        ExecuteDeployment.execute(variableList);
        Test.stopTest();
    }
    @isTest static void takeGitSnapshot() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<TakeGitSnapshot.InvocableVariables> variableList = new List<TakeGitSnapshot.InvocableVariables>();
        TakeGitSnapshot.InvocableVariables firstSet = new TakeGitSnapshot.InvocableVariables();
        firstSet.snapshotId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        TakeGitSnapshot.execute(variableList);
        Test.stopTest();
    }
    @isTest static void runAllOrgApexTests() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunAllOrgApexTests.InvocableVariables> variableList = new List<RunAllOrgApexTests.InvocableVariables>();
        RunAllOrgApexTests.InvocableVariables firstSet = new RunAllOrgApexTests.InvocableVariables();
        firstSet.orgId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunAllOrgApexTests.execute(variableList);
        Test.stopTest();
    }
    @isTest static void runContinuousIntegration() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunContinuousIntegration.InvocableVariables> variableList = new List<RunContinuousIntegration.InvocableVariables>();
        RunContinuousIntegration.InvocableVariables firstSet = new RunContinuousIntegration.InvocableVariables();
        firstSet.ciId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunContinuousIntegration.execute(variableList);
        Test.stopTest();
    }
    @isTest static void runSeleniumTestGroup() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunSeleniumTestGroup.InvocableVariables> variableList = new List<RunSeleniumTestGroup.InvocableVariables>();
        RunSeleniumTestGroup.InvocableVariables firstSet = new RunSeleniumTestGroup.InvocableVariables();
        firstSet.groupId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunSeleniumTestGroup.execute(variableList);
        Test.stopTest();
    }
    @isTest static void runSeleniumTest() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunSeleniumTest.InvocableVariables> variableList = new List<RunSeleniumTest.InvocableVariables>();
        RunSeleniumTest.InvocableVariables firstSet = new RunSeleniumTest.InvocableVariables();
        firstSet.runId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunSeleniumTest.execute(variableList);
        Test.stopTest();
    }

    @isTest static void recalculateBranchStatus() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RecalculateBranchStatus.InvocableVariables> variableList = new List<RecalculateBranchStatus.InvocableVariables>();
        RecalculateBranchStatus.InvocableVariables firstSet = new RecalculateBranchStatus.InvocableVariables();
        firstSet.flowId = UserInfo.getUserId(); // mocking the id param
        firstSet.branchName = 'dev';
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RecalculateBranchStatus.execute(variableList);
        Test.stopTest();
    }
    @isTest static void userStoryCommitFiles() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<UserStoryCommitFiles.InvocableVariables> variableList = new List<UserStoryCommitFiles.InvocableVariables>();
        UserStoryCommitFiles.InvocableVariables firstSet = new UserStoryCommitFiles.InvocableVariables();
        firstSet.userStoryId = UserInfo.getUserId(); // mocking the id param
        firstSet.commitMessage = 'TEST';
        firstSet.jsonBody = '[{}]';
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        UserStoryCommitFiles.execute(variableList);
        Test.stopTest();
    }
    @isTest static void deployPromotion() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunDeployPromotion.InvocableVariables> variableList = new List<RunDeployPromotion.InvocableVariables>();
        RunDeployPromotion.InvocableVariables firstSet = new RunDeployPromotion.InvocableVariables();
        firstSet.promotionId = UserInfo.getUserId(); // mocking the id param
        firstSet.checkOnly = true;
        firstSet.testLevel = 'Run All Tests';
        firstSet.deploymentName = 'My test deployment';
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunDeployPromotion.execute(variableList);
        Test.stopTest();
    }
    @isTest static void orgCompliance() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunOrgComplianceScan.InvocableVariables> variableList = new List<RunOrgComplianceScan.InvocableVariables>();
        RunOrgComplianceScan.InvocableVariables firstSet = new RunOrgComplianceScan.InvocableVariables();
        firstSet.orgId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunOrgComplianceScan.execute(variableList);
        Test.stopTest();
    }
    @isTest static void snapshotCompliance() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunSnapshotComplianceScan.InvocableVariables> variableList = new List<RunSnapshotComplianceScan.InvocableVariables>();
        RunSnapshotComplianceScan.InvocableVariables firstSet = new RunSnapshotComplianceScan.InvocableVariables();
        firstSet.snapId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunSnapshotComplianceScan.execute(variableList);
        Test.stopTest();
    }
    @isTest static void storyCompliance() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunUserStoryComplianceScan.InvocableVariables> variableList = new List<RunUserStoryComplianceScan.InvocableVariables>();
        RunUserStoryComplianceScan.InvocableVariables firstSet = new RunUserStoryComplianceScan.InvocableVariables();
        firstSet.storyId = UserInfo.getUserId(); // mocking the id param
        firstSet.repoId = UserInfo.getUserId(); // mocking the id param
        firstSet.branch = 'dev';
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunUserStoryComplianceScan.execute(variableList);
        Test.stopTest();
    }
    @isTest static void storySCA() {
        createAPIkey();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);

        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
                Static_Code_Analysis_Settings__c = scas.Id,
                Rule_Name__c = 'ApexBadCrypto',
                Priority__c = '3');
        insert scar;

        List<Feature__c> features = new List<Feature__c>();
        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        features.add(f);
        f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        features.add(f);
        f = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        features.add(f);
        insert features;

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(Name = 'test', Active__c = true, Main_Branch__c = 'master', Git_Repository__c = gr.Id, Static_Code_Analysis_Settings__c = scas.Id);
        insert df;

        Project__c p = new Project__c(Name = 'Test Project', Deployment_Flow__c = df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for(Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for(Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        List<Attachment> attachments = new List<Attachment>();
        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        Attachment testAttachment = createAttachment(us.Id, 'MetaData', attBody);
        attachments.add(testAttachment);

        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Git MetaData', attBody);
        attachments.add(testAttachment);

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Delete MetaData', attBody);
        attachments.add(testAttachment);
        insert attachments;

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev1', Source_Environment__c = Le[0].Id, Destination_Environment__c = Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev2', Source_Environment__c = Le[1].Id, Destination_Environment__c = Le[2].Id));
        insert inserts;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunUserStoryStaticCodeAnalysis.InvocableVariables> variableList = new List<RunUserStoryStaticCodeAnalysis.InvocableVariables>();
        RunUserStoryStaticCodeAnalysis.InvocableVariables firstSet = new RunUserStoryStaticCodeAnalysis.InvocableVariables();
        firstSet.storyId = us.Id; // mocking the id param
        firstSet.orgId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunUserStoryStaticCodeAnalysis.execute(variableList);
        Test.stopTest();
    }
    @isTest static void orgSCA() {
        createAPIkey();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);

        Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
        insert scas;

        Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
                Static_Code_Analysis_Settings__c = scas.Id,
                Rule_Name__c = 'ApexBadCrypto',
                Priority__c = '3');
        insert scar;


        List<Feature__c> features = new List<Feature__c>();
        Feature__c f = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 5);
        features.add(f);
        f = new Feature__c(Name = 'Git Backup', Enabled__c = true);
        features.add(f);
        f = new Feature__c(Name = 'Apex Test', Enabled__c = true);
        features.add(f);
        insert features;

        Git_Repository__c gr = new Git_Repository__c(Name = 'test');
        insert gr;

        Deployment_Flow__c df = new Deployment_Flow__c(Name = 'test', Active__c = true, Main_Branch__c = 'master', Git_Repository__c = gr.Id, Static_Code_Analysis_Settings__c = scas.Id);
        insert df;

        List<Environment__c> environments = new List<Environment__c>();
        for(Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            environments.add(e);
        }
        insert environments;

        List<Org__c> orgCredentials = new List<Org__c>();
        for(Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = environments[i].Id);
            orgCredentials.add(o);
        }
        insert orgCredentials;

        List<Deployment_Flow_Step__c> flowSteps = new List<Deployment_Flow_Step__c>();
        flowSteps.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev1', Source_Environment__c = environments[0].Id, Destination_Environment__c = environments[1].Id));
        flowSteps.add(new Deployment_Flow_Step__c(Deployment_Flow__c = df.Id, Branch__c = 'dev2', Source_Environment__c = environments[1].Id, Destination_Environment__c = environments[2].Id));
        insert flowSteps;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunOrgStaticCodeAnalysis.InvocableVariables> variableList = new List<RunOrgStaticCodeAnalysis.InvocableVariables>();
        RunOrgStaticCodeAnalysis.InvocableVariables firstSet = new RunOrgStaticCodeAnalysis.InvocableVariables();
        firstSet.orgId = orgCredentials[0].Id;
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunOrgStaticCodeAnalysis.execute(variableList);
        Test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(parentId = parentId, name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }

    @IsTest static void runUserStoryTests() {
        createAPIkey();
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Project__c p = new Project__c(Name = 'Test Project');
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for(Integer i = 0; i < 6; i++) {
            Environment__c e = new Environment__c(Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;

        List<Org__c> Lo = new List<Org__c>();
        for(Integer i = 0; i < 6; i++) {
            Org__c o = new Org__c(Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        List<RunUserStoryTests.InvocableVariables> variableList = new List<RunUserStoryTests.InvocableVariables>();
        RunUserStoryTests.InvocableVariables firstSet = new RunUserStoryTests.InvocableVariables();
        firstSet.userStoryId = us.Id;
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunUserStoryTests.execute(variableList);
        Test.stopTest();
    }
}