public with sharing class ExecuteTestRunExtension {
    public final Test_Run__c testRun {get;set;}
    public List<Test_Run_Step__c> steps {get;set;}
    public Map<Id,Test_Run_Step__c> mapSteps {get;set;}
    public Boolean showPicklist {get;set;}
    public Boolean showButtons {get;set;}
    public Personal_Settings__c mySettings {get;set;}
    
    public String thisStepId {get;set;}
    public String thisStepStatus {get;set;}
    
    //Accessibility
    public String access_statusColumn {get;set;}
    
    public ExecuteTestRunExtension(ApexPages.StandardController stdController) {
        thisStepId = '';
        thisStepStatus = '';
        mapSteps = new Map<Id,Test_Run_Step__c>();
        mySettings = Personal_Settings__c.getInstance(UserInfo.getUserId());
        if(mySettings==null){
            mySettings = new Personal_Settings__c(SetupOwnerId=UserInfo.getUserId());
        }
        access_statusColumn = (mySettings.AccessStatusColumn__c==null)?'images':mySettings.AccessStatusColumn__c;
        showPicklist = (mySettings.AccessStatusColumn__c=='dropdown')?true:false;
        showButtons =  (mySettings.AccessStatusColumn__c==null || mySettings.AccessStatusColumn__c=='images' || mySettings.AccessStatusColumn__c!='dropdown')?true:false;      
        testRun = (Test_Run__c)stdController.getRecord();
        steps = new List<Test_Run_Step__c>();
        steps = CMUtilities.getTestRunStepsByTestRun(testRun.Id);
        for(Test_Run_Step__c s : steps){
            mapSteps.put(s.Id, s);
        }
        
    } 
    public pageReference saveProgress(){
        Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.Sobjecttype.Test_Run_Step__c);
        return null;
    }
    public void updateAccess_statusColumn() {
        this.access_statusColumn = access_statusColumn;
        mySettings.AccessStatusColumn__c = access_statusColumn;
        showPicklist = (mySettings.AccessStatusColumn__c=='dropdown')?true:false;
        showButtons =  (mySettings.AccessStatusColumn__c==null || mySettings.AccessStatusColumn__c=='images' || mySettings.AccessStatusColumn__c!='dropdown')?true:false;      
        if(mySettings.Id==null){
            Utilities.Secure_DML(mySettings, Utilities.DML_Action.INS, schema.Sobjecttype.Personal_Settings__c);
        }
        else{
            Utilities.Secure_DML(mySettings, Utilities.DML_Action.UPD, schema.Sobjecttype.Personal_Settings__c);
        }
    }
    public void updateTestRunStatus() {
        Test_Run_Step__c trs = mapSteps.get(thisStepId);
        trs.Status__c = thisStepStatus;
        Utilities.Secure_DML(trs, Utilities.DML_Action.UPD, schema.Sobjecttype.Test_Run_Step__c);
        thisStepId = '';
        thisStepStatus = '';
        setTestRunStatus();
    }
    private void setTestRunStatus(){
        String status = testRun.Status__c;
        Map<String,Integer> counter = new Map<String,Integer>{'Passed' => 0, 'Failed' => 0, 'Passed with comments' => 0};
        for (Test_Run_Step__c s:steps){
            counter.put(String.isNotBlank(s.Status__c)?s.Status__c:'none', (counter.get(s.Status__c)!=null?counter.get(s.Status__c):0)+1);
        }
        if (counter.get('Passed') == steps.size()){
            status = 'Passed';
        }
        if (counter.get('Failed') >0){
            status = 'Failed';
        }
        if (counter.get('Passed with comments') >0 && counter.get('Failed')==0){
            status = 'Passed with comments';
        }
        if (counter.get('none')>0){
            status='In progress';
        }
        testRun.Status__c = status;
        System.debug('counter: ' + counter + ' status: ' + status + ' test run: ' + testRun);
        Utilities.Secure_DML(testRun, Utilities.DML_Action.UPD, schema.Sobjecttype.Test_Run__c);
    }
}