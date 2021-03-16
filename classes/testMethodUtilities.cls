@IsTest
public with sharing class testMethodUtilities {
    public static Deployment__c create(String name, Datetime dt1, Datetime dt2, Id fromOrgId, String schedule, String status) {
        Deployment__c x = new Deployment__c();
        x.Name = name;
        x.Date__c = dt1;
        x.Deployment_command_sent__c = dt2;
        x.From_Org__c = fromOrgId;
        x.Schedule__c = schedule;
        x.Status__c = status;
        return x;
    }

    public static Deployment_Job__c create(Integer numDeployed, Id destOrgId, String extId, String status, Id stepId) {
        Deployment_Job__c x = new Deployment_Job__c();
        x.Deployed__c = numDeployed;
        x.Destination_Org__c = destOrgId;
        x.External_Id__c = extId;
        x.Status__c = status;
        x.Step__c = stepId;
        return x;
    }

    public static Step__c create(String name, String attId, String djson, Id deploymentId, Integer numOrder, String status, String stype) {
        Step__c x = new Step__c();
        x.Name = name;
        x.Attachment_Id__c = attId;
        x.dataJson__c = djson;
        x.Deployment__c = deploymentId;
        x.Order__c = numOrder;
        x.Status__c = status;
        x.Type__c = stype;
        return x;
    }

    public static Destination_Org__c create(Id deploymentId, String status, Id toOrgId) {
        Destination_Org__c x = new Destination_Org__c();
        x.Deployment__c = deploymentId;
        x.Status__c = status;
        x.To_Org__c = toOrgId;
        return x;
    }

    public static Org__c createOrg(String name, String orgType, String sfdcorgid, String token, String un, Datetime vd) {
        Org__c x = new Org__c();
        x.Name = name;
        x.Org_Type__c = orgType;
        x.SFDC_Org_ID__c = sfdcorgid;
        x.Token__c = token;
        x.Username__c = un;
        x.Validated_Date__c = vd;
        return x;
    }

    public static Git_Repository__c createGitRepository(String name, String uri) {
        Git_Repository__c x = new Git_Repository__c();
        x.Name = name;
        x.URI__c = uri;
        return x;
    }

    public static Git_Backup__c create(String s, String b, String f, Git_Repository__c gr, Date lb, Org__c o) {
        Git_Backup__c x = new Git_Backup__c();
        x.Name = s;
        x.Branch__c = b;
        x.Frequency__c = f;
        x.Git_Repository__c = gr.Id;
        x.Last_Backup__c = lb;
        x.Org__c = o.Id;
        return x;
    }

    public static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(ParentId = parentId, Name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }

    public static Boolean hasMessage(String s) {
        Boolean b = false;
        for (ApexPages.Message msg : ApexPages.getMessages()) {
            if (msg.getDetail().contains(s)) {
                b = true;
            }
        }
        return b;
    }

    public static void enableSelenium() {
        Settings__c s = Settings__c.getOrgDefaults();
        if (!s.Enabled_Multi_Licenses__c) {
            s.Enabled_Multi_Licenses__c = true;
            upsert s;
        }
        Copado_License__c lics = Copado_License__c.getInstance();
        if (!lics.Enable_CST__c) {
            lics.Enable_CST__c = true;
            upsert lics;
        }
        // "simulate" an API Key, since testmethods do not support webservice callouts inside DeployAPI.createAPIKey();
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }
    }

    public static String getTestNameSpace() {
        if ([SELECT Id, Name, NamespacePrefix FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'].size() == 1) {
            return 'copado__';
        }
        return 'none';
    }

    public static Settings__c upsertOrgwideSettings() {
        Settings__c s = Settings__c.getOrgDefaults();
        s.Namespace__c = testMethodUtilities.getTestNameSpace();
        s.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        s.CryptoKEY__c = EncodingUtil.base64Encode(key);
        Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.SObjectType.Settings__c);

        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }
        return s;
    }
}