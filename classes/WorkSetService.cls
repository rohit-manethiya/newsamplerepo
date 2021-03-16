public with sharing class WorkSetService implements CLIInterface {
    /**
     * Empty Constructor
     */
    public WorkSetService() {
    }
    /**
     * Get instance of WorkSet Service that implements CLI Interface
     * @return instance of WorkSetService()
     */
    public CLIInterface getInstance() {
        return new WorkSetService();
    }
    /**
     * Runs requested operation under root service
     * @return JSON of CliSfDataWrapper.ReturnWrapper
     */
    public String run(CliProxy.CLIWrapper record) {
        List<String> checkOlsList = CliSecurityService.checkOLS(
            new List<String>{ Schema.SObjectType.User_Story__c.getName(), Schema.SObjectType.Deployment_Flow_Step__c.getName() }
        );
        if (!checkOlsList.isEmpty()) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.Insufficient_Access + checkOlsList));
        }
        WorkSetWrapper params = (WorkSetWrapper) JSON.deserialize(record.body, WorkSetWrapper.class);
        // Passing directly params.value to que string query doesen't work.
        String prmVal = params.value;

        String soqlString = 'SELECT Id, Name, Environment__c, Base_Branch__c, Project__r.Deployment_Flow__c, Project__r.Deployment_Flow__r.Main_Branch__c, Release__r.Base_Branch__c, (SELECT External_Id__c FROM User_Story_Commits__r ORDER BY Snapshot_Commit__r.Commit_Date__c DESC LIMIT 1) FROM User_Story__c WHERE {0} = :prmVal LIMIT 1';
        String dynamicQuery = String.format(soqlString, new List<String>{ String.escapeSingleQuotes(params.criteria) });
        List<User_Story__c> sObjList = Database.query(dynamicQuery);

        List<Deployment_Flow_Step__c> pipelineConnList = new List<Deployment_Flow_Step__c>();
        if (!sObjList.isEmpty()) {
            pipelineConnList = [
                SELECT Id, Branch__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :sObjList[0].Project__r.Deployment_Flow__c AND Source_Environment__c = :sObjList[0].Environment__c
            ];
            if (pipelineConnList.isEmpty()) {
                return (JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.USER_STORY_COMMIT_NO_ENVIRONMENT)));
            }
        }

        return (JSON.serialize(
            new WorkSetDataWrapper(
                CliSfDataWrapper.StatusResult.OK.name(),
                !sObjList.isEmpty() ? pipelineConnList[0].Branch__c : null,
                !sObjList.isEmpty() ? sObjList[0] : null
            )
        ));
    }
    /**
     * Wrapper class to deserialize copado:work:set api call Body
     */
    @TestVisible
    private class WorkSetWrapper {
        public String criteria;
        public String value;
    }
    @TestVisible
    private class WorkSetDataWrapper extends CliSfDataWrapper {
        public User_Story__c userStory;
        public String environmentBranch;
        public WorkSetDataWrapper(String stat, String envb, User_Story__c us) {
            status = stat;
            environmentBranch = envb;
            userStory = us;
        }
    }
}