public with sharing class UserStoryReadyForPromoteExtension {
    //CONSTANT variables
    private static final String apiKey = DeployAPI.getUserAPIKey();
    private final List<String> manualSteps = new List<String>{
            'Pull Request', 'Manual Approval', 'Manual Test'
    };

    //NON-CONSTANT variables
    public User_Story__c currentUserStory { get; set; }
    public Boolean manualStepRequired { get; set; }
    public String nextEnvironment { get; set; }
    public String connectionBehavior { get; set; }

    public List<Quality_Gate__c> qualityGateList {
        get {
            if(null == qualityGateList) {
                qualityGateList = new List<Quality_Gate__c>();
            }
            return qualityGateList;
        }
        set;
    }
    public List<User_Story__c> dependenciesList {
        get {
            if(null == dependenciesList) {
                dependenciesList = new List<User_Story__c>();
            }
            return dependenciesList;
        }
        set;
    }

    public Map<String, List<Object>> pageMessagesMap { get; set; }

    //current User api key

    public Boolean hasApiKey {
        get {
            return null != apiKey;
        }
        set;
    }
    public static String ERROR = 'ERROR';
    public static String WARNING = 'WARNING';

    /**
     * Account Summary redirection to create api key
     *
     * @return PageReference
     */
    public pageReference redirectToAccountSummary() {
        PageReference pageRef = Page.appHome;
        pageRef.setRedirect(true);
        return pageRef;
    }
    /**
     * DeploymentFlowSteps getter
     *
     * @return DeploymentFlowSteps
     */
    public List<GlobalUtilities.flowStepWrapper> getDeploymentFlowSteps() {
        System.debug('currentUserStory===> ' + currentUserStory);
        List<GlobalUtilities.flowStepWrapper> visualFlowSteps = GlobalUtilities.getDeploymentFlowSteps(currentUserStory);
        for(GlobalUtilities.flowStepWrapper fswItem : visualFlowSteps) {
            if(fswItem.style == 'slds-is-complete slds-is-won') {
                fswItem.style = 'slds-is-complete';
            }
        }
        if(visualFlowSteps.isEmpty() && String.isNotBlank(currentUserStory.Org_Credential__c) && String.isNotBlank(currentUserStory.Project__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Org_Credential_Not_Included_In_Deployment_Flow));
        }
        return visualFlowSteps;
    }

    public UserStoryReadyForPromoteExtension(ApexPages.StandardController stdController) {
        pageMessagesMap = new Map<String, List<Object>>();

        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>{
                    'Name', 'Manual_Step_Required__c', 'Project__r.Deployment_Flow__c', 'Release__r.Base_Branch__c', 'Base_Branch__c', 'Release__r.Project__r.Deployment_Flow__c', 'Promote_Change__c', 'Environment__c', 'Environment__r.Name', 'Org_Credential__c', 'Org_Credential__r.Org_Type__c'
            });
        }
        this.currentUserStory = (User_Story__c) stdController.getRecord();

        if(currentUserStory.Promote_Change__c) {
            pageMessagesMap.put(WARNING, new List<Object>{
                    Label.USER_STORY_ALREADY_MARKED_FOR_PROMOTION
            });
        }
        calculateConnectionBehavior();
    }

    /**
     * method to return related pipeline Connections based current parameter
     *
     * @param envParam environment name if sent from the page
     * @param depFlow pipeline Id
     * @param sourceEnv current User Story Environment
     *
     * @return Deployment_Flow_Step__c list
     */
    public List<Deployment_Flow_Step__c> returnPipelineConnections(String envParam, Id depFlow, Id sourceEnv) {
        List<Deployment_Flow_Step__c> pipelineConnection;
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            if(String.isNotBlank(envParam)) {
                pipelineConnection = [
                        SELECT Id, Name, Destination_Environment__r.Name, Connection_Behavior__c, Connection_Behavior_Override__c
                        FROM Deployment_Flow_Step__c
                        WHERE Source_Environment__r.Name = :envParam
                        AND Deployment_Flow__c = :depFlow
                ];
            } else {
                pipelineConnection = [
                        SELECT Id, Name, Destination_Environment__r.Name, Connection_Behavior__c, Connection_Behavior_Override__c
                        FROM Deployment_Flow_Step__c
                        WHERE Source_Environment__c = :sourceEnv
                        AND Deployment_Flow__c = :depFlow
                ];
            }
        } else {
            pageMessagesMap.put(ERROR, new List<Object>{
                    Label.Insufficient_Access, Label.Related_Object + ': ' + Schema.SObjectType.Deployment_Flow_Step__c.Name
            });
        }
        return pipelineConnection;
    }

    /**
     * execution of connection behavior calculation process
     */
    public void calculateConnectionBehavior() {
        qualityGateList.clear();
        manualStepRequired = false;
        Id sourceEnv = currentUserStory.Environment__c;
        if(Test.isRunningTest()) {
            currentUserStory = [SELECT Id, Base_Branch__c, Release__r.Base_Branch__c, Promote_Change__c, Org_Credential__r.Org_Type__c, Name, Environment__c, Org_Credential__c, Project__r.Deployment_Flow__c, Project__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE Id = :currentUserStory.Id];
        }
        Id depFlow = null != currentUserStory.Project__r.Deployment_Flow__c ? currentUserStory.Project__r.Deployment_Flow__c : currentUserStory.Release__r.Project__r.Deployment_Flow__c;

        String envParam = ApexPages.currentPage().getParameters().get('environment');
        List<Deployment_Flow_Step__c> pipelineConnection = returnPipelineConnections(envParam, depFlow, sourceEnv);

        if(pipelineConnection.isEmpty()) {
            pageMessagesMap.clear();
            pageMessagesMap.put(ERROR, new List<Object>{
                    Label.USER_STORY_NEXT_ENV_NOT_FOUND
            });
            return;
        }
        System.debug('pipelineConnection===> ' + pipelineConnection);

        nextEnvironment = pipelineConnection[0].Destination_Environment__r.Name;

        dependenciesList = GlobalUtilities.getUserStoriesDependencies(new Set<Id>{
                currentUserStory.Id
        }, pipelineConnection[0].Destination_Environment__c);

        if(String.isBlank(pipelineConnection[0].Connection_Behavior__c)) {
            pageMessagesMap.put(ERROR, new List<Object>{
                    Label.USER_STORY_CONNECTION_BEHAVIOR_NOT_FOUND
            });
            return;
        }
        List<Attachment> attList = [SELECT Name, Body, ParentId FROM Attachment WHERE ParentId = :currentUserStory.Id AND Name = 'Git MetaData'];
        Attachment attItem;
        if(attList.size() > 0) {
            attItem = attList[0];
        } else {
            pageMessagesMap.put(ERROR, new List<Object>{
                    Label.NoCommitOnUs
            });
            return;
        }

        List<AttachmentTriggerHelper.jsonMetaDataWrapper> dataList = (List<AttachmentTriggerHelper.jsonMetaDataWrapper>) JSON.deserialize(attItem.Body.toString(), List<AttachmentTriggerHelper.jsonMetaDataWrapper>.class);

        connectionBehavior = [SELECT Id, Promotion_Behavior__c FROM Connection_Behavior__c WHERE Id = :pipelineConnection[0].Connection_Behavior__c].Promotion_Behavior__c;

        returnQualityGates(dataList, pipelineConnection);
    }

    /**
     * find related quality gates which will run based on currently commitled data
     *
     * @param dataList committed data on current User story
     * @param pipelineConnection related deployment flow steps
     *
     * @return Quality_Gate__c List
     */
    public List<Quality_Gate__c> returnQualityGates(List<AttachmentTriggerHelper.jsonMetaDataWrapper> dataList, List<Deployment_Flow_Step__c> pipelineConnection) {
        if(Schema.SObjectType.Quality_Gate__c.isQueryable() && Schema.SObjectType.Quality_Gate__c.isAccessible()) {
            List<Quality_Gate__c> tempList = [SELECT Metadata_Group__c, Id, Name, Type__c, Connection_Behavior__r.Promotion_Behavior__c, Connection_Behavior__r.Promotion_Schedule__c FROM Quality_Gate__c WHERE Connection_Behavior__c = :pipelineConnection[0].Connection_Behavior__c LIMIT 1000];
            Set<Id> mgIds = new Set<Id>();
            for(Quality_Gate__c qgItem : tempList) {
                mgIds.add(qgItem.Metadata_Group__c);
            }
            if(Schema.SObjectType.Metadata_Group_Item__c.isQueryable() && Schema.SObjectType.Metadata_Group_Item__c.isAccessible()) {
                List<Metadata_Group_Item__c> mgiList = [SELECT Id, Name, Metadata_Group__c, Type__c, Operator__c, Value__c FROM Metadata_Group_Item__c WHERE Metadata_Group__c IN :mgIds];
                Map<Id, List<Metadata_Group_Item__c>> mgId_mgiListMap = new Map<Id, List<Metadata_Group_Item__c>>();
                for(Metadata_Group_Item__c mgiItem : mgiList) {
                    List<Metadata_Group_Item__c> tempListMgi = new List<Metadata_Group_Item__c>();
                    if(mgId_mgiListMap.containsKey(mgiItem.Metadata_Group__c)) {
                        tempListMgi = mgId_mgiListMap.get(mgiItem.Metadata_Group__c);
                    }
                    tempListMgi.add(mgiItem);
                    mgId_mgiListMap.put(mgiItem.Metadata_Group__c, tempListMgi);
                }
                for(Quality_Gate__c qgItem : tempList) {
                    if(mgId_mgiListMap.containsKey(qgItem.Metadata_Group__c)) {
                        for(Metadata_Group_Item__c mgiItem : mgId_mgiListMap.get(qgItem.Metadata_Group__c)) {
                            if(AttachmentTriggerHelper.createStep(dataList, mgiItem)) {
                                if(manualSteps.contains(qgItem.Type__c)) {
                                    manualStepRequired = true;
                                }
                                qualityGateList.add(qgItem);
                                break;
                            }
                        }
                    }
                }
            } else {
                pageMessagesMap.put(ERROR, new List<Object>{
                        Label.Insufficient_Access, Label.Related_Object + ': ' + Schema.SObjectType.Metadata_Group_Item__c.Name
                });
            }
        } else {
            pageMessagesMap.put(ERROR, new List<Object>{
                    Label.Insufficient_Access, Label.Related_Object + ': ' + Schema.SObjectType.Quality_Gate__c.Name
            });
        }
        return qualityGateList;
    }
    /**
     * redirection to User Story after submit/cancel operation
     *
     * @return
     */
    public PageReference goBackToUserStory() {
        return new PageReference('/' + currentUserStory.Id);
    }

    /**
     * User Story update for promote changes
     *
     * @return
     */
    public PageReference submitChanges() {
        if(currentUserStory.Promote_Change__c) {
            currentUserStory.Promote_Change__c = false;
            Utilities.Secure_DML(currentUserStory, Utilities.DML_Action.UPD, SObjectType.User_Story__c);
            if(ApexPages.getMessages().size() > 0) {
                populatePageMessagesMap();
                return null;
            }
        }
        currentUserStory.Promote_Change__c = true;
        if(manualStepRequired) {
            currentUserStory.Manual_Step_Required__c = true;
        }
        try {
            Utilities.Secure_DML(currentUserStory, Utilities.DML_Action.UPD, SObjectType.User_Story__c);
        } catch(DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        if(ApexPages.getMessages().size() > 0) {
            populatePageMessagesMap();
            return null;
        }

        PageReference pageRef = new PageReference('/' + currentUserStory.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }

    /**
     * populatePageMessagesMap population
     */
    public void populatePageMessagesMap() {
        pageMessagesMap.clear();
        for(ApexPages.Message msg : ApexPages.getMessages()) {
            pageMessagesMap.put(msg.getSeverity().name(), new List<Object>{
                    msg.getDetail()
            });
        }
    }

}