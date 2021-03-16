public class MetaDataItem {
    @AuraEnabled
    public String t { get; set; } // Metadata Type
    @AuraEnabled
    public String n { get; set; } // Metadata Name
    @AuraEnabled
    public Boolean r; // Retrieve Only
    @AuraEnabled
    public Boolean s; // Metadata Is Selected
    @AuraEnabled
    public String cb; // Created By
    @AuraEnabled
    public String cd; // Created Date
}