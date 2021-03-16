@isTest
private class TestPromotionEditExtension {
    
    static testMethod void test() {
        
        Promotion__c p = new Promotion__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(p);
        PromotionEditExtension pee = new PromotionEditExtension(sc);
        
    }
}