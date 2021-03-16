/**
 * Batch class to Execute checkForAutomatedBackPromotions method via chunks for CCD back-promotion
 *
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since Copado v15
 */
public class CCD_BackPromotionBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    //CONSTANT variables
    public final String COMPLETED = 'Completed';
    public final String PROCESSED = 'Processed';
    private final String SCHEDULED = 'Scheduled';
    //NON-CONSTANT variables
    public String executerId;
    private Set<Id> destEnvIds;
    public Id deploymentId;

    public CCD_BackPromotionBatch(Id executerId){
        this.executerId = executerId;
    }

    public CCD_BackPromotionBatch(Id executerId, Set<Id> destEnvIds){
        this.executerId = executerId;
        this.destEnvIds = destEnvIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Back_Promotion__c, Destination_Environment__c, Source_Environment__c,  Release__c, Release__r.Project__c, Release__r.Project__r.Deployment_Flow__c, Project__c, Project__r.Deployment_Flow__c FROM Promotion__c WHERE Connection_Behavior__c != NULL AND Connection_Behavior__c != :PROCESSED AND Status__c = :COMPLETED AND ((Destination_Environment__c IN : destEnvIds AND Back_Promotion__c = FALSE) OR (Source_Environment__c IN : destEnvIds AND Back_Promotion__c = TRUE)) ORDER BY Project__c, Release__r.Project__c, Destination_Environment__c, LastModifiedDate NULLS LAST';
        return Database.getQueryLocator(query); 
    }

    public void execute(Database.BatchableContext BC, List<Promotion__c> scope) {
        PromotionChangeEventTriggerHandler.commitUserId = executerId;
        PromotionChangeEventTriggerHandler.connectionBehavior = SCHEDULED;
        deploymentId = PromotionChangeEventTriggerHandler.ccdCheckForAutomatedBackPromotions(scope, deploymentId);
    }

    public void finish(Database.BatchableContext BC) {
        Id jobId = BC.getJobId();
        List<AsyncApexJob> apexJobItems = [SELECT JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ParentJobId = : jobId];
        if(!apexJobItems.isEmpty()) {
            AsyncApexJob apexJobItem = apexJobItems[0];
            //had to place Test.isRunningTest() since DML after the callout is a must to crate Quality gate steps and can never be in a single transaction in a real case scenario
            if(apexJobItem.JobItemsProcessed == apexJobItem.TotalJobItems && !Test.isRunningTest() && null != deploymentId) {
                DeployAPI.deploy(deploymentId, executerId);
            }
        }
    }
}