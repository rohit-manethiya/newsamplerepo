@IsTest
private class TestDeployJobHelper {
    @TestSetup
    static voId setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    @isTest
    public static voId doTest() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgTestName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'Pending');
        insert deployment;
        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert destinationOrg;
        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 0, 'Pending', 'MetaData');
        insert step;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id]);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert secondDestinationOrg;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id]);
        System.assertEquals(2, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id]);

        delete destinationOrg;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id]);
    }

    @isTest
    public static voId testNextStep() {
        testMethodUtilities.upsertOrgwIdeSettings();

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgTestName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'Pending');
        insert deployment;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        String dataJson = '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":"';
        dataJson += UserInfo.getUserId();
        dataJson += '","Notify_Task_Owner":"Chatter and Email"}';
        Step__c step = testMethodUtilities.create('Step 1', 'attId', dataJson, deployment.Id, 1, 'Pending', 'Manual Task');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 2, 'Pending', 'MetaData');
        insert new List<Step__c>{ step, step2 };

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c);

        deploymentJob.Status__c = 'Success';
        deploymentJob.Deployed__c = 100;
        update deploymentJob;
        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
    }

    @isTest
    public static voId testNextStep2() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();
        insert deployment;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };
        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 2, 'Pending', 'MetaData');
        insert new List<Step__c>{ step, step2 };

        Test.startTest();
        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c);

        deploymentJob.Status__c = 'Failed';
        deploymentJob.Deployed__c = 0;
        update deploymentJob;

        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('In progress', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);

        Deployment_Job__c stepDeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', stepDeploymentJobToUpdate.Status__c);

        stepDeploymentJobToUpdate.Status__c = 'Failed';
        stepDeploymentJobToUpdate.Deployed__c = 0;
        update stepDeploymentJobToUpdate;
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);

        Deployment_Job__c step2DeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step2.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', step2DeploymentJobToUpdate.Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);

        Deployment_Job__c step2DeploymentJobToUpdateForSecondDestinationOrg = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step2.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', step2DeploymentJobToUpdateForSecondDestinationOrg.Status__c);
        System.assertEquals('Pending', [SELECT Status__c FROM step__c WHERE Id = :step2.Id].Status__c);
        Test.stopTest();
    }
    @isTest
    public static voId testNextStep3() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert deployment;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        insert step;

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c);
        deploymentJob.Status__c = 'Failed';
        deploymentJob.Deployed__c = 0;
        update deploymentJob;
        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('In progress', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Destination_Org__c WHERE Id = :destinationOrg.Id].Status__c);

        Deployment_Job__c stepDeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', stepDeploymentJobToUpdate.Status__c);
        stepDeploymentJobToUpdate.Status__c = 'Success';
        stepDeploymentJobToUpdate.Deployed__c = 100;
        update stepDeploymentJobToUpdate;
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Destination_Org__c WHERE Id = :secondDestinationOrg.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);
    }

    @IsTest
    private static void testSalesforceFlowStepExecution() {
        Settings__c setting = Settings__c.getOrgDefaults();
        setting.CryptoKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        upsert setting;

        Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
        personalSetting.API_Key__c = DeployAPI.encryptAPIKey('testApiKey');
        upsert personalSetting;

        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        String dataJson =
            '{"flowApiName": "TestFlow","type":"wait","flowParameters":[' +
            '["Copado Org Id","{!CopadoOrg.OrgId}"],' +
            '["Copado Org Credential Id","{!CopadoOrg.CredentialId}"],' +
            '["Copado Org Api Key","{!CopadoOrg.ApiKey}"],' +
            '["Source Org Id","{!Source.OrgId}"],' +
            '["Source Credential Id","{!Source.CredentialId}"],' +
            '["Destination Org Id","{!Destination.OrgId}"],' +
            '["Destination Credential Id","{!Destination.CredentialId}"],' +
            '["Deployment Id","{!Deployment.Id}"],' +
            '["Deployment Job Id","{!Deployment.JobId}"],' +
            '["Promotion Id","{!Promotion.Id}"],' +
            '["Resume URL","{!ResumeURL}"]' +
            ']}';

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, dataJson)
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deploymentJob = [
            SELECT Status__c, Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c, 'Job Status should be pending');
        deploymentJob.Status__c = 'In progress';
        update deploymentJob;
        List<AsyncApexJob> ayncFlowExecutors = [SELECT Id FROM AsyncApexJob];
        deploymentJob = [
            SELECT Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        Result__c result = [SELECT Job_Type__c, Status__c FROM Result__c];
        System.assertEquals(result.Id, deploymentJob.Last_Result__c, 'Last_Result__c should correspond to Result Id');
        System.assertEquals('Deployment Step 0', result.Job_Type__c, 'Job Type should correspond to Step Name');
        System.assertEquals('In Progress', result.Status__c, 'Result Status should be In progress');
        System.assert(!ayncFlowExecutors.isEmpty(), 'There should be a job enqueued');
        Test.stopTest();

        deploymentJob = [
            SELECT Status__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Failed', deploymentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deploymentJob.Step__r.Deployment__c];

        String resultBody = resultAttachment.Body.toString();
        String expectedMessage = String.format(Label.ERROR_FLOW_EXECUTION, new List<Object>{ 'Invalid type: TestFlow' });
        System.assert(resultBody.contains(expectedMessage), 'Flow execution should fail');

        result = [SELECT Status__c, Error_Message__c FROM Result__c];
        System.assertEquals('Failed', result.Status__c, 'Result Status should be Failed');
        System.assertEquals(expectedMessage, result.Error_Message__c, 'Result error message should match');
    }

    @IsTest
    private static void testSalesforceFlowStepExecutionJsonParsingError() {
        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, 'testDataJson')
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deploymentJob = [
            SELECT Status__c, Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c, 'Job Status should be pending');
        deploymentJob.Status__c = 'In progress';
        update deploymentJob;
        List<AsyncApexJob> ayncFlowExecutors = [SELECT Id FROM AsyncApexJob];
        deploymentJob = [
            SELECT Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        Result__c result = [SELECT Job_Type__c, Status__c FROM Result__c];
        System.assertEquals(result.Id, deploymentJob.Last_Result__c, 'Last_Result__c should correspond to Result Id');
        System.assertEquals('Deployment Step 0', result.Job_Type__c, 'Job Type should correspond to Step Name');
        System.assertEquals('In Progress', result.Status__c, 'Result Status should be In progress');
        System.assert(!ayncFlowExecutors.isEmpty(), 'There should be a job enqueued');
        Test.stopTest();

        deploymentJob = [
            SELECT Status__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Failed', deploymentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deploymentJob.Step__r.Deployment__c];

        String resultBody = resultAttachment.Body.toString();
        String expectedMessage = String.format(Label.ERROR_PARSING_FLOW_INFORMATION, new List<Object>{ '' });
        System.assert(resultBody.contains(expectedMessage), 'Flow information parsing should fail');

        result = [SELECT Status__c, Error_Message__c FROM Result__c];
        System.assertEquals('Failed', result.Status__c, 'Result Status should be Failed');
        System.assert(result.Error_Message__c.contains(expectedMessage), 'Result error message should match');
    }

    /**
     * Test method to check the Order field in the inserted steps is autopopulated according the existing steps for that deployment.
     * TODO: Refactor StepTriggerHelper and create TestStepTriggerHelper.cls, move this method there.
     */
    @IsTest
    private static voId testSetStepOrderOnInsert() {
        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();
        insert deployment;

        Test.startTest();
        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 7, 'Pending', 'MetaData');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 6, 'Pending', 'MetaData');
        insert new List<Step__c>{ step, step2 };
        Step__c step3 = testMethodUtilities.create('Step 3', 'attId', 'JSONString', deployment.Id, null, 'Pending', 'MetaData');
        insert step3;
        Test.stopTest();

        System.assertEquals(1, [SELECT Order__c FROM step__c WHERE Id = :step.Id].Order__c, 'Order is not sequential.');
        System.assertEquals(2, [SELECT Order__c FROM step__c WHERE Id = :step2.Id].Order__c, 'Order is not sequential.');
        System.assertEquals(3, [SELECT Order__c FROM step__c WHERE Id = :step3.Id].Order__c, 'Order is not sequential.');
    }

    @IsTest
    private static voId testUpdateStatus() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert deployment;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        insert step;

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c, Destination_Org__c, step__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        DeployJobHelper.updateStatus(deploymentJob, deployment.Id);
        System.assertEquals('Pending', deploymentJob.Status__c, 'Deployment job status should updated to Pending');
    }
}