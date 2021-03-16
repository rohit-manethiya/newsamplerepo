/**
 * This is the controller for PipelineTemplate component
 * Based on selected template system will create necessary records (given below) and go to next step by updating
 * "Last_Step__c" field
 * Updates deployment flow(pipeline) for storing selected template's coordinates
 * Creates deployment flow steps(pipeline steps) corresponding to selected template
 * @see WizardHelper
 */
public with sharing class PipelineTemplateComponentController extends WizardHelper {
    public String currentType { get; set; } // Stores currently selected template type
    public String selectionsJSON { get; set; } //Selected template JSON
    @TestVisible private final String basicJson; // Basic template json file to store step connections and branch
    @TestVisible private final String standardJson; // Standard template json file to store step connections and branch
    @TestVisible private final String advanceJson;// Advance template json file to store step connections and branch

    /**
     * Constructor
     * Initializes type Json's and cooardinates map
     */
    public PipelineTemplateComponentController() {
        if(String.isBlank(setupWizardSettings.Pipeline_Id__c)) {
            handleError(Label.Pipeline_Pipeline_Needed_To_Continue, new List<String>{
                    Label.Pipeline_Pipeline_Needed_To_Continue_Fix
            }, 'previousPage');
            return;
        } else {
            if(Schema.SObjectType.Deployment_Flow__c.isAccessible() && Schema.SObjectType.Deployment_Flow__c.isQueryable()) {
                List<Deployment_Flow__c> deploymentFlows = [SELECT Id FROM Deployment_Flow__c WHERE Id = :setupWizardSettings.Pipeline_Id__c];
                if(deploymentFlows.isEmpty()) {
                    handleError(Label.Pipeline_Pipeline_Needed_To_Continue, new List<String>{
                            Label.Pipeline_Pipeline_Needed_To_Continue_Fix
                    }, 'previousPage');
                    return;
                }
            } else {
                handleError(Label.INSUFFICENT_ACCESS, new List<String>{
                        Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + SObjectType.Deployment_Flow__c.label
                }, '');
                return;
            }

        }
        // Type JSON files

        basicJson = '{"staging":"master","dev1":"staging","dev2":"staging"}';
        standardJson = '{"staging":"master","integration":"staging","dev1":"integration","dev2":"integration"}';
        advanceJson = '{"staging":"master","qa":"staging","integration":"qa","dev1":"integration","dev2":"integration"}';

        currentType = 'STANDARD';
        selectionsJSON = standardJson;
    }

    /**
     * Creates deployment flow steps
     * Updates the "Last_Step__c" value of the custom setting, next step will be "OrgAuthentication" component
     * @return OrgAuthenticationWizard page
     */
    public PageReference selectTemplate() {
        Map<String, String> selections = (Map<String, String>) JSON.deserialize(selectionsJSON, Map<String, String>.class);
        Boolean goNextPage = createFlowSteps(selections);
        return goNextPage ? goToNextComponent() : null;
    }

    /**
     * Used in the component for reading current selected template type and passing it to controller
     * Dummy method.
     * @return null
     */
    public PageReference processSelectedTemplateType() {
        if(currentType == 'BASIC') {
            selectionsJSON = basicJson;
        } else if(currentType == 'STANDARD') {
            selectionsJSON = standardJson;
        } else if(currentType == 'ADVANCED') {
            selectionsJSON = advanceJson;
        } else {
            handleError(Label.Pipeline_Unexpected_Template_Type, new List<String>{
                    Label.Pipeline_Unexpected_Template_Type_Explanation
            }, 'previousPage');
        }
        System.debug(selectionsJSON);
        return null;
    }

    public PageReference skipTemplates() {
        Deployment_Flow_Step__c step = new Deployment_Flow_Step__c();
        step.Branch__c = '';
        step.Destination_Branch__c = 'master';
        step.Deployment_Flow__c = setupWizardSettings.Pipeline_Id__c;
        Utilities.Secure_DML(step, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);

        return goToNextComponent();
    }

    /**
     * Data operations
     * Creates flow steps and updates coordinates in the flow
     * @see WizardHelper.handleError
     * @param selections
     */
    private Boolean createFlowSteps(Map<String, String> selections) {
        List<Deployment_Flow_Step__c> steps = new List<Deployment_Flow_Step__c>();
        for(String fromBranch : selections.keySet()) {
            Deployment_Flow_Step__c temp = new Deployment_Flow_Step__c();
            temp.Branch__c = fromBranch;
            temp.Destination_Branch__c = selections.get(fromBranch);
            temp.Deployment_Flow__c = setupWizardSettings.Pipeline_Id__c;
            steps.add(temp);
        }

        Deployment_Flow__c currentFlow = new Deployment_Flow__c(
                Id = setupWizardSettings.Pipeline_Id__c
        );

        if(!steps.isEmpty()) {
            try {
                Utilities.Secure_DML(steps, Utilities.DML_Action.INS, schema.SObjectType.Deployment_Flow_Step__c);
            } catch(Exception excp) {
                handleException(excp);
                return false;
            }

            try {
                Utilities.Secure_DML(currentFlow, Utilities.DML_Action.UPD, schema.SObjectType.Deployment_Flow__c);
            } catch(Exception excp) {
                handleException(excp);
                return false;
            }
        }
        return true;
    }
}