/**
 * Batch class to Execute checkConnectionBehaviorAndPromote method via chunks for CCD promotion
 *
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since Copado v15
 */
public class CCD_PromotionBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public final String CANCELLED = 'Cancelled';
    public String executerId;
    public Set<Id> sourceEnvIds;
    public String deploymentId;
    public Connection_Behavior__c connectionBehavior;

    public CCD_PromotionBatch(Id executerId) {
        this.executerId = executerId;
    }

    public CCD_PromotionBatch(Id executerId, Set<Id> sourceEnvIds) {
        this.executerId = executerId;
        this.sourceEnvIds = sourceEnvIds;
    }

    public CCD_PromotionBatch(Id executerId, Set<Id> sourceEnvIds, Connection_Behavior__c connectionBehavior) {
        this.executerId = executerId;
        this.sourceEnvIds = sourceEnvIds;
        this.connectionBehavior = connectionBehavior;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String userStoryQuery = 'SELECT Id, Environment__c, Release__c, Release__r.Project__c, Release__r.Project__r.Deployment_Flow__c, Project__c, Project__r.Deployment_Flow__c FROM User_Story__c';
        String defaultWhereCondition = ' WHERE Promote_Change__c = TRUE AND Exclude_From_CBM__c = FALSE AND Status__c != :CANCELLED AND Environment__c IN : sourceEnvIds';
        String orderBy = ' ORDER BY Manual_Step_Required__c, Project__c, Release__r.Project__c, Environment__c NULLS LAST';
        String connectionCriteria = '';
        if (connectionBehavior != null && connectionBehavior.Promotion_Criteria__c != null) {
            connectionCriteria += ' AND ' + connectionBehavior.Promotion_Criteria__c;
        }
        String mainQuery = userStoryQuery + defaultWhereCondition + connectionCriteria + orderBy;
        return Database.getQueryLocator(mainQuery);
    }

    public void execute(Database.BatchableContext BC, List<User_Story__c> scope) {
        Set<String> usIds = new Set<String>();
        for (User_Story__c us : scope) {
            usIds.add(us.Id);
        }
        UserStoryChangeEventTriggerHandler.connectionBehavior = 'Scheduled';
        deploymentId = UserStoryChangeEventTriggerHandler.ccdCheckConnectionBehaviorAndPromote(
            usIds,
            executerId,
            false,
            (String.isBlank(deploymentId) ? null : deploymentId)
        );
    }

    public void finish(Database.BatchableContext BC) {
        Id jobId = BC.getJobId();
        List<AsyncApexJob> apexJobItems = [SELECT JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ParentJobId = :jobId];
        if (!apexJobItems.isEmpty()) {
            AsyncApexJob apexJobItem = apexJobItems[0];
            //had to place Test.isRunningTest() since DML after the callout is a must to crate Quality gate steps and can never be in a single transaction in a real case scenario
            if (apexJobItem.JobItemsProcessed == apexJobItem.TotalJobItems && !Test.isRunningTest()) {
                DeployAPI.deploy(deploymentId, executerId);
            }
        }
    }
}