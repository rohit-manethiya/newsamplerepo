public class JobsManager {
    public List<Copado_Notification__c> tasks = new List<Copado_Notification__c>();
    public List<Copado_Notification__c> running = new List<Copado_Notification__c>();

    public List<String> matchingKeys = new List<String>();

    public JobsManager() {
    }

    public JobsManager(ApexPages.StandardController stdController) {
    }

    // Initialize the list of keys with a string in the format: KEY1;KEY2;...
    public String matchingKeysString {
        get {
            return String.join(matchingKeys, ';');
        }
        set {
            matchingKeys.clear();
            for(String s : value.split(';'))
                if(!String.isBlank(s))
                    matchingKeys.add(s);
            loadTasks();
        }
    }

    public void loadTasks() {
        if(matchingKeys.size()==0){
            return;
        }
        // NOTE: not sure if there might be a false positive
        if(Schema.sObjectType.Copado_Notification__c.isQueryable()){
            tasks = [SELECT Matching_Key__c, Type__c, isFinished__c, isSuccess__c, Status__c, LastModifiedDate, LastModifiedBy.Id, LastModifiedBy.Alias FROM Copado_Notification__c
            WHERE Matching_Key__c IN :matchingKeys
            ORDER BY LastModifiedDate DESC LIMIT 10];
        }
        running.clear();
        for(Copado_Notification__c n : tasks){
            if(!n.isFinished__c){
                running.add(n);
            }
        }
    }

    public boolean getHasRunningTasks() {
        return running.size()>0;
    }

    public List<Copado_Notification__c> getRunningTasks() {
        return running;
    }

    public List<Copado_Notification__c> getTasks() {
        return tasks;
    }

  	public String getFormattedDatetime(){
        return Datetime.now().format();
    }


    /**
    * Replacement for status manager, pure apex and pure js compatible
    **/

    public String namespace  { get{ return Settings.ns; } }
    // Parameters for jsCreateRunningJob
    public String matchingKey {get; set;}
    public String apiType {get; set;}
    public Id parentId {get;set;}
    public String status {get;set;}

    // possibleRunningJobs is a ";"-separated list of definitions (usually one) of jobs to watch out for.
    // MATCHINGKEY can be empty (JOBTYPE+PARENTID will be used to check for nonfinished jobs)
    public String possibleRunningJobs {get;set;}

    public List<Copado_Notification_Wrapper> runningJobsMatching {get;set;}
    public Copado_Notification_Wrapper latestRunningJobsMatching { get;set; }
    public String jsLatestRunningJobsMatching { get { return JSON.serialize(latestRunningJobsMatching); } }

    /**
    * Query the list of ALL jobs currently running that match the list of possible job types defined in "possibleRunningJobs"
    **/
    public PageReference jsRunningJobsMatching() {
        if(possibleRunningJobs==null) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.warning,'possibleRunningJobs is not set. Locking/unlocking the screen might not work'));
            return null;
        }
        runningJobsMatching = new List<Copado_Notification_Wrapper>();
        for(String jobDef : possibleRunningJobs.split(';')) {
            List<String> p = jobDef.split(',');
            if(p.size()!=4) {
                System.debug('jsRunningJobsMatching: ignoring job (parsed size!=4): '+p);
                continue;
            }
            System.debug('jsRunningJobsMatching: listening for: '+p);
            try{
                runningJobsMatching.addAll( listRunningJobsMatching(p.get(0), p.get(1), String.isEmpty(p.get(2))?null:p.get(2), p.get(3)=='true') );
            }catch(Exception e) {
                System.debug(logginglevel.ERROR, 'jsRunningJobsMatching() error adding listen job='+e+' jobDef='+jobDef);
            }
        }
        if(runningJobsMatching.size()>0) {
            latestRunningJobsMatching = runningJobsMatching.get(0);
        }else if(latestRunningJobsMatching!=null) {
            if(Schema.SObjectType.Copado_Notification__c.isQueryable() && Schema.SObjectType.Copado_Notification__c.isAccessible()) {
                for (Copado_Notification__c cn : [SELECT isFinished__c, isSuccess__c, status__c, Type__c, ParentId__c, Message__c, OwnerId, LastModifiedDate, CreatedDate, Matching_Key__c FROM Copado_Notification__c WHERE Id = :latestRunningJobsMatching.Id]) {
                    latestRunningJobsMatching = new Copado_Notification_Wrapper(cn);
                }
            }
        }
        System.debug('latestRunningJobsMatching='+latestRunningJobsMatching);
        return  null;
    }

    /**
    * Create a new notification that a new job was called.
    **/
    public PageReference jsCreateRunningJob() {
        runningJobsMatching = new List<Copado_Notification_Wrapper>();
        runningJobsMatching.add( createRunningJob(matchingKey, apiType, parentId, status) );
        latestRunningJobsMatching = runningJobsMatching.get(0);
        return  null;
    }

    // Copado_Notification__c wrapper to avoid JS namespace issues.
    public class Copado_Notification_Wrapper {
        public Copado_Notification_Wrapper(Copado_Notification__c c) {
            Id = c.Id;
            status = c.Status__c;
            this.type = c.Type__c;
            parentId = c.parentId__c;
            ownerId = c.OwnerId;
            lastModified = c.LastModifiedDate;
            isFinished = c.isFinished__c;
            isSuccess = c.isSuccess__c;
            matchingKey = c.Matching_Key__c;
            message = c.Message__c;
        }
        public String Id {get;set;}
        public String status {get;set;}
        public String type {get;set;}
        public String parentId {get;set;}
        public String message {get;set;}
        public String ownerId {get;set;}
        public String matchingKey {get;set;}
        public boolean isFinished {get;set;}
        public boolean isSuccess {get;set;}
        public Datetime lastModified {get;set;}
    }

    /**
    * Returns running jobs (if any), for the current user or everybody, newest first.
    * matchingKey or apiType + ParentId are required
    **/
    public static List<Copado_Notification_Wrapper> listRunningJobsMatching(String matchingKey, String apiType, Id ParentId, boolean onlyOwnedByMe) {
        System.debug('listRunningJobsMatching() '+matchingKey+', '+apiType+', '+ParentId+', '+onlyOwnedByMe+';');
        List<Copado_Notification__c> notifications;
        if(Schema.sObjectType.Copado_Notification__c.isQueryable()){
            if(String.isNotEmpty(matchingKey)){
                notifications = [SELECT isFinished__c, isSuccess__c, status__c, Type__c, ParentId__c, Message__c, OwnerId, LastModifiedDate, CreatedDate, Matching_Key__c  FROM Copado_Notification__c WHERE isFinished__c=false AND LastModifiedDate >= LAST_N_DAYS:1 AND Matching_Key__c=:matchingKey ORDER BY LastModifiedDate DESC LIMIT 100];
            }else{
                notifications = [SELECT isFinished__c, isSuccess__c, status__c, Type__c, ParentId__c, Message__c, OwnerId, LastModifiedDate, CreatedDate, Matching_Key__c  FROM Copado_Notification__c WHERE isFinished__c=false AND LastModifiedDate >= LAST_N_DAYS:1 AND Type__c=:apiType and ParentId__c=:ParentId ORDER BY LastModifiedDate DESC LIMIT 100];
            }
        }
        // optionally filter by owner.
        if(onlyOwnedByMe) {
            List<Copado_Notification__c> temp = new List<Copado_Notification__c>();
            for(Copado_Notification__c cn : notifications) {
                if( cn.OwnerId==UserInfo.getUserId()) {
                    temp.add(cn);
                }
            }
            notifications = temp;
        }

        List<Copado_Notification_Wrapper> returnValue = new List<Copado_Notification_Wrapper>();
        for(Copado_Notification__c cn : notifications) {
            returnValue.add( new Copado_Notification_Wrapper(cn));
        }
        System.debug('listRunningJobsMatching: returnValue='+returnValue);
        return returnValue;
    }

    /**
    * Creates a new (and unfinished) job in Copado_Notification__c
    **/
    public static Copado_Notification_Wrapper createRunningJob(String matchingKey, String apiType, Id ParentId, String status) {
        if(!Schema.sObjectType.Copado_Notification__c.fields.Name.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Matching_Key__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Type__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.ParentId__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Status__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.isFinished__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.isSuccess__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Name.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Matching_Key__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Type__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.ParentId__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Status__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.isFinished__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.isSuccess__c.isCreateable()){
            return null;
        }
        Copado_Notification__c cn = new Copado_Notification__c(Name=apiType+' '+ParentId, Matching_Key__c=matchingKey, Type__c=apiType, ParentId__c=ParentId, Status__c=status, isFinished__c=false, isSuccess__c=false);
        Utilities.Secure_DML(cn, Utilities.DML_Action.UPS, schema.Sobjecttype.Copado_Notification__c);
        System.debug('createRunningJob() cn='+cn);
        return new Copado_Notification_Wrapper(cn);
    }

    /**
    * Creates a new (and unfinished) job in Copado_Notification__c
    **/
    public static Copado_Notification_Wrapper destroyRunningJob(String matchingKey, String apiType, Id ParentId, String status) {
        if(!Schema.sObjectType.Copado_Notification__c.fields.Name.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Matching_Key__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Type__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.ParentId__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Status__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.isFinished__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.isSuccess__c.isUpdateable() && !Schema.sObjectType.Copado_Notification__c.fields.Name.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Matching_Key__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Type__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.ParentId__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.Status__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.isFinished__c.isCreateable() && !Schema.sObjectType.Copado_Notification__c.fields.isSuccess__c.isCreateable()){
            return null;
        }
        Copado_Notification__c cn = new Copado_Notification__c(Name=apiType+' '+ParentId, Matching_Key__c=matchingKey, Type__c=apiType, ParentId__c=ParentId, Status__c=status, isFinished__c=false, isSuccess__c=false);
        Utilities.Secure_DML(cn, Utilities.DML_Action.UPS, schema.Sobjecttype.Copado_Notification__c);
        System.debug('createRunningJob() cn='+cn);
        return new Copado_Notification_Wrapper(cn);
    }

}