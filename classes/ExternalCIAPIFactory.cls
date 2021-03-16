/**
 * This is the factory class for external CI APIs
 * By using passed CI Setting Id this class decides which API to use to send an HTTP request and how to parse its body.
 * @author Mert YALTI
 * @date 16.06.2017
 * @see  IExternalCIAPI
 * @exception UnsupportedTypeException If requested CI setting does not have a supported API class within Copado this exception will be thrown
 */
public with sharing class ExternalCIAPIFactory {
    public final IExternalCIAPI api;
    public final External_CI_Setting__c setting;
    /**
     * Constructor method for this class
     * Finds suitable api for requested CI Setting
     * @param ciSettingId Id of requested CI Setting
     * @return N/A
     */
    public ExternalCIAPIFactory(String ciSettingId) {
        if (ciSettingId == null)
            throw new UnsupportedTypeException(Label.NO_SETTING_SELECTED);
        this.setting = getCISetting(ciSettingId);
        try {
            if (apis.containsKey(setting.CI_Tool__c)) {
                this.api = (IExternalCIAPI) apis.get(setting.CI_Tool__c).newInstance();
            } else {
                throw new UnsupportedTypeException(Label.UNSUPPORTED_CI_TOOL_TYPE + ' ' + setting.CI_Tool__c);
            }
        } catch (Exception e) {
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
    }
    /**
     * Sends HTTP request to the external CI tool by using valid API
     * @param endPoint Http request endpoint url
     * @param method Http request method (POST,GET,DELETE etc)
     * @param optionalHeaders Auth header is automatical other than that you can setting more headers is optional
     * @param isInternal True if the request endpoint is Copado backend Heroku endpoint otherwise false
     * @return HttpResponse
     */
    public HttpResponse sendRequest(String urlParameters, String method, Map<String, String> optionalHeaders, Boolean isInternal) {
        //String url = setting.Endpoint__c;
        //url += url.endsWith('/') ? urlParameters.removeStart('/') : urlParameters;
        return api.sendRequestToCI(urlParameters, method, optionalHeaders, isInternal);
    }
    /**
     * Sends HTTP request to the external CI tool by using valid API
     * @param endPoint Http request endpoint url
     * @param method Http request method (POST,GET,DELETE etc)
     * @param optionalHeaders Auth header is automatical other than that you can setting more headers is optional
     * @return HttpResponse
     */
    public HttpResponse sendRequest(String urlParameters, String method, Map<String, String> optionalHeaders) {
        return sendRequest(urlParameters, method, optionalHeaders, false);
    }
    /**
     * Parses body of HttpResponse
     * @param String response body
     * @return Object Since more than one type of CI tool can be supported this method returns Object so developers will be able to cast the result to the suitable type
     */
    public Object parseResponseBody(String type, HttpResponse response) {
        return api.parseResponseBody(type, response);
    }

    static final Map<String, Type> apis = new Map<String, Type>{
        'Jenkins' => JenkinsAPI.class,
        'Bamboo' => JenkinsAPI.class,
        'Team City' => TeamCityAPI.class
    };
    /**
     * Custom exception
     * @see Exception
     */
    public class UnsupportedTypeException extends Exception {
    }
    /**
     * By using given CI Setting Id this method queries the setting to retrieve all required fields.
     * @param ciSettingId
     * @return External_CI_Setting__c
     */
    public External_CI_Setting__c getCISetting(String ciSettingId) {
        return (External_CI_Setting__c) Utilities.queryAllfields('External_CI_Setting__c', ciSettingId);
    }

    public class Validate {
        public Boolean success { get; set; }
        public String message { get; set; }
        public Validate(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
    /**
     * Data normalization wrapper class for job lists
     * By using this type we can normalize job lists regardless of the CI tool
     */
    public class JobList {
        public String jobName { get; set; }
        public String url { get; set; }
        public JobList(String name, String url) {
            this.jobName = name;
            this.url = url;
        }
    }
    /**
     * Data normalization wrapper class for job status
     * By using this type we can normalize job statuses regardless of the CI tool
     */
    public class JobStatus {
        public String message { get; set; }
        public JobStatus(String message) {
            this.message = message;
        }
    }
    static String SOQL_STRING = 'SELECT {0} FROM {1} WHERE {3} =: {2}';
    public static List<SObject> queryAllValues(
        String sObjectName,
        String whereField,
        String recordId,
        String additionalWhereClause,
        String limitClause
    ) {
        if (recordId != null) {
            recordId = EncodingUtil.urlEncode(recordId, 'UTF-8');
            Map<String, String> d = Utilities.getAllFields(sObjectName);
            whereField = !whereField.startsWith(Settings.ns) && whereField.endsWith('__c') ? Settings.ns + whereField : whereField;
            String queryStr =
                'SELECT ' +
                d.get(Label.FIELDS) +
                ' FROM ' +
                d.get(Label.OBJECT) +
                ' WHERE ' +
                String.escapeSingleQuotes(whereField) +
                ' =:recordId';
            if (additionalWhereClause != null) {
                queryStr += ' ' + additionalWhereClause;
            }
            if (limitClause != null) {
                queryStr += ' ' + limitClause;
            }
            System.debug('QUERY: ' + queryStr);
            List<SObject> sos = Database.query(queryStr);
            if (!sos.isEmpty()) {
                return sos;
            }
        }
        return null;
    }
}