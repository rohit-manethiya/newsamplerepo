public with sharing class OrgStatusIconsController {

	/**
     * icons by status
     */
    public Map<String,Map<String,String>> iconByStatus = new Map<String,Map<String,String>> {
        'Connection' => new Map<String,String>{
                'OK' => 'connection-ok.png',
                'Error' => 'connection-ko.png',
                'None' =>'connection-none.png'
        },
        'Tests' => new Map<String,String>{
                'OK' => 'health-ok.png',
                'Error' => 'health-ko.png',
                'None' => 'health-none.png'
        },
        'Git' => new Map<String,String>{
                'OK' => 'git-ok.png',
                'Error' => 'git-ko.png',
                'None' => 'git-none.png'
        }
    };


    public String Validated_Status {get;set;}
    public Datetime Validated_Date {get;set;}
    public String Last_Apex_Tests_Status {get;set;}
    public Datetime Last_Apex_Tests_Datetime {get;set;}
    public String Last_Git_Backup_Status {get;set;}
    public Datetime Last_Git_Backup_Datetime {get;set;}

    public Org__c org {get;}
    public Destination_Org__c destination {get;}
   
    /**
     * icons map
     */
    public Map<String,Map<String,String>> getIconByStatus(){
        return iconByStatus;
    }

    public OrgStatusIconsController(){}

    public void setOrg(Org__c o){

        
        if(o != null){
            Validated_Status = String.isBlank(o.Validated_Status__c) ? 'None':o.Validated_Status__c ;
            Validated_Date = (Datetime)o.Validated_Date__c;
            Last_Apex_Tests_Status = String.isBlank(o.Last_Apex_Tests_Status__c) ? 'None':o.Last_Apex_Tests_Status__c ;
            Last_Apex_Tests_Datetime = (Datetime)o.Last_Apex_Tests_Datetime__c;
            Last_Git_Backup_Status = String.isBlank(o.Last_Git_Backup_Status__c) ? 'None':o.Last_Git_Backup_Status__c ;
            Last_Git_Backup_Datetime = (Datetime)o.Last_Git_Backup_Datetime__c;
        }
   
    }

    public void setDestination(Destination_Org__c o){

        if(o != null){
            Validated_Status = String.isBlank(o.To_Org__r.Validated_Status__c) ? 'None':o.To_Org__r.Validated_Status__c ;
            Validated_Date = (Datetime)o.To_Org__r.Validated_Date__c;
            Last_Apex_Tests_Status = String.isBlank(o.To_Org__r.Last_Apex_Tests_Status__c) ? 'None':o.To_Org__r.Last_Apex_Tests_Status__c ;
            Last_Apex_Tests_Datetime = (Datetime)o.To_Org__r.Last_Apex_Tests_Datetime__c;
            Last_Git_Backup_Status = String.isBlank(o.To_Org__r.Last_Git_Backup_Status__c) ? 'None':o.To_Org__r.Last_Git_Backup_Status__c ;
            Last_Git_Backup_Datetime = (Datetime)o.To_Org__r.Last_Git_Backup_Datetime__c;
        }
   
    }
}