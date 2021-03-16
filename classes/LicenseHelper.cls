public with sharing class LicenseHelper {
	public boolean copadoEnabled {get;set;}
    public boolean ccmEnabled {get;set;}
    public boolean cstEnabled {get;set;}
    public boolean cadEnabled {get;set;}
    public boolean cchEnabled {get;set;}
    public boolean licensesExceeded {get;set;}
    public static Id automatedProcessTriggeringUserId;
    public static LicenseManagerController lmc = new LicenseManagerController();

    public static boolean isCopadoEnabled(){
        Copado_License__c lics = null != automatedProcessTriggeringUserId ? Copado_License__c.getInstance(automatedProcessTriggeringUserId) : Copado_License__c.getInstance();
        Boolean disableCopado = lmc.enableMultiLicenses == true && lics.Enable_Copado__c == false;
		System.debug('***** Checking Copado License =  ' + lics.Enable_Copado__c + ' Copado enabled = ' + !disableCopado + ' lmc.enableMultiLicenses = ' + lmc.enableMultiLicenses);
		return !disableCopado;
	}

    public static boolean isCCMEnabled(){//SI CCM
        Copado_License__c lics = null != automatedProcessTriggeringUserId ? Copado_License__c.getInstance(automatedProcessTriggeringUserId) : Copado_License__c.getInstance();
        Boolean disableCCM = lmc.enableMultiLicenses == true && lics.Enable_CCM__c == false && lics.Enable_Copado__c == false;
		System.debug('***** Checking CCM license. multi =  ' + lmc.enableMultiLicenses + ' License ccm =  ' + lics.Enable_CCM__c + ' Copado enabled = ' + lics.Enable_Copado__c+ ' CCM enabled = ' + !disableCCM);
		return !disableCCM;//TRUE
	}
    
    public static boolean isCSTEnabled(){
        Copado_License__c lics = null != automatedProcessTriggeringUserId ? Copado_License__c.getInstance(automatedProcessTriggeringUserId) : Copado_License__c.getInstance();
        Boolean enableCST = lmc.enableMultiLicenses == true && lics.Enable_CST__c == true;
		System.debug('***** Checking CST License =  ' + lics + ' CST enabled = ' + enableCST);
		return enableCST;
	}
    public static boolean isCADEnabled(){
        Copado_License__c lics = null != automatedProcessTriggeringUserId ? Copado_License__c.getInstance(automatedProcessTriggeringUserId) : Copado_License__c.getInstance();
        Boolean enableCAD = lmc.enableMultiLicenses == true && lics.Enable_CAD__c == true;
        //System.debug('***** Checking CAD license. Settings =  ' + settings + ' License =  ' + lics + ' CAD enabled = ' + enableCAD);
        return enableCAD;
    }

    @AuraEnabled
    public static boolean isCCHEnabled(){ //COpado COmpliance
        Copado_License__c lics = null != automatedProcessTriggeringUserId ? Copado_License__c.getInstance(automatedProcessTriggeringUserId) : Copado_License__c.getInstance();
        Boolean enableCCH = lmc.enableMultiLicenses == true && lics.Enable_CCH__c == true;
        //System.debug('***** Checking CAD license. Settings =  ' + settings + ' License =  ' + lics + ' CAD enabled = ' + enableCAD);
        return enableCCH;
    }
    public static boolean actionIsLicenseEnabled(String action){ 
        if(!isMultiLicense()) {return true;} //Non Multilicense CAN perform all.
        if(action.equals('commitFiles') && (isCCMEnabled() || isCopadoEnabled())) {return true;}
        if(action.equals('selectMetadata') && (isCCMEnabled() || isCopadoEnabled())) {return true;}
        if(action.equals('callOut') && (isCCHEnabled()||isCSTEnabled() || isCCMEnabled() || isCopadoEnabled())) {return true;}
        if(action.equals('viewUserStoryPage') && (isCCMEnabled() || isCopadoEnabled() || isCADEnabled() || isCSTEnabled() || isCCHEnabled())) {return true;}
        if(action.equals('viewEditOrgCredential')) {return true;}
        if(action.equals('viewEditOrgDifferences') && (isCopadoEnabled())) {return true;}
        if(action.equals('viewEditGitSnapshot') && (isCopadoEnabled() || isCCHEnabled() || isCCMEnabled())) {return true;}
        if(action.equals('viewEditGitRepository') && (isCopadoEnabled() || isCCHEnabled())) {return true;}
		if(action.equals('viewEditSnapshotDifferences') && (isCopadoEnabled() || isCCMEnabled())) {return true;}
        if(action.equals('viewEditScheduledJob') && (isCopadoEnabled() || isCSTEnabled())) {return true;}
        if(action.equals('viewEditExternalCI') && (isCopadoEnabled() || isCCMEnabled())) {return true;}
        if(action.equals('viewEditDeployment') && (isCopadoEnabled() || isCCMEnabled() || isCCHEnabled())) {return true;}
        if(action.equals('requestStaticCodeAnalysis') && (isCopadoEnabled() || isCCMEnabled())) {return true;}
        if(action.equals('requestComplianceScan') && (isCopadoEnabled() || isCCMEnabled() || isCCHEnabled())) {return true;}
        if(action.equals('viewSetupWarning') && (!isCADEnabled() || (isCADEnabled() && (isCCMEnabled() || isCSTEnabled() || isCCHEnabled()|| isCopadoEnabled())))) {return true;}
        if(action.equals('WorkManager') && (isCCMEnabled() || isCopadoEnabled() || isCADEnabled() || isCSTEnabled() || isCCHEnabled())) {return true;}
        return false;
    } 

    public static boolean isMultiLicense(){
        return lmc.enableMultiLicenses;
    }

    public static boolean isLicensesExceeded() {
        if(lmc.enableMultiLicenses == false) return false;
        if(lmc.copadoLicensesUsed>lmc.copadoLicensesAvailable)return true;
        if(lmc.ccmLicensesUsed>lmc.ccmLicensesAvailable)return true;
        if(lmc.cstLicensesUsed>lmc.cstLicensesAvailable)return true;
        if(lmc.cchLicensesUsed>lmc.cchLicensesAvailable)return true;
        return false;
    }
    
    //Constructors
    private void constructor(){
        copadoEnabled = isCopadoEnabled();
        ccmEnabled = isCCMEnabled();
        cstEnabled = isCSTEnabled();
        cadEnabled = isCADEnabled(); 
        cchEnabled = isCCHEnabled(); 
        licensesExceeded = isLicensesExceeded();
    }
    public LicenseHelper(){
        constructor();
    }
    public LicenseHelper(ApexPages.StandardController stdController){
        constructor();
    }  
    public LicenseHelper(SeleniumTestQuickRun stdController){
        constructor();
    }

    /**
    * Returns null (CST feature is enabled and the user has license), or a suitable error message for the lack of feature or lack of license.
    **/
    public static String getPossibleCSTErrorMsg() {
        // check the FEATURE
        if(lmc.enableMultiLicenses == false)
            return Label.SELENIUM_NOT_ENABLED;

        boolean featureFound = lmc.cstLicensesAvailable >0;
        if(!featureFound)
            return Label.SELENIUM_NOT_ENABLED;

        Copado_License__c lics = Copado_License__c.getInstance();
        if(!lics.Enable_CST__c)
            return Label.SELENIUM_NOT_LICENSED;

        return null;
    }//Changes
}