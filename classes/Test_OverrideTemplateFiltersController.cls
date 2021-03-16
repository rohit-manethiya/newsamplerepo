@IsTest
private with sharing class Test_OverrideTemplateFiltersController {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the OverrideTemplateFilters page and click on "Back" button
     * In this condition we will open page from advanced deployment step
     */
    @IsTest
    static void overrideFilterFromStepAndGoBack() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Main Account Template FO',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            Data_Template__c dt1 = TestDataFactory.createDataTemplate('FO Copado', 'FO_Copado__c', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt2 = TestDataFactory.createDataTemplate('Parent Account', 'Account', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt3 = TestDataFactory.createDataTemplate('Contact', 'Contact', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt4 = TestDataFactory.createDataTemplate(
                'Opportunity',
                'Opportunity',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            insert new List<Data_Template__c>{ dt, dt1, dt2, dt3, dt4 };

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            DeploymentHelper.StepAttachmentDetails sad = new DeploymentHelper.StepAttachmentDetails();
            sad.dataTemplateId = dt.Id;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not Started', 1, null, JSON.serialize(sad));
            insert step;

            // Attachment creation
            Attachment att3 = TestDataFactory.createAttachment('Data Template', step.Id, JSON.serialize(sad));

            String newAttBody = Test_DataTemplateSetupExtension.updateAttachmentBodyForNewTemplateIds(
                dt.Id,
                dt1.Id,
                dt2.Id,
                dt3.Id,
                dt4.Id,
                orgList[2].Id
            );

            Attachment att = TestDataFactory.createAttachment('Template Detail', dt.Id, newAttBody);
            Attachment att1 = TestDataFactory.createAttachment(
                'ADD_Describe_Global_Result',
                orgList[2].Id,
                Test_DataTemplateSetupExtension.orgJobResponse
            );
            Attachment att2 = TestDataFactory.createAttachment(
                'ADD_Describe_SObject_Result',
                dt.Id,
                Test_DataTemplateSetupExtension.objectJobResponseAfterRefresh
            );
            insert new List<Attachment>{ att, att1, att2, att3 };

            PageReference pReference = Page.OverrideTemplateFilters;
            pReference.getParameters().put('deploymentId', deployment.Id);
            pReference.getParameters().put('stepId', step.Id);
            Test.setCurrentPage(pReference);

            OverrideTemplateFiltersController controller = new OverrideTemplateFiltersController();
            System.assertEquals(deployment.Id, controller.deploymentId);
            System.assertEquals(step.Id, controller.stepId);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deploymentId;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(step.Id, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(true, urlContainsParameter);

            pReference.getParameters().put('action', 'justGo');
            PageReference returnedPage = componentController.saveFiltersAndGoToRecord();
            PageReference expectedPage = Page.Deployment;
            expectedPage.getParameters().put('id', componentController.deploymentId);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the OverrideTemplateFilters page and add new filter value and click on save
     * In this condition we will open page from advanced deployment step
     */
    @IsTest
    static void overrideFilterFromStepAddNewFilterAndSave() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Main Account Template FO',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            Data_Template__c dt1 = TestDataFactory.createDataTemplate('FO Copado', 'FO_Copado__c', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt2 = TestDataFactory.createDataTemplate('Parent Account', 'Account', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt3 = TestDataFactory.createDataTemplate('Contact', 'Contact', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt4 = TestDataFactory.createDataTemplate(
                'Opportunity',
                'Opportunity',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            insert new List<Data_Template__c>{ dt, dt1, dt2, dt3, dt4 };

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            DeploymentHelper.StepAttachmentDetails sad = new DeploymentHelper.StepAttachmentDetails();
            sad.dataTemplateId = dt.Id;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not Started', 1, null, JSON.serialize(sad));
            insert step;

            // Attachment creation
            Attachment att3 = TestDataFactory.createAttachment('Data Template', step.Id, JSON.serialize(sad));

            String newAttBody = Test_DataTemplateSetupExtension.updateAttachmentBodyForNewTemplateIds(
                dt.Id,
                dt1.Id,
                dt2.Id,
                dt3.Id,
                dt4.Id,
                orgList[2].Id
            );

            Attachment att = TestDataFactory.createAttachment('Template Detail', dt.Id, newAttBody);
            Attachment att1 = TestDataFactory.createAttachment(
                'ADD_Describe_Global_Result',
                orgList[2].Id,
                Test_DataTemplateSetupExtension.orgJobResponse
            );
            Attachment att2 = TestDataFactory.createAttachment(
                'ADD_Describe_SObject_Result',
                dt.Id,
                Test_DataTemplateSetupExtension.objectJobResponseAfterRefresh
            );
            insert new List<Attachment>{ att, att1, att2, att3 };

            PageReference pReference = Page.OverrideTemplateFilters;
            pReference.getParameters().put('deploymentId', deployment.Id);
            pReference.getParameters().put('stepId', step.Id);
            Test.setCurrentPage(pReference);

            OverrideTemplateFiltersController controller = new OverrideTemplateFiltersController();
            System.assertEquals(deployment.Id, controller.deploymentId);
            System.assertEquals(step.Id, controller.stepId);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deploymentId;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(step.Id, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(true, urlContainsParameter);

            componentController.addNewCriteria();
            System.assertEquals(7, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            List<SelectOption> filterFieldsList = componentController.getAllFieldsAPIName();
            System.assertEquals(69, filterFieldsList.size());

            List<SelectOption> operatorsList = componentController.setOperators();
            System.assertEquals(13, operatorsList.size());

            componentController.temporaryCriteriaWrappers[6].fieldName = 'Test - AccountNumber';
            pReference.getParameters().put('cro', '7');
            componentController.getFieldOperators();
            componentController.temporaryCriteriaWrappers[6].input = 'Test';
            System.assertEquals(6, componentController.temporaryCriteriaWrappers[6].operatorSet.size());

            pReference.getParameters().put('action', 'saveAndGo');
            PageReference returnedPage = componentController.saveFiltersAndGoToRecord();
            PageReference expectedPage = Page.Deployment;
            expectedPage.getParameters().put('id', componentController.deploymentId);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the OverrideTemplateFilters page and click on "Back" button
     * In this condition we will open page from deployment task
     */
    @IsTest
    static void overrideFilterFromTaskAndGoBack() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Main Account Template FO',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            Data_Template__c dt1 = TestDataFactory.createDataTemplate('FO Copado', 'FO_Copado__c', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt2 = TestDataFactory.createDataTemplate('Parent Account', 'Account', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt3 = TestDataFactory.createDataTemplate('Contact', 'Contact', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt4 = TestDataFactory.createDataTemplate(
                'Opportunity',
                'Opportunity',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            insert new List<Data_Template__c>{ dt, dt1, dt2, dt3, dt4 };

            String newAttBody = Test_DataTemplateSetupExtension.updateAttachmentBodyForNewTemplateIds(
                dt.Id,
                dt1.Id,
                dt2.Id,
                dt3.Id,
                dt4.Id,
                orgList[2].Id
            );

            Attachment att = TestDataFactory.createAttachment('Template Detail', dt.Id, newAttBody);
            Attachment att1 = TestDataFactory.createAttachment(
                'ADD_Describe_Global_Result',
                orgList[2].Id,
                Test_DataTemplateSetupExtension.orgJobResponse
            );
            Attachment att2 = TestDataFactory.createAttachment(
                'ADD_Describe_SObject_Result',
                dt.Id,
                Test_DataTemplateSetupExtension.objectJobResponseAfterRefresh
            );
            insert new List<Attachment>{ att, att1, att2 };

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                envList[0].Id,
                envList[2].Id,
                deploymentFlow.Id,
                ''
            );
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                envList[1].Id,
                envList[2].Id,
                deploymentFlow.Id,
                ''
            );
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, envList[0].Id, orgList[0].Id);
            insert userStory;

            // Deployment Task creation
            Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('override filter', 1, 'Data Template', 'Draft', userStory.Id);
            deploymentTask.dataJson__c = '{"dataTemplateName":"' + dt.Name + '","dataTemplateId":"' + dt.Id + '"}';
            insert deploymentTask;

            PageReference pReference = Page.OverrideTemplateFilters;
            pReference.getParameters().put('taskId', deploymentTask.Id);
            Test.setCurrentPage(pReference);

            OverrideTemplateFiltersController controller = new OverrideTemplateFiltersController();
            System.assertEquals(null, controller.deploymentId);
            System.assertEquals(null, controller.stepId);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deploymentId;
            System.assertEquals(null, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(deploymentTask.Id, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(true, urlContainsParameter);

            pReference.getParameters().put('action', 'justGo');
            PageReference returnedPage = componentController.saveFiltersAndGoToRecord();
            PageReference expectedPage = Page.ViewDeploymentTasks;
            expectedPage.getParameters().put('id', componentController.taskId);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the OverrideTemplateFilters page and add new filter value and click on save
     * In this condition we will open page from deployment task
     */
    @IsTest
    static void overrideFilterFromTaskAddNewFilterAndSave() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Main Account Template FO',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            Data_Template__c dt1 = TestDataFactory.createDataTemplate('FO Copado', 'FO_Copado__c', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt2 = TestDataFactory.createDataTemplate('Parent Account', 'Account', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt3 = TestDataFactory.createDataTemplate('Contact', 'Contact', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt4 = TestDataFactory.createDataTemplate(
                'Opportunity',
                'Opportunity',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            insert new List<Data_Template__c>{ dt, dt1, dt2, dt3, dt4 };

            String newAttBody = Test_DataTemplateSetupExtension.updateAttachmentBodyForNewTemplateIds(
                dt.Id,
                dt1.Id,
                dt2.Id,
                dt3.Id,
                dt4.Id,
                orgList[2].Id
            );

            Attachment att = TestDataFactory.createAttachment('Template Detail', dt.Id, newAttBody);
            Attachment att1 = TestDataFactory.createAttachment(
                'ADD_Describe_Global_Result',
                orgList[2].Id,
                Test_DataTemplateSetupExtension.orgJobResponse
            );
            Attachment att2 = TestDataFactory.createAttachment(
                'ADD_Describe_SObject_Result',
                dt.Id,
                Test_DataTemplateSetupExtension.objectJobResponseAfterRefresh
            );
            insert new List<Attachment>{ att, att1, att2 };

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                envList[0].Id,
                envList[2].Id,
                deploymentFlow.Id,
                ''
            );
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                envList[1].Id,
                envList[2].Id,
                deploymentFlow.Id,
                ''
            );
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, envList[0].Id, orgList[0].Id);
            insert userStory;

            // Deployment Task creation
            Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('override filter', 1, 'Data Template', 'Draft', userStory.Id);
            deploymentTask.dataJson__c = '{"dataTemplateName":"' + dt.Name + '","dataTemplateId":"' + dt.Id + '"}';
            insert deploymentTask;

            PageReference pReference = Page.OverrideTemplateFilters;
            pReference.getParameters().put('taskId', deploymentTask.Id);
            Test.setCurrentPage(pReference);

            OverrideTemplateFiltersController controller = new OverrideTemplateFiltersController();
            System.assertEquals(null, controller.deploymentId);
            System.assertEquals(null, controller.stepId);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deploymentId;
            System.assertEquals(null, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(deploymentTask.Id, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(true, urlContainsParameter);

            componentController.addNewCriteria();
            System.assertEquals(7, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            List<SelectOption> filterFieldsList = componentController.getAllFieldsAPIName();
            System.assertEquals(69, filterFieldsList.size());

            List<SelectOption> operatorsList = componentController.setOperators();
            System.assertEquals(13, operatorsList.size());

            componentController.temporaryCriteriaWrappers[6].fieldName = 'Test - AccountNumber';
            pReference.getParameters().put('cro', '7');
            componentController.getFieldOperators();
            componentController.temporaryCriteriaWrappers[6].input = 'Test';
            System.assertEquals(6, componentController.temporaryCriteriaWrappers[6].operatorSet.size());

            pReference.getParameters().put('action', 'saveAndGo');
            PageReference returnedPage = componentController.saveFiltersAndGoToRecord();
            PageReference expectedPage = Page.ViewDeploymentTasks;
            expectedPage.getParameters().put('id', componentController.taskId);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }
}