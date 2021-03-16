public with sharing class ScheduleConnectionBehaviorController {
    public Connection_Behavior__c thisConnectionBehavior { get; private set; }
    public Boolean showError { get; private set; }
    public String promotionType {
        get {
            promotionType = ApexPages.currentPage().getParameters().get('promotionType');
            if(String.isBlank(promotionType)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Promotion_Type_Specificed));
                showError = true;
            }
            return promotionType;
        }
        private set;
    }

    /**
     * @description constructor for getting the URL parameters and passing them to the ScheduleCronExpression component.
     */
    public ScheduleConnectionBehaviorController() {
        showError = false;
        String recordId = ApexPages.currentPage().getParameters().get('id');
        if(String.isBlank(recordId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Record_Found));
            showError = true;
            return;
        }
        thisConnectionBehavior = [SELECT Name, Promotion_Schedule__c, Back_Promotion_Schedule__c FROM Connection_Behavior__c WHERE Id = :recordId];
    }
}