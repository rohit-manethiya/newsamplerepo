public class DeploymentFlowStepTriggerHelper {
    public static Integer existingFlows = 0;
    public static Integer existingSteps = 0;
    public static Integer newStepCount = 0;
    public static boolean isFeatureEnabled = false;
    private static LicenseManagerController lmc = new LicenseManagerController();

    public class ApplicationException extends Exception {}
    
    public static void prepareData(){
        isFeatureEnabled = FeatureHelper.isFeatureEnabled('Branch Management');
        
        Set<Id> idset = new Set<Id>();
        for(SObject so : Trigger.new){
            if(so.Id!=null)idset.add(so.Id);
        }
        
        existingSteps = [select count() from Deployment_Flow_Step__c where 
                         Deployment_Flow__r.Active__c=true and
                         (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') AND// MY: Added to exclude scratch orgs from used CBM licenses
                         Deployment_Flow__r.Main_Branch__c!=null and 
                         Deployment_Flow__r.Git_Repository__c!=null and 
                         Branch__c!=null and (NOT(Id in :idset)) ];
        
        newStepCount = 0;
        for(SObject so : Trigger.new){
            Deployment_Flow_Step__c dfs = (Deployment_Flow_Step__c)so;
            if(dfs.Source_Environment__c != null && (String.isNotBlank(dfs.Source_Environment__r.Type__c) && !dfs.Source_Environment__r.Type__c.startsWithIgnoreCase('Scratch Org'))) { // MY: Added to exclude scratch orgs from used CBM licenses
                if (isValidFlowStep(dfs))newStepCount++;
            }
        }
        Integer totalCount = existingSteps + newStepCount;
        Integer allowedCount = lmc.cbmBranchesAvailable;
        for(SObject so : Trigger.new){
            Deployment_Flow_Step__c dfs = (Deployment_Flow_Step__c)so;
            if(isValidFlowStep(dfs)){
                if(!isFeatureEnabled){
                    dfs.addError(Label.BRANCH_MGMT_NOT_ENABLED);
                }
                else if(totalCount > allowedCount){
                 	dfs.addError(Label.BRANCH_MGMT_LICENSE_EXCEEDED);     
                }
            }
        }
    }
    public static boolean isValidFlowStep(Deployment_Flow_Step__c dfs){
        return (String.isNotBlank(dfs.branch__c) && dfs.Deployment_Flow__r.Active__c == true);
    } 

    public static void firePossibleFlowValidations(List<Deployment_Flow_Step__c> Ldfs) {

        System.Debug('Enter firePossibleFlowValidations');

        Map<Id,Deployment_Flow__c> MdfIds = new Map<Id,Deployment_Flow__c>();

        for (Deployment_Flow_Step__c dfs: Ldfs) {
            Deployment_Flow__c df = new Deployment_Flow__c();
            df.Id = dfs.Deployment_Flow__c;
            MdfIds.put(df.Id,df);
        }

        try {
            update MdfIds.values();
        }
        catch (Exception e) {
            String mess = e.getMessage();
            String validationException = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
            mess = mess.substring(mess.indexOf(validationException)+validationException.length()+2, mess.length()-1);
            System.Debug('Exception mess = ' + mess);
            throw new applicationException(mess);
        }
    }
}