global with sharing class RunTestGroupsBatch implements Database.Batchable<Id>, Database.AllowsCallouts {
    public final static integer ENV_SOURCE = 0;
    public final static integer ENV_DEST = 1;
    public final static integer MODE_ALL_TESTS = 0;
    public final static integer MODE_REGRESSION_ONLY = 1;
    public final static integer MODE_USERSTORY_ONLY = 2;

    List<Id> testGroupIds = new List<Id>();

    global RunTestGroupsBatch(List<Id> testGroupIds1) {
        testGroupIds = testGroupIds1;
    }

    global List<Id> start(Database.BatchableContext BC) {
        return testGroupIds;
    }

    global void execute(Database.BatchableContext BC, List<Id> testGroupIdsBatch) {
        for (Integer i = 0; i < testGroupIdsBatch.size(); i++) {
            WebhookAPI.runSeleniumTestGroup(testGroupIdsBatch.get(i), DeployAPI.getUserAPIKey());
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    public static integer runSeleniumTestsOfPromotions(integer sourceOrDestEnv, integer regressionUserStoryOrBoth, List<Promotion__c> proms) {
        if (!LicenseHelper.isCSTEnabled()) {
            return 0; // skip everything if CST is not enabled in this org.
        }
        if (proms.size() == 0)
            return 0;
        List<Id> promIds = new List<Id>();
        List<Id> userstoryTestIds = new List<Id>();
        List<Id> testGroupIds = new List<Id>();

        for (Promotion__c p : proms)
            promIds.add(p.Id);

        Id envId = (sourceOrDestEnv == ENV_SOURCE)
                ? proms.get(0).Source_Environment__c
                : proms.get(0).Destination_Environment__c;

        // get the user stories of this promotion
        if (regressionUserStoryOrBoth == MODE_ALL_TESTS || regressionUserStoryOrBoth == MODE_USERSTORY_ONLY) {
            // now get the test groups of each user story
            for (User_Story_Selenium_Test__c a : [select Selenium_Test_Group__c from User_Story_Selenium_Test__c where User_Story__c in (select User_Story__c from Promoted_User_Story__c where Promotion__c in :promIds)])
                userstoryTestIds.add(a.Selenium_Test_Group__c);
        }

        // get the test groups of each user story AND each regression test for this env
        // also, set each group as in progress, for visual feedback.
        //System.debug('------ userstoryTestIds='+userstoryTestIds+' sourceOrDestEnv='+sourceOrDestEnv+' regressionUserStoryOrBoth='+regressionUserStoryOrBoth+' envId='+envId+' promIds='+promIds);
        List<Selenium_Test_Group__c> rSTGs = new List<Selenium_Test_Group__c>();
        for (Selenium_Test_Group__c rSTG : [
                SELECT Id, Name, Status__c, Type__c, Environment__c
                FROM Selenium_Test_Group__c
                WHERE (Id in :userstoryTestIds AND Environment__c = :envId) OR (Type__c = 'Regression Test' AND Environment__c = :envId)
        ]) {
            //System.debug('** '+rSTG);
            // If we need userstory mode only, skip any regression tests
            if (regressionUserStoryOrBoth == MODE_USERSTORY_ONLY && rSTG.Type__c == 'Regression Test')
                continue;

            testGroupIds.add(rSTG.Id);
            if (rSTG.Status__c != 'In Progress') {
                rSTG.Status__c = 'In Progress';
                rSTGs.add(rSTG);
            }
        }
        Utilities.Secure_DML(rSTGs, Utilities.DML_Action.UPD, schema.Sobjecttype.Selenium_Test_Group__c);
        System.debug('runSeleniumTestsOfPromotionId() ' + userstoryTestIds + ' testGroupIds=' + testGroupIds);
        // send each group for execution, 10 at a time.
        RunTestGroupsBatch batch = new RunTestGroupsBatch(testGroupIds);
        Database.executeBatch(batch, 10);
        return testGroupIds.size();
    }

    public static integer runSeleniumTestsOfPromotionId(Id promotionId, integer sourceOrDestEnv, integer regressionUserStoryOrBoth) {
        List<Promotion__c> proms = new List<Promotion__c>();
        proms.add([SELECT Id, Source_Environment__c, Destination_Environment__c FROM Promotion__c WHERE Id = :promotionId]);
        return runSeleniumTestsOfPromotions(sourceOrDestEnv, regressionUserStoryOrBoth, proms);
    }
}