public class GitHelper {
    public static Map<String,ACommit>  commitMap = new Map<String,ACommit>();
    
    public static List<ACommit> getCommits(String repositoryId, String branch, Date fromDate, Date toDate, String startCommit, String endCommit, Integer lim) {
        commitMap = new Map<String,ACommit>();
        List<ACommit> aCommitList = new List<ACommit>();
        List<Git_Org_Commit__c> gitOrgCommitList = new List<Git_Org_Commit__c>();
        
        if(Schema.SObjectType.Git_Org_Commit__c.isQueryable() && Schema.SObjectType.Git_Org_Commit__c.isAccessible()) {
            List<Git_Org_Commit__c> tempGitOrgCommitList = [SELECT Commit_Id__c, Commit_Date__c, Commit_Message__c, Git_Backup__r.Branch__c FROM Git_Org_Commit__c WHERE Git_Backup__r.Git_Repository__c = :repositoryId AND Commit_Date__c >= :fromDate AND Commit_Date__c <= :toDate AND Status__c = 'Complete' ORDER BY Commit_Date__c DESC, CreatedDate DESC LIMIT :lim];

            for(Git_Org_Commit__c gitOrgCommit : tempGitOrgCommitList) {
                // if branch is not empty and gitOrgCommit.Git_Backup__r.Branch__c not equal to this it will enter the else, but in this case it should do nothing
                if(String.isNotBlank(branch)) {
                    if(gitOrgCommit.Git_Backup__r.Branch__c == branch) {
                        gitOrgCommitList.add(gitOrgCommit); 
                    }
                } else {
                    gitOrgCommitList.add(gitOrgCommit); 
                }
            }
        }

        for(Git_Org_Commit__c gitOrgCommit : gitOrgCommitList) {
			//add commit without dupes
			if(!commitMap.containsKey(gitOrgCommit.Commit_Id__c)) {
                ACommit aCommitItem = new ACommit(gitOrgCommit.Commit_Id__c,gitOrgCommit.Commit_Message__c,gitOrgCommit.Commit_Date__c, gitOrgCommit.Git_Backup__r.Branch__c);
				commitMap.put(gitOrgCommit.Commit_Id__c,aCommitItem);
                aCommitList.add(aCommitItem);
            } 
        }

        List<Git_Commit__c> gitCommitList = new List<Git_Commit__c>();
        if(Schema.SObjectType.Git_Commit__c.isQueryable() && Schema.SObjectType.Git_Commit__c.isAccessible()) {
            List<Git_Commit__c> tempGitCommitList = [SELECT Commit_Id__c, Commit_Date__c, Commit_Message__c, Branch__c FROM Git_Commit__c WHERE Git_Repository__c = :repositoryId AND Commit_Date__c >= :fromDate AND Commit_Date__c <= :toDate ORDER BY Commit_Date__c DESC, CreatedDate DESC LIMIT :lim];

            for(Git_Commit__c gitCommit : tempGitCommitList) {
                if(String.isNotBlank(branch)) {
                    if(gitCommit.Branch__c == branch) {
                        gitCommitList.add(gitCommit); 
                    }
                } else {
                    gitCommitList.add(gitCommit); 
                }
            }
        }

        for(Git_Commit__c gitCommit : gitCommitList) {
			//add commit without dupes
			if(!commitMap.containsKey(gitCommit.Commit_Id__c)) {
                ACommit aCommitItem = new ACommit(gitCommit.Commit_Id__c,gitCommit.Commit_Message__c,gitCommit.Commit_Date__c, gitCommit.Branch__c);
				commitMap.put(gitCommit.Commit_Id__c, aCommitItem);
                aCommitList.add(aCommitItem);
            }
        }

        aCommitList.sort();
        if(String.isNotBlank(startCommit) && String.isBlank(endCommit)) {
            List<ACommit> tempACommitList = new List<ACommit>();
            for(ACommit aCommitItem : aCommitList) {
                tempACommitList.add(aCommitItem);
                if(aCommitItem.id == startCommit) {
                    break;
                }
            }
            aCommitList = tempACommitList;
        }
        return aCommitList;
    }
    
    public class ACommit implements Comparable {
        public String id { get; set; }
        public String message { get; set; }
        public DateTime cdate { get; set; }
        public String branch { get; set; }

        public ACommit(String id, String message, DateTime cdate, String branch) {
            this.id = id;
            this.message = message;
            this.cdate = cdate;
            this.branch = branch;
        }

        public Integer compareTo(Object obj) {
            ACommit aCommitItem = (ACommit)obj;
            if(aCommitItem.cdate > this.cdate) {
                return 1;
            }
            if(aCommitItem.cdate < this.cdate) {
                return -1;
            }
            return 0;
        }
    }
}