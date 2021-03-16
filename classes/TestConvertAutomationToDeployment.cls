@isTest
private class TestConvertAutomationToDeployment {

    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    private static void makeData() {
        Map<String, RecordTypeInfo> deploymentRecordTypes = SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

            List<Environment__c> envList = TestDataFactory.createEnvironments(2);

            List<Org__c> orgList = TestDataFactory.createOrgCredentials(2, standardUser.Username, envList);

            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    Deployment__c.SObjectType,
                    Deployment__c.RecordTypeId,
                    deploymentRecordTypes.get('Automation_Template').getRecordTypeId()
                )
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
                .setFieldValue(Step__c.SObjectType, Step__c.DataJson__c, '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}')
                .setDataSize(Step__c.SObjectType, 10)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    private static void executeAutomationTemplate() {
        System.runAs(getStandardUser()) {
            Deployment__c automationTemplate = getDeployment();
            List<Org__c> orgList = getOrgs();

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(getMockResponse(), null));

            Test.startTest();
            convertAutomation(automationTemplate.Id, orgList[0].Id, orgList[1].Id, true);
            Test.stopTest();

            List<Deployment__c> convertedDeployments = getConvertedDeployments(automationTemplate);
            List<Result__c> results = getResults(convertedDeployments[0]);
            System.assertEquals(1, convertedDeployments.size(), 'The automation template should be converted in a new advanced deployment record');
            System.assertEquals(1, results.size(), 'There should be only one result record for this deployment record');
        }
    }

    @IsTest
    private static void executeAutomationTemplateWithoutOptionalParameters() {
        System.runAs(getStandardUser()) {
            Deployment__c automationTemplate = getDeployment();

            Test.startTest();
            convertAutomation(automationTemplate.Id, null, null, false);
            Test.stopTest();

            List<Deployment__c> convertedDeployments = getConvertedDeployments(automationTemplate);
            List<Result__c> results = getResults(convertedDeployments[0]);
            System.assertEquals(1, convertedDeployments.size(), 'The automation template should be converted in a new advanced deployment record');
            System.assertEquals(1, results.size(), 'There should be only one result record for this deployment record');
        }
    }

    @IsTest
    private static void executeAutomationTemplateWithSourceOrgOnly() {
        System.runAs(getStandardUser()) {
            Deployment__c automationTemplate = getDeployment();
            List<Org__c> orgList = getOrgs();

            Test.startTest();
            convertAutomation(automationTemplate.Id, orgList[0].Id, null, false);
            Test.stopTest();

            List<Deployment__c> convertedDeployments = getConvertedDeployments(automationTemplate);
            List<Result__c> results = getResults();
            System.assertEquals(0, convertedDeployments.size(), 'The automation template should not be converted in a new advanced deployment record because only source credential was provided');
            System.assertEquals(1, results.size(), 'There should be only one result record for this deployment record');
        }
    }

    private static String getMockResponse(){
        // AUTO RECHARGE NOT ENABLED
        return '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":1000,"credits":1348,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
    }

    private static User getStandardUser(){
        return [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
    }

    private static Deployment__c getDeployment(){
        return [SELECT Id, Name FROM Deployment__c LIMIT 1];
    }

    private static List<Org__c> getOrgs(){
        return [SELECT Id FROM Org__c];
    }

    private static List<Deployment__c> getConvertedDeployments(Deployment__c automationTemplate){
        String newDeploymentName = Label.Execution_of + ' ' + automationTemplate.Name;
        return [SELECT Id FROM Deployment__c WHERE Name = :newDeploymentName];
    }

    private static List<Result__c> getResults(Deployment__c automationTemplate){
        return [SELECT Id FROM Result__c WHERE Deployment__c = :automationTemplate.Id];
    }

    private static List<Result__c> getResults(){
        return [SELECT Id FROM Result__c];
    }

    private static void convertAutomation(Id automationTemplateId, String sourceCredentialId, String targetCredentialId, Boolean execute){
        ConvertAutomationToDeployment.InvocableVariables request = new ConvertAutomationToDeployment.InvocableVariables();
        request.automationTemplateId = automationTemplateId;
        request.sourceCredentialIdString = sourceCredentialId;
        request.targetCredentialIdString = targetCredentialId;
        request.execute = execute;
        ConvertAutomationToDeployment.execute(new List<ConvertAutomationToDeployment.InvocableVariables>{ request });
    }

}