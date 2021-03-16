/**
 * Created by mertyalti on 07/03/2018.
 */

public with sharing class ArtifactPackageController {
    private final Artifact__c artifact { get; set; }
    public String pw { get; set; }
    private AbstractDXOrg dxOrgService;

    public ArtifactPackageController(ApexPages.StandardController stdController) {
        artifact = (Artifact__c) stdController.getRecord();
        dxOrgService = DXOrgFactory.getInstance('ScratchOrgService');
        dxOrgService.setOrgId(artifact.Org_Credential__c);
    }
    
    public PageReference refreshPackageList() {
        ((ScratchOrgService)dxOrgService).getListOfPackages();
        return null;
    }

    public PageReference encryptPassword() {
        String pwFromPage = ApexPages.currentPage().getParameters().get('pass');
        if(String.isNotBlank(pwFromPage)){
            pw = DeployAPI.encryptAPIKey(pwFromPage);
        }
        return null;
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == DXLabel.CREATE_ORG) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }
}