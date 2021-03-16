@IsTest
private with sharing class TestDeploymentWizardUseCases {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    private static final String METADATA = 'metadata';
    private static final String METADATA_NAME = 'MetaData';
    private static final String DATA = 'data';
    private static final String ORG = 'org';
    private static final String DEV1_0 = 'dev1 0';
    private static final String STAGING_0 = 'staging 0';
    private static final String BUTTON_ACTION = 'buttonAction';
    private static final String NEXT_STEP = 'nextStep';
    private static final String ID = 'id';
    private static final String APEX = '/apex/';
    private static final String DEPLOYMENT = 'deployment';
    private static final String METADATA_PRESELECTION_ID = 'MetadataPreselectionId';
    private static final String DEPLOYMENT_ACTION_TYPE = 'deploymentActionType';
    private static final String EMPTY_STRING = '';
    private static final String DEPLOYMENT_NOT_CREATED = 'Deployment is not created';
    private static final String STEPS_LOADED = 'Steps loaded and at this point should be empty';
    private static final String ATTACHMENT_CREATED = 'Attachment created and it shouldn\'t be';
    private static final String ERRORS_FOUND = 'Errors found at this point';

    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095cEEAQ_0050X000007h8hTQAQ_6')
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095CBEAY_0050X000007h8hTQAQ_3')
                .setDataSize(Org__c.SObjectType, 1)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CopadoDeploymentWizardTestDefaults.GitCommitDefaults.class)
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        Git_Commit__c.SObjectType => new Set<Schema.SObjectField>{ Git_Commit__c.Commit_Id__c }
                    }
                )
                .setSObjectRelation(
                    Git_Commit__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Git_Commit__c.Git_Repository__c => 1 }
                )
                .setDataSize(Git_Commit__c.SObjectType, 3)
                .generateDefaults()
                .executeDML();

            Git_Repository__c createdRepo = (Git_Repository__c) orgCredentialDefaults.getTestData(Git_Repository__c.SObjectType)[0];

            Org__c dev1Org = new Org__c();
            Org__c stagingOrg = new Org__c();
            List<Org__c> createdOrgs = (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType);
            List<Org__c> test = [SELECT Id, Name, Validated_Date__c, Validated_Status__c FROM Org__c WHERE Id = :createdOrgs[0].Id];

            for (Org__c org : createdOrgs) {
                switch on org.Name {
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                }
            }

            ITestDefaults gitSnapshot = new CopadoDeploymentWizardTestDefaults.GitBackupDefaults()
                .setFieldDefaults()
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Backup__c.SObjectType, Git_Backup__c.Git_Repository__c, createdRepo.Id)
                .includeDefaults(CopadoDeploymentWizardTestDefaults.GitOrgCommitDefaults.class)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Org__c, stagingOrg.Id)
                .setFieldValue(Git_Org_Commit__c.SObjectType, Git_Org_Commit__c.Status__c, 'Complete')
                .setIncrementalFields(
                    new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
                        Git_Org_Commit__c.SObjectType => new Set<Schema.SObjectField>{ Git_Org_Commit__c.Commit_Id__c }
                    }
                )
                .setSObjectRelation(
                    Git_Org_Commit__c.SObjectType,
                    Git_Backup__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Git_Org_Commit__c.Git_Backup__c => 1 }
                )
                .setDataSize(Git_Backup__c.SObjectType, 1)
                .setDataSize(Git_Org_Commit__c.SObjectType, 3)
                .generateDefaults()
                .executeDML();

            // It creates Environments associated to Orgs. Cleaner that using framework in this case.
            update createdOrgs;

            ITestDefaults dataTemplate = new CopadoDeploymentWizardTestDefaults.DataTemplateDefaults()
                .setFieldDefaults()
                .setFieldValue(Data_Template__c.SObjectType, Data_Template__c.Template_Source_Org__c, dev1Org.Id)
                .setDataSize(Data_Template__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    /**
     * Test Deployment wizard. Metadata deployment from Org to Org.
     */
    @IsTest
    static void testMetadataDeploymentOrgSource() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            // Click on New Deployment
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deploymentRecord = new Deployment__c();
            deploymentRecord.Name = 'Metadata Deployment';
            deploymentRecord.RecordTypeId = metadataDeploymentRecordTypeId;
            insert deploymentRecord;

            PageReference sourcePage = Page.DW_Source;
            sourcePage.getParameters().put('id', deploymentRecord.Id);
            Test.setCurrentPage(sourcePage);

            // Select Source page
            ApexPages.StandardController deploymentSc = new ApexPages.StandardController(deploymentRecord);
            DW_SourceExtension sourceExtensionController = new DW_SourceExtension(deploymentSc);
            System.assertNotEquals(null, sourceExtensionController.deployment, 'Deployment is not created');
            System.assertEquals(null, sourceExtensionController.attId, ATTACHMENT_CREATED);
            System.assertEquals(
                metadataDeploymentRecordTypeId,
                sourceExtensionController.deployment.RecordTypeId,
                'Current deployment record type is not "Metadata"'
            );
            System.assertEquals(6, sourceExtensionController.pagesList.size(), 'Pages related to this option is not 6');
            System.assertEquals(6, sourceExtensionController.stepsList.size(), 'Steps related to this option is not 6');
            System.assertEquals(0, sourceExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(EMPTY_STRING, sourceExtensionController.selectedSourceType, 'Source type assigned and it shouldn\'t at this point');
            System.assertNotEquals(null, sourceExtensionController.deploymentInterface, 'No interface assigned');
            System.assertEquals(0, sourceExtensionController.currentStepValue, 'Current step value is not 0');

            Set<String> assertSourceTypeLabels = new Set<String>{ 'Salesforce Org', 'Git' };
            Set<String> assertSourceTypes = new Set<String>{ ORG, 'git' };
            Set<String> sourceTypeLabels = new Set<String>();
            Set<String> sourceTypes = new Set<String>();
            System.assertEquals(2, sourceExtensionController.sourceTypeList.size(), 'Available deployment sources is not 2');
            for (DW_SourceExtension.SourceTypesWrapper sourceType : sourceExtensionController.sourceTypeList) {
                sourceTypeLabels.add(sourceType.sourceTypeLabel);
                sourceTypes.add(sourceType.sourceType);
            }
            System.assert(assertSourceTypeLabels.equals(sourceTypeLabels), 'Source labels list is not correct');
            System.assert(assertSourceTypes.equals(sourceTypes), 'Source types list is not correct');

            String sourceHeader = sourceExtensionController.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(Label.New_Deployment, sourceHeader, 'Page header is not New Deployment');

            // Source type is "Org"
            sourceExtensionController.deployment.Name = 'My new Metadata deployment';
            sourceExtensionController.selectedSourceType = ORG;
            sourceExtensionController.populateNecessaryData();
            System.assertEquals(2, sourceExtensionController.sourceList.size(), 'Number of orgs created is not 2');
            String assertFromOrgId;
            // Select org as Source
            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : sourceExtensionController.sourceList) {
                if (deploymentSourceWrapper.orgRecord.Name == DEV1_0) {
                    deploymentSourceWrapper.isSelected = true;
                    assertFromOrgId = deploymentSourceWrapper.orgRecord.Id;
                    break;
                }
            }

            // Click on "Confirm source"
            sourcePage.getParameters().put(BUTTON_ACTION, NEXT_STEP);
            sourceExtensionController.configureSource();
            System.assertEquals(0, sourceExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(0, sourceExtensionController.stepList.size(), STEPS_LOADED);
            System.assertNotEquals(null, sourceExtensionController.deployment.Id, 'Deployment is not created');

            PageReference targetPage = sourceExtensionController.goToNextStep();
            Test.setCurrentPage(targetPage);

            PageReference assertTargetPage = Page.DW_Target;
            assertTargetPage.getParameters().put(ID, sourceExtensionController.deployment.Id);
            System.assertEquals(
                assertTargetPage.getUrl().toLowerCase().subStringAfter(APEX),
                targetPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Target.page"'
            );

            Test.startTest(); // Test Starts here to avoid 101 too many soqls

            // Select Target page
            DW_TargetExtension targetExtensionController = new DW_TargetExtension(deploymentSc);
            System.assertNotEquals(null, targetExtensionController.deployment, DEPLOYMENT_NOT_CREATED);
            System.assertEquals(null, targetExtensionController.attId, ATTACHMENT_CREATED);
            System.assertEquals(6, targetExtensionController.pagesList.size(), 'Pages loaded for this type is not 6');
            System.assertEquals(6, targetExtensionController.stepsList.size(), 'Steps loaded for this type is not 6');
            System.assertEquals(0, targetExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertNotEquals(null, targetExtensionController.deploymentInterface, 'deploymentInterface is not assigned');
            System.assertEquals(1, targetExtensionController.currentStepValue, 'Current step value is not 1');
            System.assertEquals(
                new Destination_Org__c(),
                targetExtensionController.destinationOrg,
                'Destination org is selected and it shouldn\'t a this point'
            );
            System.assertEquals(2, targetExtensionController.sourceList.size(), 'Number of orgs created is different from 2');

            targetExtensionController.deployment.Deployment_Last_Step__c = sourceExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;
            String targetHeader = targetExtensionController.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(Label.New_Deployment, targetHeader, 'Page header is not New Deployment');

            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : targetExtensionController.sourceList) {
                if (deploymentSourceWrapper.orgRecord.Name == STAGING_0) {
                    deploymentSourceWrapper.isSelected = true;
                    break;
                }
            }

            targetExtensionController.checkIfSelectedOrgIsValid();
            targetExtensionController.upsertDestinationOrg();
            System.assertNotEquals(null, targetExtensionController.destinationOrg.Id, 'Destination Org is not assigned');

            PageReference selectChangesPage = targetExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(selectChangesPage);

            PageReference assertSelectChangesPage = Page.DW_SelectChanges;
            assertSelectChangesPage.getParameters().put(ID, targetExtensionController.deployment.Id);
            System.assertEquals(
                assertSelectChangesPage.getUrl().toLowerCase().subStringAfter(APEX),
                selectChangesPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_SelectChanges.page"'
            );

            // Changes selection page
            DW_SelectChangesExtension selectChangesController = new DW_SelectChangesExtension(deploymentSc);
            System.assertEquals(0, selectChangesController.pageMessagesMap.size(), ERRORS_FOUND);

            selectChangesController.deployment.Deployment_Last_Step__c = targetExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            String stepId = DW_SelectChangesExtension.insertStep(selectChangesController.deployment.Id);
            System.assertNotEquals(null, stepId);
            Step__c assertStep = [SELECT Id, Name, Type__c, Status__c, Order__c, Deployment__c FROM Step__c WHERE Id = :stepId LIMIT 1];
            System.assertEquals('Step 1', assertStep.Name, 'Check new step created - Name is not "Step 1" ');
            System.assertEquals(METADATA_NAME, assertStep.Type__c, 'Check new step created - Type is not "MetaData" ');
            System.assertEquals('Not started', assertStep.Status__c, 'Check new step created - Status is not "Not Started" ');
            System.assertEquals(1, assertStep.Order__c, 'Check new step created - Order is not 1');
            System.assertEquals(
                assertStep.Deployment__c,
                selectChangesController.deployment.Id,
                'Check new step created - Deployment is not Deployment created'
            );

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Developer 1","cd":"2017-11-13","cb":"Developer 1","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Developer 1","cd":"2017-11-13","cb":"Developer 1","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Developer 1","cd":"2017-11-13","cb":"Developer 1","r":false,"t":"ApexTrigger"}]';
            Attachment metadataSelectionAttachment = TestDataFactory.createAttachment(METADATA_NAME, stepId, attBody);
            insert metadataSelectionAttachment;

            PageReference overviewPage = selectChangesController.confirmAndGoNextStep();
            Test.setCurrentPage(overviewPage);

            PageReference assertOverviewPage = Page.DW_Overview;
            assertOverviewPage.getParameters().put(ID, selectChangesController.deployment.Id);
            assertOverviewPage.getParameters().put(METADATA_PRESELECTION_ID, metadataSelectionAttachment.Id);
            System.assertEquals(
                assertOverviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                overviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Overview.page"'
            );

            // Overview page
            DW_OverviewExtension overviewExtensionController = new DW_OverviewExtension(deploymentSc);
            Destination_Org__c destinationOrg = overviewExtensionController.getDestinationOrg();
            System.assertEquals(0, overviewExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(assertFromOrgId, overviewExtensionController.deployment.From_Org__c, 'Source org is not correct');
            System.assertEquals(STAGING_0, destinationOrg.To_Org__r.Environment__r.Name, 'Destination org is not correct');
            overviewExtensionController.deployment.Deployment_Last_Step__c = selectChangesController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // Those methods are skipped. They check for Customer credits. As it is in a callout, can be skipped.
            //overviewPage.getParameters().put('actionName', DEPLOYMENT);
            //overviewExtensionController.confirmDeployment();
            overviewExtensionController.deploymentActionName = DEPLOYMENT; // Manually assign this parameter due to previous method skipped.
            overviewExtensionController.deploymentDMLs();

            // We skip overviewExtensionController.deploymentCallout() => it is only a callout. No point to tes it.
            PageReference deployPage = overviewExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(deployPage);

            PageReference assertDeployPage = Page.DW_Deployment;
            assertDeployPage.getParameters().put(ID, overviewExtensionController.deployment.Id);
            assertDeployPage.getParameters().put(METADATA_PRESELECTION_ID, metadataSelectionAttachment.Id);
            assertDeployPage.getParameters().put(DEPLOYMENT_ACTION_TYPE, DEPLOYMENT);
            System.assertEquals(
                assertDeployPage.getUrl().toLowerCase().subStringAfter(APEX),
                deployPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Deployment.page"'
            );

            // Deploy page
            DW_DeploymentExtension deploymentExtensionController = new DW_DeploymentExtension(deploymentSc);
            System.assertEquals(0, deploymentExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(false, deploymentExtensionController.enableCancelDeploymentButton, 'Cancel Deplyoment button is enabled');
            System.assertEquals(false, deploymentExtensionController.startActionPoller, 'Poller is enabled');
            deploymentExtensionController.deployment.Deployment_Last_Step__c = overviewExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // This part is simulating the page running the Deployment with poller.
            deploymentExtensionController.initPoller();
            System.assertEquals(true, deploymentExtensionController.startActionPoller, 'Poller is not enabled');
            System.assertEquals(false, deploymentExtensionController.enableCancelDeploymentButton, 'Cancel Deplyoment button is enabled');
            System.assertEquals(1, deploymentExtensionController.componentMessagesMap.size(), 'No messages found');
            for (String severity : deploymentExtensionController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity, 'Severity is not Info');
                for (Object obj : deploymentExtensionController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj, 'Message is not ' + Label.Initializing);
                }
            }

            deploymentExtensionController.copadoNotificationProcesses();
            Integer messageSize = deploymentExtensionController.getComponentMessageSize();
            System.assertEquals(1, deploymentExtensionController.componentMessagesMap.size(), 'No messages found');
            System.assertEquals(1, messageSize, 'Message size is not 1');

            Copado_Notification__c copadoNotification = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                deploymentExtensionController.getDeploymentJobId()
            );
            insert copadoNotification;

            deploymentExtensionController.copadoNotificationProcesses();
            for (String severity : deploymentExtensionController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity, 'Severity is no Info');
                System.assertEquals(2, deploymentExtensionController.componentMessagesMap.get(severity).size(), 'Number os messages is not 2');
            }
            messageSize = deploymentExtensionController.getComponentMessageSize();
            System.assertEquals(2, messageSize, 'Message size is not 2');

            copadoNotification.isFinished__c = true;
            copadoNotification.isSuccess__c = true;
            copadoNotification.status__c = 'done';
            update copadoNotification;

            PageReference summaryPage = deploymentExtensionController.copadoNotificationProcesses();
            System.assertEquals(false, deploymentExtensionController.startActionPoller, 'startActionPoller is enabled');
            System.assertEquals('Successful', deploymentExtensionController.currentStatusOfAction, 'Current status is no Successful');
            Test.setCurrentPage(summaryPage);

            // Summary Page
            PageReference assertSummaryPage = Page.DW_Summary;
            assertSummaryPage.getParameters().put(ID, deploymentExtensionController.deployment.Id);
            assertSummaryPage.getParameters().put(METADATA_PRESELECTION_ID, metadataSelectionAttachment.Id);
            assertSummaryPage.getParameters().put(DEPLOYMENT_ACTION_TYPE, deploymentExtensionController.deploymentActionName);
            System.assertEquals(
                assertSummaryPage.getUrl().toLowerCase().subStringAfter(APEX),
                summaryPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next page is not "DW_Summary.page"'
            );

            DW_SummaryExtension summaryExtensionController = new DW_SummaryExtension(deploymentSc);

            PageReference deploymentTab = summaryExtensionController.goToDeploymentTab();
            String assertDeploymentTab = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            System.assertEquals(assertDeploymentTab, deploymentTab.getUrl(), 'Url is not Deployment listview');

            Test.stopTest();
        }
    }
    /**
     * Test Deployment wizard. Metadata deployment from Git to Org.
     */
    @IsTest
    static void testMetadataDeploymentGitSource() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            Git_Org_Commit__c selectedCommit = [SELECT Id, Name, Commit_Id__c FROM Git_Org_Commit__c WHERE Commit_Id__c = 'cmm 0' LIMIT 1];
            Attachment gitOrgAttachment = TestDataFactory.createAttachment(METADATA_NAME, selectedCommit.Id, 'test');
            insert gitOrgAttachment;

            // Click on New Deployment
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deploymentRecord = new Deployment__c();
            deploymentRecord.Name = 'Metadata Deployment';
            deploymentRecord.RecordTypeId = metadataDeploymentRecordTypeId;
            insert deploymentRecord;

            PageReference sourcePage = Page.DW_Source;
            sourcePage.getParameters().put('id', deploymentRecord.Id);
            Test.setCurrentPage(sourcePage);

            // Select Source page
            ApexPages.StandardController deploymentSc = new ApexPages.StandardController(deploymentRecord);
            DW_SourceExtension sourceExtensionController = new DW_SourceExtension(deploymentSc);

            // Source type is "Org"
            sourceExtensionController.deployment.Name = 'My new Metadata deployment';
            sourceExtensionController.selectedSourceType = 'git';
            sourceExtensionController.populateNecessaryData();

            System.assertEquals(6, sourceExtensionController.sourceList.size(), 'Number of commits is not correct');
            // Select org as Source
            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : sourceExtensionController.sourceList) {
                if (deploymentSourceWrapper.commitId == selectedCommit.Commit_Id__c) {
                    deploymentSourceWrapper.isSelected = true;
                    break;
                }
            }

            sourcePage.getParameters().put(BUTTON_ACTION, NEXT_STEP);
            sourceExtensionController.configureSource();
            System.assertEquals(1, sourceExtensionController.stepList.size(), 'Number of steps for this point is not 1');
            System.assertNotEquals(null, sourceExtensionController.deployment.Id, 'No deployment created');

            PageReference targetPage = sourceExtensionController.goToNextStep();
            Test.setCurrentPage(targetPage);

            PageReference assertTargetPage = Page.DW_Target;
            assertTargetPage.getParameters().put(ID, sourceExtensionController.deployment.Id);
            System.assertEquals(
                assertTargetPage.getUrl().toLowerCase().subStringAfter(APEX),
                targetPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next page is not "DW_Target" '
            );

            Test.startTest(); // Test Starts here to avoid 101 too many soqls

            // Select Target page
            DW_TargetExtension targetExtensionController = new DW_TargetExtension(deploymentSc);
            System.assertNotEquals(null, targetExtensionController.deployment, DEPLOYMENT_NOT_CREATED);
            System.assertEquals(null, targetExtensionController.attId, ATTACHMENT_CREATED);
            System.assertEquals(6, targetExtensionController.pagesList.size(), 'Pages created for this point is not 6');
            System.assertEquals(6, targetExtensionController.stepsList.size(), 'Steps created for this point is not 6');
            System.assertEquals(0, targetExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertNotEquals(null, targetExtensionController.deploymentInterface, 'No deploymentInterface assigned');
            System.assertEquals(
                new Destination_Org__c(),
                targetExtensionController.destinationOrg,
                'Destination org selected and it shouldn\' at this point'
            );
            System.assertEquals(2, targetExtensionController.sourceList.size(), 'Number of orgs created is different of 2');

            targetExtensionController.deployment.Deployment_Last_Step__c = sourceExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;
            String targetHeader = targetExtensionController.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(Label.New_Deployment, targetHeader, 'Page header is not New Deployment');

            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : targetExtensionController.sourceList) {
                if (deploymentSourceWrapper.orgRecord.Name == STAGING_0) {
                    deploymentSourceWrapper.isSelected = true;
                    break;
                }
            }

            targetExtensionController.checkIfSelectedOrgIsValid();
            targetExtensionController.upsertDestinationOrg();
            System.assertNotEquals(null, targetExtensionController.destinationOrg.Id, 'Destination Org is not assigned');

            PageReference selectChangesPage = targetExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(selectChangesPage);

            PageReference assertSelectChangesPage = Page.DW_SelectChanges;
            assertSelectChangesPage.getParameters().put(ID, targetExtensionController.deployment.Id);
            System.assertEquals(
                assertSelectChangesPage.getUrl().toLowerCase().subStringAfter(APEX),
                selectChangesPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_SelectChanges.page"'
            );

            // Changes selection page
            DW_SelectChangesExtension selectChangesController = new DW_SelectChangesExtension(deploymentSc);
            System.assertEquals(0, selectChangesController.pageMessagesMap.size(), ERRORS_FOUND);
            selectChangesController.deployment.Deployment_Last_Step__c = targetExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;
            Step__c assertStep = [
                SELECT Id, Name, Type__c, Status__c, Order__c, Deployment__c
                FROM Step__c
                WHERE Deployment__c = :selectChangesController.deployment.Id
                LIMIT 1
            ];
            System.assertEquals('Step 1', assertStep.Name, 'Check new step created - Name is not "Step 1" ');
            System.assertEquals('Git MetaData', assertStep.Type__c, 'Check new step created - Type is not "Git Metadata" ');
            System.assertEquals('Not started', assertStep.Status__c, 'Check new step created - Status is not "Not Started" ');
            System.assertEquals(1, assertStep.Order__c, 'Check new step created - Order is not 1');
            System.assertEquals(
                assertStep.Deployment__c,
                selectChangesController.deployment.Id,
                'Check new step created - Deployment is not the created one'
            );

            // At this point we need to create the attachment manually because the function is in Javascript.
            /*Attachment attachmentCreatedInSelection = TestDataFactory.createAttachment(selectedCommit.Commit_Id__c + '.json', assertStep.Id, 'test');
             insert attachmentCreatedInSelection;*/
            Attachment attachmentCreatedInSelection = TestDataFactory.createAttachment(METADATA_NAME, assertStep.Id, 'test');
            insert attachmentCreatedInSelection;

            PageReference overviewPage = selectChangesController.confirmAndGoNextStep();
            Test.setCurrentPage(overviewPage);

            PageReference assertOverviewPage = Page.DW_Overview;
            assertOverviewPage.getParameters().put(ID, selectChangesController.deployment.Id);
            assertOverviewPage.getParameters().put(METADATA_PRESELECTION_ID, attachmentCreatedInSelection.Id);
            System.assertEquals(
                assertOverviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                overviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Overview.page"'
            );

            // Overview page
            DW_OverviewExtension overviewExtensionController = new DW_OverviewExtension(deploymentSc);
            Destination_Org__c destinationOrg = overviewExtensionController.getDestinationOrg();
            System.assertEquals(0, overviewExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            // assert from
            System.assertEquals(STAGING_0, destinationOrg.To_Org__r.Environment__r.Name, 'Destination is name is not ' + STAGING_0);

            overviewExtensionController.deployment.Deployment_Last_Step__c = selectChangesController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // Those methods are skipped. They check for Customer credits. As it is in a callout, can be skipped.
            //overviewPage.getParameters().put('actionName', DEPLOYMENT);
            //overviewExtensionController.confirmDeployment();
            overviewExtensionController.deploymentActionName = DEPLOYMENT; // Manually assign this parameter due to previous method skipped.
            overviewExtensionController.deploymentDMLs();

            // We skip overviewExtensionController.deploymentCallout() => it is only a callout. No point to tes it.
            PageReference deployPage = overviewExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(deployPage);

            PageReference assertDeployPage = Page.DW_Deployment;
            assertDeployPage.getParameters().put(ID, overviewExtensionController.deployment.Id);
            assertDeployPage.getParameters().put(METADATA_PRESELECTION_ID, attachmentCreatedInSelection.Id);
            assertDeployPage.getParameters().put(DEPLOYMENT_ACTION_TYPE, DEPLOYMENT);
            System.assertEquals(
                assertDeployPage.getUrl().toLowerCase().subStringAfter(APEX),
                deployPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Deployment.page"'
            );

            // Deploy page
            DW_DeploymentExtension deploymentExtensionController = new DW_DeploymentExtension(deploymentSc);
            System.assertEquals(0, deploymentExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(attachmentCreatedInSelection.Id, deploymentExtensionController.attId);
            deploymentExtensionController.deployment.Deployment_Last_Step__c = overviewExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // This part is simulating the page running the Deployment with poller.
            deploymentExtensionController.initPoller();
            deploymentExtensionController.copadoNotificationProcesses();
            Integer messageSize = deploymentExtensionController.getComponentMessageSize();

            Copado_Notification__c copadoNotification = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                deploymentExtensionController.getDeploymentJobId()
            );
            insert copadoNotification;

            deploymentExtensionController.copadoNotificationProcesses();
            copadoNotification.isFinished__c = true;
            copadoNotification.isSuccess__c = true;
            copadoNotification.status__c = 'done';
            update copadoNotification;

            PageReference summaryPage = deploymentExtensionController.copadoNotificationProcesses();
            Test.setCurrentPage(summaryPage);

            // Summary Page
            DW_SummaryExtension summaryExtensionController = new DW_SummaryExtension(deploymentSc);

            PageReference deploymentTab = summaryExtensionController.goToDeploymentTab();
            String assertDeploymentTab = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            System.assertEquals(assertDeploymentTab, deploymentTab.getUrl(), 'Is not Deployment Listview page');

            Test.stopTest();
        }
    }
    /**
     * Test Deployment wizard. Data deployment end to end test.
     */
    @IsTest
    static void testDataDeployment() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        System.runAs(standardUser) {
            // Click on New Deployment
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deploymentRecord = new Deployment__c();
            deploymentRecord.Name = 'Metadata Deployment';
            deploymentRecord.RecordTypeId = dataDeploymentRecordTypeId;
            insert deploymentRecord;

            PageReference sourcePage = Page.DW_Source;
            sourcePage.getParameters().put('id', deploymentRecord.Id);
            Test.setCurrentPage(sourcePage);

            // Select Source page
            ApexPages.StandardController deploymentSc = new ApexPages.StandardController(deploymentRecord);
            DW_SourceExtension sourceExtensionController = new DW_SourceExtension(deploymentSc);
            System.assertNotEquals(null, sourceExtensionController.deployment, 'Deployment Created');
            System.assertEquals(null, sourceExtensionController.attId, ATTACHMENT_CREATED);
            System.assertEquals(
                dataDeploymentRecordTypeId,
                sourceExtensionController.deployment.RecordTypeId,
                'Current deployment record type is not "Metadata"'
            );
            System.assertEquals(7, sourceExtensionController.pagesList.size(), 'Number of pages for this point is not 7');
            System.assertEquals(7, sourceExtensionController.stepsList.size(), 'Number of steps for this point is not 7');
            System.assertEquals(0, sourceExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(ORG, sourceExtensionController.selectedSourceType, 'No Source type Org selected at this point');
            System.assertNotEquals(null, sourceExtensionController.deploymentInterface, 'deploymentInterface is not assigned');
            System.assertEquals(0, sourceExtensionController.currentStepValue, 'Current step value is not 0');

            System.assertEquals(2, sourceExtensionController.sourceList.size(), 'Number of orgs created is different from 2');

            sourceExtensionController.deployment.Name = 'My new Data deployment';

            String assertFromOrgId;
            // Select Source org
            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : sourceExtensionController.sourceList) {
                if (deploymentSourceWrapper.orgRecord.Name == DEV1_0) {
                    deploymentSourceWrapper.isSelected = true;
                    assertFromOrgId = deploymentSourceWrapper.orgRecord.Id;
                    break;
                }
            }

            // Click on "Confirm source"
            sourcePage.getParameters().put(BUTTON_ACTION, NEXT_STEP);
            sourceExtensionController.configureSource();
            System.assertEquals(0, sourceExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(0, sourceExtensionController.stepList.size(), STEPS_LOADED);
            System.assertNotEquals(null, sourceExtensionController.deployment.Id, DEPLOYMENT_NOT_CREATED);

            PageReference targetPage = sourceExtensionController.goToNextStep();
            Test.setCurrentPage(targetPage);

            PageReference assertTargetPage = Page.DW_Target;
            assertTargetPage.getParameters().put(ID, sourceExtensionController.deployment.Id);
            System.assertEquals(
                assertTargetPage.getUrl().toLowerCase().subStringAfter(APEX),
                targetPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Target.page"'
            );

            Test.startTest(); // Test Starts here to avoid 101 too many soqls

            // Select Target page
            DW_TargetExtension targetExtensionController = new DW_TargetExtension(deploymentSc);
            System.assertNotEquals(null, targetExtensionController.deployment, DEPLOYMENT_NOT_CREATED);
            System.assertEquals(null, targetExtensionController.attId, ATTACHMENT_CREATED);
            System.assertEquals(7, targetExtensionController.pagesList.size(), 'Pages loaded for this point is not 7');
            System.assertEquals(7, targetExtensionController.stepsList.size(), 'Steps loaded for this point is not 7');
            System.assertEquals(0, targetExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertNotEquals(null, targetExtensionController.deploymentInterface, 'deploymentInterface is not assigned');
            System.assertEquals(1, targetExtensionController.currentStepValue, 'currentStepValue is not 1');
            System.assertEquals(
                new Destination_Org__c(),
                targetExtensionController.destinationOrg,
                'Destination org selected and it shouldn\'t at this point '
            );
            System.assertEquals(2, targetExtensionController.sourceList.size(), 'Number of orgs created is different from 2');

            targetExtensionController.deployment.Deployment_Last_Step__c = sourceExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : targetExtensionController.sourceList) {
                if (deploymentSourceWrapper.orgRecord.Name == STAGING_0) {
                    deploymentSourceWrapper.isSelected = true;
                    break;
                }
            }

            targetExtensionController.checkIfSelectedOrgIsValid();
            targetExtensionController.upsertDestinationOrg();
            System.assertNotEquals(null, targetExtensionController.destinationOrg.Id, 'Destination Org is not assigned');
            System.assertNotEquals(STAGING_0, targetExtensionController.destinationOrg.Name, 'Destination Org is ' + STAGING_0);

            PageReference selectDataTemplatePage = targetExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(selectDataTemplatePage);

            PageReference assertSelectDataTemplatePage = Page.DW_SelectDataTemplate;
            assertSelectDataTemplatePage.getParameters().put(ID, targetExtensionController.deployment.Id);
            System.assertEquals(
                assertSelectDataTemplatePage.getUrl().toLowerCase().subStringAfter(APEX),
                SelectDataTemplatePage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_SelectChanges.page"'
            );

            // Data Template Selection
            DW_SelectDataTemplateExtension selectDataTemplateExtensionController = new DW_SelectDataTemplateExtension(deploymentSc);
            System.assertNotEquals(null, selectDataTemplateExtensionController.deployment.Id, DEPLOYMENT_NOT_CREATED);
            System.assertEquals(7, selectDataTemplateExtensionController.pagesList.size(), 'Pages loaded for this point is not 7');
            System.assertEquals(7, selectDataTemplateExtensionController.stepsList.size(), 'Steps loaded for this point is not 7');
            System.assertEquals(0, selectDataTemplateExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertNotEquals(null, selectDataTemplateExtensionController.deploymentInterface, 'Deployment is not assigned');
            System.assertEquals(2, selectDataTemplateExtensionController.currentStepValue, 'Step value is not 2');

            selectDataTemplateExtensionController.deployment.Deployment_Last_Step__c = targetExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            String generalHeader = selectDataTemplateExtensionController.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(Label.New_Data_Deployment, generalHeader, 'Header in Select Data Template page is not ' + Label.New_Data_Deployment);

            for (DeploymentHelper.SourceWrapper deploymentSourceWrapper : selectDataTemplateExtensionController.sourceList) {
                if (deploymentSourceWrapper.template.Name == 'My data template 0') {
                    deploymentSourceWrapper.isSelected = true;
                }
            }

            PageReference overviewPage = selectDataTemplateExtensionController.confirmAndGoOverride();
            Test.setCurrentPage(overviewPage);

            PageReference assertOverviewPage = Page.DW_Overview;
            assertOverviewPage.getParameters().put(ID, selectDataTemplateExtensionController.deployment.Id);
            System.assertEquals(
                assertOverviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                overviewPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Overview.page"'
            );

            // Overview page
            DW_OverviewExtension overviewExtensionController = new DW_OverviewExtension(deploymentSc);
            Destination_Org__c destinationOrg = overviewExtensionController.getDestinationOrg();
            System.assertEquals(0, overviewExtensionController.pageMessagesMap.size(), ERRORS_FOUND);
            System.assertEquals(assertFromOrgId, overviewExtensionController.deployment.From_Org__c, 'Source is not correct');
            System.assertEquals(STAGING_0, destinationOrg.To_Org__r.Environment__r.Name, 'Destination is not correct');
            System.assertEquals(assertFromOrgId, overviewExtensionController.dataTemplate.Template_Source_Org__c, 'Destination is not correct');

            overviewExtensionController.deployment.Deployment_Last_Step__c = selectDataTemplateExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // Those methods are skipped. They check for Customer credits. As it is in a callout, can be skipped.
            //overviewPage.getParameters().put('actionName', DEPLOYMENT);
            //overviewExtensionController.confirmDeployment();
            overviewExtensionController.deploymentActionName = DEPLOYMENT; // Manually assign this parameter due to previous method skipped.
            overviewExtensionController.deploymentDMLs();

            // We skip overviewExtensionController.deploymentCallout() => it is only a callout. No point to tes it.
            PageReference deployPage = overviewExtensionController.confirmAndGoNextStep();
            Test.setCurrentPage(deployPage);

            PageReference assertDeployPage = Page.DW_Deployment;
            assertDeployPage.getParameters().put(ID, overviewExtensionController.deployment.Id);
            assertDeployPage.getParameters().put(DEPLOYMENT_ACTION_TYPE, DEPLOYMENT);
            System.assertEquals(
                assertDeployPage.getUrl().toLowerCase().subStringAfter(APEX),
                deployPage.getUrl().toLowerCase().subStringAfter(APEX),
                'Next Page reference is not "DW_Deployment.page"'
            );

            // Deploy page
            DW_DeploymentExtension deploymentExtensionController = new DW_DeploymentExtension(deploymentSc);
            deploymentExtensionController.deployment.Deployment_Last_Step__c = overviewExtensionController.deploymentWillBeRedirected.Deployment_Last_Step__c;

            // This part is simulating the page running the Deployment with poller.
            deploymentExtensionController.initPoller();
            deploymentExtensionController.copadoNotificationProcesses();
            Integer messageSize = deploymentExtensionController.getComponentMessageSize();

            Copado_Notification__c copadoNotification = TestDataFactory.createCopadoNotification(
                'Deployer',
                'Starting',
                false,
                false,
                CopadoNotificationHelper.PROGRESS_STATUS_COPADO,
                deploymentExtensionController.getDeploymentJobId()
            );
            insert copadoNotification;

            deploymentExtensionController.copadoNotificationProcesses();
            messageSize = deploymentExtensionController.getComponentMessageSize();
            System.assertEquals(2, messageSize, 'Number of messages is not two');

            copadoNotification.isFinished__c = true;
            copadoNotification.isSuccess__c = true;
            copadoNotification.status__c = 'done';
            update copadoNotification;

            PageReference summaryPage = deploymentExtensionController.copadoNotificationProcesses();
            System.assertEquals(false, deploymentExtensionController.startActionPoller, 'Poller is not enabled');
            System.assertEquals('Successful', deploymentExtensionController.currentStatusOfAction, 'Current status is not Successful');
            Test.setCurrentPage(summaryPage);

            // Summary Page
            DW_SummaryExtension summaryExtensionController = new DW_SummaryExtension(deploymentSc);

            PageReference deploymentTab = summaryExtensionController.goToDeploymentTab();
            String assertDeploymentTab = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            System.assertEquals(assertDeploymentTab, deploymentTab.getUrl(), 'Url is not Deployment Listview');

            Test.stopTest();
        }
    }
}