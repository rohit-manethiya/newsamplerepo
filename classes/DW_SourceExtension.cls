/**
 * It is main controller for DW_Summary page
 */
public with sharing class DW_SourceExtension extends DeploymentHelper {
    // Non Constants
    public String selectedSourceType { get; set; }
    public List<SourceTypesWrapper> sourceTypeList { get; set; }
    public List<String> possibleSourceTypesList { get; set; }
    @TestVisible
    private List<Step__c> stepList;

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_SourceExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        selectedSourceType = String.isNotBlank(deployment.Deployment_Source_Type__c) ? deployment.Deployment_Source_Type__c : '';
        // if record type is data, selected source type should be org
        selectedSourceType = (String.isNotBlank(selectedSourceType) &&
            String.isNotBlank(deployment.RecordTypeId) &&
            deployment.RecordTypeId == dataDeploymentRecordTypeId)
            ? ORG
            : '';
        // if source org is selected while creating the deployment, selected source type should be org
        selectedSourceType = (String.isNotBlank(selectedSourceType) && String.isNotBlank(deployment.From_Org__c)) ? ORG : '';
        initializeServiceClasses();
        populatePossibleSourceTypes();
        if (String.isNotBlank(deployment.Id) && String.isNotBlank(selectedSourceType)) {
            populateNecessaryData();
        }
        populateStepsList();
        populatePagesList();
    }

    /**
     * It is used to populate wrapper list to repeat at DW_Source page
     */
    private void populatePossibleSourceTypes() {
        sourceTypeList = new List<SourceTypesWrapper>();
        possibleSourceTypesList = deploymentInterface.getSourceTypeList();
        if (!possibleSourceTypesList.isEmpty() && possibleSourceTypesList.size() == 1) {
            selectedSourceType = ORG;
            populateNecessaryData();
        }
        sourceTypeList.add(new SourceTypesWrapper('Salesforce Org', ORG, 'cloud.png'));
        sourceTypeList.add(new SourceTypesWrapper('Git', GIT, 'git.png'));
    }

    /**
     * It is used to populate org credential or git org commit records
     */
    public void populateNecessaryData() {
        pageMessagesMap.clear();
        if (String.isNotBlank(selectedSourceType)) {
            sourceList = new List<SourceWrapper>();
            if (selectedSourceType == ORG) {
                for (Org__c org : getLastViewedOrgs()) {
                    Boolean alreadySelected = deployment.From_Org__c != null && deployment.From_Org__c == org.Id;
                    sourceList.add(new SourceWrapper(alreadySelected, org, '', '', '', '', '', '', null, null));
                }
            } else {
                List<Step__c> gitStep = new List<Step__c>();
                if (Schema.SObjectType.Step__c.isAccessible() && Schema.SObjectType.Step__c.isQueryable()) {
                    gitStep = new List<Step__c>([SELECT Id, Commit_Id__c FROM Step__c WHERE Deployment__c = :deployment.Id LIMIT 1]);
                } else {
                    pageMessagesMap.put(
                        C_WARNING,
                        new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Step__c.getLabel() }
                    );
                    return;
                }
                for (Git_Commit__c gc : getGitCommits()) {
                    Boolean alreadySelectedGc = gitStep.size() > 0
                        ? (gitStep[0].Commit_Id__c != null && gitStep[0].Commit_Id__c == gc.Commit_Id__c)
                        : false;
                    sourceList.add(
                        new SourceWrapper(
                            alreadySelectedGc,
                            null,
                            gc.Name,
                            gc.Commit_Id__c,
                            gc.Commit_Message__c,
                            gc.Branch__c,
                            gc.Git_Repository__c,
                            gc.Git_Repository__r.Name,
                            gc.Commit_Date__c.format(),
                            null
                        )
                    );
                }
                for (Git_Org_Commit__c goc : getGitOrgCommits()) {
                    Boolean alreadySelectedGoc = gitStep.size() > 0
                        ? (gitStep[0].Commit_Id__c != null && gitStep[0].Commit_Id__c == goc.Commit_Id__c)
                        : false;
                    sourceList.add(
                        new SourceWrapper(
                            alreadySelectedGoc,
                            null,
                            goc.Name,
                            goc.Commit_Id__c,
                            goc.Commit_Message__c,
                            goc.Git_Backup__r.Branch__c,
                            goc.Git_Backup__r.Git_Repository__c,
                            goc.Git_Backup__r.Git_Repository__r.Name,
                            Date.valueOf(goc.Commit_Date__c).format(),
                            null
                        )
                    );
                }
            }
            sourceList.sort();
            deployment.Deployment_Source_Type__c = selectedSourceType;
        }
    }

    /**
     * It is used to populate git commit records based on last commit date
     *
     * @return
     */
    private List<Git_Commit__c> getGitCommits() {
        List<Git_Commit__c> gitCommitList = new List<Git_Commit__c>();
        if (Schema.SObjectType.Git_Commit__c.isAccessible() && Schema.SObjectType.Git_Commit__c.isQueryable()) {
            return gitCommitList = [
                SELECT Id, Name, Commit_Message__c, Commit_Id__c, Git_Repository__c, Git_Repository__r.Name, Commit_Date__c, Branch__c
                FROM Git_Commit__c
                WHERE Commit_Id__c != null AND Commit_Date__c != null
                ORDER BY Commit_Date__c DESC
                LIMIT 500
            ];
        } else {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Git_Commit__c.getLabel() }
            );
            return null;
        }
    }

    /**
     * It is used to populate git org commit records based on last commit date
     *
     * @return
     */
    private List<Git_Org_Commit__c> getGitOrgCommits() {
        List<Git_Org_Commit__c> gitOrgCommitList = new List<Git_Org_Commit__c>();
        if (Schema.SObjectType.Git_Org_Commit__c.isAccessible() && Schema.SObjectType.Git_Org_Commit__c.isQueryable()) {
            return gitOrgCommitList = [
                SELECT
                    Id,
                    Name,
                    Commit_Message__c,
                    Commit_Id__c,
                    Git_Backup__r.Git_Repository__c,
                    Git_Backup__r.Git_Repository__r.Name,
                    Commit_Date__c,
                    Git_Backup__r.Branch__c
                FROM Git_Org_Commit__c
                WHERE Commit_Id__c != null AND Commit_Date__c != null AND Status__c = 'Complete'
                ORDER BY Commit_Date__c DESC
                LIMIT 500
            ];
        } else {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Git_Org_Commit__c.getLabel() }
            );
            return null;
        }
    }

    /**
     * It is used to populate Source Org Credential record before upsert deployment for salesforce org selection
     * It is used to create a Step record to deployment for git commit selection
     */
    public void configureSource() {
        // setup the save point for rollback
        Savepoint sp;
        if (!Test.isRunningTest()) {
            sp = Database.setSavepoint();
        }
        stepList = new List<Step__c>();
        pageMessagesMap.clear();
        String action = ApexPages.currentPage().getParameters().get('buttonAction');
        String selection = ApexPages.currentPage().getParameters().get('selection');
        Boolean goToNextStep = String.isNotBlank(action) && action == 'nextStep';

        try {
            if (goToNextStep && deployment.Name == null) {
                pageMessagesMap.put(C_WARNING, new List<Object>{ Label.Give_Your_Deployment_a_Name });
                return;
            }
            if (deployment.Name != null) {
                // deployment Id is required for Step so upsert deployment before step creation
                if (selectedSourceType == GIT) {
                    upsertDeployment(goToNextStep);
                }

                SourceWrapper tempSw;
                for (SourceWrapper sw : sourceList) {
                    if (sw.commitName == selection) {
                        tempSw = sw;
                    }
                    if (sw.isSelected) {
                        if (selectedSourceType == ORG) {
                            deployment.From_Org__c = sw.orgRecord.Id;
                        } else if (selectedSourceType == GIT) {
                            Step__c step = stepFactory(sw);
                            stepList.add(step);
                        }
                        break;
                    }
                }
                // START---additional control for selection for selection is not on the current page
                if (goToNextStep && (selectedSourceType == ORG && deployment.From_Org__c == null) && !String.isEmpty(selection)) {
                    deployment.From_Org__c = selection;
                }

                if (selectedSourceType == GIT && stepList.isEmpty() && null != tempSw) {
                    Step__c step = stepFactory(tempSw);
                    stepList.add(step);
                }
                // END---additional control for selection for selection is not on the current page

                if (selectedSourceType == GIT && !stepList.isEmpty()) {
                    Utilities.Secure_DML(stepList, Utilities.DML_Action.INS, schema.SObjectType.Step__c);
                }

                if (
                    goToNextStep &&
                    ((selectedSourceType == ORG && deployment.From_Org__c == null) || (selectedSourceType == GIT && stepList.isEmpty()))
                ) {
                    pageMessagesMap.put(C_WARNING, new List<Object>{ Label.WorkManager_Alert_NoRecord });
                    return;
                }

                // deployment from org is populated for org type, so upsert deployment
                if (selectedSourceType == ORG) {
                    upsertDeployment(goToNextStep);
                }
            }
        } catch (Exception excp) {
            // roll everything back in case of error
            Database.rollback(sp);
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    /**
     * It is used to create step
     *
     * @return
     */
    private Step__c stepFactory(SourceWrapper sw) {
        Step__c step = new Step__c();
        step.Deployment__c = deployment.Id;
        step.Name = STEP_ONE;
        step.Type__c = GIT_METADATA;
        step.Status__c = NOT_STARTED;
        step.Order__c = 1;
        step.Commit_Id__c = sw.commitId;
        step.Branch__c = sw.branchName;
        step.Git_Repository__c = sw.gitRepository;
        step.Commit_Name__c = sw.commitName;

        return step;
    }

    /**
     * It is used to populate source type values
     */
    public class SourceTypesWrapper {
        public String sourceTypeLabel { get; set; }
        public String sourceType { get; set; }
        public String imageName { get; set; }

        public SourceTypesWrapper(String sTypeLabel, String sType, String iName) {
            this.sourceTypeLabel = sTypeLabel;
            this.sourceType = sType;
            this.imageName = iName;
        }
    }
}