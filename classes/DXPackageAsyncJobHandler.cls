/**
 * Created by mertyalti on 31/08/2018.
 */

public with sharing class DXPackageAsyncJobHandler {
    private final Map<String, String> messageByJobType= new Map<String, String>{
        DXLabel.CREATE_PACKAGE => Label.DX_Package_created_succesfully ,
        DXLabel.CREATE_PACKAGE_VERSION => Label.DX_Package_version_created_succesfully,
        DXLabel.PROMOTE_BETA_RELEASED => Label.DX_Package_version_promoted_to_released_succesfully,
        DXLabel.PACKAGE_UPDATE => Label.DX_Package_updated_succesfully,
        DXLabel.PACKAGE_VERSION_UPDATE => Label.DX_Package_version_updated_succesfully
    };
    public DXPackageAsyncJobHandler(ApexPages.StandardController controller) {
    }
    public DXPackageAsyncJobHandler() {
    }
    public PageReference jobStatusNotification() {
        Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
        Boolean jobFinished = pageParameters.get('jobFinished') == 'true';

        if(jobFinished) {
            Boolean jobSuccess = pageParameters.get('jobSuccess') == 'true';
            if(jobSuccess) {
                String jobType = pageParameters.get('jobType');
                if(messageByJobType.containsKey(jobType)) {
                    addPageMessage(ApexPages.Severity.CONFIRM, messageByJobType.get(jobType));
                }
            } else {
                String jobMessage = pageParameters.get('jobMessage');
                if(String.isNotBlank(jobMessage)) {
                    addPageMessage(ApexPages.Severity.ERROR, jobMessage);
                }
            }
        }

        String jobParentId = pageParameters.get('jobParentId');
        if(String.isNotBlank(jobParentId)) {
            PageReference thisPage = new PageReference('/' + jobParentId);
            thisPage.setRedirect(true);
            return thisPage;
        }
        return null;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}