/**
 * Extension of New, Edit and view page for External CI Job object.
 *
 * New, Edit and View pages are overriden by custom visualforce pages.
 * @author Mert YALTI
 * @date 19.06.2017
 * @see EditExternalCIJob
 * @see ViewExternalCIJob
 */
public with sharing class ExternalCIJobsExtension {
    public External_CI_Job__c externalCIjob { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public String url { get; set; }
    private String baseUrl { get; set; }
    public Boolean hasCache { get; set; }
    public String settingType { get; set; }
    public String tempJSON { get; set; }
    private External_CI_Setting__c setting { get; set; }
    public List<URLParameters> urlParams { get; set; }
    private Attachment att;
    public Datetime lastCacheDate { get; set; }
    private ExternalCIAPIFactory factory { get; set; }
    private External_CI_Job__c job { get; set; }
    public String jobName { get; set; }
    public List<ExternalCIAPIFactory.JobList> jobsList { get; set; }
    public List<External_CI_Job_Result__c> jobResults { get; set; }
    public ExternalCIJobsExtension(ApexPages.StandardController std) {
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        if(!Test.isRunningTest()) {
            std.addFields(new List<String>(Schema.SObjectType.External_CI_Job__c.fields.getMap().keySet()));
        }
        job = (External_CI_Job__c) std.getRecord();

        if(std.getId() != null) {
            externalCIjob = Utilities.getCIJobById(std.getId());
        } else {
            externalCIjob = new External_CI_Job__c();
        }
        setSetting(job.External_CI_Setting__c);
        externalCIjob.External_CI_Setting__c = job.External_CI_Setting__c;
        externalCIjob.User_Story__c = job.User_Story__c;
        externalCIjob.Environment__c = job.Environment__c;
        tempJSON = externalCIjob.dataJSON__c;
        if(externalCIjob.dataJSON__c != null) {
            if(urlParams == null) {
                urlParams = new List<URLParameters>();
            }
            Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(externalCIjob.dataJSON__c);
            List<Object> paramsList = (List<Object>) fullMap.get('parameters');
            for(Object o : paramsList) {
                Map<String, Object> temp = (Map<String, Object>) o;
                urlParams.add(new URLParameters(String.valueOf(temp.get('name')), String.valueOf(temp.get('value'))));
            }
        }
        jobListCache();
        getRelated();
    }
    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditExternalCI')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }
    /**
     * By using given settingId parameter this methods queries the External CI setting
     * This method also retrieves ci jobs cache [JobListCache] method.
     * @param settingId
     */
    @TestVisible private void setSetting(String settingId) {
        System.debug(LoggingLevel.ERROR, '*** settingId: ' + settingId);
        if(settingId != null) {
            setting = Utilities.getCISettingById(settingId);
            if(null != setting) {
                url = setting.Endpoint__c;
                if(externalCIjob.Job_Api_Name__c != null) {
                    url = url.endsWith('/') ? url.removeEnd('/') + '/job/' + externalCIjob.Job_Api_Name__c : url + '/job/' + externalCIjob.Job_Api_Name__c;
                }
                baseUrl = setting.Endpoint__c;
                settingType = setting.CI_Tool__c;
                externalCIjob.External_CI_Setting__c = setting.Id;
                jobListCache();
            }
        }
    }
    /**
     * Overloading method of setSetting.
     * If the setting id is not provided by the standard contoller
     * this method uses selected setting Id from the setting lookup.
     * @return PageReference
     */
    public PageReference setSetting() {
        String pageSettingId = ApexPages.currentPage().getParameters().get('setId');
        System.debug(LoggingLevel.ERROR, '*** pageSettingId: ' + pageSettingId);
        if(pageSettingId != null) {
            setSetting(pageSettingId);
            urlParams = new List<URLParameters>();
        }
        return new Apexpages.StandardController(externalCIjob).view();
    }
    /**
     * To increase the performance this methods retrieves the cache attachment from the selected setting and populates jobslist
     */
    public void jobListCache() {
        if(externalCIjob.External_CI_Setting__c != null) {
            jobsList = new List<ExternalCIAPIFactory.JobList>();
            try {
                if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()){
                    att = [SELECT Id, ParentId, Name, ContentType, BodyLength, Body, Description, CreatedDate, LastModifiedDate FROM Attachment WHERE ParentId = :externalCIjob.External_CI_Setting__c AND Name = 'jobList.json'];
                } else {
                    ApexPages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Schema.SObjectType.Attachment.getName() +': ' + Label.Insufficient_Access_Rights));
                }
                hasCache = true;
                if(att != null) {
                    lastCacheDate = att.LastModifiedDate;
                }
                jobsList.addAll((List<ExternalCIAPIFactory.JobList>) JSON.deserialize(att.Body.toString(), List<ExternalCIAPIFactory.JobList>.class));
            } catch(Exception e) {
                hasCache = false;
            }
        }
    }
    /**
     * This methods creates cache attachment on selected setting record.
     * @param List<ExternalCIAPIFactory.JobList> jobList
     */
    private void createJobListAttachment(List<ExternalCIAPIFactory.JobList> jobList) {
        Attachment cache = new Attachment(
                Name = 'jobList.json',
                ParentId = externalCIjob.External_CI_Setting__c,
                Body = Blob.valueOf(JSON.serialize(jobList))
        );
        lastCacheDate = Datetime.now();
        Utilities.Secure_DML(cache, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
    }
    /**
     * Sends GET request to Copado Heroku backend to get available jobs list from the external ci tool by using selected setting setup.
     * @return PageReference
     * @see HttpRequest
     * @see  ExternalCIAPIFactory
     */
    public String requestLabel;
    /**
     * Overrides standard delete function
     * @return Pagereference
     * @see Utilities
     */
    public PageReference deleteJob() {
        if(externalCIjob.Id != null) {
            PageReference retPage;
            if(setting != null) {
                retPage = new PageReference('/' + setting.Id);
            } else {
                retPage = new PageReference('/home/home.jsp');
            }
            retPage.setRedirect(true);
            try {
                Utilities.Secure_DML(externalCIjob, Utilities.DML_Action.DEL, schema.SObjectType.External_CI_Job__c);
                return retPage;
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ERROR + ' : ' + e.getMessage()));
                return null;
            }
        }
        return null;
    }

    public PageReference retrievejobsList() {
        jobsList = new List<ExternalCIAPIFactory.JobList>();
        lastCacheDate = Datetime.now();
        if(externalCIjob.External_CI_Setting__c != null) {
            if(setting == null) {
                setSetting(externalCIjob.External_CI_Setting__c);
            }
            factory = new ExternalCIAPIFactory(externalCIjob.External_CI_Setting__c);
            String retrieveUrl = DeployAPI.copadoURL + '/json/v1/getJobsXCI/' + externalCIjob.External_CI_Setting__c;
            retrieveUrl += '?uri=' + EncodingUtil.urlEncode(setting.Endpoint__c, 'UTF-8') + '&type=' + setting.CI_Tool__c;
            try {
                Map<String, String> optionalHeader = new Map<String, String>();
                Sensitive_Information__c externalCIConfiguration = Sensitive_Information__c.getValues(setting.Id);
                if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Username__c)) {
                    optionalHeader.put('un', externalCIConfiguration.Username__c);
                }
                if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Password__c)) {
                    optionalHeader.put('pw', DeployAPI.decryptAPIKey(externalCIConfiguration.Password__c));
                }
                if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.API_Token__c)) {
                    optionalHeader.put('tk', externalCIConfiguration.API_Token__c);
                }
                HttpResponse res = factory.sendRequest(retrieveUrl, 'GET', optionalHeader, true);
                Map<String, Object> fullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Boolean success = fullMap.get('error') == null;
                if(success) {
                    List<ExternalCIAPIFactory.JobList> parsedBodyList = (List<ExternalCIAPIFactory.JobList>) factory.parseResponseBody('Listing', res);
                    for(ExternalCIAPIFactory.JobList joblst : parsedBodyList) {
                        jobsList.add(new ExternalCIAPIFactory.JobList(joblst.jobName, joblst.url));
                    }
                    if(!hasCache) {
                        createJobListAttachment(jobsList);
                    } else {
                        att.Body = Blob.valueOf(JSON.serialize(jobsList));
                        Utilities.Secure_DML(att, Utilities.DML_Action.UPD, schema.SObjectType.Attachment);
                    }
                    lastCacheDate = Datetime.now();
                    return null;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.WRONG_CREDENTIALS));
                }
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NO_JOB_FOUND));
            }
        }
        return null;
    }
    /**
     * Overrides standard save method
     * @return PageReference
     */
    public PageReference saveJob() {
        try {
            if(externalCIjob.External_CI_Setting__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NO_SETTING_SELECTED));
            }
            if(url != null) {
                if(!String.isBlank(tempJSON)) {
                    List<Object> paramsList = (List<Object>) JSON.deserializeUntyped(tempJSON);
                    urlParams = new List<URLParameters>();
                    String name;
                    String value;
                    for(Object gen : paramsList) {
                        List<Object> innerArrayList = (List<Object>) gen;
                        Integer i = 0;
                        for(Object obj : innerArrayList) {
                            if(i == 0) {
                                name = String.valueOf(obj);
                            }
                            if(i == 1) {
                                value = String.valueOf(obj);
                            }
                            i++;
                        }
                        urlParams.add(new URLParameters(name, value));
                    }
                    externalCIjob.dataJSON__c = JSON.serialize(new Parameters(urlParams));
                }
                if(jobName != null && jobName != externalCIjob.Job_Api_Name__c) {
                    externalCIjob.Job_Api_Name__c = jobName;
                }
                Utilities.Secure_DML(externalCIjob, Utilities.DML_Action.UPS, schema.SObjectType.External_CI_Job__c);
                return new apexpages.StandardController(externalCIjob).view();
                //}
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PLEASE_ENTER_VALID_URL));
                return null;
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.PLEASE_ENTER_VALID_URL));
            return null;
        }
    }
    /**
     * TODO: make this a dynamic static method in the factory class to make it work for different sObject types and reusable
     */
    public void getRelated() {
        jobResults = ExternalCIAPIFactory.queryAllValues('External_CI_Job_Result__c', 'External_CI_Job__c', externalCIjob.Id, '', '');
    }
    /**
     * Sends request to Heroku backend to build the job in the external ci tool.
     */
    public void BuildJob() {
        ExternalCIAPIFactory factory = new ExternalCIAPIFactory(setting.Id);

        String url = DeployAPI.copadoURL + '/json/v1/runJobXCI/' + externalCIjob.Id;
        url += '?uri=' + EncodingUtil.urlEncode(setting.Endpoint__c, 'UTF-8') + '&type=' + setting.CI_Tool__c;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        Map<String, String> optionalHeaderMap = new Map<String, String>();
        Sensitive_Information__c externalCIConfiguration = Sensitive_Information__c.getValues(setting.Id);
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Username__c)) {
            optionalHeaderMap.put('un', externalCIConfiguration.Username__c);
        }
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.Password__c)) {
            optionalHeaderMap.put('pw', DeployAPI.decryptAPIKey(externalCIConfiguration.Password__c));
        }
        if(externalCIConfiguration != null && String.isNotBlank(externalCIConfiguration.API_Token__c)) {
            optionalHeaderMap.put('tk', externalCIConfiguration.API_Token__c);
        }
        HttpResponse res = factory.sendRequest(url, 'POST', optionalHeaderMap, true);
        ExternalCIAPIFactory.JobStatus parsedResult = (ExternalCIAPIFactory.JobStatus) factory.parseResponseBody('STATUS', res);
        if(parsedResult.message == null) {
            EditExternalCISetting.validateConnection(setting);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, parsedResult.message != null ? parsedResult.message : 'Could not retrieve status message'));
        }
    }
    /**
     * Captures selected job details
     */
    public PageReference selectJob() {
        if(jobName != externalCIjob.Job_Api_Name__c) {
            if(urlParams != null) {
                urlParams.clear();
            }
            externalCIjob.Job_Api_Name__c = jobName;
            url = baseUrl.endsWith('/') ? baseUrl + 'job/' + jobName : baseUrl + '/job/' + jobName ;
        }
        return null;
    }
    /**
     * Creates instance for a url param
     */
    public void addUrlParam() {
        if(urlParams == null) {
            urlParams = new List<URLParameters>();
        }
        urlParams.add(new URLParameters('', ''));
    }
    /**
     * removes pointed parameter from the url params list
     */
    public void removeUrlParam() {
        Integer sOrder = Integer.valueOf(ApexPages.currentPage().getParameters().get('order'));
        try {
            urlParams.remove(sOrder);
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
    /**
     * Wrapper class for url parameters
     */
    public class Parameters {
        public List<URLParameters> parameters { get; set; }
        public Parameters(List<URLParameters> parameters) {
            this.parameters = parameters;
        }
    }
    public class URLParameters {
        public String name { get; set; }
        public String value { get; set; }
        public URLParameters(String key, String value) {
            this.name = key;
            this.value = value;
        }
    }
}