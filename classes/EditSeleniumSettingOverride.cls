/**
 * Created by umitcanuckan on 23/11/2018.
 */

public with sharing class EditSeleniumSettingOverride {
    public Selenium_Settings__c SeleniumSetting;
    public Boolean isDefOrgCredRequired {
    get{
        if(null == isDefOrgCredRequired){
            isDefOrgCredRequired = false;
        }
        return isDefOrgCredRequired;
        }
        set;
    }
    public String aliasString {
    get{
        if(String.isBlank(aliasString)){
            aliasString = ApexPages.currentPage().getParameters().get('fromQuickRun');
        }
        return aliasString;
        }
        set;
    }
    public String retUrl {get;set;}
    private final String CASEID = 'caseId';
    private final String SUITEID = 'suiteId';
    private final String QUICKTESTSETTINGS = ' Quick Test Settings';
    public EditSeleniumSettingOverride(ApexPages.StandardController stdController) {
        this.SeleniumSetting = (Selenium_Settings__c)stdController.getRecord();
        if(String.isNotBlank(aliasString)){
            SeleniumSetting.Name = aliasString + QUICKTESTSETTINGS;
            isDefOrgCredRequired = true;
        }
    }
    public PageReference saveMethod(){
        Utilities.Secure_DML(SeleniumSetting, Utilities.DML_ACTION.UPS, Schema.SObjectType.Selenium_Settings__c);
        PageReference ref;
        if(String.isNotBlank(aliasString)){
            String fullUrl = '/apex/' + Settings.ns + 'SeleniumTestQuickRun'  +retUrl;
            ref = new PageReference(fullUrl);
        }else{
            ref = new PageReference('/' + SeleniumSetting.Id);
        }
        ref.setRedirect(true);
        System.debug('saveMethod '+ref);
        return ref;
    }

    public PageReference goBackToQuickRunPage(){
        String caseId = ApexPages.currentPage().getParameters().get(CASEID);
        String suiteId = ApexPages.currentPage().getParameters().get(SUITEID);
        String fullurl = '/' + (String.isNotBlank(caseId) ? Id.valueOf(caseId) : Id.valueOf(suiteId));
        PageReference ref = new PageReference(fullurl);
        ref.setRedirect(true);
        System.debug('goBackToQuickRunPage '+ref);
        return ref;
    }
}