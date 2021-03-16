@IsTest
public with sharing class TestDataFactory {
    public static List<User> createUsers() {
        List<User> userList = new List<User>();
        User sysUs = new User();
        sysUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        sysUs.LastName = 'LastName';
        sysUs.Email = 'test1@test1.com';
        sysUs.Username = 'psysUser000@amamama.com' + System.currentTimeMillis();
        sysUs.CompanyName = 'TEST';
        sysUs.Title = 'title';
        sysUs.Alias = 'alias';
        sysUs.TimeZoneSidKey = 'America/Los_Angeles';
        sysUs.EmailEncodingKey = 'UTF-8';
        sysUs.LanguageLocaleKey = 'en_US';
        sysUs.LocaleSidKey = 'en_US';
        userList.add(sysUs);

        User stdUs = new User();
        stdUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        stdUs.LastName = 'LastName';
        stdUs.Email = 'test2@test2.com';
        stdUs.Username = 'pstdUser002@amamama.com' + System.currentTimeMillis();
        stdUs.CompanyName = 'TEST';
        stdUs.Title = 'title2';
        stdUs.Alias = 'alias2';
        stdUs.TimeZoneSidKey = 'America/Los_Angeles';
        stdUs.EmailEncodingKey = 'UTF-8';
        stdUs.LanguageLocaleKey = 'en_US';
        stdUs.LocaleSidKey = 'en_US';
        userList.add(stdUs);

        insert userList;

        return userList;
    }

    public static List<Environment__c> createEnvironments(Integer count) {
        List<Environment__c> envList = new List<Environment__c>();
        for (Integer i = 0; i < count; i++) {
            Environment__c envProd = new Environment__c();
            envProd.Name = 'Environment ' + i;
            envProd.Index_Back_Promotion_metadata__c = true;
            envProd.Type__c = 'Production/Developer';

            envList.add(envProd);
        }

        insert envList;

        return envList;
    }

    public static Environment__c createEnvironments(String environmentName, String environmentType) {
        Environment__c environment = new Environment__c();
        environment.Name = environmentName;
        environment.Index_Back_Promotion_metadata__c = true;
        environment.Type__c = environmentType;

        return environment;
    }

    public static List<Org__c> createOrgCredentials(Integer count, String userName, List<Environment__c> envList) {
        List<Org__c> orgList = new List<Org__c>();
        for (Integer i = 0; i < count; i++) {
            Org__c org = new Org__c();
            org.Name = 'Test Org ' + i;
            org.Org_Type__c = 'Production/Developer';
            org.Username__c = userName + i;
            org.Environment__c = envList[i].Id;
            org.Oauth_Signature__c = 'signature';
            org.Validated_Date__c = System.now();

            orgList.add(org);
        }

        insert orgList;

        return orgList;
    }

    public static Org__c createOrgCredentials(String userName, String environmentId, String orgType) {
        Org__c org = new Org__c();
        org.Name = 'Test Org ' + environmentId;
        org.Org_Type__c = orgType;
        org.Username__c = userName + environmentId;
        org.Environment__c = environmentId;
        org.Oauth_Signature__c = 'signature';
        org.Validated_Date__c = System.now();

        return org;
    }

    public static Data_Template__c createDataTemplate(String name, String mainObject, String filterLogic, String orgId) {
        Data_Template__c dataTemplate = new Data_Template__c();
        dataTemplate.Name = name;
        dataTemplate.Description__c = 'This is to test read-only access for Jesus';
        dataTemplate.Main_Object__c = mainObject;
        dataTemplate.Attachment_Options__c = 'Insert attachments';
        dataTemplate.Continue_on_Error__c = 'Continue deployment until blocker issue';
        dataTemplate.Filter_Logic__c = filterLogic;
        dataTemplate.Active__c = true;
        dataTemplate.Template_Source_Org__c = orgId;

        return dataTemplate;
    }

    public static Deployment__c createDeployment(String name, String recordTypeId, String fromOrgId) {
        Deployment__c deployment = new Deployment__c();
        deployment.Name = name;
        deployment.From_Org__c = fromOrgId;
        deployment.RecordTypeId = recordTypeId;

        return deployment;
    }

    public static Attachment createAttachment(String name, String parentId, String attBody) {
        Attachment att = new Attachment();
        att.Name = name;
        att.ParentId = parentId;
        att.Body = Blob.valueOf(attBody);
        return att;
    }

    public static Destination_Org__c createDestinationOrg(String deploymentId, String toOrg) {
        Destination_Org__c destination = new Destination_Org__c();
        destination.Deployment__c = deploymentId;
        destination.To_Org__c = toOrg;

        return destination;
    }

    public static Git_Repository__c createGitRepository() {
        Git_Repository__c repo = new Git_Repository__c();
        repo.Name = 'test repo';

        return repo;
    }

    public static Git_Commit__c createGitCommit(String commitId, Date commitDate, String repositoryId) {
        Git_Commit__c gitCommit = new Git_Commit__c();
        gitCommit.Commit_Id__c = commitId;
        gitCommit.Commit_Date__c = commitDate;
        gitCommit.Git_Repository__c = repositoryId;

        return gitCommit;
    }

    public static Git_Backup__c createGitBackup(String name, String orgId, String repositoryId) {
        Git_Backup__c gitBackup = new Git_Backup__c();
        gitBackup.Name = name;
        gitBackup.Git_Repository__c = repositoryId;
        gitBackup.Org__c = orgId;

        return gitBackup;
    }

    public static Git_Org_Commit__c createGitOrgCommit(String commitId, Date commitDate, String snapshotId, String orgId, String status) {
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c();
        gitOrgCommit.Commit_Id__c = commitId;
        gitOrgCommit.Commit_Date__c = commitDate;
        gitOrgCommit.Git_Backup__c = snapshotId;
        gitOrgCommit.Org__c = orgId;
        gitOrgCommit.Status__c = status;

        return gitOrgCommit;
    }

    public static Copado_Notification__c createCopadoNotification(
        String type,
        String status,
        Boolean isSuccess,
        Boolean isFinished,
        String name,
        String parentId
    ) {
        Copado_Notification__c copadoNotification = new Copado_Notification__c();
        copadoNotification.Type__c = type;
        copadoNotification.status__c = status;
        copadoNotification.isSuccess__c = isSuccess;
        copadoNotification.isFinished__c = isFinished;
        copadoNotification.Name = name;
        copadoNotification.ParentId__c = parentId;

        return copadoNotification;
    }

    public static Step__c createStep(
        String deploymentId,
        String name,
        String type,
        String status,
        Integer order,
        String commitName,
        String dataJson
    ) {
        Step__c step = new Step__c();
        step.Deployment__c = deploymentId;
        step.Name = name;
        step.Type__c = type;
        step.Status__c = status;
        step.Order__c = order;
        step.Commit_Name__c = commitName;
        step.dataJson__c = dataJson;

        return step;
    }

    public static Connection_Behavior__c createConnectionBehavior(
        String promotionBehavior,
        String backPromotionBehavior,
        String statusAfterDeployment
    ) {
        Connection_Behavior__c connectionBehavior = new Connection_Behavior__c();
        connectionBehavior.Name = 'Test Connection Behavior';
        connectionBehavior.Promotion_Behavior__c = promotionBehavior;
        connectionBehavior.Max_Scheduled_Promotion_Batch_Size__c = 1;
        connectionBehavior.Back_Promotion_Behavior__c = backPromotionBehavior;
        connectionBehavior.Max_Scheduled_Back_Promotion_Batch_Size__c = 1;
        connectionBehavior.Story_Status_After_Deployment__c = statusAfterDeployment;

        return connectionBehavior;
    }

    public static Quality_Gate__c createQualityGate(
        String complianceRuleGroupId,
        String metadataGroupId,
        String connectionBehaviorId,
        String seleniumTestGroupId,
        String staticCodeAnalysisSettingId,
        String type,
        String testLevel,
        Integer scoreThreshold
    ) {
        Quality_Gate__c qualityGate = new Quality_Gate__c();
        qualityGate.Name = 'Test Quality Gate';
        qualityGate.Compliance_Rule_Group__c = complianceRuleGroupId;
        qualityGate.Metadata_Group__c = metadataGroupId;
        qualityGate.Connection_Behavior__c = connectionBehaviorId;
        qualityGate.Selenium_Test_Group__c = seleniumTestGroupId;
        qualityGate.Static_Code_Analysis_Settings__c = staticCodeAnalysisSettingId;
        qualityGate.Type__c = type;
        qualityGate.Test_Level__c = testLevel;
        qualityGate.Score_Threshold__c = scoreThreshold;

        return qualityGate;
    }

    public static Deployment_Task__c createDeploymentTask(String name, Integer order, String type, String status, String userStoryId) {
        Deployment_Task__c deploymentTask = new Deployment_Task__c();
        deploymentTask.Name = name;
        deploymentTask.Order__c = order;
        deploymentTask.Type__c = type;
        deploymentTask.Status__c = status;
        deploymentTask.User_Story__c = userStoryId;

        return deploymentTask;
    }

    public static Deployment_Flow__c createDeploymentFlow(String name, Boolean isActive, String gitRepositoryId, Boolean enableDX) {
        Deployment_Flow__c deploymentFlow = new Deployment_Flow__c();
        deploymentFlow.Name = name;
        deploymentFlow.Active__c = isActive;
        deploymentFlow.Git_Repository__c = gitRepositoryId;
        deploymentFlow.Enable_Copado_DX__c = enableDX;

        return deploymentFlow;
    }

    public static Deployment_Flow_Step__c createDeploymentFlowStep(
        String sourceEnvironmentId,
        String destinationEnvironmentId,
        String deploymentFlowId,
        String scratchOrgDestination
    ) {
        Deployment_Flow_Step__c deploymentFlowStep = new Deployment_Flow_Step__c();
        deploymentFlowStep.Source_Environment__c = sourceEnvironmentId;
        deploymentFlowStep.Destination_Environment__c = destinationEnvironmentId;
        deploymentFlowStep.Deployment_Flow__c = deploymentFlowId;
        deploymentFlowStep.Enable_as_Scratch_Org_Destination__c = scratchOrgDestination;

        return deploymentFlowStep;
    }

    public static Project__c createProject(String name, String deploymentFlowId, Boolean indexMetadata) {
        Project__c project = new Project__c();
        project.Name = name;
        project.Deployment_Flow__c = deploymentFlowId;
        project.Index_Metadata__c = indexMetadata;

        return project;
    }

    public static Release__c createRelease(String name, String projectId) {
        Release__c release = new Release__c();
        release.Name = name;
        release.Project__c = projectId;

        return release;
    }

    public static User_Story__c createUserStory(
        String userStoryTitle,
        String status,
        String sprintId,
        String projectId,
        String environmentId,
        String orgId
    ) {
        User_Story__c userStory = new User_Story__c();
        userStory.User_Story_Title__c = userStoryTitle;
        userStory.Status__c = status;
        userStory.Sprint__c = sprintId;
        userStory.Project__c = projectId;
        userStory.Environment__c = environmentId;
        userStory.Org_Credential__c = orgId;

        return userStory;
    }

    public static Test_Script__c createTestScript(String testScriptName, String userStoryId) {
        Test_Script__c testScript = new Test_Script__c();
        testScript.Test_Title__c = testScriptName;
        testScript.User_Story__c = userStoryId;
        return testScript;
    }

    public static Test_Script_Step__c createTestScriptStep(
        Integer order,
        String stepTitle,
        String actionDescription,
        String expectedResult,
        String testScriptId
    ) {
        Test_Script_Step__c testScriptStep = new Test_Script_Step__c();
        testScriptStep.Step_Title__c = stepTitle;
        testScriptStep.Order__c = order;
        testScriptStep.Action_Description__c = actionDescription;
        testScriptStep.Expected_Result__c = expectedResult;
        testScriptStep.Test_Script__c = testScriptId;

        return testScriptStep;
    }

    public static Test_Run__c createTestRun(String testScriptId, String testerId, String environmentId) {
        Test_Run__c testRun = new Test_Run__c();
        testRun.Test_Script__c = testScriptId;
        testRun.Tester__c = testerId;
        testRun.Environment__c = environmentId;

        return testRun;
    }

    public static SObject createSObject(SObject sObj, Map<Schema.SObjectField, Object> fieldDefaults) {
        addFieldDefaults(sObj, fieldDefaults);
        return sObj;
    }

    public static List<SObject> createSObjectList(SObject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, null, null);
    }

    public static List<SObject> createSObjectList(
        SObject sObj,
        Integer numberOfObjects,
        Map<Schema.SObjectField, Object> fieldDefaults,
        Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFields
    ) {
        List<SObject> sObjs = new List<SObject>{};
        SObject newObj;
        newObj = createSObject(sObj, fieldDefaults);

        // Get the name field for the object
        String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }
        System.debug('namefield: ' + nameField);
        Boolean nameIsAutoNumber = sObj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber();

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            if (!nameIsAutoNumber && nameField != 'Id') {
                clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
            }
            if (incrementalFields.containsKey(sObj.getSObjectType())) {
                for (Schema.SObjectField field : incrementalFields.get(sObj.getSObjectType())) {
                    clonedSObj.put(field, (String) clonedSObj.get(field) + ' ' + i);
                }
            }
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // When we create a list of SObjects, we need to have a unique field for the insert if there isn't an autonumber field.
    // Usually we use the Name field, but some objects don't have a name field.
    private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField>{
        Contact.SObjectType => Contact.LastName,
        Case.SObjectType => Case.CaseNumber, //this is the autonumber field
        User.SObjectType => User.LastName,
        PermissionSetAssignment.SObjectType => PermissionSetAssignment.Id
    };

    public class TestDataFactoryException extends Exception {
    }
}