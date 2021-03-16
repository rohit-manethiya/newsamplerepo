/**
 * This is the controller for SetupWizardFinish page
 */
public with sharing class SetupWizardFinishController extends WizardHelper {

    /**
     * This method is used to redirect user to the pipeline diagram
     * @see gotoPipelineDiagram
     * @return
     */
    public PageReference enjoyCopado() {
        String pipelineId = ApexPages.currentPage().getParameters().get(PIPELINE_ID);
        if(String.isNotBlank(setupWizardSettings.Pipeline_Id__c)) {
            return gotoPipelineDiagram(setupWizardSettings.Pipeline_Id__c);
        } else if(String.isNotBlank(pipelineId)) {
            return gotoPipelineDiagram(pipelineId);
        } else {
            if(Schema.SObjectType.Deployment_Flow__c.isAccessible() && Schema.SObjectType.Deployment_Flow__c.isQueryable()) {
                List<Deployment_Flow__c> deploymentFlows = new List<Deployment_Flow__c>([
                        SELECT Id
                        FROM Deployment_Flow__c
                        WHERE Main_Branch__c != NULL
                ]);
                if(!deploymentFlows.isEmpty()) {
                    return gotoPipelineDiagram(deploymentFlows[0].Id);
                } else {
                    String homepageUrl = UserInfo.getUiThemeDisplayed().startsWithIgnoreCase('Theme4') ? '/one/one.app' : '/home/home.jsp';
                    PageReference retPage = new PageReference(homepageUrl);
                    retPage.setRedirect(true);
                    return retPage;
                }
            } else {
                handleError(Label.INSUFFICENT_ACCESS, new List<String>{
                        Label.Insufficient_Access_Rights, Label.OBJECT_NAME + Schema.SObjectType.Deployment_Flow__c.label
                }, '');
                return null;
            }

        }
    }
    /**
     * Redirection to the pipeline diagram
     *
     * @param pipelineId
     * @return Page.PipelineDiagram
     */
    private PageReference gotoPipelineDiagram(String pipelineId) {
        PageReference pipelineSetup = Page.PipelineManager;
        pipelineSetup.getParameters().put('Id', pipelineId);
        pipelineSetup.getParameters().put('mode', 'diagram');
        pipelineSetup.setRedirect(true);

        if(setupWizardSettings != null) {
            try {
                Utilities.Secure_DML(setupWizardSettings, Utilities.DML_Action.DEL, Schema.SObjectType.Setup_Wizard_Steps__c);
            } catch(Exception excp) {
                System.debug('User deleted by hand... Bypass exception...');
            }
        }
        return pipelineSetup;
    }
}