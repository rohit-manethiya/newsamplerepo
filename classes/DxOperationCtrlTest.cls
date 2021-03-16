@IsTest
private with sharing class DxOperationCtrlTest {
    @TestSetup
    private static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.insertUser('user1-dxOperations@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @IsTest
    private static void testScratchOrgCommitHistory() {
        Org__c thisOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        Test.startTest();
        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = thisOrg.Id;
        // Select Commit History action
        controller.selectedAction = 'ch';
        // Simulate the page link's onclick behavior and retrieve one snapshot commit for the selected org
        controller.enableSelectedPanels();
        System.assertEquals(1, controller.snapshotCommits.size());
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgExtensionDeployment() {
        Org__c thisOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];
        Org__c dev1Org = [SELECT Environment__c FROM Org__c WHERE Name = 'Dev1'];
        Deployment__c deployment = [SELECT Id FROM Deployment__c WHERE Name = 'Deployment'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = thisOrg.Id;
        controller.getOperationActions();
        // Assert available scratch org operation options
        System.assertEquals('gsos', controller.actionMap.get(Label.DXOperation_OrgStatus));
        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory));
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData));
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata));

        // Select Extensions action
        controller.selectedAction = 'exs';
        // Simulate the page link's onclick behavior and retrieve one snapshot commit for the selected org
        controller.enableSelectedPanels();

        ScratchOrgExtensionsController extensionsController = new ScratchOrgExtensionsController();
        extensionsController.setComponentMode('add');
        extensionsController.setControllerKey('ScratchOrgExtensions');
        extensionsController.setPageController(controller);
        // Set selected source org id
        extensionsController.sourceOrgId = dev1Org.Id;
        // Simulate the page picklist's onclick behavior and retrieve a deployment list for the selected org
        extensionsController.populateDeployments();
        System.assertEquals(1, extensionsController.deploymentList.size());
        // Selected a deployment job template from the list
        extensionsController.selectedDeploymentId = deployment.Id;
        // Initialize the selected deployment's steps
        extensionsController.initDeploymentStep();

        Test.startTest();
        // Add selected deployment to extensions
        extensionsController.addToExtensions();
        // Populate the deployment id again to simulate the edition of the selected extension (the new copy of the original deployment)
        extensionsController.selectedDeploymentId = extensionsController.getDeploymentInformationAt(0).getDeploymentId();
        // Edit deployment extension steps
        extensionsController.editExtension();
        // Cancel edition
        extensionsController.cancelPrep();
        // Populate the deployment id again to simulate the deletion of the selected extension (the new copy of the original deployment)
        extensionsController.selectedDeploymentId = extensionsController.getDeploymentInformationAt(0).getDeploymentId();
        // Delete deployment extension from the list
        extensionsController.deleteExtension();
        // Add the deployment extension back
        extensionsController.selectedDeploymentId = deployment.Id;
        extensionsController.initDeploymentStep();
        extensionsController.addToExtensions();

        //Click to the load metadata button. Set mock callout class
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        extensionsController.executeSteps();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgLoadMetadataFromArtifactWithProjectTemplate() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];
        Scratch_Org_Project_Template__c template = [SELECT Id FROM Scratch_Org_Project_Template__c WHERE Name = 'Test'];
        Artifact__c thisArtifact = [SELECT Id FROM Artifact__c WHERE Name = 'GitArtifact'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;
        controller.getOperationActions();
        // Assert available scratch org operation options
        System.assertEquals('gsos', controller.actionMap.get(Label.DXOperation_OrgStatus));
        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory));
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData));
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata));

        // Select Load Metadata action
        controller.selectedAction = 'lm';
        // Simulate the page link's onclick behavior and load the available metadata sources
        controller.enableSelectedPanels();
        // Set the selected template Id for the metadata load
        ApexPages.currentPage().getParameters().put('templateId', template.Id);
        //Instantiate and construct the controller class of the scratch org metadata component
        ScratchOrgMetadataController metadataController = new ScratchOrgMetadataController();
        metadataController.setComponentMode('add');
        metadataController.setShowTemplateButtons(false);
        metadataController.setShowButtons(true);
        metadataController.setControllerKey('ScratchOrgMetadata');
        metadataController.setPageController(controller);

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', DXLabel.ARTIFACT);
        metadataController.selectType();

        // Set selected artifact id to load metadata from and update the source selections
        metadataController.selectedArtifactIDs = new List<String>{ thisArtifact.Id };
        metadataController.updateSourceSelections();

        // Update the selected git artifact template
        metadataController.updateTemplate();

        Test.startTest();
        //Click to the load metadata button. Set mock callout class
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        metadataController.loadMetadata();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.LOAD_METADATA);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgLoadMetadataFromUnlockedPackageWithTemplate() {
        Org__c sourceOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Dev Hub 1'];
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];
        Scratch_Org_Project_Template__c template = [SELECT Id FROM Scratch_Org_Project_Template__c WHERE Name = 'Test'];
        Artifact__c thisArtifact = [SELECT Artifact_Version__c FROM Artifact__c WHERE Name = 'Unlocked1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;
        controller.getOperationActions();
        // Assert available scratch org operation options
        System.assertEquals('gsos', controller.actionMap.get(Label.DXOperation_OrgStatus));
        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory));
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData));
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata));

        // Select Load Metadata action
        controller.selectedAction = 'lm';
        // Simulate the page link's onclick behavior and load the available metadata sources
        controller.enableSelectedPanels();
        // Set the selected template Id for the metadata load
        ApexPages.currentPage().getParameters().put('templateId', template.Id);
        //Instantiate and construct the controller class of the scratch org metadata component
        ScratchOrgMetadataController metadataController = new ScratchOrgMetadataController();
        metadataController.setComponentMode('add');
        metadataController.setShowTemplateButtons(false);
        metadataController.setShowButtons(true);
        metadataController.setControllerKey('ScratchOrgMetadata');
        metadataController.setPageController(controller);

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', DXLabel.UNLOCKPACKAGE);
        metadataController.selectType();

        // Set selected source org in the metadata component
        metadataController.setSelectedOrgId(sourceOrg.Id);
        metadataController.getOrgArtifacts();
        System.assertEquals(2, metadataController.artifactOptions.size());

        // Set selected artifact id to load metadata from and get its artifact versions
        metadataController.selectedArtifactId = thisArtifact.Id;
        metadataController.populateArtifactVersions();
        System.assertEquals(1, metadataController.artifactVersionOptions.size());

        // Select one artifact version to install in the target org and update the source selections
        metadataController.selectedVersionId = thisArtifact.Artifact_Version__c;
        metadataController.addValuesToSelectedPackages();
        // Remove selected package
        ApexPages.currentPage().getParameters().put('aVersion', metadataController.selectedVersionId);
        metadataController.removePackage();
        // Select package again
        metadataController.addValuesToSelectedPackages();

        // Update the selected unlocked artifact template
        metadataController.updateTemplate();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        metadataController.loadMetadata();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.LOAD_METADATA);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgLoadMetadataFromPatch() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];
        Release__c thisRelease = [SELECT Id FROM Release__c WHERE Name = 'Release 2'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;
        controller.getOperationActions();
        // Assert available scratch org operation options
        System.assertEquals('gsos', controller.actionMap.get(Label.DXOperation_OrgStatus));
        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory));
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData));
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata));

        // Select Load Metadata action
        controller.selectedAction = 'lm';
        // Simulate the page link's onclick behavior and load the available metadata sources
        controller.enableSelectedPanels();
        // Set the selected branch from which to load metadata
        ApexPages.currentPage().getParameters().put('branchName', 'dev1');
        controller.setBranchName();
        //Instantiate and construct the controller class of the scratch org metadata component
        ScratchOrgMetadataController metadataController = new ScratchOrgMetadataController();
        metadataController.setComponentMode('add');
        metadataController.setShowTemplateButtons(false);
        metadataController.setShowButtons(true);
        metadataController.setControllerKey('ScratchOrgMetadata');
        metadataController.setPageController(controller);

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', DXLabel.PATCH);
        metadataController.selectType();

        // Set selected release
        metadataController.selectedReleaseId = thisRelease.Id;
        metadataController.setRepository();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        metadataController.refreshBranchCache();
        metadataController.loadMetadata();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.LOAD_METADATA);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgLoadMetadataFromBranch() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];
        Git_Repository__c thisRepository = [SELECT Id FROM Git_Repository__c WHERE Name = 'git 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;
        controller.getOperationActions();
        // Assert available scratch org operation options
        System.assertEquals('gsos', controller.actionMap.get(Label.DXOperation_OrgStatus));
        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory));
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData));
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata));

        // Select Load Metadata action
        controller.selectedAction = 'lm';
        // Simulate the page link's onclick behavior and load the available metadata sources
        controller.enableSelectedPanels();
        // Set the selected branch from which to load metadata
        ApexPages.currentPage().getParameters().put('branchName', 'dev1');
        controller.setBranchName();
        //Instantiate and construct the controller class of the scratch org metadata component
        ScratchOrgMetadataController metadataController = new ScratchOrgMetadataController();
        metadataController.setComponentMode('add');
        metadataController.setShowTemplateButtons(false);
        metadataController.setShowButtons(true);
        metadataController.setControllerKey('ScratchOrgMetadata');
        metadataController.setPageController(controller);

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', DXLabel.BRANCH);
        metadataController.selectType();

        // Set selected repository
        metadataController.selectedRepositoryId = thisRepository.Id;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        metadataController.loadMetadata();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.LOAD_METADATA);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    // TODO: ADD LOAD METADATA TEST FROM BRANCH WITH ATTACHMENT

    @IsTest
    private static void testScratchOrgGetOrgStatus() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;
        controller.getOperationActions();

        // Select Get Scratch Org Status action
        controller.selectedAction = 'gsos';
        // Simulate the page link's onclick behavior and load the available metadata sources
        controller.enableSelectedPanels();

        // Instantiate the ScratchOrgStatus component that is inside the DXOperation page
        ScratchOrgStatusCtrl statusController = new ScratchOrgStatusCtrl();
        statusController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        statusController.requestStatus();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgGetOrgDetails() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org Branch 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;

        // Instantiate the ScratchOrgDisplay component that is inside of the DXOperation page
        ScratchOrgDisplayController displayController = new ScratchOrgDisplayController();
        displayController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        displayController.orgDetails();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgGetOrgDetailsError() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org Branch 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;

        // Instantiate the ScratchOrgDisplay component that is inside of the DXOperation page
        ScratchOrgDisplayController displayController = new ScratchOrgDisplayController();
        displayController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        displayController.orgDetails();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgDeleteScratchOrg() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org Branch 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;

        // Instantiate the ScratchOrgDisplay component that is inside of the DXOperation page
        ScratchOrgDisplayController displayController = new ScratchOrgDisplayController();
        displayController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        displayController.deleteScratchOrg();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.DELETE_ORG);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testScratchOrgGeneratePassword() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org Branch 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;

        // Instantiate the ScratchOrgDisplay component that is inside of the DXOperation page
        ScratchOrgDisplayController displayController = new ScratchOrgDisplayController();
        displayController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        displayController.generatePassword();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.ORG_IDE_DETAILS);
        controller.jobStatusNotification();

        Test.stopTest();
    }

    // TODO: review this test. There is no assert.
    @IsTest
    private static void testScratchOrgGeneratePasswordError() {
        Org__c targetScratchOrg = [SELECT Environment__c FROM Org__c WHERE Name = 'Scratch Org Branch 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.loadSubmenu();
        //Select the Scratch Org 1 from picklist and populate actions
        controller.selectedOrgId = targetScratchOrg.Id;

        // Instantiate the ScratchOrgDisplay component that is inside of the DXOperation page
        ScratchOrgDisplayController displayController = new ScratchOrgDisplayController();
        displayController.scratchOrgId = controller.selectedOrgId;

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"error":"passwdError"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        displayController.generatePassword();

        Test.stopTest();
    }

    @IsTest
    private static void testDevHubOperationsCreateScratchOrgWithTemplate() {
        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = 'Dev Hub 1'];
        Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c WHERE Name = 'Deployment Flow 1'];
        Scratch_Org_Definition__c template = [SELECT Id FROM Scratch_Org_Definition__c WHERE Name = 'Scratch Org Definition'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '2';
        controller.loadSubmenu();
        System.assertEquals(2, controller.orgCredentialOptions.size());
        //Select the Dev hub 1 from picklist and populate actions
        controller.selectedOrgId = devHubOrg.Id;
        controller.getOperationActions();
        // Assert available dev hub operation options
        System.assertEquals('cso', controller.actionMap.get(Label.DXOperation_CreateSO));
        System.assertEquals('mso', controller.actionMap.get(Label.DXOperation_ManageSOs));
        // Select Create Scratch Org action
        controller.selectedAction = 'cso';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();

        // Instantiate the ScratchOrgTemplate component that is inside of the DXOperation page
        ScratchOrgController orgController = new ScratchOrgController();
        orgController.setComponentMode('new');
        orgController.setShowTemplateButtons(true);
        orgController.setShowButtons(true);
        orgController.setControllerKey('ScratchOrgTemplate');
        orgController.setPageController(controller);
        // Set selected dev hub org id on the component
        orgController.setDevHubOrgId(devHubOrg.Id);
        // Assert available template options
        System.assertEquals(2, orgController.templatesWithHubId.size());
        // Set selected template id
        orgController.templateId = template.Id;
        // Simulate onchange event for selected template
        orgController.readOrgDefinitionFromTemplate();
        // Assert available pipeline options
        System.assertEquals(3, orgController.deploymentFlowOptions.size());
        // Set target Pipeline
        orgController.selectedPipelineId = pipeline.Id;
        // Simulate the onchange behavior when selecting a new pipeline
        orgController.populateDeploymentFlowSteps();
        System.assertEquals(3, orgController.dfsSelectOptionList.size());
        // Set a new name for the Scratch Org
        orgController.setDxUserStoryName('SO-1111111');
        // Update scratch org definition template
        orgController.updateTemplate();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        orgController.createOrg();

        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.CREATE_ORG);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testDevHubOperationsCreateScratchOrgWithoutTemplate() {
        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = 'Dev Hub 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '2';
        controller.loadSubmenu();
        System.assertEquals(2, controller.orgCredentialOptions.size());
        //Select the Dev hub 1 from picklist and populate actions
        controller.selectedOrgId = devHubOrg.Id;
        controller.getOperationActions();
        // Assert available dev hub operation options
        System.assertEquals('cso', controller.actionMap.get(Label.DXOperation_CreateSO));
        System.assertEquals('mso', controller.actionMap.get(Label.DXOperation_ManageSOs));
        // Select Create Scratch Org action
        controller.selectedAction = 'cso';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();

        // Instantiate the ScratchOrgTemplate component that is inside of the DXOperation page
        ScratchOrgController orgController = new ScratchOrgController();
        orgController.setComponentMode('new');
        orgController.setShowTemplateButtons(true);
        orgController.setShowButtons(true);
        orgController.setControllerKey('ScratchOrgTemplate');
        orgController.setPageController(controller);
        // Set selected dev hub org id on the component
        orgController.setDevHubOrgId(devHubOrg.Id);
        // Set a new name for the Scratch Org
        orgController.setDxUserStoryName('SO-1111111');
        // Set a name for the new scratch org definition template
        orgController.templateName = 'New Scratch Org Template';
        // Create new scratch org definition template
        orgController.newTemplate();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        orgController.createOrg();

        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', DXLabel.CREATE_ORG);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @IsTest
    private static void testDevHubOperationsManageScratchOrgs() {
        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = 'Dev Hub 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        Test.startTest();
        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '2';
        controller.loadSubmenu();
        System.assertEquals(2, controller.orgCredentialOptions.size());
        //Select the Dev hub 1 from picklist and populate actions
        controller.selectedOrgId = devHubOrg.Id;
        controller.getOperationActions();
        // Assert available dev hub operation options
        System.assertEquals('cso', controller.actionMap.get(Label.DXOperation_CreateSO));
        System.assertEquals('mso', controller.actionMap.get(Label.DXOperation_ManageSOs));
        // Select Manage Scratch Orgs action
        controller.selectedAction = 'mso';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();
        // Assert figures of active and deleted scratch orgs
        System.assertEquals(1, controller.activeScratchOrgs.size());
        System.assertEquals(1, controller.deletedScratchOrgs.size());
        Test.stopTest();
    }

    @IsTest
    private static void testPlanningOperationsManageDefinitionTemplate() {
        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        Test.startTest();
        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '4';
        controller.loadSubmenu();
        // Assert available dev hub operation options
        System.assertEquals('mdt', controller.actionMap.get(Label.DXOperation_ManageDefinitionTemplate));
        System.assertEquals('mpt', controller.actionMap.get(Label.DXOperation_ManageProjectTemplate));
        System.assertEquals('ma', controller.actionMap.get(Label.DXOperation_ManageArtifacts));
        // Select Manage Definition Template action
        controller.selectedAction = 'mdt';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();
        // Simulate the Refresh button click
        controller.retrieveDefinitionTemplates();
        // Assert the available scratch org definition templates
        System.assertEquals(1, controller.orgDefinitionTemplates.size());
        Test.stopTest();
    }

    @IsTest
    private static void testPlanningOperationsManageArtifacts() {
        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = 'Dev Hub 1'];

        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        Test.startTest();
        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '4';
        controller.loadSubmenu();
        // Assert available dev hub operation options
        System.assertEquals('mdt', controller.actionMap.get(Label.DXOperation_ManageDefinitionTemplate));
        System.assertEquals('mpt', controller.actionMap.get(Label.DXOperation_ManageProjectTemplate));
        System.assertEquals('ma', controller.actionMap.get(Label.DXOperation_ManageArtifacts));
        // Select Manage Packages action
        controller.selectedAction = 'ma';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();
        // Assert available org credentials
        System.assertEquals(10, controller.orgCredentialOptions.size());
        // Set selected dev hub org
        controller.selectedOrgId = devHubOrg.Id;
        // Simulate the onchange behavior
        controller.retrieveArtifacts();
        // Assert available artifacts
        System.assertEquals(3, controller.artifacts.size());
        Test.stopTest();
    }

    @IsTest
    private static void testPlanningOperationsManageProjectTemplate() {
        PageReference thisPage = Page.DXOperation;
        Test.setCurrentPage(thisPage);
        DXOperationController controller = new DXOperationController();

        Test.startTest();
        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '4';
        controller.loadSubmenu();
        // Assert available dev hub operation options
        System.assertEquals('mdt', controller.actionMap.get(Label.DXOperation_ManageDefinitionTemplate));
        System.assertEquals('mpt', controller.actionMap.get(Label.DXOperation_ManageProjectTemplate));
        System.assertEquals('ma', controller.actionMap.get(Label.DXOperation_ManageArtifacts));
        // Select Manage Definition Template action
        controller.selectedAction = 'mpt';
        // Simulate the page link's onclick behavior and open the Manage Scratch Orgs page
        controller.enableSelectedPanels();
        // Simulate the Refresh button click
        controller.retrieveProjectTemplates();
        // Assert the available scratch org definition templates
        System.assertEquals(1, controller.projectTemplates.size());
        Test.stopTest();
    }

    @IsTest
    private static void testUserStoryOperations() {
        setCurrentPage();

        User_Story__c userStory = [SELECT Name FROM User_Story__c WHERE User_Story_Title__c = 'Test User Story'];
        DXOperationController controller = getPageController();
        controller.selectedOperation = '3';
        controller.userStoryInfo.usId = userStory.Id;
        controller.userStoryInfo.usName = userStory.Name;

        Test.startTest();
        controller.getOperationActions();
        Test.stopTest();

        System.assertEquals('ch', controller.actionMap.get(Label.DXOperation_CommitHistory), 'Commit History should always appear under User Story Operations.');
        System.assertEquals('csous', controller.actionMap.get(Label.DXOperation_CreateSO), 'Create Scratch Org should always appear under User Story Operations.');
        System.assertEquals('ld', controller.actionMap.get(Label.DXOperation_LoadData), 'Extensions should always appear under User Story Operations.');
        System.assertEquals('lm', controller.actionMap.get(Label.DXOperation_LoadMetadata), 'Load Metadata should always appear under User Story Operations.');
    }

    @IsTest
    private static void userStoryOperationsCommitHistory() {
        setCurrentPage();

        User_Story__c userStory = [SELECT Name FROM User_Story__c WHERE User_Story_Title__c = 'Test User Story'];
        DXOperationController controller = getPageController();
        controller.selectedOperation = '3';
        controller.userStoryInfo.usId = userStory.Id;
        controller.userStoryInfo.usName = userStory.Name;
        controller.getOperationActions();
        controller.selectedAction = 'ch';

        Test.startTest();
        controller.enableSelectedPanels();
        Test.stopTest();

        System.assert(controller.userStoryCommits.isEmpty(), 'This User Story has no commits. The list must be empty.');
    }

    @IsTest
    private static void userStoryOperationsCreateScratchOrgWithOrgCredential() {
        setCurrentPage();

        Org__c credential = [SELECT Id FROM Org__c WHERE Name = :'Scratch Org 1'];
        User_Story__c userStory = [SELECT Name FROM User_Story__c WHERE User_Story_Title__c = 'Test User Story'];
        userStory.Org_Credential__c = credential.Id;
        update userStory;

        DXOperationController controller = getPageController();
        controller.selectedOperation = '3';
        controller.userStoryInfo.usId = userStory.Id;
        controller.userStoryInfo.usName = userStory.Name;
        controller.getOperationActions();
        controller.selectedAction = 'csous';

        Test.startTest();
        PageReference actualPage = controller.enableSelectedPanels();
        Test.stopTest();

        PageReference expectedPage = Page.CreateUserStoryScratchOrg;
        expectedPage.getParameters().put('id', userStory.Id);
        System.assert(actualPage != null, 'Could not find the selected user story. Unable to redirect to Scratch Org creation page.');
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    private static void userStoryOperationsLoadMetadataSources() {
        setCurrentPage();

        Org__c credential = [SELECT Id FROM Org__c WHERE Name = :'Scratch Org Branch 1'];
        User_Story__c userStory = [SELECT Name FROM User_Story__c WHERE User_Story_Title__c = 'Test User Story'];
        userStory.Org_Credential__c = credential.Id;
        update userStory;

        DXOperationController controller = getPageController();
        controller.selectedOperation = '3';
        controller.userStoryInfo.usId = userStory.Id;
        controller.userStoryInfo.usName = userStory.Name;
        controller.getOperationActions();
        controller.selectedAction = 'lm';
        controller.selectedOrgId = null;

        Test.startTest();
        PageReference page = controller.enableSelectedPanels();
        Test.stopTest();

        System.assert(page == null, 'Users should not be redirected anywhere when selecting this action.');
        System.assertEquals(credential.Id, controller.selectedOrgId, 'The selected org should be the one set as org credential for the given user story.');
        System.assert(controller.disableLoadMetadataPanel, 'When metadata sources are loaded from an attachment, the user may not selected any on this page.');
    }

    @IsTest
    private static void scheduleDXJob() {
        setCurrentPage();

        DXOperationController controller = getPageController();

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        controller.scheduleDxJob();
        Test.stopTest();

        System.assert(!controller.showSchedule, 'If a DX job is already scheduled, the user should not see the Schedule DX Job button on the page.');
    }

    @IsTest
    private static void jobStatusNotificationError() {
        setCurrentPage();
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
        ApexPages.currentPage().getParameters().put('jobType', 'DxCreateFullScratchOrgJob');
        ApexPages.currentPage().getParameters().put('jobMessage', 'Error during job execution');

        DXOperationController controller = getPageController();

        Test.startTest();
        PageReference actualPage = controller.jobStatusNotification();
        Test.stopTest();

        String expectedJobMessage = 'Error during job execution';
        String actualJobMessage = ApexPages.getMessages()[0].getDetail();
        System.assert(actualPage == null, 'When an error in the job occurs, the user must not be redirected from the current page.');
        System.assertEquals(expectedJobMessage, actualJobMessage, 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    private static void testCreateScratchOrgFromUserStory() {
        Org__c sourceOrg = [SELECT Id, Environment__c FROM Org__c WHERE Name = 'Dev Hub 1'];
        User_Story__c userStory = [
            SELECT Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
            FROM User_Story__c
            WHERE User_Story_Title__c = 'Test User Story'
        ];
        Artifact__c thisArtifact = [SELECT Id, Artifact_Version__c FROM Artifact__c WHERE Name = 'Unlocked1'];

        PageReference thisPage = Page.CreateUserStoryScratchOrg;
        Test.setCurrentPage(thisPage);
        ApexPages.StandardController standardController = new ApexPages.StandardController(userStory);
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(standardController);

        //Instantiate and construct the controller class of the scratch org metadata component
        ScratchOrgMetadataController metadataController = new ScratchOrgMetadataController();
        metadataController.setComponentMode('wizard');
        metadataController.setShowTemplateButtons(false);
        metadataController.setShowButtons(true);
        metadataController.setControllerKey('ScratchOrgMetadata');
        metadataController.setPageController(controller);
        controller.setChildComponentController(metadataController);

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', DXLabel.UNLOCKPACKAGE);
        metadataController.selectType();

        // Set selected source org in the metadata component
        metadataController.setSelectedOrgId(sourceOrg.Id);
        metadataController.getOrgArtifacts();
        System.assertEquals(2, metadataController.artifactOptions.size());

        // Set selected artifact id to load metadata from and get its artifact versions
        metadataController.selectedArtifactId = thisArtifact.Id;
        metadataController.populateArtifactVersions();
        System.assertEquals(1, metadataController.artifactVersionOptions.size());

        // Select one artifact version to install in the target org and update the source selections
        metadataController.selectedVersionId = thisArtifact.Artifact_Version__c;
        metadataController.addValuesToSelectedPackages();

        // Simulate clicking on the Next button from the Load Metadata screen.
        //controller.nextStep();

    }

    //Load metadata is covered for user story operation
    @IsTest
    private static void userStoryOperationsTwo() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select User Story Operations and execute the change function
        controller.selectedOperation = '3';

        //Select the user story from lookup and populate actions
        User_Story__c uStory3 = [
            SELECT Id, User_Story_Title__c, Org_Credential__c
            FROM User_Story__c
            WHERE User_Story_Title__c = :'Error on dx operation 3'
        ];

        //Select load metadata from action.
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Select create scratch org action to get warning
        ApexPages.currentPage().getParameters().put('actionName', 'csous');
        controller.enableSelectedPanels();
    }

    @IsTest
    private static void planningOperationsOne() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';

        //Select manage artifact from action
        ApexPages.currentPage().getParameters().put('actionName', 'ma');
        controller.enableSelectedPanels();

        //Select the Dev Hub 1 from picklist and populate artifact lists
        Org__c orgDevHub = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        controller.retrieveArtifacts();

        //Instantiate and construct the controller class of ArtifactManageMetadata page.
        Artifact__c art = [SELECT Id, Artifact_Repository__c, Org_Credential__c FROM Artifact__c WHERE Name = :'StaticResources2'];
        PageReference pageAmm = Page.ArtifactManageMetadata;
        Test.setCurrentPage(pageAmm);
        pageAmm.getParameters().put('Id', art.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(art);

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"copadoJobId":"testMe","ok":"ok","status":"in progress","error":"","success":"true","message":"test"}',
            null
        );
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        ArtifactManageMetadataController ammController = new ArtifactManageMetadataController(sc);

        //MockHttpResponseGenerator fakeResponseError = new MockHttpResponseGenerator(200,'Complete','{"copadoJobId":"","ok":"","status":"","error":"There is test error"}',null);
        //Test.setMock(HttpCalloutMock.class, fakeResponseError);
        ammController.callJob();
        Test.stopTest();
    }

    @IsTest
    private static void planningOperationsOneDashTwo() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';

        //Select manage artifact from action
        ApexPages.currentPage().getParameters().put('actionName', 'ma');
        controller.enableSelectedPanels();

        //Select the Dev Hub 1 from picklist and populate artifact lists
        Org__c orgDevHub = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        controller.retrieveArtifacts();

        //Instantiate and construct the controller class of ArtifactManageMetadata page.
        Artifact__c art = [SELECT Id, Artifact_Repository__c, Org_Credential__c FROM Artifact__c WHERE Name = :'StaticResources2'];
        PageReference pageAmm = Page.ArtifactManageMetadata;
        Test.setCurrentPage(pageAmm);
        pageAmm.getParameters().put('Id', art.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(art);

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"copadoJobId":"","ok":"ok","status":"in progress","error":"","success":"true","message":"test"}',
            null
        );
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        ArtifactManageMetadataController ammController = new ArtifactManageMetadataController(sc);
        Copado_Notification__c c = CopadoNotificationHelper.instCopadoNotification('test', 'testId', 'test', 'testId');
        c.isFinished__c = true;
        c.isSuccess__c = true;
        insert c;

        //MockHttpResponseGenerator fakeResponseError = new MockHttpResponseGenerator(200,'Complete','{"copadoJobId":"","ok":"","status":"","error":"There is test error"}',null);
        //Test.setMock(HttpCalloutMock.class, fakeResponseError);
        ammController.checkJobApex();
        c.isSuccess__c = false;
        update c;
        ammController.checkJobApex();
        ammController.errorLevel = 'WARNING';
        ammController.messageName = 'WARNING';
        ammController.showMessage();
        ammController.errorLevel = 'CONFIRM';
        ammController.showMessage();
        Test.stopTest();
    }

    @IsTest
    private static void planningOperationsTwo() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';

        //Select manage manage definition template and execute function
        ApexPages.currentPage().getParameters().put('actionName', 'mpt');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somController = new ScratchOrgMetadataController();
        somController.setComponentMode('template');
        somController.setShowTemplateButtons(true);
        somController.setShowButtons(false);
        somController.setControllerKey('ScratchOrgMetadata');
        somController.setPageController(controller);

        //Click to Save as Template button. It will return because template name is empty
        somController.newTemplate();
        List<ApexPages.Message> messageList = ApexPages.getMessages();
        Boolean err = false;
        for (ApexPages.Message msg : messageList) {
            if (msg.getDetail().contains(Label.SOD_Template_Name_Validation)) {
                err = true;
            }
        }
        System.assert(err);

        //Fill template name and Click Save as Template button again
        somController.newTemplate();

        somController.typeName = 'artifact';
        somController.getOrgCredentialsWithArtifactsList();
        Org__c orgDevHub = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        Artifact__c art = [SELECT Id, Artifact_Repository__c, Org_Credential__c FROM Artifact__c WHERE Name = :'StaticResources2'];
        somController.setSelectedOrgId(orgDevHub.Id);
        somController.newTemplate();
        somController.updateTemplate();
    }

    @IsTest
    private static void planningOperationsThree() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        Test.startTest();
        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';

        //Select manage manage definition template and execute function
        ApexPages.currentPage().getParameters().put('actionName', 'mdt');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somController = new ScratchOrgMetadataController();
        somController.setComponentMode('template');
        somController.setShowTemplateButtons(true);
        somController.setShowButtons(false);
        somController.setControllerKey('ScratchOrgMetadata');
        somController.setPageController(controller);

        //Click to Save as Template button. It will return because template name is empty
        somController.newTemplate();
        List<ApexPages.Message> messageList = ApexPages.getMessages();
        Boolean err = false;
        for (ApexPages.Message msg : messageList) {
            if (msg.getDetail().contains(Label.SOD_Template_Name_Validation)) {
                err = true;
            }
        }
        System.assert(err);

        //Fill template name and Click Save as Template button again
        somController.newTemplate();

        somController.typeName = 'artifact';
        somController.getOrgCredentialsWithArtifactsList();
        Org__c orgDevHub = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        Artifact__c art = [SELECT Id, Artifact_Repository__c, Org_Credential__c FROM Artifact__c WHERE Name = :'StaticResources2'];
        somController.setSelectedOrgId(orgDevHub.Id);
        somController.newTemplate();
        somController.updateTemplate();

        Test.stopTest();
    }

    @IsTest
    private static void existingOrgIdOperations() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Select the Dev Hub 1
        Org__c orgDevHub = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];

        //Assign the dev hub id to the page as a parameter
        pageRef.getParameters().put('id', orgDevHub.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef1 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef1);

        //Select the wrong scratch org
        Org__c scratchOrg = [SELECT Id FROM Org__c WHERE Name = :'Scratch Org Branch'];

        //Assign the dev hub id to the page as a parameter
        pageRef1.getParameters().put('id', scratchOrg.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller1 = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef2 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef2);

        //Select the correct scratch org
        Org__c scratchOrg1 = [SELECT Id FROM Org__c WHERE Name = :'Scratch Org 1'];

        //Assign the dev hub id to the page as a parameter
        pageRef2.getParameters().put('id', scratchOrg1.Id);

        //Assign action name to the page as a parameter (lm = load metadata)
        pageRef2.getParameters().put('act', 'lm');

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller2 = new DXOperationController();

        //Select manage manage definition template and execute function
        ApexPages.currentPage().getParameters().put('actionName', 'main');
        controller2.enableSelectedPanels();
    }

    @IsTest
    private static void existingUserStoryIdOperations() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Select the user story from lookup and populate actions. It will return because us do not belong to project and deployment flow is null
        User_Story__c uStory = [SELECT Id, User_Story_Title__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation'];

        //Assign the user story id to the page as a parameter
        pageRef.getParameters().put('id', uStory.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef1 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef1);

        //Select the user story from lookup and populate actions.
        User_Story__c uStory1 = [SELECT Id, User_Story_Title__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];

        //Assign the user story id to the page as a parameter
        pageRef1.getParameters().put('id', uStory1.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller1 = new DXOperationController();
    }

    @IsTest
    private static void scratchOrgExtensionPermissionTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User u1 = new User(
            ProfileId = p.Id,
            Alias = 'standt1',
            Email = 'soextTest1@testorg.com',
            Username = 'insertUpdateTest1@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u1;
        TestUtilities.assignLicense(UserInfo.getUserName(), false, false, false, false, false);

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [SELECT Id, Name, Environment__c FROM Org__c WHERE Name = :'Scratch Org 2 For Org'];
        System.runAs(u1) {
            //Select commit history from action and load snapshots commit
            ApexPages.currentPage().getParameters().put('actionName', 'ld');
            controller.enableSelectedPanels();

            ScratchOrgExtensionsController extContoller = new ScratchOrgExtensionsController();
            extContoller.setComponentMode('add');
            extContoller.setShowTemplateButtons(false);
            extContoller.setShowButtons(false);
            extContoller.setControllerKey('ScratchOrgExtensions');
            extContoller.setPageController(controller);
            extContoller.initExtensionPrep();

            Test.startTest();
            //Populate deployment picklist based on selected source org
            extContoller.sourceOrgId = orgScratch.Id;
            extContoller.sourceOrgName = orgScratch.Name;
            extContoller.populateDeployments();

            //Select deployment and init the cloning
            extContoller.selectedDeploymentId = null;
            extContoller.initDeploymentStep();
            extContoller.addToExtensions();
            System.assert([SELECT Id, Name FROM Deployment__c WHERE Name != :'Deployment' LIMIT 1].size() == 0);
            extContoller.editExtension();
            extContoller.cancelPrep();

            MockHttpResponseGenerator fakeResponseCache = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponseCache);
            extContoller.executeSteps();

            DXExtensionStatusController sowcb = new DXExtensionStatusController();
            sowcb.setComponentMode('add');
            sowcb.setShowTemplateButtons(false);
            sowcb.setShowButtons(false);
            sowcb.setControllerKey('ScratchOrgExtensions');
            sowcb.setPageController(controller);
            sowcb.getPageController().setComponentControllerMap('ScratchOrgExtensions', extContoller);

            ApexPages.currentPage().getParameters().put('actionName', 'exs');
            controller.enableSelectedPanels();

            sowcb.addDeploymentInfo(orgScratch.Id, orgScratch.Name, null, null);
            sowcb.enabledRebasePromotionPoller = true;
            sowcb.checkExtensionStatuses();
            sowcb.checkExtensionStatuses();

            extContoller.addDeploymentInfo(extContoller.sourceOrgId, extContoller.sourceOrgName, null, null);
            extContoller.selectedDeploymentId = null;
            extContoller.deleteExtension();
            Test.stopTest();
        }
    }

    private static void setCurrentPage() {
        PageReference page = Page.DXOperation;
        Test.setCurrentPage(page);
    }

    private static DXOperationController getPageController() {
        DXOperationController controller = new DXOperationController();
        return controller;
    }
}