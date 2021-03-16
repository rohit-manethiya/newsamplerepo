@IsTest
private with sharing class Test_DW_OverrideFiltersExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_OverrideFilter page and click on "Back" button
     */
    @IsTest
    static void overrideFilterBack() {
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

            PageReference pReference = Page.DW_OverrideFilters;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverrideFiltersExtension controller = new DW_OverrideFiltersExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deployment.Id;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(false, urlContainsParameter);

            PageReference returnedPage = componentController.goToPreviousStep();
            PageReference expectedPage = Page.DW_SelectDataTemplate;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_OverrideFilter page and add new filter value and click on save and close button
     */
    @IsTest
    static void overrideFilterAddNewFilterAndSave() {
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

            PageReference pReference = Page.DW_OverrideFilters;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverrideFiltersExtension controller = new DW_OverrideFiltersExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deployment.Id;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(false, urlContainsParameter);

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

            PageReference returnedPage = componentController.saveFiltersAndClose();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            List<Step__c> steList = [SELECT dataJson__c FROM Step__c WHERE Deployment__c = :componentController.deploymentId LIMIT 1];
            String dataJson = steList[0].dataJson__c;
            System.assert(String.isNotBlank(dataJson));
            Test.stopTest();
        }
    }

    /**
     * Open the DW_OverrideFilter page and add new filter value and click on confirm filter button
     */
    @IsTest
    static void overrideFilterAddNewFilterAndGoNextStep() {
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

            PageReference pReference = Page.DW_OverrideFilters;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverrideFiltersExtension controller = new DW_OverrideFiltersExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deployment.Id;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(false, urlContainsParameter);

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

            PageReference returnedPage = componentController.confirmAndGoOverview();
            PageReference expectedPage = Page.DW_Overview;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_OverrideFilter page
     * Remove one of the existing filter
     * Reset the filters
     * Change one of the existing filter values
     * Click on save and close button
     */
    @IsTest
    static void overrideFilterRemoveFilterResetAndSave() {
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

            PageReference pReference = Page.DW_OverrideFilters;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverrideFiltersExtension controller = new DW_OverrideFiltersExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            //Instantiate and construct the controller class of component.
            OverrideFiltersComponentController componentController = new OverrideFiltersComponentController();
            componentController.deploymentId = controller.deployment.Id;
            System.assertEquals(deployment.Id, componentController.deploymentId);
            System.assertEquals(null, componentController.stepId);
            System.assertEquals(null, componentController.taskId);
            System.assertEquals(true, componentController.enableADD);
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());
            System.assertEquals(6, componentController.mainCriteriaWrappers.size());

            Boolean urlContainsParameter = componentController.getURLParameters();
            System.assertEquals(false, urlContainsParameter);

            pReference.getParameters().put('criteriaOrder', '2');
            componentController.removeCriteria();
            System.assertEquals(5, componentController.temporaryCriteriaWrappers.size());

            componentController.resetFilterValues();
            System.assertEquals(6, componentController.temporaryCriteriaWrappers.size());

            componentController.temporaryCriteriaWrappers[0].input = 'Test-modified';

            PageReference returnedPage = componentController.saveFiltersAndClose();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            List<Step__c> steList = [SELECT dataJson__c FROM Step__c WHERE Deployment__c = :componentController.deploymentId LIMIT 1];
            String dataJson = steList[0].dataJson__c;
            System.assert(String.isNotBlank(dataJson));

            Test.stopTest();
        }
    }
}