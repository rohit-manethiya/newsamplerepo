public with sharing class DeployCommits {
    public String repositoryId { get; set; }
    public String branch {get; set;}
    public Git_Repository__c repo {get; set;}
    public List<GitHelper.ACommit> commits;
    public Git_Commit__c dateFrom { get; set; }
    public Git_Commit__c dateTo { get; set; }
    public Deployment__c deployment { get; set; }
    public String chooseCommit {get; set;}
    public String startCommit {get; set;}
    public String endCommit {get; set;}
    public Settings settings { get; set; }
    public String errorLevel { get; set; }
    public String messageName { get; set; }
    public GitHelper.ACommit startGitCommit {get; set;}
    public GitHelper.ACommit endGitCommit {get; set;}
    
    public Step__c step { get; set; }

    public DeployCommits(){
        initValues();
    }

    public DeployCommits(ApexPages.StandardController std){
        initValues();
        deployment.Name = 'Git Deployment';
    }

    private void initValues() {
        repositoryId = ApexPages.currentPage().getParameters().get('repositoryId');
        DateTime frm = DateTime.now().addYears(-1);
        dateFrom = new Git_Commit__c(Commit_Date__c = frm.date());
        dateTo = new Git_Commit__c(Commit_Date__c = Date.today() + 1);
        step = new Step__c(CheckOnly__c = false, Run_All_Tests__c = false);
        deployment = new Deployment__c();
        
        try{
        	repo = [SELECT Id, Name, URI__c FROM Git_Repository__c WHERE Id =:repositoryId];
        }
        catch(Exception excp){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'LABEL: Invalid Repository Id: ' + repositoryId));
        }
    }

    public Boolean getShowTable() {
        return String.isBlank(startCommit) || String.isBlank(endCommit);
    }

    public Boolean getShowDeploy() {
        return String.isNotBlank(startCommit) && String.isNotBlank(endCommit);
    }

    public List<GitHelper.ACommit> getCommits(){
        return GitHelper.getCommits(repositoryId, branch, dateFrom.Commit_Date__c, dateTo.Commit_Date__c, startCommit, endCommit,200);
    }
    
    public PageReference chooseCommit() {
        if(String.isBlank(startCommit)) {
            startCommit = chooseCommit;
            startGitCommit = GitHelper.commitMap.get(chooseCommit);
            branch = startGitCommit.branch;
        } else {
            endCommit = chooseCommit;
            endGitCommit = GitHelper.commitMap.get(chooseCommit);
        }
        return null;
    }

    public PageReference cancel() {
        PageReference pr = new ApexPages.StandardController(repo).view();
        pr.setRedirect(true);
        return pr;
    }

    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public void showMessage() {
        ApexPages.Severity level = errorLevel == 'WARNING' ? ApexPages.Severity.Warning : errorLevel == 'CONFIRM' ? ApexPages.Severity.CONFIRM : ApexPages.Severity.ERROR;
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
    }
}