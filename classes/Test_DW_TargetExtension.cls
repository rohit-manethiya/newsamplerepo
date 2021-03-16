@IsTest
public with sharing class Test_DW_TargetExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_Target page and click on "Back" button
     */
    @IsTest
    static void targetBack() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_Source;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Target page and click on "Back" button
     */
    @IsTest
    static void targetBackForDataDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_Source;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "Save & Close" button
     */
    @IsTest
    static void targetOrgSaveAndClose() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();

            controller.upsertDestinationOrg();
            System.assertNotEquals(orgList[1].Id, controller.destinationOrg.Id);

            PageReference returnedPage = controller.saveAndCloseStep();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "Save & Close" button
     */
    @IsTest
    static void targetOrgSaveAndCloseForDataDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();

            controller.upsertDestinationOrg();
            System.assertNotEquals(orgList[1].Id, controller.destinationOrg.Id);

            PageReference returnedPage = controller.saveAndCloseStep();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "Save & Close" button
     */
    @IsTest
    static void targetOrgSaveAndCloseError() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(controller.pageMessagesMap.size(), 0);
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "Save & Close" button
     */
    @IsTest
    static void targetOrgSaveAndCloseNotValidOrg() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', 'success', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(controller.pageMessagesMap.size(), 0);
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.DESTINATION_ORG_NOT_VALIDATED, obj);
                }
            }
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "ConfirmTarget" button
     */
    @IsTest
    static void targetOrgConfirmTargetNoDestinationOrg() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(null, controller.destinationOrg.To_Org__c);
            Test.stopTest();

            controller.upsertDestinationOrg();
            System.assertEquals(null, controller.destinationOrg.Id);

            PageReference returnedPage = controller.confirmAndGoNextStep();
            System.assertEquals(null, returnedPage);
            System.assertEquals(controller.pageMessagesMap.size(), 1);
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('warning', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.WorkManager_Alert_NoRecord, obj);
                }
            }
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "ConfirmTarget" button
     */
    @IsTest
    static void targetOrgConfirmTarget() {
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
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();

            controller.upsertDestinationOrg();
            System.assertNotEquals(null, controller.destinationOrg.Id);

            PageReference returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_SelectChanges;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);
        }
    }

    /**
     * Open the DW_Target page, select "Destination Org" and click on "ConfirmTarget" button
     */
    @IsTest
    static void targetOrgConfirmTargetForDataDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Target';
            insert deployment;

            PageReference pReference = Page.DW_Target;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_TargetExtension controller = new DW_TargetExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(1, controller.currentStepValue);
            System.assertEquals(new Destination_Org__c(), controller.destinationOrg);
            System.assertEquals(3, controller.sourceList.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 1') {
                    sw.isSelected = true;
                    break;
                }
            }

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.checkIfSelectedOrgIsValid();
            System.assertEquals(deployment.Id, controller.destinationOrg.Deployment__c);
            System.assertEquals(orgList[1].Id, controller.destinationOrg.To_Org__c);
            Test.stopTest();

            controller.upsertDestinationOrg();
            System.assertNotEquals(null, controller.destinationOrg.Id);

            PageReference returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_SelectDataTemplate;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);
        }
    }
}