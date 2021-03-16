@RestResource(urlMapping='/SeleniumTestCaseViewEdit')
global with sharing class SeleniumTestCaseViewEdit {
    ApexPages.StandardController stdController;

    public static final String TESTCASENAME = 'Copado.SeleniumTestCase.json';
    public static final String TESTDATANAME = 'Copado.SeleniumTestData.json';

	public String TestCasesPerSuiteSave {get; set;} // JSON written from JS, with [ [testCaseID, datasetName], ... ]

    public String getAPIKey(){
        return DeployAPI.getUserAPIKey();
    }
    public SeleniumTestCaseViewEdit(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) try{ stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Case__c.fields.getMap().keySet())); }catch(Exception e) { stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Suite__c.fields.getMap().keySet())); }
        this.stdController = stdController;
    }

    static public String APIEndpoint {
        get {
            if (APIEndpoint == null) {
                //memoize
                String orgId = UserInfo.getOrganizationId();
                String userId = UserInfo.getUserId();
                String sessionId = UserInfo.getSessionId();

                //use getSalesforceBaseUrl within batches and schedules (not Visualforce), and fix inconsistent protocol
                if (sessionId == null) return Url.getSalesforceBaseUrl().toExternalForm().replace('http:', 'https:');

                PageReference pr = new PageReference('/id/' + orgId + '/' + userId);
                pr.getParameters().put('oauth_token', sessionId);
                pr.getParameters().put('format', 'json');

                //within test context use url class, else derive from identity api
                String data = Test.isRunningTest() ? '{"urls": {"rest": "' + Url.getSalesforceBaseUrl().toExternalForm() + '"}}' : pr.getContent().toString();
                Map<String,Object> result = (Map<String,Object>)Json.deserializeUntyped(data);
                Map<String,Object> urls = (Map<String,Object>)result.get('urls');

                //compose pod from the REST endpoint
                Url rest = new Url((String)urls.get('rest'));
                APIEndpoint = rest.getProtocol() + '://' + rest.getHost();
            }

            return APIEndpoint;
        } set;
    }

    global class TestCaseNameAndVersion {
    	public Id Id;
    	public String Name;
    	public String Version;
    	public Id Previous_Version;
    }

    global class TestCaseInfo {
        public TestCaseNameAndVersion tc = new TestCaseNameAndVersion();
    	public Attachment testCase;
    	public Attachment testData;
    	public String testCaseSrc;
    	public String testDataSrc;
    }

    global class TestCaseDatasets {
    	public ID Id;
    	public String Name;
    	public String Version;
    	public String selectedDataset;
    	public List<String> datasets = new List<String>();
    }

    /**
     * Fill a consitent set of values into "obj", creating/retrieving the attachments, arrays and other information related to the TestCase
     **/
    global static TestCaseInfo getTestCaseInfo(Id TestCaseId) {
        // we might be creating a new testcase, so no attachments will exist anyway.
		TestCaseInfo testcase = new TestCaseInfo();
        testcase.tc.Version = '1';

        if(TestCaseId!=null) {
            Selenium_Test_Case__c tc = new Selenium_Test_Case__c();
            if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
                tc = [SELECT Id, Name, Version__c, Previous_Version__c FROM Selenium_Test_Case__c WHERE Id = :TestCaseId LIMIT 1];
            }
            testcase.tc.Id = tc.Id;
            testcase.tc.Name = tc.Name;
            testcase.tc.Version = tc.Version__c;
            testcase.tc.Previous_Version = tc.Previous_Version__c;
            if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                for (Attachment a : [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :TestCaseId AND Name in (:TESTCASENAME, :TESTDATANAME) ORDER BY name ASC LIMIT 100]) {
                    if (a.Name == TESTCASENAME) {
                        testcase.testCase = a;
                        testcase.testCaseSrc = testcase.testCase.Body.toString();
                        testcase.testCase.Body = null;
                    } else if (a.Name == TESTDATANAME) {
                        testcase.testData = a;
                        testcase.testDataSrc = testcase.testData.Body.toString();
                        testcase.testData.Body = null;
                    }
                }
            }
        }

		System.debug('### getTestCaseInfo.1 TestCaseId='+TestCaseId+' testcase.tc='+testcase.tc+' Version__c='+testcase.tc.Version);

        return testcase;
    }

 	global static TestCaseInfo testCaseSaveAllImpl(Id testCaseId, String versionString, String name, String testCaseSrc, String testDataSrc) {
        // retrieve the testcase information, if it's an existing test case, or a new, clean instance, fit for serialization
		TestCaseInfo testcase = getTestCaseInfo(testCaseId);

        System.debug('testCaseSaveAllImpl'+testcaseId+', versionString='+versionString+', name='+name);

        // upsert the testcase record.
        Selenium_Test_Case__c tc = new Selenium_Test_Case__c();
        if(!Schema.sObjectType.Selenium_Test_Case__c.fields.Name.isUpdateable() || !Schema.sObjectType.Selenium_Test_Case__c.fields.Version__c.isUpdateable()){
            return null;
        }
        tc.Id = testCaseId;
        tc.Name = name;
        tc.Version__c = (versionString==null||versionString.equals(''))?'1':versionString;
        //psert tc;
        Utilities.Secure_DML(tc, Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Test_Case__c);
        testCaseId = tc.Id;
        testcase.tc.Id = testCaseId;

        // upsert the testcase and testdata attachments (testadata only if necessary)
        if(testcase.testCase==null) {
            testcase.testCaseSrc = '{}';
            if(!Schema.sObjectType.Attachment.fields.Name.isCreateable() || !Schema.sObjectType.Attachment.fields.ParentId.isCreateable() || !Schema.sObjectType.Attachment.fields.Body.isCreateable() || !Schema.sObjectType.Attachment.fields.Name.isUpdateable() || !Schema.sObjectType.Attachment.fields.body.isUpdateable()){
                return null;
            }
            testcase.testCase = new Attachment(Name=TESTCASENAME, ParentId=testCaseId, body=Blob.valueOf(testcase.testCaseSrc));
        }
        if(testcase.testData==null) {
            testcase.testDataSrc = '{}';
            testcase.testData = new Attachment(Name=TESTDATANAME, ParentId=testCaseId, body=Blob.valueOf(testcase.testDataSrc));
        }
        testcase.testCaseSrc = (testCaseSrc!=null?testCaseSrc:'{}');
        testcase.testCase.Body=Blob.valueOf(testcase.testCaseSrc);
        testcase.testDataSrc = (testDataSrc!=null?testDataSrc:'{}');
        testcase.testData.Body=Blob.valueOf(testcase.testDataSrc);
		//upsert testcase.testCase;
        Utilities.Secure_DML(testcase.testCase, Utilities.DML_Action.UPS, schema.Sobjecttype.Attachment);
        if(testcase.testDataSrc.length()>4) {
            //upsert testcase.testData;
            Utilities.Secure_DML(testcase.testData, Utilities.DML_Action.UPS, schema.Sobjecttype.Attachment);
        }

        // Refresh and return the informatin
		return getTestCaseInfo(testCaseId);
    }

    /**
     * Load all
	*/
    @HttpGet
 	global static TestCaseInfo testCaseLoadAll() {
        RestResponse res = RestContext.response;
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE');
        res.addHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
		res.addHeader('Content-Type', 'application/json');

        String testCaseId = RestContext.request.params.get('id');

        // retrieve the testcase information, if it's an existing test case, or a new, clean instance, fit for serialization
		return getTestCaseInfo(testCaseId);
    }

    /**
     * Save all
	*/
    @HttpPost
 	global static TestCaseInfo testCaseSaveAll(Id testCaseId, String versionString, String name, String testCaseSrc, String testDataSrc) {
		if(name==null || name==''){
            return null;
        }

        TestCaseInfo testcase = testCaseSaveAllImpl(testCaseId, versionString, name, testCaseSrc, testDataSrc);
        return testcase;
    }

    public static String getJsonTestCases() {
        String testCaseId = ApexPages.currentPage().getParameters().get('id');
        List<TestCaseInfo> tcs = new List<TestCaseInfo>();
        tcs.add(getTestCaseInfo(testCaseId));
        return JSON.serialize(tcs);
    }

    /**
     * Return the searched testcases, plus the names of each dataset
     * Or, returns all the testcases in a particular testsuite.
     **/
    public static String getLookupTestCases() {
        String q = ApexPages.currentPage().getParameters().get('q');
        String tsId = ApexPages.currentPage().getParameters().get('id'); // in this instance, id means testcase id
        System.debug('SeleniumTestCaseViewEdit.getLookupTestCases tsid='+tsid+' q='+q);

        List<TestCaseDatasets> result = new List<TestCaseDatasets>();
        List<Selenium_Test_Case__c> tcs = new List<Selenium_Test_Case__c>();
        Map<Id, List<Attachment>> atts_per_tcs = new Map<Id, List<Attachment>>();
        List<String> tcsSelectedDatasets = new List<String>();

        if(String.isBlank(tsid)) {
            if(String.isBlank(q)) {
                q = '%';
            }else{
                q = '%'+q+'%';
            }
            if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
                for (Selenium_Test_Case__c c : [
                        SELECT Id, Name, Version__c, (SELECT Id FROM Attachments WHERE Name = :TESTDATANAME ORDER BY CreatedDate DESC LIMIT 1)
                        FROM Selenium_Test_Case__c
                        WHERE Name like :q
                        ORDER BY LastModifiedDate DESC
                        LIMIT 20
                ]) {
                    tcs.add(c);
                    atts_per_tcs.put(c.Id, c.Attachments);
                }
            }
        }else{
            if(Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.isAccessible()) {
                for (Selenium_Test_Case_Per_Suite__c a : [
                        SELECT  Selenium_Test_Case__r.Id,
                                Selenium_Test_Case__r.Name,
                                Selenium_Test_Case__r.Version__c,
                                Test_Dataset_Name__c
                        FROM Selenium_Test_Case_Per_Suite__c
                        WHERE Selenium_Test_Suite__c = :tsId
                        ORDER BY Order__c, CreatedDate
                        LIMIT 100
                ]) {

                    tcs.add(a.Selenium_Test_Case__r);
                    atts_per_tcs.put(a.Selenium_Test_Case__r.Id, new List<Attachment>());
                    tcsSelectedDatasets.add(a.Test_Dataset_Name__c);
                    System.debug('-tcsps ' + a);
                }
            }
            if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                for (Attachment a : [SELECT Id, ParentId FROM Attachment WHERE parentId in :atts_per_tcs.keySet() AND Name = :TESTDATANAME]) {
                    System.debug('-att ' + a);
                    atts_per_tcs.get(a.ParentId).add(a);
                }
            }
        }

        System.debug('SeleniumTestCaseViewEdit.getLookupTestCases #tcs='+tcs.size());

		Integer idx = 0;
        if(Schema.sObjectType.Selenium_Test_Case__c.isQueryable() && Schema.sObjectType.Selenium_Test_Case__c.isAccessible()) {
            for (Selenium_Test_Case__c c : tcs) {
                System.debug('getLookupTestCases() processing: ' + c.Name + ' #atts=' + c.Attachments.size());
                TestCaseDatasets tcds = new TestCaseDatasets();
                tcds.Id = c.Id;
                tcds.Name = c.Name;
                tcds.Version = c.Version__c;
                tcds.selectedDataset = tcsSelectedDatasets.size() > 0 ? tcsSelectedDatasets.get(idx) : null;
                if (Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                    for (Attachment a : atts_per_tcs.get(c.Id)) {
                        a = [Select Body FROM Attachment Where Id = :a.Id];
                        List<Object> dss = (List<Object>) JSON.deserializeUntyped(a.Body.toString());
                        System.debug('getLookupTestCases() dss: ' + dss);
                        for (Object ds : dss) {
                            System.debug('getLookupTestCases() item: ' + ds);
                            tcds.datasets.add((String) ((Map<String, Object>) ds).get('name'));
                        }
                    }
                }
                result.add(tcds);
                idx++;
            }
        }

        String t = JSON.serialize(result);
        System.debug('SeleniumTestCaseViewEdit.getLookupTestCases return '+t);
        return t;
    }

	public PageReference saveTestCasesPerSuite() {
        String tsId = ApexPages.currentPage().getParameters().get('id'); // in this instance, id means testcase id
        System.debug('saveTestCases tsId='+tsId+' TestCasesPerSuiteSave='+TestCasesPerSuiteSave);
        List<Selenium_Test_Case_Per_Suite__c> tcList = new List<Selenium_Test_Case_Per_Suite__c>();
        if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
            tcList = [SELECT id FROM Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :tsId];
        }
        Utilities.Secure_DML(tcList, Utilities.DML_Action.DEL, schema.Sobjecttype.Selenium_Test_Case_Per_Suite__c);
        if(TestCasesPerSuiteSave!=null && TestCasesPerSuiteSave.trim()!='') {
            Integer order_no = 1;
            List<Selenium_Test_Case_Per_Suite__c> tcpsList = new List<Selenium_Test_Case_Per_Suite__c>();
            if(!Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Suite__c.isCreateable() || !Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Case__c.isCreateable() || !Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Test_Dataset_Name__c.isCreateable() || !Schema.sObjectType.Selenium_Test_Case_Per_Suite__c.fields.Order__c.isCreateable()){
                return null;
            }
            for(List<String> item : (List<List<String>>)JSON.deserialize(TestCasesPerSuiteSave, List<List<String>>.class) ) {
                System.debug('saveTestCases item: '+item);

                tcpsList.add(new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c=tsId, Selenium_Test_Case__c=item.get(0), Test_Dataset_Name__c=item.get(1), Order__c=order_no));
                order_no++;
            }
            Utilities.Secure_DML(tcpsList, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Case_Per_Suite__c);
        }
        return this.stdController.view();
    }
}