@IsTest
private class Test_DW_SelectDataTemplateExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_SelectDataTemplate page and click on "Back" button
     */
    @IsTest
    static void selectDataTemplatesBack() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectDataTemplate';
            insert deployment;

            // Data Template creation
            Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('Test Data Template', 'Account', '1', orgList[2].Id);
            insert dataTemplate;

            PageReference pReference = Page.DW_SelectDataTemplate;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectDataTemplateExtension controller = new DW_SelectDataTemplateExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_Target;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(urlContains, true);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectDataTemplate page and click on "Save & Close" button
     */
    @IsTest
    static void selectDataTemplatesSaveAndClose() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectDataTemplate';
            insert deployment;

            // Data Template creation
            Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('Test Data Template', 'Account', '1', orgList[2].Id);
            insert dataTemplate;

            PageReference pReference = Page.DW_SelectDataTemplate;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectDataTemplateExtension controller = new DW_SelectDataTemplateExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.saveStepAndClose();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                sw.isSelected = true;
            }

            returnedPage = controller.saveStepAndClose();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectDataTemplate page and click on "Review Filter" button
     */
    @IsTest
    static void selectDataTemplatesConfirmAndGoNextStep() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectDataTemplate';
            insert deployment;

            // Data Template creation
            Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('Test Data Template', 'Account', '1', orgList[2].Id);
            insert dataTemplate;

            PageReference pReference = Page.DW_SelectDataTemplate;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectDataTemplateExtension controller = new DW_SelectDataTemplateExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.saveStepAndClose();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                sw.isSelected = true;
            }

            returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_OverrideFilters;
            expectedPage.getParameters().put('id', controller.deployment.Id);

            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectDataTemplate page with existing
     */
    @IsTest
    static void openSelectDataTemplatesWithExistingDataAndSave() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Data Template creation
            Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('Test Data Template', 'Account', '1', orgList[2].Id);
            Data_Template__c dataTemplate1 = TestDataFactory.createDataTemplate('Test Data Template 1', 'Contact', '1', orgList[2].Id);
            insert new List<Data_Template__c>{ dataTemplate, dataTemplate1 };

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_SelectDataTemplate';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destOrg;

            DeploymentHelper.StepAttachmentDetails sad = new DeploymentHelper.StepAttachmentDetails();
            sad.dataTemplateId = dataTemplate.Id;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not Started', 1, null, JSON.serialize(sad));
            insert step;

            // Attachment creation
            Attachment att = TestDataFactory.createAttachment('Data Template', step.Id, JSON.serialize(sad));
            insert att;

            PageReference pReference = Page.DW_SelectDataTemplate;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectDataTemplateExtension controller = new DW_SelectDataTemplateExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                sw.isSelected = sw.template.Name == 'Test Data Template' ? false : true;
            }

            PageReference returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_OverrideFilters;
            expectedPage.getParameters().put('id', controller.deployment.Id);

            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_SelectDataTemplate page and click on "Confirm Selection" button
     */
    @IsTest
    static void selectDataTemplatesGoOverview() {
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
            deployment.Deployment_Last_Step__c = 'DW_SelectDataTemplate';
            insert deployment;

            // Data Template creation
            Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('Test Data Template', 'Account', '1', orgList[2].Id);
            insert dataTemplate;

            PageReference pReference = Page.DW_SelectDataTemplate;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SelectDataTemplateExtension controller = new DW_SelectDataTemplateExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(2, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            PageReference returnedPage = controller.saveStepAndClose();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for (DeploymentHelper.SourceWrapper sw : controller.sourceList) {
                sw.isSelected = true;
            }

            returnedPage = controller.confirmAndGoOverride();
            PageReference expectedPage = Page.DW_Overview;
            expectedPage.getParameters().put('id', controller.deployment.Id);

            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }
}