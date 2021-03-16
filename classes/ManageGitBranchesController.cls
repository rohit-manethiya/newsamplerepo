global with sharing class ManageGitBranchesController {

    public class CopadoException extends Exception{}
    public Git_Repository__c gitRepo {get;set;}
    public String repoId {get;set;}
    public Boolean showError {get;set;}
    public Set<String> branchNamesInUse {
    get{
        if(null == branchNamesInUse){
            branchNamesInUse = new Set<String>{'master'};
        }
        return branchNamesInUse;
    }set;}
    public String branchNamesInUseJoined {
    get{
        return String.join(new List<String>(branchNamesInUse),',');
    }set;}

    public ManageGitBranchesController() {
        // Show Destructive Changes Warning
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DELETE_BRANCHES_WARNING));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.BranchesInUseInfo));
        // Get RepositoryId from URL
        repoId = ApexPages.currentPage().getParameters().get('repoId');
        if(null == repoId) {
            showError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.GIT_REPOSITORY_ID_NOT_FOUND));
        } else {
            if(Schema.sObjectType.Git_Repository__c.isQueryable()) {
                Set<Id> flowIds = new Set<Id>();
                for (Git_Repository__c gitRepository : [SELECT Id, Name, URI__c,(SELECT Id, Main_Branch__c FROM Deployment_Flows__r) FROM Git_Repository__c WHERE Id = :repoId]) {
                    gitRepo = gitRepository;
                    for(Deployment_Flow__c df :gitRepository.Deployment_Flows__r){
                        flowIds.add(df.Id);
                        if(String.isNotBlank(df.Main_Branch__c)) {
                            branchNamesInUse.add(df.Main_Branch__c);
                        }
                    }
                }
                if(flowIds.size() > 0){
                    for(Deployment_Flow_Step__c dfs :[SELECT Id, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c IN :flowIds]){
                        if(String.isNotBlank(dfs.Branch__c)) {
                            branchNamesInUse.add(dfs.Branch__c);
                        }
                    }
                }
            }
            showError = false;
        }
    }

    public PageReference deleteGitBranches() {
        if(gitRepo.Id != null) {
            try {
            String deleteGitBranches = ApexPages.currentPage().getParameters().get('deleteGitBranches');
            String callURL = Settings.Server_URL + '/json/v1/deleteGitBranches/' + EncodingUtil.urlEncode(gitRepo.Id,'UTF-8');
                HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, deleteGitBranches, true);
                String body = res.getBody();
                if(String.isNotBlank(body)){
                    CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                    if(String.isNotBlank(r.copadoJobId)) {
                        JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DELETE_GIT_BRANCHES,null,'Starting...');
                    }
                }
            } catch (Exception e){
                throw new CopadoException('An error has occured while deleting branches. ' + e.getMessage());
            }
        }
        return null;
    }

    public PageReference refreshBranchCache(){
        if(String.isNotBlank(repoId)){
            SfdxAPI.retrieveBranchesFromRepository(repoId);
        }
        return null;
    }

    public PageReference cancel(){
        //return new PageReference('/'+repoId);
        return new ApexPages.StandardController(gitRepo).view();

    }
}