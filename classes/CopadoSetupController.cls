public with sharing class CopadoSetupController {
    private static final String MODE = 'mode';
    private static final String ID = 'id';
    private static final String USER_STORY = 'User Story';

    private enum PipelineMode { MANAGER, DIAGRAM }

    public Copado_License__c copadoLicense { get; set; }
    public Org__c orgCredentials { get; set; }
    public Git_Backup__c gitSnapshot { get; set; }
    public Deployment_Flow__c deploymentFlow { get; set; }
    public Deployment_Flow_Step__c deploymentFlowStep { get; set; }

    public String selectedGitRepositories { get; set; }
    public String selectedDeploymentFlow { get; set; }
    public String namespace { get; set; }
    private final String C_NONE = 'none';
    private final String C_NONELABEL = '-- None --';

    public Map<Id, Org__c> orgCredentialMap { get; set; }

    public List<Git_Backup__c> gitSnapshotList { get; set; }
    public List<Deployment_Flow_Step__c> deploymentFlowStepList { get; set; }

    public Boolean enableGitSnapshotForm { get; set; }
    public Boolean enableDeploymentFlowForm { get; set; }
    public Boolean enableDeploymentFlowStepForm { get; set; }

    public CopadoSetupController() {
        gitSnapshotList = new List<Git_Backup__c>();
        deploymentFlowStepList = new List<Deployment_Flow_Step__c>();

        orgCredentials = new Org__c();
        deploymentFlow = new Deployment_Flow__c();
        copadoLicense = new Copado_License__c();

        retrieveCopadoLicenses();

        selectedGitRepositories = '';
        selectedDeploymentFlow = '';
        namespace = Settings.ns;

        enableGitSnapshotForm = false;
        enableDeploymentFlowForm = false;
        enableDeploymentFlowStepForm = false;
    }

    // used this SOQL to check current users active licenses. variable listed on visualforce page
    public void retrieveCopadoLicenses() {
        String userName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        for(Copado_License__c cl : Utilities.getCopadoLicenses(userName)) {
            copadoLicense = cl;
            return;
        }
    }

    // inserting org credentials
    public void createOrgCredentials() {
        try {
            Utilities.Secure_DML(orgCredentials, Utilities.DML_Action.INS, Schema.SObjectType.Org__c);//OLS,FLS security issue insert orgCredentials;

            // to create new org credential getting new instance to clear existing values
            orgCredentials = new Org__c();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ERROR_ORG_CREDENTIAL + ' / ' + e.getMessage()));
        }
    }

    // to refresh the org credential list
    public void refreshOrgCredentialList() {
        orgCredentialMap.clear();
    }

    // retrieve all org credentials, returned boolean to render org credential panel on visualforce page
    public Boolean getExistingOrgCredentials() {
        orgCredentialMap = new Map<Id, Org__c>();
        if(Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            orgCredentialMap = new Map<Id, Org__c>([SELECT Id, Name, Org_Type__c, is_Developer_Hub_Org__c, Username__c, Environment__c, Environment__r.Name, Test_Frequency__c FROM Org__c WHERE CreatedById = :UserInfo.getUserId() LIMIT 1000]);
        }
        return !orgCredentialMap.isEmpty() ? false : true;
    }

    // getting git snapshots for selected git repository
    public void getsGitSnapshots() {
        if(selectedGitRepositories == C_NONE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.SELECT_GIT_REPOSITORY_OR_CREATE_ONE));
            return;
        } else {
            // retrieving the git snapshots depend on the selected git repo
            gitSnapshotList = retrieveGitSnapshots(selectedGitRepositories);
        }
    }

    // returns list of the git snapshots depend on the git repo
    public List<Git_Backup__c> retrieveGitSnapshots(Id gitRepoId) {
        List<Git_Backup__c> gitbackupList = new List<Git_Backup__c>();
        if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
            gitbackupList = [SELECT Id, Name, Git_Repository__c, Git_Repository__r.Name, Branch__c, Git_Snapshot_Permissions__c, Frequency__c, Org__c, Org__r.Name FROM Git_Backup__c WHERE Git_Repository__c = :gitRepoId];
        }
        return gitbackupList;
    }

    // filling selectoptions with possible git repositories
    public List<SelectOption> getGitRepos() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(C_NONE, C_NONELABEL));
        if(Schema.SObjectType.Git_Repository__c.isQueryable() && Schema.SObjectType.Git_Repository__c.isAccessible()) {
            for(Git_Repository__c gr : [SELECT Id, Name FROM Git_Repository__c LIMIT 1000]) {
                options.add(new SelectOption(gr.Id, gr.Name));
            }
        }
        return options;
    }

    // used this method to get new instance of git snapshot.
    public void openGitSnapshotForm() {
        gitSnapshot = new Git_Backup__c();
        gitSnapshot.Git_Repository__c = selectedGitRepositories; // to auto populate git repository field of the git snapshot, assigned selected git repository to the git repository field of the git snapshot
        enableGitSnapshotForm = true; // it is used at rendered attribute to show git snapshot input form
    }

    // used this method to close git snapshot form
    public void closeGitSnapshotForm() {
        gitSnapshot = new Git_Backup__c();
        enableGitSnapshotForm = false;
    }

    // inserting git snapshots
    public void createGitSnapshot() {
        try {
            if(gitSnapshot.Name == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.GIT_SNAPSHOT_NAME_REQUIRED));
                return;
            }
            if(gitSnapshot.Branch__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.BRANCH_FIELD_REQUIRED));
                return;
            }
            if(gitSnapshot.Git_Snapshot_Permissions__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.GIT_SNAPSHOT_PERMISSION_FIELD_REQUIRED));
                return;
            }
            if(gitSnapshot.Org__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ORG_CREDENTIAL_FIELD_REQUIRED));
                return;
            }

            Utilities.Secure_DML(gitSnapshot, Utilities.DML_Action.INS, Schema.SObjectType.Git_Backup__c);// OLS, FLS security issue insert gitSnapshot;

            enableGitSnapshotForm = false; // it is used at rendered attribute to show git snapshot input form

            // new value added to git snapshot list. So retrieving the git snapshots depend on the selected git repo
            gitSnapshotList.clear(); // clearing the old values to fill in again
            gitSnapshotList = retrieveGitSnapshots(selectedGitRepositories);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ERROR_GIT_SNAPSHOT + ' / ' + e.getMessage()));
        }

    }

    // filling selectoptions with possible deployment flows
    public List<SelectOption> getDeploymentFlows() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(C_NONE, C_NONELABEL));
        if(Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            for(Deployment_Flow__c df : [SELECT Id, Name, Active__c FROM Deployment_Flow__c LIMIT 1000]) {
                options.add(new SelectOption(df.Id, df.Active__c ? df.Name + ' {Active}' : df.Name));
            }
        }
        return options;
    }

    // getting new instance for deployment flow
    public void openDeploymentFlowForm() {
        enableDeploymentFlowForm = true;
        deploymentFlow = new Deployment_Flow__c();
        selectedDeploymentFlow = '';
    }

    // closing new deployment flow form
    public void closeDeploymentFlowForm() {
        enableDeploymentFlowForm = false;
        deploymentFlow = new Deployment_Flow__c();
    }

    // to create new git repositories getting new instance to clear existing values
    public void getsDeploymentFlowSteps() {
        if(selectedDeploymentFlow == C_NONE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.SELECT_DEPLOYMENT_FLOW_OR_CREATE_ONE));
            return;
        } else {
            // retrieving the deployment flow steps depend on the selected deployment flow
            deploymentFlowStepList = retrieveDeploymentFlowSteps(selectedDeploymentFlow);
        }
    }

    /**
     * Redirects page to Pipeline Manager / Diagram or old BranchManagement page depending on pipeline calculated based on.
     */
    public PageReference manageReleases() {
        PageReference pReference;
        try {
            List<Deployment_Flow__c> selectedPipeline = [SELECT Id, Active__c, Calculate_Based_on__c FROM Deployment_Flow__c WHERE Id = :selectedDeploymentFlow WITH SECURITY_ENFORCED LIMIT 1];
            if(!selectedPipeline.isEmpty()) {
                if(selectedPipeline[0].Calculate_Based_on__c == USER_STORY) {
                    String pipelineMode = selectedPipeline[0].Active__c ? PipelineMode.MANAGER.name().toLowerCase() : PipelineMode.DIAGRAM.name().toLowerCase();
                    pReference = Page.PipelineManager;
                    pReference.getParameters().put(MODE, pipelineMode);
                } else {
                    pReference = Page.BranchManagement;
                }
                pReference.getParameters().put(ID, selectedDeploymentFlow);
                pReference.setRedirect(true);
            }
        } catch(System.QueryException exceptions) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment_Flow__c.getLabel()));
        }
        return pReference;
    }

    // returns list of the git snapshots depend on the git repo
    public List<Deployment_Flow_Step__c> retrieveDeploymentFlowSteps(Id deploymentFlowId) {
        List<Deployment_Flow_Step__c> deploymentFlowList = new List<Deployment_Flow_Step__c>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            deploymentFlowList = [SELECT Id, Name, Deployment_Flow__c, Destination_Environment__c, Destination_Environment__r.Name, Source_Environment__c, Source_Environment__r.Name, Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :deploymentFlowId];
        }
        return deploymentFlowList;
    }

    // inserting deployment flow
    public void createDeploymentFlow() {
        try {
            if(deploymentFlow.Name == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.DEPLOYMENT_FLOW_NAME_REQUIRED));
                return;
            }

            Utilities.Secure_DML(deploymentFlow, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow__c);// OLS, FLS security issue insert deploymentFlow;

            // assigning new git repo id to the selectedGitRepositories variable to render page correctly
            selectedDeploymentFlow = deploymentFlow.Id;

            // new deployment flow is created. deployment flow step list should be cleared.
            deploymentFlowStepList.clear();

            // to close the deployment flow creation form
            enableDeploymentFlowForm = false;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ERROR_DEPLOYMENT_FLOW + ' / ' + e.getMessage()));
        }
    }

    // used this method to get new instance of deployment flow step.
    public void openDeploymentFlowStepForm() {
        deploymentFlowStep = new Deployment_Flow_Step__c();
        deploymentFlowStep.Deployment_Flow__c = selectedDeploymentFlow; // to auto populate deployment flow field of the deployment flow step, assigned selected deployment flow to the deployment flow field of the deployment flow step
        enableDeploymentFlowStepForm = true; // it is used at rendered attribute to show deployment flow step input form
    }

    // closing new deployment flow step form
    public void closeDeploymentFlowStepsForm() {
        enableDeploymentFlowStepForm = false;
        deploymentFlowStep = new Deployment_Flow_Step__c();
    }

    // inserting deployment flow steps
    public void createDeploymentFlowSteps() {
        try {
            Utilities.Secure_DML(deploymentFlowStep, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Flow_Step__c);// OLS, FLS security issue insert deploymentFlowStep;

            enableDeploymentFlowStepForm = false; // it is used at rendered attribute to show deployment flow step input form

            // new value added to deployment flow step list. So retrieving the deployment flow steps depend on the selected deployment flow
            deploymentFlowStepList.clear(); // clearing the old values to fill in again
            deploymentFlowStepList = retrieveDeploymentFlowSteps(selectedDeploymentFlow);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ERROR_DEPLOYMENT_FLOW_STEP + ' / ' + e.getMessage()));
        }
    }

    // used this method to set oauth authenticate
    public PageReference doOauth() {
        String orgCredentialId = ApexPages.currentPage().getParameters().get('setOauth');
        return String.isNotBlank(orgCredentialId) ? Utilities.doOauth(orgCredentialMap.get(orgCredentialId)) : null;
    }

    // used this global api method to retrieve API key for current user
    public String getAPIKey() {
        return DeployAPI.getUserAPIKey();
    }
}