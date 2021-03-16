@IsTest
public with sharing class Test_DW_SummaryExtension {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the DW_Summary page and click on "Start New Deployment" button
     */
    @IsTest
    static void summaryStartNewDeployment() {
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
            deployment.Deployment_Last_Step__c = 'DW_Summary';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Completed Successfully', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Summary;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SummaryExtension controller = new DW_SummaryExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(5, controller.currentStepValue);

            PageReference returnedPage = controller.startNewDeployment();
            PageReference expectedPage = Page.DW_Intermediary;
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Summary page and click on "Clone" button
     */
    @IsTest
    static void summaryClone() {
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
            deployment.Deployment_Last_Step__c = 'DW_Summary';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Completed Successfully', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Summary;
            pReference.getParameters().put('deploymentActionType', 'deployment');
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_SummaryExtension controller = new DW_SummaryExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(5, controller.currentStepValue);

            PageReference returnedPage = controller.deepCloneDeployment();

            String clonedDeploymentId = '';
            for (Deployment__c dep : [SELECT Id FROM Deployment__c LIMIT 2]) {
                if (dep.Id != controller.deployment.Id) {
                    clonedDeploymentId = dep.Id;
                }
            }
            PageReference expectedPage = Page.DW_Source;
            expectedPage.getParameters().put('id', clonedDeploymentId);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }
}