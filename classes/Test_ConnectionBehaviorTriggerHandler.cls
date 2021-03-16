/**
 * Created by COPADO\ucan on 9/6/19.
 */

@IsTest
private class Test_ConnectionBehaviorTriggerHandler {
    @IsTest
    static void testBehavior() {
        Test.startTest();
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '57 0 1 ? * * *');
        cbItem.Promotion_Behavior__c = 'Scheduled';
        update cbItem;
        List<CronTrigger> ctList = [
            SELECT Id, CronExpression, CronJobDetailId, OwnerId, State
            FROM CronTrigger
            WHERE CronExpression = '57 0 1 ? * * *'
        ];
        System.assertEquals(1, ctList.size());
        cbItem.Back_Promotion_Behavior__c = 'Scheduled';
        update cbItem;
        ctList = [SELECT Id, CronExpression, CronJobDetailId, OwnerId, State FROM CronTrigger WHERE CronExpression = '57 0 1 ? * * *'];
        System.assertEquals(2, ctList.size());

        cbItem.Promotion_Schedule__c = '19 1 2 ? * * *';
        update cbItem;
        ctList = [SELECT Id, CronExpression, CronJobDetailId, OwnerId, State FROM CronTrigger WHERE CronExpression = '19 1 2 ? * * *'];
        System.assertEquals(1, ctList.size());

        cbItem.Back_Promotion_Behavior__c = 'Manual';
        cbItem.Promotion_Behavior__c = 'Automated';
        update cbItem;
        delete cbItem;

        Test.stopTest();
    }

    @IsTest
    static void validatePromotionCriteria_Fail() {
        Test.startTest();
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '57 0 1 ? * * *');
        cbItem.Promotion_Criteria__c = 'Environment__c.Name = \'FO dev 1 org\'';
        try {
            update cbItem;
        } catch (Exception exc) {
            System.assertNotEquals(null, exc.getMessage(), 'Promotion Criteria validation will fail because the entered value is not correct');
        }
        Test.stopTest();
    }

    @IsTest
    static void validateBackPromotionCriteria_Fail() {
        Test.startTest();
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '57 0 1 ? * * *');
        cbItem.Back_Promotion_Criteria__c = 'Environment__c.Name = \'FO dev 1 org\'';
        try {
            update cbItem;
        } catch (Exception exc) {
            System.assertNotEquals(null, exc.getMessage(), 'Back Promotion Criteria validation will fail because the entered value is not correct');
        }
        Test.stopTest();
    }
}