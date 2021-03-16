/**
 * Created by mertyalti on 12/09/2018.
 */

public with sharing class DXExtensionStatusController extends ScratchOrgWizardComponentBase {
    public List<Deployment__c> scratchOrgExtensions { get; set; }
    public Boolean enabledRebasePromotionPoller { get; set; }

    public DXExtensionStatusController() {
        enabledRebasePromotionPoller = true;
        scratchOrgExtensions = new List<Deployment__c>();
        resetDeploymentInfoList();
        scratchOrgExtensions = getDeployments();
        enabledRebasePromotionPoller = scratchOrgExtensions.isEmpty();
    }

    public PageReference checkExtensionStatuses() {
        ScratchOrgExtensionsController extensionsController = (ScratchOrgExtensionsController) getPageController().getComponentController('ScratchOrgExtensions');
        if(getDeploymentInfoList().isEmpty() && !extensionsController.getDeploymentInfoList().isEmpty()) {
            setDeploymentInfoList(extensionsController.getDeploymentInfoList());
        }
        scratchOrgExtensions = getDeployments();
        Integer incompleteCount = 0;
        for(Deployment__c dep : scratchOrgExtensions) {
            if(dep.Status__c != 'Completed' || dep.Status__c != 'Completed with errors') {
                incompleteCount++;
                break;
            }
        }
        enabledRebasePromotionPoller = incompleteCount > 0;
        return null;
    }

    private List<Deployment__c> getDeployments() {
        Set<Id> deploymentIds = getDeploymentIdsFromDeploymentInformationList();
        if(!deploymentIds.isEmpty()) {
            return new List<Deployment__c>([SELECT Name, Status__c, From_Org__c,Deployed__c FROM Deployment__c WHERE Id IN :deploymentIds]);
        }
        return new List<Deployment__c>();
    }
}