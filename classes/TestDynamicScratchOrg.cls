@IsTest
public class TestDynamicScratchOrg {
    @TestSetup
    static void setup() {
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        createTestData();
    }

    @IsTest
    static void testRunOperation() {
        setCurrentPage();

        Test.startTest();
        DynamicScratchOrgController controller = getPageController();
        Test.stopTest();

        Id credentialId = controller.testRun.Test_Script__r.User_Story__r.Org_Credential__c;
        String projectJSON = getAttachmentJSON(credentialId, DXLabel.PROJECT_FILE).replaceAll('"package":', '"packageName":').replaceAll('"default":', '"defaultArtifact":');
        DXProject expectedProject = (DXProject) JSON.deserialize(projectJson, DXProject.class);
        DXProject actualProject = controller.getArtifactProject();
        System.assertEquals(expectedProject.getNamespace(), actualProject.getNamespace(), 'The DX Project namespace does not match the original namespace from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getSfdcLoginUrl(), actualProject.getSfdcLoginUrl(), 'The DX Project login URL does not match the original login URL from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getSourceApiVersion(), actualProject.getsourceApiVersion(), 'The DX Project API version does not match the original API version from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getPackageDirectories().size(), actualProject.getPackageDirectories().size(), 'The DX Project directories do not match the original directories from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getPackageAliases().size(), actualProject.getPackageAliases().size(), 'The DX Project aliases do not match the original alises from the org credential attachment (sfdx-project.json).');

        String orgDefinitionJSON = getAttachmentJSON(credentialId, DXLabel.DEFINITION_FILE);
        ScratchOrgDefinition expectedDefinition = (ScratchOrgDefinition) JSON.deserialize(orgDefinitionJSON, ScratchOrgDefinition.class);
        ScratchOrgDefinition actualDefinition = controller.getOrgTemplate();
        System.assertEquals(controller.testRun.Name + ' Scratch Org', actualDefinition.getOrgName(), 'The Scratch Org name does not match the original org name from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getCountry(), actualDefinition.getCountry(), 'The Scratch Org country does not match the original country from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getUserName(), actualDefinition.getUserName(), 'The Scratch Org username does not match the original username from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getAdminEmail(), actualDefinition.getAdminEmail(), 'The Scratch Org admin email does not match the original admin email from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getEdition(), actualDefinition.getEdition(), 'The Scratch Org edition does not match the original edition from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getDescription(), actualDefinition.getDescription(), 'The Scratch Org description does not match the original description from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getHasSampleData(), actualDefinition.getHasSampleData(), 'The Scratch Org sample data flag does not match the original sample data flag from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getLanguage(), actualDefinition.getLanguage(), 'The Scratch Org language does not match the original language from the org credential attachment (project-scratch-def.json).');
    }

    @IsTest
    static void loadReviewData() {
        setCurrentPage();

        DynamicScratchOrgController controller = getPageController();
        controller.setComponentControllerMap('ScratchOrgCompletion', new ScratchOrgCompletionController());

        Test.startTest();
        controller.loadReviewData();
        Test.stopTest();

        ScratchOrgCompletionController completionController = ((ScratchOrgCompletionController) controller.getComponentController('ScratchOrgCompletion'));
        System.assertEquals(controller.testRun.Id, completionController.parentId, 'The parent (Test Run) Id was not correctly passed to the Scratch Org Completion controller.');
        System.assertEquals(controller.getDevHubOrgId(), completionController.getDevHubOrgId(), 'The Dev Hub org Id was not correctly passed to the Scratch Org Completion controller.');
        System.assertEquals(false, completionController.showPermissionsPanel, 'The permissions panel flag was not correctly set from the Dynamic Scratch Org controller.');
        System.assertEquals(controller.sourceBranch, completionController.sourceBranch, 'The source branch was not correctly passed to the Scratch Org Completion controller.');
        System.assertEquals(false, completionController.showSetup, 'The setup flag was not correctly set from the Dynamic Scratch Org controller.');

        DXProject expectedProject = controller.getArtifactProject();
        DXProject actualProject = completionController.artifactProject;
        System.assertEquals(expectedProject.getNamespace(), actualProject.getNamespace(), 'The DX Project namespace does not match the original namespace from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getSfdcLoginUrl(), actualProject.getSfdcLoginUrl(), 'The DX Project login URL does not match the original login URL from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getSourceApiVersion(), actualProject.getsourceApiVersion(), 'The DX Project API version does not match the original API version from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getPackageDirectories().size(), actualProject.getPackageDirectories().size(), 'The DX Project directories do not match the original directories from the org credential attachment (sfdx-project.json).');
        System.assertEquals(expectedProject.getPackageAliases().size(), actualProject.getPackageAliases().size(), 'The DX Project aliases do not match the original alises from the org credential attachment (sfdx-project.json).');

        ScratchOrgDefinition expectedDefinition = controller.getOrgTemplate();
        ScratchOrgDefinition actualDefinition = completionController.orgDefinition;
        System.assertEquals(controller.testRun.Name + ' Scratch Org', actualDefinition.getOrgName(), 'The Scratch Org name does not match the original org name from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getCountry(), actualDefinition.getCountry(), 'The Scratch Org country does not match the original country from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getUserName(), actualDefinition.getUserName(), 'The Scratch Org username does not match the original username from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getAdminEmail(), actualDefinition.getAdminEmail(), 'The Scratch Org admin email does not match the original admin email from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getEdition(), actualDefinition.getEdition(), 'The Scratch Org edition does not match the original edition from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getDescription(), actualDefinition.getDescription(), 'The Scratch Org description does not match the original description from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getHasSampleData(), actualDefinition.getHasSampleData(), 'The Scratch Org sample data flag does not match the original sample data flag from the org credential attachment (project-scratch-def.json).');
        System.assertEquals(expectedDefinition.getLanguage(), actualDefinition.getLanguage(), 'The Scratch Org language does not match the original language from the org credential attachment (project-scratch-def.json).');
    }

    @IsTest
    static void jobStatusNotificationSuccess() {
        setCurrentPage();
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobType', 'DxCreateFullScratchOrgJob');

        DynamicScratchOrgController controller = getPageController();

        Test.startTest();
        PageReference actualPage = controller.jobStatusNotification();
        Test.stopTest();

        PageReference expectedPage = Page.DXTestOrgIntermediary;
        expectedPage.getParameters().put('id', controller.testRun.Id);

        System.assertEquals(expectedPage.getParameters().get('id'), actualPage.getParameters().get('id'), 'The Test Run Id was not set as a URL parameter for the target page.');
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The redirect URL for the target page is not correct.');
    }

    @IsTest
    static void jobStatusNotificationError() {
        setCurrentPage();
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
        ApexPages.currentPage().getParameters().put('jobType', 'DxCreateFullScratchOrgJob');
        ApexPages.currentPage().getParameters().put('jobMessage', 'Error during job execution');

        DynamicScratchOrgController controller = getPageController();

        Test.startTest();
        PageReference actualPage = controller.jobStatusNotification();
        Test.stopTest();

        String expectedJobMessage = 'Error during job execution';
        String actualJobMessage = ApexPages.getMessages()[0].getDetail();
        System.assert(actualPage == null, 'When an error in the job occurs, the user must not be redirected from the current page.');
        System.assertEquals(expectedJobMessage, actualJobMessage, 'The redirect URL for the target page is not correct.');
    }

    private static void createTestData() {
        List<Environment__c> environments = new List<Environment__c>();
        Environment__c devHubEnvironment = CMTestMethodUtilities.createEnvironment('DEV-HUB-13', '000000000000000001');
        environments.add(devHubEnvironment);
        Environment__c environment = CMTestMethodUtilities.createEnvironment('DEV-13', '000000000000000000');
        environments.add(environment);
        insert environments;

        Org__c devHubCredential = CMTestMethodUtilities.createOrg('DEV-13', 'Production', '000000000000000001', null, null, System.now(), devHubEnvironment.Id);
        devHubCredential.is_Developer_Hub_Org__c = true;
        insert devHubCredential;
        Org__c credential = CMTestMethodUtilities.createOrg('DEV-13', 'Scratch Org', '000000000000000000', null, null, System.now(), environment.Id);
        credential.Developer_Hub_Org__c = devHubCredential.Id;
        insert credential;
        
        List<Attachment> attachments = new List<Attachment>();
        Attachment definitionFile = new Attachment();
        definitionFile.Name = DXLabel.DEFINITION_FILE;
        definitionFile.Body = Blob.valueOf('{"adminEmail" : "rtoro@copa.do", "country" : "US","description" : "","edition" : "Developer","hasSampleData" : false,"language" : "en_US","orgName" : "SO-0019648","username" : "","features" : [ ],"settings" : { }}');
        definitionFile.ParentId = credential.Id;
        attachments.add(definitionFile);
        Attachment projectFile = new Attachment();
        projectFile.Name = DXLabel.PROJECT_FILE;
        projectFile.Body = Blob.valueOf('{"sourceApiVersion":"45.0","sfdcLoginUrl":"https://login.salesforce.com","packageDirectories":[{"path":"force-app","definitionFile":"config/project-scratch-def.json","default":true},{"path":"RT_19.11","definitionFile":"config/project-scratch-def.json","default":false}],"namespace":""}');
        projectFile.ParentId = credential.Id;
        attachments.add(projectFile);
        insert attachments;

        User_Story__c userStory = CMTestMethodUtilities.createUserStory('Test DynamicScratchOrgController');
        userStory.Org_Credential__c = credential.Id;
        insert userStory;

        Test_Script__c script = CMTestMethodUtilities.createTestScript('Test DynamicScratchOrgController from apex code');
        script.User_Story__c = userStory.Id;
        insert script;

        Test_Run__c testRun = CMTestMethodUtilities.createTestRun(script.Id);
        testRun.User_Story__c = userStory.Id;
        insert testRun;
    }

    private static void setCurrentPage() {
        PageReference page = Page.TestRunScratchOrg;
        Test.setCurrentPage(page);
    }

    private static DynamicScratchOrgController getPageController() {
        Test_Run__c testRun = [SELECT Id FROM Test_Run__c WHERE User_Story__r.User_Story_Title__c = 'Test DynamicScratchOrgController' LIMIT 1];
        ApexPages.StandardController controller = new ApexPages.StandardController(testRun);
        DynamicScratchOrgController extension = new DynamicScratchOrgController(controller);
        return extension;
    }

    private static String getAttachmentJSON(Id parentId, String name) {
        Attachment attachment = [SELECT Body FROM Attachment WHERE ParentId = :parentId AND Name = :name LIMIT 1];
        String attachmentJSON = attachment.Body.toString();
        return attachmentJSON;
    }
}