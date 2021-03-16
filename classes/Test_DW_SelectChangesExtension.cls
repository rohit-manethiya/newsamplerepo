@IsTest
public with sharing class Test_DW_SelectChangesExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_SelectChanges page and click on "Back" button
     */
    @IsTest
    static void selectChangesBack() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectChanges';
            insert deployment;

            PageReference pReference = Page.DW_SelectChanges;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectChangesExtension controller = new DW_SelectChangesExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            controller.getDeploymentStepRecord();
            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_Target;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectChanges page and click on "Save & Close" button
     */
    @IsTest
    static void selectChangeSaveAndClose() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectChanges';
            insert deployment;

            PageReference pReference = Page.DW_SelectChanges;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectChangesExtension controller = new DW_SelectChangesExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String stepId = DW_SelectChangesExtension.insertStep(deployment.Id);
            System.assertNotEquals(null, stepId);

            PageReference returnedPage = controller.saveAndCloseStep();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectChanges page and click on "Refresh Metadata" link
     */
    @IsTest
    static void selectChangeRefreshMetadataFailure() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectChanges';
            insert deployment;

            PageReference pReference = Page.DW_SelectChanges;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectChangesExtension controller = new DW_SelectChangesExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            pReference.getParameters().put('operation', 'refreshCache');
            controller.initPoller();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
            System.assertEquals(controller.componentMessagesMap.size(), 1);
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            controller.pollerHandler();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
            System.assertEquals(1, controller.componentMessagesMap.size());
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            // Copado Notification creation
            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'MetadataRetriever',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.deployment.From_Org__c
            );
            insert cn;

            controller.pollerHandler();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
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

            controller.pollerHandler();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
            System.assertEquals(true, controller.showRefreshCachePromtButton);
            System.assertEquals(2, controller.componentMessagesMap.size());

            controller.clearMessagesMap();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals(false, controller.showRefreshCachePromtButton);
            System.assertEquals('', controller.copadoNotificationId);
            System.assertEquals(new List<Copado_Notification__c>(), controller.copadoNotificationList);
            System.assertEquals(new Map<String, Set<Object>>(), controller.componentMessagesMap);
        }
    }

    /**
     * Open the DW_SelectChanges page and click on "Refresh Metadata" link
     */
    @IsTest
    static void selectChangeRefreshMetadataSuccess() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectChanges';
            insert deployment;

            PageReference pReference = Page.DW_SelectChanges;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectChangesExtension controller = new DW_SelectChangesExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            pReference.getParameters().put('operation', 'refreshCache');
            controller.initPoller();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
            System.assertEquals(controller.componentMessagesMap.size(), 1);
            for (String severity : controller.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : controller.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }
            Integer messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            controller.pollerHandler();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
            System.assertEquals(1, controller.componentMessagesMap.size());
            messageSize = controller.getComponentMessageSize();
            System.assertEquals(1, messageSize);

            // Copado Notification creation
            Copado_Notification__c cn = TestDataFactory.createCopadoNotification(
                'MetadataRetriever',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                controller.deployment.From_Org__c
            );
            insert cn;

            controller.pollerHandler();
            System.assertEquals(false, controller.isRefreshCacheSucceeded);
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

            controller.pollerHandler();
            System.assertEquals(true, controller.isRefreshCacheSucceeded);

            controller.clearMessagesMap();
            System.assertEquals(false, controller.startActionPoller);
            System.assertEquals(false, controller.showRefreshCachePromtButton);
            System.assertEquals('', controller.copadoNotificationId);
            System.assertEquals(new List<Copado_Notification__c>(), controller.copadoNotificationList);
            System.assertEquals(new Map<String, Set<Object>>(), controller.componentMessagesMap);
        }
    }

    /**
     * Open the DW_SelectChanges page and click on "ConfirmMetadata" button
     */
    @IsTest
    static void selectChangeConfirmMetadata() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectChanges';
            insert deployment;

            PageReference pReference = Page.DW_SelectChanges;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectChangesExtension controller = new DW_SelectChangesExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String stepId = DW_SelectChangesExtension.insertStep(deployment.Id);
            System.assertNotEquals(null, stepId);

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', stepId, attBody);
            insert att;

            PageReference returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_Overview;
            expectedPage.getParameters().put('id', controller.deployment.Id);

            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }
}