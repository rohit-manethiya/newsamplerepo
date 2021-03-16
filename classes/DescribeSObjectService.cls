public with sharing class DescribeSObjectService {
    private static final String API_SERVER_URL = Settings.server_url;

    @TestVisible
    private static final String GLOBAL_DESCRIBE_ENDPOINT = '/json/v1/organization/{0}/metadata/describeGlobal';
    @TestVisible
    private static final String DESCRIBE_ENDPOINT = '/json/v1/organization/{0}/metadata/{1}/describe';
    @TestVisible
    private static final String DESCRIBE_FULL_ENDPOINT = '/json/v1/metadata/describe/full/{0}/{1}';

    private static final String GLOBAL_DESCRIBE_URL = API_SERVER_URL + GLOBAL_DESCRIBE_ENDPOINT;
    private static final String DESCRIBE_URL = API_SERVER_URL + DESCRIBE_ENDPOINT;
    private static final String DESCRIBE_ALL_FIELDS_URL = API_SERVER_URL + DESCRIBE_FULL_ENDPOINT;

    private String orgId;

    private static List<String> disabledObjects {
        get {
            if (disabledObjects == null) {
                disabledObjects = new List<String>();
                List<Data_Template_Setup__mdt> settings = [
                    SELECT API_Names__c
                    FROM Data_Template_Setup__mdt
                    WHERE DeveloperName = 'Disabled_Main_Objects'
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (!settings.isEmpty()) {
                    disabledObjects = settings[0].API_Names__c.split(',');
                }
            }
            return disabledObjects;
        }
        set;
    }

    public DescribeSObjectService(String orgId) {
        this.orgId = orgId;
    }

    public DescribeGlobalResponse getObjects() {
        String url = String.format(GLOBAL_DESCRIBE_URL, new List<String>{ encodeUtf8(this.orgId) });

        return (DescribeGlobalResponse) new HerokuCallout(url, HttpMethod.GET)
            .default()
            .request()
            .type(DescribeGlobalResponse.class)
            .parseResponse();
    }

    public DescribeResponse getCreateableUpdateableFields(String mainObject) {
        String url = String.format(DESCRIBE_URL, new List<String>{ encodeUtf8(this.orgId), encodeUtf8(mainObject) });

        return (DescribeResponse) new HerokuCallout(url, HttpMethod.GET)
            .default()
            .request()
            .type(DescribeResponse.class)
            .parseResponse();
    }

    public DescribeResponse getFields(String mainObject) {
        String url = String.format(DESCRIBE_ALL_FIELDS_URL, new List<String>{ encodeUtf8(this.orgId), encodeUtf8(mainObject) });

        return (DescribeResponse) new HerokuCallout(url, HttpMethod.GET)
            .default()
            .request()
            .type(DescribeResponse.class)
            .parseResponse();
    }

    private static String encodeUtf8(String value) {
        return EncodingUtil.urlEncode(value, 'UTF-8');
    }

    public with sharing class DescribeGlobalResponse {
        public Boolean success;
        public String error;
        public Boolean retryOnError;
        public String encoding;
        public Integer maxBatchSize;
        public List<CopadoObject> sobjects;
    }

    public with sharing class CopadoObject implements Comparable {
        public Boolean custom;
        public String label;
        public String name;
        public Boolean queryable;
        public Boolean triggerable;
        public Boolean updateable;

        public Boolean isCustomMetadataType() {
            return name.containsIgnoreCase('__mdt');
        }

        public Boolean isPlatformEvent() {
            return name.containsIgnoreCase('__e');
        }

        public Boolean isDisabled() {
            return disabledObjects.contains(name);
        }

        public Integer compareTo(Object compareTo) {
            CopadoObject compareToObject = (CopadoObject) compareTo;
            return label.compareTo(compareToObject.label);
        }
    }

    public with sharing class DescribeResponse {
        public Boolean success;
        public String error;
        public Boolean retryOnError;
        public List<CopadoChildRelationship> childRelationships;
        public List<CopadoField> fields;
        public Boolean custom;
        public String label;
    }

    public with sharing class CopadoField implements Comparable {
        public Boolean autoNumber;
        public Boolean calculated;
        public Boolean createable;
        public Boolean custom;
        public Boolean filterable;
        public Boolean idLookup;
        public String label;
        public Integer length;
        public String name;
        public Boolean nameField;
        public Boolean nillable;
        public Integer relationshipOrder;
        public List<String> referenceTo;
        public String soapType;
        public Boolean sortable;
        public String type;
        public Boolean unique;
        public Boolean updateable;
        public Boolean writeRequiresMasterRead;
        public Boolean externalId;

        public Boolean isCompound() {
            return type == 'address' || type == 'location';
        }

        public Boolean isId() {
            return type == 'id';
        }

        public Boolean isReference() {
            return type == 'reference' && referenceTo != null;
        }

        public Integer compareTo(Object compareTo) {
            CopadoField compareToField = (CopadoField) compareTo;
            return label.compareTo(compareToField.label);
        }
    }

    public with sharing class CopadoChildRelationship {
        public String childSObject;
        public String field;
        public String relationshipName;
    }
}