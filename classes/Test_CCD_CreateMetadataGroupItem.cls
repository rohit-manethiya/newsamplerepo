@IsTest
public with sharing class Test_CCD_CreateMetadataGroupItem {
    @IsTest
    static void testMetadataGroupItemCreate_WithAllMetadataNames() {
        Metadata_Group__c thisGroup = TestUtilities.createMetadataGroup();
        insert thisGroup;

        Test.startTest();

        PageReference thisPage = Page.CCD_CreateMetadataGroupItem;
        Test.setCurrentPage(thisPage);

        Metadata_Group_Item__c thisItem = new Metadata_Group_Item__c();
        ApexPages.StandardController thisStdController = new ApexPages.StandardController(thisItem);
        CCD_CreateMetadataGroupItemExtension controller = new CCD_CreateMetadataGroupItemExtension(thisStdController);

        controller.selectedMetadataItemName = Label.ALL;
        controller.thisItem.Type__c = controller.itemTypeOptions[0].getValue();
        controller.thisItem.Metadata_Group__c = thisGroup.Id;
        controller.save();

        List<Metadata_Group_Item__c> insertedItems = [SELECT Id FROM Metadata_Group_Item__c WHERE Id = :thisItem.Id];
        System.assert(!insertedItems.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testMetadataGroupItemCreate_WithAdvancedMetadataNames() {
        Metadata_Group__c thisGroup = TestUtilities.createMetadataGroup();
        insert thisGroup;

        Test.startTest();

        PageReference thisPage = Page.CCD_CreateMetadataGroupItem;
        Test.setCurrentPage(thisPage);

        Metadata_Group_Item__c thisItem = new Metadata_Group_Item__c();
        ApexPages.StandardController thisStdController = new ApexPages.StandardController(thisItem);
        CCD_CreateMetadataGroupItemExtension controller = new CCD_CreateMetadataGroupItemExtension(thisStdController);

        controller.selectedMetadataItemName = Label.Advanced_Metadata_Name;
        controller.thisItem.Type__c = controller.itemTypeOptions[0].getValue();
        controller.thisItem.Operator__c = controller.itemOperatorOptions[0].getValue();
        controller.thisItem.Value__c = '*';
        controller.thisItem.Metadata_Group__c = thisGroup.Id;
        controller.save();

        List<Metadata_Group_Item__c> insertedItems = [SELECT Id FROM Metadata_Group_Item__c WHERE Id = :thisItem.Id];
        System.assert(!insertedItems.isEmpty());

        Test.stopTest();
    }
}