@IsTest
private class Test_DataTemplateTaskComponent {
    @IsTest
    public static void testConstructor() {
        DataTemplateTaskComponentController dtTaskComponentController = new DataTemplateTaskComponentController();
        dtTaskComponentController.lookupAux = new AuxiliaryObject__c(Data_Template__c = '000000000000000000');
        System.assertNotEquals(null,dtTaskComponentController.lookupAux.Data_Template__c);
    }
}