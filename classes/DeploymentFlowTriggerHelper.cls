public class DeploymentFlowTriggerHelper {
    public static Integer existingFlows = 0;
    public static Integer existingSteps = 0;
    public static Integer newFlowCount = 0;
    public static boolean isFeatureEnabled = false;
    public static Map<String,List<Deployment_Flow_Step__c>> MdepSteps;
    public static Map<String,Integer> MsourceAndDestination;
    private static LicenseManagerController lmc = new LicenseManagerController();
    
    public static void prepareData(){
        Set<Id> idset = new Set<Id>();
        for(SObject so : Trigger.new){
            if(so.Id!=null)idset.add(so.Id);
            
            if(String.isNotBlank((String)so.get(Settings.ns+'Order_By__c'))){
                PromotionTriggerHelper.checkValidity(so);
            }
        }
        MdepSteps = new Map<String,List<Deployment_Flow_Step__c>>();
        for (Deployment_Flow_Step__c dfs: [SELECT Branch__c, Deployment_Flow__c, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name  
                                             FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c IN :idset ORDER BY Deployment_Flow__c]) {

            if (MdepSteps.containsKey(dfs.Deployment_Flow__c)) {
                List<Deployment_Flow_Step__c> Ltmp = MdepSteps.get(dfs.Deployment_Flow__c);
                Ltmp.add(dfs);
                MdepSteps.put(dfs.Deployment_Flow__c, Ltmp);
            }
            else {
                MdepSteps.put(dfs.Deployment_Flow__c, new List<Deployment_Flow_Step__c>{dfs});
            }
        }
    }

    public static void checkForCBMlicenses(){
        isFeatureEnabled = FeatureHelper.isFeatureEnabled('Branch Management');
        
        Set<Id> idset = new Set<Id>();
        for(SObject so : Trigger.new){
            if(so.Id!=null)idset.add(so.Id);
        }

        existingSteps = [select count() from Deployment_Flow_Step__c where 
                         Deployment_Flow__r.Active__c=true and 
                         Deployment_Flow__r.Main_Branch__c!=null and 
                         Deployment_Flow__r.Git_Repository__c!=null and
                         (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') AND// MY: Added to exclude scratch orgs from used CBM licenses
                         Branch__c!=null];
        
        newFlowCount = 0;
        for(SObject so : Trigger.new){
            Deployment_Flow__c df = (Deployment_Flow__c)so;
            if(isValidFlow(df) && Trigger.isInsert)newFlowCount++;
        }
        Integer totalCount = existingSteps + newFlowCount;
        Integer allowedCount = lmc.cbmBranchesAvailable;
        
        for(SObject so : Trigger.new){
            Deployment_Flow__c df = (Deployment_Flow__c)so;
            if(isValidFlow(df)){
                if(!isFeatureEnabled){
                    df.addError(Label.BRANCH_MGMT_NOT_ENABLED);
                }
                else if(totalCount > allowedCount){
                    df.addError(Label.BRANCH_MGMT_LICENSE_EXCEEDED);     
                }
            }
        }
    }

    public static boolean isValidFlow(Deployment_Flow__c df){
        return (df.Active__c==true && df.Git_Repository__c!=null && String.isNotBlank(df.Main_branch__c));
    }

    public static void beforeCommon(SObject so) {

        Deployment_Flow__c df = (Deployment_Flow__c)so;
        if(df.Calculate_Based_on__c != 'Branch'){
            df.Hide_tabs__c = 'Commits Ahead;Commits Behind;Deployment Error;File Differences;Auto Resolved Conflicts;Merged Files';
        }
        if (!df.Disable_Validations__c && isValidFlow(df)) {

            if (MdepSteps.containsKey(df.Id)) {

                List<Deployment_Flow_Step__c> Ldfs = MdepSteps.get(df.Id);
                Map<String,Boolean> Mbranch = new Map<String,Boolean>();
                Map<String,Boolean> Msource = new Map<String,Boolean>();

                for (Deployment_Flow_Step__c dfs: Ldfs) {
                    // Commented out based on new oktana UX design
                    /*if (dfs.Branch__c == null || dfs.Branch__c == '') {
                        df.addError(Label.ALL_FLOW_STEPS_WITH_BRANCH_NAME);
                        return;
                    }
                    if (dfs.Source_Environment__c == null || dfs.Destination_Environment__c == null) {
                        df.addError(Label.MUST_HAVE_SOURCE_AND_DESTINATION);
                        return;
                    }*/
                    if (Mbranch.containsKey(dfs.Branch__c) || dfs.Branch__c == df.Main_branch__c) {
                        df.addError(Label.REPEATED_BRANCH_NAME);
                        return;
                    }
                    else {
                        Mbranch.put(dfs.Branch__c,true);
                    }
                    if (df.Equal_Branch_Environment_Name__c) {
                        if (!dfs.Branch__c.equals(dfs.Source_Environment__r.Name)) {
                            df.addError(Label.BRANCH_AND_SOURCE_ENVIRONMENT_EQUALS);
                        }
                    }
                    if (dfs.Source_Environment__c != null && Msource.containsKey(dfs.Source_Environment__c)) {
                        df.addError(Label.REPEATED_SOURCE_ENVIRONMENT);
                        return;
                    }
                    else {
                        Msource.put(dfs.Source_Environment__c,true);
                    }
                }
            }
        }
    }                                                                                    
}