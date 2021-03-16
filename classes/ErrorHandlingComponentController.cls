/**
 * This is the controller for ErrorHandling component
 */
public with sharing class ErrorHandlingComponentController extends WizardHelper {
    public String overrideMessage { get; set; }
    public String actionName { get; set; }
    public List<String> stepsToFixIssueList { get; set; }

    public ErrorHandlingComponentController() {
    }

    public void populateErrorMessage() {
        super.jsonParser(errorMessageJSON);
        overrideMessage = super.errorMessage.generalMessage;
        stepsToFixIssueList = super.errorMessage.stepsToFix;
        actionName = super.errorMessage.actionName;
    }

    /**
     * This method will send user to step they can try again
     * Possible options: "previousPage", "currentPage" and "nextPage"
     *
     * @return last step page
     */
    public PageReference tryAgain() {
        return actionName == 'previousPage' ? goToPreviousComponent() : actionName == 'currentPage' ? goToNextComponent() : goToNextComponent(setupWizardSettings.Last_Step__c);
    }
}