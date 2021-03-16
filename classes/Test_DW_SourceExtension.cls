@IsTest
public with sharing class Test_DW_SourceExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_Source page and click on "Back" button, no deployment record created yet
     */
    @IsTest
    static void sourceBack() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            PageReference returnedPage = controller.goToDeploymentTab();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page and click on "Back" button, no deployment record created yet
     */
    @IsTest
    static void sourceBackForDataDeployment() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('org', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.goToDeploymentTab();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Salesforce Org" and click on "Save & Close" button
     */
    @IsTest
    static void sourceOrgSaveAndCloseError() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            Test.startTest();

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.deployment.Name = 'test deployment';
            controller.selectedSourceType = 'org';
            controller.populateNecessaryData();
            System.assertEquals(3, controller.sourceList.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 2') {
                    sw.isSelected = true;
                    break;
                }
            }

            controller.configureSource();
            System.assertEquals(orgList[2].Id, controller.deployment.From_Org__c);
            System.assertEquals(0, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Salesforce Org" and click on "Save & Close" button
     */
    @IsTest
    static void sourceOrgSaveAndCloseNotValidOrg() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.deployment.Name = 'test deployment';
            controller.selectedSourceType = 'org';
            controller.populateNecessaryData();
            System.assertEquals(3, controller.sourceList.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 2') {
                    sw.isSelected = true;
                    break;
                }
            }

            controller.configureSource();
            System.assertEquals(orgList[2].Id, controller.deployment.From_Org__c);
            System.assertEquals(0, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', 'success', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals(severity, 'error');
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(obj, Label.WRONG_CREDENTIALS);
                }
            }
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Salesforce Org" and click on "Save & Close" button
     */
    @IsTest
    static void sourceOrgSaveAndClose() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.deployment.Name = 'test deployment';
            controller.selectedSourceType = 'org';
            controller.populateNecessaryData();
            System.assertEquals(3, controller.sourceList.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 2') {
                    sw.isSelected = true;
                    break;
                }
            }

            controller.configureSource();
            System.assertEquals(orgList[2].Id, controller.deployment.From_Org__c);
            System.assertEquals(0, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());

            PageReference returnedPage = controller.goToDeploymentTab();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Salesforce Org" and click on "Confirm Source" button
     */
    @IsTest
    static void sourceOrgConfirm() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.selectedSourceType = 'org';
            controller.populateNecessaryData();
            System.assertEquals(3, controller.sourceList.size());

            pReference.getParameters().put('buttonAction', 'nextStep');
            controller.deployment.Name = null;
            controller.configureSource();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals(severity, 'warning');
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(obj, Label.Give_Your_Deployment_a_Name);
                }
            }
            controller.deployment.Name = 'test deployment';
            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 2') {
                    sw.isSelected = true;
                    break;
                }
            }
            controller.configureSource();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals(orgList[2].Id, controller.deployment.From_Org__c);
            System.assertEquals(0, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());

            PageReference returnedPage = controller.goToNextStep();
            PageReference expectedPage = Page.DW_Target;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Git" and click on "Save & Close" button
     */
    @IsTest
    static void sourceGitSaveAndClose() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Git Repository creation
            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Datetime yesterday = Datetime.now().addDays(-1);
            Datetime lastTwoYear = Datetime.now().addYears(-2);
            Datetime tomorrow = Datetime.now().addDays(1);

            // Git Commit creation
            Git_Commit__c gitCommit1 = TestDataFactory.createGitCommit('today', Datetime.now().date(), repo.Id);
            Git_Commit__c gitCommit2 = TestDataFactory.createGitCommit('yesterday', yesterday.date(), repo.Id);
            Git_Commit__c gitCommit3 = TestDataFactory.createGitCommit('tomorrow', tomorrow.date(), repo.Id);
            insert new List<Git_Commit__c>{ gitCommit1, gitCommit2, gitCommit3 };

            // Git Backup creation
            Git_Backup__c snap = TestDataFactory.createGitBackup('test snapshot', orgList[2].Id, repo.Id);
            insert snap;

            // Git Org Commit creation
            Git_Org_Commit__c gitOrgCommit1 = TestDataFactory.createGitOrgCommit('yesterday', yesterday.date(), snap.Id, orgList[2].Id, 'Complete');
            Git_Org_Commit__c gitOrgCommit2 = TestDataFactory.createGitOrgCommit(
                'last 2 year',
                lastTwoYear.date(),
                snap.Id,
                orgList[2].Id,
                'Complete'
            );
            insert new List<Git_Org_Commit__c>{ gitOrgCommit1, gitOrgCommit2 };

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(Label.New_Deployment, generalHeader);

            controller.deployment.Name = 'test deployment';
            controller.selectedSourceType = 'git';
            controller.populateNecessaryData();
            System.assertEquals(5, controller.sourceList.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.commitId == 'last 2 year') {
                    sw.isSelected = true;
                    break;
                }
            }

            controller.configureSource();
            System.assertEquals(1, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());

            PageReference returnedPage = controller.goToDeploymentTab();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            List<Step__c> stepList = [
                SELECT Id
                FROM Step__c
                WHERE Type__c = 'Git MetaData' AND Name = 'Step 1' AND Status__c = 'Not Started' AND Order__c = 1
            ];
            System.assertEquals(stepList.size(), 1);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Git" and click on "Confirm Git Commit" button
     */
    @IsTest
    static void sourceGitConfirm() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Git Repository creation
            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Datetime yesterday = Datetime.now().addDays(-1);
            Datetime lastTwoYear = Datetime.now().addYears(-2);
            Datetime tomorrow = Datetime.now().addDays(1);

            // Git Commit creation
            Git_Commit__c gitCommit1 = TestDataFactory.createGitCommit('today', Datetime.now().date(), repo.Id);
            Git_Commit__c gitCommit2 = TestDataFactory.createGitCommit('yesterday', yesterday.date(), repo.Id);
            Git_Commit__c gitCommit3 = TestDataFactory.createGitCommit('tomorrow', tomorrow.date(), repo.Id);

            insert new List<Git_Commit__c>{ gitCommit1, gitCommit2, gitCommit3 };

            // Git Backup creation
            Git_Backup__c snap = TestDataFactory.createGitBackup('test snapshot', orgList[2].Id, repo.Id);
            insert snap;

            // Git Org Commit creation
            Git_Org_Commit__c gitOrgCommit1 = TestDataFactory.createGitOrgCommit('yesterday', yesterday.date(), snap.Id, orgList[2].Id, 'Complete');
            Git_Org_Commit__c gitOrgCommit2 = TestDataFactory.createGitOrgCommit(
                'last 2 year',
                lastTwoYear.date(),
                snap.Id,
                orgList[2].Id,
                'Complete'
            );
            insert new List<Git_Org_Commit__c>{ gitOrgCommit1, gitOrgCommit2 };

            // Attachment creation
            Attachment attachment = TestDataFactory.createAttachment('MetaData', gitOrgCommit2.Id, 'test');
            insert attachment;

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.deployment.Name = 'test deployment';
            controller.selectedSourceType = 'git';
            controller.populateNecessaryData();
            System.assertEquals(controller.sourceList.size(), 5);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.commitId == 'last 2 year') {
                    sw.isSelected = true;
                    break;
                }
            }

            pReference.getParameters().put('buttonAction', 'nextStep');
            controller.configureSource();
            System.assertEquals(controller.stepList.size(), 1);
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());

            PageReference returnedPage = controller.goToNextStep();
            PageReference expectedPage = Page.DW_Target;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);

            List<Step__c> stepList = [
                SELECT Id
                FROM Step__c
                WHERE Type__c = 'Git MetaData' AND Name = 'Step 1' AND Status__c = 'Not Started' AND Order__c = 1
            ];
            System.assertEquals(stepList.size(), 1);
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Source page, select "Salesforce Org" and click on "Confirm Source" button
     */
    @IsTest
    static void sourceOrgConfirmForDataDeployment() {
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
            insert deployment;

            PageReference pReference = Page.DW_Source;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SourceExtension controller = new DW_SourceExtension(sc);
            System.assertNotEquals(null, controller.deployment);
            System.assertEquals(null, controller.attId);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals('org', controller.selectedSourceType);
            System.assertEquals(2, controller.sourceTypeList.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(0, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            controller.populateNecessaryData();
            System.assertEquals(3, controller.sourceList.size());

            pReference.getParameters().put('buttonAction', 'nextStep');
            controller.deployment.Name = null;
            controller.configureSource();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals(severity, 'warning');
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.Give_Your_Deployment_a_Name, obj);
                }
            }
            controller.deployment.Name = 'test deployment';
            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                if (sw.orgRecord.Name == 'Test Org 2') {
                    sw.isSelected = true;
                    break;
                }
            }
            controller.configureSource();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertEquals(orgList[2].Id, controller.deployment.From_Org__c);
            System.assertEquals(0, controller.stepList.size());
            System.assertNotEquals(null, controller.deployment.Id);

            Test.startTest();
            String res =
                '{"Name":"Copado Ltd","orgId":"' +
                orgList[2].Id +
                '","orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.validateOrg();
            System.assertEquals(0, controller.pageMessagesMap.size());

            PageReference returnedPage = controller.goToNextStep();
            PageReference expectedPage = Page.DW_Target;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);
            Test.stopTest();
        }
    }
}