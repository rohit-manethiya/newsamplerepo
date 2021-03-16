@IsTest
private with sharing class DeploymentExtTest {
    @TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
            ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        }
        User standardUser = getStandardUser();
        TestUtilities.assignLicense(standardUser.Username, true, true, true);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @IsTest
    private static void testCheckAndValidateFromOrg() {
        Org__c fromOrg = TestMethodUtilities.createOrg('From-Org-1', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert fromOrg;

        Deployment__c deployment = TestMethodUtilities.create('Deployment-1', System.now(), System.now(), fromOrg.Id, 'Deploy now', 'Scheduled');
        insert deployment;

        PageReference thisPage = Page.Deployment;
        thisPage.getParameters().put('id', deployment.id);
        Test.setCurrentPage(thisPage);

        String requestString =
            '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
            fromOrg.sfdc_org_id__c +
            '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(requestString, null));

        System.runAs(getStandardUser()) {
            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            Boolean isOrgCredentialValidated = ext.checkAndValidateFromOrg();
            System.assert(isOrgCredentialValidated, 'The source org credential is validated but the response returns an incorrect value.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testInitDestination() {
        System.runAs(getStandardUser()) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c fromOrg = TestMethodUtilities.createOrg('From-Org-1', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            Org__c toOrg = TestMethodUtilities.createOrg('To-Org-1', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            orgs.add(fromOrg);
            orgs.add(toOrg);
            insert orgs;

            Connection_Behavior__c connectionBehavior = new Connection_Behavior__c();
            connectionBehavior.Name = 'TEST CONNECTION BEHAVIOR';
            insert connectionBehavior;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Active__c = true;
            insert pipeline;

            Deployment_Flow_Step__c connection = new Deployment_Flow_Step__c();
            connection.Deployment_Flow__c = pipeline.Id;
            connection.Connection_Behavior_Override__c = connectionBehavior.Id;
            insert connection;

            Project__c project = new Project__c();
            project.Deployment_Flow__c = pipeline.Id;
            project.Name = 'TEST PROJECT';
            insert project;

            Promotion__c promotion = new Promotion__c();
            promotion.Source_Org_Credential__c = fromOrg.Id;
            promotion.Destination_Org_Credential__c = toOrg.Id;
            promotion.Status__c = 'Draft';
            promotion.Project__c = project.Id;
            insert promotion;

            Deployment__c deployment = TestMethodUtilities.create('Deployment-1', System.now(), System.now(), fromOrg.Id, 'Deploy now', 'Scheduled');
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            Destination_Org__c destinationOrg = TestMethodUtilities.create(deployment.Id, 'Draft', toOrg.Id);
            insert destinationOrg;

            PageReference thisPage = Page.Deployment;
            thisPage.getParameters().put('id', deployment.id);
            Test.setCurrentPage(thisPage);

            String requestString =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                fromOrg.sfdc_org_id__c +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(requestString, null));

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            System.assert(ext.destinations.size() == 1, 'The destination org(s) were not correctly initialized.');
            System.assert(ext.orgId_hasManualConnectionBehaviorMap.containsKey(toOrg.Id), 'Connection Behavior map was not correctly populated.');
            System.assert(ext.ccdEnabled, 'CCD shows as not enabled even though there is a connection behavior on the given pipeline.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testController() {
        System.runAs(getStandardUser()) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);

            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;
            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'MetaData');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;
            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);

            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);

            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);

            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);

            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);

            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);

            insert destinationOrgs;
            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            String b =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                testFromOrg.sfdc_org_id__c +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));
            System.assert(ext.destinations.size() > 1, 'The destination org(s) were not correctly initialized.');

            ext.saveDeployment();
            ext.addDestination();
            ext.saveDestination();
            ext.getJobsManagerMatchingKey();

            System.assert(ext.destinations.size() > 1, 'The destination org(s) were not correctly initialized.');
            System.assert(ext.orgId_hasManualConnectionBehaviorMap.containsKey(testToOrg.Id), 'Connection Behavior map was not correctly populated.');

            // Save again with a destination Org
            ext.destinations[0] = testDestOrg2;
            ext.destinations[1] = testDestOrg3;
            ext.destinations[2] = testDestOrg4;
            ext.destinations[3] = testDestOrg5;
            ext.destinations[4] = testDestOrg6;

            ext.saveDestination();
            ext.fullCloneRedirect();
            ext.sharing();
            ext.addMsgOk('a');
            ext.addMsgError('a');
            ext.getDestinationsJson();
            ext.getStepsJson();
            ext.getDepJson();
            ext.getjsonMessagesQueue();
            ext.deleteDestOrg();
            ext.getHistoryVisible();

            System.assert(ext.destinations.size() > 1, 'The destination org(s) were not correctly initialized.');
            System.assert(!ext.orgId_hasManualConnectionBehaviorMap.isEmpty(), 'Connection Behavior map was not correctly populated.');

            DeploymentExt.sortSteps(new List<String>{ testStep.Id });
            Id stepId = testStep.Id;
            DeploymentExt.deleteStep(testStep.Id);
            List<Step__c> stepList = [SELECT Id FROM Step__c WHERE Id = :stepId];
            System.assert(stepList.isEmpty(), 'Failed to delete selected step.');
            DeploymentExt.getisChatterEnabled();
            Test.stopTest();
        }
    }

    @IsTest
    private static void testSaveDestinationWithPromotion() {
        System.runAs(getStandardUser()) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c fromOrg = TestMethodUtilities.createOrg('From-Org-1', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(fromOrg);
            Org__c toOrg = TestMethodUtilities.createOrg('To-Org-1', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            orgs.add(toOrg);
            insert orgs;

            Connection_Behavior__c connectionBehavior = new Connection_Behavior__c();
            connectionBehavior.Name = 'TEST CONNECTION BEHAVIOR';
            connectionBehavior.Promotion_Behavior__c = 'Manual';
            insert connectionBehavior;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Active__c = true;
            insert pipeline;

            Deployment_Flow_Step__c connection = new Deployment_Flow_Step__c();
            connection.Deployment_Flow__c = pipeline.Id;
            connection.Connection_Behavior_Override__c = connectionBehavior.Id;
            insert connection;

            Project__c project = new Project__c();
            project.Deployment_Flow__c = pipeline.Id;
            project.Name = 'TEST PROJECT';
            insert project;

            Promotion__c promotion = new Promotion__c();
            promotion.Source_Org_Credential__c = fromOrg.Id;
            promotion.Destination_Org_Credential__c = toOrg.Id;
            promotion.Status__c = 'Draft';
            promotion.Project__c = project.Id;
            insert promotion;

            Deployment__c deployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                fromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            Destination_Org__c destinationOrg = TestMethodUtilities.create(deployment.Id, 'Draft', toOrg.Id);
            insert destinationOrg;

            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pref);

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            for (Destination_Org__c destination : ext.destinations) {
                destination.To_Org__c = destinationOrg.Id;
            }

            ext.saveDestination();
            System.assert(ext.destinations.size() == 1, 'The destination org(s) were not correctly initialized.');
            System.assert(ext.orgId_hasManualConnectionBehaviorMap.containsKey(toOrg.Id), 'Connection Behavior map was not correctly populated.');
            System.assert(ext.ccdEnabled, 'CCD shows as not enabled even though there is a connection behavior on the given pipeline.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void saveDestination() {
        System.runAs(getStandardUser()) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);
            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;

            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'MetaData');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;

            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();
            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);
            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);
            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);
            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);
            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);
            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);
            insert destinationOrgs;

            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            ext.addDestination();
            for (Destination_Org__c dOrgs : ext.destinations) {
                dOrgs.To_Org__c = testDestOrg.Id;
            }
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            ext.saveDestination();
            System.assert(ext.destinations.size() > 1, 'The destination org(s) were not correctly initialized.');
            System.assert(!ext.orgId_hasManualConnectionBehaviorMap.isEmpty(), 'Connection Behavior map was not correctly populated.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void validateOrgAndSaveDestination() {
        System.runAs(getStandardUser()) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);

            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;
            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git Promotion');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;

            List<Attachment> attachmentList = new List<Attachment>();
            Attachment att = new Attachment();
            att.Body = Blob.valueOf('{"flow_id" : "123456789" ,"target_branch" : "master"}');
            att.Name = 'Git-Promotion.json';
            att.ParentId = testStep.Id;
            attachmentList.add(att);
            insert attachmentList;

            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);

            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);

            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);

            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);

            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);

            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);

            insert destinationOrgs;
            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            ext.validateFromOrg();
            String matchingKey = ext.getJobsManagerMatchingKey();
            System.assert(String.isBlank(matchingKey), 'Matching key was returned from jobs manager for an invalidated org.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testWithCCMLicense() {
        Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = new Deployment__c(name = 'Test Deployment');

        PageReference pref = Page.DeploymentWizard;
        Test.setCurrentPage(pref);
        TestUtilities.exceedCopadoLicenses();

        System.runAs(getStandardUser()) {
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            Test.startTest();
            ext.saveDeployment();
            Boolean hasErrorMessage = false;
            for (Map<String, String> m : ext.messagesQueue) {
                if (m.get('m').contains(Label.LICENSES_EXCEEDED)) {
                    hasErrorMessage = true;
                    break;
                }
            }
            System.assert(true, hasErrorMessage);
            TestUtilities.enableLicenses(2, 2, 2);

            ext.saveDeployment();
            hasErrorMessage = false;
            for (Map<String, String> m : ext.messagesQueue) {
                if (m.get('m').contains(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED)) {
                    hasErrorMessage = true;
                    break;
                }
            }
            Test.stopTest();
            System.assert(true, hasErrorMessage);
        }
    }

    private static User getStandardUser() {
        User user = [SELECT Username FROM User WHERE Username = 'test_user@myorg.com'];
        return user;
    }
}