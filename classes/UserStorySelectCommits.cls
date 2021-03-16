public with sharing class UserStorySelectCommits {
    public User_Story__c us {get;set;}
    public String repositoryId {get;set;}
    public String snapshotId {get;set;}
    public String orgId {get;set;}
    public String userStoryId {get;set;}

    public List<ACommit> commits {get;set;}
    public String orgName {get;set;}
    public String repoName {get;set;}
    public String branch {get;set;}

    //Pagination
    public Boolean showPagination {get;set;}
    public Boolean showNext {get;set;}
    public Boolean showPrevious {get;set;}
    public Integer oSet {get;set;}
    public static final Integer OFFSET_INT = 200;

    public UserStorySelectCommits(ApexPages.StandardController std){
        oSet = 0;
        this.us = (User_Story__c) std.getRecord();
        Map<String, String> params = ApexPages.currentPage().getParameters();
        repositoryId = params.get('repoId');
        snapshotId = params.get('snapshotId');
        orgId = params.get('orgId');
        userStoryId = params.get('userStoryId');

        //get values for subtitle
        if (Schema.SObjectType.Git_Backup__c.isQueryable() && String.isNotBlank(snapshotId)) {
            Git_Backup__c snapshot = new Git_Backup__c();
            if(Schema.sObjectType.Git_Backup__c.isQueryable() && Schema.sObjectType.Git_Backup__c.isAccessible()){
                snapshot = [SELECT Org__r.Name, Branch__c, Git_Repository__r.Name FROM Git_Backup__c WHERE Id = :snapshotId];
            }
            orgName = snapshot.Org__r.Name;
            repoName = snapshot.Git_Repository__r.Name;
            branch = snapshot.Branch__c;
        }

        //get Commits and start pagination if needed
        commits = getCompletedSnapshotCommits();
        showPrevious = false;
        if(commits.size()>=OFFSET_INT){showNext = true;showPagination = true;}

    }
    public List<ACommit> getCompletedSnapshotCommits(){
        commits = new List<ACommit>();
        Set<String> existing = new Set<String>();
        if (Schema.SObjectType.User_Story_Commit__c.isQueryable() && Schema.SObjectType.User_Story_Commit__c.isAccessible() && Schema.SObjectType.Git_Org_Commit__c.isQueryable()) {
            for (User_Story_Commit__c sc : [SELECT Snapshot_Commit__r.Commit_Id__c FROM User_Story_Commit__c WHERE User_Story__c = :userStoryId])existing.add(sc.Snapshot_Commit__r.Commit_Id__c);
                for (Git_Org_Commit__c c : [
                        SELECT Commit_Date__c, Commit_Id__c, Commit_Message__c
                        FROM Git_Org_Commit__c
                        WHERE Git_Backup__c = :this.snapshotId AND Status__c = 'Complete'
                        ORDER BY Commit_Date__c DESC, CreatedDate DESC
                        LIMIT 2000
                        OFFSET :oSet
                ]) {
                    commits.add(new ACommit(c, existing.contains(c.Commit_Id__c)));
            }
        }
        return commits;
    }

    public PageReference next(){
        showPrevious = true;
        oSet = oSet + OFFSET_INT;
        commits = getCompletedSnapshotCommits();
        if(oSet == 2000){
            showNext = false;
        }
        return null;
    }

    public PageReference previous(){
        showNext = true;
        oSet = oSet - OFFSET_INT;
        commits = getCompletedSnapshotCommits();
        if(oSet == 0){
            showPrevious = false;
        }
        return null;
    }


    public PageReference saveSelections(){
        List<User_Story_Commit__c> t = new List<User_Story_Commit__c>();
        for(ACommit c:commits){
            if(c.sel){
                t.add(new User_Story_Commit__c(User_Story__c = this.userStoryId, Snapshot_Commit__c = c.c.Id, External_Id__c = this.userStoryId + '_' + c.c.Commit_Id__c));
            }
        }
        Utilities.Secure_DML(t, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story_Commit__c, schema.sObjectType.User_Story_Commit__c.fields.External_Id__c);
        if(String.isNotBlank(this.userStoryId)){
            // known checkmarks security workaround: assign the id to a variable.
            Id newUsId = this.userStoryId;
            return new ApexPages.StandardController(newUsId.getSobjectType().newSObject(newUsId)).view();
        }
        return null;
    }
    public PageReference cancel(){
        if(String.isNotBlank(this.userStoryId)){
            // known checkmarks security workaround: assign the id to a variable.
            Id newUsId = this.userStoryId;
            return new ApexPages.StandardController(newUsId.getSobjectType().newSObject(newUsId)).view();
        }
        return null;
    }
    public class ACommit{
        public Git_Org_Commit__c c{get;set;}
        public boolean sel{get;set;}
        public ACommit(Git_Org_Commit__c c, boolean sel){
            this.c = c;
            this.sel = sel;
        }
    }
}