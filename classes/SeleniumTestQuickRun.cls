public with sharing class SeleniumTestQuickRun {
    public static String copadoURL = settings.Server_URL;

    public Selenium_Test_Run__c run { get; set; }
    public Selenium_Test_Suite__c suite { get; set; }
    public Selenium_Settings__c settings { get; set; }

    public String returnUrl { get; set; }
    public String mode { get; set; }
    public Integer count_cases { get; set; }

    private String runId;
    private String suiteId;
    private String caseId;
    public String userAlias;
    private Boolean noDML;
    public final String hostUrl {
    get{
        if(String.isBlank(hostUrl)){
            hostUrl = URL.getSalesforceBaseUrl().getProtocol() + '://' + ApexPages.currentPage().getHeaders().get('Host');
        }
        return hostUrl;
    }set;}
    private final String QUICKRUN = ' Quick Run ';
    private final String QUICKTESTSETTINGS = ' Quick Test Settings';
    private final String C_COMPLETED = 'completed';
    private final String C_CONTINUE = 'continue';
    private final String C_RUNID = 'runId';

    public SeleniumTestQuickRun() {
        returnUrl = Url.getSalesforceBaseUrl().toExternalForm();
        String modeParam = ApexPages.currentPage().getParameters().get('mode');
        mode = modeParam == null ? '' : modeParam;

        runId = ApexPages.currentPage().getParameters().get(C_RUNID);
        suiteId = ApexPages.currentPage().getParameters().get('suiteId');
        caseId = ApexPages.currentPage().getParameters().get('caseId');
        if(Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
            userAlias = [SELECT Alias FROM User WHERE Id = :UserInfo.getUserId()].Alias;
        }
        if(null != runId){
            if(Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                run = [
                        SELECT Id, Name, Last_Status__c, Org_Credential__r.Name, Selenium_Settings__c, Selenium_Test_Suite__c
                        FROM Selenium_Test_Run__c
                        WHERE Id = :runId
                ];
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING,Label.PermissionForTestRun));
            }
        }else{
            run = new Selenium_Test_Run__c();
        }

        if(null != run.Selenium_Test_Suite__c){
            if(Schema.SObjectType.Selenium_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Test_Suite__c.isAccessible()) {
                suite = [SELECT Id, Name FROM Selenium_Test_Suite__c WHERE Id = :run.Selenium_Test_Suite__c];
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING,Label.PermissionForTestSuite));
            }
        }else{
            suite = new Selenium_Test_Suite__c();
        }

        if(null != run.Selenium_Settings__c){
            if(Schema.SObjectType.Selenium_Settings__c.isQueryable() && Schema.SObjectType.Selenium_Settings__c.isAccessible()) {
                settings = [SELECT Id, Name FROM Selenium_Settings__c WHERE Id = :run.Selenium_Settings__c];
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Label.PermissionForSeleniumSetting));
            }
        }else{
            settings = new Selenium_Settings__c();
        }
    }

    public PageReference quickRunConfirmed() {
        mode = C_CONTINUE;
        return quickRun();
    }

    public PageReference save() {
        Selenium_Settings__c currentSetting = new Selenium_Settings__c(Name = userAlias + QUICKTESTSETTINGS);
        if(!Schema.SObjectType.Selenium_Settings__c.fields.Webdriver_URL__c.isCreateable() || !Schema.SObjectType.Selenium_Settings__c.fields.Default_Org_Credential__c.isCreateable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PermissionForSeleniumSetting));
            return null;
        }
        currentSetting.Webdriver_URL__c = settings.Webdriver_URL__c;
        currentSetting.Default_Org_Credential__c = settings.Default_Org_Credential__c;
        currentSetting.Provider__c = settings.Provider__c;
        currentSetting.Selected_Platforms__c = settings.Selected_Platforms__c;
        Utilities.Secure_DML(currentSetting, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Settings__c);
        return quickRun();
    }

    public PageReference cancel() {
        return new PageReference('/' + (runId != null ? runId : (suiteId != null ? suiteId : (caseId != null ? caseId : ''))));
    }

    /*
    * Find or create suite and/or run
    */
    private void findOrCreateRecords() {
        Selenium_Test_Case__c currentCase = null;
        String runName;
        if(caseId != null && Schema.SObjectType.Selenium_Test_Case__c.isQueryable() && Schema.SObjectType.Selenium_Test_Case__c.isAccessible()) {
            currentCase = [SELECT Name FROM Selenium_Test_Case__c WHERE Id = :caseId];
            runName = userAlias + QUICKRUN + currentCase.Name;
            if(Schema.SObjectType.Selenium_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Test_Suite__c.isAccessible()) {
                for(Selenium_Test_Suite__c currentSuite : [SELECT Id, Name FROM Selenium_Test_Suite__c WHERE Name = :runName ORDER BY CreatedDate DESC LIMIT 1]) {
                    suite = currentSuite;
                    break;
                }
            }
            if(suite.Id == null) {
                suite = new Selenium_Test_Suite__c(Name = runName.abbreviate(80));
                if(Schema.SObjectType.Selenium_Test_Suite__c.fields.Name.isCreateable()) {
                    Utilities.Secure_DML(suite, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Test_Suite__c);
                }
                Selenium_Test_Case_Per_Suite__c cs = new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c = suite.Id, Selenium_Test_Case__c = currentCase.Id);
                if(Schema.SObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Suite__c.isCreateable() && Schema.SObjectType.Selenium_Test_Case_Per_Suite__c.fields.Selenium_Test_Case__c.isCreateable()) {
                    Utilities.Secure_DML(cs, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Test_Case_Per_Suite__c);
                }
                noDML = false;
            }
        } else if(suiteId != null) {
            if(Schema.SObjectType.Selenium_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Test_Suite__c.isAccessible()) {
                suite = [SELECT Id, Name FROM Selenium_Test_Suite__c WHERE Id = :suiteId];
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING,Label.PermissionForTestSuite));
            }
            runName = suite.Name.startsWith(userAlias + QUICKRUN) ? suite.Name : userAlias + QUICKRUN + suite.Name;
            System.debug('runName==> '+runName);
        }

        if(Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
            for(Selenium_Test_Run__c currentRun : [
                    SELECT Id, Name
                    FROM Selenium_Test_Run__c
                    WHERE Name = :runName AND Selenium_Test_Suite__c = :suite.Id
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ]) {
                run = currentRun;
                break;
            }
        }

        if(run.Id == null) {
            run = new Selenium_Test_Run__c(
                    Name = runName.abbreviate(80),
                    Selenium_Settings__c = settings.Id,
                    Selenium_Test_Suite__c = suite.Id,
                    Org_Credential__c = settings.Default_Org_Credential__c,
                    Last_Status__c = null
            );
            if(Schema.SObjectType.Selenium_Test_Run__c.fields.Name.isCreateable() && Schema.SObjectType.Selenium_Test_Run__c.fields.Selenium_Settings__c.isCreateable() && Schema.SObjectType.Selenium_Test_Run__c.fields.Selenium_Test_Suite__c.isCreateable() && Schema.SObjectType.Selenium_Test_Run__c.fields.Last_Status__c.isCreateable() && Schema.SObjectType.Selenium_Test_Run__c.fields.Org_Credential__c.isCreateable()) {
                Utilities.Secure_DML(run, Utilities.DML_Action.INS, schema.SObjectType.Selenium_Test_Run__c);
            }
            noDML = false;
        }
        runId = run.Id;
    }

    public PageReference quickRun() {
        noDML = true;

        if(runId == null) {
            String name = userAlias + QUICKTESTSETTINGS;
            if(Schema.SObjectType.Selenium_Settings__c.isQueryable() && Schema.SObjectType.Selenium_Settings__c.isAccessible()) {
                for(Selenium_Settings__c currentSetting : [SELECT Id, Name, Selected_Platforms__c, Webdriver_URL__c, Default_Org_Credential__c, Provider__c FROM Selenium_Settings__c WHERE Name = :name ORDER BY CreatedDate DESC LIMIT 1]) {
                    settings = currentSetting;
                    break;
                }
            }
            if(settings.Id == null) {
                mode = 'create';
                return null;
            }

            findOrCreateRecords();
        }

        if(Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
            // now we always have a run and runId
            for(Selenium_Test_Run__c currentRun : [
                    SELECT Id, Name, Last_Status__c,
                            Org_Credential__r.Id, Org_Credential__r.Name,
                            Selenium_Test_Suite__r.Id, Selenium_Test_Suite__r.Name,
                            Selenium_Settings__r.Id, Selenium_Settings__r.Name,
                            Selenium_Settings__r.Webdriver_URL__c,
                            Selenium_Settings__r.Provider__c,
                            Selenium_Settings__r.Selected_Platforms__c,
                            Selenium_Settings__r.Default_Org_Credential__c
                    FROM Selenium_Test_Run__c
                    WHERE Id = :runId
                    LIMIT 1
            ]) {
                run = currentRun;
                suite = run.Selenium_Test_Suite__r;
                settings = run.Selenium_Settings__r;
                break;
            }
        }

        String laststatus = run.Last_Status__c == null ? C_COMPLETED : run.Last_Status__c;
        count_cases = 0;

        if(suite != null && suite.Id != null && Schema.SObjectType.Selenium_Test_Case_Per_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Test_Case_Per_Suite__c.isAccessible()) {
            count_cases = [SELECT COUNT() FROM Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :suite.Id];
        }

        if(!(laststatus.containsIgnoreCase('failure') || laststatus.containsIgnoreCase(C_COMPLETED)) && mode != C_CONTINUE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.This_test_is_already_running));
            PageReference pr = ApexPages.currentPage();
            mode = 'confirm';
            return null;
        }

        if(count_cases == 0 || settings == null || settings.Selected_Platforms__c == '' || suite == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Some of the values for the test run/suite/settings are missing'));
            PageReference pr = ApexPages.currentPage();
            mode = 'cancel';
            return null;
        }

        if(noDML) {
            // no changes to the DB. Execute the Test Run
            if(!Test.isRunningTest()) {
                try {
                    if(String.isBlank(settings.Provider__c) || String.isBlank(settings.Selected_Platforms__c)) {
                        // and now redirect to Settings page to select the provider and a browser
                        PageReference pr = new PageReference('/' + settings.Id + '/e');
                        pr.setRedirect(true);
                        return pr;
                    }

                    WebhookAPI.runSeleniumTest(run.Id, DeployAPI.getUserAPIKey());
                    Selenium_Test_Run__c currentRun = new Selenium_Test_Run__c();
                    if(Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                        currentRun = [SELECT Id FROM Selenium_Test_Run__c WHERE Id = :run.Id];
                    }

                    if(Schema.SObjectType.Selenium_Test_Run__c.fields.Last_Status__c.isCreateable()) {
                        currentRun.Last_Status__c = 'Queued';
                        Utilities.Secure_DML(currentRun, Utilities.DML_Action.UPD, schema.SObjectType.Selenium_Test_Run__c);
                    }
                } catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            // and now redirect to the Test results.
            PageReference pr = new apexpages.StandardController(run).view();
            pr.setRedirect(true);
            return pr;
        } else {
            // Quick Settings/Suite/Run were created, redirect to this very page.
            PageReference pr = Page.SeleniumTestQuickRun;
            pr.getParameters().put(C_RUNID, run.Id);
            pr.setRedirect(true);
            return pr;
        }
    }
}