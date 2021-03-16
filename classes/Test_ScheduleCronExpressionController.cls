@IsTest
public with sharing class Test_ScheduleCronExpressionController {
    @IsTest
    static void testScheduleCronExpression_FromCopadoScheduledJob() {
        Scheduled_Job__c thisScheduledJob = new Scheduled_Job__c();
        thisScheduledJob.Name = 'Test Scheduled Job';
        insert thisScheduledJob;

        Test.startTest();

        PageReference thisPage = Page.ScheduleCopadoScheduledJob;
        Test.setCurrentPage(thisPage);
        ApexPages.CurrentPage().getParameters().put('newCronExpression', '0 8 4 ? * MON-FRI *');

        ScheduleCronExpressionController thisController = new ScheduleCronExpressionController();
        thisController.setThisRecordId(thisScheduledJob.Id);
        thisController.setCronExpressionValue();
        thisController.saveJob();
        thisController.goBackToRecordDetail();

        Scheduled_Job__c updatedScheduledJob = [SELECT Cron_Expression__c FROM Scheduled_Job__c WHERE Id = :thisScheduledJob.Id];
        System.assertEquals('0 8 4 ? * MON-FRI *', updatedScheduledJob.Cron_Expression__c);

        Test.stopTest();
    }

    @IsTest
    static void testScheduleCronExpression_FromConnectionBehavior() {
        Connection_Behavior__c thisConnectionBehavior = new Connection_Behavior__c();
        thisConnectionBehavior.Name = 'Test Connection Behavior';
        insert thisConnectionBehavior;

        Test.startTest();

        PageReference thisPage = Page.ScheduleConnectionBehavior;
        Test.setCurrentPage(thisPage);
        ApexPages.CurrentPage().getParameters().put('newCronExpression', '0 8 4 ? * MON-FRI *');
        ApexPages.CurrentPage().getParameters().put('promotionType', 'Promotion');

        ScheduleCronExpressionController thisController = new ScheduleCronExpressionController();
        thisController.setThisRecordId(thisConnectionBehavior.Id);
        thisController.setCronExpressionValue();
        thisController.saveJob();
        thisController.goBackToRecordDetail();

        Connection_Behavior__c updatedConnectionBehavior = [SELECT Promotion_Schedule__c FROM Connection_Behavior__c WHERE Id = :thisConnectionBehavior.Id];
        System.assertEquals('0 8 4 ? * MON-FRI *', updatedConnectionBehavior.Promotion_Schedule__c);

        Test.stopTest();
    }

    @IsTest
    static void testScheduleCronExpression_NewCronExpressionIsEmpty() {
        Connection_Behavior__c thisConnectionBehavior = new Connection_Behavior__c();
        thisConnectionBehavior.Name = 'Test Connection Behavior';
        thisConnectionBehavior.Back_Promotion_Schedule__c = '0 8 4 ? * MON-FRI *';
        insert thisConnectionBehavior;

        Test.startTest();

        PageReference thisPage = Page.ScheduleConnectionBehavior;
        Test.setCurrentPage(thisPage);
        ApexPages.CurrentPage().getParameters().put('promotionType', 'Back_Promotion');

        ScheduleCronExpressionController thisController = new ScheduleCronExpressionController();
        thisController.setThisRecordId(thisConnectionBehavior.Id);
        thisController.thisCronExpression = null;
        thisController.saveJob();

        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assert(!pageMessages.isEmpty());
        System.assert((pageMessages[0].getDetail().contains(Label.Cron_Expression_Required)));

        thisController.goBackToRecordDetail();

        Connection_Behavior__c updatedConnectionBehavior = [SELECT Back_Promotion_Schedule__c FROM Connection_Behavior__c WHERE Id = :thisConnectionBehavior.Id];
        System.assert(updatedConnectionBehavior.Back_Promotion_Schedule__c != null);

        Test.stopTest();
    }

    @IsTest
    static void testScheduleConnectionBehaviorController() {
        Connection_Behavior__c thisConnectionBehavior = new Connection_Behavior__c();
        thisConnectionBehavior.Name = 'Test Connection Behavior';
        insert thisConnectionBehavior;

        Test.startTest();

        PageReference thisPage = Page.ScheduleConnectionBehavior;
        Test.setCurrentPage(thisPage);
        ApexPages.CurrentPage().getParameters().put('id', thisConnectionBehavior.Id);
        ApexPages.CurrentPage().getParameters().put('promotionType', 'Back_Promotion');

        ScheduleConnectionBehaviorController thisController = new ScheduleConnectionBehaviorController();
        System.assertEquals('Back_Promotion', thisController.promotionType);

        Test.stopTest();
    }
}