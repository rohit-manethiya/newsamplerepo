public with sharing class WorkSubmitService implements CLIInterface {

    private final Settings cSetting = new Settings();
    private final List<String> attNames = new List<String>{
            'MetaData', 'Git MetaData', 'Test Classes'
    };
    private final String orgId = UserInfo.getOrganizationId();
    private final String VALIDATION = 'Validation';
    private final String SLASH = '/';
    private final String NONE = 'none';
    private final String VALIDATE = 'validate';
    private final String PROMOTE = 'promote';
    private final String DEPLOY = 'deploy';
    private User_Story__c userStory;


    /**
    * Empty Constructor
    */
    public WorkSubmitService() {
    }

    /**
     * Get instance of WorkSubmitService that implements CLI Interface
     * @return instance of WorkSubmitService()
     */
    public CLIInterface getInstance() {
        return new WorkSubmitService();
    }

    /**
     * Runs requested operation under root service
     * @return JSON of CliSfDataWrapper.ReturnWrapper as return of requestedAction
     */
    public String run(CliProxy.CLIWrapper record) {
        List<String> checkOlsList = CliSecurityService.checkOLS(new List<String>{
                Schema.SObjectType.User_Story__c.getName()
        });
        if(!checkOlsList.isEmpty()) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.Insufficient_Access + checkOlsList));
        }

        String requestedAction = record.operation.toLowerCase();
        SubmitServiceWrapper params = (SubmitServiceWrapper) JSON.deserialize(record.body, SubmitServiceWrapper.class);

        List<User_Story__c> userStoryList = [SELECT Id, Name, Promote_and_Deploy__c, Promote_Change__c, Last_Validation_Promotion__c, Project__c, Release__c, Environment__c, Promote_as_Single_Step__c, Promotion_Test_Level__c, Org_Credential__c FROM User_Story__c WHERE Id = :params.usId LIMIT 1];
        if(userStoryList.isEmpty()) {
            // This case of no user story found is handled by CLI client
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), null));
        }
        userStory = userStoryList[0];

        return (requestedAction == VALIDATE ? validate() : requestedAction == PROMOTE || requestedAction == DEPLOY ? promoteDeploy(requestedAction) : Label.UnSupportedOperation);
    }

    /**
     * Changes "promote" or "promote and deploy" USer Story checkboxes
     * @param action  promote to change "promote" checkbox or deploy to change "promote and deploy" checkbox
     * @return JSON of CliSfDataWrapper.ReturnWrapper
     */
    public String promoteDeploy(String action) {
        List<String> fieldList = new List<String>();
        WorkSubmitDataWrapper returnDataWrapper = new WorkSubmitDataWrapper();
        if(action == PROMOTE) {
            userStory.Promote_Change__c = true;
            fieldList.add(Schema.SObjectType.User_Story__c.fields.Promote_Change__c.getName());
        } else if(action == DEPLOY) {
            userStory.Promote_and_Deploy__c = true;
            fieldList.add(Schema.SObjectType.User_Story__c.fields.Promote_and_Deploy__c.getName());
        }
        List<String> checkFlsList = CliSecurityService.checkFLS(Schema.SObjectType.User_Story__c.getName(), fieldList, Utilities.DML_Action.UPD);
        if(!checkFlsList.isEmpty()) {
            returnDataWrapper.status = CliSfDataWrapper.StatusResult.ERROR.name();
            returnDataWrapper.message = Label.Insufficient_Access + checkFlsList;
            return(JSON.serialize(returnDataWrapper));
        }
        try {
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
            returnDataWrapper.status = CliSfDataWrapper.StatusResult.OK.name();
            returnDataWrapper.userStory = userStory;
        } catch(Exception excp) {
            returnDataWrapper.status = CliSfDataWrapper.StatusResult.ERROR.name();
            returnDataWrapper.message = excp.getMessage();
        }
        return(JSON.serialize(returnDataWrapper));
    }

    /**
     * This method creates a validation deployment for defined usId
     * @param usId - user Story Id to validate
     * @return JSON of CliSfDataWrapper.ReturnWrapper
     */
    private String validate() {
        List<String> checkFlsList = new List<String>();
        List<String> checkFlsPromotion = CliSecurityService.checkFLS(Schema.SObjectType.Promotion__c.getName(), new List<String>{
                Schema.SObjectType.Promotion__c.fields.Project__c.getName(), Schema.SObjectType.Promotion__c.fields.Release__c.getName(), Schema.SObjectType.Promotion__c.fields.Source_Org_Credential__c.getName(), Schema.SObjectType.Promotion__c.fields.Source_Environment__c.getName(), Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.getName(), Schema.SObjectType.Promotion__c.fields.Status__c.getName()
        }, Utilities.DML_Action.INS);
        if(!checkFlsPromotion.isEmpty()) {
            checkFlsList.addAll(checkFlsPromotion);
        }
        List<String> checkFlsPromotedUserStory = CliSecurityService.checkFLS(Schema.SObjectType.Promoted_User_Story__c.getName(), new List<String>{
                Schema.SObjectType.Promoted_User_Story__c.fields.User_Story__c.getName(), Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.getName()
        }, Utilities.DML_Action.INS);
        if(!checkFlsPromotedUserStory.isEmpty()) {
            checkFlsList.addAll(checkFlsPromotedUserStory);
        }
        List<String> checkFlsUserStory = CliSecurityService.checkFLS(Schema.SObjectType.User_Story__c.getName(), new List<String>{
                Schema.SObjectType.User_Story__c.fields.Last_Validation_Promotion__c.getName(), Schema.SObjectType.User_Story__c.fields.Last_Validation_Deployment__c.getName()
        }, Utilities.DML_Action.UPD);
        if(!checkFlsPromotedUserStory.isEmpty()) {
            checkFlsList.addAll(checkFlsPromotedUserStory);
        }

        if(!checkFlsList.isEmpty()) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.Insufficient_Access + checkFlsList));
        }

        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = userStory.Project__c;
        promotion.Release__c = userStory.Release__c;
        promotion.Source_Org_Credential__c = userStory.Org_Credential__c;
        promotion.Source_Environment__c = userStory.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;
        promotion.Status__c = VALIDATION;
        Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);

        Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);
        pus.Name = 'Promoted User Story: ' + userStory.Name;
        Utilities.Secure_DML(pus, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);

        userStory.Last_Validation_Promotion__c = promotion.Id;
        userStory.Last_Validation_Deployment__c = null;
        Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);

        DeployAPI.deployPromotionAsync(userStory.Last_Validation_Promotion__c, userStory.Name, true, userStory.Promote_as_Single_Step__c, userStory.Promotion_Test_Level__c);
        return JSON.serialize(new WorkSubmitDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), 'Promotion record ' + promotion.Id + ' has been created for User Story ' + userStory.Id));
    }

    /**
     * Wrapper class to deserialize copado:work:submit api call Body
     */
    @TestVisible
    private class SubmitServiceWrapper {
        public String usId;
    }

    @TestVisible
    private class WorkSubmitDataWrapper extends CliSfDataWrapper {
        public User_Story__c userStory;
        public WorkSubmitDataWrapper() {
        }
        public WorkSubmitDataWrapper(String stat, User_Story__c us) {
            status = stat;
            userStory = us;
        }
        public WorkSubmitDataWrapper(String stat, String msg) {
            status = stat;
            message = msg;
        }
    }
}