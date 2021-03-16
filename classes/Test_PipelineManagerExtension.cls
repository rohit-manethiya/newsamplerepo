@IsTest
private with sharing class Test_PipelineManagerExtension {
    static TestUtilities tu = new TestUtilities();

    @TestSetup
    static void setupData() {
        TestUtilities.insertUser('pipeline-manager-adm@copado.com', 'System Administrator');
        TestUtilities.insertUser('pipeline-manager-std@copado.com', 'Standard User');

        User adminUser = [SELECT Id, Username FROM User WHERE Username = 'pipeline-manager-adm@copado.com'];
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'pipeline-manager-std@copado.com'];

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 100);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ps.Id);
        insert new PermissionSetAssignment(AssigneeId = standardUser.Id, PermissionSetId = ps.Id);

        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
            TestUtilities.createTestDataForStandardPipeline(adminUser);

            List<Epic__c> epicList = new List<Epic__c>();
            List<Sprint__c> sprintList = new List<Sprint__c>();
            List<Theme__c> themeList = new List<Theme__c>();
            List<Team__c> teamList = new List<Team__c>();

            Epic__c thisEpic = new Epic__c();
            thisEpic.Epic_Title__c = 'test epic';
            epicList.add(thisEpic);

            Utilities.Secure_DML(epicList, Utilities.DML_Action.INS, Schema.SObjectType.Epic__c);

            Sprint__c thisSprint = new Sprint__c();
            thisSprint.Name = 'test sprint';
            sprintList.add(thisSprint);

            Utilities.Secure_DML(sprintList, Utilities.DML_Action.INS, Schema.SObjectType.Sprint__c);

            Theme__c thisTheme = new Theme__c();
            thisTheme.Name = 'test theme';
            themeList.add(thisTheme);

            Utilities.Secure_DML(themeList, Utilities.DML_Action.INS, Schema.SObjectType.Theme__c);

            Team__c thisTeam = new Team__c();
            thisTeam.Name = 'test team';
            teamList.add(thisTeam);

            Utilities.Secure_DML(teamList, Utilities.DML_Action.INS, Schema.SObjectType.Team__c);
        }
    }

    @IsTest
    static void openLastViewedPipeline() {
        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        Deployment_Flow__c dpf = new Deployment_Flow__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
        PipelineManagerExtension pmextController = new PipelineManagerExtension(sc);
        pmextController.getAllPipelines();

        Test.stopTest();
    }

    @IsTest
    static void promoteUserStories() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c dpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            List<Environment__c> envList = [SELECT Id, Name FROM Environment__c WHERE Name IN ('Dev1 env', 'UAT env')];
            Map<String, String> envMap = new Map<String, String>();
            for (Environment__c env : envList) {
                envMap.put(env.Name, env.Id);
            }

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            ApexPages.currentPage().getParameters().put('deploymentEnvId', envList[0].Id);
            List<Deployment__c> latestDeployments = pmext.getLatestDeploymentsByEnvironment();
            System.assertEquals(0, latestDeployments.size());

            pmext.populateFlowGridMap();
            pmext.getPromotableUserStoriesCount();
            pmext.getBackPromotableUserStoriesCount();

            System.assertEquals(pmext.allEnvironmentsByStageGroupMap.size(), 3);

            PipelineManagerExtension.promotableStoriesForRemoteAction(
                dpf.Id,
                JSON.serialize(pmext.allSourceIdsSet, true),
                JSON.serialize(pmext.selectedFilter, true)
            );
            PipelineManagerExtension.backPromotableStoriesForRemoteAction(
                dpf.Id,
                JSON.serialize(pmext.allDestinationIdsSet, true),
                JSON.serialize(pmext.selectedFilter, true),
                JSON.serialize(pmext.flowStepToEnvMap, true),
                JSON.serialize(pmext.allEnvironmentsByStageGroupMap, true),
                JSON.serialize(pmext.allEnvironmentsMap.keySet(), true)
            );

            pmext.getAllEnvironmentsKeysetJSON();
            pmext.getAllEnvironmentsToStageGroupKeysetJSON();
            pmext.getSelectedFilterJSON();
            pmext.getFlowStepToEnvironmentJSON();

            ApexPages.currentPage().getParameters().put('fromId', envMap.get('Dev1 env'));
            ApexPages.currentPage().getParameters().put('toId', envMap.get('UAT env'));
            ApexPages.currentPage().getParameters().put('pathType', 'merge');
            pmext.getPromotableBackPromotableUserStoriesList();

            System.assertEquals(pmext.newOverlay.pathType, 'merge');
            System.assertEquals(pmext.newOverlay.fromEnvName, 'Dev1 env');
            System.assertEquals(pmext.newOverlay.toEnvName, 'UAT env');
            System.assertEquals(pmext.newOverlay.userStories.size(), 3);

            pmext.createPromotionListAndDeploy();

            System.assertEquals(pmext.promotionListWrapper.size(), 2);
            System.assertNotEquals(pmext.promotionListWrapper[0].promotion.Project__c, pmext.promotionListWrapper[1].promotion.Project__c);

            ApexPages.currentPage().getParameters().put('currentProId', pmext.promotionListWrapper[0].promotion.Id);
            pmext.assignCurrentPro();
            System.assertEquals(pmext.promotionListWrapper[0].promotion.Id, pmext.currentProId4Dependency);

            pmext.resetPromotionList();
        }
        Test.stopTest();
    }

    @IsTest
    static void promoteCheckOnlyUserStories() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            List<Environment__c> envList = [SELECT Id, Name FROM Environment__c WHERE Name IN ('Dev1 env', 'UAT env')];
            Map<String, String> envMap = new Map<String, String>();
            for (Environment__c env : envList) {
                envMap.put(env.Name, env.Id);
            }

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            pmext.populateFlowGridMap();
            pmext.getPromotableUserStoriesCount();
            pmext.getBackPromotableUserStoriesCount();

            //Stages
            System.assertEquals(pmext.allEnvironmentsByStageGroupMap.size(), 3);

            ApexPages.currentPage().getParameters().put('fromId', envMap.get('Dev1 env'));
            ApexPages.currentPage().getParameters().put('toId', envMap.get('UAT env'));
            ApexPages.currentPage().getParameters().put('pathType', 'merge');
            pmext.getPromotableBackPromotableUserStoriesList();

            pmext.showSeleniumResultsTab();
            pmext.getSTGSize();
            pmext.showComplianceResultsTab();
            pmext.getCRSize();
            pmext.showUserStoriesTab();

            System.assertEquals(pmext.newOverlay.pathType, 'merge');
            System.assertEquals(pmext.newOverlay.fromEnvName, 'Dev1 env');
            System.assertEquals(pmext.newOverlay.toEnvName, 'UAT env');
            System.assertEquals(pmext.newOverlay.userStories.size(), 3);

            pmext.createPromotionforValidation();

            System.assertEquals(pmext.promotionListWrapper.size(), 2);
            System.assertNotEquals(pmext.promotionListWrapper[0].promotion.Project__c, pmext.promotionListWrapper[1].promotion.Project__c);
        }
        Test.stopTest();
    }

    @IsTest
    static void backPromoteUserStories() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            List<Environment__c> envList = [SELECT Id, Name FROM Environment__c WHERE Name IN ('Dev2 env', 'UAT env')];
            Map<String, String> envMap = new Map<String, String>();
            for (Environment__c env : envList) {
                envMap.put(env.Name, env.Id);
            }

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            pmext.populateFlowGridMap();
            pmext.getPromotableUserStoriesCount();
            pmext.getBackPromotableUserStoriesCount();

            //Stages
            System.assertEquals(pmext.allEnvironmentsByStageGroupMap.size(), 3);

            ApexPages.currentPage().getParameters().put('fromId', envMap.get('UAT env'));
            ApexPages.currentPage().getParameters().put('toId', envMap.get('Dev2 env'));
            ApexPages.currentPage().getParameters().put('pathType', 'pull');
            pmext.getPromotableBackPromotableUserStoriesList();

            System.assertEquals(pmext.newOverlay.pathType, 'pull');
            System.assertEquals(pmext.newOverlay.fromEnvName, 'UAT env');
            System.assertEquals(pmext.newOverlay.toEnvName, 'Dev2 env');
            System.assertEquals(pmext.newOverlay.userStories.size(), 1);

            pmext.createPromotionListAndDeploy();
            System.assertEquals(pmext.promotionListWrapper.size(), 1);

            pmext.checkPromotionsStatuses();
        }

        Test.stopTest();
    }

    @IsTest
    static void inprogressUserStories() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            pmext.populateFlowGridMap();
        }
        Test.stopTest();
    }

    @IsTest
    static void pendingApprovalUserStories() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            List<Environment__c> envList = [SELECT Id, Name FROM Environment__c WHERE Name IN ('Dev1 env', 'UAT env')];
            Map<String, String> envMap = new Map<String, String>();
            for (Environment__c env : envList) {
                envMap.put(env.Name, env.Id);
            }

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            pmext.populateFlowGridMap();
            pmext.renderInApproval = true;

            pmext.recalculate();

            ApexPages.currentPage().getParameters().put('approvalEnvId', envMap.get('Dev1 env'));
            pmext.getPendingApprovalsByEnvironment();
        }
        Test.stopTest();
    }

    @IsTest
    static void testActivatePipeline() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        fpf.Active__c = false;
        update fpf;
        System.assertEquals(false, fpf.Active__c, 'Pipeline should been de-activated');
        Test.startTest();
        System.runAs(adminUser) {
            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);
            pmext.activatePipeline();
        }
        Test.stopTest();
        fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        System.assertEquals(true, fpf.Active__c, 'Pipeline should been activated');
    }

    @IsTest
    static void filtersMethods() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Deployment_Flow__c fpf = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            List<Environment__c> envList = [SELECT Id, Name FROM Environment__c WHERE Name IN ('Dev1 env', 'UAT env')];
            Map<String, String> envMap = new Map<String, String>();
            for (Environment__c env : envList) {
                envMap.put(env.Name, env.Id);
            }

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(fpf);
            PipelineManagerExtension pmext = new PipelineManagerExtension(sc);

            pmext.populateFlowGridMap();

            pmext.getPromotableUserStoriesCount();
            pmext.getBackPromotableUserStoriesCount();

            pmext.updatePipeline();
            pmext.closeToastMessage();
        }
        Test.stopTest();
    }

    @IsTest
    static void testRecalculatePipelineStructureAndGetConnections_WithAllPipelineConnections() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        List<Deployment_Flow_Step__c> flowStepList = [
            SELECT Destination_Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :thisPipeline.Id
        ];
        for (Deployment_Flow_Step__c thisStep : flowStepList) {
            thisStep.Destination_Branch__c = null;
        }
        Utilities.Secure_DML(flowStepList, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow_Step__c);

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        List<Deployment_Flow_Step__c> flowSteps = PipelineManagerExtension.recalculatePipelineStructureAndGetConnections(thisPipeline.Id);
        System.assertEquals(3, flowSteps.size());

        for (Deployment_Flow_Step__c thisStep : flowSteps) {
            if (thisStep.Branch__c == 'uat') {
                System.assertEquals('master', thisStep.Destination_Branch__c);
            } else if (thisStep.Branch__c == 'dev1') {
                System.assertEquals('uat', thisStep.Destination_Branch__c);
            } else if (thisStep.Branch__c == 'dev2') {
                System.assertEquals('uat', thisStep.Destination_Branch__c);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void testRecalculatePipelineStructureAndGetConnections_WithOnePipelineConnectionAndNullEnvironments() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        List<Deployment_Flow_Step__c> flowStepList = [
            SELECT Destination_Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :thisPipeline.Id
        ];
        Utilities.Secure_DML(flowStepList, Utilities.DML_Action.DEL, Schema.SObjectType.Deployment_Flow_Step__c);

        Deployment_Flow_Step__c dfstepDev1 = new Deployment_Flow_Step__c();
        dfstepDev1.Deployment_Flow__c = thisPipeline.Id;
        Utilities.Secure_DML(dfstepDev1, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow_Step__c);

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        List<Deployment_Flow_Step__c> flowSteps = PipelineManagerExtension.recalculatePipelineStructureAndGetConnections(thisPipeline.Id);
        System.assertEquals(1, flowSteps.size());
        System.assertEquals(null, flowSteps[0].Branch__c);
        System.assertEquals(null, flowSteps[0].Destination_Branch__c);

        Test.stopTest();
    }

    @IsTest
    static void testRecalculatePipelineStructureAndGetConnections_WithOnePipelineConnectionAndNullDestinationEnvironment() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 2' LIMIT 1];
        List<Deployment_Flow_Step__c> flowStepList = [
            SELECT Destination_Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :thisPipeline.Id
        ];
        Utilities.Secure_DML(flowStepList, Utilities.DML_Action.DEL, Schema.SObjectType.Deployment_Flow_Step__c);

        List<Environment__c> thisEnvironment = [SELECT Id FROM Environment__c WHERE Name = 'Dev1 env' LIMIT 1];

        Deployment_Flow_Step__c dfstepDev1 = new Deployment_Flow_Step__c();
        dfstepDev1.Deployment_Flow__c = thisPipeline.Id;
        dfstepDev1.Source_Environment__c = thisEnvironment[0].Id;
        Utilities.Secure_DML(dfstepDev1, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow_Step__c);

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        List<Deployment_Flow_Step__c> flowSteps = PipelineManagerExtension.recalculatePipelineStructureAndGetConnections(thisPipeline.Id);
        System.assertEquals(1, flowSteps.size());
        System.assertEquals(null, flowSteps[0].Branch__c);
        System.assertEquals(null, flowSteps[0].Destination_Branch__c);

        Test.stopTest();
    }

    @IsTest
    static void testRecalculatePipelineStructureAndGetConnections_WithUatConnectionMissing() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        List<Deployment_Flow_Step__c> flowStepList = [
            SELECT Id
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :thisPipeline.Id AND Branch__c = 'uat'
        ];
        Utilities.Secure_DML(flowStepList, Utilities.DML_Action.DEL, Schema.SObjectType.Deployment_Flow_Step__c);

        List<Deployment_Flow_Step__c> remainingFlowSteps = [
            SELECT Destination_Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :thisPipeline.Id
        ];
        for (Deployment_Flow_Step__c thisStep : remainingFlowSteps) {
            thisStep.Destination_Branch__c = null;
        }
        Utilities.Secure_DML(remainingFlowSteps, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Flow_Step__c);

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        List<Deployment_Flow_Step__c> flowSteps = PipelineManagerExtension.recalculatePipelineStructureAndGetConnections(thisPipeline.Id);
        System.assertEquals(2, flowSteps.size());

        for (Deployment_Flow_Step__c thisStep : flowSteps) {
            if (thisStep.Branch__c == 'dev1') {
                System.assertEquals('master', thisStep.Destination_Branch__c);
            } else if (thisStep.Branch__c == 'dev2') {
                System.assertEquals('master', thisStep.Destination_Branch__c);
            }
        }

        undelete flowStepList;

        flowSteps = PipelineManagerExtension.recalculatePipelineStructureAndGetConnections(thisPipeline.Id);
        System.assertEquals(3, flowSteps.size());

        for (Deployment_Flow_Step__c thisStep : flowSteps) {
            if (thisStep.Branch__c == 'uat') {
                System.assertEquals('master', thisStep.Destination_Branch__c);
            } else if (thisStep.Branch__c == 'dev1') {
                System.assertEquals('uat', thisStep.Destination_Branch__c);
            } else if (thisStep.Branch__c == 'dev2') {
                System.assertEquals('uat', thisStep.Destination_Branch__c);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void testCalculateApprovalPendingUserStories() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        Environment__c envProd = [SELECT Id FROM Environment__c WHERE Name = 'Production env' LIMIT 1];

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        pReference.getParameters().put('approvalEnvId', envProd.Id);
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        thisControllerExtension.populateFlowGridMap();
        thisControllerExtension.calculateApprovalPendingUserStories();
        thisControllerExtension.getPendingApprovalsByEnvironment();

        Test.stopTest();
    }

    @IsTest
    static void testCreateConnectionBehavior() {
        Deployment_Flow__c thisPipeline = [SELECT Id, Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];

        Test.startTest();

        PageReference pReference = Page.PipelineManager;
        pReference.getParameters().put('mode', 'manager');
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisControllerExtension = new PipelineManagerExtension(thisController);

        System.assertEquals('manager', thisControllerExtension.pipelineMode);

        thisControllerExtension.changePipelineMode();

        System.assertEquals('diagram', thisControllerExtension.pipelineMode);

        PageReference result = thisControllerExtension.createConnectionBehavior();
        System.assertEquals(null, result, 'Connection behavior cannot be created without pipeline connection or environment id');
        pReference.getParameters().put('pipelineStepId', '');
        pReference.getParameters().put('environmentId', '');
        thisControllerExtension.populateFlowGridMap();
        thisControllerExtension.calculateApprovalPendingUserStories();
        thisControllerExtension.getPendingApprovalsByEnvironment();

        Test.stopTest();
    }

    @IsTest
    static void testPipelineFilters() {
        Deployment_Flow__c thisPipeline = [SELECT Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
        Environment__c envProd = [SELECT Name, Connection_Behavior__c FROM Environment__c WHERE Name = 'Production env' LIMIT 1];
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
        envProd.Connection_Behavior__c = cbItem.Id;
        update envProd;
        Test.startTest();
        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisExtension = new PipelineManagerExtension(thisController);

        ApexPages.currentPage().getParameters().put('recordId', envProd.Id);
        thisExtension.deepCloneRelatedConnectionBehavior();
        List<SelectOption> filterOptions = thisExtension.filterOptions;
        thisExtension.removeFilterConditionEntry();
        PipelineManagerExtension.FilterCondition thisCondition = new PipelineManagerExtension.FilterCondition(Settings.ns + 'Environment__c');
        thisExtension.selectedFilter.filterConditions.add(thisCondition);
        thisCondition.getOperatorOptions();
        thisCondition.getAuxiliaryField();
        thisExtension.selectedFilter.userStoryFilter.Environment__c = envProd.Id;
        thisExtension.selectedFilter.thisFilter.Name = 'RT Filter 1';
        thisExtension.environmentsToHide.add(new SelectOption(envProd.Id, envProd.Name));
        thisExtension.selectedConditionIndex = '0';
        thisExtension.updateInputType();
        thisExtension.saveFilter();
        filterOptions = thisExtension.filterOptions;
        thisExtension.selectedFilterId = thisExtension.selectedFilter.thisFilter.Id;
        thisExtension.applySelectedFilter();
        thisExtension.createFromExistingFilter();
        thisExtension.addFilterConditionEntry();
        thisExtension.selectedConditionIndex = '1';
        thisExtension.removeFilterConditionEntry();
        thisExtension.deleteSelectedFilter();
        OperatorTypeCodes.getTypeToOps();

        //TODO assert and better testing needed

        Test.stopTest();
    }

    @IsTest
    static void testPipelineFiltersRemoveAllFilterConditions() {
        Deployment_Flow__c thisPipeline = [SELECT Name, Git_Repository__c, Active__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];

        Test.startTest();
        PageReference pReference = Page.PipelineManager;
        Test.setCurrentPage(pReference);
        ApexPages.StandardController thisController = new ApexPages.StandardController(thisPipeline);
        PipelineManagerExtension thisExtension = new PipelineManagerExtension(thisController);

        thisExtension.selectedConditionIndex = '0';
        thisExtension.removeFilterConditionEntry();
        System.assertEquals(1, thisExtension.selectedFilter.filterConditions.size());

        Test.stopTest();
    }

    @IsTest
    static void createOrgCredforExistingEnv() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'pipeline-manager-adm@copado.com' LIMIT 1];
        Test.startTest();
        System.runAs(adminUser) {
            Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '');
            Deployment_Flow__c dpf = [SELECT Id, Name, Git_Repository__c FROM Deployment_Flow__c WHERE Name = 'test 1' LIMIT 1];
            Deployment_Flow_Step__c dpfstepsList = [
                SELECT Id, Connection_Behavior_Override__c, Name, Source_Environment__c, Source_Environment__r.Name
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__r.Name = 'test 1'
                LIMIT 1
            ];
            dpfstepsList.Connection_Behavior_Override__c = cbItem.Id;
            update dpfstepsList;

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(dpf);

            PipelineManagerExtension pipelineController = new PipelineManagerExtension(sc);

            ApexPages.currentPage().getParameters().put('flowStepId', dpfstepsList.Id);
            ApexPages.currentPage().getParameters().put('recordId', dpfstepsList.Id);
            ApexPages.currentPage().getParameters().put('envId', dpfstepsList.Source_Environment__c);
            ApexPages.currentPage().getParameters().put('envName', dpfstepsList.Source_Environment__r.Name);
            ApexPages.currentPage().getParameters().put('newOrg', 'false');
            pipelineController.createOrgCredential();
            pipelineController.deepCloneRelatedConnectionBehavior();
            ApexPages.currentPage().getParameters().put('newOrg', 'true');
            pipelineController.createOrgCredential();
        }

        Test.stopTest();
    }

    @IsTest
    static void testDeprecatedClasses() {
        PipelinePagesHelper pph = new PipelinePagesHelper();
        PipelineComponentHelper pch = new PipelineComponentHelper();
        PipelineDiagramExtension pde = new PipelineDiagramExtension();
        PipelineFiltersController pfc = new PipelineFiltersController();
        PipelineHeaderController phc = new PipelineHeaderController();
    }

    @IsTest
    static void testMultiselectController() {
        MultiselectController mc = new MultiselectController();
        List<SelectOption> rightOptions = new List<SelectOption>();
        mc.rightOptions = rightOptions;
        mc.leftOptions = null;
        mc.rightOptionsHidden = 'test&test';
        mc.leftOptionsHidden = 'test-left&test-left';
    }
}