public with sharing class GitCommitLookupController{
    public String selectedRepository { get; set; }
    
    public GitCommitLookupController() {
        selectedRepository = '';
    }

    public static List<SelectOption> getRepositories() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Select --'));
        if(Schema.SObjectType.Git_Repository__c.isQueryable() && Schema.SObjectType.Git_Repository__c.isAccessible()) {
            for(Git_Repository__c gitRepository : [SELECT Id, Name FROM Git_Repository__c ORDER BY Name DESC LIMIT 200]) {
                options.add(new SelectOption(gitRepository.Id, gitRepository.Name));
            }
        }
        return options;
    }

    public string getFormTag() {
        return System.currentPageReference().getParameters().get('frm');
    }
     
    public string getTextBox() {
        return System.currentPageReference().getParameters().get('txt');
    }
}