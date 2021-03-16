/**
 * This is main controller for Metadata deployment type which implements DeploymentInterface
 *
 * @see DeploymentInterface
 */
public with sharing class MetadataDeploymentService implements DeploymentInterface {
    private String namespace = Settings.ns;
    private final String C_ID = 'id';
    private final String METADATA_PRESELECTION_ID = 'MetadataPreselectionId';
    private final String METADATA = 'MetaData';

    /**
     * This is order of the possible steps for Metadata Deployment Wizard
     * They are same as page names, in each step we will compare and find the order number
     *
     * NOTE: if you change the page label, you should update this code as well
     */
    private enum PossibleWizardSteps {
        DW_Source,
        DW_Target,
        DW_SelectChanges,
        DW_Overview,
        DW_Deployment,
        DW_Summary
    }

    private Map<String, String> stepsPageNameByLabel = new Map<String, String>{
        'DW_Source' => 'Source',
        'DW_Target' => 'Target',
        'DW_SelectChanges' => 'Select & Compare',
        'DW_Overview' => 'Overview',
        'DW_Deployment' => 'Deployment',
        'DW_Summary' => 'Summary'
    };

    public MetadataDeploymentService() {
        // singleton
    }

    public DeploymentInterface getInstance() {
        return new MetadataDeploymentService();
    }

    /**
     * It is used to return enum values to the controller to define which steps to be shown at deployment wizard
     *
     * @return
     */
    public List<String> returnAvailableSteps() {
        List<String> steps = new List<String>();
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            if (stepsPageNameByLabel.containsKey(possibleWizardStepItem.name())) {
                steps.add(stepsPageNameByLabel.get(possibleWizardStepItem.name()));
            }
        }
        return steps;
    }

    /**
     * It is used to return enum values to the controller to define which steps to be shown at deployment wizard
     *
     * @return
     */
    public List<String> returnAvailablePages() {
        List<String> pages = new List<String>();
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            pages.add(possibleWizardStepItem.name());
        }
        return pages;
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
            for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
                if (
                    deployment.Deployment_Last_Step__c != null &&
                    deployment.Deployment_Last_Step__c.containsIgnoreCase(String.valueOf(possibleWizardStepItem))
                ) {
                    currentComponentOrder = possibleWizardStepItem.ordinal();
                    break;
                }
            }
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[currentComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);

            // Find the step and attachment to auto populate selected item on load
            String attId = returnAttachmentIdFromStep(deployment.Id);
            if (String.isNotBlank(attId)) {
                pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
            }
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
            for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
                if (String.isNotBlank(currentURL) && currentURL.containsIgnoreCase(String.valueOf(possibleWizardStepItem))) {
                    currentComponentOrder = possibleWizardStepItem.ordinal();
                    break;
                }
            }
            // Checking the total page size for wizard to avoid error for last step
            Integer order = currentComponentOrder - 1;
            Integer validComponentOrder = (order < 0) ? (order + 1) : order;
            String newComponentName = String.valueOf(PossibleWizardSteps.values()[validComponentOrder]);
            String currentURLProtocol = Url.getSalesforceBaseUrl().getProtocol();
            String currentURLHost = Url.getSalesforceBaseUrl().getHost();
            String newComponentURL = currentURLProtocol + '://' + currentURLHost + '/apex/' + namespace + newComponentName;
            pReference = new PageReference(newComponentURL);
            pReference.getParameters().put(C_ID, deployment.Id);

            // Find the step and attachment to auto populate selected item on load
            String attId = returnAttachmentIdFromStep(deployment.Id);
            if (String.isNotBlank(attId)) {
                pReference.getParameters().put(METADATA_PRESELECTION_ID, attId);
            }
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
        for (PossibleWizardSteps possibleWizardStepItem : PossibleWizardSteps.values()) {
            if (String.isNotBlank(valueToCheck) && valueToCheck.containsIgnoreCase(String.valueOf(possibleWizardStepItem))) {
                currentComponentOrder = possibleWizardStepItem.ordinal();
            }
        }
        return currentComponentOrder;
    }

    /**
     * It is used to find existing attachment id
     * For "MetaData" type of step, attachment is under "Step" record
     * For "Git MetaData" type of step, attachment is under either "Git Commit" or "Git Org Commit" record
     *
     * @param deploymentId
     *
     * @return
     */
    private String returnAttachmentIdFromStep(String deploymentId) {
        List<Step__c> steps = new List<Step__c>();
        try {
            steps = [
                SELECT Id, Type__c, Commit_Id__c, Commit_Name__c
                FROM Step__c
                WHERE Deployment__c = :deploymentId AND Type__c IN ('Git Metadata', 'MetaData')
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];

            if (!steps.isEmpty()) {
                List<Attachment> attachments = [
                    SELECT Id
                    FROM Attachment
                    WHERE ParentId = :steps[0].Id AND Name = :METADATA
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (!attachments.isEmpty()) {
                    return attachments[0].Id;
                }
            }
        } catch (System.QueryException exceptions) {
            throw new MetadataDeploymentServiceException(exceptions.getMessage());
        }
        return '';
    }

    /**
     * It is used to return source type list for Source step of wizard
     *
     * @return
     */
    public List<String> getSourceTypeList() {
        return new List<String>{ 'org', 'git' };
    }

    /**
     * It is used to return general step header
     *
     * @return
     */
    public String getStepGeneralHeader() {
        return Label.New_Deployment;
    }

    public class MetadataDeploymentServiceException extends Exception {
    }
}