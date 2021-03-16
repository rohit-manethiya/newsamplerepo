public with sharing class SeleniumTestCasePerSuite {
	public Selenium_Test_Suite__c obj {get; set;}
	public String TestCaseList {get; set;}
    private ApexPages.StandardController stdController;
    
    public SeleniumTestCasePerSuite(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.obj = (Selenium_Test_Suite__c)stdController.getRecord();
    }
      
    public String jsonData {
        get {
        	String q = ApexPages.currentPage().getParameters().get('q');
	    	System.debug('SeleniumTestCasePerSuite.jsonData q='+q);
			if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
				if (q != null && q != '') {
					q = '%' + q + '%';
					return JSON.serialize([SELECT Id, Name FROM Selenium_Test_Case__c WHERE Name like :q ORDER BY LastModifiedDate DESC LIMIT 50]);
				}
				return JSON.serialize([SELECT Id, Name FROM Selenium_Test_Case__c ORDER BY LastModifiedDate DESC LIMIT 50]);
			}
            else{
                return null;
            }
        }
    }
      
    public String jsonTestcases {
        get {
        	List<Selenium_Test_Case__c> l = new List<Selenium_Test_Case__c>();
            if(Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isAccessible()) {
                for (Selenium_Test_Case_Per_Suite__c a : [SELECT Selenium_Test_Case__r.Id, Selenium_Test_Case__r.Name FROM Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :this.obj.Id ORDER BY Order__c, CreatedDate LIMIT 100]) {
                    l.add(a.Selenium_Test_Case__r);
                }
            }
	    	System.debug('SeleniumTestCasePerSuite.jsonTestcases length='+l.size());
            return JSON.serialize(l);
        }
    }
    
	public PageReference saveTestCases() {
        List<Selenium_Test_Case_Per_Suite__c> tcList = new List<Selenium_Test_Case_Per_Suite__c>();
        if(Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isAccessible()) {
            Utilities.Secure_DML([select id from Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :this.obj.id], Utilities.DML_Action.DEL, schema.Sobjecttype.Selenium_Test_Case_Per_Suite__c);
        }
		if(TestCaseList!=null && TestCaseList.trim()!='') {
			Integer order_no = 1;
			for(String id : TestCaseList.trim().split(' ')) {
                tcList.add(new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c=this.obj.id, Selenium_Test_Case__c=id, Order__c=order_no));
				order_no++;
			}
		}
        if(!Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Suite__c.isCreateable() || !Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Case__c.isCreateable() || !Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Order__c.isCreateable()){

        }
        Utilities.Secure_DML(tcList, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Case_Per_Suite__c);
        return this.stdController.view();
	}
}