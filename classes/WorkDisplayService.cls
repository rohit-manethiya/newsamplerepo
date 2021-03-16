public with sharing class WorkDisplayService implements CLIInterface {
    /**
     * Empty Constructor
     */
    public WorkDisplayService() {
    }
    /**
     * Get instance of WorkDisplayService that implements CLI Interface
     * @return instance of WorkDisplayService()
     */
    public CLIInterface getInstance() {
        return new WorkDisplayService();
    }

    /**
     * Runs requested operation under root service
     * @return JSON of CliSfDataWrapper.ReturnWrapper
     */
    public String run(CliProxy.CLIWrapper record) {
        List<String> checkOlsList = CliSecurityService.checkOLS(new List<String>{ Schema.SObjectType.User_Story__c.getName() });
        if (!checkOlsList.isEmpty()) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.Insufficient_Access + checkOlsList));
        }
        WorkDisplayWrapper params = (WorkDisplayWrapper) JSON.deserialize(record.body, WorkDisplayWrapper.class);
        // Passing directly params.value to que string query doesen't work.
        String prmVal = params.value;

        String soqlString = 'SELECT Id, Name, User_Story_Title__c, Status__c, Project__r.Name, Sprint__c, Release__r.Name FROM User_Story__c WHERE {0} = :prmVal LIMIT 1';
        String dynamicQuery = String.format(soqlString, new List<String>{ String.escapeSingleQuotes(params.criteria) });
        List<User_Story__c> sobjList = Database.query(dynamicQuery);
        return (JSON.serialize(new WorkDisplayDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), !sobjList.isEmpty() ? sobjList[0] : null)));
    }
    /**
     * Wrapper class to deserialize copado:work:display api call Body
     */
    @TestVisible
    private class WorkDisplayWrapper {
        public String criteria;
        public String value;
    }

    @TestVisible
    private class WorkDisplayDataWrapper extends CliSfDataWrapper {
        public User_Story__c userStory;
        public WorkDisplayDataWrapper(String stat, User_Story__c us) {
            status = stat;
            userStory = us;
        }
    }
}