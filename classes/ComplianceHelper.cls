/*
    jgaviria@copa.do
    Helpe component controller for related to Compliance
 */
public with sharing class ComplianceHelper {
    /*
        Id of the current item, it can be: 
            -Deployment
            -Environment
            -Git Snapshot
            -Org Credential
            -User Story
     */
    public  Id soId {get;set;}
    public  String soAPIRelName {get;set;}
    public  String csrId {get;set;}
    /*
        Return Warning Message
     */
    public String getwMessage (){
        return String.format(System.Label.Compliance_Comp_Warn,new String[]{csrId});
    }
    /*
        Return Error Message
     */    
    public String geteMessage (){
        return String.format(System.Label.Compliance_Comp_Error,new String[]{csrId});
    }
	public ComplianceHelper() {
		
	}
    /*
        Look for the CSR record
     */        
    public Compliance_Scan_Result__c srw{
        get{
            if(srw == null){
                Compliance_Scan_Result__c csr = GlobalUtilities.getWOSharingCSR(soId, soAPIRelName);
                csrId = csr.Id;        
                srw=csr;
            }
            return srw;
        }
        private set;
    }

}