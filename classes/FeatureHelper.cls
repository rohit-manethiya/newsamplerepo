public without sharing class FeatureHelper {
    
    public boolean branchMgmtEnabled {get;set;}
    public boolean complianceHubEnabled {get;set;}
    
    public static boolean isFeatureEnabled(String feature){
        LicenseManagerController lmc = new LicenseManagerController();
        Boolean res = true;

        if (feature == 'Compliance Hub') {
            res = lmc.cchLicensesAvailable >0;
        }
        else if (feature == 'Selenium Testing') {
            res = lmc.cstLicensesAvailable > 0;
        }
        else if (feature == 'Branch Management') {
            res = lmc.cbmBranchesAvailable > 0;
        }
        else {
            res = lmc.copadoLicensesAvailable >0;
        }
        system.debug('***** Feature: '+ feature + ' = ' + res);
        return res;
    }
    public static boolean isBranchMgmtEnabled(){
        return featureHelper.isFeatureEnabled('Branch Management');
    }

    @AuraEnabled
    public static boolean isComplianceHubEnabled(){
        return featureHelper.isFeatureEnabled('Compliance Hub');
    }

    public static boolean isChangeChangeManagementEnabled(){
        return featureHelper.isFeatureEnabled('Change Management');
    }
    
    //Constructors
    private void constructor(){
        branchMgmtEnabled = isBranchMgmtEnabled();
        complianceHubEnabled = isComplianceHubEnabled();
    }
    public FeatureHelper(){
        constructor();
    }
    public FeatureHelper(ApexPages.StandardController stdController){
        constructor();
    }

    /** 
     * This method will be called from following actions;
     * 1- When we install package: postinstallclass
     * 2- When we create or update new pipeline steps
     * 3- When we update pipeline (active-deactive)
     * 
     * Method will be future method because we can not update feature parameter after any DML
     * 
     * First of all we will retrieve all active pipelines
     * We will get the all steps of active pipelines and find the final destination step
     * if final destination org is not sandbox or scratch org, we will update the "NumberOfProductionEnvironment" feature parameter
     * 
     * To find the final destination we will use two map (source and destination), the environment only exist in destination is final environment
     */
    @Future
    public static void updateNumberOfProductionEnvironmentFeatureParameter() {
        try {
            Integer numberOfProductionEnvironment = 0; 
        
            Map<Id, Set<Id>> destinationEnvironmentsByPipelineId = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> sourceEnvironmentsByPipelineId = new Map<Id, Set<Id>>();

            // find all pipeline connections of active pipelines
            for(Deployment_Flow_Step__c pipelineConnection : [SELECT Id, Destination_Environment__c, Destination_Environment__r.Type__c, Source_Environment__c, Deployment_Flow__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__r.Active__c = TRUE AND (NOT Destination_Environment__r.Type__c LIKE 'Scratch Org%') AND Destination_Environment__r.Type__c != 'Sandbox']) {

                // fill destinationEnvironmentsByPipelineId map
                if(!destinationEnvironmentsByPipelineId.containskey(pipelineConnection.Deployment_Flow__c)) {
                    destinationEnvironmentsByPipelineId.put(pipelineConnection.Deployment_Flow__c, new Set<Id> { pipelineConnection.Destination_Environment__c });
                } else {
                    Set<Id> destinationEnvironmentIds = destinationEnvironmentsByPipelineId.get(pipelineConnection.Deployment_Flow__c);
                    destinationEnvironmentIds.add(pipelineConnection.Destination_Environment__c);
                    destinationEnvironmentsByPipelineId.put(pipelineConnection.Deployment_Flow__c, destinationEnvironmentIds);
                }

                // fill sourceEnvironmentsByPipelineId map
                if(!sourceEnvironmentsByPipelineId.containskey(pipelineConnection.Deployment_Flow__c)) {
                    sourceEnvironmentsByPipelineId.put(pipelineConnection.Deployment_Flow__c, new Set<Id> { pipelineConnection.Source_Environment__c });
                } else {
                    Set<Id> sourceEnvironmentIds = sourceEnvironmentsByPipelineId.get(pipelineConnection.Deployment_Flow__c);
                    sourceEnvironmentIds.add(pipelineConnection.Source_Environment__c);
                    sourceEnvironmentsByPipelineId.put(pipelineConnection.Deployment_Flow__c, sourceEnvironmentIds);
                }
            }

            // find the final destination of each pipeline
            Map<Id, Id> finalEnvironmentIdByPipelineId = new Map<Id, Id>();
            if(!destinationEnvironmentsByPipelineId.isEmpty() && !sourceEnvironmentsByPipelineId.isEmpty()) {
                for(Id pipelineId : destinationEnvironmentsByPipelineId.keySet()) {
                    for(Id destinationEnvironmentId : destinationEnvironmentsByPipelineId.get(pipelineId)) {
                        if(!sourceEnvironmentsByPipelineId.get(pipelineId).contains(destinationEnvironmentId)) {
                            finalEnvironmentIdByPipelineId.put(pipelineId, destinationEnvironmentId);
                        }
                    }
                }
            }

            // Calculate the final count of production envrionments by checking the type of environment
            if(!finalEnvironmentIdByPipelineId.isEmpty()) {
                numberOfProductionEnvironment = finalEnvironmentIdByPipelineId.size();
            }
            System.debug('**f**numberOfProductionEnvironment : ' + numberOfProductionEnvironment);

            // update "NumberOfProductionEnvironment" feature parameter
            if(numberOfProductionEnvironment == 0) {
                numberOfProductionEnvironment = 1; // this is default value so if there is nothing, it will be always 1 
            }
            if(numberOfProductionEnvironment > 0) {
                FeatureManagement.setPackageIntegerValue('Number_of_Prod_Envs', numberOfProductionEnvironment);
            }
        } catch (Exception exceptions) {
            System.debug('**f**exceptions : ' + exceptions);
        }
    }
}