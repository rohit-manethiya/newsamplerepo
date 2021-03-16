@IsTest
public with sharing class Test_DW_DeploymentExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationSuccessBackToSetup() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Successful', controller.currentStatusOfAction);

            PageReference returnedPage = controller.goToOverviewStep();
            PageReference expectedPage = Page.DW_Overview;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationSuccessStartDeploymentFailure() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Successful', controller.currentStatusOfAction);

            controller.updateStepForDeployment();
            Test.startTest();
            controller.restartDeployment();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('Methods defined as TestMethod do not support Web service callouts', obj);
                }
            }
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationSuccessStartDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Successful', controller.currentStatusOfAction);

            controller.updateStepForDeployment();
            Test.startTest();
            String res = '{"customerOrg":{"Name":"Copado","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            PageReference returnedPage = controller.restartDeployment();
            PageReference expectedPage = Page.DW_Deployment;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            expectedPage.getParameters().put('deploymentActionType', controller.deploymentActionName);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationFailureReviewSourceAndTarget() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = false;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Error', controller.currentStatusOfAction);

            PageReference returnedPage = controller.goToSourceStep();
            PageReference expectedPage = Page.DW_Source;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationFailureReviewMetadata() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = false;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Error', controller.currentStatusOfAction);

            PageReference returnedPage = controller.goToSelectChangesStep();
            PageReference expectedPage = Page.DW_SelectChanges;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, validation process success
     */
    @IsTest
    static void validationFailureRestartDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'validation');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = false;
            cn.status__c = 'done';
            update cn;

            controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Error', controller.currentStatusOfAction);

            Test.startTest();
            String res = '{"customerOrg":{"Name":"Copado","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            PageReference returnedPage = controller.restartDeployment();
            PageReference expectedPage = Page.DW_Deployment;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            expectedPage.getParameters().put('deploymentActionType', controller.deploymentActionName);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, deployment process success
     */
    @IsTest
    static void deploymentSuccess() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Completed with Errors', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Error', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;

            PageReference returnedPage = controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Successful', controller.currentStatusOfAction);

            PageReference expectedPage = Page.DW_Summary;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            expectedPage.getParameters().put('deploymentActionType', controller.deploymentActionName);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, deployment process success
     */
    @IsTest
    static void deploymentSuccessForGitMetadata() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Git Repository creation
            Git_Repository__c repository = TestDataFactory.createGitRepository();
            insert repository;

            // Git Commit creation
            Git_Commit__c gcRecord = TestDataFactory.createGitCommit('1234567890abcd', System.now().date(), repository.Id);
            insert gcRecord;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Completed Successfully', 1, gcRecord.Name, '');
            step.Commit_Id__c = gcRecord.Commit_Id__c;
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;

            PageReference returnedPage = controller.copadoNotificationProcesses();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('Successful', controller.currentStatusOfAction);

            PageReference expectedPage = Page.DW_Summary;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('deploymentActionType', controller.deploymentActionName);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Deployment page, deployment process success
     */
    @IsTest
    static void deploymentCancelDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            // Attachment creation
            String jobAttachmentBody = '{"duration":2,"test_total":0,"comp_total":3,"comp_error":0,"start":1558538908000,"test_error":0,"end":1558538910000,"async_id":"0Af0O00000OszKfSAJ","comp_deployed":3,"test_completed":0,"status":"Pending"}';
            Attachment jobAttachment = TestDataFactory.createAttachment(
                'DEPLOYMENT_STATUS_COPADO',
                controller.getDeploymentJobId(),
                jobAttachmentBody
            );
            insert jobAttachment;

            controller.copadoNotificationProcesses();
            System.assertEquals(true, controller.enableCancelDeploymentButton);

            Test.startTest();
            String res = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":"true","credits":10,"id":995}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.cancelDeployment();
            System.assertEquals(0, controller.pageMessagesMap.size());
            Test.stopTest();

            PageReference returnedPage = controller.goToOverviewPage();
            PageReference expectedPage = Page.DW_Overview;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);
        }
    }

    /**
     * Open the DW_Deployment page, deployment process success
     */
    @IsTest
    static void deploymentCancelDeploymentFailure() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Deployment';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Deployment;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_DeploymentExtension controller = new DW_DeploymentExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals('In Progress', controller.currentStatusOfAction);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.initPoller();
            System.assertEquals(true, controller.startActionPoller);
            System.assertEquals(false, controller.enableCancelDeploymentButton);
            System.assertEquals(1, controller.componentMessagesMap.size());
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            controller.copadoNotificationProcesses();
            System.assertEquals(1, controller.componentMessagesMap.size());
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.getDeploymentJobId()
            );
            insert cn;

            controller.copadoNotificationProcesses();
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                System.assertEquals(2, controller.componentMessagesMap.get(severity).size());
            }
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(2, messageSize);

            // Attachment creation
            String jobAttachmentBody = '{"duration":2,"test_total":0,"comp_total":3,"comp_error":0,"start":1558538908000,"test_error":0,"end":1558538910000,"async_id":"0Af0O00000OszKfSAJ","comp_deployed":3,"test_completed":0,"status":"Pending"}';
            Attachment jobAttachment = TestDataFactory.createAttachment(
                'DEPLOYMENT_STATUS_COPADO',
                controller.getDeploymentJobId(),
                jobAttachmentBody
            );
            insert jobAttachment;

            controller.copadoNotificationProcesses();
            System.assertEquals(true, controller.enableCancelDeploymentButton);

            Test.startTest();
            controller.cancelDeployment();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('Methods defined as TestMethod do not support Web service callouts', obj);
                }
            }
            Test.stopTest();
        }
    }
}