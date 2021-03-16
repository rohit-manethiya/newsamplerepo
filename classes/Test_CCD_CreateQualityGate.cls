@IsTest
public with sharing class Test_CCD_CreateQualityGate {
    @IsTest
    static void testCreateQualityGate_TypelIsURLCallout() {
        Connection_Behavior__c thisConnectionBehavior = new Connection_Behavior__c();
        thisConnectionBehavior.Name = 'Test Connection';
        insert thisConnectionBehavior;
        Metadata_Group__c thisGroup = new Metadata_Group__c();
        thisGroup.Name = 'Test Group';
        thisGroup.Description__c = 'Some description';
        insert thisGroup;
        Test.startTest();
        PageReference thisPage = Page.CCD_CreateQualityGate;
        thisPage.getParameters()
            .put(
                'dataJSON',
                '{"type":"wait","method":"POST","url":"https://dev-app-api.copado.com/json/v1/webhook/promotions/a0Z1n00000BgnxL/process?api_key=3262104cfef17d87c243b40952d6742c&checkOnly=false","body":"    ","queryParameters":[["api_key","3262104cfef17d87c243b40952d6742c"],["checkOnly","false"]],"headers":[]}'
            );
        Test.setCurrentPage(thisPage);
        Quality_Gate__c thisQualityGate = new Quality_Gate__c();
        ApexPages.StandardController thisStdController = new ApexPages.StandardController(thisQualityGate);
        CCD_CreateQualityGateExtension controller = new CCD_CreateQualityGateExtension(thisStdController);
        controller.thisQualityGate.Name = 'Test Quality Gate';
        controller.thisQualityGate.Metadata_Group__c = thisGroup.Id;
        controller.thisQualityGate.Connection_Behavior__c = thisConnectionBehavior.Id;
        controller.thisQualityGate.Type__c = 'URL Callout';
        controller.save();
        List<Quality_Gate__c> insertedRecords = [SELECT Id FROM Quality_Gate__c WHERE Id = :controller.thisQualityGate.Id];
        System.assert(!insertedRecords.isEmpty());
        Test.stopTest();
    }
}