@IsTest
public with sharing class Test_ConnectionBehaviorInfoController {
    @IsTest
    static void testConnectionBehaviorInfoController() {
        Connection_Behavior__c thisConnectionBehavior = new Connection_Behavior__c();
        insert thisConnectionBehavior;

        Environment__c thisEnvironment = new Environment__c();
        thisEnvironment.Name = 'Prod';
        thisEnvironment.Type__c = 'Production/Developer';
        thisEnvironment.Connection_Behavior__c = thisConnectionBehavior.Id;
        insert thisEnvironment;

        Deployment_Flow__c thisFlow = new Deployment_Flow__c();
        thisFlow.Name = 'test 1';
        thisFlow.Active__c = true;
        thisFlow.Main_Branch__c = 'master';
        thisFlow.Calculate_Based_on__c = 'User Story';
        insert thisFlow;

        Deployment_Flow_Step__c thisFlowStep = new Deployment_Flow_Step__c();
        thisFlowStep.Source_Environment__c = thisEnvironment.Id;
        thisFlowStep.Connection_Behavior_Override__c = thisConnectionBehavior.Id;
        thisFlowStep.Deployment_Flow__c = thisFlow.Id;
        insert thisFlowStep;

        PageReference thisPage = Page.ConnectionBehaviorUsageInformation;
        Test.setCurrentPage(thisPage);

        ApexPages.StandardController thisStdController = new ApexPages.StandardController(thisConnectionBehavior);

        Test.startTest();

        ConnectionBehaviorUsageInfoController thisController = new ConnectionBehaviorUsageInfoController(thisStdController);
        System.assertEquals(2, thisController.totalRelation);

        Test.stopTest();
    }
}