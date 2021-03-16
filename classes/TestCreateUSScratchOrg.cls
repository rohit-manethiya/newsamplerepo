@IsTest
private class TestCreateUSScratchOrg {
    private static final String jsonfile = '{"features":["Communities","ServiceCloud","Chatbot"],"settings":{"orgPreferenceSettings":{"networksEnabled":true,"s1DesktopEnabled":true,"s1EncryptedStoragePref2":false},"omniChannelSettings":{"enableOmniChannel":true},"caseSettings":{"systemUserEmail":"support@acme.com"}}}';
    private static final String orgDefinitionfile = '{"orgName":"Acme","edition":"Enterprise","features":["Communities","ServiceCloud","Chatbot"],"settings":{"orgPreferenceSettings":{"networksEnabled":true,"s1DesktopEnabled":true,"s1EncryptedStoragePref2":false},"omniChannelSettings":{"enableOmniChannel":true},"caseSettings":{"systemUserEmail":"support@acme.com"}}}';

    @TestSetup
    static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @IsTest
    static void createUserStoryScratchOrg() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        List<String> orgNameStrings = new List<String>{ 'Dev Hub 1', 'Scratch Org Branch' };
        String devHub;
        List<Org__c> orgList = [SELECT Id, Name, Developer_Hub_Org__c, is_Developer_Hub_Org__c FROM Org__c WHERE Name = :orgNameStrings];
        for (Org__c orgCred : orgList) {
            if (orgCred.is_Developer_Hub_Org__c) {
                devHub = orgCred.Id;
                break;
            }
        }
        for (Org__c orgCred : orgList) {
            if (!orgCred.is_Developer_Hub_Org__c) {
                orgCred.Developer_Hub_Org__c = devHub;
                break;
            }
        }
        update orgList;

        User_Story__c us = [SELECT Id, Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Create test run
        Test_Script__c testScript = new Test_Script__c();
        testScript.User_Story__c = us.Id;
        insert testScript;

        Test_Run__c testRun = new Test_Run__c();
        testRun.User_Story__c = us.Id;
        testRun.Test_Script__c = testScript.Id;
        insert testRun;

        Test_Run__c testRunObject = [
            SELECT
                Id,
                Name,
                Test_Script__r.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Test_Script__r.User_Story__r.Project__r.Deployment_Flow__c,
                Test_Script__r.User_Story__r.Project__c,
                Test_Script__r.User_Story__r.Org_Credential__c,
                Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c
            FROM Test_Run__c
            WHERE Id = :testRun.Id
            LIMIT 1
        ];
        Attachment att = new Attachment();
        att.ParentId = testRunObject.Test_Script__r.User_Story__r.Org_Credential__c;
        att.Name = DXLabel.DEFINITION_FILE;
        att.Body = Blob.valueOf(orgDefinitionfile);
        insert att;

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'branch';
        //somcController.showPatchOptions = false;

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        //Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name =: 'Dev Hub 1'];
        socController.setDevHubOrgId(devHub);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c = :gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE', controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');
        soecController.sourceOrgId = devHub;
        soecController.populateDeployments();
        //soecController.selectedDeploymentId = [SELECT Id FROM Deployment__c WHERE Name = 'Dev1 Deployment' LIMIT 1].Id;
        soecController.addToExtensions();

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');
        soccController.tRun = testRunObject;

        Test.startTest();
        MockHttpResponseGenerator fullScratchOrgFakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fullScratchOrgFakeResponse);

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();
        controller.nextStepOrgTemplate();
        controller.fullCreateCompleted();

        Test.stopTest();
    }

    @IsTest
    static void createUserStoryScratchOrgWithExtension() {
        PageReference pageRef = Page.CreateUserStoryScratchOrg;
        Test.setCurrentPage(pageRef);

        List<String> orgNameStrings = new List<String>{ 'Dev Hub 1', 'Scratch Org Branch' };
        String devHub;
        List<Org__c> orgList = [SELECT Id, Name, Developer_Hub_Org__c, is_Developer_Hub_Org__c FROM Org__c WHERE Name = :orgNameStrings];
        for (Org__c orgCred : orgList) {
            if (orgCred.is_Developer_Hub_Org__c) {
                devHub = orgCred.Id;
                break;
            }
        }
        for (Org__c orgCred : orgList) {
            if (!orgCred.is_Developer_Hub_Org__c) {
                orgCred.Developer_Hub_Org__c = devHub;
                break;
            }
        }
        update orgList;

        User_Story__c userStory = [SELECT Id, Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];
        pageRef.getParameters().put('Id', userStory.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(userStory);

        Attachment att = new Attachment();
        att.ParentId = userStory.Org_Credential__c;
        att.Name = DXLabel.DEFINITION_FILE;
        att.Body = Blob.valueOf(orgDefinitionfile);
        insert att;

        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);
        controller.getChildComponentController();

        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'branch';

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');
        socController.orgTemplate.setOrgName('FO test');
        socController.setDevHubOrgId(devHub);

        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__r.Name = 'git 1'];

        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE', controller.definition);
        controller.previousStep();
        controller.nextStep();

        Test.startTest();
        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');
        soecController.sourceOrgId = devHub;
        soecController.populateDeployments();
        soecController.selectedDeploymentId = [SELECT Id FROM Deployment__c WHERE Name = 'Deployment' LIMIT 1].Id;
        soecController.addToExtensions();
        Test.stopTest();

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        MockHttpResponseGenerator fullScratchOrgFakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fullScratchOrgFakeResponse);

        soccController.createFullScratchOrg();
        ApexPages.currentPage().getParameters().put('csvPerm', '');
        controller.fullCreateCompleted();
    }

    @IsTest
    static void createUserStoryScratchOrgUnlockedPackage() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id, Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'unlocked'; //Old value "unlockPackage"
        //somcController.showPatchOptions = false;

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep(); //

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        //socController.mergeArtifactOrgDefinitionDependencies();

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c = :gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE', controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest
    static void createUserStoryScratchOrgArtifact() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id, Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];
        Artifact__c at = [SELECT Id FROM Artifact__c WHERE Name = 'StaticResources2' LIMIT 1];

        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'artifact';

        somcController.setSourceSelections(at.Id);

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep(); //

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');
        ScratchOrgDefinition orgTemplate = socController.orgTemplate;

        Attachment orgDefinitionDependency = new Attachment();
        orgDefinitionDependency.ParentId = at.Id;
        orgDefinitionDependency.Body = Blob.valueOf(jsonfile);
        orgDefinitionDependency.Name = DXLabel.DEFINITION_FILE;
        insert orgDefinitionDependency;

        //socController.mergeArtifactOrgDefinitionDependencies();
        socController.orgTemplate.setOrgName('FO test');

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c = :gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE', controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest
    static void createUserStoryScratchOrgPatch() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id, Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = :'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'patch';

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep(); //

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name = :'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name = :'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c = :gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE', controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest
    static void scratchOrgOpen() {
        PageReference pageRef = Page.ScratchOrgOpen;

        Test.setCurrentPage(pageRef);

        ScratchOrgOpen sooController = new ScratchOrgOpen();
        sooController.rScratchOrgJob();
        System.assert(sooController.copadoJobFinished, 'copadoJobFinished should be true');
        System.assertEquals(ApexPages.getMessages()[0].getDetail(), Label.ORG_CREDENTIAL_NOT_COMPLETED, 'Execution should report org credential not completed');

        sooController.soId = 'test';
        sooController.rScratchOrgJob();
        System.assert(sooController.copadoJobFinished, 'copadoJobFinished should be true');
        System.assertEquals(ApexPages.getMessages()[1].getDetail(), 'Org Credential does not exist or is not accessible', 'Execution should report org credential does not exist');

        Org__c orgScratch = [SELECT Id, Environment__c FROM Org__c WHERE Name = :'Scratch Org 1'];

        Copado_Notification__c cn = new Copado_Notification__c();
        cn.Type__c = CopadoNotificationHelper.DX_OPEN_ORG;
        cn.OwnerId = UserInfo.getUserId();
        cn.isFinished__c = true;
        cn.ParentId__c = orgScratch.Id;
        cn.Matching_Key__c = 'test';
        insert cn;

        Attachment att = new Attachment();
        att.ParentId = orgScratch.Id;
        att.Name = 'AccessUrl.txt';
        att.Body = Blob.valueOf(DeployAPI.encryptAPIKey('https://www.salesforce.com/home/home.jsp'));
        insert att;

        pageRef.getParameters().put('id', orgScratch.Id);

        sooController.soId = orgScratch.Id;

        Test.startTest();
        MockHttpResponseGenerator fakeResponseCopadoWithoutId = new MockHttpResponseGenerator(200, 'Complete', '{"copadoJobId":"","ok":"AccessUrl Valid","status":"","error":""}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoWithoutId);
        PageReference pr = sooController.rScratchOrgJob();
        System.assert(sooController.copadoJobFinished, 'copadoJobFinished should be true');
        System.assertEquals('https://www.salesforce.com/home/home.jsp', pr.getUrl(), 'PageReference URL should match');
        MockHttpResponseGenerator fakeResponseCopadoWithId = new MockHttpResponseGenerator(200, 'Complete', '{"copadoJobId":"test","ok":"AccessUrl Valid","status":"","error":""}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoWithId);
        sooController.rScratchOrgJob();
        System.assert(!sooController.copadoJobFinished, 'copadoJobFinished should be false');
        sooController.rScratchOrgJob();
        System.assert(sooController.copadoJobFinished, 'copadoJobFinished should be true');
        System.assertEquals(ApexPages.getMessages()[2].getDetail(), 'Could not open scratch org', 'Execution should report org could not open');
        Test.stopTest();
    }

    // Those method are never used, because they are overwritten.
    @IsTest
    static void overWrittenMethods() {
        Test.startTest();
        ScratchOrgWizardPageBase scowpb = new ScratchOrgWizardPageBase();
        ScratchOrgWizardComponentBase controller = scowpb.getChildComponentController();
        scowpb.getThis();

        scowpb.setComponentControllerMap('ScratchOrgComponent', controller);
        Map<String, ScratchOrgWizardComponentBase> testScowpb = scowpb.getComponentControllerMap();
        Test.stopTest();
    }

    @IsTest
    static void jobStatusNotificationError() {
        setCurrentPage();
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
        ApexPages.currentPage().getParameters().put('jobType', 'DxCreateFullScratchOrgJob');
        ApexPages.currentPage().getParameters().put('jobMessage', 'Error during job execution');

        CreateUserStoryScratchOrgController controller = getPageController();

        Test.startTest();
        PageReference actualPage = controller.jobStatusNotification();
        Test.stopTest();

        String expectedJobMessage = 'Error during job execution';
        String actualJobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        System.assert(actualPage == null, 'When an error in the job occurs, the user must not be redirected from the current page.');
        System.assertEquals(expectedJobMessage, actualJobMessage, 'The redirect URL for the target page is not correct.');
    }

    private static void setCurrentPage() {
        PageReference page = Page.TestRunScratchOrg;
        Test.setCurrentPage(page);
    }

    private static CreateUserStoryScratchOrgController getPageController() {
        User_Story__c userStory = [SELECT Name, Org_Credential__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE User_Story_Title__c = 'Test User Story' LIMIT 1];
        ApexPages.StandardController controller = new ApexPages.StandardController(userStory);
        CreateUserStoryScratchOrgController extension = new CreateUserStoryScratchOrgController(controller);
        return extension;
    }
}