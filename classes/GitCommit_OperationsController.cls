public with sharing class GitCommit_OperationsController extends GitCommit_ComponentBase {
    public AuxiliaryObject__c auxObj {
        get {
            if(auxObj == null) {
                auxObj = new AuxiliaryObject__c();
                auxObj.Org_Credential__c = updateAuxObject();
            }
            return auxObj;
        }
        set {
            if(auxObj != null) {
                pageController.snapshot.Org__c = auxObj.Org_Credential__c;
            }
        }
    }

    /**
     * It is used to populate auxObject org credential by using snapshot record
     * @see GitCommit_PageBase
     * @see GitCommit_ComponentBase
     *
     * @return String value of org credential name
     */
    public String updateAuxObject() {
        if(pageController != null && pageController.snapshot != null) {
            return pageController.snapshot.Org__c;
        }
        return '';
    }

    public Boolean disableRecreateBranch {
        get {
            Personal_Settings__c settings = Personal_Settings__c.getInstance();
            return settings != null ? settings.Disable_Re_Create_Feature_Branch_in_US__c  : false;
        }
    }
}