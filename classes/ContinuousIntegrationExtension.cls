public with sharing class ContinuousIntegrationExtension {

	public Continuous_Integration__c ci {get;set;}
    public Personal_Settings__c mySettings {get;set;}
    public String destOrgValidationStatus {get;set;}
    public String ciStatusImgUrl {get;set;}
    public String preCiStatusImgUrl {get;set;}
    public String postSuccessImgUrl {get;set;}
    public String postFailureImgUrl {get;set;}
    public String hookUrl {get;set;}
    public Boolean showHookUrl {get;set;}
    public Boolean isCIenabled {get;set;}
    public ApexPages.StandardController controller {get;set;}
    /*flag for custom fieldset*/
    public boolean showOtherInformation{get;set;}

    public static final String[] CI_FIELDS = new String[] {'Name','Status__c' ,'LastModifiedById','LastModifiedDate','Active__c','Branch__c','Check_Only__c','Destination_Org_Credential__c','Files_to_be_deployed__c','Git_Repository__c','Git_Repository__r.Name','Last_Build_Task_Duration__c','Run_All_Tests__c','Destination_Org_Credential__r.Name','OwnerId','Pre_Deployment_Jobs__c','Pre_Deployment_Options__c','Post_Success_Deployment_Jobs__c','Post_Failed_Deployment_Jobs__c','Pre_Deployment_Jobs__r.Status__c','Post_Success_Deployment_Jobs__r.Status__c','Post_Failed_Deployment_Jobs__r.Status__c','Pre_Deployment_Jobs__r.Flag_Status__c','Post_Success_Deployment_Jobs__r.Flag_Status__c','Post_Failed_Deployment_Jobs__r.Flag_Status__c'};

    public ContinuousIntegrationExtension(ApexPages.StandardController stdController) {
        isCIenabled = true;
        if(!FeatureHelper.isFeatureEnabled('Continuous Integration')){
            Apexpages.addMessage(new apexpages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED+' Continuous Integration'));
            isCIenabled = false;
        }
        controller = stdController;
        showHookUrl = false;
        if(!Test.isRunningTest())stdController.addFields(CI_FIELDS);
        ci = (Continuous_Integration__c)controller.getRecord();
        mySettings = Personal_Settings__c.getInstance();
        if(mySettings==null)mySettings = new Personal_Settings__c(SetupOwnerId=UserInfo.getUserId());
        mySettings.Build_Task_Rows__c = (mySettings.Build_Task_Rows__c==null)?5:mySettings.Build_Task_Rows__c;

        if(ci.Destination_Org_Credential__c!=null){
        	try{
                Org__c org = [SELECT Id, Validated_Status__c FROM Org__c WHERE Id=:ci.Destination_Org_Credential__c];
                destOrgValidationStatus = setValidationImageUrl(org.Validated_Status__c);
                ciStatusImgUrl = setCIstatusUrl(ci.Status__c);
            }
            catch(Exception e){
                Apexpages.addMessage(new apexpages.Message(ApexPages.Severity.WARNING, 'There was an error retrieving the Destination Org Credential.  Please ensure that you have read access to this Salesforce record.'));
                return;
            }
            
        }
        showOtherInformation = SObjectType.Continuous_Integration__c.FieldSets.CustomFields.getFields().size()>0;
    }
    public PageReference getCI(){
        //ci = [select Id, Status__c from Continuous_Integration__c where Id=:ci.Id];
        String theQuery = 'SELECT ';
        for(String s : CI_FIELDS){
            theQuery += s+',';
        }
        theQuery = theQuery.subString(0, theQuery.length() - 1);
        theQuery += ' FROM Continuous_Integration__c WHERE Id=\'' + String.escapeSingleQuotes(ci.Id) + '\' LIMIT 1';
        system.debug('#### THE QUERY: '+theQuery);
        Continuous_Integration__c[] cis = Database.query(theQuery);
        ci = cis[0];
        ciStatusImgUrl = setCIstatusUrl(ci.Status__c);
        preCiStatusImgUrl = setCIstatusUrl(ci.Pre_Deployment_Jobs__r.Status__c);
   		postSuccessImgUrl = setCIstatusUrl(ci.Post_Success_Deployment_Jobs__r.Status__c);
    	postFailureImgUrl = setCIstatusUrl(ci.Post_Failed_Deployment_Jobs__r.Status__c);
        //ci = new Continuous_Integration__c();
        //ci = (Continuous_Integration__c)controller.getRecord();
        return null;
    }
    public static String setCIstatusUrl(String status){
        if(status=='Success'||status=='Completed Successfully')return 'img/icons/confirm24.png';
        else if(status=='Failed'||status=='Completed with Errors')return 'img/icons/error24.png';
        else if(status=='In Progress')return 'img/icons/loading.gif';
        return 'img/icons/s.gif'; //empty 1px image.
    }
    public static String setValidationImageUrl(String validationStatus){
        String fn = '';
        if(validationStatus.toLowerCase()=='none')fn='warning';
        if(validationStatus.toLowerCase()=='ok')fn='confirm';
        if(validationStatus.toLowerCase()=='error')fn='error';
    	return (fn=='')?'img/icons/s.gif':'img/icons/'+fn+'24.png';
    }
    public PageReference executeCI(){
        if(!FeatureHelper.isFeatureEnabled('Continuous Integration')){
            Apexpages.addMessage(new apexpages.Message(ApexPages.Severity.ERROR, Label.FEATURE_NOT_SUPPORTED+' Continuous Integration'));
            isCIenabled = false;
            return null;
        }
        List<Continuous_Integration_Permission__c> cips = new List<Continuous_Integration_Permission__c>();
        if(Schema.SObjectType.Continuous_Integration_Permission__c.isQueryable() && Schema.SObjectType.Continuous_Integration_Permission__c.isAccessible()){
            cips = [SELECT Id, User__c, Access__c FROM Continuous_Integration_Permission__c WHERE Continuous_Integration__c =:ci.Id];
        }
    	boolean isAllowed = false;
    	for(Continuous_Integration_Permission__c cip : cips){
    		if(cip.User__c == UserInfo.getUserId()){
    			isAllowed = (cip.Access__c=='Read Only')?false:true;
    		}
    	}
    	if(isAllowed){
    		DeployAPI.executeCI(ci.Id);
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The run has been scheduled and a Build Task will be shown as soon as it\'s ready.'));
    	}
    	else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to run this Continuous Integration.'));
    	}
    	return null;
    }
    public void showHookUrl(){
        List<Continuous_Integration_Permission__c> perms = new List<Continuous_Integration_Permission__c>();
        if(Schema.SObjectType.Continuous_Integration_Permission__c.isQueryable() && Schema.SObjectType.Continuous_Integration_Permission__c.isAccessible()){
            perms = [SELECT Id, User__c, Access__c FROM Continuous_Integration_Permission__c WHERE Continuous_Integration__c =:ci.Id AND User__c =:UserInfo.getUserId()];
        }
        for(Continuous_Integration_Permission__c perm : perms){
            if(perm.Access__c=='Run Continuous Integration'){
                showHookUrl = true;
                if(String.isBlank(mySettings.API_Key__c)){
                    DeployApi.createAPIKey();
                }
                hookUrl = Settings.server_url+'/json/v1/webhook/ci/'+ci.Id+'?api_key='+DeployAPI.getUserAPIKey();
                return;
            }
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot view the Hook URL because you do not have the permission "Run Continuous Integration" assigned.'));
    }
    public void hideHookUrl(){
        showHookUrl = false;
    }
    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public String errorLevel {get; set;}
    public String messageName {get; set;}
    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.WARNING;
        }else{
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
    }
}