/**
 * Each deployment type will have one service class which will implement this interface method
 */
public interface DeploymentInterface {
    /**
     * This method will define the possible steps for deployment for each deployment type
     * Step values are stored in Enum values in the related service class
     *
     * @return
     */
    List<String> returnAvailableSteps();

    /**
     * This method will define the possible pages for deployment for each deployment type
     * Page values are stored in Enum values in the related service class
     *
     * @return
     */
    List<String> returnAvailablePages();

    /**
     * This method will define the next steps to open
     * deploymentType is the action name of the deployment such as "Validate" or "Deployment"
     *
     * @return
     */
    PageReference goToNextStep(Deployment__c deployment, String deploymentType);

    /**
     * This method will define the previous steps to open
     *
     * @return
     */
    PageReference goToPreviousStep(Deployment__c deployment);

    /**
     * It is used the get instance of necessary service class
     *
     * @return
     */
    DeploymentInterface getInstance();

    /**
     * It is used to get the current step name
     *
     * @return
     */
    Integer getComponentIndex(String valueToCheck);

    /**
     * It is used to return source type list for Source step of wizard
     *
     * @return
     */
    List<String> getSourceTypeList();

    /**
     * It is used to return general step header
     *
     * @return
     */
    String getStepGeneralHeader();
}