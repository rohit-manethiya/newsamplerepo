/**
 * Created by mertyalti on 18/04/2018.
 */

public with sharing class ManageRepositoryBranchesController {
    public String repositoryId {
        get;
        set{
            if(String.isNotBlank(value)){
                repositoryId = value;
            }
        }
    }
    public void refreshBranchCache() {
        if (String.isNotBlank(repositoryId)) SfdxAPI.retrieveBranchesFromRepository(repositoryId);
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == CopadoNotificationHelper.DX_LIST_REPO_BRANCHES) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Branches retrieved successfully.'));
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Completed successfully.'));
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }
}