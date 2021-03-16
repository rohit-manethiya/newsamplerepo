global with sharing class WorkPushService implements CLIInterface {
    private final String RETRIEVE_C = 'retrieve';
    private final String COMMITFILES = 'commitFiles';
    private final String GIT_METADATA = 'Git MetaData';
    private final String ALLOW_SNAPSHOTS_ONLY = 'Allow Snapshots Only';
    private final String ADDED = 'added';
    private final String UPDATED = 'updated';
    private final String COMPLETE = 'Complete';
    private final String METADATA = 'MetaData';
    private final String EXTERNAL_METADATA = 'ExternalMetaData';
    private final String DYNAMIC_SOQL = 'SELECT {0} FROM User_Story__c WHERE Id = \'\'{1}\'\' LIMIT 1';

    private List<Attachment> attList = new List<Attachment>();
    // Key = path to file , value= file retrievable.
    private Map<String, SfRetrievable> attRetrievableMap = new Map<String, SfRetrievable>();
    // Key = key to identify new ones, value = file retrievable
    private Map<String, SfRetrievable> retrievableMap = new Map<String, SfRetrievable>();
    // Key = user story commit, value = object retrievable
    private Map<String, List<SfRetrievable>> attContentMap = new Map<String, List<SfRetrievable>>();
    private String lastModifiedBy;

    /**
     * Empty constructor is necessary to initalise the interface impl.
     */
    public WorkPushService() {
    }

    /**
     * Get instance of WorkPushService that implements CLI Interface
     * @return instance of WorkPushService()
     */
    public CLIInterface getInstance() {
        return new WorkPushService();
    }

    /**
     * Runs requested operation under root service
     * @see CliSfDataWrapper
     * @see CliSfDataWrapper.ReturnWrapper returned information details
     * @return JSON of CliSfDataWrapper.ReturnWrapper for CLI communication
     */
    public String run(CliProxy.CLIWrapper record) {
        String securityException = securityCheck();
        if (String.isNotBlank(securityException)) {
            return securityException;
        }

        String statusResult;
        String messageResult;
        String projectTypeField;

        ServiceHelper workPushHelper;
        WorkPushWrapper commitWrapperList;
        DxFormatConvertResponse retrievableList;

        Set<String> filenameSet = new Set<String>();
        List<Git_Org_Commit__c> snapshotCommitList = new List<Git_Org_Commit__c>();
        List<User_Story_Commit__c> userStoryCommitList = new List<User_Story_Commit__c>();

        try {
            commitWrapperList = (WorkPushWrapper) JSON.deserialize(record.body, WorkPushWrapper.class);
            System.debug('*** Commitlist: ' + commitWrapperList);
        } catch (Exception ex) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), ex.getMessage()));
        }
        if (commitWrapperList.commitList.isEmpty()) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), messageResult));
        }

        filenameSet = buildFilenameSet(commitWrapperList.commitList);

        List<User_Story__c> currentUserStory = userStoryQuery(commitWrapperList);
        if (currentUserStory.isEmpty()) {
            return jsonReturnResult(CliSfDataWrapper.StatusResult.ERROR.name(), Label.USER_STORY_NOT_SET);
        }

        projectTypeField = getProjectType(commitWrapperList.projectTypeField, currentUserStory[0]);

        List<Git_Backup__c> gitSnapshotList = [
            SELECT Id, Git_Repository__c, Git_Repository__r.Source_Format__c
            FROM Git_Backup__c
            WHERE
                Org__c = :currentUserStory[0].Org_Credential__c
                AND Git_Repository__c = :currentUserStory[0].Project__r.Deployment_Flow__r.Git_Repository__c
                AND Git_Snapshot_Permissions__c != :ALLOW_SNAPSHOTS_ONLY
            LIMIT 1
        ];
        if (gitSnapshotList.isEmpty()) {
            return jsonReturnResult(CliSfDataWrapper.StatusResult.ERROR.name(), Label.NO_VALID_SNAPSHOT);
        }

        // TODO: In order to make external service logic extendable we need to implement service abstraction to initialise proper service via proper type.
        // Service initialisation decides internal or external service usage.
        // Initiliaze as "Metadata" in case customer haven't change format. In that case, is empty so we assume is Metadata. If it would be DX it had to be changed.
        String sourceFormat = METADATA;
        if (String.isBlank(projectTypeField)) {
            workPushHelper = (ServiceHelper) (InternalServiceHelper.class.newInstance());
            sourceFormat = String.isNotBlank(gitSnapshotList[0].Git_Repository__r.Source_Format__c)
                ? gitSnapshotList[0].Git_Repository__r.Source_Format__c
                : sourceFormat;
        } else {
            workPushHelper = (ServiceHelper) (ExternalServiceHelper.class.newInstance());
            sourceFormat = projectTypeField;
        }
        // file to ret might fail on the backend side for internal service usage below try/catch checks that scenario
        try {
            retrievableList = workPushHelper.fileToRet(new FileToRetWrapper(filenameSet, commitWrapperList.projectJson), sourceFormat);
            attRetrievableMap = getRetrievablesMap(retrievableList.response);
        } catch (Exception excp) {
            statusResult = CliSfDataWrapper.StatusResult.ERROR.name();
            messageResult = excp.getMessage();
            return (jsonReturnResult(statusResult, messageResult));
        }

        Savepoint sp;
        try {
            sp = Database.setSavepoint();
            List<Attachment> gitMetadataAttachment = [
                SELECT Id, Body
                FROM Attachment
                WHERE Name = :GIT_METADATA AND ParentId = :currentUserStory[0].Id
                LIMIT 1
            ];
            lastModifiedBy = currentUserStory[0].Developer__c != null ? currentUserStory[0].Developer__r.Name : currentUserStory[0].Owner.Name;

            // First git snapshot is always selected.
            // Insert Git Snapshot Commit for the local git commits
            snapshotCommitList = processSnapshotCommit(commitWrapperList.commitList, gitSnapshotList[0].Id, currentUserStory[0].Org_Credential__c);
            Utilities.Secure_DML(
                snapshotCommitList,
                Utilities.DML_Action.UPS,
                Schema.SObjectType.Git_Org_Commit__c,
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Id__c
            );

            // Insert User Story Commits that are retrieved from the local git.
            userStoryCommitList = processUserStoryCommit(
                snapshotCommitList,
                currentUserStory[0].Id,
                gitSnapshotList[0].Git_Repository__c,
                String.isBlank(projectTypeField) ? METADATA : EXTERNAL_METADATA
            );
            Utilities.Secure_DML(
                userStoryCommitList,
                Utilities.DML_Action.UPS,
                Schema.SObjectType.User_Story_Commit__c,
                Schema.SObjectType.User_Story_Commit__c.fields.External_Id__c
            );

            // Associate commit details to user story commit to display context (metadata) on the commit UI.
            attList.add(attUserStoryRetrievable(gitMetadataAttachment, retrievableMap, currentUserStory[0].Id));
            Utilities.Secure_DML(attList, Utilities.DML_Action.UPS, Schema.SObjectType.Attachment);
            // Prepare status CLI for success
            statusResult = CliSfDataWrapper.StatusResult.OK.name();
        } catch (Exception ex) {
            // Prepare status for failure
            statusResult = CliSfDataWrapper.StatusResult.ERROR.name();
            messageResult = ex.getMessage();
            Database.rollback(sp);
        }
        // Communicate the result to CLI
        return (JSON.serialize(new WorkPushDataWrapper(statusResult, messageResult, retrievableList.errors)));
    }

    /**
     * User Story Commit records and User Story Commit and Repository Commit Attachments
     * @param snapshotCommitList
     * @param currentUserStoryId
     * @param gitRepo
     * @param sourceFormat
     *
     * @return User Story Commit List
     */
    private List<User_Story_Commit__c> processUserStoryCommit(
        List<Git_Org_Commit__c> snapshotCommitList,
        String currentUserStoryId,
        String gitRepo,
        String sourceFormat
    ) {
        List<User_Story_Commit__c> userStoryCommitList = new List<User_Story_Commit__c>();
        for (Git_Org_Commit__c snapComm : snapshotCommitList) {
            User_Story_Commit__c uscomm = new User_Story_Commit__c();
            uscomm.External_Id__c = currentUserStoryId + '_' + snapComm.Commit_Id__c;
            uscomm.Snapshot_Commit__c = snapComm.Id;
            uscomm.User_Story__c = currentUserStoryId;
            userStoryCommitList.add(uscomm);

            Attachment attCommit = new Attachment();
            attCommit.Name = sourceFormat;
            attCommit.ParentId = snapComm.Id;
            // In this case, if attContentMap.get(snapComm.Commit_Id__c) is null, attachment has to be created anyway, even if it is created empty
            attCommit.Body = Blob.valueOf(JSON.serialize(attContentMap.get(snapComm.Commit_Id__c), true));

            attList.add(attCommit);

            Attachment attRepository = new Attachment();
            attRepository.Name = snapComm.Commit_Id__c + '.json';
            attRepository.ParentId = gitRepo;
            attRepository.Body = attCommit.Body;

            attList.add(attRepository);
        }
        return userStoryCommitList;
    }

    /**
     * Org Commit creation and setting up retrievables.
     * @param commitList
     * @param gitSnapshotId
     * @param orgCredentialId
     * @return Snapshot Commit List (Git Org commit)
     */
    private List<Git_Org_Commit__c> processSnapshotCommit(List<CommitWrapper> commitList, String gitSnapshotId, String orgCredentialId) {
        List<Git_Org_Commit__c> snapshotCommitList = new List<Git_Org_Commit__c>();
        for (CommitWrapper comm : commitList) {
            // Setting up retrievables
            setUpRetrievables(comm);

            // Setting up Git Snapshot commit
            Git_Org_Commit__c snapshotcmm = new Git_Org_Commit__c();
            snapshotcmm.Commit_Id__c = comm.commitId;
            snapshotcmm.Commit_Message__c = comm.commitMessage;
            snapshotcmm.Git_Backup__c = gitSnapshotId;
            snapshotcmm.Status__c = COMPLETE;
            snapshotcmm.Org__c = orgCredentialId;
            snapshotcmm.Commit_Date__c = Datetime.valueOfGmt(comm.commitDate);
            snapshotCommitList.add(snapshotcmm);
        }
        return snapshotCommitList;
    }
    /**
     * Filling attContentMap to have retrievables per user story commit.
     * Key = user story commit, value = object retrievable
     * @see processSnapshotCommit
     * @param comm
     */
    private void setUpRetrievables(CommitWrapper comm) {
        List<SfRetrievable> tmpSfRetrievables = new List<SfRetrievable>();
        for (String file : comm.commitFiles) {
            if (attRetrievableMap.containsKey(file) && attRetrievableMap.get(file) != null) {
                // attRetrievableMap.get(file) != null is used to avoid this case: filePath=classes/myClassDev.cls, metaData=null
                String commitDateStr = String.valueOfGmt(Datetime.valueOfGmt(comm.commitDate));
                SfRetrievable sfr = attRetrievableMap.get(file);
                sfr.s = false;
                sfr.d = commitDateStr;
                sfr.b = lastModifiedBy;
                sfr.cd = commitDateStr;
                sfr.cb = comm.commitAuthor;
                sfr.r = false;
                tmpSfRetrievables.add(sfr);

                sfr.snapshotCommitId = comm.commitId;
                sfr.cmm = ADDED;
                retrievableMap.put(sfr.n + sfr.t, sfr);
            }
        }
        attContentMap.put(comm.commitId, tmpSfRetrievables);
    }

    /**
     * Security check for the entire method
     * @return null or an error to show in CLI
     */
    private String securityCheck() {
        // OLS check
        List<String> checkOlsList = CliSecurityService.checkOLS(
            new List<String>{ Schema.SObjectType.User_Story__c.getName(), Schema.SObjectType.Git_Backup__c.getName() }
        );
        if (!checkOlsList.isEmpty()) {
            return jsonReturnResult(CliSfDataWrapper.StatusResult.ERROR.name(), 'Insufficient privileges to ' + checkOlsList);
        }
        // FLS check
        List<String> checkFlsList = new List<String>();
        List<String> checkFlsSnapShotCommit = CliSecurityService.checkFLS(
            Schema.SObjectType.Git_Org_Commit__c.getName(),
            new List<String>{
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Id__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Message__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Git_Backup__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Org__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Status__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Date__c.getName()
            },
            Utilities.DML_Action.INS
        );
        if (!checkFlsSnapShotCommit.isEmpty()) {
            checkFlsList.addAll(checkFlsSnapShotCommit);
        }

        List<String> checkFlsUserStoryCommit = CliSecurityService.checkFLS(
            Schema.SObjectType.User_Story_Commit__c.getName(),
            new List<String>{
                Schema.SObjectType.User_Story_Commit__c.fields.External_Id__c.getName(),
                Schema.SObjectType.User_Story_Commit__c.fields.Snapshot_Commit__c.getName(),
                Schema.SObjectType.User_Story_Commit__c.fields.User_Story__c.getName()
            },
            Utilities.DML_Action.INS
        );
        if (!checkFlsUserStoryCommit.isEmpty()) {
            checkFlsList.addAll(checkFlsUserStoryCommit);
        }

        if (!checkFlsList.isEmpty()) {
            return jsonReturnResult(CliSfDataWrapper.StatusResult.ERROR.name(), Label.Insufficient_Access + checkFlsList);
        }
        return null;
    }
    /**
     * Extract file names to a Set String.
     * @param commitList
     * @return Set<String> with commit file names
     */
    private Set<String> buildFilenameSet(List<CommitWrapper> commitList) {
        Set<String> filenameSet = new Set<String>();
        for (CommitWrapper comm : commitList) {
            filenameSet.addAll(comm.commitFiles);
        }
        return filenameSet;
    }

    /**
     * Queries User Stories to return current US
     * @param commitWrapper
     * @return current user story
     */
    private List<User_Story__c> userStoryQuery(WorkPushWrapper commitWrapper) {
        String selectFieldsString = 'Id, Name, Project__r.Deployment_Flow__r.Git_Repository__c, Developer__r.Name, Owner.Name, Org_Credential__c';
        selectFieldsString += String.isBlank(commitWrapper.projectTypeField) ? '' : ', Project__r.' + commitWrapper.projectTypeField;

        // Dynamic query: 'SELECT {0} FROM User_Story__c WHERE Id = :{1} LIMIT 1'
        String dynamicQuery = String.format(DYNAMIC_SOQL, new List<String>{ selectFieldsString, String.escapeSingleQuotes(commitWrapper.userStory) });

        return Database.query(dynamicQuery);
    }

    /**
     * Gets value of Project field if exists. Null/Blank means this project is Salesforce project.
     * @param prType
     * @param currUs
     * @return value of Project field. Null means this project is Salesforce project
     */
    private String getProjectType(String prType, User_Story__c currUs) {
        // If "prType" has value, it has to be turned to lowercase, because "Project__c.fields.getMap().keySet()" is API Name in lowercase.
        String projectTypeString = String.isBlank(prType) ? prType : prType.toLowerCase();
        return Schema.SObjectType.Project__c.fields.getMap().keySet().contains(projectTypeString) ? (String) currUs.Project__r.get(prType) : null;
    }
    /**
     * Endpoint integration to get file retrievables.
     * @see DeployAPI.fileToRead
     * @param filesList
     */
    private Map<String, SfRetrievable> getRetrievablesMap(List<Retrievable> retrievableList) {
        Map<String, SfRetrievable> retrievableMap = new Map<String, SfRetrievable>();
        for (Retrievable ret : retrievableList) {
            retrievableMap.put(ret.filePath, ret.metaData);
        }
        return retrievableMap;
    }

    /**
     *  This method returns the Attachment to upsert in the User Story.
     * @param usAttachmentList User Story Attachment with Git MetaData
     * @param retrievableMap Map with metadata
     * @return Attachment to upsert in User Story
     */
    private Attachment attUserStoryRetrievable(List<Attachment> usAttachmentList, Map<String, SfRetrievable> retrievableMap, Id usId) {
        List<SfRetrievable> attUsRetrievable = new List<SfRetrievable>();
        // Identify existing metadata in Git Metadata Attachment
        if (!usAttachmentList.isEmpty()) {
            List<SfRetrievable> sfrList = (List<SfRetrievable>) JSON.deserialize(usAttachmentList[0].Body.toString(), List<SfRetrievable>.class);
            for (SfRetrievable sfr : sfrList) {
                String key = sfr.n + sfr.t;
                if (retrievableMap.containsKey(key)) {
                    SfRetrievable sfret = retrievableMap.get(key);
                    sfr.d = sfret.d;
                    sfr.b = sfret.b;
                    sfr.cmm = UPDATED;
                }
                retrievableMap.put(key, sfr);
            }
        }
        // Adds Metadata to Git Metadata Attachment
        for (SfRetrievable v : retrievableMap.values()) {
            attUsRetrievable.add(v);
        }

        Attachment att = new Attachment();
        if (!usAttachmentList.isEmpty()) {
            att.Id = usAttachmentList[0].Id;
        } else {
            att.ParentId = usId;
            att.Name = GIT_METADATA;
        }
        att.Body = Blob.valueOf(JSON.serialize(attUsRetrievable, true));
        return att;
    }

    /**
     * Method exception
     * @param status
     * @param message
     * @return json serialized message
     */
    private String jsonReturnResult(String status, String message) {
        return JSON.serialize(new CliSfDataWrapper(status, message));
    }

    public interface ServiceHelper {
        DxFormatConvertResponse fileToRet(FileToRetWrapper retWrapper, String sourceFormat);
    }

    public with sharing class InternalServiceHelper implements ServiceHelper {
        public DxFormatConvertResponse fileToRet(FileToRetWrapper retWrapper, String sourceFormat) {
            return DeployAPI.fileToRet(retWrapper, sourceFormat);
        }
    }

    public with sharing class ExternalServiceHelper implements ServiceHelper {
        private final String FW_SLASH = '/';

        /**
         * File to Ret for non Salesforce formats.
         * @param filenameSet
         * @param projectTypeField
         * @return DxFormatConvertResponse
         */
        public DxFormatConvertResponse fileToRet(FileToRetWrapper retWrapper, String sourceFormat) {
            List<Retrievable> retrievablesList = new List<Retrievable>();
            DxFormatConvertResponse fileToRetResponse = new DxFormatConvertResponse();
            for (String pathString : retWrapper.fileList) {
                SfRetrievable retMetaData = new SfRetrievable();
                // "pathString.contains(FW_SLASH)" is extracting file name from pathstring. /classes/myfolder/myfile.js (for example)so, substringAfterLast(FW_SLASH) is going to return last string after last "/"
                retMetaData.n = pathString.contains(FW_SLASH) ? pathString.substringAfterLast(FW_SLASH) : pathString;
                retMetaData.t = sourceFormat;

                Retrievable ret = new Retrievable();
                ret.filePath = pathString;
                ret.metaData = retMetaData;

                retrievablesList.add(ret);
            }
            fileToRetResponse.response = retrievablesList;
            return fileToRetResponse;
        }
    }

    /**
     * Wrapper classes to deserialize copado:work:push api call Body
     */
    @TestVisible
    private class WorkPushWrapper {
        public String userStory;
        public String projectJson;
        public String projectTypeField;
        public List<CommitWrapper> commitList;
    }

    @TestVisible
    private class CommitWrapper {
        public String commitId;
        public String commitMessage;
        public String commitDate;
        public String commitAuthor;
        public List<String> commitFiles;
    }

    public class FileToRetWrapper {
        public Set<String> fileList;
        public String projectJson;
        public FileToRetWrapper(Set<String> fileList, String projectJson) {
            this.fileList = fileList;
            this.projectJson = projectJson;
        }
    }

    /**
     * Classes to parse JSON coming from retrievable endpoint
     */
    public class Retrievable {
        public String filePath;
        public SfRetrievable metaData;
    }
    public class SfRetrievable {
        public String n;
        public Boolean s;
        public String d;
        public String b;
        public String cb;
        public Boolean r;
        public String t;
        public String cd;
        public String cmm;
        public String snapshotCommitId;
    }

    public class DxFormatConvertResponse {
        private List<Retrievable> response;
        private Boolean hasErrors;
        private List<FormatError> errors;
    }
    public class FormatError {
        private String filePath;
        private final String errorKey;
        private final String errorMessage;
    }
    @TestVisible
    private class WorkPushDataWrapper extends CliSfDataWrapper {
        private List<FormatError> errors;
        public WorkPushDataWrapper(String stat, String msg, List<FormatError> errList) {
            status = stat;
            message = msg;
            errors = errList;
        }
    }
}