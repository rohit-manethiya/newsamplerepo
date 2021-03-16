public with sharing class BranchManagementExt {
    Deployment_Flow__c deploymentflow;

    public BranchManagementExt(ApexPages.StandardController stdController) {
        this.deploymentflow = (Deployment_Flow__c)stdController.getRecord();
    }

    // return multiple keys.
    public String jobsManagerMatchingKeys {
        get {
            Deployment_Flow__c flow = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c WHERE Id = :deploymentflow.Id];
            Map<Id,String> branchesPerEnv = PromoteChangesExtension.getEnvsAndBranchesOfDeploymentFlow(flow.Id);
            String m = '';
            for(String branch : branchesPerEnv.values() )
                m += ';GIT-'+flow.Git_Repository__c+'-'+branch;
            return m.replaceFirst(';','');
        }
        set;
    }
}