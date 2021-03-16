/**
 * This is main controller for GitCommit_Advanced component which extends GitCommit_ComponentBase to get values from GitCommit_PageBase
 * @see GitCommit_PageBase
 */
public with sharing class GitCommit_AdvancedController extends GitCommit_ComponentBase {

    /**
     * It is used to update user story base branch field with entered value on pageController.userStoryBaseBranch variable
     * @see pageController is used to render GitCommit_ComponentBase component
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     */
    public void updateUserStoryBaseBranch() {
        String selectedBranch = ApexPages.currentPage().getParameters().get('branchName');
        if(String.isNotBlank(selectedBranch)) {
            pageController.userStory.Base_Branch__c = selectedBranch;
            Utilities.Secure_DML(pageController.userStory, Utilities.DML_Action.UPD, Schema.SObjectType.User_Story__c);
        }
    }
}