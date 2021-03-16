public with sharing class CCD_CreateQualityGateExtension {
    public Quality_Gate__c thisQualityGate { get; set; }

    public CCD_CreateQualityGateExtension(ApexPages.StandardController thisStdController) {
        if (!Test.isRunningTest()) {
            thisStdController.addFields(new List<String>(Schema.SObjectType.Quality_Gate__c.fields.getMap().keySet()));
        }
        thisQualityGate = (Quality_Gate__c) thisStdController.getRecord();
    }
    /**
     * @description validates required fields, clears unnecessary fields and saves the new record to the database.
     *
     * @return a new page reference redirection to the record detail page.
     */
    public PageReference save() {
        String dataJSON = ApexPages.currentPage().getParameters().get('dataJSON');
        if (String.isNotBlank(dataJSON)) {
            thisQualityGate.DataJSON__c = dataJSON;
        }
        try {
            Utilities.Secure_DML(thisQualityGate, Utilities.DML_Action.UPS, SObjectType.Quality_Gate__c);
        } catch (Exception ex) {
            return null;
        }
        PageReference recordDetail = new ApexPages.StandardController(thisQualityGate).view();
        return recordDetail;
    }
}