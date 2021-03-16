public with sharing class Utilities {
    // Constants for Query builder
    public final static String EQUALS = '=';
    public final static String GREATER = '>';
    public final static String GREATER_THAN = '>';
    public final static String LESS = '<';
    public final static String LESS_THAN = '<=';
    public final static String IN_VALUES = 'IN';
    public final static String NOT_IN_VALUES = 'NOT IN';

    public static void resetStatuses(String dId, Boolean allJobs) {
        Deployment_Job__c[] jobs;
        Destination_Org__c[] dos;
        Step__c[] steps;
        if (Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            steps = [
                SELECT Id, Status__c, Deployment__c
                FROM Step__c
                WHERE Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8')
                ORDER BY Order__c, CreatedDate
                LIMIT 10000
            ];
        }
        if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
            jobs = [
                SELECT Id, Status__c, Step__r.Deployment__c, Deployed__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8')
                LIMIT 10000
            ];
        }
        if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
            dos = [
                SELECT Id, Status__c, Deployment__c
                FROM Destination_Org__c
                WHERE Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8')
                LIMIT 10000
            ];
        }
        Integer i = 0;
        for (Step__c s : steps) {
            if (Schema.SObjectType.Step__c.fields.Status__c.isUpdateable()) {
                s.Status__c = 'Not started';
                i++;
                s.Order__c = i;
            }
        }
        for (Destination_Org__c d : dos) {
            if (Schema.SObjectType.Destination_Org__c.fields.Status__c.isUpdateable()) {
                d.Status__c = 'Not started';
            }
        }
        for (Deployment_Job__c o : jobs) {
            if ((allJobs || o.Status__c != 'Success') && Schema.SObjectType.Deployment_Job__c.fields.Status__c.isUpdateable()) {
                o.Status__c = 'Pending';
                if (allJobs)
                    o.Early_Completion_Status__c = 'Pending';
                o.Deployed__c = 0;
            }
        }

        Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
        Utilities.Secure_DML(jobs, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Job__c);
        Utilities.Secure_DML(dos, Utilities.DML_Action.UPD, schema.SObjectType.Destination_Org__c);
        Utilities.Secure_DML(
            new Deployment__c(Id = dId, Deployment_command_sent__c = null),
            Utilities.DML_Action.UPD,
            schema.SObjectType.Deployment__c
        );
    }
    public HerokuResult httpGet(String url) {
        try {
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            DeployAPI.setAuthHeaders(req); //to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            String r = res.getBody();
            return new HerokuResult(true, r, null);
        } catch (System.Exception ex) {
            return new HerokuResult(false, null, ex.getMessage());
        }
    }

    // START FIELD methods
    public static String describeFields(String sObjectName) {
        String availableQueryFields = '';
        try {
            Map<String, Schema.SObjectType> schemaMap = new Map<String, Schema.SObjectType>();
            schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectName).getDescribe().fields.getMap();
            for (Schema.SObjectField sfield : fieldMap.values()) {
                schema.DescribeFieldResult dfield = sfield.getDescribe();
                if (String.isBlank(availableQueryFields)) {
                    availableQueryFields = dfield.getName();
                } else {
                    availableQueryFields += ',' + dfield.getName();
                }
            }
            return availableQueryFields;
        } catch (Exception ex) {
            return null;
        }
    }
    // END FIELD methods

    public static PageReference doOauth(Org__c org) {
        User currentUser = new User();
        if (Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
            currentUser = [SELECT API_URL__c FROM User WHERE Id = :UserInfo.getUserId()];
        }
        String urlParameters =
            '?orgId=' +
            EncodingUtil.urlEncode(org.Id, 'UTF-8') +
            '&url=' +
            EncodingUtil.urlEncode(currentUser.API_URL__c, 'UTF-8');
        if (org.Org_Type__c == 'Sandbox') {
            urlParameters += '&sandbox=true';
        }
        if (org.Org_Type__c == 'Custom Domain') {
            urlParameters += '&domain=' + EncodingUtil.urlEncode(org.Custom_Domain__c, 'UTF-8');
        }
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), 'UTF-8');
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), 'UTF-8');
        urlParameters +=
            '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), 'UTF-8');
        String herokuServer = Settings.server_url;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        PageReference pr = new PageReference(urlOauth);
        return pr;
    }

    public static List<Copado_License__c> getCopadoLicenses(String userName) {
        List<Copado_License__c> clList = new List<Copado_License__c>();
        clList = [
            SELECT
                Id,
                Name,
                SetupOwnerId,
                SetupOwner.Name,
                Enable_CCM__c,
                Enable_CAD__c,
                Enable_CST__c,
                Enable_Copado__c,
                Enable_CCH__c,
                Enable_ADD__c
            FROM Copado_License__c
            WHERE SetupOwner.Name = :userName
        ];
        return clList;
    }

    public static Attachment insertAttachment(Blob body, String name, String contentType, String parentId) {
        Attachment att = new Attachment();
        att.Body = body;
        att.Name = name;
        att.ContentType = contentType;
        att.IsPrivate = false;
        att.ParentId = parentId;
        Utilities.Secure_DML(att, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
        return att;
    }

    // QUERIES START
    public static Org__c[] getAllOrgs() {
        Org__c[] orgs;
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            orgs = [
                SELECT
                    Id,
                    Test_Frequency__c,
                    Name,
                    Username__c,
                    Token__c,
                    Org_Type__c,
                    SFDC_Org_ID__c,
                    Validated_Date__c,
                    Error__c,
                    Disable_Validation__c
                FROM Org__c
                LIMIT 10000
            ];
        }
        return orgs;
    }

    public static Git_Repository__c getGitById(String recordId) {
        SObject so = queryAllfields('Git_Repository__c', recordId);
        if (so == null) {
            return null;
        }
        Git_Repository__c o = (Git_Repository__c) so;
        return o;
    }

    public static Release__c getReleaseById(String recordId) {
        SObject so = queryAllfields('Release__c', recordId);
        if (so == null) {
            return null;
        }
        Release__c o = (Release__c) so;
        return o;
    }

    public static External_CI_Setting__c getCISettingById(String recordId) {
        SObject so = queryAllfields('External_CI_Setting__c', recordId);
        if (so == null) {
            return null;
        }
        External_CI_Setting__c o = (External_CI_Setting__c) so;
        return o;
    }

    public static External_CI_Job__c getCIJobById(String recordId) {
        SObject so = queryAllfields('External_CI_Job__c', recordId);
        if (so == null) {
            return null;
        }
        External_CI_Job__c o = (External_CI_Job__c) so;
        return o;
    }

    public static Git_Backup__c getGitBackupById(String recordId) {
        SObject so = queryAllfields('Git_Backup__c', recordId);
        if (so == null) {
            return null;
        }
        Git_Backup__c o = (Git_Backup__c) so;
        return o;
    }

    public static Deployment_Flow__c getDeploymentFlowById(String recordId) {
        SObject so = queryAllfields('Deployment_Flow__c', recordId);
        if (so == null) {
            return null;
        }
        Deployment_Flow__c o = (Deployment_Flow__c) so;
        return o;
    }

    public static Promotion__c getPromotionById(String recordId) {
        SObject so = queryAllfields('Promotion__c', recordId);
        if (so == null) {
            return null;
        }
        Promotion__c o = (Promotion__c) so;
        return o;
    }

    public static User_Story__c getUserStoryById(String recordId) {
        SObject so = queryAllfields('User_Story__c', recordId);
        if (so == null) {
            return null;
        }
        User_Story__c o = (User_Story__c) so;
        return o;
    }

    public static PermissionSet getPermissionSetById(String recordId) {
        SObject so = queryAllfields('PermissionSet', recordId);
        if (so == null) {
            return null;
        }
        PermissionSet o = (PermissionSet) so;
        return o;
    }

    public static Org__c getOrgById(String recordId) {
        List<Org__c> orgs = new List<Org__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            orgs = [
                SELECT
                    Id,
                    Name,
                    Test_Frequency__c,
                    Username__c,
                    Metadata_Types__c,
                    Token__c,
                    Org_Type__c,
                    SFDC_Org_ID__c,
                    Validated_Date__c,
                    Error__c,
                    Disable_Validation__c,
                    Oauth_Signature__c,
                    Validated_Status__c,
                    Last_Apex_Tests_Datetime__c,
                    Last_Apex_Tests_Status__c,
                    Last_Git_Backup_Datetime__c,
                    Last_Git_Backup_Status__c,
                    Custom_Domain__c,
                    Environment__c,
                    Default_Credential__c,
                    is_Developer_Hub_Org__c,
                    Developer_Hub_Org__c,
                    Developer_Hub_Org__r.is_Developer_Hub_Org__c,
                    Default_Scratch_Org_Definition__c
                FROM Org__c
                WHERE Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')
                LIMIT 1
            ];
        }
        if (orgs.size() > 0) {
            return orgs[0];
        } else {
            return new Org__c();
        }
    }
    public static Deployment__c getDeploymentById(String recordId) {
        Deployment__c deployment = new Deployment__c();
        if (Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
            deployment = [
                SELECT
                    Id,
                    OwnerId,
                    IsDeleted,
                    Name,
                    RecordTypeId,
                    Build_Task__c,
                    Completed__c,
                    Date__c,
                    Deployed__c,
                    Deployment_Completed_email_sent__c,
                    Deployment_command_sent__c,
                    Flag_Status__c,
                    From_Org__c,
                    Promotion__c,
                    Schedule__c,
                    Send_Deployment_Complete_email__c,
                    Server_URL__c,
                    Status__c,
                    Count_Completed__c,
                    Deployment_Jobs_Count__c,
                    SUM_Deployed__c,
                    Compliance_Status__c,
                    Last_Compliance_Scan_Date__c,
                    Deployment_Type__c,
                    Deployment_Last_Step__c,
                    Deployment_Source_Type__c,
                    Source_Environment__c,
                    Paused__c,
                    Description__c,
                    Template__c,
                    Execution_Context__c,
                    Active__c,
                    LastActivityDate,
                    LastModifiedById,
                    LastModifiedDate,
                    SystemModstamp,
                    CreatedById,
                    CreatedDate
                FROM Deployment__c
                WHERE Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')
            ];
        }
        return deployment;
    }
    public static Step__c[] getStepsByDeploymentId(String recordId) {
        //added Branch_Base_URL__c to query to create a direct link to related branch on step detail - UCU 24.05.18
        Step__c[] steps;
        if (Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            steps = [
                SELECT
                    Id,
                    IsDeleted,
                    Name,
                    CreatedDate,
                    CreatedById,
                    LastModifiedDate,
                    LastModifiedById,
                    SystemModstamp,
                    LastActivityDate,
                    Deployment__c,
                    Attachment_Id__c,
                    Branch__c,
                    CheckOnly__c,
                    Commit_Id__c,
                    Commit_Name__c,
                    Completed__c,
                    Deployed__c,
                    Git_Repository__c,
                    Order__c,
                    Run_all_tests__c,
                    Status_Flag__c,
                    Status__c,
                    Type__c,
                    View_Attachment__c,
                    dataJson__c,
                    Count_Completed__c,
                    Org_Count__c,
                    SUM_Deployed__c,
                    Manual_Task_Notified__c,
                    Notify_Task_Owner__c,
                    Read_Only__c,
                    Automated_Behaviour__c,
                    Git_Repository__r.Name,
                    Git_Repository__r.Branch_Base_URL__c,
                    Deployment__r.From_Org__c
                FROM Step__c
                WHERE Deployment__c = :recordId
                ORDER BY Order__c ASC
                LIMIT 10000
            ];
        }
        return steps;
    }
    public static Step__c getStepById(String recordId) {
        Step__c step = new Step__c();
        if (Schema.SObjectType.Step__c.isQueryable() && Schema.SObjectType.Step__c.isAccessible()) {
            step = [
                SELECT Id, Name, Order__c, Deployment__c, Type__c, dataJson__c, Status__c, CheckOnly__c, Status_Flag__c, Deployment__r.From_Org__c
                FROM Step__c
                WHERE Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')
                LIMIT 1
            ];
        }
        return step;
    }

    public static Map<Id, String> getEnvsAndBranchesOfDeploymentFlow(Id dfId) {
        Map<Id, String> envsAndBranches = new Map<Id, String>(); // Env.Id, Branch_name
        Deployment_Flow__c df = new Deployment_Flow__c();
        List<Deployment_Flow_Step__c> steps = new List<Deployment_Flow_Step__c>();
        if (Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            df = [SELECT Id, Name, Git_Repository__c, Main_Branch__c FROM Deployment_Flow__c WHERE Id = :dfId];
        }

        if (Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            steps = [
                SELECT Source_Environment__c, Branch__c, Destination_Environment__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :df.Id
            ];
        }
        if (steps.size() > 0) {
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Source_Environment__c != null) {
                    envsAndBranches.put(step.Source_Environment__c, step.Branch__c);
                }
            }
            // any dest environment not previously set as a source somewhere, is the main env, and matches the main branch.
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Destination_Environment__c != null && !envsAndBranches.containsKey(step.Destination_Environment__c)) {
                    envsAndBranches.put(step.Destination_Environment__c, df.Main_Branch__c);
                }
            }
        }
        return envsAndBranches;
    }

    public static List<Deployment_Flow_Step__c> getStepDetailsOfDeploymentFlow(Id dfId) {
        List<Deployment_Flow_Step__c> steps = (List<Deployment_Flow_Step__c>) ExternalCIAPIFactory.queryAllValues(
            'Deployment_Flow_Step__c',
            'Deployment_Flow__c',
            dfId,
            '',
            ''
        );
        return steps;
    }

    public static Destination_Org__c[] getDestinationOrgsByDeploymentId(String recordId) {
        Destination_Org__c[] dos;
        if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
            dos = [
                SELECT
                    Id,
                    IsDeleted,
                    Name,
                    CreatedDate,
                    CreatedById,
                    LastModifiedDate,
                    LastModifiedById,
                    LastActivityDate,
                    Deployment__c,
                    Completed__c,
                    Deployed__c,
                    Status_Flag__c,
                    Status__c,
                    To_Org_Name__c,
                    To_Org__c,
                    Count_Completed__c,
                    SUM_Deployed__c,
                    Step_Count__c,
                    To_Org__r.Environment__c,
                    To_Org__r.Validated_Date__c,
                    To_Org__r.Validated_Status__c,
                    To_Org__r.Last_Apex_Tests_Datetime__c,
                    To_Org__r.Last_Apex_Tests_Status__c,
                    To_Org__r.Last_Git_Backup_Datetime__c,
                    To_Org__r.Last_Git_Backup_Status__c
                FROM Destination_Org__c
                WHERE Deployment__c = :EncodingUtil.urlEncode(recordId, 'UTF-8')
                ORDER BY Name ASC
                LIMIT 10000
            ];
        }
        return dos;
    }
    public static Destination_Org__c getDestinationOrgsById(String recordId) {
        Destination_Org__c dorg = new Destination_Org__c();
        if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
            dorg = [
                SELECT
                    Id,
                    Name,
                    Status__c,
                    Deployment__c,
                    To_Org__c,
                    To_Org__r.Name,
                    To_Org__r.Last_Apex_Tests_Status__c,
                    To_Org__r.Last_Apex_Tests_Datetime__c,
                    To_Org__r.Last_Git_Backup_Status__c,
                    To_Org__r.Last_Git_Backup_Datetime__c
                FROM Destination_Org__c
                WHERE Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')
                LIMIT 1
            ];
        }
        return dorg;
    }
    //public static List<Add_on__c> getAllAddons(){
    //    Add_on__c[] addons = [select Id, Name, Description__c, Package_Name__c, Visualforce_page__c from Add_on__c order by Name DESC];
    //    return addons;
    //}
    // QUERIES END

    public class HerokuResult {
        public Boolean success { get; set; }
        public String response { get; set; }
        public String ErrorMessage { get; set; }

        public HerokuResult(Boolean b, String r, String em) {
            this.success = b;
            this.response = r;
            this.ErrorMessage = em;
        }
    }
    public class IsufficientAccessException extends Exception {
    }
    public enum DML_Action {
        INS,
        UPD,
        DEL,
        UPS
    }

    private static void HandleDatabaseOperations(Database.SaveResult[] dbsr) {
        for (Database.SaveResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.Error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DmlException(messages);
                }
            }
        }
    }
    private static void HandleDatabaseOperations(Database.UpsertResult[] dbsr) {
        for (Database.UpsertResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.Error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DmlException(messages);
                }
            }
        }
    }
    private static void HandleDatabaseOperations(Database.DeleteResult[] dbsr) {
        for (Database.DeleteResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.Error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DmlException(messages);
                }
            }
        }
    }

    public static List<SObject> Secure_DML(
        List<SObject> sobjects,
        DML_Action action,
        Schema.DescribeSObjectResult stype,
        Schema.DescribeFieldResult externalIDField
    ) {
        //US-0001074: FL: to prevent Error messages on customer VF pages.
        if (sobjects == null || sobjects.size() == 0) {
            //Ignoring permissions
            return sobjects;
        }
        Boolean isUpdateable = stype.isUpdateable();
        Boolean isCreateable = stype.isCreateable();
        Boolean isDeletable = stype.isDeletable();
        Boolean isAccessible = stype.isAccessible();
        Boolean isCustomSetting = stype.isCustomSetting();
        Boolean forceDML = isCustomSetting || Trigger.isExecuting;
        System.debug('upd => ' + isUpdateable + ' cre => ' + isCreateable + ' acc => ' + isAccessible + ' forceDML => ' + forceDML);
        //US-0001123: FL: allow triggers to do DML since they run in system mode.
        if (action == DML_Action.INS) {
            if (isAccessible && isCreateable || forceDML) {
                Database.SaveResult[] srList = Database.insert(sobjects, true);
                //THERE MAY BE FALSE POSITIVE CRUD INSERT SINCE WE CHECK ISINSERTABLE
                //FOR THE GIVEN OBJECT IF THE OBJECT IS NOT A CUSTOM SETTING AND IF THE TRANSACTION IS NOT IN TRIGGER EXECUTION
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DmlException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        } else if (action == DML_Action.UPD) {
            if (isAccessible && isUpdateable || forceDML) {
                Database.SaveResult[] srList = Database.update(sobjects, true);
                //THERE MAY BE FALSE POSITIVE CRUD UPDATE SINCE WE CHECK ISUPDATEABLE
                //FOR THE GIVEN OBJECT IF THE OBJECT IS NOT A CUSTOM SETTING AND IF THE TRANSACTION IS NOT IN TRIGGER EXECUTION
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DmlException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        } else if (action == DML_Action.DEL) {
            if (isAccessible && isDeletable || forceDML) {
                Database.DeleteResult[] srList = Database.delete(sobjects, true);
                //THERE MAY BE FALSE POSITIVE CRUD DELETE SINCE WE CHECK ISDELETEABLE
                //FOR THE GIVEN OBJECT IF THE OBJECT IS NOT A CUSTOM SETTING AND IF THE TRANSACTION IS NOT IN TRIGGER EXECUTION
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DmlException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        } else if (action == DML_Action.UPS) {
            if (isAccessible && isCreateable && isUpdateable || forceDML) {
                if (externalIDField != null) {
                    //THERE MAY BE FALSE POSITIVE CRUD UPSERT SINCE WE CHECK ISINSERTABLE AND UPDATEABLE
                    //FOR THE GIVEN OBJECT IF THE OBJECT IS NOT A CUSTOM SETTING AND IF THE TRANSACTION IS NOT IN TRIGGER EXECUTION
                    Database.UpsertResult[] upr = Database.upsert(sobjects, externalIDField.getSobjectField());
                    HandleDatabaseOperations(upr);
                } else {
                    List<SObject> upds = new List<SObject>();
                    List<SObject> ins = new List<SObject>();
                    for (SObject s : sobjects) {
                        if (s.Id == null) {
                            ins.add(s);
                        } else {
                            upds.add(s);
                        }
                    }
                    if (upds.size() > 0) {
                        Database.SaveResult[] srList = Database.update(upds);
                        HandleDatabaseOperations(srList);
                    }
                    if (ins.size() > 0) {
                        Database.SaveResult[] srList = Database.insert(ins);
                        HandleDatabaseOperations(srList);
                    }
                }
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DmlException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        }
        return sobjects;
    }

    public static List<SObject> Secure_DML(List<SObject> sobjects, DML_Action action, Schema.DescribeSObjectResult stype) {
        List<SObject> SObjectList = Secure_DML(sobjects, action, stype, null);
        return SObjectList;
    }
    public static SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype, Schema.DescribeFieldResult externalIDField) {
        List<SObject> records = Secure_DML(new List<SObject>{ sob }, action, stype, externalIDField);
        if (records != null && !records.isEmpty()) {
            return records[0];
        }
        return null;
    }

    public static SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype) {
        List<SObject> records = Secure_DML(new List<SObject>{ sob }, action, stype);
        if (records != null && !records.isEmpty()) {
            return records[0];
        }
        return null;
    }
    //checks if the user has edit access on current record and query it only when needed - UCU
    public static Boolean HasEditAccess(Id currentId) {
        UserRecordAccess cUserAccess = new UserRecordAccess();
        if (Schema.SObjectType.Destination_Org__c.isQueryable() && Schema.SObjectType.Destination_Org__c.isAccessible()) {
            cUserAccess = [
                SELECT RecordId, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId = :currentId
                LIMIT 1
            ];
        }
        return (null != cUserAccess ? cUserAccess.HasEditAccess : false);
    }
    public static Integer randomInteger(Integer min, Integer max) {
        Integer i = Math.mod(Integer.valueOf(Math.random() * 10 * (max + ''.length())), max);
        while (i < min) {
            i += min;
            if (i > max)
                i -= max;
        }
        return i;
    }
    public static void sendEmail(String toAddress, String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new List<String>{ toAddress };
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName(UserInfo.getName());
        mail.setSubject(subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    public static Map<String, String> getAllFields(String sObjectName) {
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME)
            sObjectName = Settings.ns + sObjectName;
        Map<String, String> result = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        Set<String> accessiblefields = new Set<String>();

        for (Schema.SObjectField field : fields.values()) {
            if (!field.getDescribe().isAccessible() && !Test.isRunningTest())
                continue;
            accessiblefields.add(field.getDescribe().getName());
        }

        //Now we do the same for fields in the FieldSets
        Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fieldSets.getMap();

        for (Schema.FieldSet fs : fsMap.values()) {
            for (Schema.FieldSetMember fsm : fs.getFields()) {
                accessiblefields.add(fsm.getFieldPath());
            }
        }

        String allfields = '';

        for (String fieldname : accessiblefields) {
            allfields += fieldname + ',';
        }

        allfields = allfields.substring(0, allfields.length() - 1);

        System.Debug('getAllFieldsResult = ' + allfields);

        result.put(Label.OBJECT, sObjectName);
        result.put(Label.FIELDS, allfields);
        return result;
    }
    public static SObject queryAllfields(String sObjectName, String recordId) {
        recordId = EncodingUtil.urlEncode(recordId, 'UTF-8');
        Map<String, String> d = getAllFields(sObjectName);

        String queryString = 'SELECT ' + d.get(Label.FIELDS) + ' FROM ' + d.get(Label.OBJECT) + ' WHERE ID =:recordId';
        System.debug('QUERY: ' + queryString);
        List<SObject> sos = Database.query(queryString);
        if (sos.size() > 0)
            return sos.get(0);
        return null;
    }
    /*
     ** This method is to be used whenever we need an API Capable Session Id, normally used when doing something from LEX
     **
     */
    public static String getClassicSessionId() {
        String content = '';

        content = Test.isRunningTest() ? '{"sId":"TestMethodKey123"}' : Page.ClassicSessionId.getContent().toString();

        /*if (Test.IsRunningTest()) {
            content = '{"sId":"TestMethodKey123"}';
        } else {
            content = Page.ClassicSessionId.getContent().toString();
        }*/
        Map<String, Object> jMap = (Map<String, Object>) JSON.deserializeUntyped(content);
        return (String) jMap.get('sId');
    }

    public static List<String> getPicklistValues(String sObjectName, String Field_name) {
        sObjectName = Settings.ns + sObjectName;
        List<String> lstPickvals = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName);
        SObject Object_name = targetType.newSObject();
        Schema.SObjectType sobject_type = Object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry a : pick_list_values) {
            lstPickvals.add(a.getValue());
        }

        return lstPickvals;
    }

    /**
     * @param Id UserId: this user will be @ mentioned in the chatter post.
     * @param String chatterMessage: chatter post text.
     * @param Id recordId: chatter will post the notification in this record.
     */
    public static void notifyUsingChatterWithAtMention(Id userId, String chatterMessage, Id recordId) {
        /* ConnectApi class is not accessible from Tests Classes */
        if (!Test.isRunningTest()) {
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            mentionSegmentInput.id = userId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            textSegmentInput.text = chatterMessage;
            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = recordId;

            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
    }

    /**
     * @param String SObjectType: API name of the Object to be checked.
     * @returns Boolean: true if it's enabled for both Org and Object, false otherwise. No exception it's thrown to prevent stopping a process.
     */
    public static Boolean isChatterEnabled(String SObjectType) {
        List<String> types = new List<String>();
        types.add(SObjectType);
        List<Schema.DescribeSObjectResult> results = Schema.describeSObjects(types);
        if ((results != null && !results.isEmpty() && !results[0].feedEnabled) || !Schema.SObjectType.User.isFeedEnabled()) {
            System.debug(System.Label.CHATTER_NOT_ENABLED);
            return false;
        } else {
            return true;
        }
    }

    public static List<SelectOption> selectOptionSortByLabel(List<SelectOption> selectOptionsToSort) {
        if (selectOptionsToSort == null || selectOptionsToSort.size() <= 1) {
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        Integer pivot = selectOptionsToSort.size() / 2;

        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for (SelectOption SO : selectOptionsToSort) {
            if (SO.getLabel() <= pivotValue.getLabel()) {
                lessSelectOption.add(SO);
            } else if (SO.getLabel() > pivotValue.getLabel()) {
                greaterSelectOption.add(SO);
            }
        }
        List<SelectOption> sortedSelectOptions = new List<SelectOption>();
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return sortedSelectOptions;
    }

    /**
     * getFields Returns all fields from a specific SObject
     * @param  sObjectName       The object API name. Ex: Account, MyCustomObject__c
     * @param  includeReferences Tells if the method should also return lookup or master-detail fields
     * @param  updateatableOnly  Tells if the method should return only updateatable fields
     * @return                   return A map containing the field name as key and field labels as value
     */
    public static Map<String, String> getFields(String sObjectName, Boolean includeReferences, Boolean updateatableOnly) {
        Map<String, String> result = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();

            if (describe.isAccessible()) {
                if ((updateatableOnly && describe.isUpdateable()) || !updateatableOnly) {
                    if ((describe.getType() == DisplayType.REFERENCE && includeReferences)) {
                        result.put(describe.getName(), describe.getLabel());
                    } else {
                        result.put(describe.getName(), describe.getLabel());
                    }
                }
            }
        }
        return result;
    }

    /**
     * getQuery Returns something like Select * FROM
     * @param  sObjectName       The SObject name
     * @param  includeReferences Tells if the method should also return lookup or master-detail fields
     * @param  updateatableOnly  Tells if the method should return only updateatable fields
     * @return                   return The query
     */
    /*public static String getQuery( String sObjectName, Boolean includeReferences, Boolean updateatableOnly ) {
        String query = 'SELECT ';
        Map<String,String> sObjectFields = Utilities.getFields( sObjectName, includeReferences, updateatableOnly );
        for( String fieldName : sObjectFields.keySet() ) {
            query += fieldName + ', ';
        }

        query = query.left( query.length() - 2 );
        query += ' FROM ' + sObjectName;
        return query;
    }*/

    /**
     * getQuery 					Returns something like Select * FROM
     * @param  sObjectType       	The SObject name
     * @param  includeReferences 	Tells if the method should also return lookup or master-detail fields
     * @param  updateatableOnly  	Tells if the method should return only updateatable fields
     * @param  fieldsToExcludeList  Tells which fields must be excluded from select statement.
     * @return                   	return The query
     */
    /*public static String getQuery( String sObjectType, Boolean includeReferences, Boolean updateatableOnly, List<String> fieldsToExcludeList ) {
        String query = 'SELECT ';
        String result = '';
        Map<String,String> sObjectFields = Utilities.getFields( sObjectType, includeReferences, updateatableOnly );
        for( String fieldName : sObjectFields.keySet() ) {
            result += fieldName + ', ';
        }

        for( String fieldToExclude : fieldsToExcludeList ) {
            result = result.startsWith( fieldToExclude ) ? result.replace( fieldToExclude + ',', '' ) : result.replace(', ' + fieldToExclude + ',', ', ');
        }

        if( result.endsWith(', ') ) {
            result = result.left(result.length()-2);
        }

        query = query + result;
        return query;
    }*/

    /**
     * getQuery 					Returns something like Select * FROM where ...
     * @param  sObjectType        	The SObject name
     * @param  updateatableOnly   	Tells if the method should also return lookup or master-detail fields
     * @param  includeReferences  	Tells if the method should return only updateatable fields
     * @param  fieldsToExcludeList  Tells which fields must be excluded from select statement.
     * @param  filters            	A list of SOQLFilters.Filter. Ex: new List<SOQLFilters> { SOQLFilters billingStateFilter = new SOQLFilters('Account', 'BillingState', Utilities.EQUALS, new List<String> {'PE'} );) }
     * @param  filterLogic        	Just any logic condition in Saleforce. Ex: (1 OR 3) AND 2
     * @return                    	return The query
     */
    /*public static String getQuery( String sObjectType, Boolean updateatableOnly, Boolean includeReferences, List<String> fieldsToExcludeList, List<SOQLFilters> filters, String filterLogic ) {
        String result = '';
        String selectClause = getQuery( sObjectType, includeReferences, updateatableOnly, fieldsToExcludeList );
        String whereClause = '';

        Integer index = 1;
        for( SOQLFilters filter : filters ) {
            String filterStr =  filter.getFilter();
            filterLogic = filterLogic.replace(String.valueOf(index), filterStr);
            index++;
        }

        result = selectClause + ' FROM ' + sObjectType + ( filters.size() > 0 ? ' WHERE ' + filterLogic  : '' );
        return result;
    }*/
}