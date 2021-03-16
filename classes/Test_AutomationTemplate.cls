@IsTest
private with sharing class Test_AutomationTemplate {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void executeAutomationTemplate() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String automationDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Automation_Template')
                .getRecordTypeId();
            Deployment__c automationTemplate = TestDataFactory.createDeployment('Test Dev 1', automationDeploymentRecordTypeId, orgList[2].Id);

            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c advancedDeployment = TestDataFactory.createDeployment('Test Dev 1', advancedDeploymentRecordTypeId, orgList[2].Id);
            insert new List<Deployment__c>{ automationTemplate, advancedDeployment };

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(advancedDeployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c automationTemplateStep = TestDataFactory.createStep(automationTemplate.Id, 'Step 1', 'Apex', 'Not Started', 1, null, '');
            Step__c advancedDeploymentStep = TestDataFactory.createStep(advancedDeployment.Id, 'Step 1', 'Automation', 'Not Started', 1, null, '');
            advancedDeploymentStep.dataJson__c = '{"automationId":"' + automationTemplate.Id + '"}';
            insert new List<Step__c>{ automationTemplateStep, advancedDeploymentStep };

            // Attachment creation
            String automationStepAttachmentBody = 'System.debug("test automation ");';
            Attachment automationStepAttachment = TestDataFactory.createAttachment('Apex', automationTemplateStep.Id, automationStepAttachmentBody);

            String advancedStepAttachmentBody = '"{\"automationId\":\"' + automationTemplate.Id + '\"}"';
            Attachment advancedStepAttachment = TestDataFactory.createAttachment('Apex', advancedDeploymentStep.Id, advancedStepAttachmentBody);
            insert new List<Attachment>{ automationStepAttachment, advancedStepAttachment };

            PageReference pageReference = Page.DeploymentWizard;
            pageReference.getParameters().put('id', advancedDeployment.Id);
            Test.setCurrentPage(pageReference);

            DeploymentWizardExtension wizardExtension = new DeploymentWizardExtension(new ApexPages.StandardController(advancedDeployment));

            wizardExtension.deployment.Date__c = System.today();
            wizardExtension.deployment.Schedule__c = 'Deploy now';
            wizardExtension.step_setupSchedule = true;

            // AUTO RECHARGE NOT ENABLED
            String mockResponse = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":false,"minCredits":1000,"credits":1348,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(mockResponse, null));
            wizardExtension.creditCheckAndValidations();
            wizardExtension.confirmAll();
            wizardExtension.confirm();

            List<Deployment_Job__c> advancedStepJobs = [SELECT Id, Status__c FROM Deployment_Job__c WHERE Step__c = :advancedDeploymentStep.Id];
            advancedStepJobs[0].Status__c = 'In Progress';

            update advancedStepJobs;
            Test.stopTest();

            String newDeploymentName = Label.Execution_of + ' ' + automationTemplate.Name;
            List<Deployment__c> convertedDeployments = [SELECT Id FROM Deployment__c WHERE Name = :newDeploymentName];
            System.assertEquals(1, convertedDeployments.size(), 'automation template is converted into advanced deployment');

            List<Deployment_Job__c> convertedStepJobs = [
                SELECT Id, Status__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :convertedDeployments[0].Id
            ];
            convertedStepJobs[0].Status__c = 'Success';

            update convertedStepJobs;

            Integer completedDeployments = [
                SELECT COUNT()
                FROM Deployment__c
                WHERE RecordTypeId = :advancedDeploymentRecordTypeId AND Status__c = 'Completed Successfully'
            ];
            System.assertEquals(2, completedDeployments, 'there are 2 deployment finished successfully');
        }
    }
}