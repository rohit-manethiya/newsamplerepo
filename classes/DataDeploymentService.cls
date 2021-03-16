/**
 * This is main controller for Data deployment type which implements DeploymentInterface
 *
 * @see DeploymentInterface
 */
public with sharing class DataDeploymentService implements DeploymentInterface {
    private final String C_ID = 'id';
    private final String C_APEX = '/apex/';

    /**
     * This is order of the possible steps for Metadata Deployment Wizard
     * They are same as page names, in each step we will compare and find the order number
     *
     * NOTE: if you change the page label, you should update this code as well
     */
    private enum PossibleWizardSteps {
        DW_Source,
        DW_Target,
        DW_SelectDataTemplate,
        DW_OverrideFilters,
        DW_Overview,
        DW_Deployment,
        DW_Summary
    }

    private Map<String, String> stepsPageNameToLabelMap = new Map<String, String>{
        'DW_Source' => 'Source',
        'DW_Target' => 'Target',
        'DW_SelectDataTemplate' => 'Data Template',
        'DW_OverrideFilters' => 'Filter Specification',
        'DW_Overview' => 'Overview',
        'DW_Deployment' => 'Deployment',
        'DW_Summary' => 'Summary'
    };

    public DataDeploymentService() {
        // singleton
    }

    public DeploymentInterface getInstance() {
        return new DataDeploymentService();
    }

    /**
     * It is used to return enum values to the controller to define which steps to be shown at deployment wizard
     *
     * @return
     */
    public List<String> returnAvailableSteps() {
        List<String> stepsList = new List<String>();
        for (PossibleWizardSteps pws : PossibleWizardSteps.values()) {
            if (stepsPageNameToLabelMap.containsKey(pws.name())) {
                stepsList.add(stepsPageNameToLabelMap.get(pws.name()));
            }
        }
        return stepsList;
    }

    /**
     * It is used to return enum values to the controller to define which steps to be shown at deployment wizard
     *
     * @return
     */
    public List<String> returnAvailablePages() {
        List<String> pagesList = new List<String>();
        for (PossibleWizardSteps pws : PossibleWizardSteps.values()) {
            pagesList.add(pws.name());
        }
        return pagesList;
    }

    /**
     * It is used to define which steps to open at first load by checking selected deployment type or Deployment record
     *
     * @return one of the PossibleWizardSteps value
     */
    public PageReference goToNextStep(Deployment__c deployment, String deploymentActionType) {
        PageReference pReference;
        if (deployment.Id != null) {
            Integer currentComponentOrder = 0;
            for (PossibleWizardSteps pws : PossibleWizardSteps.values()) {
                if (deployment.Deployment_Last_Step__c != null && deployment.Deployment_Last_Step__c.containsIgnoreCase(String.valueOf(pws))) {
                    currentComponentOrder = pws.ordinal();
                    break;
                }
            }
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[currentComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + C_APEX + Settings.ns + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);

            // This is after overview to pass if deployment type is validation or deployment
            if (String.isNotBlank(deploymentActionType)) {
                pReference.getParameters().put('deploymentActionType', deploymentActionType);
            }
        } else {
            pReference = Page.DW_Source;
        }
        pReference.setRedirect(true);
        return pReference;
    }

    /**
     * It is used to define which steps to open when user click on "Back" button
     *
     * @return one of the PossibleWizardSteps value
     */
    public PageReference goToPreviousStep(Deployment__c deployment) {
        PageReference pReference;
        if (deployment.Id != null) {
            Integer currentComponentOrder = 0;
            String currentURL = ApexPages.currentPage().getUrl();
            for (PossibleWizardSteps pws : PossibleWizardSteps.values()) {
                if (String.isNotBlank(currentURL) && currentURL.containsIgnoreCase(String.valueOf(pws))) {
                    currentComponentOrder = pws.ordinal();
                    break;
                }
            }
            // Checking the total page size for wizard to avoid error for last step
            Integer order = currentComponentOrder - 1;
            Integer validComponentOrder = (order < 0) ? (order + 1) : order;
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[validComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + C_APEX + Settings.ns + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);

            pReference.setRedirect(true);
            return pReference;
        } else {
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            return new PageReference(url);
        }
    }

    /**
     * This method is used to find next component order by using given existing component name
     * Before redirect to next page, we have to update custom setting "Last_Step__c" field with new component name, so other parameters are null
     *
     * @param valueToCheck existing component name for current step
     *
     * @return order number of the next component in SetupPipelineOrder enum
     */
    public Integer getComponentIndex(String valueToCheck) {
        Integer currentComponentOrder = 0;
        for (PossibleWizardSteps pws : PossibleWizardSteps.values()) {
            if (String.isNotBlank(valueToCheck) && valueToCheck.containsIgnoreCase(String.valueOf(pws))) {
                currentComponentOrder = pws.ordinal();
            }
        }
        return currentComponentOrder;
    }

    /**
     * It is used to return source type list for Source step of wizard
     *
     * @return
     */
    public List<String> getSourceTypeList() {
        return new List<String>{ 'org' };
    }

    /**
     * It is used to return general step header
     *
     * @return
     */
    public String getStepGeneralHeader() {
        return Label.New_Data_Deployment;
    }

    public class DataDeploymentServiceException extends Exception {
    }
}